"""Loopback-only upload fixture; never uses production credentials or photo data."""
import base64
import hashlib
import json
import sys
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path

PAYLOAD = b"Cogsworth synthetic upload fixture\n"
DIGEST = base64.b64encode(hashlib.sha256(PAYLOAD).digest()).decode()


class Handler(BaseHTTPRequestHandler):
    completed = False
    received = False

    def log_message(self, *_):
        pass

    def respond(self, value, status=200):
        body = json.dumps(value).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_POST(self):
        body = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
        if self.headers.get("Authorization") != "Bearer smoke-test-only":
            return self.respond({}, 401)
        if self.path == "/auth/uploaded_contents":
            assert body["hashes"] == [DIGEST]
            return self.respond({"hashes": [DIGEST] if Handler.completed else []})
        assert self.path == "/graphql"
        query, variables = body["query"], body["variables"]
        if "createPhotoPromise(" in query:
            result = {"createPhotoPromise": {"promise": {"id": "fixture"}}}
        elif "attachPhotoPromiseFiles(" in query:
            file = variables["files"][0]
            assert len(variables["files"]) == 1
            assert file["imageHash"] == DIGEST and file["fileSizeBytes"] == len(PAYLOAD)
            result = {"attachPhotoPromiseFiles": {"files": [{
                "id": "fixture-file", "originalFilename": file["originalFilename"],
                "uploadUrl": f"http://127.0.0.1:{self.server.server_port}/storage",
                "uploadHeaders": {"X-Fixture": "synthetic"},
            }]}}
        elif "updatePhotoPromiseFileUpdate(" in query:
            assert variables["status"] == "SUCCESS" and Handler.received
            Handler.completed = True
            result = {"updatePhotoPromiseFileUpdate": {"file": {"status": "SUCCESS"}}}
        else:
            raise AssertionError("Unexpected GraphQL operation")
        self.respond({"data": result})

    def do_PUT(self):
        assert self.path == "/storage" and self.headers.get("X-Fixture") == "synthetic"
        assert self.rfile.read(int(self.headers["Content-Length"])) == PAYLOAD
        Handler.received = True
        self.respond({})


if __name__ == "__main__":
    server = HTTPServer(("127.0.0.1", 0), Handler)
    Path(sys.argv[1]).write_text(f"http://127.0.0.1:{server.server_port}")
    server.serve_forever()
