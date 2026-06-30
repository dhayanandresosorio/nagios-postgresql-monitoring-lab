#!/usr/bin/env bash

set -euo pipefail

POSTGRES_HOST="${POSTGRES_HOST:-192.168.14.50}"
POSTGRES_DB="${POSTGRES_DB:-nagiosdatabase}"
POSTGRES_USER="${POSTGRES_USER:-nagios_monitor}"

echo "== PostgreSQL port check =="
nc -zv "$POSTGRES_HOST" 5432 || true

echo
echo "== check_pgsql =="
/usr/lib/nagios/plugins/check_pgsql -H "$POSTGRES_HOST" -p 5432 -U "$POSTGRES_USER" -d "$POSTGRES_DB" || true

echo
echo "== check_postgres backends =="
/usr/lib/nagios/plugins/check_postgres.pl --action=backends --host="$POSTGRES_HOST" --db="$POSTGRES_DB" --dbuser="$POSTGRES_USER" --warning=5 --critical=10 || true
