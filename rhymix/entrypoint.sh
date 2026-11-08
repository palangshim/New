#!/bin/sh
set -eu
if [ ! -f /var/www/html/index.php ]; then
  cp -a /usr/src/rhymix/. /var/www/html/
fi
mkdir -p /var/www/html/files
chown www-data:www-data /var/www/html/files
exec docker-php-entrypoint "$@"
