# Tailnet Fleet Enrollment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enroll all reachable non-member hosts in the tailnet, provide a usable Tailscale CLI on each reachable host, and publish verified tailnet SSH aliases in dotfiles.

**Architecture:** Use the official stable package on Linux and a one-shot, protected process environment for the reusable auth key. Existing memberships are preserved; only hosts in `NeedsLogin` or without Tailscale are changed. After enrollment, discover each machine's MagicDNS name and tailnet IP, add a non-conflicting SSH alias to `ssh/config`, then push the verified configuration.

**Tech Stack:** Tailscale stable packages, systemd, macOS Tailscale app CLI integration, OpenSSH, Git.

**Spec:** `docs/superpowers/specs/2026-09-27-tailnet-fleet-enrollment-design.md`

## Global Constraints

- Do not persist the reusable auth key in Git, shell history, service units, host configuration, or command output.
- Do not set tags, routes, exit-node settings, or Tailscale SSH.
- Preserve existing Tailscale memberships and settings.
- Use an official stable package and enable `tailscaled` at boot on Linux.
- Prefer MagicDNS names for new SSH aliases; retain existing LAN aliases and users/ports.
- Treat `msi`, `win-desktop`, and `wsl-desktop` as pending while unreachable; exclude `docker-lxc`.

## Review Focus

- Auth-key leakage: inspect Git, unit files, shell history, and process arguments after enrollment; no auth-key material may remain.
- Existing-member preservation: `smb-srv`, `img-srv`, `ediacarian`, the MacBook, DGX, and Windows desktop must retain their current tailnet identities.
- Boot persistence: every newly enrolled Linux host must report `tailscaled` enabled and active after setup.
- SSH alias correctness: aliases must resolve to a discovered MagicDNS name and authenticate with the configured user/port.
- Partial fleet failure: an installation or join failure must leave the host unchanged beyond package installation and be reported, not masked.

---

### Task 1: Preflight and protected enrollment context

**Files:**
- Modify: none
- Test: per-host status capture

**Interfaces:**
- Consumes: reusable auth key supplied out-of-band by the user.
- Produces: a per-host inventory of OS, Tailscale state, hostname, and pre-existing settings.

- [ ] **Step 1: Capture baseline Tailscale status for every reachable host**

Run `tailscale status --json` where installed and record hostname, backend state, tailnet IPs, advertised routes, exit-node state, and SSH setting without exposing credentials.

- [ ] **Step 2: Verify the auth key is available only to a root-owned one-shot environment**

Use a protected temporary environment or root-owned file descriptor; verify it is absent from command arguments and persistent files before the first enrollment.

- [ ] **Step 3: Confirm the preflight test passes**

Expected: targets are partitioned into already enrolled, needs login, not installed, and unreachable; no existing-member settings are scheduled for modification.

### Task 2: Install and enroll reachable Linux targets

**Files:**
- Modify: OS package sources and package database only as required by the official Tailscale stable installer.
- Test: `tailscale status --json`, `systemctl is-enabled tailscaled`, `systemctl is-active tailscaled`.

**Interfaces:**
- Consumes: Task 1 target inventory and protected auth-key environment.
- Produces: a running, boot-enabled Tailscale member with a usable `/usr/bin/tailscale` CLI.

- [ ] **Step 1: Probe each target package manager and release**

Targets: Proxmox, `mcp-srv`, `vpn-srv`, `oidc-srv`, `dns-srv`, `sh-srv`, `md-srv`, and `log-srv`. Record the native package manager and do not modify a host with an unsupported platform until its install method is reviewed.

- [ ] **Step 2: Install the official stable Tailscale package on each missing target**

Use Tailscale's supported installation path for the detected Linux distribution. Start and enable `tailscaled`; do not change its default route acceptance, advertised routes, exit-node role, or SSH mode.

- [ ] **Step 3: Enroll only `NeedsLogin` or newly installed hosts**

Run `tailscale up --auth-key` through the protected environment. Do not run `tailscale up` on hosts already in the tailnet.

- [ ] **Step 4: Verify each Linux enrollment**

Expected per changed host: `tailscale status --json` is `Running`, `tailscale ip -4` returns one address, `/usr/bin/tailscale` runs, and `tailscaled` is enabled and active.

### Task 3: Expose the MacBook CLI without changing membership

**Files:**
- Modify: only the Mac's CLI integration or user shell configuration if the app cannot install its launcher.
- Test: `tailscale status` through the launcher/alias and comparison of tailnet identity before and after.

**Interfaces:**
- Consumes: existing app enrollment on `Jacks-MacBook-Air`.
- Produces: a `tailscale` command usable from its terminal.

- [ ] **Step 1: Detect the installed macOS Tailscale variant and existing CLI location**

Check whether supported CLI integration can install `/usr/local/bin/tailscale`; otherwise locate `/Applications/Tailscale.app/Contents/MacOS/Tailscale`.

- [ ] **Step 2: Install the supported launcher or a shell alias using `TAILSCALE_BE_CLI=1`**

Do not replace the existing macOS Tailscale app or invoke authentication.

- [ ] **Step 3: Verify Mac CLI behavior and membership preservation**

Expected: `tailscale status` works from a login shell and reports the same tailnet device identity as preflight.

### Task 4: Publish and verify tailnet SSH aliases

**Files:**
- Modify: `ssh/config`
- Test: `ssh -G new-tailnet-alias` and `ssh new-tailnet-alias true` from an enrolled source host.

**Interfaces:**
- Consumes: verified MagicDNS names, tailnet IPs, login users, and ports from Tasks 2–3.
- Produces: one new non-conflicting tailnet alias per enrolled host.

- [ ] **Step 1: Discover verified MagicDNS names and SSH endpoints**

Use the tailnet status output after enrollment. Preserve existing LAN aliases; use `hostname-tailnet` naming when no alias already exists.

- [ ] **Step 2: Add minimal SSH entries to `ssh/config`**

For each newly enrolled host, set `HostName` to its MagicDNS name and preserve the host's verified `User` and any non-default `Port`. Do not add credentials or private material.

- [ ] **Step 3: Test each new alias from an enrolled Linux source**

Expected: `ssh -G` shows the intended endpoint and `ssh new-tailnet-alias true` succeeds without changing known-hosts policy globally.

- [ ] **Step 4: Commit and push the shared SSH configuration and enrollment documentation**

Run `git diff --check`, commit `ssh/config` and the approved design/plan documents, then push `main`.

### Task 5: Fleet reconciliation and final verification

**Files:**
- Modify: each reachable host's dotfiles checkout through a normal fast-forward update.
- Test: `git status --porcelain=v1`, `git rev-parse HEAD`, Tailscale state, and SSH alias tests.

**Interfaces:**
- Consumes: pushed canonical SSH configuration from Task 4.
- Produces: a final per-host status report.

- [ ] **Step 1: Fast-forward each reachable dotfiles checkout to the pushed canonical commit**

Do not overwrite a new local change; inspect and reconcile it before updating.

- [ ] **Step 2: Verify fleet state and secret hygiene**

Expected: every changed host has the canonical commit, an enabled/running Tailscale daemon or preserved existing membership, a usable CLI, and no persisted auth key. Mark offline or unreachable hosts pending with the observed reason.

- [ ] **Step 3: Commit any final tracked documentation-only changes**

Run `git diff --check`, commit only intentional tracked changes, and verify `main` is synchronized with `origin/main`.
