"""Authenticated Action Cable worker; inference stays off the socket receive loop."""
import asyncio
import json
import os
import random
from urllib.parse import urlsplit

from websockets.asyncio.client import connect
from websockets.exceptions import ConnectionClosed, InvalidStatus

from .app import TASKS
from .support import capture_updates

IDENTIFIER = json.dumps({"channel": "WorkerChannel", "protocol": 1}, separators=(",", ":"))


def infer(work):
    task = TASKS[work["task"]]
    with capture_updates() as updates:
        task(work["photo_id"])
    if len(updates) != 1:
        raise RuntimeError("Inference did not produce a result")
    return updates[0]


class Worker:
    def __init__(self, socket):
        self.socket = socket
        self.active = None
        self.claim_pending = False
        self.claim_sent_at = 0
        self.subscribed = False
        self.connected = True
        self.lease_valid = False
        self.renewed = asyncio.Event()
        self.completed = asyncio.Event()
        self.current = None

    async def action(self, action, **data):
        await self.socket.send(json.dumps({
            "command": "message", "identifier": IDENTIFIER,
            "data": json.dumps({"action": action, **data}),
        }))

    async def poll(self):
        while self.connected:
            if self.subscribed and self.active is None and (
                not self.claim_pending or asyncio.get_running_loop().time() - self.claim_sent_at >= 30
            ):
                self.claim_pending = True
                self.claim_sent_at = asyncio.get_running_loop().time()
                await self.action("claim")
            await asyncio.sleep(10)

    async def heartbeat(self, work):
        while self.connected and self.lease_valid:
            self.renewed.clear()
            await self.action("heartbeat", id=work["id"], lease_token=work["lease_token"])
            try:
                await asyncio.wait_for(self.renewed.wait(), timeout=30)
            except TimeoutError:
                self.lease_valid = False
                return
            await asyncio.sleep(30)

    async def run_work(self, work):
        self.lease_valid = True
        heartbeat = asyncio.create_task(self.heartbeat(work))
        try:
            # Terminate the helper on a hung native inference; cancelling a thread cannot stop it.
            try:
                result = await asyncio.wait_for(asyncio.to_thread(infer, work), timeout=3500)
            except TimeoutError:
                os._exit(2)
            if self.connected and self.lease_valid:
                self.completed.clear()
                for _ in range(3):
                    await self.action("complete", id=work["id"], lease_token=work["lease_token"], result=result)
                    try:
                        await asyncio.wait_for(self.completed.wait(), timeout=15)
                        break
                    except TimeoutError:
                        continue
        except Exception:
            if self.connected and self.lease_valid:
                await self.action("failed", id=work["id"], lease_token=work["lease_token"])
        finally:
            heartbeat.cancel()
            await asyncio.gather(heartbeat, return_exceptions=True)
            self.active = None
            self.current = None

    async def run(self):
        await self.socket.send(json.dumps({"command": "subscribe", "identifier": IDENTIFIER}))
        polling = asyncio.create_task(self.poll())
        try:
            async for raw in self.socket:
                envelope = json.loads(raw)
                if envelope.get("type") == "confirm_subscription":
                    self.subscribed = True
                    print("COGSWORTH_READY", flush=True)
                elif envelope.get("type") == "reject_subscription":
                    raise PermissionError("Worker subscription rejected")
                elif envelope.get("type") == "disconnect":
                    if envelope.get("reconnect") is False:
                        raise PermissionError("Worker credential revoked")
                    break
                # Cable control frames (notably ping) carry a numeric message,
                # while channel messages carry a dictionary.
                if envelope.get("type") is not None:
                    continue
                message = envelope.get("message")
                if not isinstance(message, dict):
                    continue
                kind = message.get("type")
                if kind in {"work", "idle"}:
                    self.claim_pending = False
                if kind == "work" and self.active is None:
                    if message["task"] not in TASKS:
                        await self.action("failed", id=message["id"], lease_token=message["lease_token"])
                    else:
                        self.current = message["id"]
                        self.active = asyncio.create_task(self.run_work(message))
                elif kind == "renewed" and message.get("id") == self.current:
                    self.renewed.set()
                elif kind == "completed" and message.get("id") == self.current:
                    self.completed.set()
                elif kind == "lease_rejected":
                    self.lease_valid = False
                    self.completed.set()
        finally:
            self.connected = False
            self.lease_valid = False
            polling.cancel()
            await asyncio.gather(polling, return_exceptions=True)
            # Keep the process busy until an old inference finishes. Never overlap claims on reconnect.
            if self.active:
                await self.active


async def main():
    endpoint = os.environ["CABLE_URL"]
    parsed = urlsplit(endpoint)
    if parsed.scheme != "wss" and not (parsed.scheme == "ws" and parsed.hostname in {"localhost", "127.0.0.1"}):
        raise ValueError("Worker requires a secure WebSocket endpoint")
    origin = ("https" if parsed.scheme == "wss" else "http") + "://" + parsed.netloc
    token = os.environ["API_KEY"]
    delay = 1
    while True:
        try:
            async with connect(endpoint, additional_headers={"Authorization": f"Bearer {token}"},
                               origin=origin, subprotocols=["actioncable-v1-json"], max_size=2**20) as socket:
                delay = 1
                await Worker(socket).run()
        except PermissionError:
            print("COGSWORTH_AUTH_REQUIRED", flush=True)
            return
        except InvalidStatus as error:
            if error.response.status_code in {401, 403}:
                print("COGSWORTH_AUTH_REQUIRED", flush=True)
                return
            if error.response.status_code == 404:
                print("COGSWORTH_ENDPOINT_UNAVAILABLE", flush=True)
                return
        except (OSError, ConnectionClosed, TimeoutError):
            pass
        print("COGSWORTH_RECONNECTING", flush=True)
        await asyncio.sleep(delay + random.random())
        delay = min(delay * 2, 60)


if __name__ == "__main__":
    asyncio.run(main())
