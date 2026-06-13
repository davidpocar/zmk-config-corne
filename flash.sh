#!/usr/bin/env bash
set -euo pipefail

DEV_LABEL="/dev/disk/by-label/NICENANO"
POLL_INTERVAL=1

usage() {
    echo "Usage: $0 <firmware.zip>"
    echo "Extracts firmware and flashes both Corne halves sequentially."
    exit 1
}

[[ $# -ne 1 ]] && usage
[[ ! -f "$1" ]] && echo "Error: '$1' not found." && exit 1

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

echo "Extracting $1..."
unzip -q "$1" -d "$tmp"

left=$(find "$tmp" -iname '*left*.uf2' | head -1)
right=$(find "$tmp" -iname '*right*.uf2' | head -1)

[[ -z "$left" ]] && echo "Error: No UF2 file with 'left' found in archive." && exit 1
[[ -z "$right" ]] && echo "Error: No UF2 file with 'right' found in archive." && exit 1

echo "Found: $(basename "$left")"
echo "Found: $(basename "$right")"

flash_side() {
    local label=$1 uf2=$2

    echo ""
    echo ">>> Put the $label half into bootloader mode (double-tap reset)"

    while [[ ! -e "$DEV_LABEL" ]]; do
        sleep "$POLL_INTERVAL"
    done

    echo "Detected NICENANO..."
    local dev mount_path
    dev=$(readlink -f "$DEV_LABEL")
    mount_path=$(lsblk -no MOUNTPOINT "$dev" | head -1)

    if [[ -z "$mount_path" ]]; then
        udisksctl mount -b "$dev"
        mount_path=$(lsblk -no MOUNTPOINT "$dev" | head -1)
    fi

    echo "Flashing $label..."
    cp "$uf2" "$mount_path/"
    sync

    echo "Waiting for $label to disconnect..."
    while [[ -e "$DEV_LABEL" ]]; do
        sleep "$POLL_INTERVAL"
    done

    echo "$label done."
}

flash_side "LEFT" "$left"
flash_side "RIGHT" "$right"

echo ""
echo "Both halves flashed successfully."
