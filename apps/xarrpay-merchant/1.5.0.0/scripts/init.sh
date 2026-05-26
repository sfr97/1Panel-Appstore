#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
APP_DIR=$(dirname "$SCRIPT_DIR")
ENV_FILE="$APP_DIR/.env"
DATA_ROOT="$APP_DIR/data"
APP_MOUNT_DIR="$DATA_ROOT/xarrpay-merchant"
PROJECT_CONFIG_YML="$APP_DIR/config/config.yml"
PROJECT_CONFIG_YAML="$APP_DIR/config/config.yaml"
MOUNT_CONFIG_DIR="$APP_MOUNT_DIR/config"
MOUNT_CONFIG_YML="$MOUNT_CONFIG_DIR/config.yml"
MOUNT_CONFIG_YAML="$MOUNT_CONFIG_DIR/config.yaml"

generate_mac() {
  set -- $(od -An -N6 -tx1 /dev/urandom)
  first=$(printf '%02x' "$(( (0x$1 & 254) | 2 ))")
  printf '%s:%s:%s:%s:%s:%s\n' "$first" "$2" "$3" "$4" "$5" "$6"
}

mkdir -p "$APP_MOUNT_DIR" "$MOUNT_CONFIG_DIR"

if [ -f "$PROJECT_CONFIG_YML" ] && [ ! -f "$MOUNT_CONFIG_YML" ]; then
  cp -a "$PROJECT_CONFIG_YML" "$MOUNT_CONFIG_YML"
fi

if [ -f "$PROJECT_CONFIG_YAML" ] && [ ! -f "$MOUNT_CONFIG_YAML" ]; then
  cp -a "$PROJECT_CONFIG_YAML" "$MOUNT_CONFIG_YAML"
fi

if [ ! -f "$ENV_FILE" ]; then
  : > "$ENV_FILE"
fi

if grep -q '^PANEL_APP_MAC_ADDRESS=' "$ENV_FILE"; then
  first_mac=$(grep -m 1 '^PANEL_APP_MAC_ADDRESS=' "$ENV_FILE")
  tmp_file="${ENV_FILE}.tmp.$$"
  awk '
    BEGIN { kept = 0 }
    /^PANEL_APP_MAC_ADDRESS=/ {
      if (kept == 0) {
        print
        kept = 1
      }
      next
    }
    { print }
  ' "$ENV_FILE" > "$tmp_file"
  mv "$tmp_file" "$ENV_FILE"
  printf '%s\n' "$first_mac"
else
  PANEL_APP_MAC_ADDRESS=$(generate_mac)
  printf '\nPANEL_APP_MAC_ADDRESS=%s\n' "$PANEL_APP_MAC_ADDRESS" >> "$ENV_FILE"
  printf 'PANEL_APP_MAC_ADDRESS=%s\n' "$PANEL_APP_MAC_ADDRESS"
fi
