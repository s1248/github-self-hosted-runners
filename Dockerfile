# Sử dụng base image Ubuntu 22.04 LTS (Jammy Jellyfish)
# Đây là một lựa chọn ổn định và được hỗ trợ lâu dài.
FROM ubuntu:22.04

# Thêm thông tin về giấy phép và người bảo trì
# Giúp người khác hiểu rõ hơn về image này khi sử dụng.
LABEL maintainer="s1248.com <github-self-hosted-runners@s1248.com>"
LABEL license="MPL-2.0"

# Các biến môi trường để cài đặt runner.
# Việc đặt phiên bản runner trong ARG giúp dễ dàng cập nhật khi build image.
ARG RUNNER_VERSION="2.311.0"
ENV RUNNER_USER="runner"
ENV RUNNER_HOME="/home/runner"
ENV ACTIONS_RUNNER_INPUT_URL=""
ENV ACTIONS_RUNNER_INPUT_TOKEN=""
ENV ACTIONS_RUNNER_INPUT_LABELS="ubuntu-22.04,arm64"

# === GIAI ĐOẠN 1: CÀI ĐẶT HỆ THỐNG VÀ DEPENDENCIES ===
# Thực hiện các thao tác với quyền root.

# Cập nhật package list, cài đặt các công cụ cần thiết (curl, git, jq, sudo)
# và sau đó dọn dẹp cache của apt để giữ cho image nhỏ gọn.
RUN apt-get update && apt-get install -y \
    curl \
    git \
    jq \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Tạo người dùng không phải root ('runner') để chạy tiến trình.
# TẠM THỜI cấp quyền sudo không cần mật khẩu cho người dùng này.
# Quyền này sẽ được thu hồi sau khi không còn cần thiết.
RUN useradd -m -s /bin/bash "${RUNNER_USER}" && \
    usermod -aG sudo "${RUNNER_USER}" && \
    echo "${RUNNER_USER} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/runner

# Chuyển sang thư mục làm việc chính là thư mục home của người dùng 'runner'.
WORKDIR "${RUNNER_HOME}"

# Tải về gói cài đặt GitHub Actions Runner cho kiến trúc ARM64.
# Sau đó giải nén và xóa file tarball để tiết kiệm không gian.
RUN curl -o actions-runner-linux-arm64-${RUNNER_VERSION}.tar.gz -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-arm64-${RUNNER_VERSION}.tar.gz && \
    tar xzf ./actions-runner-linux-arm64-${RUNNER_VERSION}.tar.gz && \
    rm ./actions-runner-linux-arm64-${RUNNER_VERSION}.tar.gz

# Chạy script cài đặt các dependencies mà runner yêu cầu.
# Lệnh này cần quyền sudo, đó là lý do chúng ta đã cấp ở trên.
RUN sudo ./bin/installdependencies.sh

# === GIAI ĐOẠN 2: TĂNG CƯỜNG BẢO MẬT ===
# Thu hồi lại các đặc quyền không cần thiết trước khi hoàn thành image.

# [BƯỚC BẢO MẬT QUAN TRỌNG]
# Xóa file cấu hình sudo và gỡ người dùng 'runner' khỏi nhóm sudo.
# Sau bước này, người dùng 'runner' sẽ không còn khả năng leo thang đặc quyền
# bên trong container khi nó đang chạy.
RUN rm /etc/sudoers.d/runner && \
    gpasswd -d ${RUNNER_USER} sudo

# Đảm bảo người dùng 'runner' sở hữu toàn bộ thư mục home của mình
# và tất cả các file của Actions Runner.
RUN chown -R ${RUNNER_USER}:${RUNNER_USER} "${RUNNER_HOME}"

# === GIAI ĐOẠN 3: CẤU HÌNH RUNTIME ===
# Chuyển sang người dùng không có đặc quyền và thiết lập entrypoint.

# Chuyển context thực thi sang người dùng 'runner'.
# Tất cả các lệnh sau (COPY, RUN, ENTRYPOINT, CMD) sẽ được thực thi bởi user này.
USER ${RUNNER_USER}

# Sao chép entrypoint script vào container và cấp quyền thực thi.
# Sử dụng flag --chown để đảm bảo file được tạo ra với đúng chủ sở hữu.
COPY --chown=${RUNNER_USER}:${RUNNER_USER} entrypoint.sh .
RUN chmod +x entrypoint.sh

# Thiết lập entrypoint mặc định cho container.
# Script này sẽ chịu trách nhiệm cấu hình và khởi chạy runner khi container bắt đầu.
ENTRYPOINT ["./entrypoint.sh"]