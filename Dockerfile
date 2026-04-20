# STAGE 1: Build binary (Nâng cấp lên bản golang mới nhất)
FROM golang:1.24-alpine AS builder

WORKDIR /build

# Tải các thư viện phụ thuộc trước để tối ưu cache của Docker
COPY go.mod go.sum ./
RUN go mod download

# Copy toàn bộ source code
COPY . .

# Biên dịch mã nguồn
RUN CGO_ENABLED=0 GOOS=linux go build -v -o minio main.go

# STAGE 2: Tạo image chạy thực tế
FROM alpine:3.19

RUN apk add --no-cache ca-certificates

# Copy file binary và script entrypoint
COPY --from=builder /build/minio /usr/bin/minio
COPY --from=builder /build/dockerscripts/docker-entrypoint.sh /usr/bin/docker-entrypoint.sh

RUN chmod +x /usr/bin/minio /usr/bin/docker-entrypoint.sh

EXPOSE 9000 9001

ENTRYPOINT ["/usr/bin/docker-entrypoint.sh"]

VOLUME ["/data"]

CMD ["minio", "server", "/data", "--console-address", ":9001"]