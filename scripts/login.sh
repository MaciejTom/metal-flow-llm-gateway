#!/usr/bin/env bash
# Interactive Antigravity OAuth login — run by the ACCOUNT OWNER only. Writes credentials to ./auths.
# On a remote VPS first open a tunnel from your laptop:  ssh -L 51121:127.0.0.1:51121 <vps>
# then open the printed URL in your local browser; the callback returns through the tunnel.
set -euo pipefail
cd "$(dirname "$0")/.."
if [ "${1:-docker}" = "local" ]; then
  exec bin/cli-proxy-api -config "${CONFIG:-config/config.local.yaml}" -antigravity-login -no-browser
fi
exec docker compose run --rm -p 127.0.0.1:51121:51121 gateway /app/cli-proxy-api -config /app/config.yaml -antigravity-login -no-browser
