#!/usr/bin/env bash
# Build CLIProxyAPI binary from the official repo at the pinned commit into ./bin (no Docker).
set -euo pipefail
cd "$(dirname "$0")/.."; source ./UPSTREAM
if [ ! -d .upstream/.git ]; then git clone --filter=blob:none "$CLIPROXY_REPO" .upstream; fi
git -C .upstream fetch -q origin && git -C .upstream checkout -q --detach "$CLIPROXY_COMMIT"
[ "$(git -C .upstream rev-parse HEAD)" = "$CLIPROXY_COMMIT" ] || { echo "commit mismatch"; exit 1; }
mkdir -p bin
(cd .upstream && go build -buildvcs=false -ldflags="-s -w -X 'main.Version=$CLIPROXY_VERSION' -X 'main.Commit=$CLIPROXY_COMMIT'" -o ../bin/cli-proxy-api ./cmd/server/)
echo "built bin/cli-proxy-api ($CLIPROXY_VERSION @ ${CLIPROXY_COMMIT:0:7})"
