"""Entry point for the native macOS XPC host's isolated CPython interpreter."""
import io
import json
import os
import sys


def _redirect_output():
    import _cogsworth_xpc

    class Output(io.TextIOBase):
        def __init__(self):
            self.pending = ""

        @property
        def encoding(self):
            return "utf-8"

        def writable(self):
            return True

        def write(self, text):
            self.pending += text
            while "\n" in self.pending:
                line, self.pending = self.pending.split("\n", 1)
                if line in {"COGSWORTH_READY", "COGSWORTH_RECONNECTING",
                            "COGSWORTH_AUTH_REQUIRED", "COGSWORTH_ENDPOINT_UNAVAILABLE"}:
                    _cogsworth_xpc.emit(line)
            self.pending = self.pending[-16384:]
            return len(text)

        def flush(self):
            pass

    sys.stdout = Output()
    sys.stderr = Output()


def run(configuration_json):
    configuration = json.loads(configuration_json)
    # Supplied by the native host, never from user-provided Python code or a script path.
    os.environ.update(configuration)
    _redirect_output()
    import asyncio
    from .__main__ import main
    asyncio.run(main())


def check(configuration_json):
    """Offline validation through the same embedded interpreter used for inference."""
    import importlib
    _redirect_output()
    assert sys.flags.isolated and sys.flags.dont_write_bytecode
    assert sys.flags.no_user_site and sys.flags.ignore_environment
    for path in sys.path:
        assert os.path.realpath(path).startswith(os.path.realpath(sys.prefix) + os.sep)
    for name in ("ssl", "hashlib", "numpy", "PIL", "torch", "tensorflow", "tf_keras",
                 "transformers", "deepface", "websockets", "hedonism.who_dis.app"):
        importlib.import_module(name)
