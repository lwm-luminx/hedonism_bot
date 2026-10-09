import json
import os
import sys
import types
from unittest.mock import patch

from hedonism.who_dis.xpc_runtime import run


def test_native_bridge_emits_only_status_and_applies_configuration():
    events = []
    bridge = types.SimpleNamespace(emit=events.append)

    async def main():
        assert os.environ["API_KEY"] == "test-secret"
        assert sys.stdout.writable()
        assert not sys.stdout.isatty()
        assert sys.stdout.encoding == "utf-8"
        print("COGSWORTH_", end="")
        print("READY")
        print("A library error containing test-secret", file=sys.stderr)
        print("COGSWORTH_RECONNECTING")

    worker = types.SimpleNamespace(main=main)
    with patch.dict(sys.modules, {"_cogsworth_xpc": bridge, "hedonism.who_dis.__main__": worker}), \
         patch.dict(os.environ, {}), patch.object(sys, "stdout"), patch.object(sys, "stderr"):
        run(json.dumps({"API_KEY": "test-secret"}))
    assert events == ["COGSWORTH_READY", "COGSWORTH_RECONNECTING"]
