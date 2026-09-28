#!/usr/bin/env sh
set -eu

command -v cloudflared >/dev/null 2>&1 || {
  echo "cloudflared is required" >&2
  exit 1
}

exec cloudflared tunnel --url http://127.0.0.1:8765
