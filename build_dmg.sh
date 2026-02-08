#!/bin/bash

# Build DMG installer for Jarvis Voice
# This script creates a self-contained macOS app bundle with all dependencies

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }

# Configuration
APP_NAME="JarvisVoice"
APP_VERSION="3.0"
DMG_NAME="JarvisVoice-${APP_VERSION}.dmg"
BUILD_DIR="build"
APP_BUNDLE="${BUILD_DIR}/${APP_NAME}.app"
RESOURCES_DIR="${APP_BUNDLE}/Contents/Resources"
MACOS_DIR="${APP_BUNDLE}/Contents/MacOS"

print_status "Building Jarvis Voice DMG installer v${APP_VERSION}"
print_status "This will create a self-contained app bundle"
echo ""

# Clean and create build directory
print_status "Setting up build directory..."
rm -rf "${BUILD_DIR}"
mkdir -p "${APP_BUNDLE}/Contents/"{MacOS,Resources,Frameworks}
mkdir -p "${RESOURCES_DIR}/"{models,whisper.cpp/bin,python_env}
print_success "Build directory created"

# Check if model exists
MODEL_SOURCE="$HOME/Applications/JarvisVoice/whisper.cpp/models/ggml-base.en.bin"
if [ ! -f "${MODEL_SOURCE}" ]; then
    print_error "Model not found at ${MODEL_SOURCE}"
    print_status "Downloading model first..."
    mkdir -p "$HOME/Applications/JarvisVoice/whisper.cpp/models"
    curl -L -o "$HOME/Applications/JarvisVoice/whisper.cpp/models/ggml-base.en.bin" \
        "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin"
fi

# Copy model to app bundle
print_status "Copying model to app bundle..."
cp "${MODEL_SOURCE}" "${RESOURCES_DIR}/models/"
print_success "Model copied ($(du -h "${RESOURCES_DIR}/models/ggml-base.en.bin" | cut -f1))"

# Check if whisper-cli exists
WHISPER_BUILD_DIR="$HOME/Applications/JarvisVoice_backup_20260208_230810/whisper.cpp/build"
WHISPER_CLI_SOURCE="${WHISPER_BUILD_DIR}/bin/whisper-cli"

if [ ! -f "${WHISPER_CLI_SOURCE}" ]; then
    # Try alternative locations
    WHISPER_BUILD_DIR="$HOME/Applications/JarvisVoice/whisper.cpp/build"
    WHISPER_CLI_SOURCE="${WHISPER_BUILD_DIR}/bin/whisper-cli"
    
    if [ ! -f "${WHISPER_CLI_SOURCE}" ]; then
        print_error "whisper-cli not found"
        print_error "Please ensure whisper.cpp is built"
        exit 1
    fi
fi

# Copy whisper-cli to app bundle
print_status "Copying whisper-cli and libraries to app bundle..."
cp "${WHISPER_CLI_SOURCE}" "${RESOURCES_DIR}/whisper.cpp/bin/"
chmod +x "${RESOURCES_DIR}/whisper.cpp/bin/whisper-cli"

# Copy required dylibs
mkdir -p "${RESOURCES_DIR}/whisper.cpp/lib"

# Copy all whisper and ggml libraries (flatten structure - all in lib/)
cp "${WHISPER_BUILD_DIR}/src/"libwhisper*.dylib "${RESOURCES_DIR}/whisper.cpp/lib/" 2>/dev/null || true
cp "${WHISPER_BUILD_DIR}/ggml/src/"libggml*.dylib "${RESOURCES_DIR}/whisper.cpp/lib/" 2>/dev/null || true
cp "${WHISPER_BUILD_DIR}/ggml/src/ggml-blas/"libggml*.dylib "${RESOURCES_DIR}/whisper.cpp/lib/" 2>/dev/null || true
cp "${WHISPER_BUILD_DIR}/ggml/src/ggml-metal/"libggml*.dylib "${RESOURCES_DIR}/whisper.cpp/lib/" 2>/dev/null || true

