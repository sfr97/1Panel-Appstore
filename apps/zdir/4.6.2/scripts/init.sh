#!/usr/bin/env bash
set -e

: "${ZDIR_DATA_DIR:=./data}"

mkdir -p "${ZDIR_DATA_DIR}"
chmod 755 "${ZDIR_DATA_DIR}"

echo "[OK] data dir prepared: ${ZDIR_DATA_DIR}"
