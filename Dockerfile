# Bắt đầu từ image Ubuntu LTS ổn định.
FROM ubuntu:22.04

# Các biến build image.
ARG RUNNER_VERSION="2.317.0"
ARG RUNNER_ARCH="arm64"

# Các biến môi trường khi container chạy.
ENV GITHUB_PAT=""
ENV GITHUB_OWNER=""
ENV GITHUB_REPOSITORY=""
ENV RUNNER_LABELS="self-hosted-runners"

# Thiết lập WORKDIR sớm.
WORKDIR /actions-runner

# --- Cài đặt các gói phụ thuộc ---
RUN apt-get update && apt-get install -y \
    curl \
    git \
    jq \
    ca-certificates \
    gnupg \
    lsb-release \
    && rm -rf /var/lib/apt/lists/*

# --- Cài đặt Docker Engine (Docker-in-Docker) ---
RUN install -m 0755 -d /etc/apt/keyrings
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
RUN chmod a+r /etc/apt/keyrings/docker.asc
RUN echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN apt-get update && apt-get install -y \
    docker-ce docker-ce-cli containerd.io docker-buildx-plugin

# --- Cài đặt GOSU để hạ quyền an toàn ---
RUN curl -o /usr/local/bin/gosu -sSL "https://github.com/tianon/gosu/releases/download/1.17/gosu-$(dpkg --print-architecture | sed 's/aarch64/arm64/')" \
    && chmod +x /usr/local/bin/gosu

# --- Tạo User và Cấp quyền ---
# Tạo user 'runner' không có mật khẩu, tạo home directory.
RUN useradd -m -s /bin/bash runner
# Thêm user 'runner' vào nhóm 'docker' để có quyền sử dụng Docker daemon.
RUN usermod -aG docker runner

# --- Tải và cài đặt GitHub Actions Runner ---
RUN curl -o actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz \
    && tar xzf ./actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz \
    && rm ./actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz

# --- Sao chép Entrypoint và Cấp quyền cuối cùng ---
COPY entrypoint.sh .
RUN chmod +x entrypoint.sh
# Cấp quyền sở hữu toàn bộ thư mục cho user 'runner'.
RUN chown -R runner:runner /actions-runner

# Entrypoint sẽ chạy với quyền root mặc định.
ENTRYPOINT ["/actions-runner/entrypoint.sh"]