#!/usr/bin/env bash
# Extracts a build-state artifact into the build root.
# Usage: extract_state.sh <state dir> <root>
# Handles the current tar.zst format and the older state.7z format, so
# trees uploaded before the switch can still seed a run.
set -euo pipefail

state=$1
root=$2
mkdir -p "$root"

if [ -f "$state/state.tar.zst" ]; then
  tar -I zstd -xf "$state/state.tar.zst" -C "$root"
elif [ -f "$state/state.7z" ]; then
  echo "Extracting legacy 7z state (mtimes are not exact; expect rebuilds)"
  rc=0
  "${ZBIN:-7z}" x "$state/state.7z" "-o$root" -y -bso0 -bsp0 || rc=$?
  # 7z exits with 1 for warnings (dangling symlinks in the tree).
  if [ "$rc" -gt 1 ]; then echo "extract failed"; exit 1; fi
else
  echo "no state archive in $state"
  ls -la "$state" || true
  exit 1
fi
