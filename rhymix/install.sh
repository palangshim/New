#!/bin/sh
# Run once as root from Synology DSM Task Scheduler.
set -eu
umask 077
PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
export PATH
APP_DIR=/volume1/docker/palangshim
INSTALL_DIR="$APP_DIR/rhymix"
mkdir -p "$APP_DIR"
if [ "$(id -u)" != 0 ]; then echo "Run this task as root." >&2; exit 1; fi
compose() {
  if docker compose version >/dev/null 2>&1; then
    docker compose -p palangshim-rhymix -f "$INSTALL_DIR/compose.yaml" "$@"
  else
    docker-compose -p palangshim-rhymix -f "$INSTALL_DIR/compose.yaml" "$@"
  fi
}
if ! mkdir "$APP_DIR/.github-update.lock" 2>/dev/null; then
  echo "Another update is running. Retry this task in two minutes." >&2
  exit 1
fi
TMP_DIR=
SWITCHING=false
SUCCESS=false
STOPPED_IDS=
cleanup() {
  CODE=$?
  trap - EXIT HUP INT TERM
  if [ "$SUCCESS" != true ] && [ "$SWITCHING" = true ]; then
    compose stop web || true
    for ID in $STOPPED_IDS; do docker start "$ID" || true; done
    rm -f "$APP_DIR/.rhymix-mode"
    echo "Rhymix start failed; attempted to restore the previous sample app." >&2
  fi
  if [ -n "$TMP_DIR" ]; then rm -rf "$TMP_DIR"; fi
  rmdir "$APP_DIR/.github-update.lock"
  exit "$CODE"
}
trap cleanup EXIT
trap 'exit 1' HUP INT TERM
show_info() {
  echo "Rhymix installation page is ready on the existing website address."
  echo "Database host: db"
  echo "Database port: 3306"
  echo "Database name: rhymix"
  echo "Database user: rhymix"
  printf "Database password: "
  sed -n 's/^DB_PASSWORD=//p' "$INSTALL_DIR/.env"
  echo "Create your administrator account in the browser. Do not share this task output."
}
# Re-running a completed installation never overwrites website files or passwords.
if [ -f "$INSTALL_DIR/.rhymix-ready" ]; then
  compose up -d
  show_info
  SUCCESS=true
  exit 0
fi
TMP_DIR=$(mktemp -d "$APP_DIR/.rhymix-setup.XXXXXX")
curl -fLsS --connect-timeout 15 --max-time 120 \
  https://codeload.github.com/palangshim/New/tar.gz/refs/heads/main -o "$TMP_DIR/repository.tar.gz"
tar -xzf "$TMP_DIR/repository.tar.gz" -C "$TMP_DIR" New-main/rhymix
mkdir -p "$INSTALL_DIR"
for FILE in Dockerfile entrypoint.sh compose.yaml .dockerignore; do
  cp "$TMP_DIR/New-main/rhymix/$FILE" "$INSTALL_DIR/$FILE"
done
if [ ! -f "$INSTALL_DIR/.env" ]; then
  if [ -d "$INSTALL_DIR/db/mysql" ]; then
    echo "An existing DB has no .env file. Restore its passwords before continuing." >&2
    exit 1
  fi
  DB_PASSWORD=$(od -An -N24 -tx1 /dev/urandom | tr -d ' \n')
  DB_ROOT_PASSWORD=$(od -An -N32 -tx1 /dev/urandom | tr -d ' \n')
  printf 'DB_PASSWORD=%s\nDB_ROOT_PASSWORD=%s\n' "$DB_PASSWORD" "$DB_ROOT_PASSWORD" > "$INSTALL_DIR/.env"
fi
chmod 600 "$INSTALL_DIR/.env"
mkdir -p "$INSTALL_DIR/www"
chmod 755 "$INSTALL_DIR/www"
curl -fLsS --connect-timeout 15 --max-time 180 \
  https://codeload.github.com/rhymix/rhymix/tar.gz/6234bfd2bc133286113421e8a525f38a9fa3eaf5 \
  -o "$INSTALL_DIR/rhymix.tar.gz"
(cd "$INSTALL_DIR" && printf '%s\n' '83bb89c45a3a188481aa390df1d41a473d8787e896fccfa5fde793748ea393f4  rhymix.tar.gz' | sha256sum -c -)
compose config >/dev/null
# Build and initialize DB before stopping the previous homepage.
compose build web
compose pull db
compose up -d db
DB_READY=false
for ATTEMPT in $(seq 1 90); do
  DB_ID=$(compose ps -q db)
  if [ -n "$DB_ID" ] && [ "$(docker inspect -f '{{.State.Health.Status}}' "$DB_ID")" = healthy ]; then
    DB_READY=true
    break
  fi
  sleep 2
done
if [ "$DB_READY" != true ]; then
  echo "Database startup failed. Check Container Manager logs for palangshim-rhymix." >&2
  exit 1
fi
# Only stop the known sample app, identified by its exact app.py bind mount.
PREVIOUS_IDS=
for ID in $(docker ps --filter publish=18080 --format '{{.ID}}'); do
  PROJECT=$(docker inspect -f '{{index .Config.Labels "com.docker.compose.project"}}' "$ID")
  if [ "$PROJECT" = palangshim-rhymix ]; then continue; fi
  SOURCE=$(docker inspect -f '{{range .Mounts}}{{if eq .Destination "/app/app.py"}}{{.Source}}{{end}}{{end}}' "$ID")
  if [ "$SOURCE" != "$APP_DIR/app.py" ]; then
    echo "Port 18080 is used by a different app. No existing app was stopped." >&2
    exit 1
  fi
  PREVIOUS_IDS="$PREVIOUS_IDS $ID"
done
SWITCHING=true
touch "$APP_DIR/.rhymix-mode"
for ID in $PREVIOUS_IDS; do
  STOPPED_IDS="$STOPPED_IDS $ID"
  docker stop "$ID"
done
compose up -d
WEB_READY=false
for ATTEMPT in $(seq 1 90); do
  if curl -fLsS --max-time 5 http://127.0.0.1:18080/ > "$TMP_DIR/page.html" \
     && grep -qi rhymix "$TMP_DIR/page.html"; then
    WEB_READY=true
    break
  fi
  sleep 2
done
if [ "$WEB_READY" != true ]; then
  echo "Installation page failed its check. See Container Manager web logs." >&2
  exit 1
fi
touch "$INSTALL_DIR/.rhymix-ready"
SUCCESS=true
show_info
