# GitHub Actions Self-Hosted Runner với Kaniko

## Tổng quan

Image này là phiên bản cải tiến của GitHub Actions self-hosted runner sử dụng **Kaniko** thay vì Docker-in-Docker để build container images. Điều này mang lại những lợi ích sau:

### ✅ Lợi ích của Kaniko

1. **Bảo mật cao hơn**: Không cần Docker daemon chạy với quyền root
2. **Cô lập hoàn toàn**: Container hoạt động như user thường, không cần privileged mode
3. **Hiệu suất tốt hơn**: Không có overhead của Docker-in-Docker
4. **Ổn định**: Ít vấn đề về tài nguyên và xung đột

## Sử dụng

### Khởi chạy Runner

```bash
docker run -d \
  --name kaniko-runner \
  -e GITHUB_PAT="your-github-token" \
  -e GITHUB_OWNER="your-org" \
  -e GITHUB_REPOSITORY="your-repo" \
  -e RUNNER_LABELS="kaniko,self-hosted,secure" \
  your-registry/github-runner:kaniko
```

### Build Images với Kaniko

Trong GitHub Actions workflow, sử dụng script helper:

```yaml
name: Build với Kaniko
on: push

jobs:
  build:
    runs-on: [self-hosted, kaniko]
    steps:
      - uses: actions/checkout@v4
      
      - name: Build image với Kaniko
        run: |
          kaniko-build.sh \
            Dockerfile \
            . \
            my-registry.com/my-image:${{ github.sha }}
```

### Cấu hình Registry Credentials

Mount Docker config để push images:

```bash
docker run -d \
  --name kaniko-runner \
  -v /path/to/docker-config.json:/var/secrets/docker-config.json:ro \
  -e GITHUB_PAT="your-token" \
  -e GITHUB_OWNER="your-org" \
  -e GITHUB_REPOSITORY="your-repo" \
  your-registry/github-runner:kaniko
```

## Khác biệt với Docker-in-Docker

| Aspect | Docker-in-Docker | Kaniko |
|--------|------------------|---------|
| **Quyền hạn** | Cần privileged mode | User thường |
| **Security** | Ít an toàn hơn | Rất an toàn |
| **Hiệu suất** | Overhead cao | Hiệu suất tốt |
| **Cô lập** | Chia sẻ Docker daemon | Hoàn toàn cô lập |
| **Phức tạp** | Setup phức tạp | Đơn giản |

## Ví dụ Workflow hoàn chỉnh

```yaml
name: Secure Build Pipeline
on:
  push:
    branches: [main]

jobs:
  secure-build:
    runs-on: [self-hosted, kaniko]
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        
      - name: Build và push image
        run: |
          # Build với Kaniko
          kaniko-build.sh \
            Dockerfile \
            . \
            registry.company.com/app:${{ github.sha }}
            
      - name: Run security scan
        run: |
          # Chạy security scan trên image đã build
          trivy image registry.company.com/app:${{ github.sha }}
```

## Cấu hình nâng cao

### Sử dụng cache
```bash
kaniko-build.sh Dockerfile . my-image:latest --cache=true --cache-repo=my-cache-repo
```

### Build multi-stage
```bash
kaniko-build.sh Dockerfile . my-image:latest --target=production
```

### Build với build args
```bash
kaniko-build.sh Dockerfile . my-image:latest --build-arg VERSION=1.0.0
```

## Giám sát và Debug

### Xem logs runner
```bash
docker logs kaniko-runner
```

### Debug Kaniko builds
Set log level trong workflow:
```bash
kaniko-build.sh Dockerfile . my-image:latest --verbosity=debug
```

## Bảo mật

1. ✅ Container chạy như user không có quyền root
2. ✅ Không cần Docker daemon hoặc privileged mode  
3. ✅ Cô lập hoàn toàn giữa các build
4. ✅ Secrets được quản lý an toàn qua files
5. ✅ Minimal attack surface

## Troubleshooting

### Lỗi thường gặp

1. **Registry authentication failed**
   - Kiểm tra docker-config.json được mount đúng
   - Verify credentials trong config

2. **Build context không tìm thấy**
   - Đảm bảo context path tồn tại
   - Check workspace permissions

3. **Out of disk space**  
   - Kaniko sử dụng /workspace cho builds
   - Mount volume nếu cần thêm space

### Health check
```bash
# Kiểm tra Kaniko executor
docker exec kaniko-runner /kaniko-executor --help

# Test build capability
docker exec kaniko-runner kaniko-build.sh --help
```