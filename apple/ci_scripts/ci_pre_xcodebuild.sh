#!/bin/sh
set -eu

echo "=== Xcode Cloud: Running ci_pre_xcodebuild.sh ==="

export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"

# Resolve directories
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
if [ -d "$SCRIPT_DIR/../HedonismUploader" ]; then
    APPLE_DIR="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"
    REPO_DIR="$(CDPATH= cd -- "$APPLE_DIR/.." && pwd)"
elif [ -d "$SCRIPT_DIR/apple/HedonismUploader" ]; then
    REPO_DIR="$SCRIPT_DIR"
    APPLE_DIR="$REPO_DIR/apple"
elif [ -n "${CI_PRIMARY_REPOSITORY_PATH:-}" ]; then
    REPO_DIR="$CI_PRIMARY_REPOSITORY_PATH"
    APPLE_DIR="$REPO_DIR/apple"
elif [ -n "${CI_WORKSPACE:-}" ]; then
    REPO_DIR="$CI_WORKSPACE"
    APPLE_DIR="$REPO_DIR/apple"
else
    echo "Could not resolve repository root." >&2
    exit 1
fi

SCHEME="${CI_XCODE_SCHEME:-Cogsworth}"
echo "Scheme: $SCHEME"

case "$SCHEME" in
    Chip|ChipMac|ChipUITests)
        echo "Scheme $SCHEME does not require embedded Python runtime."
        ;;
    *)
        case "$(uname -m)" in
            arm64)
                PYTHON_HEADER="$APPLE_DIR/HedonismUploader/.build/bundled-python/runtime/include/python3.13/Python.h"
                if [ ! -f "$PYTHON_HEADER" ]; then
                    echo "Python header not found at $PYTHON_HEADER. Ensuring uv and bundling runtime..."
                    if ! command -v uv >/dev/null 2>&1; then
                        if command -v brew >/dev/null 2>&1; then
                            brew install uv
                        else
                            curl -LsSf https://astral.sh/uv/install.sh | sh
                        fi
                        export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
                    fi
                    STAGE="$APPLE_DIR/HedonismUploader/.build/bundled-python/xpc-input"
                    "$APPLE_DIR/HedonismUploader/script/bundle-python.sh" "$STAGE"
                else
                    echo "Bundled Python headers already verified at $PYTHON_HEADER."
                fi
                ;;
            *)
                echo "Skipping Python bundling on $(uname -m) architecture."
                ;;
        esac
        ;;
esac

echo "=== ci_pre_xcodebuild.sh complete ==="
