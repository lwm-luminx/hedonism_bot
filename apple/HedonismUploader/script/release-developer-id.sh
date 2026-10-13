#!/bin/sh
# Archive, Developer ID sign, notarize and staple Cogsworth, package a notarized DMG and
# write a Sparkle appcast for it. COGSWORTH_PUBLISH=1 also publishes both to GitHub releases.
# Usage: script/release-developer-id.sh <version> <build-number>
#
# Needs a "Developer ID Application" certificate for team DWVXMLB45Y in the login keychain
# and an App Store Connect API key (Developer or Admin role). Credentials stay on this Mac:
#   ASC_KEY_ID      API key id (required)
#   ASC_ISSUER_ID   issuer id (required)
#   ASC_KEY_PATH    defaults to ~/.appstoreconnect/private_keys/AuthKey_$ASC_KEY_ID.p8
# Sparkle's EdDSA private key is in the login Keychain under account lumiere-cogsworth;
# SPARKLE_BIN points at the bin folder of the Sparkle release that holds sign_update.
# SPARKLE_KEY_FILE signs with an exported key file instead (no Keychain access prompt).
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
appcast="$out/appcast.xml"
tag="cogsworth-v$version-$build"
repo=lwm-luminx/hedonism_bot
sparkle_bin=${SPARKLE_BIN:-$HOME/Developer/Sparkle-tools/2.10.0/bin}
[ -x "$sparkle_bin/sign_update" ] || { echo "sign_update not found in $sparkle_bin" >&2; exit 1; }

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

# DeveloperID matches the AppStore configuration plus Sparkle and its installer entitlement.
"$package_dir/script/embed-sparkle.sh" --fetch
# shellcheck disable=SC2086
xcodebuild -project "$repo_dir/apple/LumiereUploader.xcodeproj" \
  -scheme Cogsworth-DeveloperID -configuration DeveloperID \
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
python3 "$repo_dir/apple/macOS/Tests/verify_entitlements.py" --developer-id "$app"

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

# Sparkle compares CFBundleVersion (the build number); the feed lists only the newest build.
if [ -n "${SPARKLE_KEY_FILE:-}" ]; then
  signature=$("$sparkle_bin/sign_update" --ed-key-file "$SPARKLE_KEY_FILE" "$dmg")
else
  # The first run asks to let sign_update read the Keychain item; choose Always Allow.
  signature=$("$sparkle_bin/sign_update" --account lumiere-cogsworth "$dmg")
fi
cat > "$appcast" <<XML
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>Cogsworth</title>
    <link>https://github.com/$repo/releases</link>
    <item>
      <title>Cogsworth $version</title>
      <pubDate>$(LC_ALL=C date -u '+%a, %d %b %Y %H:%M:%S +0000')</pubDate>
      <sparkle:version>$build</sparkle:version>
      <sparkle:shortVersionString>$version</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
      <sparkle:releaseNotesLink>https://github.com/$repo/releases/tag/$tag</sparkle:releaseNotesLink>
      <enclosure url="https://github.com/$repo/releases/download/$tag/Cogsworth-$version.dmg" type="application/octet-stream" $signature />
    </item>
  </channel>
</rss>
XML
xmllint --noout "$appcast"
echo "Notarized $dmg; appcast $appcast"

if [ "${COGSWORTH_PUBLISH:-0}" = 1 ]; then
  # Sparkle reads releases/latest/download/appcast.xml, so this release must be the latest.
  gh release create "$tag" "$dmg" "$appcast" -R "$repo" --target "$(git -C "$repo_dir" rev-parse HEAD)" \
    --title "Cogsworth $version (build $build)" --latest \
    --notes "Developer ID signed and notarized build of Cogsworth for macOS 14+ on Apple silicon. Requires a Lumière photographer account.

SHA-256: $(shasum -a 256 "$dmg" | cut -d' ' -f1)"
fi
