#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source tools/cloud_env.sh
mkdir -p "$SUDOKU_TOOLS_DIR/downloads" "$SUDOKU_TOOLS_DIR/bin"

# The prepared image supplies Godot 4.6.3 and Java 21. Fail clearly if that changes.
godot --version | grep -q '^4\.6\.3\.' || { echo 'Godot 4.6.3 is required.' >&2; exit 1; }
command -v java >/dev/null
command -v keytool >/dev/null

template_name=Godot_v4.6.3-stable_export_templates.tpz
template_dir="$XDG_DATA_HOME/godot/export_templates/4.6.3.stable"
if [[ ! -f "$template_dir/android_debug.apk" || ! -f "$template_dir/android_release.apk" ]]; then
  if [[ ! -f "$SUDOKU_TOOLS_DIR/downloads/$template_name" ]]; then
    curl --fail --location --retry 2 \
      "https://github.com/godotengine/godot/releases/download/4.6.3-stable/$template_name" \
      --output "$SUDOKU_TOOLS_DIR/downloads/$template_name.part"
    mv "$SUDOKU_TOOLS_DIR/downloads/$template_name.part" "$SUDOKU_TOOLS_DIR/downloads/$template_name"
  fi
  python3 - <<'PY'
import hashlib, os, zipfile
from pathlib import Path
root = Path(os.environ['SUDOKU_TOOLS_DIR'])
archive = root / 'downloads/Godot_v4.6.3-stable_export_templates.tpz'
# From the official 4.6.3 release SHA512-SUMS.txt, fetched over verified HTTPS.
expected = 'da606b61c10157844f8300172df374472665f95015495cb1a7cd132c40ede404faa96cc1016a4b9662db9909ddea69632c4948b2cd11163438dad4808881fb68'
h = hashlib.sha512()
with archive.open('rb') as f:
    for block in iter(lambda: f.read(1024 * 1024), b''): h.update(block)
if h.hexdigest() != expected: raise SystemExit('Godot template checksum mismatch')
target = root / 'xdg-data/godot/export_templates/4.6.3.stable'
target.mkdir(parents=True, exist_ok=True)
with zipfile.ZipFile(archive) as z:
    for name in ('android_debug.apk', 'android_release.apk', 'version.txt'):
        (target / name).write_bytes(z.read('templates/' + name))
PY
fi

if [[ ! -x "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" ]]; then
  curl --fail --location --retry 2 \
    https://dl.google.com/android/repository/commandlinetools-linux-16111833_latest.zip \
    --output "$SUDOKU_TOOLS_DIR/downloads/android-commandline.zip"
  python3 - <<'PY'
import hashlib, os, zipfile
from pathlib import Path
root = Path(os.environ['SUDOKU_TOOLS_DIR'])
archive = root / 'downloads/android-commandline.zip'
# Checksum published in Google's repository2-1.xml for this exact archive.
expected = 'e025545c62a8e64c7559119566a569fb1dec5f60'
if hashlib.sha1(archive.read_bytes()).hexdigest() != expected:
    raise SystemExit('Android command-line tools checksum mismatch')
target = root / 'android-sdk/cmdline-tools/latest'
with zipfile.ZipFile(archive) as z:
    for item in z.infolist():
        relative = Path(item.filename).relative_to('cmdline-tools')
        if str(relative) == '.': continue
        path = target / relative
        if item.is_dir(): path.mkdir(parents=True, exist_ok=True)
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(z.read(item))
            path.chmod((item.external_attr >> 16) or 0o644)
PY
fi

if [[ ! -x "$ANDROID_HOME/build-tools/36.0.0/apksigner" || ! -x "$ANDROID_HOME/platform-tools/adb" || ! -f "$ANDROID_HOME/platforms/android-36/android.jar" ]]; then
  # sdkmanager handles repository artifact verification; its exit status is preserved.
  "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" --sdk_root="$ANDROID_HOME" --licenses < <(yes 2>/dev/null)
  "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" --sdk_root="$ANDROID_HOME" \
    'platform-tools' 'build-tools;36.0.0' 'platforms;android-36'
fi

# Android's adb needs its conventional cache directory even for version checks.
mkdir -p "$HOME/.android"
if [[ ! -f "$SUDOKU_TOOLS_DIR/debug.keystore" ]]; then
  keytool -genkeypair -keystore "$SUDOKU_TOOLS_DIR/debug.keystore" \
    -storepass android -alias androiddebugkey -keypass android \
    -dname 'CN=Android Debug,O=Android,C=US' -keyalg RSA -keysize 2048 -validity 10000
fi
mkdir -p build
touch build/.gdignore
godot --headless --path . --editor --import --quit
python3 tools/configure_android.py
printf 'Godot and Android development dependencies are ready.\n'
