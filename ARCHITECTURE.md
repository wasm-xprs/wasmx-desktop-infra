# Desktop architecture

wasm-xprs is the raw-Wasmtime member of the local FaaS family.

```
public hostname
     |
Cloudflare Tunnel
     | outbound connection only
127.0.0.1:8765
     |
wasmx-desktop-daemon
     |
Wasmtime Engine (shared immutable compiler/runtime state)
     |
fresh Store per invocation
     |
guest WebAssembly module
```

The daemon is the security boundary. Desktop infra only starts, supervises and exposes it through an outbound tunnel. It must not add ambient guest capabilities.

## Process responsibilities

- **wasmx-desktop-cli**: operator UX; deploy, list, invoke and delete.
- **wasmx-desktop-daemon**: authentication, artifact validation/persistence, resource limits and Wasmtime execution.
- **wasmx-desktop-infra**: local lifecycle, Cloudflare Tunnel and OS service integration.

## Network model

The daemon binds loopback only. A named Cloudflare Tunnel should terminate the public hostname and forward to `http://127.0.0.1:8765`. No dedicated public IP or inbound router configuration is required.

For production/self-hosted use, place Cloudflare Access or another edge authentication layer in front of the tunnel. The daemon bearer token remains required as defense in depth.


## Isolation layers

`wasm-xprs` is intentionally not an actor runtime. The guest execution model is a short-lived direct Wasmtime invocation with a fresh `Store`; actor/mailbox/supervision semantics belong in Lunatic Lorry.

The Linux unit applies OS-level restrictions that are compatible with a JIT runtime. It intentionally does **not** set `MemoryDenyWriteExecute=true`, because Cranelift must create executable code mappings. Hosts requiring a stronger outer boundary should place the daemon inside a dedicated OS account, container sandbox, or microVM.

## Desktop startup

- Linux: hardened systemd user unit.
- macOS: LaunchAgent template with a background process lifecycle.
- Windows: per-user Scheduled Task at logon.

All three keep the daemon bound to loopback. Cloudflare Tunnel is the only intended public ingress path.

## Persistent artifact boundary

Each deployment directory contains the immutable Wasm module plus a host-only integrity manifest. Runtime cold loads verify that manifest before caching/instantiating the module. Tenant deployment-count and byte quotas bound local persistent growth independently of invocation memory/fuel limits.
