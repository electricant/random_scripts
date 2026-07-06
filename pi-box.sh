#!/usr/bin/env bash
set -euo pipefail
#
# pi-box — run the pi coding agent in a bubblewrap FS sandbox on NixOS.
#
# Boundary model:
#   - Writable inside the box: the current dir ($PWD) and ~/.pi (state, skills,
#     installed packages, npm cache). Nothing else from $HOME exists in the box.
#   - /nix/store is read-only (pi + node + all closures resolve from here).
#   - Network is OPEN (pi needs it; npm install needs it). No egress policy.
#   - npm is exposed on purpose: `pi install npm:/git:` works, including its
#     install-time arbitrary code. The box contains its *reach*, not its intent.
#
# Undo everything:  rm -rf "$PI_STATE"  (+ delete this script & alias)
# Nothing is written outside /nix/store and $PI_STATE.

# --- knobs ---------------------------------------------------------------
PI_STATE="${PI_STATE:-$HOME/.local/share/pi-sandbox}" # Persistent state
PI_FLAKE="${PI_FLAKE:-nixpkgs}"	# pin: github:NixOS/nixpkgs/<rev>
# The agent itself is fetched from the unstable repo
PI_AGENT="github:NixOS/nixpkgs/nixos-unstable#pi-coding-agent"

# Capability allowlist: every entry is a binary the agent's bash can reach.
PI_PKGS=(
  bubblewrap          # sandbox launcher (host side)
  nodejs              # node runtime + npm (npm required for `pi install` deps)
  git                 # git ops + `pi install git:`
  ripgrep             # pi's grep tool backend
  bash                # provides the shell npm needs to run lifecycle scripts
  # ---- file handling ----
  coreutils		    # ls, cat, cp, mv, rm, mkdir, head, tail, wc, sort, ...
  findutils           # find, xargs
  gnugrep             # grep
  gnused              # sed
  gawk                # awk
  which
  diffutils           # diff, cmp
  # ---- extras ----
  jq
  python314
  python314Packages.ddgs # for agent web search
  # gcc
  curl
)

# Per-invocation extra mounts (space-separated paths; survive the environment):
#   PI_RO="$HOME/ref /data/spec" pi      # expose read-only
#   PI_RW="$HOME/scratch2"       pi      # expose read-write
PI_RO="${PI_RO:-}"
PI_RW="${PI_RW:-}"
# -------------------------------------------------------------------------

mkdir -p "$PI_STATE/pi/.npm-cache"

pkgs=(); for p in "${PI_PKGS[@]}"; do pkgs+=("$PI_FLAKE#$p"); done

EXTRA_BWRAP=()                                   # genuinely empty — no phantom arg
for p in $PI_RO; do EXTRA_BWRAP+=( --ro-bind "$p" "$p" ); done
for p in $PI_RW; do EXTRA_BWRAP+=( --bind    "$p" "$p" ); done

exec nix shell "$PI_AGENT" "${pkgs[@]}" -c \
  bwrap \
    --unshare-all --share-net --die-with-parent \
    --ro-bind /nix/store /nix/store \
    --ro-bind-try /etc/static       /etc/static \
    --ro-bind-try /etc/ssl          /etc/ssl \
    --ro-bind-try /etc/resolv.conf  /etc/resolv.conf \
    --ro-bind-try /etc/passwd       /etc/passwd \
    --ro-bind-try /etc/group        /etc/group \
    --proc /proc --dev /dev --tmpfs /tmp \
    --setenv npm_config_cache "$HOME/.pi/.npm-cache" \
    --bind "$PWD"          "$PWD" \
    --bind "$PI_STATE/pi"  "$HOME/.pi" \
    --chdir "$PWD" \
    "${EXTRA_BWRAP[@]}" \
    pi "$@"
