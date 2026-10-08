# Local RAW quality experiments

Read camera media locally, compare decoder/model options, and produce inspectable measurements and suggested ranges. Originals are opened read-only. Nothing is uploaded or deleted. Inference uses existing local weights; setup and model downloads are separate commands.

## Start when the card arrives

Run from the repository root. This Mac already has Swift, Python, NumPy, FFmpeg and ffprobe, so the baseline needs no downloads:

```sh
python3 tools/video_quality/quality.py doctor
python3 tools/video_quality/quality.py scan \
  --input "/Volumes/YOUR_CARD" \
  --output "$PWD/tools/video_quality/results/card-first-pass" \
  --limit 3 --duration 20 --fps 4
open tools/video_quality/results/card-first-pass/index.html
```

The default inspects the first three candidate files in sorted path order, twenty seconds each. `batch.json` inventories every candidate, including unprocessed files. Choose a specific file to test a particular camera/codec. Outputs must be new directories outside the input tree. Card folders, originals and sidecars are never modified. Expected storage is a JPEG plus an uncompressed grayscale frame per sample; full-frame-rate runs can be large.

```sh
python3 tools/video_quality/quality.py scan \
  --input "/Volumes/YOUR_CARD/path/clip.mov" \
  --output "$PWD/tools/video_quality/results/clip-native" \
  --decoder native --start 15 --duration 10 --fps 4
```

`--decoder auto` attempts native Apple decoding, then FFmpeg. `--decoder native` or `ffmpeg` isolates a decoder for comparison. `--pixel-format half` or `bgra` lets you test Apple output formats explicitly; auto requests half-float RGBA for detected ProRes RAW and BGRA otherwise. Decoder timeouts default to 600 seconds per attempt. FFmpeg fallback currently decodes sequentially from the beginning, so a late `--start` may need a longer `--timeout`.

On another Mac, install Xcode Command Line Tools, FFmpeg and uv, then:

```sh
bash tools/video_quality/setup.sh baseline
tools/video_quality/.venv/bin/python tools/video_quality/quality.py doctor
```

Use that environment's Python for the following commands if system Python lacks NumPy. Setup downloads dependencies and may download Python. It does not download any AI model.

## RAW format coverage

| Input | Current test path | What remains to validate |
|---|---|---|
| DJI Ronin ProRes RAW / RAW HQ (`.mov`) | AVFoundation → half-float image → CoreImage sRGB samples; FFmpeg can also be tested | Actual camera files and the installed Apple decoder; codec listing alone proves nothing |
| Sony cinema RAW / X-OCN (`.mxf`) | Actual native/FFmpeg decode attempt, with error logs; local developed proxy fallback | Camera/codec-specific decoding; no Sony SDK integration is claimed |
| Sony RAW stills (`.arw`) | CoreImage RAW development → image/face quality and optional MLX | Camera-specific Apple RAW support; no video ranges or DOVER for stills |
| Blackmagic RAW (`.braw`) | Inventory and decode diagnostics; local developed proxy fallback | Direct SDK integration is not implemented; use local Resolve/Blackmagic SDK development for now |

A failed decode produces `error.json`, decoder logs and a nonzero batch exit status. Other files continue processing. It is never reported as a low-quality image. RAW still failure does not silently substitute the embedded camera JPEG.

For BRAW or Sony cinema RAW requiring a vendor decoder, export a **full-length, constant-frame-rate, display-referred SDR ProRes proxy** locally and record the relationship:

```sh
python3 tools/video_quality/quality.py scan \
  --input "/path/to/developed-proxy.mov" \
  --original "/Volumes/YOUR_CARD/clip.braw" \
  --proxy-note "Resolve version; Rec.709 SDR; camera WB/ISO; exposure 0; no creative LUT" \
  --output "$PWD/tools/video_quality/results/braw-proxy" \
  --duration 20 --fps 4
```

