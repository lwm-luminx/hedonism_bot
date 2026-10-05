import importlib
import re
import sys
import types
from pathlib import Path
from unittest.mock import MagicMock

import pytest

RAILS_JOBS = Path(__file__).resolve().parents[2] / "app" / "jobs"


@pytest.fixture(scope="module")
def tasks():
    # Stub the model loaders so importing the tasks doesn't download weights.
    fake_transformers = types.ModuleType("transformers")
    fake_transformers.pipeline = MagicMock(return_value=MagicMock())
    fake_transformers.AutoImageProcessor = MagicMock()
    fake_transformers.AutoModel = MagicMock()

    with pytest.MonkeyPatch.context() as mp:
        mp.setitem(sys.modules, "transformers", fake_transformers)
        yield types.SimpleNamespace(
            app=importlib.import_module("hedonism.who_dis.app").app,
            caption_image=importlib.import_module("hedonism.who_dis.tasks.caption_image"),
            extract_facial_data=importlib.import_module("hedonism.who_dis.tasks.extract_facial_data"),
        )


def test_registered_task_names_match_rails_jobs(tasks):
    enqueued = {
        name
        for job in RAILS_JOBS.glob("*.rb")
        for name in re.findall(r'Celery\.enqueue\s+"([^"]+)"', job.read_text())
    }

    assert enqueued
    assert enqueued <= set(tasks.app.tasks)
    assert {
        "hedonism.who_dis.worker.caption_image",
        "hedonism.who_dis.worker.extract_facial_data",
        "hedonism.who_dis.worker.extract_visual_features",
    } <= set(tasks.app.tasks)


def test_caption_image_updates_caption(tasks, monkeypatch):
    worker = tasks.caption_image

    monkeypatch.setattr(worker, "get_photo_url", lambda photo_id: "https://example.com/photo.jpg")

    mock_pipe = MagicMock(
        side_effect=[
            [{"generated_text": "A professional generated caption"}],
            [{"generated_text": "A searchable description"}],
        ]
    )
    monkeypatch.setattr(worker, "LLAVA_PIPE", mock_pipe)

    client = MagicMock()
    monkeypatch.setattr(worker, "graph_client", MagicMock(return_value=client))

    worker.caption_image("photo-1")

    assert mock_pipe.call_count == 2
    assert client.execute.call_count == 1
    mutation = client.execute.call_args[0][0]
    assert mutation.variable_values == {
        "photoId": "photo-1",
        "caption": "A professional generated caption",
        "description": "A searchable description",
    }


def test_extract_facial_data_filters_low_confidence_faces(tasks, monkeypatch):
    worker = tasks.extract_facial_data

    monkeypatch.setattr(worker, "get_photo_url", lambda photo_id: "https://example.com/photo.jpg")

    monkeypatch.setattr(
        worker.DeepFace,
        "represent",
        MagicMock(
            return_value=[
                {
                    "embedding": [0.1, 0.2],
                    "facial_area": {"x": 1, "y": 2, "w": 3, "h": 4},
                    "face_confidence": 0.95,
                },
                {
                    "embedding": [0.3, 0.4],
                    "facial_area": {"x": 5, "y": 6, "w": 7, "h": 8},
                    "face_confidence": 0.4,
                },
            ]
        ),
    )

    client = MagicMock()
    monkeypatch.setattr(worker, "graph_client", MagicMock(return_value=client))

    worker.extract_facial_data("photo-2")

    assert client.execute.call_count == 1
    mutation = client.execute.call_args[0][0]
    assert mutation.variable_values == {
        "photoId": "photo-2",
        "faceObjects": [
            {
                "embedding": [0.1, 0.2],
                "facialArea": {"x": 1, "y": 2, "w": 3, "h": 4},
                "faceConfidence": 0.95,
            }
        ],
    }


def test_extract_facial_data_handles_exception(tasks, monkeypatch):
    worker = tasks.extract_facial_data

    monkeypatch.setattr(worker, "get_photo_url", lambda photo_id: "https://example.com/photo.jpg")

    monkeypatch.setattr(
        worker.DeepFace,
        "represent",
        MagicMock(side_effect=RuntimeError("deepface failure")),
    )

    client = MagicMock()
    monkeypatch.setattr(worker, "graph_client", MagicMock(return_value=client))

    worker.extract_facial_data("photo-3")

    client.execute.assert_not_called()
