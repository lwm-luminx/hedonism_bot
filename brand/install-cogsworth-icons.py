#!/usr/bin/env python3
"""Install Cogsworth artwork and regenerate its macOS icon sizes with sips."""

import json
from pathlib import Path
import shutil
import subprocess

ROOT = Path(__file__).resolve().parent.parent
SOURCES = ROOT / "brand/concepts/cogsworth"
CATALOG = ROOT / "apple/macOS/Assets.xcassets"


def resize(source, destination, size):
    subprocess.run(
        ["sips", "-z", str(size), str(size), str(source), "--out", str(destination)],
        check=True, stdout=subprocess.DEVNULL,
    )


for variant in ("framed", "transparent", "borderless"):
    name = "Cogsworth" + variant.capitalize()
    imageset = CATALOG / (name + ".imageset")
    imageset.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(SOURCES / (variant + "-v1.png"), imageset / (name + ".png"))
    (imageset / "Contents.json").write_text(json.dumps({
        "images": [{"filename": name + ".png", "idiom": "universal"}],
        "info": {"author": "xcode", "version": 1},
    }, indent=2) + "\n")

appicon = CATALOG / "AppIcon.appiconset"
for image in json.loads((appicon / "Contents.json").read_text())["images"]:
    size = int(image["size"].split("x")[0]) * int(image["scale"][0])
    resize(SOURCES / "framed-v1.png", appicon / image["filename"], size)

resize(SOURCES / "framed-v1.png",
       ROOT / "mac/HedonismUploader/Resources/AppIcon-1024.png", 1024)
# Both Xcode and SwiftPM load this shared resource in the menu and settings header.
resize(SOURCES / "transparent-v1.png",
       ROOT / "mac/HedonismUploader/Sources/HedonismUploader/Resources/LumiereMark.png", 1024)
