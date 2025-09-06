# Sử dụng base image Ubuntu 22.04
FROM ubuntu:22.04

# Thêm thông tin về giấy phép và người bảo trì
LABEL maintainer="s1248.com <github-self-hosted-runners@s1248.com>"
LABEL license="MPL-2.0"

# Các biến môi trường để cài đặt runner
ARG RUNNER_VERSION="2.311.0"
# Sử dụng TARGETARCH để xác định kiến trúc khi build đa nền tảng
#ARG TARGETARCH
ENV RUNNER_USER="runner"
ENV RUNNER_HOME="/home/runner"
ENV ACTIONS_RUNNER_INPUT_URL=""
ENV ACTIONS_RUNNER_INPUT_TOKEN=""
#ENV ACTIONS_RUNNER_INPUT_LABELS="ubuntu-24.04"
ENV ACTIONS_RUNNER_INPUT_LABELS="ubuntu-22.04,arm64"

# Cập nhật hệ thống và cài đặt các dependencies cần thiết
RUN apt-get update && apt-get install -y \
    curl \
    git \
    jq \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Tạo người dùng không phải root để chạy runner
RUN useradd -m -s /bin/bash "${RUNNER_USER}" && \
    usermod -aG sudo "${RUNNER_USER}" && \
    echo "${RUNNER_USER} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Chuyển sang thư mục home của người dùng runner
WORKDIR "${RUNNER_HOME}"

# Tải và cài đặt GitHub Actions runner phù hợp với kiến trúc
#RUN set -e; \
#    if [ "$TARGETARCH" = "amd64" ]; then ARCH="x64"; \
#    elif [ "$TARGETARCH" = "arm64" ]; then ARCH="arm64"; \
#    elif [ "$TARGETARCH" = "arm" ] || [ "$TARGETARCH" = "arm/v7" ]; then ARCH="arm"; \
#    else echo "Unsupported architecture: $TARGETARCH" && exit 1; fi; \
#    curl -o actions-runner-linux-${ARCH}-${RUNNER_VERSION}.tar.gz -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-${ARCH}-${RUNNER_VERSION}.tar.gz && \
#    tar xzf ./actions-runner-linux-${ARCH}-${RUNNER_VERSION}.tar.gz && \
#    rm ./actions-runner-linux-${ARCH}-${RUNNER_VERSION}.tar.gz

# Tải và cài đặt GitHub Actions runner cho ARM64
RUN curl -o actions-runner-linux-arm64-${RUNNER_VERSION}.tar.gz -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-arm64-${RUNNER_VERSION}.tar.gz && \
    tar xzf ./actions-runner-linux-arm64-${RUNNER_VERSION}.tar.gz && \
    rm ./actions-runner-linux-arm64-${RUNNER_VERSION}.tar.gz

# Cài đặt các dependencies cho runner
RUN sudo ./bin/installdependencies.sh

# Chuyển quyền sở hữu thư mục cho người dùng runner
RUN sudo chown -R ${RUNNER_USER}:${RUNNER_USER} "${RUNNER_HOME}"

# Chuyển sang người dùng runner
USER ${RUNNER_USER}

# Sao chép và cấp quyền thực thi cho entrypoint script
COPY --chown=${RUNNER_USER}:${RUNNER_USER} entrypoint.sh .
RUN chmod +x entrypoint.sh

# Thiết lập entrypoint
ENTRYPOINT ["./entrypoint.sh"]