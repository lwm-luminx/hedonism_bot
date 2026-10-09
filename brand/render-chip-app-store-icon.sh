#!/bin/sh
# Rebuild Chip's opaque App Store PNG from the vector master.
set -eu
repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
icon_dir="$repo_root/apple/iOS/Assets.xcassets/AppIcon.appiconset"
render_file=$(mktemp /tmp/chip-app-icon.XXXXXX)
trap 'rm -f "$render_file"' EXIT
rsvg-convert -w 1024 -h 1024 "$repo_root/brand/masters/chip-app-store.svg" -o "$render_file"
magick "$render_file" -background '#0f0f0f' -alpha remove -alpha off -colorspace sRGB "PNG24:$icon_dir/Chip-AppStore.png"
