#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
APP_DIR=$(dirname "$SCRIPT_DIR")
ENV_FILE="$APP_DIR/.env"
DATA_DIR="$APP_DIR/data/lskypro"
THEMES_DIR="$DATA_DIR/themes"

mkdir -p "$DATA_DIR" "$THEMES_DIR"

if [ ! -f "$ENV_FILE" ]; then
  : > "$ENV_FILE"
fi

clean_value() {
  value=$(printf '%s' "$1" | tr -d '\r')
  case "$value" in
    \"*\")
      value=${value#\"}
      value=${value%\"}
      ;;
    \'*\')
      value=${value#\'}
      value=${value%\'}
      ;;
  esac
  printf '%s' "$value"
}

get_env() {
  key="$1"
  default_value="$2"
  raw_value=$(grep -E "^${key}=" "$ENV_FILE" | tail -n 1 | sed "s/^${key}=//" || true)
  cleaned_value=$(clean_value "$raw_value")
  if [ -n "$cleaned_value" ]; then
    printf '%s' "$cleaned_value"
  else
    printf '%s' "$default_value"
  fi
}

quote_env_value() {
  escaped=$(printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\$/\\$/g')
  printf '"%s"' "$escaped"
}

upsert_env() {
  key="$1"
  value="$2"
  tmp_file=$(mktemp)
  quoted_value=$(quote_env_value "$value")
  awk -v key="$key" -v value="$quoted_value" '
    $0 ~ "^" key "=" {
      if (!done) {
        print key "=" value
        done = 1
      }
      next
    }
    { print }
    END {
      if (!done) {
        print key "=" value
      }
    }
  ' "$ENV_FILE" > "$tmp_file"
  mv "$tmp_file" "$ENV_FILE"
}

require_value() {
  key="$1"
  value="$2"
  if [ -z "$value" ]; then
    echo "Missing required value: $key" >&2
    exit 1
  fi
}

DB_TYPE=$(printf '%s' "$(get_env PANEL_DB_TYPE 'mysql')" | tr '[:upper:]' '[:lower:]')
DB_HOST=$(get_env PANEL_DB_HOST '')
DB_NAME=$(get_env PANEL_DB_NAME 'lsky')
DB_USER=$(get_env PANEL_DB_USER 'lsky')
DB_PASSWORD=$(get_env PANEL_DB_USER_PASSWORD '')
REDIS_HOST=$(get_env PANEL_REDIS_HOST '')
REDIS_PORT=$(get_env PANEL_REDIS_PORT '')
REDIS_PASSWORD=$(get_env PANEL_REDIS_ROOT_PASSWORD '')

case "$DB_TYPE" in
  postgresql|pgsql|postgres)
    DB_CONNECTION='pgsql'
    DEFAULT_DB_PORT='5432'
    ;;
  mysql|mariadb)
    DB_CONNECTION='mysql'
    DEFAULT_DB_PORT='3306'
    ;;
  *)
    echo "Unsupported PANEL_DB_TYPE: $DB_TYPE" >&2
    exit 1
    ;;
esac

DB_PORT="$DEFAULT_DB_PORT"

if [ -n "$REDIS_HOST" ] && [ -z "$REDIS_PORT" ]; then
  REDIS_PORT='6379'
fi

require_value 'PANEL_DB_HOST' "$DB_HOST"
require_value 'PANEL_DB_NAME' "$DB_NAME"
require_value 'PANEL_DB_USER' "$DB_USER"
require_value 'PANEL_DB_USER_PASSWORD' "$DB_PASSWORD"

upsert_env APP_ENV 'production'
upsert_env APP_DEBUG 'false'
upsert_env DB_CONNECTION "$DB_CONNECTION"
upsert_env DB_HOST "$DB_HOST"
upsert_env DB_PORT "$DB_PORT"
upsert_env DB_DATABASE "$DB_NAME"
upsert_env DB_USERNAME "$DB_USER"
upsert_env DB_PASSWORD "$DB_PASSWORD"

if [ -n "$REDIS_HOST" ]; then
  upsert_env CACHE_STORE 'redis'
  upsert_env REDIS_HOST "$REDIS_HOST"
  upsert_env REDIS_PORT "$REDIS_PORT"
  upsert_env REDIS_PASSWORD "$REDIS_PASSWORD"
  upsert_env SESSION_DRIVER 'redis'
  upsert_env SESSION_CONNECTION 'default'
  upsert_env QUEUE_CONNECTION 'redis'
else
  upsert_env CACHE_STORE 'file'
  upsert_env REDIS_HOST ''
  upsert_env REDIS_PORT ''
  upsert_env REDIS_PASSWORD ''
  upsert_env SESSION_DRIVER 'file'
  upsert_env SESSION_CONNECTION ''
  upsert_env QUEUE_CONNECTION 'sync'
fi
