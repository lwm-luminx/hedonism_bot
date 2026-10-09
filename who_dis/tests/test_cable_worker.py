import asyncio
import importlib
import json
import time

import pytest
from unittest.mock import MagicMock

from gql import gql

from hedonism.who_dis import support

worker_module = importlib.import_module("hedonism.who_dis.__main__")


class Socket:
    def __init__(self, reject_lease=False):
        self.incoming = asyncio.Queue()
        self.sent = []
        self.reject_lease = reject_lease

    async def send(self, raw):
        envelope = json.loads(raw)
        self.sent.append(envelope)
        if envelope["command"] != "message":
            return
        data = json.loads(envelope["data"])
        reply = None
        if data["action"] == "heartbeat":
            reply = {"type": "lease_rejected"} if self.reject_lease else {"type": "renewed", "id": data["id"]}
        elif data["action"] == "complete":
            reply = {"type": "completed", "id": data["id"]}
        if reply:
            self.incoming.put_nowait(json.dumps({"message": reply}))

    def __aiter__(self):
        return self

    async def __anext__(self):
        value = await self.incoming.get()
        if value is None:
            raise StopAsyncIteration
        return value


def test_inference_buffers_mutations_instead_of_writing_before_completion(monkeypatch):
    underlying = MagicMock()
    monkeypatch.setattr(support, "Client", MagicMock(return_value=underlying))

    def infer_photo(_photo):
        request = gql("mutation Caption($caption: String!) { updatePhotoCaption(caption: $caption) { id } }")
        request.variable_values = {"caption": "Buffered"}
        support.graph_client().execute(request)

    monkeypatch.setitem(worker_module.TASKS, "test", infer_photo)
    result = worker_module.infer({"task": "test", "photo_id": "photo"})
    assert result == {"caption": "Buffered"}
    underlying.execute.assert_not_called()


def exercise_socket(monkeypatch, reject_lease=False, disconnect_busy=False):
    finished = []

    def infer(_work):
        time.sleep(0.1)
        finished.append(True)
        return {"caption": "Result", "description": "Description"}

    monkeypatch.setattr(worker_module, "infer", infer)

    async def scenario():
        socket = Socket(reject_lease)
        worker = worker_module.Worker(socket)
        socket.incoming.put_nowait(json.dumps({"type": "confirm_subscription"}))
        socket.incoming.put_nowait(json.dumps({"message": {
            "type": "work", "id": "job", "lease_token": "lease",
            "task": "hedonism.who_dis.worker.caption_image", "photo_id": "photo",
        }}))
        run = asyncio.create_task(worker.run())
        while worker.active is None:
            await asyncio.sleep(0.01)
        if not disconnect_busy:
            while worker.active is not None:
                await asyncio.sleep(0.01)
        socket.incoming.put_nowait(None)
        await asyncio.wait_for(run, timeout=2)
        assert finished
        return [json.loads(frame["data"])["action"] for frame in socket.sent if frame["command"] == "message"]

    return asyncio.run(scenario())


def test_results_complete_over_the_authenticated_socket(monkeypatch):
    actions = exercise_socket(monkeypatch)
    assert "heartbeat" in actions
    assert "complete" in actions


def test_rejected_lease_cannot_send_results(monkeypatch):
    assert "complete" not in exercise_socket(monkeypatch, reject_lease=True)


def test_disconnect_waits_for_existing_inference_and_discards_results(monkeypatch):
    assert "complete" not in exercise_socket(monkeypatch, disconnect_busy=True)


@pytest.mark.parametrize("control", [
    {"type": "welcome"},
    {"type": "ping", "message": 1791498000},
    {"message": None},
    {"message": "unexpected"},
])
def test_control_frames_do_not_interrupt_channel_messages(control, capsys):
    async def scenario():
        socket = Socket()
        worker = worker_module.Worker(socket)
        worker.claim_pending = True
        for envelope in [
            {"type": "confirm_subscription"}, control,
            {"message": {"type": "idle"}},
        ]:
            socket.incoming.put_nowait(json.dumps(envelope))
        socket.incoming.put_nowait(None)
        await worker.run()
        assert worker.subscribed
        assert not worker.claim_pending
    asyncio.run(scenario())
    assert "COGSWORTH_READY" in capsys.readouterr().out


@pytest.mark.parametrize("status, marker", [
    (401, "COGSWORTH_AUTH_REQUIRED"),
    (403, "COGSWORTH_AUTH_REQUIRED"),
    (404, "COGSWORTH_ENDPOINT_UNAVAILABLE"),
])
def test_connection_rejection_reports_actionable_status(monkeypatch, capsys, status, marker):
    from websockets.exceptions import InvalidStatus
    from websockets.http11 import Response
    from websockets.datastructures import Headers

    def rejected(*args, **kwargs):
        raise InvalidStatus(Response(status, "Rejected", Headers()))

    monkeypatch.setenv("CABLE_URL", "wss://example.com/cable")
    monkeypatch.setenv("API_KEY", "test-only")
    monkeypatch.setattr(worker_module, "connect", rejected)
    asyncio.run(worker_module.main())
    assert marker in capsys.readouterr().out


def test_worker_process_survives_cable_heartbeats():
    import os
    import sys
    from pathlib import Path
    from websockets.asyncio.server import serve

    async def scenario():
        heartbeats_sent = asyncio.Event()

        async def server(socket):
            assert socket.request.headers["Authorization"] == "Bearer integration-test"
            subscription = json.loads(await socket.recv())
            assert subscription["command"] == "subscribe"
            await socket.send(json.dumps({"type": "welcome"}))
            await socket.send(json.dumps({"type": "confirm_subscription", "identifier": worker_module.IDENTIFIER}))
            for tick in range(5):
                await socket.send(json.dumps({"type": "ping", "message": 1791498000 + tick}))
                await asyncio.sleep(0.1)
            heartbeats_sent.set()
            await socket.wait_closed()

        async with serve(server, "127.0.0.1", 0, subprotocols=["actioncable-v1-json"]) as listener:
            port = listener.sockets[0].getsockname()[1]
            process = await asyncio.create_subprocess_exec(
                sys.executable, "-B", "-u", "-m", "hedonism.who_dis",
                cwd=Path(__file__).resolve().parents[1],
                env={**os.environ, "CABLE_URL": f"ws://127.0.0.1:{port}/cable", "API_KEY": "integration-test"},
                stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE,
            )
            try:
                assert await asyncio.wait_for(process.stdout.readline(), timeout=5) == b"COGSWORTH_READY\n"
                await asyncio.wait_for(heartbeats_sent.wait(), timeout=5)
                assert process.returncode is None, (await process.stderr.read()).decode()
            finally:
                if process.returncode is None:
                    process.terminate()
                await asyncio.wait_for(process.wait(), timeout=5)
    asyncio.run(scenario())
