#!/usr/bin/env python3
"""Local RAW decoder experiments and conservative, inspectable quality measurements."""
import argparse
import csv
import hashlib
import html
import importlib.metadata
import json
import math
import os
from pathlib import Path
import platform
import shutil
import subprocess
import sys
import time
from urllib.parse import quote

ROOT = Path(__file__).resolve().parent
VIDEO = {".mov", ".mp4", ".mxf", ".braw", ".avi", ".mkv"}
STILLS = {".arw", ".dng", ".nef", ".cr2", ".cr3"}
DEFAULTS = {"soft_laplacian": 35.0, "black_fraction": 0.85,
            "white_fraction": 0.60, "minimum_review_seconds": 0.5}


def write_json(path, data):
    path = Path(path)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(json.dumps(data, indent=2, allow_nan=False) + "\n")
    temporary.replace(path)


def run(command, timeout=120, **kwargs):
    return subprocess.run([str(x) for x in command], capture_output=True, text=True,
                          timeout=timeout, **kwargs)


def positive(value):
    number = float(value)
    if not math.isfinite(number) or number <= 0:
        raise argparse.ArgumentTypeError("Must be finite and positive")
    return number


def nonnegative(value):
    number = float(value)
    if not math.isfinite(number) or number < 0:
        raise argparse.ArgumentTypeError("Must be finite and nonnegative")
    return number


def natural(value):
    number = int(value)
    if number < 1:
        raise argparse.ArgumentTypeError("Must be a positive integer")
    return number


def native_binary():
    build = ROOT / ".build"
    build.mkdir(exist_ok=True)
    binary = build / "native-sampler"
    source = ROOT / "NativeSampler.swift"
    if not binary.exists() or source.stat().st_mtime > binary.stat().st_mtime:
        result = run(["swiftc", "-parse-as-library", "-O", "-module-cache-path", build / "modules",
                      source, "-o", binary], timeout=180)
        if result.returncode:
            raise RuntimeError(result.stderr)
    return binary


def fingerprint(path):
    stat = path.stat()
    return {"path": str(path), "size": stat.st_size, "mtime_ns": stat.st_mtime_ns}


def discover(path):
    if path.is_file():
        return [path]
    if not path.is_dir():
        raise ValueError(f"Input does not exist: {path}")
    return sorted(p for p in path.rglob("*") if p.is_file()
                  and not p.name.startswith(".") and p.suffix.lower() in VIDEO | STILLS)


def probe(source):
    if not shutil.which("ffprobe"):
        return {"error": "ffprobe is not installed"}
    result = run(["ffprobe", "-v", "error", "-show_format", "-show_streams", "-of", "json", source])
    return json.loads(result.stdout) if result.returncode == 0 else {"error": result.stderr}


def doctor(args):
    details = {"platform": platform.platform(), "machine": platform.machine(),
               "python": sys.version, "packages": {}, "tools": {}}
    for package in ("numpy", "mlx-vlm", "torch", "decord", "onnxruntime"):
        try:
            details["packages"][package] = importlib.metadata.version(package)
        except importlib.metadata.PackageNotFoundError:
            details["packages"][package] = None
    for tool, flags in (("swift", ["--version"]), ("ffmpeg", ["-version"]), ("ffprobe", ["-version"])):
        details["tools"][tool] = run([tool, *flags]).stdout.splitlines()[0] if shutil.which(tool) else None
    if shutil.which("ffmpeg"):
        details["ffmpeg_raw_decoders"] = [line.strip() for line in run(["ffmpeg", "-hide_banner", "-decoders"]).stdout.splitlines()
                                          if any(word in line.lower() for word in ("prores", "braw", "xocn", "sony"))]
    try:
        details["native_sampler"] = str(native_binary())
    except (OSError, RuntimeError, subprocess.TimeoutExpired) as exc:
        details["native_sampler_error"] = str(exc)
    details["note"] = "Listed codecs are not proof of RAW decoding. Run scan on an actual camera file."
    if args.output:
        write_json(args.output, details)
    print(json.dumps(details, indent=2))


def read_pgm(path):
    import numpy as np
    with Path(path).open("rb") as file:
        if file.readline().strip() != b"P5":
            raise ValueError("Expected binary PGM")
        width, height = map(int, file.readline().split())
        if file.readline().strip() != b"255":
            raise ValueError("Expected 8-bit PGM")
        return np.frombuffer(file.read(), dtype=np.uint8).reshape(height, width).astype(np.float32)


def sharpness(gray):
    import numpy as np
    if min(gray.shape) < 3:
        return None
    laplacian = (gray[1:-1, :-2] + gray[1:-1, 2:] + gray[:-2, 1:-1]
                 + gray[2:, 1:-1] - 4 * gray[1:-1, 1:-1])
    return float(np.var(laplacian))


