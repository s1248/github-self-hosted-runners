# Giai đoạn 1: Base Image và Cài đặt
# Bắt đầu từ một image Ubuntu LTS (Long-Term Support) ổn định.
FROM ubuntu:22.04

# Các biến được sử dụng trong quá trình build image.
ARG RUNNER_VERSION="2.317.0"
# Đảm bảo kiến trúc này khớp với server của bạn
ARG RUNNER_ARCH="arm64"

# Các biến môi trường sẽ được sử dụng khi container chạy.
ENV GITHUB_PAT=""
ENV GITHUB_OWNER=""
ENV GITHUB_REPOSITORY=""
ENV RUNNER_LABELS="self-hosted-runners"

# --- Thiết lập thư mục làm việc ---
# Đặt WORKDIR sớm. Tất cả các lệnh sau sẽ chạy trong thư mục này.
WORKDIR /actions-runner

# --- Cài đặt các gói phụ thuộc cần thiết ---
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
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

# --- Tải và cài đặt GitHub Actions Runner ---
# Vì WORKDIR đã là /actions-runner, runner sẽ được tải và giải nén vào đúng chỗ.
RUN curl -o actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz \
    && tar xzf ./actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz \
    && rm ./actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz

# --- Sao chép và cấu hình Entrypoint Script ---
# Lệnh COPY . sẽ sao chép file vào WORKDIR hiện tại, tức là /actions-runner.
# Vì vậy file sẽ nằm ở /actions-runner/entrypoint.sh
COPY entrypoint.sh .
RUN chmod +x entrypoint.sh

# Chạy entrypoint script khi container khởi động.
# Sử dụng đường dẫn tuyệt đối là cách làm an toàn và rõ ràng nhất.
ENTRYPOINT ["/actions-runner/entrypoint.sh"]