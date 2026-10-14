#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
case "${1:-baseline}" in
  baseline)
    uv venv --python 3.12 "$ROOT/.venv"
    uv pip install --python "$ROOT/.venv/bin/python" 'numpy>=2,<3'
    "$ROOT/.venv/bin/python" "$ROOT/quality.py" doctor
    ;;
  mlx)
    uv venv --python 3.12 "$ROOT/.venv-mlx"
    uv pip install --python "$ROOT/.venv-mlx/bin/python" 'numpy>=2,<3' mlx-vlm
    ;;
  *)
    echo 'Usage: bash setup.sh baseline|mlx (downloads dependencies; never uploads footage)' >&2
    exit 2
    ;;
esac
