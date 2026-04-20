# STAGE 1: Build binary
FROM golang:1.24-alpine AS builder

# Cài đặt git và ca-certificates ở stage builder (thường ổn định hơn)
RUN apk add --no-cache git ca-certificates

WORKDIR /build

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -v -o minio main.go

# STAGE 2: Tạo image chạy thực tế
FROM alpine:3.19

# Thay vì RUN apk add, ta COPY từ stage builder đã cài sẵn
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Copy file binary và script entrypoint
COPY --from=builder /build/minio /usr/bin/minio
COPY --from=builder /build/dockerscripts/docker-entrypoint.sh /usr/bin/docker-entrypoint.sh

RUN chmod +x /usr/bin/minio /usr/bin/docker-entrypoint.sh

EXPOSE 9000 9001

ENTRYPOINT ["/usr/bin/docker-entrypoint.sh"]

VOLUME ["/data"]

CMD ["minio", "server", "/data", "--console-address", ":9001"]