def measure(gray, faces):
    import numpy as np
    height, width = gray.shape
    regions = []
    for face in faces:
        x, y, w, h = face["box"]
        crop = gray[max(0, int(y * height)):min(height, math.ceil((y + h) * height)),
                    max(0, int(x * width)):min(width, math.ceil((x + w) * width))]
        regions.append({**face, "laplacian_variance": sharpness(crop) if crop.size else None})
    return {"laplacian_variance": sharpness(gray), "mean_luma": float(np.mean(gray)),
            "black_fraction": float(np.mean(gray <= 5)), "white_fraction": float(np.mean(gray >= 250)),
            "faces": regions}


def frame_reasons(metrics, thresholds):
    reasons = []
    if metrics["laplacian_variance"] < thresholds["soft_laplacian"]:
        reasons.append("low_detail_or_soft_focus")
    if metrics["black_fraction"] > thresholds["black_fraction"]:
        reasons.append("mostly_black_render")
    if metrics["white_fraction"] > thresholds["white_fraction"]:
        reasons.append("mostly_clipped_render")
    return reasons


def intervals(rows, start, end, minimum):
    """Midpoint cells, then merge contiguous review runs; never infer outside coverage."""
    if not rows:
        return []
    boundaries = [start] + [(a["time"] + b["time"]) / 2 for a, b in zip(rows, rows[1:])] + [end]
    spans = []
    for index, row in enumerate(rows):
        state = "review" if row["reasons"] else "candidate"
        if spans and spans[-1]["state"] == state:
            spans[-1]["end"] = boundaries[index + 1]
            spans[-1]["reasons"] = sorted(set(spans[-1]["reasons"] + row["reasons"]))
        else:
            spans.append({"start": boundaries[index], "end": boundaries[index + 1],
                          "state": state, "reasons": list(row["reasons"])})
    for span in spans:
        if span["state"] == "review" and span["end"] - span["start"] < minimum:
            span["state"] = "brief_review"
    return spans


def baseline(folder, thresholds):
    import numpy as np
    manifest = json.loads((folder / "manifest.json").read_text())
    began = time.perf_counter()
    rows = []
    previous = None
    for frame in manifest["frames"]:
        gray = read_pgm(folder / frame["gray"])
        metrics = measure(gray, frame.get("faces", []))
        # This deliberately remains a motion/change signal, not a shake classifier.
        metrics["mean_frame_difference"] = (float(np.mean(np.abs(gray - previous)))
                                             if previous is not None and previous.shape == gray.shape else None)
        previous = gray
        rows.append({**frame, **metrics, "reasons": frame_reasons(metrics, thresholds)})
    report = {"method": "baseline", "thresholds": thresholds, "frames": rows,
              "analysis_seconds": time.perf_counter() - began,
              "segments": intervals(rows, manifest["start"], manifest["end"],
                                    thresholds["minimum_review_seconds"]) if manifest["kind"] == "video" else [],
              "limitations": "Uncalibrated rendered-image heuristics. Candidate is not confirmed usable. "
                             "Frame difference is not camera shake; face quality is not a universal focus score."}
    write_json(folder / "baseline.json", report)
    with (folder / "metrics.csv").open("w", newline="") as file:
        columns = ["time", "laplacian_variance", "mean_luma", "black_fraction", "white_fraction", "mean_frame_difference", "reasons"]
        writer = csv.DictWriter(file, fieldnames=columns, extrasaction="ignore")
        writer.writeheader()
        writer.writerows({**row, "reasons": ";".join(row["reasons"])} for row in rows)
    write_html(folder, manifest, report)
    return report


def write_html(folder, manifest, report):
    esc = html.escape
    cards = []
    for row in report["frames"]:
        reasons = ", ".join(row["reasons"]) or "candidate — no baseline flags"
        cards.append(f'<article><img loading="lazy" src="{esc(quote(row["image"]), quote=True)}">'
                     f'<b>{row["time"]:.3f}s</b> {esc(reasons)}'
                     f'<p>Sharpness: {row["laplacian_variance"]:.1f}; '
                     f'luma: {row["mean_luma"]:.1f}; faces: {len(row["faces"])}</p></article>')
    payload = esc(json.dumps(report["segments"], indent=2))
    (folder / "review.html").write_text('<!doctype html><meta charset="utf-8"><title>Local quality review</title>'
        '<style>body{font:16px system-ui;background:#15171b;color:#eee;margin:32px}'
        '.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(300px,1fr));gap:18px}'
        'img{width:100%}article{background:#252830;padding:12px}pre{white-space:pre-wrap}</style>'
        f'<h1>{esc(Path(manifest["source"]).name)}</h1><p>{esc(report["limitations"])}</p>'
        f'<p>{esc(manifest["render"])}</p><details><summary>Suggested ranges</summary><pre>{payload}</pre></details>'
        f'<div class="grid">{"".join(cards)}</div>')


