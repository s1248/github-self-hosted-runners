#!/bin/bash

# Hàm hiển thị thông tin debug
debug_info() {
    echo "=== KANIKO RUNNER DEBUG INFO ==="
    echo "User: $(whoami)"
    echo "UID: $(id -u)"
    echo "GID: $(id -g)"
    echo "Working Directory: $(pwd)"
    echo "Kaniko Executor: $(ls -la /kaniko-executor 2>/dev/null || echo 'Not found')"
    echo "Home Directory: $HOME"
    echo "================================"
}

# Hiển thị thông tin debug
debug_info

# Đọc secret từ file nếu có
if [ -n "${GITHUB_PAT_FILE}" ] && [ -f "${GITHUB_PAT_FILE}" ]; then
  export GITHUB_PAT=$(cat "${GITHUB_PAT_FILE}")
fi

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

# Cấu hình runner với Kaniko labels
echo "Đang cấu hình runner với Kaniko support..."
./config.sh \
    --url "https://github.com/${GITHUB_OWNER}/${GITHUB_REPOSITORY}" \
    --token "${REG_TOKEN}" \
    --name "kaniko-runner-$(hostname)" \
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

# Tạo script helper cho Kaniko
create_kaniko_helper() {
    cat > /tmp/kaniko-build.sh << 'EOF'
#!/bin/bash
# Kaniko Build Helper Script
# Usage: kaniko-build.sh <dockerfile> <context> <destination>

DOCKERFILE=${1:-"Dockerfile"}
CONTEXT=${2:-"."}
DESTINATION=${3:-"temp-image:latest"}

echo "Building với Kaniko..."
echo "Dockerfile: $DOCKERFILE"
echo "Context: $CONTEXT"
echo "Destination: $DESTINATION"

# Kiểm tra Docker registry credentials
if [ -f "/var/secrets/docker-config.json" ]; then
    cp /var/secrets/docker-config.json /kaniko/.docker/config.json
fi

# Chạy Kaniko executor
exec /kaniko-executor \
    --dockerfile="$DOCKERFILE" \
    --context="$CONTEXT" \
    --destination="$DESTINATION" \
    --cache=true \
    --compressed-caching=false \
    --snapshot-mode=redo \
    --use-new-run \
    "$@"
EOF
    chmod +x /tmp/kaniko-build.sh
    echo "Kaniko helper script đã được tạo tại /tmp/kaniko-build.sh"
}

# Tạo script helper
create_kaniko_helper

# Thiết lập môi trường cho Kaniko
export PATH="/tmp:$PATH"

echo "Runner đã sẵn sàng với Kaniko support!"
echo "Sử dụng 'kaniko-build.sh' để build container images."
echo "Ví dụ: kaniko-build.sh Dockerfile . my-registry/my-image:tag"

# Chạy runner
./run.sh & wait $!