# Fix library paths in whisper-cli using install_name_tool
WHISPER_CLI_BIN="${RESOURCES_DIR}/whisper.cpp/bin/whisper-cli"

print_status "Fixing library paths in whisper-cli and libraries..."

# Remove old rpaths and add new one
install_name_tool -delete_rpath "${WHISPER_BUILD_DIR}/src" "${WHISPER_CLI_BIN}" 2>/dev/null || true
install_name_tool -delete_rpath "${WHISPER_BUILD_DIR}/ggml/src" "${WHISPER_CLI_BIN}" 2>/dev/null || true
install_name_tool -delete_rpath "${WHISPER_BUILD_DIR}/ggml/src/ggml-blas" "${WHISPER_CLI_BIN}" 2>/dev/null || true
install_name_tool -delete_rpath "${WHISPER_BUILD_DIR}/ggml/src/ggml-metal" "${WHISPER_CLI_BIN}" 2>/dev/null || true

# Add the correct rpath
install_name_tool -add_rpath "@loader_path/../lib" "${WHISPER_CLI_BIN}" 2>/dev/null || true

# Fix library references in all dylibs
for lib in "${RESOURCES_DIR}/whisper.cpp/lib/"*.dylib; do
    if [ -f "$lib" ]; then
        # Fix references to other libraries - replace build paths with @rpath
        install_name_tool -change \
            "${WHISPER_BUILD_DIR}/ggml/src/libggml.dylib" \
            "@rpath/libggml.dylib" \
            "$lib" 2>/dev/null || true
        
        install_name_tool -change \
            "${WHISPER_BUILD_DIR}/ggml/src/ggml-blas/libggml-blas.dylib" \
            "@rpath/libggml-blas.dylib" \
            "$lib" 2>/dev/null || true
            
        install_name_tool -change \
            "${WHISPER_BUILD_DIR}/ggml/src/ggml-metal/libggml-metal.dylib" \
            "@rpath/libggml-metal.dylib" \
            "$lib" 2>/dev/null || true
        
        install_name_tool -change \
            "${WHISPER_BUILD_DIR}/src/libwhisper.dylib" \
            "@rpath/libwhisper.dylib" \
            "$lib" 2>/dev/null || true
            
        # Add rpath to the library itself
        install_name_tool -add_rpath "@loader_path" "$lib" 2>/dev/null || true
    fi
done

print_success "whisper-cli and libraries copied and configured"

# Create Python virtual environment in app bundle
print_status "Creating Python virtual environment..."
cd "${RESOURCES_DIR}"
python3.10 -m venv python_env 2>/dev/null || python3 -m venv python_env
source python_env/bin/activate

# Upgrade pip and install dependencies
print_status "Installing Python dependencies (this may take a few minutes)..."
pip install --upgrade pip -q

# Install requirements
cd - > /dev/null
pip install -r requirements.txt -q

# Ensure critical packages are installed
pip install soundfile sounddevice numpy -q

print_success "Python environment set up"

# Copy application source files
print_status "Copying application files..."
cp -r src "${RESOURCES_DIR}/"
cp whisper_cpp_wrapper.py "${RESOURCES_DIR}/"

# Copy app icon if it exists
if [ -f "resources/AppIcon.icns" ]; then
    cp "resources/AppIcon.icns" "${RESOURCES_DIR}/"
    print_success "Application files and icon copied"
else
    print_warning "App icon not found, using default"
fi

# Create Info.plist
print_status "Creating Info.plist..."
cat > "${APP_BUNDLE}/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>JarvisVoice</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.jarvisvoice.app</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Jarvis Voice</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.3.1</string>
    <key>CFBundleVersion</key>
    <string>131</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.15</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSMicrophoneUsageDescription</key>
    <string>Jarvis Voice needs microphone access to transcribe your speech.</string>
    <key>NSAppleEventsUsageDescription</key>
    <string>Jarvis Voice needs to type text into other applications.</string>
