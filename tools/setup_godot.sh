#!/usr/bin/env bash
# Installs the Godot 4.3 editor + Android export templates, drops the
# gradle-based Android build template into android/build, and points the
# Godot editor settings at a local Android SDK. Idempotent: safe to re-run.
#
# Requires on PATH: curl, unzip, keytool, and an Android SDK containing
# platform-tools/ and build-tools/<version>/ (aapt, zipalign, apksigner).
set -euo pipefail

GODOT_VERSION="${GODOT_VERSION:-4.3-stable}"
GODOT_TEMPLATE_ID="${GODOT_VERSION%-stable}.stable"
GODOT_INSTALL_DIR="${GODOT_INSTALL_DIR:-/opt/godot}"
ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-/usr/lib/android-sdk}}"
TEMPLATES_DIR="${HOME}/.local/share/godot/export_templates/${GODOT_TEMPLATE_ID}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

mkdir -p "$GODOT_INSTALL_DIR" "$TEMPLATES_DIR"

if [ ! -x "$GODOT_INSTALL_DIR/godot" ]; then
	echo "Downloading Godot ${GODOT_VERSION} editor..."
	curl -sSL -o /tmp/godot_editor.zip \
		"https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/Godot_v${GODOT_VERSION}_linux.x86_64.zip"
	unzip -o -q /tmp/godot_editor.zip -d "$GODOT_INSTALL_DIR"
	mv "$GODOT_INSTALL_DIR/Godot_v${GODOT_VERSION}_linux.x86_64" "$GODOT_INSTALL_DIR/godot"
	chmod +x "$GODOT_INSTALL_DIR/godot"
	rm -f /tmp/godot_editor.zip
fi

if [ ! -f "$TEMPLATES_DIR/android_source.zip" ]; then
	echo "Downloading Godot ${GODOT_VERSION} export templates..."
	curl -sSL -o /tmp/export_templates.tpz \
		"https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/Godot_v${GODOT_VERSION}_export_templates.tpz"
	rm -rf /tmp/godot_templates_extract
	mkdir -p /tmp/godot_templates_extract
	unzip -o -q /tmp/export_templates.tpz -d /tmp/godot_templates_extract
	rm -rf "$TEMPLATES_DIR"
	mv /tmp/godot_templates_extract/templates "$TEMPLATES_DIR"
	rm -rf /tmp/godot_templates_extract /tmp/export_templates.tpz
fi

if [ ! -f "$PROJECT_DIR/android/build/build.gradle" ]; then
	echo "Installing Android gradle build template into android/build..."
	mkdir -p "$PROJECT_DIR/android/build"
	unzip -o -q "$TEMPLATES_DIR/android_source.zip" -d "$PROJECT_DIR/android/build"
	printf "%s" "$GODOT_TEMPLATE_ID" > "$PROJECT_DIR/android/.build_version"
fi

if [ ! -f "$PROJECT_DIR/keystore/debug.keystore" ]; then
	echo "Generating debug.keystore..."
	mkdir -p "$PROJECT_DIR/keystore"
	keytool -genkeypair -v -keystore "$PROJECT_DIR/keystore/debug.keystore" \
		-storepass android -alias androiddebugkey -keypass android \
		-keyalg RSA -keysize 2048 -validity 10000 \
		-dname "CN=Android Debug,O=Android,C=US"
fi

mkdir -p "${HOME}/.config/godot"
cat > "${HOME}/.config/godot/editor_settings-4.tres" << EOF
[gd_resource type="EditorSettings" format=3]

[resource]
export/android/android_sdk_path = "${ANDROID_SDK_ROOT}"
export/android/debug_keystore = ""
export/android/debug_keystore_user = "androiddebugkey"
export/android/debug_keystore_pass = "android"
export/android/force_system_user = false
export/android/one_click_deploy_clear_previous_install = true
export/android/shutdown_adb_on_exit = true
EOF

echo "Godot ready:            $GODOT_INSTALL_DIR/godot"
echo "Export templates ready: $TEMPLATES_DIR"
echo "Android build template: $PROJECT_DIR/android/build"
echo "Android SDK path:       $ANDROID_SDK_ROOT"
