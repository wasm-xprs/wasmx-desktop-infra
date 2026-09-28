#!/usr/bin/env sh
set -eu

binary="$HOME/.local/bin/wasmx-desktop-daemon"
if [ ! -x "$binary" ]; then
  echo "missing executable: $binary" >&2
  echo "install wasmx-desktop-daemon there before installing the user service" >&2
  exit 1
fi

mkdir -p "$HOME/.wasm-xprs/daemon"
chmod 700 "$HOME/.wasm-xprs" "$HOME/.wasm-xprs/daemon"

case "$(uname -s)" in
  Darwin)
    target="$HOME/Library/LaunchAgents/com.wasm-xprs.daemon.plist"
    mkdir -p "$HOME/Library/LaunchAgents"
    sed "s|__HOME__|$HOME|g" services/launchd/com.wasm-xprs.daemon.plist > "$target"
    chmod 600 "$target"
    launchctl bootout "gui/$(id -u)" "$target" >/dev/null 2>&1 || true
    launchctl bootstrap "gui/$(id -u)" "$target"
    echo "installed launchd user service: $target"
    ;;
  Linux)
    target="$HOME/.config/systemd/user/wasmx-desktop-daemon.service"
    mkdir -p "$HOME/.config/systemd/user"
    cp services/systemd/wasmx-desktop-daemon.service "$target"
    chmod 600 "$target"
    systemctl --user daemon-reload
    systemctl --user enable --now wasmx-desktop-daemon.service
    echo "installed systemd user service: $target"
    ;;
  *)
    echo "unsupported platform for this script; use services/windows/install-task.ps1 on Windows" >&2
    exit 1
    ;;
esac
