#!/usr/bin/env bash
set -euo pipefail

echo "=== Agent Server Setup ==="

# 1. 시스템 업데이트
echo "[1/6] 시스템 업데이트..."
apt-get update && apt-get upgrade -y

# 2. Docker 설치
echo "[2/6] Docker 설치..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com | sh
    echo "Docker 설치 완료"
else
    echo "Docker 이미 설치됨"
fi
systemctl enable --now docker

# Docker Compose plugin 확인
if ! docker compose version &> /dev/null; then
    apt-get install -y docker-compose-plugin
fi

# 3. Nginx 설치 및 설정
echo "[3/6] Nginx 설치 및 설정..."
apt-get install -y nginx apache2-utils

# htpasswd 생성 (비밀번호는 수동 입력)
if [ ! -f /etc/nginx/.htpasswd ]; then
    echo "htpasswd 파일 생성 - 사용자명과 비밀번호를 입력하세요:"
    read -rp "Username: " HTUSER
    htpasswd -c /etc/nginx/.htpasswd "$HTUSER"
fi

# Self-signed cert for 443 catch-all
echo "[4/6] SSL dummy cert 생성..."
mkdir -p /etc/nginx/ssl
if [ ! -f /etc/nginx/ssl/dummy.crt ]; then
    openssl req -x509 -nodes -days 3650 \
        -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/dummy.key \
        -out /etc/nginx/ssl/dummy.crt \
        -subj "/CN=localhost"
fi

# Nginx 설정 복사
cp "$(dirname "$0")/../nginx/default.conf" /etc/nginx/sites-available/default
nginx -t && systemctl reload nginx
echo "Nginx 설정 완료"

# 5. .env 파일 확인
echo "[5/6] 환경 변수 확인..."
REPO_DIR="$(dirname "$0")/.."
if [ ! -f "$REPO_DIR/.env" ]; then
    echo ".env 파일이 없습니다. .env.example을 참고하여 생성하세요:"
    echo "  cp .env.example .env && vi .env"
    exit 1
fi

# 6. OpenHands 컨테이너 실행
echo "[6/6] OpenHands 컨테이너 실행..."
mkdir -p /opt/workspace
cd "$REPO_DIR"
docker compose up -d

echo ""
echo "=== 설정 완료 ==="
echo "접속: http://152.42.216.185 (ID/PW 인증 필요)"
