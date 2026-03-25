#!/usr/bin/env bash
set -euo pipefail

# Self-Hosted Runner를 repo 레벨 → org 레벨로 재등록
# 사용법: sudo bash scripts/upgrade-runner-to-org.sh <GITHUB_PAT> <ORG_NAME>

if [ $# -lt 2 ]; then
    echo "사용법: $0 <GITHUB_PAT> <ORG_NAME>"
    echo "예시: $0 ghp_xxxx NPDIA"
    exit 1
fi

GITHUB_PAT="$1"
ORG_NAME="$2"
RUNNER_DIR="/opt/actions-runner"
RUNNER_USER="runner"

echo "=== Runner → Organization 레벨 재등록 ==="

cd "$RUNNER_DIR"

# 1. 기존 서비스 중지
echo "[1/4] 기존 서비스 중지..."
./svc.sh stop
./svc.sh uninstall

# 2. 기존 등록 제거
echo "[2/4] 기존 repo 등록 제거..."
REMOVE_TOKEN=$(curl -s -X POST \
    -H "Authorization: token ${GITHUB_PAT}" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/repos/${ORG_NAME}/agentbot-server/actions/runners/remove-token" \
    | grep -oP '"token": "\K[^"]+')

sudo -u "$RUNNER_USER" ./config.sh remove --token "$REMOVE_TOKEN" || true

# 3. Org 레벨 Registration token 발급
echo "[3/4] Org 레벨 등록..."
ORG_REG_TOKEN=$(curl -s -X POST \
    -H "Authorization: token ${GITHUB_PAT}" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/orgs/${ORG_NAME}/actions/runners/registration-token" \
    | grep -oP '"token": "\K[^"]+')

if [ -z "$ORG_REG_TOKEN" ]; then
    echo "Error: Org registration token 발급 실패."
    echo "PAT에 admin:org 또는 manage_runners:org 권한이 필요합니다."
    exit 1
fi

sudo -u "$RUNNER_USER" ./config.sh \
    --url "https://github.com/${ORG_NAME}" \
    --token "$ORG_REG_TOKEN" \
    --name "agentbot-prod" \
    --labels "self-hosted,linux,x64,production" \
    --unattended \
    --replace

# 4. 서비스 재등록
echo "[4/4] 서비스 재등록..."
./svc.sh install "$RUNNER_USER"
./svc.sh start

echo ""
echo "=== 완료 ==="
echo "Runner가 ${ORG_NAME} org 레벨로 등록되었습니다."
echo "이제 org 내 모든 repo에서 runs-on: [self-hosted, production] 사용 가능"
