#!/bin/sh
# Offline launchd/XPC + embedded Python smoke test in a disposable, team-signed app.
set -eu
source_app=${1:?Pass the built Cogsworth.app}
identity=${COGSWORTH_SIGNING_IDENTITY:?Set a development or Developer ID signing identity for hardened-runtime validation}
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_dir=$(CDPATH= cd -- "$script_dir/../../.." && pwd)
test_dir=$(mktemp -d /tmp/Cogsworth-XPC-Smoke.XXXXXX)
fixture_pid=
trap 'result=$?; if [ -n "$fixture_pid" ]; then kill "$fixture_pid" 2>/dev/null || true; wait "$fixture_pid" 2>/dev/null || true; fi; if [ "$result" -eq 0 ]; then rm -rf "$test_dir"; else echo "Failed smoke bundle retained at $test_dir" >&2; fi' EXIT
app="$test_dir/Cogsworth.app"
# Fresh identities keep the smoke test out of existing app/service containers.
test_id="social.hotmess.CogsworthSmoke.$(uuidgen | tr '[:upper:]' '[:lower:]')"
# APFS clones keep the 2GB ML runtime inexpensive to copy; ditto is the fallback.
cp -cR "$source_app" "$app" || ditto "$source_app" "$app"
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $test_id" "$app/Contents/Info.plist"
for service in Uploader ML; do
  /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $test_id.$service" "$app/Contents/XPCServices/Cogsworth$service.xpc/Contents/Info.plist"
done
swiftc -parse-as-library -module-name CogsworthIPC -target arm64-apple-macos14.0 \
  "$repo_dir/mac/HedonismUploader/Sources/CogsworthIPC/Protocols.swift" \
  "$repo_dir/apple/macOS/Tests/XPCSmoke.swift" -o "$app/Contents/MacOS/Cogsworth"
framework="$app/Contents/XPCServices/CogsworthML.xpc/Contents/Frameworks/Python.framework"
find "$framework/Versions/3.13" -type f \( -name '*.so' -o -name '*.dylib' -o -name Python \)   -exec codesign --force --timestamp=none --sign "$identity" {} \;
codesign --force --timestamp=none --options runtime --sign "$identity" \
  --entitlements "$repo_dir/apple/macOS/MLXPC/PythonChild.entitlements" \
  "$framework/Resources/lib/python3.13/site-packages/torch/bin/torch_shm_manager"
codesign --force --timestamp=none --sign "$identity" "$framework"
for service in Uploader ML; do
  codesign --force --timestamp=none --options runtime --sign "$identity" \
    --entitlements "$repo_dir/apple/macOS/${service}XPC/$service.entitlements" \
    "$app/Contents/XPCServices/Cogsworth$service.xpc"
done
codesign --force --timestamp=none --options runtime --sign "$identity" \
  --entitlements "$repo_dir/apple/macOS/Cogsworth.entitlements" "$app"
codesign --verify --deep --strict "$app"
python3 "$repo_dir/apple/macOS/Tests/verify_entitlements.py" "$app"
python3 "$repo_dir/apple/macOS/Tests/upload_fixture.py" "$test_dir/fixture-url" >"$test_dir/fixture.log" 2>&1 &
fixture_pid=$!
attempt=0
until [ -s "$test_dir/fixture-url" ]; do
  kill -0 "$fixture_pid" 2>/dev/null || { cat "$test_dir/fixture.log" >&2; exit 1; }
  attempt=$((attempt + 1))
  [ "$attempt" -lt 50 ] || { echo "Upload fixture did not start" >&2; exit 1; }
  sleep 0.1
done
"$app/Contents/MacOS/Cogsworth" "$(cat "$test_dir/fixture-url")"
