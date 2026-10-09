#!/bin/sh
# Build-time only: assemble a relocatable CPython and the locked worker dependencies.
set -eu
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
package_dir=$(CDPATH= cd -- "$script_dir/.." && pwd)
repo_dir=$(CDPATH= cd -- "$script_dir/../../.." && pwd)
destination=${1:?Pass the app Resources/Python directory}
case "$(uname -m)" in
  arm64) ;;
  *) echo "The locked ML dependencies require an Apple silicon build host." >&2; exit 1 ;;
esac
command -v uv >/dev/null || { echo "Install uv on the build host first." >&2; exit 1; }
cache="$package_dir/.build/bundled-python"
mkdir -p "$cache"
export UV_CACHE_DIR="$cache/uv-cache"
export UV_LINK_MODE=copy
uv python install 3.13.16 --install-dir "$cache/managed" --no-bin
python_source="$cache/managed/cpython-3.13.16-macos-aarch64-none"
[ -x "$python_source/bin/python3.13" ] || { echo "Managed CPython 3.13.16 was not installed." >&2; exit 1; }
runtime="$cache/runtime"
requirements="$cache/requirements.txt"
uv export --quiet --project "$repo_dir/who_dis" --frozen --no-dev --no-emit-project --format requirements-txt --output-file "$requirements"
stamp="3.13.16-$(shasum -a 256 "$requirements" | cut -d ' ' -f 1)"
if [ ! -f "$runtime/.dependencies-$stamp" ]; then
  rm -rf "$runtime"
  ditto "$python_source" "$runtime"
  # This is our private app copy, no longer an installation maintained by uv.
  rm -f "$runtime/lib/python3.13/EXTERNALLY-MANAGED"
  uv pip sync --python "$runtime/bin/python3.13" --system --require-hashes --only-binary=:all: "$requirements"
  touch "$runtime/.dependencies-$stamp"
fi
site="$runtime/lib/python3.13/site-packages"
rm -rf "$site/hedonism"
ditto "$repo_dir/who_dis/hedonism" "$site/hedonism"
cp "$requirements" "$runtime/requirements.txt"
"$runtime/bin/python3.13" -I -c 'import gql, PIL, torch, torchvision, tensorflow, tf_keras, transformers; from deepface import DeepFace; print("Bundled dependencies verified")'
"$runtime/bin/python3.13" -I -B -c 'import sys; from hedonism.who_dis.app import TASKS; assert "torch" not in sys.modules; assert "transformers" not in sys.modules; assert "deepface" not in sys.modules; assert len(TASKS) == 3; print("Offline task registration verified")'
mkdir -p "$destination"
ditto "$runtime" "$destination"
