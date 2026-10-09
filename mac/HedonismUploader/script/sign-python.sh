#!/bin/sh
set -eu
runtime=${1:?Pass the bundled Python directory}
identity=${COGSWORTH_SIGNING_IDENTITY:--}
worker_entitlements=${COGSWORTH_WORKER_ENTITLEMENTS:-}
if [ -n "$worker_entitlements" ] && [ ! -f "$worker_entitlements" ]; then
  echo "Worker entitlements file does not exist: $worker_entitlements" >&2
  exit 1
fi
# Sign the native libraries before their containing executables and final app.
find "$runtime" -type f \( -name '*.so' -o -name '*.dylib' \) -exec codesign --force --sign "$identity" {} \;
find "$runtime/bin" -type f -perm -111 -exec sh -c '
  identity=$1
  entitlements=$2
  shift 2
  for binary do
    if file "$binary" | grep -q "Mach-O"; then
      if [ -n "$entitlements" ]; then
        codesign --force --options runtime --entitlements "$entitlements" --sign "$identity" "$binary"
      else
        codesign --force --sign "$identity" "$binary"
      fi
    fi
  done
' sh "$identity" "$worker_entitlements" {} \;
