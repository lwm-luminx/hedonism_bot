#!/usr/bin/env python3
"""Explicit one-time download, separate from offline analysis."""
import argparse
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", default="mlx-community/Qwen3-VL-4B-Instruct-4bit")
    parser.add_argument("--revision", default="main", help="Use a commit hash for reproducibility")
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    if args.output.exists():
        parser.error("Use a new model directory")
    from huggingface_hub import snapshot_download
    snapshot_download(repo_id=args.repo, revision=args.revision, local_dir=str(args.output),
                      allow_patterns=["*.json", "*.safetensors", "*.txt", "*.model", "*.jinja", "*.md"])


if __name__ == "__main__":
    main()
