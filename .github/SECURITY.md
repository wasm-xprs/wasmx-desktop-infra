# Security Policy

The desktop infra repository must preserve these invariants:

- the daemon binds only to loopback
- Cloudflare Tunnel is outbound-only and does not require a public IP or inbound firewall rule
- tunnel credentials are supplied at runtime and are never committed
- public hostnames should be protected by Cloudflare Access or an equivalent edge policy
- the daemon bearer token remains required behind the edge layer
- service definitions must preserve the local state directory while denying unnecessary OS privileges

Report vulnerabilities privately through GitHub private vulnerability reporting when available.
