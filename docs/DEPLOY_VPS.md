# Deploying the gateway on the private VPS (instructions only — nothing deployed yet)

Constraints: the VPS already runs **n8n** and **gemini-argon-api**. This stack uses its own compose project
(`metal-flow-llm-gateway`), container name, network and directory; it must not reuse their ports, networks or volumes.

1. Pre-checks: `ss -ltnp | grep -E ':8317|:51121'` (must be free; else set `GATEWAY_HOST_PORT`), `docker network ls`.
2. `git clone <this repo> ~/metal-flow/metal-flow-llm-gateway && cd $_` and create `config/config.yaml` + `.env` (README).
3. Credentials (done by the account owner only):
   - **A – copy**: `scp antigravity-<email>.json vps:~/metal-flow/metal-flow-llm-gateway/auths/ && ssh vps chmod 600 .../auths/*`
   - **B – re-login on VPS**: from laptop `ssh -L 51121:127.0.0.1:51121 vps`, then on VPS `scripts/login.sh`;
     open the printed Google URL in the laptop browser; the callback returns through the tunnel.
4. `docker compose up -d --build && scripts/smoke.sh` (expects 9/9 PASS).
5. Access from laptop: `ssh -N -L 8317:127.0.0.1:8317 vps` or Tailscale. Never bind `0.0.0.0`, no public reverse proxy.
6. Updates: `git pull && docker compose up -d --build && scripts/smoke.sh`. Rollback: previous image tag.
7. Token expiry / 401 from smoke: redo step 3.
