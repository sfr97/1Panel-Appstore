#!/bin/sh
set -eu

APP_DIR="${PWD}/data/zjmf"

mkdir -p "${APP_DIR}"

echo "Prepared 1Panel persistent directory: ${APP_DIR}"
echo "ZJMF source seeding and config.php generation will run in the application container startup wrapper."