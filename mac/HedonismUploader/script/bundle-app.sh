#!/bin/sh
# Build the native app and both XPC services. SwiftPM alone cannot assemble XPC bundles.
# Usage: script/bundle-app.sh [version] [build-number]
set -eu
package_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
repo_dir=$(CDPATH= cd -- "$package_dir/../.." && pwd)
identity=${COGSWORTH_SIGNING_IDENTITY:?Set an Apple Development or Developer ID signing identity; embedded Python requires matching Team IDs with hardened runtime}
export COGSWORTH_SIGNING_IDENTITY="$identity"
xcodebuild -project "$repo_dir/apple/LumiereUploader.xcodeproj" \
  -scheme Cogsworth-AppStore -configuration AppStore -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath "$package_dir/.build/xcode" CODE_SIGNING_ALLOWED=NO \
  MARKETING_VERSION="${1:-1.0.0}" CURRENT_PROJECT_VERSION="${2:-1}" build
app="$package_dir/.build/Cogsworth.app"
rm -rf "$app"
ditto "$package_dir/.build/xcode/Build/Products/AppStore/Cogsworth.app" "$app"
for service in Uploader ML; do
  codesign --force --options runtime --sign "$identity" \
    --entitlements "$repo_dir/apple/macOS/${service}XPC/$service.entitlements" \
    "$app/Contents/XPCServices/Cogsworth$service.xpc"
done
codesign --force --options runtime --sign "$identity" \
  --entitlements "$repo_dir/apple/macOS/Cogsworth.entitlements" "$app"
codesign --verify --deep --strict "$app"
python3 "$repo_dir/apple/macOS/Tests/verify_entitlements.py" "$app"
echo "Built $app (local build; distribution still requires provisioning and validation)"
