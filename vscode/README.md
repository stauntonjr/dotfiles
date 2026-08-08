# VS Code settings

These strict-JSON fragments are the tracked source of truth for VS Code
settings. The installer creates a generated settings file; it does not symlink
VS Code's live file, so Settings Sync and VS Code's Settings UI remain safe to
use.

## Layout

- `settings.base.json`: portable client preferences.
- `settings.macos.json` and `settings.windows.json`: client OS terminal
  profiles. Only the matching file is selected.
- `settings.ssh-client.json`: Remote-SSH client behavior and SSH aliases. It
  deliberately has no `remote.SSH.configFile`: every client uses its native
  default SSH config location.
- `remote/linux.json`: settings shared by every Linux Remote-SSH host,
  including LXC containers.
- `remote/<host>.json`: optional overlay for a host that genuinely differs.
  It is merged after `linux.json`; a host does not need its own file otherwise.

Do not add secrets, absolute local extension paths, or broad security bypasses
to shared fragments. Use an ignored local overlay when a machine needs one.

## Generate and apply

Run on the machine that owns the corresponding settings file:

```bash
# Preview the Mac/Linux/Windows client settings selected for this machine.
bash ~/dotfiles/scripts/vscode/install-settings.sh --client

# Merge the selected client settings into VS Code's User settings.
bash ~/dotfiles/scripts/vscode/install-settings.sh --client --apply

# On DGX, Proxmox, or any Linux LXC, preview/apply the common remote settings.
bash ~/dotfiles/scripts/vscode/install-settings.sh --remote dgx
bash ~/dotfiles/scripts/vscode/install-settings.sh --remote dgx --apply
bash ~/dotfiles/scripts/vscode/install-settings.sh --remote mcp-srv --apply
```

`--apply` first makes a timestamped backup beside the live settings file. It
preserves settings that are not managed by these fragments; managed values win
so the checked-in source remains authoritative. The generated file is strict
JSON, even though VS Code also accepts JSONC.

The script defaults to VS Code's stable locations. Pass `--target PATH` for
Insiders, VSCodium, or a nonstandard install.
