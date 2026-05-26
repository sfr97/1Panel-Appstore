#!/bin/sh
set -eu

APP_DIR="${APP_DIR:-/app}"
APP_SRC_DIR="${APP_SRC_DIR:-/opt/xarrpay-merchant}"
APP_BIN_NAME="${APP_BIN_NAME:-xarr-pay-merchant}"
APP_BIN="${APP_DIR}/${APP_BIN_NAME}"
SESSION_DIR="${SESSION_DIR:-/tmp/session}"
CORE_ITEMS="${CORE_ITEMS:-xarr-pay-merchant xarr-pay-merchant.md5 plugins templates}"
WRITABLE_DIRS="${WRITABLE_DIRS:-data config public runtime uploads}"
FORCE_INIT="${FORCE_INIT:-0}"
FIX_PERMISSIONS="${FIX_PERMISSIONS:-1}"

log() {
  echo "[start] $*"
}

warn() {
  echo "[start] WARN: $*" >&2
}

die() {
  echo "[start] ERROR: $*" >&2
  exit 1
}

has_content() {
  [ -d "$1" ] && [ -n "$(ls -A "$1" 2>/dev/null)" ]
}

copy_item_if_missing() {
  item="$1"
  src="${APP_SRC_DIR}/${item}"
  dst="${APP_DIR}/${item}"

  [ -e "$src" ] || return 0

  if [ ! -e "$dst" ] || [ "$FORCE_INIT" = "1" ]; then
    log "initializing ${item}"
    rm -rf "$dst"
    cp -a "$src" "$APP_DIR/"
  fi
}

copy_dir_defaults() {
  dir="$1"
  src="${APP_SRC_DIR}/${dir}"
  dst="${APP_DIR}/${dir}"

  mkdir -p "$dst"
  [ -d "$src" ] || return 0

  if [ "$FORCE_INIT" = "1" ]; then
    log "refreshing ${dir}"
    find "$dst" -mindepth 1 -exec rm -rf {} + 2>/dev/null || true
    cp -a "${src}/." "$dst/"
    return 0
  fi

  if ! has_content "$dst"; then
    log "initializing empty ${dir}"
    cp -a "${src}/." "$dst/"
  else
    log "${dir} already has content, copying missing defaults"
    cp -an "${src}/." "$dst/" 2>/dev/null || true
  fi
}

initialize_app_dir() {
  [ -d "$APP_SRC_DIR" ] || die "source directory not found: ${APP_SRC_DIR}"

  mkdir -p "$APP_DIR"

  if [ "$FORCE_INIT" = "1" ]; then
    log "FORCE_INIT=1, refreshing ${APP_DIR}"
    find "$APP_DIR" -mindepth 1 -exec rm -rf {} + 2>/dev/null || true
    cp -a "${APP_SRC_DIR}/." "$APP_DIR/"
    return 0
  fi

  if ! has_content "$APP_DIR"; then
    log "${APP_DIR} is empty, copying bundled application"
    cp -a "${APP_SRC_DIR}/." "$APP_DIR/"
    return 0
  fi

  log "${APP_DIR} already has content, filling missing files"
  for item in $CORE_ITEMS; do
    copy_item_if_missing "$item"
  done

  for dir in $WRITABLE_DIRS; do
    copy_dir_defaults "$dir"
  done
}

apply_tree_mode() {
  target="$1"
  dir_mode="$2"
  file_mode="$3"

  [ -e "$target" ] || return 0
  [ "$FIX_PERMISSIONS" = "1" ] || return 0

  if [ -d "$target" ]; then
    find "$target" -type d -exec chmod "$dir_mode" {} + 2>/dev/null || warn "failed to chmod directories under ${target}"
    find "$target" -type f -exec chmod "$file_mode" {} + 2>/dev/null || warn "failed to chmod files under ${target}"
  else
    chmod "$file_mode" "$target" 2>/dev/null || warn "failed to chmod file ${target}"
  fi
}

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

normalize_bool() {
  case $(printf '%s' "$1" | tr '[:upper:]' '[:lower:]') in
    1|true|yes|on)
      printf 'true'
      ;;
    0|false|no|off)
      printf 'false'
      ;;
    *)
      printf '%s' "$1"
      ;;
  esac
}

yaml_quote() {
  escaped=$(printf '%s' "$1" | sed "s/'/''/g")
  printf "'%s'" "$escaped"
}

require_value() {
  var_name="$1"
  var_value="$2"
  if [ -z "$var_value" ]; then
    echo "Missing required value: $var_name" >&2
    exit 1
  fi
}

get_env() {
  key="$1"
  default_value="$2"
  eval "raw_value=\${$key:-}"
  cleaned_value=$(clean_value "$raw_value")
  if [ -n "$cleaned_value" ]; then
    printf '%s' "$cleaned_value"
  else
    printf '%s' "$default_value"
  fi
}