`--original-offset 12.5` means proxy time zero corresponds to 12.5 seconds into the original. This is metadata supplied by you, not an automatically verified timecode match. Keep source rate/order unchanged. The manifest preserves both paths, file sizes and modification times, development notes and the offset. Frame times and ranges remain **decoded asset timeline seconds**; add the recorded offset to map a trimmed proxy back. SMPTE camera timecode and spanned-clip assembly are not implemented.

ARW can be scanned as a single file or alongside video. Leave `--start 0` for stills. Each ARW produces one developed frame and baseline/MLX measurements; duration and time are zero.

## What the baseline reports

- Whole-frame and detected-face Laplacian variance (sharpness/detail proxy).
- Mean luminance and fractions near black/white.
- Apple Vision face capture quality, bounding boxes, and errors if Vision is unavailable.
- Native consecutive-frame translation registration, plus mean frame differences. These are **motion diagnostics**, not a calibrated shake detector. Sparse sampling cannot resolve high-frequency shake; use full-rate frames for that experiment.
- `candidate`, `review`, and `brief_review` ranges bounded by sampled coverage. A candidate means no heuristic fired, not confirmed usable footage. No automatic rejection/cutting is performed.

The report links contact-sheet frames to actual sampled timestamps. JSON contains per-frame values; `metrics.csv` exposes basic numerical measures. `baseline.json` includes ranges and thresholds. Face boxes/quality, translation and detailed errors remain in JSON.

Default thresholds are deliberately experimental. Low-detail walls, bokeh, intentional darkness and bright backdrops can trigger them. Adjust with `--thresholds /path/to/thresholds.json`, e.g.:

```json
{"soft_laplacian": 35, "black_fraction": 0.85, "white_fraction": 0.6, "minimum_review_seconds": 0.5}
```

Short flagged runs retain `brief_review` status instead of disappearing. Range boundaries are midpoint estimates between samples, not frame-accurate edits. No pan/rack-focus intent or scene-boundary model is implemented yet.

**Color matters:** native results use Apple's default RAW development followed by an 8-bit sRGB render. FFmpeg fallback uses its default conversion with no explicit RAW development or HDR tone map. Neither measures sensor clipping or RAW recovery headroom. Inspect rendering before interpreting exposure. Keep development settings and `--max-side` constant across comparisons. Downscaling can hide slight focus problems; retry selected portions at `--max-side 1920` or higher. Thresholds need recalibration across image sizes and render paths.

## MLX framing/subject experiment

One-time dependency and weight downloads, before offline use:

```sh
bash tools/video_quality/setup.sh mlx
tools/video_quality/.venv-mlx/bin/python tools/video_quality/download_model.py \
  --repo mlx-community/Qwen3-VL-4B-Instruct-4bit \
  --output "$PWD/tools/video_quality/models/qwen3-vl-4b"
```

Weights are several gigabytes. `--revision COMMIT_HASH` can pin a model snapshot. Existing download directories are not overwritten. For a resumable interrupted download, use the Hugging Face client directly against that directory.

Find a successful `manifest.json` path in `batch.json`, then:

```sh
tools/video_quality/.venv-mlx/bin/python tools/video_quality/models.py mlx \
  --manifest "/absolute/path/to/native/manifest.json" \
  --model "$PWD/tools/video_quality/models/qwen3-vl-4b" \
  --output "/absolute/path/to/native/mlx.json"
```

This loads the model once and evaluates four timestamped images per overlapping four-second window. It asks for subject cropping, obstruction, softness and exposure, with `yes/no/uncertain` answers and a reason. ARW uses one image. Sparse-image assessment is not native full-video temporal inference. Raw responses are saved, invalid JSON is flagged, and no prose answer becomes an automatic cut. The script records load time, per-window time, peak MLX memory and package version. Try a smaller/larger local MLX VLM by changing `--model` and the output filename.

Hugging Face offline flags are set before loading. A Python TCP guard blocks accidental model downloads in both MLX and DOVER; it is a development guard, not an OS network sandbox. Analysis contains no service/API calls. Installing all dependencies/weights first allows execution with networking disconnected.

## DOVER-Mobile / DOVER comparison

