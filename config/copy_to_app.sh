#!/usr/bin/env bash
# Copies the config files (.env, appsettings.json) from config/ back into the applications:
#   config/services/<app>/  ->  services/<app>/
#   config/frontend/<app>/  ->  frontend/<app>/
# Existing config files in the application folders are overwritten - so first they are backed up to
#   config/backup/<dd_MM_yyyy_HH_mm>/services/<app>/  and  config/backup/<dd_MM_yyyy_HH_mm>/frontend/<app>/
# To undo a copy, copy the files from that backup folder back into the applications.
#
# Usage (from anywhere):  bash config/copy_to_app.sh

set -euo pipefail

CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$CONFIG_DIR")"

CONFIG_FILE_NAMES=(".env" "appsettings.json")

# ---------------------------------------------------------------- 1. back up the applications' current config files

BACKUP_DIR="$CONFIG_DIR/backup/$(date +%d_%m_%Y_%H_%M)"
[ -e "$BACKUP_DIR" ] && BACKUP_DIR="${BACKUP_DIR}_$(date +%S)"   # run twice in the same minute: add the seconds

echo "Backup of the current application config -> config/backup/$(basename "$BACKUP_DIR")"
for area in services frontend; do
  for dir in "$ROOT_DIR/$area"/*/; do
    [ -d "$dir" ] || continue
    name="$(basename "$dir")"
    for file in "${CONFIG_FILE_NAMES[@]}"; do
      if [ -f "$dir$file" ]; then
        mkdir -p "$BACKUP_DIR/$area/$name"
        cp -p "$dir$file" "$BACKUP_DIR/$area/$name/$file"
        echo "  $area/$name/$file -> config/backup/$(basename "$BACKUP_DIR")/$area/$name/$file"
      fi
    done
  done
done
echo

# ---------------------------------------------------------------- 2. copy config/ into the applications

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
