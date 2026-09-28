#!/usr/bin/env sh
set -eu

install_dir="${WASMX_INSTALL_DIR:-$HOME/.local/bin}"
daemon_version="${WASMX_DAEMON_VERSION:-latest}"
cli_version="${WASMX_CLI_VERSION:-latest}"

case "$(uname -s)" in
  Linux) os="linux" ;;
  Darwin) os="macos" ;;
  *) echo "unsupported OS; use services/windows/install-binaries.ps1 on Windows" >&2; exit 1 ;;
esac

case "$(uname -m)" in
  x86_64|amd64) arch="x86_64" ;;
  arm64|aarch64) arch="aarch64" ;;
  *) echo "unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

command -v curl >/dev/null 2>&1 || { echo "curl is required" >&2; exit 1; }
if command -v sha256sum >/dev/null 2>&1; then
  hash_cmd="sha256sum"
elif command -v shasum >/dev/null 2>&1; then
  hash_cmd="shasum -a 256"
else
  echo "sha256sum or shasum is required" >&2
  exit 1
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT INT TERM
mkdir -p "$install_dir"

download_verified() {
  repo="$1"
  version="$2"
  asset="$3"
  output="$4"
  if [ "$version" = "latest" ]; then
    base="https://github.com/wasm-xprs/$repo/releases/latest/download"
  else
    base="https://github.com/wasm-xprs/$repo/releases/download/$version"
  fi
  curl --fail --location --silent --show-error "$base/SHA256SUMS" -o "$tmp/$repo.SHA256SUMS"
  curl --fail --location --silent --show-error "$base/$asset" -o "$tmp/$asset"
  expected="$(awk -v name="$asset" '$2 == name { print $1 }' "$tmp/$repo.SHA256SUMS")"
  if [ -z "$expected" ]; then
    echo "checksum not found for $asset" >&2
    exit 1
  fi
  actual="$(sh -c "$hash_cmd \"$tmp/$asset\"" | awk '{ print $1 }')"
  if [ "$actual" != "$expected" ]; then
    echo "checksum mismatch for $asset" >&2
    exit 1
  fi
  install -m 0755 "$tmp/$asset" "$output"
}

download_verified "wasmx-desktop-daemon" "$daemon_version" "wasmx-desktop-daemon-${os}-${arch}" "$install_dir/wasmx-desktop-daemon"
download_verified "wasmx-desktop-cli" "$cli_version" "wasmx-desktop-cli-${os}-${arch}" "$install_dir/wasmx-desktop-cli"
echo "installed verified wasm-xprs binaries in $install_dir"
