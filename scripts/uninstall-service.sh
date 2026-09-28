#!/usr/bin/env sh
set -eu

case "$(uname -s)" in
  Darwin)
    target="$HOME/Library/LaunchAgents/com.wasm-xprs.daemon.plist"
    launchctl bootout "gui/$(id -u)" "$target" >/dev/null 2>&1 || true
    rm -f "$target"
    ;;
  Linux)
    systemctl --user disable --now wasmx-desktop-daemon.service >/dev/null 2>&1 || true
    rm -f "$HOME/.config/systemd/user/wasmx-desktop-daemon.service"
    systemctl --user daemon-reload
    ;;
  *)
    echo "unsupported platform for this script" >&2
    exit 1
    ;;
esac
