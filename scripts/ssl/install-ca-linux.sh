#!/usr/bin/env bash
set -euo pipefail

# install-ca-linux.sh
# Installs a local CA certificate into the system trust store on common
# Linux families (RHEL/CentOS/Fedora or Debian/Ubuntu).
# Usage: install-ca-linux.sh [path-to-cert] [--firefox]
# If no path is provided, the script uses "$HOME/dotfiles/ssl/ca.crt".
#
# Options:
#   --firefox    Import the certificate into all local Firefox profiles (requires certutil / libnss3-tools)

DEFAULT_CERT="$HOME/dotfiles/ssl/ca.crt"

# simple arg parsing: first non-option is cert path, --firefox toggles Firefox import
IMPORT_FIREFOX=0
CA_CERT=""
for arg in "$@"; do
  case "$arg" in
    --firefox)
      IMPORT_FIREFOX=1
      ;;
    --help|-h)
      echo "Usage: $0 [path-to-cert] [--firefox]"
      exit 0
      ;;
    *)
      if [ -z "$CA_CERT" ]; then
        CA_CERT="$arg"
      fi
      ;;
  esac
done

CA_CERT="${CA_CERT:-$DEFAULT_CERT}"

if [ ! -f "$CA_CERT" ]; then
  echo "Certificate not found: $CA_CERT"
  echo "If this repo is using SOPS-managed secrets, run: bash ~/dotfiles/scripts/setup-secrets.sh"
  echo "Usage: $0 [path-to-cert]"
  exit 1
fi

basename_cert=$(basename -- "$CA_CERT")

if [ -d /etc/pki/ca-trust/source/anchors ]; then
  # RHEL / CentOS / Fedora style
  echo "Installing $CA_CERT -> /etc/pki/ca-trust/source/anchors/"
  sudo cp "$CA_CERT" /etc/pki/ca-trust/source/anchors/"$basename_cert"
  sudo chmod 644 /etc/pki/ca-trust/source/anchors/"$basename_cert"
  sudo update-ca-trust extract
elif [ -d /usr/local/share/ca-certificates ]; then
  # Debian / Ubuntu style: certificate file must end with .crt
  dest="/usr/local/share/ca-certificates/$basename_cert"
  case "$dest" in
    *.crt) ;;
    *) dest="${dest%.*}.crt" ;;
  esac
  echo "Installing $CA_CERT -> $dest"
  sudo cp "$CA_CERT" "$dest"
  sudo chmod 644 "$dest"
  sudo update-ca-certificates
else
  echo "Unsupported Linux distribution. Please install $CA_CERT manually."
  exit 2
fi

echo "CA certificate installed. You may need to restart your browser or other apps to pick up the new CA."

if [ "$IMPORT_FIREFOX" -eq 1 ]; then
  echo "\n-- Importing certificate into Firefox profiles --"

  if ! command -v certutil >/dev/null 2>&1; then
    echo "certutil (libnss3-tools) not found. To import into Firefox you must install it."
    echo "On Debian/Ubuntu: sudo apt install libnss3-tools"
    echo "On RHEL/Fedora: sudo dnf install nss-tools"
    exit 0
  fi

  NICKNAME="Local CA - ${basename_cert}"

  # detect common Firefox profile locations and try to import into each
  profile_paths=("$HOME/.mozilla/firefox" "$HOME/snap/firefox/common/.mozilla/firefox" "$HOME/.var/app/org.mozilla.firefox/.mozilla/firefox")
  found=0
  for base in "${profile_paths[@]}"; do
    if [ -d "$base" ]; then
      for p in "$base"/*; do
        # skip non-directories
        [ -d "$p" ] || continue
        # check for profile indicator files
        if [ -f "$p/cert9.db" ] || [ -f "$p/prefs.js" ] || [ -f "$p/cert8.db" ]; then
          found=1
          # choose DB type: prefer sql (cert9.db)
          if [ -f "$p/cert9.db" ]; then
            dbarg="sql:$p"
          else
            dbarg="$p"
          fi
          echo "Importing into Firefox profile: $p (db=$dbarg)"
          if certutil -d "$dbarg" -L -n "$NICKNAME" >/dev/null 2>&1; then
            echo "  - entry already exists, skipping"
          else
            if certutil -d "$dbarg" -A -n "$NICKNAME" -t "CT,C,C" -i "$CA_CERT"; then
              echo "  - imported"
            else
              echo "  - failed to import into $p"
            fi
          fi
        fi
      done
    fi
  done

  if [ "$found" -eq 0 ]; then
    echo "No Firefox profiles found to import into. You can import manually via Firefox Settings → Certificates → Authorities."
  else
    echo "Import finished. Restart Firefox to use the new CA." 
  fi
fi
