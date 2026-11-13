#!/usr/bin/env bash
# Local development PostgreSQL for redant-erp (Q1, DEC-014).
# Same credentials as the guide's docker-compose.yml, so the connection
# string does not change when the project moves to Docker in Q2:
#   postgres://redant:redant_dev@localhost:5432/redant_erp
#
# Dev-only credentials. Never reuse them in production.
#
# Usage: pg-dev.sh init | start | stop | status | psql
set -euo pipefail

PG_USER="redant"
PG_PASSWORD="redant_dev"
PG_DB="redant_erp"
PG_PORT="${PG_PORT:-5432}"
PG_ROOT="${PG_ROOT:-$HOME/.local/share/redant-pg}"
PGDATA="$PG_ROOT/data"
PG_LOG="$PG_ROOT/postgres.log"

export PGPASSWORD="$PG_PASSWORD"
# English tool messages: localized ones come out in the console code page and show as mojibake
export LC_MESSAGES=C LANGUAGE=en

is_running() { pg_ctl -D "$PGDATA" status >/dev/null 2>&1; }

cmd_init() {
  if [[ -f "$PGDATA/PG_VERSION" ]]; then
    echo "Already initialized: $PGDATA"
    return 0
  fi
  mkdir -p "$PG_ROOT"
  local pwfile="$PG_ROOT/.pwfile"
  printf '%s\n' "$PG_PASSWORD" > "$pwfile"
  initdb -D "$PGDATA" -U "$PG_USER" --pwfile="$pwfile" \
         --auth=scram-sha-256 -E UTF8 --no-locale
  rm -f "$pwfile"

  cmd_start
  createdb -h localhost -p "$PG_PORT" -U "$PG_USER" "$PG_DB"
  echo "Created database $PG_DB"
}

cmd_start() {
  if is_running; then
    echo "Already running."
    return 0
  fi
  pg_ctl -D "$PGDATA" -l "$PG_LOG" -o "-p $PG_PORT" -w start
}

cmd_stop() {
  if is_running; then
    pg_ctl -D "$PGDATA" -w stop
  else
    echo "Not running."
  fi
}

cmd_status() {
  pg_ctl -D "$PGDATA" status || true
  echo "Connection: postgres://$PG_USER:$PG_PASSWORD@localhost:$PG_PORT/$PG_DB"
}

cmd_psql() {
  psql -h localhost -p "$PG_PORT" -U "$PG_USER" -d "$PG_DB" "$@"
}

case "${1:-}" in
  init)   cmd_init ;;
  start)  cmd_start ;;
  stop)   cmd_stop ;;
  status) cmd_status ;;
  psql)   shift; cmd_psql "$@" ;;
  *) echo "Usage: $(basename "$0") init|start|stop|status|psql [args]" >&2; exit 2 ;;
esac
