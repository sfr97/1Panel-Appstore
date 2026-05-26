#!/bin/sh
set -eu

APP_DIR="${APP_DIR:-/var/www/html}"
APP_SEED_DIR="${APP_SEED_DIR:-/opt/zjmf-finance-seed}"
SESSION_DIR="${SESSION_DIR:-/tmp/session}"
INSTALL_HTML="${APP_DIR}/public/install.html"

is_effectively_empty_dir() {
    [ -d "$1" ] || return 0
    [ -z "$(find "$1" -mindepth 1 -maxdepth 1 ! -name 'lost+found' -print -quit 2>/dev/null)" ]
}

ensure_session_dir() {
    mkdir -p "${SESSION_DIR}"
    chmod 777 "${SESSION_DIR}" || true
    if [ -d /tmp/session ] && [ "${SESSION_DIR}" != "/tmp/session" ]; then
        chmod 777 /tmp/session || true
    fi
    echo "Prepared PHP session directory: ${SESSION_DIR}"
}

start_main_process() {
    if [ -x /usr/local/bin/zjmf-finance-entrypoint ]; then
        exec /usr/local/bin/zjmf-finance-entrypoint supervisord -c /etc/supervisor/conf.d/supervisord.conf
    fi

    if command -v supervisord >/dev/null 2>&1; then
        exec supervisord -c /etc/supervisor/conf.d/supervisord.conf
    fi

    if [ -x /usr/bin/supervisord ]; then
        exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
    fi

    if [ -x /usr/local/bin/supervisord ]; then
        exec /usr/local/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
    fi

    echo "Error: cannot find zjmf-finance-entrypoint or supervisord in the image." >&2
    echo "Please check whether the new image still bundles Supervisor and the original startup command." >&2
    exit 1
}

mkdir -p "${APP_DIR}"
ensure_session_dir

if [ -f "${APP_SEED_DIR}/public/index.php" ] && is_effectively_empty_dir "${APP_DIR}"; then
    echo "Initializing ZJMF Finance application files into ${APP_DIR}"
    cp -a "${APP_SEED_DIR}/." "${APP_DIR}/"
fi

if [ -f "${APP_DIR}/config.php" ] && [ -f "${INSTALL_HTML}" ]; then
    echo "Detected existing ${APP_DIR}/config.php while install page still exists."
    echo "If this is a stale file from an older app template, remove ./data/zjmf-finance/config.php and restart to re-enter the installer."
fi

if [ ! -f "${APP_DIR}/config.php" ] && [ -f "${INSTALL_HTML}" ]; then
    echo "Installer defaults from 1Panel: host=${PANEL_DB_HOST:-<empty>} db=${PANEL_DB_NAME:-<empty>} user=${PANEL_DB_USER:-<empty>} port=${PANEL_DB_PORT:-<empty>} admin_dir=${PANEL_ADMIN_DIR:-<empty>}"
    APP_DIR="${APP_DIR}" php <<'PHP'
<?php
$stderr = fopen('php://stderr', 'w');
$dir = getenv('APP_DIR') ?: '/var/www/html';
$installHtml = $dir . '/public/install.html';

$writeLog = static function (string $message) use ($stderr): void {
    if (is_resource($stderr)) {
        fwrite($stderr, $message . PHP_EOL);
    }
};

if (!is_file($installHtml)) {
    exit(0);
}

$content = file_get_contents($installHtml);
if ($content === false) {
    $writeLog('Unable to read install.html, skipping installer prefill');
    exit(0);
}

$replaceFirst = static function (string $html, string $default, string $value): string {
    $safe = htmlspecialchars($value, ENT_QUOTES, 'UTF-8');
    $result = preg_replace(
        '/value="' . preg_quote($default, '/') . '" class="databaseFiv"/',
        'value="' . $safe . '" class="databaseFiv"',
        $html,
        1
    );

    return is_string($result) ? $result : $html;
};

$content = $replaceFirst($content, 'localhost', getenv('PANEL_DB_HOST') ?: 'localhost');
$content = $replaceFirst($content, '3306', getenv('PANEL_DB_PORT') ?: '3306');
$content = $replaceFirst($content, 'username', getenv('PANEL_DB_USER') ?: 'username');
$content = $replaceFirst($content, 'password', getenv('PANEL_DB_USER_PASSWORD') ?: 'password');
$content = $replaceFirst($content, 'zjmfmanger', getenv('PANEL_DB_NAME') ?: 'zjmfmanger');

$adminDir = getenv('PANEL_ADMIN_DIR') ?: 'admin';
$safeAdminDir = htmlspecialchars($adminDir, ENT_QUOTES, 'UTF-8');
$replaced = preg_replace(
    '/id="htlj"[^>]*value="[^"]*"[^>]*class="inputList"/',
    'id="htlj" type="text" placeholder="Admin path" value="' . $safeAdminDir . '" class="inputList"',
    $content,
    1
);
if (is_string($replaced)) {
    $content = $replaced;
}

if (file_put_contents($installHtml, $content) === false) {
    $writeLog('Unable to write install.html, skipping installer prefill');
    exit(0);
}

$writeLog('Prepared install.html defaults from 1Panel values');
PHP
fi

unset PANEL_DB_TYPE PANEL_DB_HOST PANEL_DB_PORT PANEL_DB_CHARSET PANEL_DB_NAME PANEL_DB_USER PANEL_DB_USER_PASSWORD PANEL_ADMIN_DIR
start_main_process
