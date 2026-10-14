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

# Install Rust toolchain if missing
if ! command -v cargo >/dev/null 2>&1 || ! command -v rustc >/dev/null 2>&1; then
    echo "Rust toolchain not found; installing Rust via rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable --profile minimal
    if [ -f "$HOME/.cargo/env" ]; then
        . "$HOME/.cargo/env"
    fi
    export PATH="$HOME/.cargo/bin:$PATH"
fi

echo "Rust version: $(rustc --version)"
echo "Cargo version: $(cargo --version)"

# Build who_dis Rust static library
echo "Building who_dis Rust library..."
cargo build --manifest-path "$REPO_DIR/who_dis/rust/Cargo.toml" --release
echo "who_dis Rust library ready."

echo "=== ci_post_clone.sh complete ==="
