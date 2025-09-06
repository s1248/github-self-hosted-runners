#!/bin/bash

# Bắt đầu dịch vụ Docker trong nền. Bước này cần quyền root.
/usr/bin/dockerd >/dev/null 2>&1 &
sleep 5

# Đợi cho Docker socket xuất hiện và cấp quyền cho nhóm docker.
# Điều này đảm bảo user 'runner' có thể truy cập nó.
while [ ! -S /var/run/docker.sock ]; do
  echo "Đang đợi Docker socket..."
  sleep 1
done
chown root:docker /var/run/docker.sock

# Đọc secret và export các biến để gosu có thể truyền chúng cho user 'runner'.
if [ -n "${GITHUB_PAT_FILE}" ] && [ -f "${GITHUB_PAT_FILE}" ]; then
  export GITHUB_PAT=$(cat "${GITHUB_PAT_FILE}")
fi
export GITHUB_OWNER
export GITHUB_REPOSITORY
export RUNNER_LABELS

# =================== BƯỚC HẠ QUYỀN ===================
# Sử dụng 'gosu' để thực thi phần còn lại của script với tư cách là user 'runner'.
# 'bash -c' được dùng để chạy một chuỗi lệnh.
# Mọi lệnh bên trong dấu '...' sẽ được chạy bởi user 'runner'.
exec gosu runner bash -c '
  # Chuyển vào thư mục làm việc
  cd /actions-runner

  # Kiểm tra các biến môi trường
  if [ -z "${GITHUB_PAT}" ] || [ -z "${GITHUB_OWNER}" ] || [ -z "${GITHUB_REPOSITORY}" ]; then
    echo "LỖI: Các biến môi trường GITHUB_PAT, GITHUB_OWNER, GITHUB_REPOSITORY là bắt buộc."
    exit 1
  fi

  # Lấy Registration Token
  echo "Đang yêu cầu registration token từ GitHub..."
  REG_TOKEN=$(curl -s -X POST \
    -H "Accept: application/vnd.github.v3+json" \
    -H "Authorization: token ${GITHUB_PAT}" \
    "https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPOSITORY}/actions/runners/registration-token" | jq .token --raw-output)

  if [ -z "${REG_TOKEN}" ] || [ "${REG_TOKEN}" == "null" ]; then
      echo "LỖI: Không thể lấy được registration token."
      exit 1
  fi

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
  trap "cleanup; exit 130" INT
  trap "cleanup; exit 143" TERM

  # Chạy runner
  ./run.sh & wait $!
'