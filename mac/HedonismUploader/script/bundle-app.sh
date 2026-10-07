#!/bin/sh
# Builds HedonismUploader.app (a menu bar app) into .build/HedonismUploader.app and signs it ad hoc.
# Usage: script/bundle-app.sh [version]
set -eu
cd "$(dirname "$0")/.."

version="${1:-1.0}"
swift build -c release --arch arm64 --arch x86_64
bin="$(swift build -c release --arch arm64 --arch x86_64 --show-bin-path)/HedonismUploader"

app=.build/HedonismUploader.app
rm -rf "$app"
mkdir -p "$app/Contents/MacOS"
cp "$bin" "$app/Contents/MacOS/HedonismUploader"
cat > "$app/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleIdentifier</key><string>social.hotmess.hedonism-uploader</string>
  <key>CFBundleName</key><string>Hedonism Uploader</string>
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
