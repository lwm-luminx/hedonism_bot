#!/bin/sh
# Builds the Lumière Archive uploader (a menu bar app) as Cogsworth.app into .build/Cogsworth.app and signs it ad hoc.
# Usage: script/bundle-app.sh [version]
set -eu
cd "$(dirname "$0")/.."

version="${1:-1.0}"
swift build -c release --arch arm64 --arch x86_64
bin="$(swift build -c release --arch arm64 --arch x86_64 --show-bin-path)/HedonismUploader"

app=.build/Cogsworth.app
rm -rf "$app"
mkdir -p "$app/Contents/MacOS"
cp "$bin" "$app/Contents/MacOS/HedonismUploader"

# App icon from Resources/AppIcon-1024.png (rendered by brand/render.mjs at the repo root).
mkdir -p "$app/Contents/Resources"
iconset="$(mktemp -d)/AppIcon.iconset"
mkdir -p "$iconset"
for px in 16 32 128 256 512; do
  sips -z $px $px Resources/AppIcon-1024.png --out "$iconset/icon_${px}x${px}.png" >/dev/null
  sips -z $((px * 2)) $((px * 2)) Resources/AppIcon-1024.png --out "$iconset/icon_${px}x${px}@2x.png" >/dev/null
done
iconutil -c icns "$iconset" -o "$app/Contents/Resources/AppIcon.icns"
cat > "$app/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleIdentifier</key><string>social.hotmess.hedonism-uploader</string>
  <key>CFBundleName</key><string>Cogsworth</string>
  <key>CFBundleDisplayName</key><string>Cogsworth</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundleExecutable</key><string>HedonismUploader</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>${version}</string>
  <key>CFBundleVersion</key><string>${version}</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>LSUIElement</key><true/>
</dict>
</plist>
PLIST
codesign --force --sign - "$app"
echo "Built $app"
