# wasmx-desktop-infra

Laptop and desktop orchestration for wasm-xprs.

This repository owns the local topology. The actual FaaS executor lives in wasmx-desktop-daemon and embeds Wasmtime directly.

## Architecture

    Cloudflare
        |
    cloudflared
        |
    127.0.0.1:8765
        |
    wasmx-desktop-daemon
        |
    fresh Wasmtime Store per invocation

The daemon is intentionally loopback-only. cloudflared creates the outbound connection, so the laptop does not need a dedicated public IP or an inbound firewall rule.

## Start locally

Install Rust, curl, cloudflared and ORESoftware/ores-compose. Then set a remotely-managed Cloudflare Tunnel token:

    export TUNNEL_TOKEN=...

Configure the tunnel's public hostname in Cloudflare to use the HTTP origin:

    http://127.0.0.1:8765

Then run:

    ores-compose check .ores-compose.yaml
    ores-compose plan .ores-compose.yaml
    ores-compose up .ores-compose.yaml

The manifest pins the exact wasmx-desktop-daemon Git revision so local startup is reproducible.

## Development quick tunnel

For a temporary development URL without a named tunnel:

    ./scripts/quick-tunnel.sh

Quick tunnels are intended only for development. Production/self-hosted installs should use a named remotely-managed tunnel and Cloudflare Access or equivalent edge authentication in addition to the daemon bearer token.

## Security notes

- The daemon never binds to a LAN/public address.
- The Cloudflare tunnel is outbound-only.
- TUNNEL_TOKEN is inherited from the local environment and is never committed.
- Wasm invocations still require the daemon bearer token.
- Cloudflare Access should protect any public hostname.
