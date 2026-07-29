SSH config managed via dotfiles

Unified config
- ssh/config: single client config used by both Linux/WSL and Windows

Deprecated (kept for reference)
- config_linux, config_win (no longer needed)

Key/cert paths (same on both platforms)
- Private key:     ~/.ssh/id_ed25519
- Certificate:     ~/.ssh/id_ed25519-cert.pub

Before using the repo-managed SSH files locally, run:
  bash ~/dotfiles/scripts/setup-secrets.sh

That restores the decrypted plaintext files under `~/dotfiles/ssh/` from the
SOPS-managed encrypted store.

Symlink commands
Linux/WSL:
  mkdir -p ~/.ssh
  [ -f ~/.ssh/config ] && cp ~/.ssh/config ~/.ssh/config.bak.$(date +%s) || true
  ln -sf "$HOME/dotfiles/ssh/config" "$HOME/.ssh/config"

Windows (Admin PowerShell):
  New-Item -ItemType Directory -Force "$env:USERPROFILE\.ssh" | Out-Null
  if (Test-Path "$env:USERPROFILE\.ssh\config") { Copy-Item "$env:USERPROFILE\.ssh\config" "$env:USERPROFILE\.ssh\config.bak.$(Get-Date -Format yyyyMMddHHmmss)" }
  New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\.ssh\config" -Target "$env:USERPROFILE\dotfiles\ssh\config" -Force

Hosts
- proxmox, docker-lxc (ProxyJump proxmox), mcp-srv, ediacarian, win-desktop
- wsl-desktop (Linux hosts use 10.0.0.204:2222 via Windows portproxy)
- wsl-desktop-local (Windows host to WSL on localhost:22)

Notes
- Use `scripts/ssh-cert-update` to refresh the certificate and commit the encrypted copy into this repo.
