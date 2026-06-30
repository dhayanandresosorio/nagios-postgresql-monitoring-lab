#!/usr/bin/env bash

set -euo pipefail

echo "== Nagios config validation =="
sudo nagios4 -v /etc/nagios4/nagios.cfg || true
