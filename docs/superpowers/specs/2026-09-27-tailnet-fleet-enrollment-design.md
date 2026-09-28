# Tailnet fleet enrollment

## Objective

Give each reachable, non-enrolled host a persistent Tailscale connection and a
usable `tailscale` CLI. Do not change hosts that are already enrolled. Do not
persist the supplied reusable auth key in Git, shell history, service units, or
host configuration.

## Scope

Enroll the Proxmox host and the reachable Linux hosts currently missing
Tailscale: `mcp-srv`, `vpn-srv`, `oidc-srv`, `dns-srv`, `sh-srv`, `md-srv`, and
`log-srv`. Ensure the CLI is usable on every reachable host. The MacBook remains
enrolled through its existing macOS application; add only its supported CLI
launcher/alias. Do not alter already enrolled `smb-srv`, `img-srv`, or
`ediacarian`.

Offline or unreachable hosts (`msi`, `win-desktop`, and `wsl-desktop`) are
reported as pending. `docker-lxc` is excluded at the user's direction. DGX and
the Windows desktop are already visible in the tailnet and are not changed.

## Design

1. Probe each target's operating system and existing network settings.
2. Install the official stable Tailscale package using its native package
   manager. Enable and start `tailscaled` at boot.
3. Pass the reusable auth key only through a protected one-shot process
   environment to `tailscale up`; do not use shell history or persistent files.
   Do not set tags, routes, exit-node settings, or Tailscale SSH.
4. On the MacBook, expose the existing app-bundled CLI using Tailscale's
   supported CLI integration when available, otherwise a shell alias that sets
   `TAILSCALE_BE_CLI=1` and invokes the app bundle executable. Keep its current
   enrollment unchanged.
5. After a host is enrolled, add a corresponding tailnet SSH host entry to
   `ssh/config`. Prefer its stable MagicDNS name, retain the existing login
   user and non-default port where applicable, and avoid replacing a working
   LAN alias. Commit and push those shared SSH-config additions only after
   verifying the new tailnet connection.
6. Verify each changed machine has a running daemon enabled for boot, a
   tailnet IP, a usable CLI, and the expected tailnet membership. Verify the
   auth key is absent from the process command line and any persistent project
   file after use.

## Failure handling

An install or enrollment failure leaves the host's existing network settings
unchanged and is reported per host. No retries use a different configuration
without investigation. Unreachable hosts remain pending rather than being
reset or modified through another route.
