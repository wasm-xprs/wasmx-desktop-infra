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