write_config() {
  DB_TYPE=$(printf '%s' "$(get_env PANEL_DB_TYPE 'mysql')" | tr '[:upper:]' '[:lower:]')
  DB_HOST=$(get_env PANEL_DB_HOST '')
  DB_NAME=$(get_env PANEL_DB_NAME 'xarr')
  DB_USER=$(get_env PANEL_DB_USER 'xarr')
  DB_PASSWORD=$(get_env PANEL_DB_USER_PASSWORD '')
  REDIS_HOST=$(get_env PANEL_REDIS_HOST '')
  REDIS_PORT=$(get_env PANEL_REDIS_PORT '')
  REDIS_PASSWORD=$(get_env PANEL_REDIS_ROOT_PASSWORD '')
  LOGGER_LEVEL=$(get_env APP_LOGGER_LEVEL 'all')
  LOGGER_STDOUT=$(normalize_bool "$(get_env APP_LOGGER_STDOUT 'true')")
  DB_LOGGER_LEVEL=$(get_env APP_DATABASE_LOGGER_LEVEL 'PROD')
  DB_LOGGER_STDOUT=$(normalize_bool "$(get_env APP_DATABASE_LOGGER_STDOUT 'true')")
  DB_DEBUG=$(normalize_bool "$(get_env APP_DATABASE_DEBUG 'true')")

  case "$DB_TYPE" in
    postgresql|pgsql|postgres)
      DB_DRIVER='pgsql'
      DB_PORT='5432'
      DB_QUERY='?sslmode=disable'
      ;;
    mariadb|mysql)
      DB_DRIVER='mysql'
      DB_PORT='3306'
      DB_QUERY='?charset=utf8mb4'
      ;;
    *)
      echo "Unsupported PANEL_DB_TYPE: $DB_TYPE" >&2
      exit 1
      ;;
  esac

  if [ -n "$REDIS_HOST" ] && [ -z "$REDIS_PORT" ]; then
    REDIS_PORT='6379'
  fi

  require_value 'PANEL_DB_HOST' "$DB_HOST"
  require_value 'PANEL_DB_NAME' "$DB_NAME"
  require_value 'PANEL_DB_USER' "$DB_USER"
  require_value 'PANEL_DB_USER_PASSWORD' "$DB_PASSWORD"

  mkdir -p "$APP_DIR/config"

  DB_LINK="$DB_DRIVER:$DB_USER:$DB_PASSWORD@tcp($DB_HOST:$DB_PORT)/$DB_NAME$DB_QUERY"
  DB_LINK_YAML=$(yaml_quote "$DB_LINK")
  LOGGER_LEVEL_YAML=$(yaml_quote "$LOGGER_LEVEL")
  DB_LOGGER_LEVEL_YAML=$(yaml_quote "$DB_LOGGER_LEVEL")
  CONFIG_YAML="$APP_DIR/config/config.yaml"
  CONFIG_YML="$APP_DIR/config/config.yml"

  cat > "$CONFIG_YAML" <<EOF
server:
  address: ":32000"

logger:
  level: $LOGGER_LEVEL_YAML
  stdout: $LOGGER_STDOUT

database:
  logger:
    level: $DB_LOGGER_LEVEL_YAML
    stdout: $DB_LOGGER_STDOUT

  default:
    link: $DB_LINK_YAML
    debug: $DB_DEBUG
EOF

  if [ -n "$REDIS_HOST" ]; then
    REDIS_ADDRESS_YAML=$(yaml_quote "$REDIS_HOST:$REDIS_PORT")
    cat >> "$CONFIG_YAML" <<EOF

redis:
  default:
    address: $REDIS_ADDRESS_YAML
    db: 0
EOF
    if [ -n "$REDIS_PASSWORD" ]; then
      REDIS_PASSWORD_YAML=$(yaml_quote "$REDIS_PASSWORD")
      cat >> "$CONFIG_YAML" <<EOF
    pass: $REDIS_PASSWORD_YAML
EOF
    fi
  fi

  if [ ! -f "$CONFIG_YML" ]; then
    cp -a "$CONFIG_YAML" "$CONFIG_YML"
  fi
}

mkdir -p "$SESSION_DIR"
chmod 1777 "$SESSION_DIR" 2>/dev/null || true

initialize_app_dir
write_config

[ -f "$APP_BIN" ] || die "binary not found: ${APP_BIN}"
chmod +x "$APP_BIN" 2>/dev/null || warn "failed to chmod binary: ${APP_BIN}"

[ -e "$APP_DIR/plugins" ] && apply_tree_mode "$APP_DIR/plugins" 755 644
[ -e "$APP_DIR/templates" ] && apply_tree_mode "$APP_DIR/templates" 755 644
for dir in $WRITABLE_DIRS; do
  apply_tree_mode "$APP_DIR/$dir" 775 664
done

cd "$APP_DIR"
exec "$APP_BIN"
