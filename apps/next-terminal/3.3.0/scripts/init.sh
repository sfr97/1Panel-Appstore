#!/bin/bash
set -euo pipefail

APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# 关键：把 1Panel 生成的 .env 加载进脚本环境
if [ -f "${APP_DIR}/.env" ]; then
  set -a
  # shellcheck disable=SC1090
  source "${APP_DIR}/.env"
  set +a
fi

# 兜底（避免没填端口时直接炸）
: "${PANEL_DB_HOST:?missing PANEL_DB_HOST}"
: "${PANEL_DB_PORT:=5432}"
: "${PANEL_DB_USER:?missing PANEL_DB_USER}"
: "${PANEL_DB_USER_PASSWORD:?missing PANEL_DB_USER_PASSWORD}"
: "${PANEL_DB_NAME:?missing PANEL_DB_NAME}"

# 生成 next-terminal 的 config.yaml（你需要它才能连 PG）
cat > "${APP_DIR}/config.yaml" <<EOF
Database:
  Enabled: true
  Type: postgres
  Postgres:
    Hostname: ${PANEL_DB_HOST}
    Port: ${PANEL_DB_PORT}
    Username: ${PANEL_DB_USER}
    Password: ${PANEL_DB_USER_PASSWORD}
    Database: ${PANEL_DB_NAME}
  ShowSql: false

log:
  Level: info
  Filename: /usr/local/next-terminal/logs/nt.log

Server:
  Addr: "0.0.0.0:8088"

App:
  Website:
    AccessLog: "/usr/local/next-terminal/logs/access.log"
  Recording:
    Type: "local"
    Path: "/usr/local/next-terminal/data/recordings"
  Guacd:
    Drive: "/usr/local/next-terminal/data/drive"
    Hosts:
      - Hostname: guacd
        Port: 4822
        Weight: 1
  ReverseProxy:
    Enabled: false
    HttpEnabled: true
    HttpAddr: ":80"
    HttpRedirectToHttps: false
    HttpsEnabled: true
    HttpsAddr: ":443"
    SelfProxyEnabled: true
    SelfDomain: "nt.yourdomain.com"
    Root: ""
    IpExtractor: "direct"
    IpTrustList:
      - "0.0.0.0/0"
EOF

echo "✅ config.yaml generated: ${APP_DIR}/config.yaml"
