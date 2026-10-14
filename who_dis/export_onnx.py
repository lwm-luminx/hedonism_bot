"""
Export who_dis models (ViT visual features, RetinaFace face detection, ArcFace face embeddings)
to ONNX format for native execution in Rust.
"""

import argparse
import os
import sys
from pathlib import Path

import torch


def export_vit(output_path: Path, model_name: str = "google/vit-large-patch32-224-in21k"):
    """
    Exports ViT model to ONNX.
    Input: pixel_values [batch_size, 3, 224, 224] (float32)
    Output: embedding [batch_size, 1024] (float32) - CLS token embedding
    """
    print(f"Loading ViT model '{model_name}'...")
    from transformers import AutoModel

    base_model = AutoModel.from_pretrained(model_name)
    base_model.eval()

    class ViTFeatureExtractor(torch.nn.Module):
        def __init__(self, vit):
            super().__init__()
            self.vit = vit

        def forward(self, pixel_values):
            outputs = self.vit(pixel_values=pixel_values)
            # CLS token at index 0 represents the whole image
            return outputs.last_hidden_state[:, 0, :]

    model = ViTFeatureExtractor(base_model)
    model.eval()

    dummy_input = torch.randn(1, 3, 224, 224, dtype=torch.float32)
    print(f"Exporting ViT to {output_path}...")
    output_path.parent.mkdir(parents=True, exist_ok=True)

    with torch.no_grad():
        torch.onnx.export(
            model,
            dummy_input,
            str(output_path),
            export_params=True,
            opset_version=17,
            do_constant_folding=True,
            input_names=["pixel_values"],
            output_names=["embedding"],
            dynamic_axes={
                "pixel_values": {0: "batch_size"},
                "embedding": {0: "batch_size"},
            },
        )

    print(f"Successfully exported ViT model to {output_path}")


def download_or_export_arcface(output_path: Path):
    """
    Exports/downloads ArcFace ResNet ONNX model (512-dim embedding from 112x112 face crop).
    """
    print(f"Preparing ArcFace ONNX model at {output_path}...")
    output_path.parent.mkdir(parents=True, exist_ok=True)

    # Standard ArcFace (ResNet50 / ResNet100) onnx source
    url = "https://github.com/deepinsight/insightface/releases/download/v0.7/w600k_r50.onnx"
    try:
        import urllib.request
        print(f"Downloading ArcFace (ResNet50) from {url}...")
        urllib.request.urlretrieve(url, str(output_path))
        print(f"Saved ArcFace model to {output_path}")
    except Exception as e:
        print(f"Direct download failed ({e}), attempting export from DeepFace...")
        from deepface import DeepFace
        model = DeepFace.build_model("ArcFace")
        # If it's a tf/keras model, export via tf2onnx
        try:
            import tf2onnx
            import tensorflow as tf
            spec = (tf.TensorSpec((None, 112, 112, 3), tf.float32, name="input"),)
            _, _ = tf2onnx.convert.from_keras(model.model, input_signature=spec, output_path=str(output_path))
            print(f"Exported ArcFace Keras model via tf2onnx to {output_path}")
        except ImportError:
            print("Please ensure tf2onnx is available, or manually place an ArcFace ONNX file at", output_path)
            raise


def download_or_export_retinaface(output_path: Path):
    """
    Downloads/exports RetinaFace (MobileNet or ResNet) ONNX model for face detection and 5-point landmarks.
    """
    print(f"Preparing RetinaFace ONNX model at {output_path}...")
    output_path.parent.mkdir(parents=True, exist_ok=True)

    # MobileNet0.25 RetinaFace ONNX (fast, lightweight, highly accurate for photography)
    url = "https://github.com/serengil/deepface_models/releases/download/v1.0/retinaface.h5"
    # Alternative direct ONNX: standard RetinaFace MobileNet0.25
    direct_onnx_url = "https://github.com/deepinsight/insightface/releases/download/v0.7/scrfd_500m_bnkps.onnx"
    try:
        import urllib.request
        print(f"Downloading face detector (SCRFD/RetinaFace) from {direct_onnx_url}...")
        urllib.request.urlretrieve(direct_onnx_url, str(output_path))
        print(f"Saved Face Detector model to {output_path}")
    except Exception as e:
        print(f"Failed to fetch detector model: {e}")
        raise


def main():
    parser = argparse.ArgumentParser(description="Export who_dis models to ONNX for Rust.")
    parser.add_argument("--output-dir", type=Path, default=Path(__file__).parent / "models",
                        help="Target directory for .onnx files (default: who_dis/models)")
    parser.add_argument("--only-vit", action="store_true", help="Only export ViT model")
    args = parser.parse_args()

    args.output_dir.mkdir(parents=True, exist_ok=True)

    export_vit(args.output_dir / "vit_large.onnx")

    if not args.only_vit:
        try:
            download_or_export_arcface(args.output_dir / "arcface.onnx")
        except Exception as e:
            print(f"Warning: ArcFace setup skipped or failed: {e}")

        try:
            download_or_export_retinaface(args.output_dir / "retinaface.onnx")
        except Exception as e:
            print(f"Warning: RetinaFace setup skipped or failed: {e}")

    print("\nExport process finished. Models are in:", args.output_dir)


if __name__ == "__main__":
    main()