</dict>
</plist>
EOF
print_success "Info.plist created"

# Create main launcher script
print_status "Creating launcher script..."
cat > "${MACOS_DIR}/JarvisVoice" << 'SCRIPT'
#!/bin/bash

# Jarvis Voice Launcher
# Sets up environment and launches the app

# Get the real path of this script (resolving symlinks)
SCRIPT_SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SCRIPT_SOURCE" ]; do
    SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_SOURCE")" && pwd)"
    SCRIPT_SOURCE="$(readlink "$SCRIPT_SOURCE")"
    [[ $SCRIPT_SOURCE != /* ]] && SCRIPT_SOURCE="$SCRIPT_DIR/$SCRIPT_SOURCE"
done
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_SOURCE")" && pwd)"

# Get the Resources directory
APP_DIR="$(cd "$SCRIPT_DIR/../Resources" && pwd)"

# CRITICAL: Set PYTHONPATH to prioritize bundled libraries
# This ensures we use the bundled whisper_cpp_wrapper.py, not any system version
export PYTHONPATH="${APP_DIR}:${APP_DIR}/src:${APP_DIR}/python_env/lib/python3.10/site-packages"
export PATH="${APP_DIR}/python_env/bin:$PATH"

# Create config directory if it doesn't exist
mkdir -p "$HOME/.jarvisvoice"

# Create default config if it doesn't exist
if [ ! -f "$HOME/.jarvisvoice/config.json" ]; then
    cat > "$HOME/.jarvisvoice/config.json" << 'CONFIG'
{
  "hotkey": "alt_r",
  "model_size": "base.en",
  "language": "en",
  "typing_delay": 0.01,
  "auto_paste": true
}
CONFIG
fi

# Launch the app
cd "${APP_DIR}"
exec "${APP_DIR}/python_env/bin/python3" "${APP_DIR}/src/main.py"
SCRIPT

chmod +x "${MACOS_DIR}/JarvisVoice"
print_success "Launcher script created"

# Patch main.py to use local imports
print_status "Patching main.py for bundled imports..."
sed -i '' 's|sys.path.insert(0, str(Path.home() / "Applications" / "JarvisVoice"))|# Using bundled whisper_cpp_wrapper|g' "${RESOURCES_DIR}/src/main.py"
print_success "main.py patched"

# Update whisper_cpp_wrapper.py to use bundled paths
print_status "Patching whisper_cpp_wrapper.py for bundled paths..."
cat > "${RESOURCES_DIR}/whisper_cpp_wrapper.py" << 'EOF'
"""
Whisper.cpp integration for Jarvis Voice
Uses the bundled whisper-cli with Metal GPU acceleration
"""

import subprocess
import tempfile
import os
import numpy as np
import soundfile as sf
from pathlib import Path
import sys


class WhisperCPP:
    """Wrapper for whisper.cpp CLI"""

    def __init__(self, model_name="base.en"):
        """Initialize whisper.cpp transcriber"""
        self.model_name = model_name
        
        # Determine paths based on whether we're bundled or not
        if getattr(sys, 'frozen', False):
            # Running in a bundle
            bundle_dir = Path(sys.executable).parent.parent / "Resources"
        else:
            # Running in normal Python environment
            # Check if we're in the bundled app structure
            app_resources = Path(__file__).parent
            if (app_resources / "models" / f"ggml-{model_name}.bin").exists():
                bundle_dir = app_resources
            else:
                # Fallback to installed location
                bundle_dir = Path.home() / "Applications" / "JarvisVoice"
        
        self.model_path = bundle_dir / "models" / f"ggml-{model_name}.bin"
        self.cli_path = bundle_dir / "whisper.cpp" / "bin" / "whisper-cli"
        
        # If model not found in bundle, try fallback locations
        if not self.model_path.exists():
            fallback_paths = [
                Path.home() / "Applications" / "JarvisVoice" / "whisper.cpp" / "models" / f"ggml-{model_name}.bin",
                Path.home() / ".jarvisvoice" / "models" / f"ggml-{model_name}.bin",
            ]
            for fallback in fallback_paths:
                if fallback.exists():
                    self.model_path = fallback
                    break
        
        # If cli not found in bundle, try fallback locations
        if not self.cli_path.exists():
            fallback_cli = Path.home() / "Applications" / "JarvisVoice" / "whisper.cpp" / "build" / "bin" / "whisper-cli"
            if fallback_cli.exists():
                self.cli_path = fallback_cli

        if not self.model_path.exists():
            raise FileNotFoundError(
                f"Whisper AI model not found. Please reinstall the application.\n"
                f"Expected at: {self.model_path}"
            )

        if not self.cli_path.exists():
            raise FileNotFoundError(
                f"whisper-cli not found. Please reinstall the application.\n"
                f"Expected at: {self.cli_path}"
            )

    # Valid ISO 639-1 language codes supported by Whisper
    VALID_LANGUAGES = {
        "en", "zh", "de", "es", "ru", "ko", "fr", "ja", "pt", "tr", "pl", "ca",
        "nl", "ar", "sv", "it", "id", "hi", "fi", "vi", "he", "uk", "el", "ms",
        "cs", "ro", "da", "hu", "ta", "no", "th", "ur", "hr", "bg", "lt", "la",
        "mi", "ml", "cy", "sk", "te", "fa", "lv", "bn", "sr", "az", "sl", "kn",
        "et", "mk", "br", "eu", "is", "hy", "ne", "mn", "bs", "kk", "sq", "sw",
        "gl", "mr", "pa", "si", "km", "sn", "yo", "so", "af", "oc", "ka", "be",
        "tg", "sd", "gu", "am", "yi", "lo", "uz", "fo", "ht", "ps", "tk", "nn",
        "mt", "sa", "lb", "my", "bo", "tl", "mg", "as", "tt", "haw", "ln", "ha",
        "ba", "jw", "su",
    }

    def transcribe(self, audio_data: np.ndarray, language: str = "en") -> str:
        """Transcribe audio using whisper.cpp"""
        if len(audio_data) == 0:
            return ""

        # Validate language code to prevent command injection
        if language not in self.VALID_LANGUAGES:
            print(f"Warning: Invalid language code '{language}', defaulting to 'en'")
            language = "en"

        # Create temporary WAV file
        with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp_file:
            tmp_path = tmp_file.name

        try:
            # Save audio as 16-bit PCM WAV file (required by whisper.cpp)
            sf.write(tmp_path, audio_data, 16000, subtype="PCM_16")

            # Run whisper-cli
            cmd = [
                str(self.cli_path),
                "-m", str(self.model_path),
                "-f", tmp_path,
                "-l", language,
                "--no-timestamps",
            ]

            result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)

            if result.returncode != 0:
                print(f"whisper.cpp error: {result.stderr}")
                return ""

            # Extract transcription from output
            lines = result.stdout.strip().split("\n")
            for line in lines:
                if line and not line.startswith("whisper_") and not line.startswith("ggml_") and not line.startswith("["):
                    return line.strip()

            return ""

        finally:
            # Clean up temp file
            if os.path.exists(tmp_path):
                os.unlink(tmp_path)
EOF
print_success "whisper_cpp_wrapper.py patched"

# Create a post-install script that will be included
print_status "Creating first-run setup script..."
cat > "${RESOURCES_DIR}/first_run.sh" << 'EOF'
#!/bin/bash
# First-run setup script

echo "Jarvis Voice First Run Setup"
echo "============================"
echo ""

# Check permissions
echo "Checking permissions..."

# Create config directory
mkdir -p "$HOME/.jarvisvoice"

# Check if config exists, create default if not
if [ ! -f "$HOME/.jarvisvoice/config.json" ]; then
    cat > "$HOME/.jarvisvoice/config.json" << 'CONFIG'
{
  "hotkey": "alt_r",
  "model_size": "base.en",
  "language": "en",
  "typing_delay": 0.01,
  "auto_paste": true
}
CONFIG
    echo "✅ Created default configuration"
fi

echo ""
echo "✅ Setup complete!"
echo ""
echo "Jarvis Voice is ready to use."
echo ""
echo "How to use:"
echo "  1. Click where you want to type"
echo "  2. Press and hold RIGHT OPTION KEY (⌥)"
echo "  3. Speak - you'll see a red pill window appear"
echo "  4. Release - text types automatically!"
echo ""
EOF
chmod +x "${RESOURCES_DIR}/first_run.sh"
print_success "First-run script created"

# Sign the app bundle (optional, for distribution)
print_status "Checking code signing..."
if command -v codesign &> /dev/null; then
    print_status "Signing app bundle..."
    codesign --force --deep --sign - "${APP_BUNDLE}" 2>/dev/null || print_warning "Could not sign app bundle (this is normal without a developer certificate)"
else
    print_warning "codesign not available, skipping signing"
fi

# Create DMG
echo ""
print_status "Creating DMG file..."

# Check if create-dmg is installed
if command -v create-dmg &> /dev/null; then
    # Use app icon for DMG if available
    VOL_ICON="${RESOURCES_DIR}/AppIcon.icns"
    if [ ! -f "$VOL_ICON" ]; then
        VOL_ICON="${RESOURCES_DIR}/python_env/bin/python3"
    fi
    
    create-dmg \
        --volname "Jarvis Voice Installer" \
        --volicon "$VOL_ICON" \
        --window-pos 200 120 \
        --window-size 600 400 \
        --icon-size 100 \
        --app-drop-link 450 185 \
        --icon "${APP_NAME}.app" 150 185 \
        "${BUILD_DIR}/${DMG_NAME}" \
        "${APP_BUNDLE}"
else
    # Fallback: use hdiutil
    print_status "Using hdiutil to create DMG (install create-dmg for better results)..."
    
    # Create a temporary directory for DMG contents
    DMG_TEMP="${BUILD_DIR}/dmg_temp"
    mkdir -p "${DMG_TEMP}"
    cp -R "${APP_BUNDLE}" "${DMG_TEMP}/"
    
    # Create a symlink to Applications folder
    ln -s /Applications "${DMG_TEMP}/Applications"
    
    # Create the DMG
    hdiutil create \
        -volname "Jarvis Voice" \
        -srcfolder "${DMG_TEMP}" \
        -ov \
        -format UDZO \
        "${BUILD_DIR}/${DMG_NAME}"
    
    # Clean up temp directory
    rm -rf "${DMG_TEMP}"
fi

# Get file size
DMG_SIZE=$(du -h "${BUILD_DIR}/${DMG_NAME}" | cut -f1)

echo ""
print_success "DMG created successfully!"
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║              ✅ DMG BUILD COMPLETE                         ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "📦 File: ${BUILD_DIR}/${DMG_NAME}"
echo "📏 Size: ${DMG_SIZE}"
echo ""
echo "📋 Installation Instructions:"
echo "   1. Double-click ${DMG_NAME} to mount it"
echo "   2. Drag 'Jarvis Voice.app' to the Applications folder"
echo "   3. Eject the disk image"
echo "   4. Launch Jarvis Voice from Applications"
echo ""
echo "⚠️  First Run:"
echo "   macOS may warn about an unsigned app."
echo "   Right-click the app and select 'Open' to allow it."
echo ""
echo "🔐 Permissions Required:"
echo "   - Microphone access (to record speech)"
echo "   - Accessibility access (to type into other apps)"
echo ""
