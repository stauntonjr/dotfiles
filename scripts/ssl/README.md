# OIDC-SRV Certificate Management

This folder contains scripts and instructions for generating and installing a local Certificate Authority (CA) and server certificate for the OIDC/Authentik service.

- `generate-ca-and-cert.sh`: Script to generate a CA and a wildcard server certificate for `*.ediacarian.home` (and `ediacarian.home`).
- `generate-wildcard-cert.sh`: Script to generate a wildcard server certificate for `*.ediacarian.home` (and `ediacarian.home`).
- `ca.crt`: The generated CA certificate (to be installed on clients). Located in `~/dotfiles/ssl/`.
- `ca.key`: The CA private key (keep this secret; do not distribute). Located in `~/dotfiles/ssl/`.
- `wildcard.ediacarian.home.crt`: The wildcard server certificate for any subdomain of `ediacarian.home`. Located in `~/dotfiles/ssl/`.
- `wildcard.ediacarian.home.key`: The wildcard server private key. Located in `~/dotfiles/ssl/`.
- `install-ca-windows.ps1`: PowerShell script to install the CA on Windows.
- `install-ca-linux.sh`: Bash script to install the CA on Linux.
- `../trust-oidc-dev-ca-macos.sh`: Bash script to install the CA into the macOS login keychain.

## Wildcard Certificate

The wildcard certificate (`wildcard.ediacarian.home.crt` and `.key`) allows you to secure any service in the `*.ediacarian.home` DNS zone with a single certificate. This certificate is signed by your local CA (`ca.crt`), which you have already installed on all your devices. As long as the CA is trusted, any service using the wildcard certificate will be trusted by browsers and clients.

**Usage:**
- Generate the wildcard cert with `generate-wildcard-cert.sh`.
- Configure your web server or Traefik to use `wildcard.ediacarian.home.crt` and `wildcard.ediacarian.home.key` for any service in the zone (e.g., dashboard, OIDC, etc).
- No need to generate individual certs for each host.

**Security Note:**
- The wildcard cert is valid for all subdomains of `ediacarian.home` (e.g., `foo.ediacarian.home`, `bar.ediacarian.home`).
- Do not share the private key outside your trusted infrastructure.
## Dashboard Certificate

The NetBird Dashboard (`https://netbird-dashboard.ediacarian.home`) requires its own server certificate, signed by your local CA, to be trusted by browsers. Use `generate-dashboard-cert.sh` to create this certificate. The generated cert is valid for both `netbird-dashboard.ediacarian.home` and `oidc.ediacarian.home` (SAN).

After generating, configure Traefik to use `netbird-dashboard.ediacarian.home.crt` and `netbird-dashboard.ediacarian.home.key` for the dashboard route.

## Usage

### 1. Generate CA and Server Certificate
Run the following from anywhere (the scripts will use `~/dotfiles/ssl` for all output):

If those files are managed by the encrypted repo store, first run:

```bash
bash ~/dotfiles/scripts/setup-secrets.sh
```

```bash
bash ~/dotfiles/scripts/ssl/generate-ca-and-cert.sh
```

This will create the CA and wildcard server certs in `~/dotfiles/ssl/`.

### 2. Install CA Certificate

#### On Windows
Run in an Administrator PowerShell prompt:
```powershell
~/dotfiles/scripts/ssl/install-ca-windows.ps1
```
Or double-click `ca.crt` and use the Certificate Import Wizard (Trusted Root Certification Authorities).

#### On Linux
Run:
```bash
sudo bash ~/dotfiles/scripts/ssl/install-ca-linux.sh
```

#### On macOS
Run:
```bash
bash ~/dotfiles/scripts/trust-oidc-dev-ca-macos.sh
```
If VS Code or another Node-based client still rejects the certificate chain, start it from a shell that exports `NODE_EXTRA_CA_CERTS=~/dotfiles/ssl/ca.crt`.

---

**After installing the CA, restart your browser.**

## Security Note
- The CA key is for local development only. Do not use in production.
- Distribute only `ca.crt` to clients.
