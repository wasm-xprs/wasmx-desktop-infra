#!/usr/bin/env sh
set -eu

missing=0
for bin in cargo curl cloudflared ores-compose; do
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo "missing: $bin" >&2
    missing=1
  fi
done

if [ "$missing" -ne 0 ]; then
  exit 1
fi

echo "wasm-xprs desktop prerequisites are installed"
