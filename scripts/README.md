Secrets helper scripts

All scripts expect `sops` to be installed and a valid age private key available
to `sops` via either:

- file: `~/.config/sops/age/keys.txt`
- env: `SOPS_AGE_KEY=...`

Primary workflow:

- `bash scripts/secrets/decrypt-all.sh`
  Decrypts every manifest entry back to its normal repo path.

- `bash scripts/secrets/encrypt-all.sh`
  Re-encrypts every manifest entry from the current plaintext working files.

- `bash scripts/secrets/edit.sh .env`
  Decrypts one tracked secret, opens it in `$EDITOR`, then re-encrypts it.

- `bash scripts/secrets/check.sh`
  Verifies every encrypted entry decrypts successfully without writing into the
  repo working tree.
