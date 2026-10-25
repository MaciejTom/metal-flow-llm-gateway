#!/usr/bin/env bash
# Run the locally built gateway on 127.0.0.1 (config/config.local.yaml must set host 127.0.0.1 and absolute auth-dir).
set -euo pipefail
cd "$(dirname "$0")/.."; mkdir -p logs
CFG=${CONFIG:-config/config.local.yaml}
grep -qE '^\s*host:\s*"127\.0\.0\.1"' "$CFG" || { echo "refusing: $CFG must bind host \"127.0.0.1\""; exit 1; }
nohup bin/cli-proxy-api -config "$CFG" >> logs/gateway.log 2>&1 &
echo "gateway pid $!"
