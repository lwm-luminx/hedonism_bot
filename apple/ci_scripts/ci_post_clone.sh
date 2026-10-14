#!/bin/sh
set -eu

echo "=== Xcode Cloud: Running ci_post_clone.sh ==="

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

echo "Repository root: $REPO_DIR"
echo "Apple directory: $APPLE_DIR"

# Install uv if missing
if ! command -v uv >/dev/null 2>&1; then
    echo "uv not found; installing uv..."
    if command -v brew >/dev/null 2>&1; then
        echo "Installing uv via Homebrew..."
        brew install uv
    else
        echo "Installing uv via standalone installer..."
        curl -LsSf https://astral.sh/uv/install.sh | sh
    fi
    export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
fi

echo "uv version: $(uv --version)"

# Install Rust toolchain if missing
if ! command -v cargo >/dev/null 2>&1 || ! command -v rustc >/dev/null 2>&1; then
    echo "Rust toolchain not found; installing Rust via rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable --profile minimal
    export PATH="$HOME/.cargo/bin:$PATH"
fi

echo "Rust version: $(rustc --version)"
echo "Cargo version: $(cargo --version)"

# Check scheme to see if Python bundling is required
SCHEME="${CI_XCODE_SCHEME:-Cogsworth}"
echo "Configured scheme: $SCHEME"

case "$SCHEME" in
    Chip|ChipMac|ChipUITests)
        echo "Scheme $SCHEME does not require embedded Python runtime. Skipping Python bundling."
        ;;
    *)
        case "$(uname -m)" in
            arm64)
                echo "Pre-bundling Python environment for $SCHEME..."
                STAGE="$APPLE_DIR/HedonismUploader/.build/bundled-python/xpc-input"
                "$APPLE_DIR/HedonismUploader/script/bundle-python.sh" "$STAGE"
                echo "Pre-bundled Python runtime ready."
                ;;
            *)
                echo "Skipping Python bundling on $(uname -m) architecture."
                ;;
        esac
        ;;
esac

echo "=== ci_post_clone.sh complete ==="
