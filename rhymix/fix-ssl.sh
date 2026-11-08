#!/bin/sh
# Run once as root in DSM Task Scheduler.
set -eu
umask 077
PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
export PATH
APP_DIR=/volume1/docker/palangshim/rhymix
CORE="$APP_DIR/www/classes/context/Context.class.php"
WEB=palangshim-rhymix-web-1
if [ "$(id -u)" != 0 ]; then echo "Run as root." >&2; exit 1; fi
if [ ! -f "$CORE" ]; then echo "Rhymix Context file is missing." >&2; exit 1; fi
mkdir -p "$APP_DIR/.repair-backups"
BACKUP_DIR=$(mktemp -d "$APP_DIR/.repair-backups/ssl.XXXXXX")
cp -p "$CORE" "$BACKUP_DIR/Context.class.php"
SUCCESS=false
cleanup() {
  CODE=$?
  trap - EXIT HUP INT TERM
  if [ "$SUCCESS" != true ]; then
    cp -p "$BACKUP_DIR/Context.class.php" "$CORE"
    echo "Patch failed; original restored from $BACKUP_DIR." >&2
  fi
  exit "$CODE"
}
trap cleanup EXIT
trap 'exit 1' HUP INT TERM
docker exec -i "$WEB" php <<'PHP'
<?php
$file = '/var/www/html/classes/context/Context.class.php';
$source = file_get_contents($file);
if ($source === false) { fwrite(STDERR, "Cannot read Context file.\n"); exit(1); }
$old = "return self::get('_use_ssl');";
$new = "return self::get('_use_ssl') ?? (RX_SSL ? 'always' : 'none');";
if (str_contains($source, $new)) { echo "SSL fallback is already applied.\n"; exit(0); }
if (substr_count($source, $old) !== 1) {
    fwrite(STDERR, "Unexpected core version; no changes made.\n"); exit(1);
}
if (file_put_contents($file, str_replace($old, $new, $source), LOCK_EX) === false) {
    fwrite(STDERR, "Cannot write Context file.\n"); exit(1);
}
PHP
docker exec "$WEB" php -l /var/www/html/classes/context/Context.class.php
SUCCESS=true
docker restart "$WEB"
echo "SSL fallback applied. Backup: $BACKUP_DIR. Reload the website and continue installation."
