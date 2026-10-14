#!/usr/bin/env python3
"""Generate ordinary ProRes fixtures and exercise the actual local decoders. NOT RAW validation."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parent


def checked(command):
    subprocess.run([str(x) for x in command], check=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True, help="New directory")
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=False)
    source = args.output / "synthetic-prores.mov"
    graph = ("testsrc2=size=640x360:rate=30:duration=2[a];"
             "testsrc2=size=640x360:rate=30:duration=2,gblur=sigma=12[b];"
             "color=black:size=640x360:rate=30:duration=2[c];"
             "color=white:size=640x360:rate=30:duration=2[d];"
             "[a][b][c][d]concat=n=4:v=1:a=0")
    checked(["ffmpeg", "-nostdin", "-v", "error", "-n", "-f", "lavfi", "-i", graph,
             "-c:v", "prores_ks", "-profile:v", "3", "-pix_fmt", "yuv422p10le", source])
    original_hash = hashlib.sha256(source.read_bytes()).hexdigest()
    for decoder in ["native", "ffmpeg"]:
        output = args.output / decoder
        checked([sys.executable, ROOT / "quality.py", "scan", "--input", source, "--output", output,
                 "--decoder", decoder, "--duration", "8", "--fps", "4"])
        batch = json.loads((output / "batch.json").read_text())
        manifest_path = output / batch["clips"][0]["manifest"]
        manifest = json.loads(manifest_path.read_text())
        baseline = json.loads(manifest_path.with_name("baseline.json").read_text())
        frames = baseline["frames"]
        sharp = [f["laplacian_variance"] for f in frames if f["time"] < 2]
        soft = [f["laplacian_variance"] for f in frames if 2 <= f["time"] < 4]
        assert sum(sharp) / len(sharp) > 5 * sum(soft) / len(soft), decoder
        assert all("mostly_black_render" in f["reasons"] for f in frames if 4 <= f["time"] < 6), decoder
        assert all("mostly_clipped_render" in f["reasons"] for f in frames if 6 <= f["time"] < 8), decoder
        assert len(frames) >= 29 and manifest["end"] > 7.9, decoder
        assert all(b["time"] > a["time"] for a, b in zip(frames, frames[1:])), decoder
        # Explicit nonzero start proves source-relative timing is retained.
        offset_output = args.output / (decoder + "-offset")
        checked([sys.executable, ROOT / "quality.py", "scan", "--input", source, "--output", offset_output,
                 "--decoder", decoder, "--start", "2.5", "--duration", "1", "--fps", "4"])
        offset_batch = json.loads((offset_output / "batch.json").read_text())
        offset_manifest = json.loads((offset_output / offset_batch["clips"][0]["manifest"]).read_text())
        assert 2.5 <= offset_manifest["frames"][0]["time"] < 2.6, decoder
    broken = args.output / "unsupported.braw"
    broken.write_bytes(b"deliberately invalid test fixture")
    failed_output = args.output / "failure"
    result = subprocess.run([sys.executable, str(ROOT / "quality.py"), "scan", "--input", str(broken),
                             "--output", str(failed_output), "--timeout", "30"])
    assert result.returncode == 1
    failed = json.loads((failed_output / "batch.json").read_text())
    assert failed["clips"][0]["status"] == "failed"
    assert len(failed["clips"][0]["attempts"]) == 2
    assert hashlib.sha256(source.read_bytes()).hexdigest() == original_hash
    print("PASS: native + FFmpeg decoding, blur/exposure flags, source timestamps, failures and unchanged source.")
    print("Camera ProRes RAW, Sony RAW/X-OCN/ARW, BRAW and actual model inference still need real fixtures/weights.")


if __name__ == "__main__":
    main()
