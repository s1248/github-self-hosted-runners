#!/bin/bash

# Đường dẫn mặc định nơi Docker Swarm mount file secret
RUNNER_TOKEN_SECRET_FILE="/run/secrets/runner_token"

# Ưu tiên đọc token từ file secret nếu nó tồn tại
if [ -f "$RUNNER_TOKEN_SECRET_FILE" ]; then
  echo "Phát hiện Docker Secret. Đang đọc token từ file."
  ACTIONS_RUNNER_INPUT_TOKEN=$(cat "$RUNNER_TOKEN_SECRET_FILE")
fi

# Kiểm tra các biến bắt buộc
if [ -z "$ACTIONS_RUNNER_INPUT_URL" ] || [ -z "$ACTIONS_RUNNER_INPUT_TOKEN" ]; then
  echo "Lỗi: ACTIONS_RUNNER_INPUT_URL là bắt buộc và token phải được cung cấp qua secret hoặc biến môi trường."
  exit 1
fi

# Cấu hình runner
./config.sh --url "${ACTIONS_RUNNER_INPUT_URL}" --token "${ACTIONS_RUNNER_INPUT_TOKEN}" --labels "${ACTIONS_RUNNER_INPUT_LABELS}" --unattended --replace

# Hàm dọn dẹp khi container dừng
cleanup() {
  echo "Đang gỡ bỏ runner..."
  ./config.sh remove --token "${ACTIONS_RUNNER_INPUT_TOKEN}"
}
trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

# Khởi chạy runner
./run.sh & wait $!