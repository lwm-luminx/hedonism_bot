#!/bin/sh
# Download the pinned Sparkle release, verify it, and embed Sparkle.framework in the app.
# Run by Xcode for the DeveloperID configuration only; the App Store build never ships Sparkle.
# Usage: script/embed-sparkle.sh <app Frameworks folder>
#        script/embed-sparkle.sh --fetch   (download only; run before xcodebuild, because Swift
#                                          resolves `import Sparkle` before build phases run)
set -eu
version=2.10.0
sha256=c2bf58aa8387266ac179357b1415d6f2635f044da8be41042af32425dae6da0c
package_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cache="$package_dir/.build/sparkle"
frameworks=${1:?Pass the app Frameworks folder or --fetch}

if [ ! -d "$cache/$version/Sparkle.framework" ]; then
  mkdir -p "$cache"
  archive="$cache/Sparkle-$version.tar.xz"
  curl --fail --location --silent --show-error -o "$archive" \
    "https://github.com/sparkle-project/Sparkle/releases/download/$version/Sparkle-$version.tar.xz"
  echo "$sha256  $archive" | shasum -a 256 -c -
  rm -rf "$cache/$version.tmp"
  mkdir -p "$cache/$version.tmp"
  tar -xJf "$archive" -C "$cache/$version.tmp"
  rm -rf "$cache/$version"
  mv "$cache/$version.tmp" "$cache/$version"
fi
# The linker finds Sparkle through FRAMEWORK_SEARCH_PATHS = .build/sparkle/current.
# A real folder here (left by an older build listing a path inside it) would capture the link.
[ -L "$cache/current" ] || rm -rf "$cache/current"
ln -sfn "$version" "$cache/current"
[ "$frameworks" = --fetch ] && exit 0

mkdir -p "$frameworks"
rm -rf "$frameworks/Sparkle.framework"
ditto "$cache/$version/Sparkle.framework" "$frameworks/Sparkle.framework"

# Re-sign inside out with the app's identity so hardened-runtime library validation sees one
# Team ID. Xcode's Developer ID export re-signs again with timestamps.
if [ "${CODE_SIGNING_ALLOWED:-NO}" = YES ] && [ -n "${EXPANDED_CODE_SIGN_IDENTITY:-}" ]; then
  framework="$frameworks/Sparkle.framework"
  sign() { codesign --force --options runtime --sign "$EXPANDED_CODE_SIGN_IDENTITY" "$@"; }
  sign "$framework/Versions/B/XPCServices/Installer.xpc"
  sign --preserve-metadata=entitlements "$framework/Versions/B/XPCServices/Downloader.xpc"
  sign "$framework/Versions/B/Autoupdate"
  sign "$framework/Versions/B/Updater.app"
  sign "$framework"
fi
