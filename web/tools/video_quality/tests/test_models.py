import argparse
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import types
import unittest
from unittest.mock import Mock, patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import models


class ModelContracts(unittest.TestCase):
    """Test orchestration contracts with explicit fakes, not model accuracy."""

    def test_mlx_loads_once_and_preserves_invalid_answers(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            args = argparse.Namespace(model=root, manifest=root / "manifest.json", window=2, stride=2,
                                      output=root / "mlx.json")
            manifest = {"kind": "video", "start": 0, "end": 4,
                        "frames": [{"time": i, "image": f"{i}.jpg"} for i in range(4)]}
            answer = {key: "uncertain" for key in models.FLAGS}
            answer["reason"] = "Test fixture response"
            model_module = types.ModuleType("mlx_vlm")
            model_module.load = Mock(return_value=(object(), object()))
            model_module.generate = Mock(side_effect=[json.dumps(answer), "invalid answer"])
            core = types.ModuleType("mlx.core")
            core.get_peak_memory = lambda: 123
            mlx = types.ModuleType("mlx")
            mlx.core = core
            prompts = types.ModuleType("mlx_vlm.prompt_utils")
            prompts.apply_chat_template = Mock(return_value="formatted")
            utils = types.ModuleType("mlx_vlm.utils")
            utils.load_config = lambda _: {}
            output = {"windows": []}
            with patch.dict(sys.modules, {"mlx": mlx, "mlx.core": core, "mlx_vlm": model_module,
                                          "mlx_vlm.prompt_utils": prompts, "mlx_vlm.utils": utils}), \
                    patch.object(models, "block_network"), patch.object(models.importlib.metadata, "version", return_value="test"):
                models.mlx_runner(args, manifest, output)
            model_module.load.assert_called_once()
            self.assertEqual(len(output["windows"]), 2)
            self.assertEqual(output["windows"][0]["assessment"], answer)
            self.assertEqual(output["windows"][1]["status"], "invalid_model_output")
            self.assertEqual(output["windows"][1]["raw_response"], "invalid answer")

    def test_dover_refuses_sparse_temporal_samples(self):
        with tempfile.TemporaryDirectory() as tmp:
            repo = Path(tmp)
            (repo / "pretrained_weights").mkdir()
            for path in ["evaluate_one_video.py", "dover-mobile.yml", "pretrained_weights/DOVER-Mobile.pth"]:
                (repo / path).touch()
            args = argparse.Namespace(repo=repo, variant="mobile")
            manifest = {"kind": "video", "nominal_fps": 30, "frames": [{"time": 0}, {"time": 0.25}]}
            with self.assertRaisesRegex(ValueError, "consecutive"):
                models.dover_runner(args, manifest, {"windows": []})

    def test_dover_invokes_offline_cpu_runner_and_retains_score(self):
        with tempfile.TemporaryDirectory() as tmp:
            repo = Path(tmp)
            (repo / "pretrained_weights").mkdir()
            for path in ["evaluate_one_video.py", "dover-mobile.yml", "pretrained_weights/DOVER-Mobile.pth"]:
                (repo / path).touch()
            frames = []
            for i in range(60):
                (repo / f"{i}.jpg").touch()
                frames.append({"time": i / 30, "image": f"{i}.jpg"})
            args = argparse.Namespace(repo=repo, variant="mobile", device="cpu", python=sys.executable,
                                      manifest=repo / "manifest.json", output=repo / "result.json",
                                      window=2, stride=2, timeout=30)
            manifest = {"kind": "video", "nominal_fps": 30, "start": 0, "end": 2, "frames": frames}
            output = {"windows": []}
            def fake_run(command, **kwargs):
                stdout = "Normalized fused overall score (scale in [0,1]): 0.75" if "-f" in command else "test-commit"
                return subprocess.CompletedProcess(command, 0, stdout, "")
            with patch.object(models, "run", side_effect=fake_run) as invocation:
                models.dover_runner(args, manifest, output)
            self.assertEqual(output["windows"][0]["fused_score"], 0.75)
            command = invocation.call_args_list[-1].args[0]
            self.assertIn("offline_run.py", str(command[1]))
            self.assertEqual(command[command.index("-d") + 1], "cpu")

    def test_offline_guard_blocks_tcp_in_child_process(self):
        wrapper = Path(models.__file__).with_name("offline_run.py")
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "connect.py"
            target.write_text("import socket\nsocket.socket().connect(('127.0.0.1', 9))\n")
            result = subprocess.run([sys.executable, str(wrapper), str(target)], capture_output=True, text=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("Offline inference", result.stderr)


if __name__ == "__main__":
    unittest.main()
