# metal-flow-llm-gateway

Private OpenAI-compatible LLM gateway for **metal-flow-ai**, built on
[CLIProxyAPI](https://github.com/router-for-me/CLIProxyAPI) (pinned: `v8.0.42` @ `bc06434`, see `UPSTREAM`).
Restricted to **Gemini models only**, bound to **127.0.0.1 only**. No upstream source is vendored: the binary/image
is built from the official repository at the pinned commit (commit hash verified during build).

> ⚠️ **Terms-of-service risk.** CLIProxyAPI authenticates with Google's Antigravity OAuth client (its embedded client
> ID/secret and an Antigravity-like User-Agent) and calls the internal `cloudcode-pa.googleapis.com` API. This is not an
> official Google API for third-party apps and may violate Google's terms; the account could be rate-limited or
> suspended. Mitigations here: Gemini-only, single user, global queue + 429 backoff in the client, no public exposure.
> The fully official alternative is metal-flow-ai's `MODEL_PROVIDER=gemini_api` with a Gemini API key.

## Layout
| Path | Purpose |
|---|---|
| `UPSTREAM` | repo URL, version tag, pinned commit |
| `Dockerfile` | multi-stage: clones upstream at pinned commit, verifies hash, builds; slim runtime |
| `docker-compose.yml` | service `gateway`, port `127.0.0.1:${GATEWAY_HOST_PORT:-8317}`, network `metal-flow-llm-gateway` |
| `config/config.example.yaml` | Gemini-only config (`oauth.excluded-models.antigravity: [claude-*, gpt-*]`) |
| `auths/` | OAuth credential JSON (gitignored, chmod 700/600) |
| `scripts/build-local.sh` / `run-local.sh` | build/run without Docker (refuses non-127.0.0.1 binding) |
| `scripts/login.sh` | interactive Antigravity login (account owner only) |
| `scripts/smoke.sh` | live test: models (Gemini-only), chat, stream, tool_calls, /responses, claude/unknown model rejected, bad key 401 |

## Run from zero (Docker)
```bash
cp config/config.example.yaml config/config.yaml && chmod 600 config/config.yaml
KEY=$(openssl rand -hex 24); sed -i "s/REPLACE_WITH_RANDOM_KEY/$KEY/" config/config.yaml
printf 'GATEWAY_URL=http://127.0.0.1:8317/v1\nGATEWAY_KEY=%s\nMODEL=gemini-3.8-flash-high\n' "$KEY" > .env && chmod 600 .env
# credentials: copy your own antigravity-<email>.json into auths/ (chmod 600) OR: scripts/login.sh
docker compose up -d --build
scripts/smoke.sh
```
Clients use `MODEL_BASE_URL=http://127.0.0.1:8317/v1` (host) or `http://metal-flow-llm-gateway:8317/v1`
(containers on the `metal-flow-llm-gateway` network) and `MODEL_API_KEY=$KEY`.

## Run without Docker
```bash
scripts/build-local.sh                    # needs Go ≥ 1.26 and git
# config/config.local.yaml: host "127.0.0.1", auth-dir = absolute path of ./auths
scripts/run-local.sh && scripts/smoke.sh
```

## Upgrading upstream
Review the upstream diff, then change `CLIPROXY_VERSION`/`CLIPROXY_COMMIT` in `UPSTREAM` **and** the defaults in
`docker-compose.yml`/`Dockerfile`, rebuild, run `scripts/smoke.sh`. Re-check that `excluded-models` still applies.

## Security
- Never publish the port on a public interface; no reverse proxy. Access from a laptop only via SSH tunnel / Tailscale.
- `auths/`, `config/config.yaml`, `.env` are gitignored; do not log or paste tokens.
- `docker-compose.box-hostnet.yml` exists only for the build sandbox (its Docker bridge has no egress); not for the VPS.

See `docs/DEPLOY_VPS.md`.
