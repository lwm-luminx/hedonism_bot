#!/bin/sh
set -eu

echo "=== Xcode Cloud: Running ci_pre_xcodebuild.sh ==="

if [ -f "$HOME/.cargo/env" ]; then
    . "$HOME/.cargo/env"
fi
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"

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
        echo "Scheme $SCHEME does not require who_dis ML runtime."
        ;;
    *)
        RUST_LIB="$REPO_DIR/who_dis/rust/target/release/libwho_dis_onnx.a"
        if [ ! -f "$RUST_LIB" ]; then
            echo "Rust library not found at $RUST_LIB. Compiling..."
            cargo build --manifest-path "$REPO_DIR/who_dis/rust/Cargo.toml" --release
        else
            echo "who_dis Rust library verified at $RUST_LIB."
        fi
        ;;
esac

echo "=== ci_pre_xcodebuild.sh complete ==="
