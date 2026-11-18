#!/usr/bin/env bash
# Brings a restored (already patched) Chromium tree in line with the patches
# in this repository: reverts the patches recorded in the tree, applies the
# current ones, and restores the modification time of every file whose
# content ended up unchanged so that only real changes are recompiled.
#
# Bash port of update_patches.ps1 (used by the Linux build stages).
# Usage: update_patches.sh <Root> <NewPatches>
set -euo pipefail

Root="$1"
NewPatches="$2"
src="$Root/src"
applied="$Root/applied_patches"

if [ ! -d "$applied" ]; then
  echo "no applied_patches directory in the restored tree" >&2
  exit 1
fi

# "<name>:<sha256>;" for every patch in a directory, in name order.
signature() {
  local d="$1" f h out=""
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    [ -e "$f" ] || continue
    h=$(sha256sum "$f" | cut -d' ' -f1)
    out+=$(basename "$f"):${h};
  done < <(find "$d" -maxdepth 1 -name '*.patch' | sort)
  printf '%s' "$out"
}

if [ "$(signature "$applied")" = "$(signature "$NewPatches")" ]; then
  echo "Patches unchanged."
  exit 0
fi

# Target files of every diff in a directory, one per line.
patched_files() {
  local d="$1" f
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    [ -e "$f" ] || continue
    grep -Eo '^diff --git a/[^ ]+ b/[^ ]+$' "$f" | sed -E 's#^diff --git a/[^ ]+ b/##'
  done < <(find "$d" -maxdepth 1 -name '*.patch' | sort)
}

mapfile -t files < <({ patched_files "$applied"; patched_files "$NewPatches"; } | sort -u)

declare -A before_hash before_time
for file in "${files[@]}"; do
  p="$src/$file"
  if [ -f "$p" ]; then
    before_hash[$file]=$(sha256sum "$p" | cut -d' ' -f1)
    before_time[$file]=$(stat -c %Y "$p")
  fi
done

cd "$src"
while IFS= read -r f; do
  [ -n "$f" ] || continue
  [ -e "$f" ] || continue
  echo "Reverting $(basename "$f")"
  git apply -R --whitespace=nowarn "$f"
done < <(find "$applied" -maxdepth 1 -name '*.patch' | sort -r)
while IFS= read -r f; do
  [ -n "$f" ] || continue
  [ -e "$f" ] || continue
  echo "Applying $(basename "$f")"
  git apply --whitespace=nowarn "$f"
done < <(find "$NewPatches" -maxdepth 1 -name '*.patch' | sort)

changed=0
for file in "${files[@]}"; do
  p="$src/$file"
  if [ -n "${before_hash[$file]:-}" ] && [ -f "$p" ]; then
    if [ "$(sha256sum "$p" | cut -d' ' -f1)" = "${before_hash[$file]}" ]; then
      touch -d "@${before_time[$file]}" "$p"
    else
      changed=$((changed + 1))
      echo "Changed: $file"
    fi
  else
    changed=$((changed + 1))
    echo "Changed: $file"
  fi
done
echo "$changed of ${#files[@]} patched files changed."

rm -rf "$applied"
mkdir -p "$applied"
cp "$NewPatches"/*.patch "$applied"/