def ffmpeg_sample(source, folder, args, metadata):
    """Fallback uses showinfo PTS, not invented frame-number timestamps."""
    import re
    streams = [s for s in metadata.get("streams", []) if s.get("codec_type") == "video"]
    if not streams:
        raise RuntimeError("ffprobe did not find a video stream; use a vendor-decoded local proxy")
    duration = float(metadata.get("format", {}).get("duration") or streams[0].get("duration") or 0)
    if duration <= args.start:
        raise RuntimeError("Missing duration or start is outside the video")
    (folder / "frames").mkdir(parents=True)
    # Decode sequentially so original PTS survive sampling. trim bounds the work after start.
    filters = (f"trim=start={args.start}:end={args.start + args.duration},"
               f"select=isnan(prev_selected_t)+gte(t-prev_selected_t\\,{1 / args.fps}),"
               f"scale=w='min({args.max_side},iw)':h='min({args.max_side},ih)':force_original_aspect_ratio=decrease,showinfo")
    result = run(["ffmpeg", "-nostdin", "-hide_banner", "-n", "-i", source, "-an", "-vf", filters,
                  "-fps_mode", "vfr", "-q:v", "2", "-start_number", "0", folder / "frames/%06d.jpg"], timeout=args.timeout)
    (folder / "decode.log").write_text(result.stderr)
    if result.returncode:
        raise RuntimeError(result.stderr[-6000:])
    times = [float(x) for x in re.findall(r"\bn:\s*\d+.*?pts_time:\s*([-+\deE.]+)", result.stderr)]
    pictures = sorted((folder / "frames").glob("*.jpg"))
    if not pictures or len(times) != len(pictures):
        raise RuntimeError("Decoded frames and source timestamps do not match")
    conversion = run(["ffmpeg", "-nostdin", "-v", "error", "-n", "-i", folder / "frames/%06d.jpg",
                      "-start_number", "0", folder / "frames/%06d.pgm"], timeout=args.timeout)
    if conversion.returncode:
        raise RuntimeError(conversion.stderr)
    nominal = streams[0].get("avg_frame_rate", "0/1")
    numerator, denominator = map(float, nominal.split("/"))
    manifest = {"source": str(source), "kind": "video", "codec": streams[0].get("codec_name"),
                "decoder": "ffmpeg", "duration": duration, "start": args.start,
                "end": min(duration, args.start + args.duration), "sample_fps": args.fps,
                "nominal_fps": numerator / denominator if denominator else 0,
                "render": "FFmpeg default conversion; no explicit RAW development or HDR tone map. Inspect before interpreting exposure.",
                "frames": [{"time": t, "image": f"frames/{p.name}", "gray": f"frames/{p.stem}.pgm", "faces": []}
                           for t, p in zip(times, pictures)]}
    write_json(folder / "manifest.json", manifest)


