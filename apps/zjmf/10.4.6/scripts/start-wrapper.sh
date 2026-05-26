#!/bin/sh
set -eu

APP_DIR="${APP_DIR:-/var/www/html}"
APP_SEED_DIR="${APP_SEED_DIR:-/opt/zjmf-seed}"
INSTALL_INDEX="${APP_DIR}/public/install/index.html"
INSTALL_JS="${APP_DIR}/public/install/js/install.js"
INSTALL_PHP="${APP_DIR}/public/install/install.php"
CACHE_BUST="$(date +%s)"

is_effectively_empty_dir() {
    [ -d "$1" ] || return 0
    [ -z "$(find "$1" -mindepth 1 -maxdepth 1 ! -name 'lost+found' -print -quit 2>/dev/null)" ]
}

mkdir -p "${APP_DIR}"

if [ -f "${APP_SEED_DIR}/public/index.php" ] && is_effectively_empty_dir "${APP_DIR}"; then
    echo "Initializing ZJMF application files into ${APP_DIR}"
    cp -a "${APP_SEED_DIR}/." "${APP_DIR}/"
fi

if [ -f "${INSTALL_INDEX}" ]; then
    sed -i "s#\./api/install\.js[^\"]*#./api/install.js?v=${CACHE_BUST}#g; s#\./js/install\.js[^\"]*#./js/install.js?v=${CACHE_BUST}#g" "${INSTALL_INDEX}"
fi

if [ -f "${APP_DIR}/config.php" ] && [ -f "${APP_DIR}/public/install/install.php" ]; then
    echo "Detected existing /var/www/html/config.php while installer assets still exist."
    echo "If this is a stale file from an older app template, remove ./data/zjmf/config.php and restart to re-enter the installer."
fi

if [ ! -f "${APP_DIR}/config.php" ] && [ -f "${INSTALL_JS}" ]; then
    echo "Installer defaults from 1Panel: host=${PANEL_DB_HOST:-<empty>} db=${PANEL_DB_NAME:-<empty>} user=${PANEL_DB_USER:-<empty>} port=${PANEL_DB_PORT:-<empty>} admin_dir=${PANEL_ADMIN_DIR:-<empty>}"
    APP_DIR="${APP_DIR}" php <<'PHP'
<?php
$stderr = fopen('php://stderr', 'w');
$dir = getenv('APP_DIR') ?: '/var/www/html';
$installJs = $dir . '/public/install/js/install.js';
$installPhp = $dir . '/public/install/install.php';

$writeLog = static function (string $message) use ($stderr): void {
    if (is_resource($stderr)) {
        fwrite($stderr, $message . PHP_EOL);
    }
};

$setJsDefault = static function (string $content, string $field, string $value): string {
    $replacement = sprintf('%s: "%s"', $field, addslashes($value));
    return preg_replace('/' . preg_quote($field, '/') . ':\s*"[^"]*"/', $replacement, $content, 1) ?? $content;
};

if (is_file($installJs)) {
    $content = file_get_contents($installJs);
    if ($content !== false) {
        $content = $setJsDefault($content, 'hostname', getenv('PANEL_DB_HOST') ?: '127.0.0.1');
        $content = $setJsDefault($content, 'dbname', getenv('PANEL_DB_NAME') ?: '');
        $content = $setJsDefault($content, 'username', getenv('PANEL_DB_USER') ?: '');
        $content = $setJsDefault($content, 'password', getenv('PANEL_DB_USER_PASSWORD') ?: '');
        $content = $setJsDefault($content, 'hostport', getenv('PANEL_DB_PORT') ?: '3306');
        file_put_contents($installJs, $content);
        $writeLog('Prepared installer database defaults from 1Panel values');
    }
}

if (is_file($installPhp)) {
    $content = file_get_contents($installPhp);
    if ($content !== false) {
        $updated = $content;

        if ((getenv('PANEL_ADMIN_DIR') ?: '') !== '' && strpos($updated, "getenv('PANEL_ADMIN_DIR')") === false) {
            $search = '$admin_application = strtolower($this->randStr(8, \'CHAR\'));';
            $replace = '$admin_application = getenv(\'PANEL_ADMIN_DIR\') ?: strtolower($this->randStr(8, \'CHAR\'));';
            $updated = str_replace($search, $replace, $updated);
        }

        if (strpos($updated, '$basePath = preg_replace(\'#/install/install\\.php.*$#\'') === false) {
            $search = '$domain = $server_http.$domain;';
            $replace = '$basePath = preg_replace(\'#/install/install\\.php.*$#\', \'\', $_SERVER[\'REQUEST_URI\'] ?? \'\');' . "\n        "
                . '$basePath = rtrim($basePath, \'/\');' . "\n        "
                . '$domain = $server_http.$domain.$basePath;';
            $updated = str_replace($search, $replace, $updated);

            $search = '$data[\'admin_url\'] = $server_http.$domain.\'/\'.$this->getSession(\'install_db_config\')[\'admin_application\'];';
            $replace = '$basePath = preg_replace(\'#/install/install\\.php.*$#\', \'\', $_SERVER[\'REQUEST_URI\'] ?? \'\');' . "\n            "
                . '$basePath = rtrim($basePath, \'/\');' . "\n            "
                . '$data[\'admin_url\'] = $server_http.$domain.$basePath.\'/\'.$this->getSession(\'install_db_config\')[\'admin_application\'];';
            $updated = str_replace($search, $replace, $updated);
        }

        if ($updated !== $content) {
            file_put_contents($installPhp, $updated);
            $writeLog('Patched installer admin directory and reverse-proxy base path handling');
        }
    }
}
PHP
fi

unset PANEL_DB_TYPE PANEL_DB_HOST PANEL_DB_PORT PANEL_DB_CHARSET PANEL_DB_NAME PANEL_DB_USER PANEL_DB_USER_PASSWORD PANEL_ADMIN_DIR
exec /usr/local/bin/zjmf-entrypoint supervisord -c /etc/supervisor/conf.d/supervisord.conf