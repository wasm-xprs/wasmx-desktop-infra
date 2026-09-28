#!/usr/bin/env sh
set -eu

url="${WASMX_DESKTOP_DAEMON_URL:-http://127.0.0.1:8765}"
token_file="${WASMX_DESKTOP_TOKEN_FILE:-$HOME/.wasm-xprs/daemon/token}"

curl --fail --silent --show-error "$url/healthz" >/dev/null

if [ ! -f "$token_file" ]; then
  echo "missing daemon token: $token_file" >&2
  exit 1
fi

token="$(tr -d "\r\n" < "$token_file")"
if [ "${#token}" -lt 32 ]; then
  echo "daemon token is invalid" >&2
  exit 1
fi

curl --fail --silent --show-error \
  -H "Authorization: Bearer $token" \
  "$url/v1/status"
echo