def scan(args):
    import numpy  # Fail before processing the card if the baseline dependency is missing.
    source = args.input.expanduser().resolve()
    if args.max_side < 64:
        raise ValueError("--max-side must be at least 64")
    files = discover(source)
    if not files:
        raise ValueError("No supported candidate files found")
    output = args.output.expanduser().resolve()
    if source.is_dir() and (output == source or source in output.parents):
        raise ValueError("Output must be outside the input directory/card")
    output.mkdir(parents=True, exist_ok=False)
    thresholds = DEFAULTS.copy()
    if args.thresholds:
        supplied = json.loads(args.thresholds.read_text())
        if set(supplied) - set(thresholds):
            raise ValueError("Unknown threshold keys")
        thresholds.update(supplied)
        if any(not isinstance(v, (float, int)) or not math.isfinite(v) or v < 0 for v in thresholds.values()):
            raise ValueError("Thresholds must be finite nonnegative numbers")
    if args.original and (not source.is_file() or not args.original.is_file()):
        raise ValueError("--original requires single existing proxy and original files")
    batch = {"settings": {k: str(v) if isinstance(v, Path) else v for k, v in vars(args).items() if k != "handler"},
             "runtime": {"platform": platform.platform(), "python": sys.version, "numpy": numpy.__version__},
             "script_sha256": {p.name: hashlib.sha256(p.read_bytes()).hexdigest()
                               for p in ROOT.iterdir() if p.suffix in (".py", ".swift")},
             "inventory": [fingerprint(p) for p in files], "clips": []}
    write_json(output / "batch.json", batch)
    for path in files[:args.limit]:
        token = hashlib.sha256(str(path).encode()).hexdigest()[:10]
        folder = output / f"{path.stem[:60]}-{token}"
        folder.mkdir()
        item = {"source": str(path), "directory": folder.name, "status": "failed", "attempts": []}
        began = time.perf_counter()
        try:
            try:
                metadata = probe(path)
            except subprocess.TimeoutExpired:
                metadata = {"error": "ffprobe timed out; attempting native decoding anyway"}
            write_json(folder / "probe.json", metadata)
            backends = ["native", "ffmpeg"] if args.decoder == "auto" else [args.decoder]
            for backend in backends:
                attempt = folder / backend
                attempt.mkdir()
                try:
                    if backend == "native":
                        result = run([native_binary(), path, attempt, args.start, args.duration,
                                      args.fps, args.max_side, args.pixel_format], timeout=args.timeout)
                        (attempt / "decode.log").write_text(result.stdout + result.stderr)
                        if result.returncode:
                            raise RuntimeError(result.stderr)
                    else:
                        if path.suffix.lower() in STILLS:
                            raise RuntimeError("RAW still development requires the native CoreImage path")
                        ffmpeg_sample(path, attempt, args, metadata)
                    manifest_path = attempt / "manifest.json"
                    manifest = json.loads(manifest_path.read_text())
                    manifest["input_fingerprint"] = fingerprint(path)
                    if args.original:
                        manifest["original"] = fingerprint(args.original.resolve())
                        manifest["original_offset_seconds"] = args.original_offset
                        manifest["proxy_note"] = args.proxy_note
                    write_json(manifest_path, manifest)
                    report = baseline(attempt, thresholds)
                    item.update(status="ok", decoder=backend, manifest=str(manifest_path.relative_to(output)),
                                samples=len(manifest["frames"]), analysis_seconds=report["analysis_seconds"])
                    break
                except (OSError, ValueError, RuntimeError, subprocess.TimeoutExpired) as exc:
                    item["attempts"].append({"decoder": backend, "error": str(exc)})
                    write_json(attempt / "error.json", {"error": str(exc)})
            if item["status"] == "failed":
                item["next_step"] = "Inspect decoder logs; use --input local-proxy.mov --original RAW_FILE --proxy-note 'development settings' for vendor-only codecs."
        except (OSError, ValueError, subprocess.TimeoutExpired) as exc:
            item["error"] = str(exc)
        item["wall_seconds"] = time.perf_counter() - began
        batch["clips"].append(item)
        write_json(output / "batch.json", batch)
        print(f"{item['status']}: {path.name} ({item['wall_seconds']:.1f}s)", flush=True)
    links = []
    for item in batch["clips"]:
        name = html.escape(Path(item["source"]).name)
        if item["status"] == "ok":
            link = html.escape(quote(str(Path(item["manifest"]).parent / "review.html")), quote=True)
            links.append(f'<li><a href="{link}">{name}</a> — {item["samples"]} samples</li>')
        else:
            links.append(f'<li>{name} — decode failed; see batch.json and decoder logs</li>')
    (output / "index.html").write_text('<!doctype html><meta charset="utf-8"><title>RAW quality experiments</title>'
                                      '<h1>RAW quality experiments</h1><ul>' + "".join(links) + '</ul>')
    print(f"Review: {output / 'index.html'}")
    return 0 if all(item["status"] == "ok" for item in batch["clips"]) else 1


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    check = commands.add_parser("doctor", help="Check local runtimes and compile the native decoder")
    check.add_argument("--output", type=Path)
    check.set_defaults(handler=doctor)
    scan_parser = commands.add_parser("scan", help="Read-only card scan or single-file experiment")
    scan_parser.add_argument("--input", type=Path, required=True)
    scan_parser.add_argument("--output", type=Path, required=True, help="New directory outside the input tree")
    scan_parser.add_argument("--limit", type=natural, default=3)
    scan_parser.add_argument("--start", type=nonnegative, default=0)
    scan_parser.add_argument("--duration", type=positive, default=20)
    scan_parser.add_argument("--fps", type=positive, default=4)
    scan_parser.add_argument("--max-side", type=natural, default=960)
    scan_parser.add_argument("--timeout", type=positive, default=600)
    scan_parser.add_argument("--decoder", choices=["auto", "native", "ffmpeg"], default="auto")
    scan_parser.add_argument("--pixel-format", choices=["auto", "bgra", "half"], default="auto")
    scan_parser.add_argument("--thresholds", type=Path)
    scan_parser.add_argument("--original", type=Path, help="Original RAW associated with a local developed proxy")
    scan_parser.add_argument("--original-offset", type=nonnegative, default=0, help="Original-relative seconds at proxy time zero")
    scan_parser.add_argument("--proxy-note", default="", help="App, version, color space, WB, ISO, exposure and LUT settings")
    scan_parser.set_defaults(handler=scan)
    args = parser.parse_args()
    try:
        return args.handler(args) or 0
    except (OSError, ValueError, RuntimeError, ImportError, subprocess.TimeoutExpired) as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
