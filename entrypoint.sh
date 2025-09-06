#!/bin/bash

# Bắt đầu dịch vụ Docker trong nền (Docker-in-Docker).
# `&` đưa tiến trình vào chạy nền để script có thể tiếp tục.
# `>/dev/null 2>&1` ẩn các log của dockerd để giữ cho log của runner sạch sẽ.
/usr/bin/dockerd >/dev/null 2>&1 &

# Đợi 5 giây để đảm bảo Docker daemon đã sẵn sàng nhận lệnh.
sleep 5

# Kiểm tra các biến môi trường cần thiết
if [ -z "${GITHUB_PAT}" ] || [ -z "${GITHUB_OWNER}" ] || [ -z "${GITHUB_REPOSITORY}" ]; then
  echo "LỖI: Các biến môi trường GITHUB_PAT, GITHUB_OWNER, GITHUB_REPOSITORY là bắt buộc."
  exit 1
fi

# Lấy Registration Token từ GitHub API.
# Token này là tạm thời và được dùng để đăng ký runner một cách an toàn.
# Chúng ta sử dụng jq để trích xuất token từ phản hồi JSON.
echo "Đang yêu cầu registration token từ GitHub..."
REG_TOKEN=$(curl -s -X POST \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Authorization: token ${GITHUB_PAT}" \
  "https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPOSITORY}/actions/runners/registration-token" | jq .token --raw-output)

# Xử lý lỗi nếu không lấy được token
if [ -z "${REG_TOKEN}" ] || [ "${REG_TOKEN}" == "null" ]; then
    echo "LỖI: Không thể lấy được registration token từ GitHub. Vui lòng kiểm tra GITHUB_PAT và tên repository."
    exit 1
fi

# Dọn dẹp cấu hình cũ nếu runner đã từng được đăng ký (quan trọng khi container khởi động lại).
./config.sh remove --token "${REG_TOKEN}"

# Cấu hình runner với các thông tin đã lấy được.
# --unattended: Chạy mà không cần hỏi người dùng.
# --replace: Thay thế runner cũ có cùng tên nếu tồn tại.
# --name: Tạo một tên độc nhất cho runner dựa trên hostname của container.
# --labels: Gán các label cho runner, lấy từ biến môi trường.
echo "Đang cấu hình runner..."
./config.sh \
    --url "https://github.com/${GITHUB_OWNER}/${GITHUB_REPOSITORY}" \
    --token "${REG_TOKEN}" \
    --name "dind-runner-$(hostname)" \
    --labels "${RUNNER_LABELS}" \
    --unattended \
    --replace

# Hàm dọn dẹp sẽ được gọi khi container nhận tín hiệu dừng (SIGINT, SIGTERM)
cleanup() {
    echo "Đang gỡ bỏ runner..."
    ./config.sh remove --token "${REG_TOKEN}"
}

# Bẫy các tín hiệu thoát và gọi hàm cleanup
trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

# Chạy runner. Dùng `exec` để tiến trình của runner thay thế tiến trình của script.
# Điều này đảm bảo runner nhận được các tín hiệu hệ thống một cách chính xác.
# Runner sẽ chạy ở foreground và lắng nghe các job cho đến khi container bị dừng.
./run.sh & wait $!