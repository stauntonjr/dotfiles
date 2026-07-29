Purpose
-------
This folder contains opinionated, reproducible artifacts to install and configure Grafana Alloy across a fleet: the Proxmox host, LXCs, and other Debian-based Linux servers.

Goals
-----
- Keep a single authoritative Alloy config template in dotfiles.
- Provide an idempotent install script that can be run manually or used by automation (Ansible/ssh).
- Provide a helper to deploy the same install into Proxmox LXCs via `pct exec`.

Files
-----
- `install_alloy.sh` — idempotent installer for Debian/Proxmox hosts. Adds Grafana apt repo, installs `alloy`, ensures directories and permissions, and can deploy a config from the dotfiles tree into `/etc/alloy/config.alloy`.
- `config.alloy.tpl` — a template Alloy config. Replace placeholder variables or use simple env-substitution before deploying.
- `alloy.service` — example systemd unit (if you need to override defaults).
- `deploy_to_lxc.sh` — helper to run the installer inside a Proxmox LXC via `pct exec`.
- `convert_promtail.sh` — wrapper that converts an existing Promtail config into Alloy format (uses local `alloy` binary).

Usage (host)
------------
1. Edit `config.alloy.tpl` and set your Loki/Prometheus endpoints or use environment substitution.
2. Run (as root or with sudo):

```bash
# from repo root
sudo /root/dotfiles/alloy/install_alloy.sh --from-repo /root/dotfiles/alloy
```

This will:
- add the Grafana apt repo (if missing),
- install `alloy` package,
- create `/etc/alloy/config.alloy` from the template if not present,
- ensure `/var/lib/alloy` and `/var/log/alloy` are owned by `alloy` user.

Usage (LXC)
-----------
To install inside LXC VMID 121:

```bash
sudo /root/dotfiles/alloy/deploy_to_lxc.sh 121 /root/dotfiles/alloy
```

This uses `pct exec <vmid> --` to run the same installer inside the container. The script checks that `pct` exists and returns helpful errors.

Notes & safety
--------------
- The scripts are idempotent and conservative: they won't overwrite an existing `/etc/alloy/config.alloy` unless you pass `--force`.
- If you plan to use Grafana Cloud remote config, prefer the Grafana Cloud "Run Alloy" one-liner so the token/remote config is bootstrapped.
- When running inside unprivileged LXCs, some host-level metrics/journal access may be restricted—install on the layer you intend to monitor.

Next steps
----------
- I can adapt the template to include your actual Loki/Mimir endpoints and CA paths and create a `dotfiles/alloy/values.env` with straightforward substitution.
- I can also add an Ansible role or systemd drop-in if you prefer that automation model.
