import json
from pathlib import Path
import sys
import tempfile
import unittest

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from quality import DEFAULTS, discover, frame_reasons, intervals, measure, sharpness
from models import parse_assessment, windows


class QualityTests(unittest.TestCase):
    def test_blur_lowers_score_without_confusing_black_with_good_focus(self):
        image = np.random.default_rng(4).uniform(0, 255, (64, 64)).astype(np.float32)
        blurred = sum(np.roll(np.roll(image, x, axis=0), y, axis=1)
                      for x in range(-3, 4) for y in range(-3, 4)) / 49
        self.assertLess(sharpness(blurred), sharpness(image) / 10)
        flags = frame_reasons(measure(np.zeros((64, 64)), []), DEFAULTS)
        self.assertIn("mostly_black_render", flags)
        self.assertIn("low_detail_or_soft_focus", flags)

    def test_face_metrics_use_region_and_exposure_stays_separate(self):
        image = np.zeros((100, 100), dtype=np.float32)
        image[:50] = np.random.default_rng(1).uniform(0, 255, (50, 100))
        result = measure(image, [{"box": [0, 0.5, 1, 0.5], "quality": 0.4}])
        self.assertEqual(result["faces"][0]["laplacian_variance"], 0)
        self.assertGreater(result["laplacian_variance"], 0)
        self.assertIn("mostly_clipped_render", frame_reasons(measure(np.full((30, 30), 255), []), DEFAULTS))

    def test_segments_preserve_gaps_and_source_offset(self):
        rows = [{"time": 10, "reasons": []}, {"time": 11, "reasons": ["soft"]},
                {"time": 12, "reasons": []}, {"time": 13, "reasons": ["dark"]}]
        spans = intervals(rows, 10, 13.2, 0.8)
        self.assertEqual(spans[0]["start"], 10)
        self.assertEqual(spans[-1]["end"], 13.2)
        self.assertEqual([s["state"] for s in spans], ["candidate", "review", "candidate", "brief_review"])
        self.assertAlmostEqual(sum(s["end"] - s["start"] for s in spans), 3.2)

    def test_inventory_includes_vendor_formats_and_arw(self):
        with tempfile.TemporaryDirectory() as tmp:
            folder = Path(tmp)
            for name in ["A.MOV", "B.MXF", "C.braw", "D.ARW", "._A.MOV", "ignore.txt"]:
                (folder / name).touch()
            self.assertEqual(len(discover(folder)), 4)

    def test_model_output_must_be_structured(self):
        valid = {k: "uncertain" for k in ["subject_cut_off", "subject_obscured", "subject_soft", "poor_exposure"]}
        valid["reason"] = "No clear primary subject"
        self.assertEqual(parse_assessment("```json\n" + json.dumps(valid) + "\n```"), valid)
        for bad in ['{"subject_soft":true}', "good footage", "[]"]:
            with self.assertRaises((ValueError, TypeError)):
                parse_assessment(bad)

    def test_window_timestamps_and_stills(self):
        manifest = {"kind": "video", "start": 2, "end": 7,
                    "frames": [{"time": i} for i in range(2, 7)]}
        self.assertEqual([(s, e) for s, e, _ in windows(manifest, 4, 2)], [(2, 6), (4, 7)])
        self.assertEqual(list(windows({"kind": "still", "frames": [{"time": 0}]}, 4, 2))[0][:2], (0, 0))


if __name__ == "__main__":
    unittest.main()
