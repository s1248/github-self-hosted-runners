#!/bin/bash

# Bắt đầu dịch vụ Docker trong nền
/usr/bin/dockerd >/dev/null 2>&1 &
sleep 5

# ================= SỬA LỖI QUAN TRỌNG =================
# Đọc nội dung từ file secret được chỉ định bởi GITHUB_PAT_FILE
# và gán nó vào biến GITHUB_PAT.
# Việc này phải được thực hiện TRƯỚC khi kiểm tra biến.
if [ -n "${GITHUB_PAT_FILE}" ] && [ -f "${GITHUB_PAT_FILE}" ]; then
  GITHUB_PAT=$(cat "${GITHUB_PAT_FILE}")
fi
# =======================================================

# Kiểm tra các biến môi trường cần thiết
if [ -z "${GITHUB_PAT}" ] || [ -z "${GITHUB_OWNER}" ] || [ -z "${GITHUB_REPOSITORY}" ]; then
  echo "LỖI: Các biến môi trường GITHUB_PAT, GITHUB_OWNER, GITHUB_REPOSITORY là bắt buộc."
  echo "Vui lòng kiểm tra lại cấu hình Stack trên Portainer."
  # Dừng script lại 300 giây để bạn có thời gian đọc log
  sleep 300
  exit 1
fi

# Lấy Registration Token từ GitHub API
echo "Đang yêu cầu registration token từ GitHub..."
REG_TOKEN=$(curl -s -X POST \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Authorization: token ${GITHUB_PAT}" \
  "https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPOSITORY}/actions/runners/registration-token" | jq .token --raw-output)

# Xử lý lỗi nếu không lấy được token
if [ -z "${REG_TOKEN}" ] || [ "${REG_TOKEN}" == "null" ]; then
    echo "LỖI: Không thể lấy được registration token từ GitHub. Vui lòng kiểm tra GITHUB_PAT và tên repository."
    sleep 300
    exit 1
fi

# Dọn dẹp cấu hình cũ nếu có
./config.sh remove --token "${REG_TOKEN}"

# Cấu hình runner
echo "Đang cấu hình runner..."
./config.sh \
    --url "https://github.com/${GITHUB_OWNER}/${GITHUB_REPOSITORY}" \
    --token "${REG_TOKEN}" \
    --name "dind-runner-$(hostname)" \
    --labels "${RUNNER_LABELS}" \
    --unattended \
    --replace

# Hàm dọn dẹp
cleanup() {
    echo "Đang gỡ bỏ runner..."
    ./config.sh remove --token "${REG_TOKEN}"
}

# Bẫy các tín hiệu thoát
trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

# Chạy runner
./run.sh & wait $!