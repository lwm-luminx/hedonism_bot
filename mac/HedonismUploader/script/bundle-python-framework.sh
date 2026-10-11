#!/bin/sh
# Build-time only. Embed libpython and the locked environment inside the ML XPC bundle.
set -eu
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
package_dir=$(CDPATH= cd -- "$script_dir/.." && pwd)
framework=${1:?Pass the destination Python.framework}
identity=${COGSWORTH_SIGNING_IDENTITY:-${EXPANDED_CODE_SIGN_IDENTITY:--}}
[ -n "$identity" ] || identity=-
stamp=$(python3 - "$package_dir" "$identity" <<'STAMP'
import hashlib, pathlib, sys
package = pathlib.Path(sys.argv[1])
repo = package.parent.parent
paths = [package / "script/bundle-python-framework.sh", package / "script/bundle-python.sh", repo / "who_dis/uv.lock", repo / "who_dis/pyproject.toml", repo / "apple/macOS/MLXPC/PythonChild.entitlements"]
paths += sorted((repo / "who_dis/hedonism").rglob("*.py"))
h = hashlib.sha256(sys.argv[2].encode())
for path in paths:
    h.update(str(path).encode()); h.update(path.read_bytes())
print(h.hexdigest())
STAMP
)
if [ -f "$framework/Resources/.source-digest" ] && [ "$(cat "$framework/Resources/.source-digest")" = "$stamp" ]; then
  exit 0
fi
stage="$package_dir/.build/bundled-python/xpc-input"
rm -rf "$stage"
"$script_dir/bundle-python.sh" "$stage"
# Always assemble a fresh tree: removed dependencies must not survive in a signed bundle.
rm -rf "$framework"
version="$framework/Versions/3.13"
mkdir -p "$version/Resources/lib"
ditto "$stage/lib/python3.13" "$version/Resources/lib/python3.13"
# Static development archives are not used by the embedded interpreter. Xcode strips
# them during app embedding, which would invalidate the framework resource seal.
find "$version/Resources/lib" -type f -name '*.a' -delete
# Protocol compilers are build tools, not inference dependencies.
rm -f "$version/Resources/lib/python3.13/site-packages/torch/bin/protoc" \
  "$version/Resources/lib/python3.13/site-packages/torch/bin/protoc-3.13.0.0"
: > "$version/Resources/openssl.cnf"
cp "$stage/lib/libpython3.13.dylib" "$version/Python"
install_name_tool -id '@rpath/Python.framework/Versions/3.13/Python' "$version/Python"
ln -s 3.13 "$framework/Versions/Current"
ln -s Versions/Current/Python "$framework/Python"
ln -s Versions/Current/Resources "$framework/Resources"
cat > "$version/Resources/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>host.lumiere.Cogsworth.Python</string>
<key>CFBundleName</key><string>Python</string>
<key>CFBundleExecutable</key><string>Python</string>
<key>CFBundlePackageType</key><string>FMWK</string>
<key>CFBundleVersion</key><string>3.13.16</string>
<key>CFBundleShortVersionString</key><string>3.13.16</string>
</dict></plist>
PLIST
# Libraries must be relocatable and carry the same signing identity as their host.
# Native extensions remain alongside their package data in the private framework.
identity=${COGSWORTH_SIGNING_IDENTITY:-${EXPANDED_CODE_SIGN_IDENTITY:--}}
[ -n "$identity" ] || identity=-
find "$version" -type f \( -name "*.so" -o -name "*.dylib" -o -perm -111 \) -exec sh -eu -c '
  identity=$1; shift
  for binary do
    case "$(file -b "$binary")" in *Mach-O*) ;; *) continue ;; esac
    # CPython extensions may link the interpreter using the build-host install path.
    otool -L "$binary" | tail -n +2 | while IFS= read -r entry; do
      # Universal binaries print a "<path> (architecture …):" header per slice.
      case "$entry" in *:) continue ;; esac
      dependency=${entry%% (compatibility*}
      dependency=$(printf "%s" "$dependency" | sed "s/^[[:space:]]*//")
      case "$dependency" in
        /*/libpython3.13.dylib) install_name_tool -change "$dependency" "@rpath/Python.framework/Versions/3.13/Python" "$binary" ;;
        /opt/homebrew/*|/usr/local/*|/Users/*) echo "Nonrelocatable dependency: $dependency in $binary" >&2; exit 1 ;;
      esac
    done
    codesign --force --sign "$identity" "$binary"
  done
' sh "$identity" {} +
# PyTorch requires this utility to exist even for single-process inference.
# If launched by PyTorch, it inherits only its parent ML service's sandbox.
codesign --force --options runtime --sign "$identity" \
  --entitlements "$package_dir/../../apple/macOS/MLXPC/PythonChild.entitlements" \
  "$version/Resources/lib/python3.13/site-packages/torch/bin/torch_shm_manager"
printf "%s" "$stamp" > "$version/Resources/.source-digest"
codesign --force --sign "$identity" "$framework"
