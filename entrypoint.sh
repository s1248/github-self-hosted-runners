#!/bin/bash

# Kiểm tra các biến môi trường cần thiết
if [ -z "$ACTIONS_RUNNER_INPUT_URL" ] || [ -z "$ACTIONS_RUNNER_INPUT_TOKEN" ]; then
  echo "Lỗi: Các biến môi trường ACTIONS_RUNNER_INPUT_URL và ACTIONS_RUNNER_INPUT_TOKEN là bắt buộc."
  exit 1
fi

# Cấu hình runner
./config.sh --url "${ACTIONS_RUNNER_INPUT_URL}" --token "${ACTIONS_RUNNER_INPUT_TOKEN}" --labels "${ACTIONS_RUNNER_INPUT_LABELS}" --unattended --replace

# Hàm dọn dẹp để gỡ bỏ runner khi container dừng
cleanup() {
  echo "Đang gỡ bỏ runner..."
  ./config.sh remove --token "${ACTIONS_RUNNER_INPUT_TOKEN}"
}

# Bắt tín hiệu để thực hiện dọn dẹp
trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

# Khởi chạy runner và đợi nó kết thúc
./run.sh & wait $!