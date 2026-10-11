#!/bin/sh
# Archive, Developer ID sign, notarize and staple Cogsworth, then package a notarized DMG.
# Usage: script/release-developer-id.sh <version> <build-number>
#
# Needs a "Developer ID Application" certificate for team DWVXMLB45Y in the login keychain
# and an App Store Connect API key (Developer or Admin role). Credentials stay on this Mac:
#   ASC_KEY_ID      API key id (required)
#   ASC_ISSUER_ID   issuer id (required)
#   ASC_KEY_PATH    defaults to ~/.appstoreconnect/private_keys/AuthKey_$ASC_KEY_ID.p8
set -eu
version=${1:?Pass the marketing version, e.g. 1.0.0}
build=${2:?Pass a build number higher than any earlier upload}
key_id=${ASC_KEY_ID:?Set ASC_KEY_ID to the App Store Connect API key id}
issuer=${ASC_ISSUER_ID:?Set ASC_ISSUER_ID to the App Store Connect issuer id}
key_path=${ASC_KEY_PATH:-$HOME/.appstoreconnect/private_keys/AuthKey_$key_id.p8}
[ -f "$key_path" ] || { echo "API key not found: $key_path" >&2; exit 1; }

package_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
repo_dir=$(CDPATH= cd -- "$package_dir/../.." && pwd)
team=DWVXMLB45Y
out=${COGSWORTH_RELEASE_DIR:-$package_dir/.build/developer-id/$version-$build}
archive="$out/Cogsworth.xcarchive"
export_dir="$out/export"
app="$export_dir/Cogsworth.app"
dmg="$out/Cogsworth-$version.dmg"

if ! security find-identity -v -p codesigning | grep -q "Developer ID Application: .*($team)"; then
  echo "No Developer ID Application identity for team $team in the keychain" >&2
  exit 1
fi
identity=$(security find-identity -v -p codesigning \
  | sed -n "s/.*\"\(Developer ID Application: .*($team)\)\"/\1/p" | head -n 1)

auth="-authenticationKeyPath $key_path -authenticationKeyID $key_id -authenticationKeyIssuerID $issuer"
notary="--key $key_path --key-id $key_id --issuer $issuer"

notarize() {
  # Submit, wait, and print Apple's log when the submission is not accepted.
  result=$(xcrun notarytool submit "$1" $notary --wait --output-format plist || true)
  status=$(printf '%s' "$result" | plutil -extract status raw -o - -)
  id=$(printf '%s' "$result" | plutil -extract id raw -o - -)
  echo "Notarization $id: $status"
  if [ "$status" != Accepted ]; then
    xcrun notarytool log "$id" $notary
    exit 1
  fi
}

rm -rf "$out"
mkdir -p "$out"

# The AppStore configuration already carries the sandbox and hardened runtime settings.
# shellcheck disable=SC2086
xcodebuild -project "$repo_dir/apple/LumiereUploader.xcodeproj" \
  -scheme Cogsworth-AppStore -configuration AppStore \
  -destination 'generic/platform=macOS' -archivePath "$archive" \
  -allowProvisioningUpdates $auth DEVELOPMENT_TEAM=$team \
  MARKETING_VERSION="$version" CURRENT_PROJECT_VERSION="$build" archive

# shellcheck disable=SC2086
xcodebuild -exportArchive -archivePath "$archive" -exportPath "$export_dir" \
  -exportOptionsPlist "$repo_dir/apple/macOS/ExportOptions-DeveloperID.plist" \
  -allowProvisioningUpdates $auth

codesign --verify --deep --strict --verbose=2 "$app"
codesign -dvv "$app" 2>&1 | grep -q "Authority=Developer ID Application" \
  || { echo "Exported app is not Developer ID signed" >&2; exit 1; }
python3 "$repo_dir/apple/macOS/Tests/verify_entitlements.py" "$app"

ditto -c -k --keepParent "$app" "$out/Cogsworth.zip"
notarize "$out/Cogsworth.zip"
xcrun stapler staple "$app"
xcrun stapler validate "$app"
spctl --assess --type execute -vvv "$app"

staging="$out/dmg"
mkdir -p "$staging"
ditto "$app" "$staging/Cogsworth.app"
ln -s /Applications "$staging/Applications"
hdiutil create -volname Cogsworth -srcfolder "$staging" -fs HFS+ -format UDZO -ov "$dmg"
codesign --force --timestamp --sign "$identity" "$dmg"
notarize "$dmg"
xcrun stapler staple "$dmg"
xcrun stapler validate "$dmg"
spctl --assess --type open --context context:primary-signature -vvv "$dmg"
shasum -a 256 "$dmg"
echo "Notarized $dmg"
