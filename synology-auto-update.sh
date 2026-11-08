#!/bin/sh
# Synology DSM Task Scheduler: run as root every minute.
set -eu
PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
export PATH
APP_DIR=/volume1/docker/palangshim
mkdir -p "$APP_DIR"
cd "$APP_DIR"
# Rhymix owns the website after migration; never restart the Python sample.
if [ -f .rhymix-mode ]; then exit 0; fi
# Prevent overlapping scheduled runs. A killed process may leave this directory;
# remove .github-update.lock manually only after confirming no updater is running.
if ! mkdir .github-update.lock 2>/dev/null; then exit 0; fi
TMP_DIR=
cleanup() {
  if [ -n "$TMP_DIR" ]; then rm -rf "$TMP_DIR"; fi
  rmdir "$APP_DIR/.github-update.lock"
}
trap cleanup EXIT
trap 'exit 1' HUP INT TERM
TMP_DIR=$(mktemp -d "$APP_DIR/.github-update.XXXXXX")
curl --fail --location --silent --show-error --connect-timeout 15 --max-time 90 \
  https://codeload.github.com/palangshim/New/tar.gz/refs/heads/main \
  -o "$TMP_DIR/source.tar.gz"
tar -xzf "$TMP_DIR/source.tar.gz" -C "$TMP_DIR" New-main/app.py New-main/compose.yaml
SOURCE="$TMP_DIR/New-main"
FINGERPRINT=$(cd "$SOURCE" && cksum app.py compose.yaml)
if [ -f .github-deployed ] && [ "$(cat .github-deployed)" = "$FINGERPRINT" ] \
   && cmp -s "$SOURCE/app.py" app.py && cmp -s "$SOURCE/compose.yaml" compose.yaml; then
  exit 0
fi
compose() {
  if docker compose version >/dev/null 2>&1; then
    docker compose "$@"
  else
    docker-compose "$@"
  fi
}
# Validate before touching the running application's files.
(cd "$SOURCE" && compose config >/dev/null)
BACKUP="$APP_DIR/.github-backups/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP"
for FILE in app.py compose.yaml; do
  if [ -f "$FILE" ]; then cp -p "$FILE" "$BACKUP/$FILE"; fi
done
cp "$SOURCE/app.py" "$APP_DIR/app.py"
cp "$SOURCE/compose.yaml" "$APP_DIR/compose.yaml"
chmod 644 app.py compose.yaml
# Recreate is required: the Python process does not reload a changed bind mount.
compose up -d --force-recreate sample
HEALTHY=false
for ATTEMPT in 1 2 3 4 5 6; do
  if curl --fail --silent --show-error --max-time 5 http://127.0.0.1:18080/health; then
    HEALTHY=true
    break
  fi
  sleep 5
done
if [ "$HEALTHY" != true ]; then
  echo "Health check failed. Backup: $BACKUP. Next schedule will retry." >&2
  exit 1
fi
printf '%s\n' "$FINGERPRINT" > .github-deployed
echo "GitHub update deployed successfully."
