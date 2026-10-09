"""Fail the signed smoke test if Cogsworth's sandbox permissions expand."""
import plistlib
import subprocess
import sys
from pathlib import Path


def verify(bundle, expected):
    result = subprocess.run(
        ["codesign", "--display", "--entitlements", ":-", str(bundle)],
        check=True, capture_output=True,
    )
    entitlements = plistlib.loads(result.stdout)
    security = {key: value for key, value in entitlements.items()
                if key.startswith("com.apple.security.")}
    if security != {key: True for key in expected}:
        raise SystemExit(f"Unexpected sandbox entitlements in {bundle.name}: {security}")


app = Path(sys.argv[1])
base = {"com.apple.security.app-sandbox", "com.apple.security.network.client"}
verify(app, base | {"com.apple.security.files.user-selected.read-only",
                    "com.apple.security.files.bookmarks.app-scope"})
services = app / "Contents/XPCServices"
if {path.name for path in services.glob("*.xpc")} != {"CogsworthUploader.xpc", "CogsworthML.xpc"}:
    raise SystemExit("Expected exactly the native uploader and ML XPC services")
for name in ("Uploader", "ML"):
    verify(services / f"Cogsworth{name}.xpc", base)
if any((services / "CogsworthUploader.xpc").rglob("Python.framework")):
    raise SystemExit("The native uploader must not bundle Python")
if not (services / "CogsworthML.xpc/Contents/Frameworks/Python.framework").is_dir():
    raise SystemExit("The ML worker is missing its embedded Python framework")
torch_bin = services / "CogsworthML.xpc/Contents/Frameworks/Python.framework/Resources/lib/python3.13/site-packages/torch/bin"
if list(torch_bin.glob("protoc*")):
    raise SystemExit("Build-time protoc compilers must not ship in the app")
verify(torch_bin / "torch_shm_manager", {"com.apple.security.app-sandbox", "com.apple.security.inherit"})
print("Signed entitlements verified: two sandboxed XPC services, outgoing network only")
