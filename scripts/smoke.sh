#!/usr/bin/env bash
# Live smoke test: models (Gemini-only), chat, stream, tool_calls, /responses, error cases.
# Env: GATEWAY_URL (default http://127.0.0.1:8317/v1), GATEWAY_KEY (or .env), MODEL (default gemini-3.8-flash-high)
set -uo pipefail
cd "$(dirname "$0")/.."  # .env gives defaults; variables already in the environment win
[ -f .env ] && while IFS= read -r l; do [[ "$l" =~ ^([A-Z_]+)=(.*)$ ]] && [ -z "${!BASH_REMATCH[1]+x}" ] && export "${BASH_REMATCH[1]}=${BASH_REMATCH[2]}"; done < .env
echo "target: ${GATEWAY_URL:-http://127.0.0.1:8317/v1}"
B=${GATEWAY_URL:-http://127.0.0.1:8317/v1}; M=${MODEL:-gemini-3.8-flash-high}
H=(-H "Authorization: Bearer ${GATEWAY_KEY:?set GATEWAY_KEY}" -H 'content-type: application/json')
pass=0; fail=0; ok(){ echo "PASS $1"; pass=$((pass+1)); }; ko(){ echo "FAIL $1: ${2:0:300}"; fail=$((fail+1)); }
r=$(curl -s -m 20 "${H[@]}" "$B/models")
echo "$r" | grep -q "\"$M\"" && ok "models lists $M" || ko models "$r"
echo "$r" | grep -qiE '"(claude|gpt)-' && ko "gemini-only listing" "$r" || ok "no claude/gpt models listed"
r=$(curl -s -m 120 "${H[@]}" "$B/chat/completions" -d "{\"model\":\"$M\",\"messages\":[{\"role\":\"user\",\"content\":\"Odpowiedz jednym słowem: OK\"}]}")
echo "$r" | grep -q '"content"' && ok chat || ko chat "$r"
r=$(curl -sN -m 120 "${H[@]}" "$B/chat/completions" -d "{\"model\":\"$M\",\"stream\":true,\"messages\":[{\"role\":\"user\",\"content\":\"Policz do 3\"}]}")
[ "$(echo "$r" | grep -c '^data: ')" -ge 2 ] && echo "$r" | grep -q 'data: \[DONE\]' && ok stream || ko stream "$r"
r=$(curl -s -m 120 "${H[@]}" "$B/chat/completions" -d "{\"model\":\"$M\",\"tool_choice\":\"auto\",\"tools\":[{\"type\":\"function\",\"function\":{\"name\":\"list_documents\",\"description\":\"List RFQ documents\",\"parameters\":{\"type\":\"object\",\"properties\":{}}}}],\"messages\":[{\"role\":\"user\",\"content\":\"Wywołaj narzędzie list_documents.\"}]}")
echo "$r" | grep -q '"tool_calls"' && ok tool_calls || ko tool_calls "$r"
r=$(curl -s -m 120 "${H[@]}" "$B/responses" -d "{\"model\":\"$M\",\"input\":\"Odpowiedz: OK\"}")
echo "$r" | grep -q '"output"' && ok responses || ko responses "$r"
c=$(curl -s -o /dev/null -m 20 -w '%{http_code}' "${H[@]}" "$B/chat/completions" -d '{"model":"claude-sonnet-4-6","messages":[{"role":"user","content":"x"}]}')
[[ "$c" =~ ^4 ]] && ok "claude request rejected ($c)" || ko "claude rejected" "$c"
c=$(curl -s -o /dev/null -m 20 -w '%{http_code}' "${H[@]}" "$B/chat/completions" -d '{"model":"no-such-model","messages":[{"role":"user","content":"x"}]}')
[[ "$c" =~ ^4 ]] && ok "unknown model ($c)" || ko "unknown model" "$c"
c=$(curl -s -o /dev/null -m 20 -w '%{http_code}' -H 'Authorization: Bearer wrong' "$B/models")
[ "$c" = 401 ] && ok "bad key 401" || ko "bad key" "$c"
echo "== $pass passed, $fail failed"; [ $fail = 0 ]
