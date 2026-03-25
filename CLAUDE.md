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

- **방식**: GitHub Actions (Self-Hosted Runner) → main push 시 자동 배포
- **워크플로우**: `.github/workflows/deploy.yml`
- **Runner**: `agentbot-prod` (라벨: `self-hosted, production`)

## 설치 체크리스트

- [x] 서버 초기화 (Ubuntu 22.04 재설치)
- [x] Docker 설치
- [x] OpenHands 컨테이너 실행
- [x] Nginx 리버스 프록시 + htpasswd 인증 설정
- [x] 도메인 접근 차단 설정
- [ ] Self-Hosted Runner 설치
- [ ] GitHub 연동 (OpenHands WebUI)
- [x] Gemini API 키 등록
- [x] Anthropic API 키 등록
