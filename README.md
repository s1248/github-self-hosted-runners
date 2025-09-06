# GitHub Self-Hosted Runners với Kaniko

A reusable, Ubuntu LTS-based Docker image for self-hosted GitHub Actions runners with **Kaniko** support for secure, isolated container builds.

## 🚀 Tính năng chính

- ✅ **Kaniko Integration**: Sử dụng Kaniko thay vì Docker-in-Docker cho container builds an toàn
- ✅ **Bảo mật cao**: Container chạy như user thường, không cần quyền root
- ✅ **Cô lập hoàn toàn**: Không cần privileged mode hoặc Docker daemon
- ✅ **Hiệu suất tốt**: Không có overhead của Docker-in-Docker
- ✅ **GitHub Actions tích hợp**: Tự động đăng ký và gỡ bỏ runner

## 🔧 Sử dụng nhanh

```bash
docker run -d \
  --name kaniko-runner \
  -e GITHUB_PAT="your-github-token" \
  -e GITHUB_OWNER="your-org" \
  -e GITHUB_REPOSITORY="your-repo" \
  -e RUNNER_LABELS="kaniko,self-hosted,secure" \
  s1248/github-self-hosted-runners:latest
```

## 📖 Tài liệu chi tiết

- [**Hướng dẫn sử dụng Kaniko**](KANIKO_USAGE.md) - Chi tiết về cách sử dụng Kaniko runner
- [**Workflow ví dụ**](.github/workflows/kaniko-build-example.yml) - GitHub Actions workflow mẫu

## 🔒 So sánh bảo mật

| Aspect | Docker-in-Docker | **Kaniko** |
|--------|------------------|------------|
| **User privileges** | Cần root | ✅ User thường |
| **Container mode** | Privileged | ✅ Unprivileged |
| **Daemon requirement** | Docker daemon | ✅ Không cần daemon |
| **Isolation** | Shared daemon | ✅ Hoàn toàn cô lập |
| **Attack surface** | Lớn | ✅ Nhỏ |

## 🛠️ Build Images

### Với Kaniko helper script:
```bash
kaniko-build.sh Dockerfile . my-registry.com/my-image:tag
```

### Trong GitHub Actions:
```yaml
- name: Build với Kaniko
  run: |
    kaniko-build.sh \
      Dockerfile \
      . \
      ${{ env.REGISTRY }}/my-app:${{ github.sha }}
```

## 🌟 Lợi ích

1. **Bảo mật tối đa**: Không cần quyền root hay privileged containers
2. **Đơn giản hóa**: Loại bỏ phức tạp của Docker-in-Docker setup  
3. **Hiệu suất**: Giảm overhead và tăng tốc độ build
4. **Ổn định**: Ít xung đột tài nguyên và vấn đề về permissions
5. **Tuân thủ**: Phù hợp với các yêu cầu bảo mật nghiêm ngặt

## 📋 Môi trường variables

| Variable | Mô tả | Bắt buộc |
|----------|-------|----------|
| `GITHUB_PAT` | GitHub Personal Access Token | ✅ |
| `GITHUB_OWNER` | GitHub username hoặc organization | ✅ |
| `GITHUB_REPOSITORY` | Repository name | ✅ |
| `RUNNER_LABELS` | Labels cho runner | ❌ |
| `GITHUB_PAT_FILE` | Path đến file chứa PAT | ❌ |