This optional research runner requires a **separate, locally installed** [DOVER checkout](https://github.com/VQAssessment/DOVER), its dependencies and `pretrained_weights/DOVER-Mobile.pth` or `DOVER.pth`. Follow its installation instructions in an isolated Python environment. Record/pin the checkout commit. Decord can require a native build on Apple silicon: see [Decord's Mac build instructions](https://github.com/dmlc/decord#mac-os). The wrapper does not silently replace missing Decord or download backbones during inference.

DOVER uses the [S-Lab noncommercial license](https://github.com/VQAssessment/DOVER/blob/master/LICENSE). These scripts do not bundle its code or weights. MPS is an experiment; CPU is the default, and failures remain visible rather than silently switching devices.

First rescan a short video at **every source frame**. Set `--fps` at least as high as the native frame rate (e.g. 60 for footage up to 60 fps):

```sh
python3 tools/video_quality/quality.py scan \
  --input "/Volumes/YOUR_CARD/path/clip.mov" \
  --output "$PWD/tools/video_quality/results/clip-fullrate" \
  --decoder native --duration 8 --fps 60 --max-side 1920

python3 tools/video_quality/models.py dover \
  --manifest "/absolute/path/to/fullrate/native/manifest.json" \
  --repo "/absolute/path/to/DOVER" \
  --python "/absolute/path/to/dover-environment/bin/python" \
  --variant mobile --device cpu \
  --output "/absolute/path/to/fullrate/native/dover-mobile-cpu.json"
```

Repeat with `--device mps` and/or `--variant full` and new output filenames. The wrapper rejects sparse/VFR samples, creates temporary high-quality H.264 proxies of consecutive rendered frames, and invokes the upstream evaluator per window. Short windows under 32 frames are marked `too_short`. These are model comparisons on rendered proxies, not a faithful native-RAW benchmark. The upstream fused score is not a calibrated probability of usability. Timings include encoding, process startup and model load on every window; they do not measure warm inference throughput. Temporary proxies are removed after each run, but the sampled JPEG/PGM inputs remain.

## Compare results and validate

```sh
python3 tools/video_quality/compare.py \
  --manifest "/absolute/path/to/native/manifest.json" \
  --result "/absolute/path/to/native/mlx.json" \
  --result "/absolute/path/to/native/dover-mobile-cpu.json" \
  --output "/absolute/path/to/native/comparison.html"

python3 -m unittest discover -s tools/video_quality/tests -v
python3 tools/video_quality/smoke_test.py \
  --output "$PWD/tools/video_quality/results/smoke-new"
```

The comparison pairs model windows with baseline measurements from the same source. Review against hand-marked usable/poor ranges, especially focus hunts, camera settling, low light, intentional pans, edge framing, and shallow depth of field. Compare good footage mistakenly flagged, missed defects, boundary errors, run time and memory. Still images need per-image labels instead of temporal ranges.

The smoke test generates ordinary ProRes with sharp, blurred, black and white sections. It checks native and FFmpeg decoding, timestamp offsets, quality measurements, malformed-input behavior and unchanged source bytes. **It does not validate any camera RAW codec or downloaded model.** If macOS media services fail under a restricted runner, rerun from Terminal with normal local media access and retain both logs.

## Local decoder references

- [Apple: Decode ProRes with AVFoundation and VideoToolbox](https://developer.apple.com/videos/play/wwdc2020/10090/) describes the half-float output path for ProRes RAW.
- [Sony RAW Viewer](https://www.sony.com/electronics/support/professional-cameras-digital-cinema-cameras/mpc-2610/software/00408235) handles Sony cinema RAW/X-OCN. Support is camera/version dependent.
- [Blackmagic RAW SDK](https://www.blackmagicdesign.com/developer/products/braw/sdk-and-software) is the intended direct BRAW decoder integration point; local proxies allow quality experiments before that adapter is built.
- [MLX-VLM](https://github.com/Blaizzy/mlx-vlm) provides local Apple-silicon VLM inference.
