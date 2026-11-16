#!/bin/sh
# Railway wrapper for n8n-MCP. Runs as root, then hands over to the upstream
# entrypoint, which fixes ownership and drops to the `nodejs` user.
#
# n8n-MCP keeps one SQLite file. It holds the node documentation that ships with
# each release *and* your workflow rollback snapshots (table workflow_versions).
# The file lives on the Railway volume at /data, so snapshots survive redeploys.
# When the image version changes, this script installs the new release's
# documentation database and copies your snapshots into it, keeping one backup
# of the previous file in /data/backup.
set -e

DB="${NODE_DB_PATH:-/data/nodes.db}"
DIR="$(dirname "$DB")"
SEED=/app/.db-seed/nodes.db
MARK="$DIR/.n8n-mcp-version"
VERSION="$(node -p 'require("/app/package.json").version')"

if [ -z "$AUTH_TOKEN" ] && [ -z "$AUTH_TOKEN_FILE" ]; then
  echo "railway-start: AUTH_TOKEN is empty. Set it in the service variables (at least 32 characters)." >&2
  exit 1
fi

mkdir -p "$DIR"

if [ ! -f "$DB" ]; then
  echo "railway-start: first start, installing the n8n-MCP $VERSION database on the volume"
  cp "$SEED" "$DB.tmp"
  node /app/railway/merge-db.js "$DB.tmp" ""
  mv "$DB.tmp" "$DB"
  echo "$VERSION" > "$MARK"
elif [ "$(cat "$MARK" 2>/dev/null)" != "$VERSION" ]; then
  OLD="$(cat "$MARK" 2>/dev/null || echo unknown)"
  echo "railway-start: upgrading the database from n8n-MCP $OLD to $VERSION, keeping workflow snapshots"
  cp "$SEED" "$DB.tmp"
  node /app/railway/merge-db.js "$DB.tmp" "$DB"
  mkdir -p "$DIR/backup"
  rm -f "$DIR"/backup/nodes-*.db
  mv "$DB" "$DIR/backup/nodes-$OLD.db"
  rm -f "$DB-wal" "$DB-shm"
  mv "$DB.tmp" "$DB"
  echo "$VERSION" > "$MARK"
fi

exec /usr/local/bin/docker-entrypoint.sh "$@"
