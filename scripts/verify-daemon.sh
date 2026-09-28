#!/usr/bin/env sh
set -eu

url="${WASMX_DESKTOP_DAEMON_URL:-http://127.0.0.1:8765}"
token_file="${WASMX_DESKTOP_TOKEN_FILE:-$HOME/.wasm-xprs/daemon/token}"

case "$url" in
  http://127.0.0.1:*|http://localhost:*|http://\[::1\]:*|https://*)
    ;;
  *)
    echo "refusing insecure or unsupported daemon URL: $url" >&2
    exit 1
    ;;
esac

curl --proto '=http,https' --fail --silent --show-error "$url/readyz" >/dev/null

if [ ! -f "$token_file" ] || [ -L "$token_file" ]; then
  echo "daemon token must be a regular non-symlink file: $token_file" >&2
  exit 1
fi

case "$(uname -s)" in
  Darwin)
    mode="$(stat -f '%Lp' "$token_file")"
    ;;
  Linux)
    mode="$(stat -c '%a' "$token_file")"
    ;;
  *)
    mode=""
    ;;
esac

if [ -n "$mode" ]; then
  last_two="$(printf '%s' "$mode" | sed 's/.*\(..\)$/\1/')"
  case "$last_two" in
    00) ;;
    *)
      echo "daemon token must not be accessible by group or other users" >&2
      exit 1
      ;;
  esac
fi

token="$(tr -d "\r\n" < "$token_file")"
if [ "${#token}" -lt 32 ]; then
  echo "daemon token is invalid" >&2
  exit 1
fi

curl --proto '=http,https' --fail --silent --show-error   -H "Authorization: Bearer $token"   "$url/v1/status"
echo
