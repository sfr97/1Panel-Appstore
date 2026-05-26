#!/bin/bash
set -e

mkdir -p ./data/netbird

echo "[NetBird Client] data dir prepared: $(pwd)/data/netbird"

if [ ! -c /dev/net/tun ]; then
  echo "[NetBird Client] WARNING: /dev/net/tun 不存在，某些环境下客户端可能无法正常建立隧道。"
fi
