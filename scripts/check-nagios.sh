#!/usr/bin/env bash

set -euo pipefail

echo "== Nagios service =="
systemctl status nagios4 --no-pager || true

echo
echo "== Apache service =="
systemctl status apache2 --no-pager || true

echo
echo "== Nagios web path =="
ls -ld /usr/share/nagios4/htdocs 2>/dev/null || true
