#!/usr/bin/env bash
# Collects the config files (.env, appsettings.json) from every service and frontend app
# into config/, mirroring the folder structure of services/ and frontend/.
# Existing config/services and config/frontend folders are deleted first.
#
# Usage (from anywhere):  bash config/copy_app_to_config.sh

set -euo pipefail

CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$CONFIG_DIR")"

CONFIG_FILE_NAMES=(".env" "appsettings.json")

for area in services frontend; do
  dest="$CONFIG_DIR/$area"
  if [ -d "$dest" ]; then
    rm -rf "$dest"
    echo "Deleted config/$area"
  fi
done

for area in services frontend; do
  src_root="$ROOT_DIR/$area"
  dest_root="$CONFIG_DIR/$area"
  echo "$area:"

  for dir in "$src_root"/*/; do
    name="$(basename "$dir")"
    mkdir -p "$dest_root/$name"

    for file in "${CONFIG_FILE_NAMES[@]}"; do
      if [ -f "$dir$file" ]; then
        cp "$dir$file" "$dest_root/$name/$file"
        echo "  $area/$name/$file -> config/$area/$name/$file"
      fi
    done
  done
done

echo "Done."
