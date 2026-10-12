#!/usr/bin/env python3
"""Update only Android fields in the cloud's existing local Godot editor settings."""
import json
import os
import re
import shutil
from pathlib import Path

tools = Path(os.environ.get("SUDOKU_TOOLS_DIR", "/workspace/.sudoku-tools"))
config = tools / "xdg-config/godot/editor_settings-4.6.tres"
if not config.is_file():
    raise SystemExit("Import the project in the editor once before configuring Android.")
java = shutil.which("java")
if java is None:
    raise SystemExit("A JDK is required for Android export.")
java_root = Path(java).resolve().parent.parent
values = {
    "export/android/android_sdk_path": str(tools / "android-sdk"),
    "export/android/java_sdk_path": str(java_root),
    "export/android/debug_keystore": str(tools / "debug.keystore"),
    "export/android/debug_keystore_user": "androiddebugkey",
    "export/android/debug_keystore_pass": "android",
}
contents = config.read_text()
if '[gd_resource type="EditorSettings"' not in contents or "[resource]" not in contents:
    raise SystemExit("Unexpected Godot editor settings format; leaving it unchanged.")
for key, value in values.items():
    line = key + " = " + json.dumps(value)
    pattern = re.compile(r"^" + re.escape(key) + r"\s*=.*$", re.MULTILINE)
    if pattern.search(contents):
        contents = pattern.sub(lambda match: line, contents)
    else:
        contents = contents.replace("[resource]", "[resource]\n" + line, 1)
temporary = config.with_suffix(".tmp")
temporary.write_text(contents)
temporary.replace(config)
print("Configured local Godot Android SDK and development signing settings.")
