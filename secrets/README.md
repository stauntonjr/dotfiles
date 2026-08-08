# Secrets in this repo

This repository stores sensitive files in `secrets/store/*.sops` using
[`sops`](https://github.com/getsops/sops) with an age recipient. The age
private key is not committed. Local decrypt/encrypt operations expect:

- `SOPS_AGE_KEY_FILE=$HOME/.config/sops/age/keys.txt`, or
- the default `sops` age key path at `~/.config/sops/age/keys.txt`

The source of truth is:

- encrypted files: `secrets/store/**`
- manifest: `secrets/manifest.tsv`

Plaintext files are materialized back to their normal repo paths when you run:

```bash
bash scripts/secrets/decrypt-all.sh
```

To re-encrypt plaintext changes back into the repo:

```bash
bash scripts/secrets/encrypt-all.sh
```

To edit one secret with automatic re-encryption:

```bash
bash scripts/secrets/edit.sh .env
```

## mcp-srv runtime configuration

The live mcp-srv environment, connector configuration, and Traefik dynamic
configuration are encrypted under `secrets/store/mcp-srv/`. They are
materialized beneath `mcp-srv/runtime/` and deployed to the service directory
without being committed to the public `mcp-srv` repository:

```bash
bash scripts/mcp-srv/deploy.sh
```

Use `--restart` only after reviewing a configuration change. The deployment
command validates the Compose project before restarting it.

To verify the full repo decrypts cleanly without leaving plaintext behind:

```bash
bash scripts/secrets/check.sh
```

`secrets/manifest.tsv` uses tab-separated columns:

1. repo-relative plaintext path
2. repo-relative encrypted `.sops` path
3. output mode to apply after decryption

## Important history note

The current working tree can now be made public safely, but older git commits
may still contain plaintext secrets from before this migration. Before pushing
this repository to a public remote, rewrite git history to remove the old
plaintext paths and rotate any credentials that were previously committed.
