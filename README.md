# wasmx-desktop-infra

Laptop and desktop orchestration for wasm-xprs.

This repository owns the local topology. The actual FaaS executor lives in wasmx-desktop-daemon and embeds Wasmtime directly.

## Architecture

    Cloudflare
        |
    cloudflared
        |
    127.0.0.1:8766
        |
    wasmx-desktop-daemon
        |
    fresh Wasmtime Store per invocation

The daemon is intentionally loopback-only. cloudflared creates the outbound connection, so the laptop does not need a dedicated public IP or an inbound firewall rule.

## Start locally

Install Rust, curl and ORESoftware/ores-compose, then run:

    ores-compose check .ores-compose.yaml
    ores-compose plan .ores-compose.yaml
    ores-compose up .ores-compose.yaml

The local compose graph starts only the loopback daemon at `127.0.0.1:8766`. It
deliberately does not start `cloudflared` or inherit tunnel credentials; public
ingress is a separately gated lifecycle with a distinct remote-auth boundary.
The manifest pins the exact `wasmx-desktop-daemon` Git revision so local startup
is reproducible.

If public ingress is later promoted, configure the tunnel separately against
`http://127.0.0.1:8766` and keep its credential out of the local compose
environment.

## Development quick tunnel

For a temporary development URL without a named tunnel:

    ./scripts/quick-tunnel.sh

Quick tunnels are intended only for explicit development testing. They are not part of the normal local compose lifecycle and are not a production authorization boundary.

## Security notes

- The daemon never binds to a LAN/public address.
- The Cloudflare tunnel is outbound-only.
- The local compose graph does not inherit Cloudflare tunnel credentials.
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

## Runtime verification

`scripts/verify-daemon.sh` verifies process readiness, token-file safety, authenticated status, and the live execution contract. It fails if the daemon drifts away from direct Wasmtime, `wasmx-v1`, `wasm32-unknown-unknown`, fresh Store-per-invocation isolation, or the no-WASI policy.

## Hot-reload routing and middleware

This product consumes the shared ORES generation model with **native atomic routes + Wasmtime middleware generations** as its default. Routing/middleware is a separate lifecycle and memory/failure boundary from standalone servers and lambda/actor workers, so route or middleware updates do not restart unrelated compute.

`hot-reload-policy.json` declares the product policy. The edge may optionally use nginx, HAProxy, or Caddy. nginx uses validated worker-generation reloads; HAProxy prefers Runtime API changes and falls back to master-worker reload for structural changes; Caddy uses its transactional Admin API. Proxy-managed application routes are opt-in and limited to declarative routing/middleware. Arbitrary middleware code stays in BEAM, Wasm, or a separately supervised process generation.

Long-lived WebSockets/streams are bounded by a hard generation drain timeout so repeated reloads cannot accumulate old generations indefinitely.


## Shared desktop infra dependency

`appliance.json` pins the exact reviewed `ORESoftware/ores-common-desktop-infra`
revision and declares the shared runtime/isolation/hot-reload capabilities used
by this product. `desktop-contract` CI validates that appliance, local compose,
and `hot-reload-policy.json` remain consistent.
