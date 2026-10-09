#!/usr/bin/env python3
"""Compare local model windows against baseline measurements without rerunning inference."""
import argparse
import html
import json
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", type=Path, required=True)
    parser.add_argument("--result", type=Path, action="append", required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    if args.output.exists():
        parser.error("Refusing to overwrite comparison")
    manifest = json.loads(args.manifest.read_text())
    baseline = json.loads(args.manifest.with_name("baseline.json").read_text())
    rows, timings = [], []
    esc = html.escape
    for path in args.result:
        result = json.loads(path.read_text())
        if result.get("source") != manifest["source"]:
            parser.error(f"Different source in {path}; compare results from the same decoded input")
        if result.get("input_fingerprint") != manifest.get("input_fingerprint"):
            parser.error(f"Source fingerprint mismatch in {path}")
        timings.append(f'<li>{esc(path.name)}: {esc(result["status"])}; wall {result.get("wall_seconds", 0):.2f}s; '
                       f'load {result.get("load_seconds", 0):.2f}s; '
                       f'{esc(result.get("error", result.get("timing_note", "")))}</li>')
        for window in result["windows"]:
            selected = [f for f in baseline["frames"] if window["start"] <= f["time"] < window["end"]]
            if manifest["kind"] == "still":
                selected = baseline["frames"]
            mean = sum(f["laplacian_variance"] for f in selected) / len(selected) if selected else None
            flags = sorted({reason for f in selected for reason in f["reasons"]})
            value = json.dumps(window.get("assessment", window.get("fused_score", window.get("error", window["status"]))))
            cells = [path.name, f'{window["start"]:.3f}–{window["end"]:.3f}',
                     f'{mean:.1f}' if mean is not None else "no baseline sample", ", ".join(flags), value]
            rows.append("<tr>" + "".join(f"<td>{esc(cell)}</td>" for cell in cells) + "</tr>")
    args.output.write_text('<!doctype html><meta charset="utf-8"><title>Local model comparison</title>'
        '<style>body{font:15px system-ui;margin:32px}table{border-collapse:collapse}'
        'td,th{border:1px solid #aaa;padding:10px;text-align:left}</style>'
        f'<h1>{esc(Path(manifest["source"]).name)}</h1><p>Advisory experiments; model scores are not calibrated probabilities.</p>'
        '<ul>' + "".join(timings) + '</ul><table><tr><th>Run</th><th>Range (seconds)</th>'
        '<th>Mean sharpness</th><th>Baseline flags</th><th>Model output</th></tr>' + "".join(rows) + '</table>')
    print(args.output.resolve())


if __name__ == "__main__":
    main()
