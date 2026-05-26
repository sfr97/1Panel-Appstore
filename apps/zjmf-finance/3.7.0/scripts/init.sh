#!/bin/sh
set -eu

APP_DIR="${PWD}/data/zjmf-finance"
SESSION_DIR="${PWD}/data/session"

mkdir -p "${APP_DIR}" "${SESSION_DIR}"
chmod 777 "${SESSION_DIR}" || true

echo "Prepared 1Panel persistent directory: ${APP_DIR}"
echo "Prepared PHP session directory: ${SESSION_DIR} (chmod 777)"
echo "ZJMF Finance source seeding and install page prefill will run in the application container startup wrapper."
