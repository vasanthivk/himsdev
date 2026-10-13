#!/usr/bin/env bash
# Copies the config files (.env, appsettings.json) from config/ back into the applications:
#   config/services/<app>/  ->  services/<app>/
#   config/frontend/<app>/  ->  frontend/<app>/
# Existing config files in the application folders are overwritten.
#
# Usage (from anywhere):  bash config/copy_config_to_app.sh

set -euo pipefail

CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$CONFIG_DIR")"

CONFIG_FILE_NAMES=(".env" "appsettings.json")

for area in services frontend; do
  src_root="$CONFIG_DIR/$area"
  dest_root="$ROOT_DIR/$area"

  if [ ! -d "$src_root" ]; then
    echo "WARNING: config/$area not found, skipped" >&2
    continue
  fi

  echo "$area:"
  for dir in "$src_root"/*/; do
    [ -d "$dir" ] || continue
    name="$(basename "$dir")"

    if [ ! -d "$dest_root/$name" ]; then
      echo "  WARNING: $area/$name does not exist, skipped" >&2
      continue
    fi

    for file in "${CONFIG_FILE_NAMES[@]}"; do
      if [ -f "$dir$file" ]; then
        cp "$dir$file" "$dest_root/$name/$file"
        echo "  config/$area/$name/$file -> $area/$name/$file"
      fi
    done
  done
done

echo "Done."
