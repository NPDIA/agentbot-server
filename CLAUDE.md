# Agent Server

## 서버 구성

| 용도 | IP | 비고 |
|------|-----|------|
| Agent / Production 예정 | 152.42.216.185 | DigitalOcean 싱가포르 / Ubuntu 22.04 |

## 에이전트 구성

- **WebUI**: OpenHands (포트 3000, Nginx 리버스 프록시)
- **LLM**: Gemini API 키 (PAYG 방식, OAuth 미사용)
- **인증**: ID/PW 로그인 방식 (외부 접근 차단)

## 접근 제어 규칙

- OpenHands WebUI는 ID/PW 인증 후에만 접근 가능
- IP 직접 접근만 허용
- 도메인을 통한 외부 접근 차단 (Nginx에서 444 반환)

## Nginx 설정

```nginx
# 도메인 접근 전체 차단
server {
    listen 80;
    listen 443 ssl;
    server_name _;
    return 444;
}

# OpenHands WebUI (IP 직접 접근만 허용)
server {
    listen 80;
    server_name 152.42.216.185;

    location / {
        auth_basic "Restricted";
        auth_basic_user_file /etc/nginx/.htpasswd;
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
    }
}
```

## 정책

- OAuth 토큰(`sk-ant-oat01-`) 사용 금지 — API 키 방식만 허용
- 불필요한 포트 외부 노출 금지
- DB 접속 정보 하드코딩 금지

## 배포

- **방식**: GitHub Actions (Self-Hosted Runner, Org 레벨) → main push 시 자동 배포
- **Runner**: `agentbot-prod` (라벨: `self-hosted, linux, x64, production`)
- **대상 레포**:

| Repo | CI | CD | 비고 |
|------|----|----|------|
| agentbot-server | - | deploy.yml | OpenHands 서버 관리 |
| mineral-community | ci.yml | cd.yml, cd-dev.yml, cd-staging.yml | 커뮤니티 플랫폼 |
| final_bot-upgraded | ci.yml | cd.yml | AI 자동 투자 봇 (Python/Flask) |
| lampad-qc-automator | ci.yml | cd.yml | QC 자동화 |

### Self-Hosted Runner 전환 가이드

기존 워크플로우에서 `runs-on` 변경:
```yaml
# Before (GitHub-hosted)
runs-on: ubuntu-latest

# After (Self-hosted)
runs-on: [self-hosted, production]
```

## 설치 체크리스트

- [x] 서버 초기화 (Ubuntu 22.04 재설치)
- [x] Docker 설치
- [x] OpenHands 컨테이너 실행
- [x] Nginx 리버스 프록시 + htpasswd 인증 설정
- [x] 도메인 접근 차단 설정
- [x] Self-Hosted Runner 설치 (repo 레벨)
- [ ] Self-Hosted Runner → Org 레벨 전환
- [ ] GitHub 연동 (OpenHands WebUI)
- [ ] 각 repo 워크플로우 runs-on 전환
- [ ] final_bot-upgraded CD 워크플로우 추가
- [x] Gemini API 키 등록
- [x] Anthropic API 키 등록
