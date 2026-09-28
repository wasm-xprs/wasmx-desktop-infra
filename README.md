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


## Install as a desktop user service

First install `wasmx-desktop-daemon` at `~/.local/bin/wasmx-desktop-daemon`.

macOS or Linux:

    ./scripts/install-service.sh
    ./scripts/verify-daemon.sh

Remove it with:

    ./scripts/uninstall-service.sh

Windows uses Task Scheduler so the ordinary console daemon can start at logon without requiring a Windows-service wrapper:

    powershell -File services/windows/install-task.ps1

Remove it with:

    powershell -File services/windows/uninstall-task.ps1

## Local resource policy

The ORES Compose manifest explicitly sets the default desktop policy:

- 128 MiB Wasm linear memory per invocation
- 8 concurrent invocations
- 2 concurrent Wasm compilations
- 32 compiled modules cached in memory
- 64 persisted deployments per tenant
- 512 MiB persisted Wasm bytes per tenant
- 50,000,000 fuel units by default

The daemon enforces its own absolute security ceilings as well; orchestration settings are not the only enforcement layer.

The daemon also persists a host-only artifact manifest that binds each deployment ID to its module SHA-256, byte length, target and guest ABI. The orchestration healthcheck uses `/readyz`, so tunnel startup waits for the artifact store to be usable rather than merely for the process to accept TCP connections.


## Shared desktop platform pin

This repo keeps `.ores-compose.yaml` as the local process/service authority and separately pins the shared desktop platform in `.ores-common-desktop.toml` at `73ebe4b3caa7478c45f64a2eb983838a91ff9732`.

The common layer owns lifecycle/routing/auth/state/packaging/conformance contracts; WasmX keeps its Wasmtime-specific runtime adapter, resource policy, and local topology. The common source repository is private, so CI must consume a promoted Zed package artifact rather than assuming a cross-organization GitHub token can clone it.
