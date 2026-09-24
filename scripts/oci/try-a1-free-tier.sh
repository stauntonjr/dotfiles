#!/usr/bin/env bash
set -euo pipefail

display_name=${OCI_A1_DISPLAY_NAME:-ediacarian-vps-2-a1}
ocpus=${OCI_A1_OCPUS:-2}
memory_gb=${OCI_A1_MEMORY_GB:-12}
state_dir=${OCI_A1_STATE_DIR:-"$HOME/.local/state/oci-a1-retry"}
repo_dir=${DOTFILES_DIR:-"$HOME/dotfiles"}
config_sops=${OCI_CONFIG_SOPS:-"$repo_dir/secrets/store/oci/config.sops"}
key_sops=${OCI_KEY_SOPS:-"$repo_dir/secrets/store/oci/oci_api_key.pem.sops"}
age_key_file=${SOPS_AGE_KEY_FILE:-"$HOME/.config/sops/age/keys.txt"}
ssh_public_key=${OCI_SSH_PUBLIC_KEY:-"$HOME/.ssh/id_ed25519.pub"}

log_file="$state_dir/attempts.log"
lock_dir="$state_dir/.lock"
mkdir -p "$state_dir"
if ! mkdir "$lock_dir" 2>/dev/null; then echo "another attempt is already running" >&2; exit 75; fi
trap 'rm -rf "$lock_dir"' EXIT

for command in oci sops jq; do command -v "$command" >/dev/null || { echo "missing required command: $command" >&2; exit 1; }; done
[[ -r "$config_sops" && -r "$key_sops" && -r "$age_key_file" && -r "$ssh_public_key" ]] || { echo "missing encrypted OCI config/key, age key, or SSH public key" >&2; exit 1; }

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir" "$lock_dir"' EXIT
export SOPS_AGE_KEY_FILE="$age_key_file"
sops -d "$config_sops" > "$tmp_dir/config"
sops -d "$key_sops" > "$tmp_dir/key"
chmod 600 "$tmp_dir/config" "$tmp_dir/key"
sed -i.bak "s#^key_file=.*#key_file=$tmp_dir/key#" "$tmp_dir/config"

tenancy=$(awk -F= '/^tenancy=/{print $2}' "$tmp_dir/config")
compartment=$(awk -F= '/^compartment-id=/{print $2}' "$tmp_dir/config")
compartment=${compartment:-$tenancy}
timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
printf '%s start name=%s shape=A1 ocpus=%s memory_gb=%s\n' "$timestamp" "$display_name" "$ocpus" "$memory_gb" >> "$log_file"

existing=$(oci --config-file "$tmp_dir/config" compute instance list --compartment-id "$compartment" --all --display-name "$display_name" --output json | jq -r '.data[] | select(."lifecycle-state" != "TERMINATED") | [.id,."lifecycle-state"] | @tsv' | head -1 || true)
if [[ -n "$existing" ]]; then printf '%s existing %s\n' "$timestamp" "$existing" | tee -a "$log_file"; exit 0; fi

image=$(oci --config-file "$tmp_dir/config" compute image list --compartment-id "$compartment" --operating-system 'Canonical Ubuntu' --sort-by TIMECREATED --sort-order DESC --all --output json | jq -r '.data[] | select(."display-name"|test("aarch64")) | .id' | head -1)
[[ -n "$image" ]] || { echo "no Ubuntu ARM image found" >&2; exit 1; }
subnet=$(oci --config-file "$tmp_dir/config" network subnet list --compartment-id "$compartment" --all --output json | jq -r '.data[] | select(."lifecycle-state" == "AVAILABLE") | .id' | head -1)
[[ -n "$subnet" ]] || { echo "no available subnet found" >&2; exit 1; }

while read -r ad; do
  if result=$(oci --config-file "$tmp_dir/config" compute instance launch --availability-domain "$ad" --compartment-id "$compartment" --subnet-id "$subnet" --shape VM.Standard.A1.Flex --shape-config "{\"ocpus\":$ocpus,\"memoryInGBs\":$memory_gb}" --image-id "$image" --assign-public-ip true --display-name "$display_name" --ssh-authorized-keys-file "$ssh_public_key" --output json 2>&1); then
    instance_id=$(jq -r '.data.id' <<<"$result")
    printf '%s success ad=%s id=%s\n' "$timestamp" "$ad" "$instance_id" | tee -a "$log_file"
    echo "$instance_id"
    exit 0
  fi
  printf '%s unavailable ad=%s\n' "$timestamp" "$ad" >> "$log_file"
done < <(oci --config-file "$tmp_dir/config" iam availability-domain list --compartment-id "$tenancy" --output json | jq -r '.data[].name')

printf '%s no-capacity\n' "$timestamp" | tee -a "$log_file"
exit 75
