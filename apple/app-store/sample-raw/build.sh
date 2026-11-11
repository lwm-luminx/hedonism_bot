#!/usr/bin/env bash
# Rebuilds chip-sample-raw.zip (11 DNGs). Needs python3 with numpy, tifffile, pillow (rawpy to verify).
#   pip install numpy tifffile pillow rawpy && ./build.sh /tmp/chip-sample-raw-build
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
work="${1:-$(mktemp -d)}"
mkdir -p "$work/src" "$work/chip-sample-raw" "$work/preview"
base=https://raw.githubusercontent.com/ageitgey/face_recognition/master
for f in examples/obama.jpg examples/obama2.jpg examples/biden.jpg examples/two_people.jpg tests/test_images/obama3.jpg; do
  curl -sSfL -o "$work/src/$(echo "$f" | tr / _)" "$base/$f"
done
python3 -I "$here/make_scenery_dng.py" "$work/chip-sample-raw"
python3 -I "$here/make_face_dng.py" "$work/src" "$work/chip-sample-raw"
cp "$here/SAMPLE-README.txt" "$work/chip-sample-raw/README.txt"
if python3 -c 'import rawpy' 2>/dev/null; then python3 -I "$here/check_decode.py" "$work/chip-sample-raw" "$work/preview"; fi
(cd "$work" && rm -f chip-sample-raw.zip && zip -qr chip-sample-raw.zip chip-sample-raw)
echo "$work/chip-sample-raw.zip"
