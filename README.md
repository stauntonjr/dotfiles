# Cross-platform dotfiles

Bash configuration and prompt customizations used on Debian/Ubuntu, WSL,
macOS, and Windows Git Bash.

## Secrets

This repo is designed to be publishable. Sensitive files live in
`secrets/store/*.sops` and are decrypted locally into their normal repo paths
only when needed.

On a machine that has the age private key in
`~/.config/sops/age/keys.txt`, run:

```bash
bash ~/dotfiles/scripts/setup-secrets.sh
```

That materializes files like `.env`, SSH private keys, and local TLS material
from the encrypted store defined in `secrets/manifest.tsv`.

## Shell setup

Clone this repository at `~/dotfiles`, then run:

```bash
bash ~/dotfiles/scripts/shell/setup-shell.sh
```

The bootstrap installs supported shell tools with the platform package manager,
installs or updates ble.sh in `~/.local` when `git` and `make` are available,
backs up existing configuration files, writes a managed `~/.bashrc` that loads
the repo's `.bashrc.d` fragments, and links the repo-managed Starship, Atuin,
Fastfetch, and ble.sh configs.

Useful modes:

```bash
# Only back up/install shell configuration; never invoke a package manager
bash ~/dotfiles/scripts/shell/setup-shell.sh --links-only

# Only install/update tools; do not change shell configuration files
bash ~/dotfiles/scripts/shell/setup-shell.sh --tools-only
```

To update Atuin later without rerunning the full shell bootstrap:

```bash
bash ~/dotfiles/scripts/shell/update-shell-tools.sh
```

When your install includes Atuin's official `atuin-update` helper, the script
uses that. Otherwise it falls back to the platform package manager for a normal
"latest available" upgrade.

On Windows, run the script from Git Bash. Symlink creation requires Windows
Developer Mode or an elevated shell. WSL follows the Linux setup path.
