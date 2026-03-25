#!/usr/bin/env bash
set -euo pipefail

# GitHub Actions Self-Hosted Runner 설치 스크립트
# 사용법: sudo bash scripts/install-runner.sh <GITHUB_PAT> <REPO_OWNER> <REPO_NAME>

if [ $# -lt 3 ]; then
    echo "사용법: $0 <GITHUB_PAT> <REPO_OWNER> <REPO_NAME>"
    echo "예시: $0 ghp_xxxx npdia agentbot-server"
    exit 1
fi

GITHUB_PAT="$1"
REPO_OWNER="$2"
REPO_NAME="$3"
RUNNER_DIR="/opt/actions-runner"
RUNNER_USER="runner"

echo "=== GitHub Actions Self-Hosted Runner 설치 ==="

# 1. runner 사용자 생성
if ! id "$RUNNER_USER" &>/dev/null; then
    useradd -m -s /bin/bash "$RUNNER_USER"
    usermod -aG docker "$RUNNER_USER"
    echo "runner 사용자 생성 완료"
fi

# 2. Runner 다운로드
mkdir -p "$RUNNER_DIR"
cd "$RUNNER_DIR"

RUNNER_VERSION=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | grep -oP '"tag_name": "v\K[^"]+')
RUNNER_ARCH="linux-x64"
RUNNER_FILE="actions-runner-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz"

if [ ! -f ".runner" ]; then
    echo "Runner v${RUNNER_VERSION} 다운로드 중..."
    curl -sL "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/${RUNNER_FILE}" -o "$RUNNER_FILE"
    tar xzf "$RUNNER_FILE"
    rm -f "$RUNNER_FILE"
fi

# 3. Registration token 발급
echo "Registration token 발급 중..."
REG_TOKEN=$(curl -s -X POST \
    -H "Authorization: token ${GITHUB_PAT}" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/actions/runners/registration-token" \
    | grep -oP '"token": "\K[^"]+')

if [ -z "$REG_TOKEN" ]; then
    echo "Error: Registration token 발급 실패. PAT 권한을 확인하세요."
    exit 1
fi

# 4. Runner 등록
chown -R "$RUNNER_USER":"$RUNNER_USER" "$RUNNER_DIR"

sudo -u "$RUNNER_USER" ./config.sh \
    --url "https://github.com/${REPO_OWNER}/${REPO_NAME}" \
    --token "$REG_TOKEN" \
    --name "agentbot-prod" \
    --labels "self-hosted,linux,x64,production" \
    --unattended \
    --replace

# 5. systemd 서비스 등록
./svc.sh install "$RUNNER_USER"
./svc.sh start

echo ""
echo "=== Runner 설치 완료 ==="
echo "이름: agentbot-prod"
echo "라벨: self-hosted, linux, x64, production"
echo "상태 확인: ./svc.sh status"
