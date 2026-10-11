"""Fail the signed smoke test if Cogsworth's sandbox permissions expand."""
import plistlib
import subprocess
import sys
from pathlib import Path


def verify(bundle, expected, extra=None):
    result = subprocess.run(
        ["codesign", "--display", "--entitlements", ":-", str(bundle)],
        check=True, capture_output=True,
    )
    entitlements = plistlib.loads(result.stdout)
    security = {key: value for key, value in entitlements.items()
                if key.startswith("com.apple.security.")}
    wanted = {key: True for key in expected}
    wanted.update(extra or {})
    if security != wanted:
        raise SystemExit(f"Unexpected sandbox entitlements in {bundle.name}: {security}")


developer_id = "--developer-id" in sys.argv[1:]
app = Path([arg for arg in sys.argv[1:] if not arg.startswith("--")][0])
base = {"com.apple.security.app-sandbox", "com.apple.security.network.client"}
# The Developer ID build adds Sparkle, whose sandboxed installer needs these two Mach services.
sparkle = None
if developer_id:
    identifier = plistlib.load(open(app / "Contents/Info.plist", "rb"))["CFBundleIdentifier"]
    sparkle = {"com.apple.security.temporary-exception.mach-lookup.global-name":
               [f"{identifier}-spks", f"{identifier}-spki"]}
    if not (app / "Contents/Frameworks/Sparkle.framework").is_dir():
        raise SystemExit("The Developer ID build is missing Sparkle.framework")
elif (app / "Contents/Frameworks/Sparkle.framework").exists():
    raise SystemExit("Sparkle must not ship in the App Store build")
verify(app, base | {"com.apple.security.files.user-selected.read-only",
                    "com.apple.security.files.bookmarks.app-scope"}, sparkle)
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
