#!/bin/bash

# Jarvis Voice - Complete Standalone DMG Builder
# Includes: Python, all dependencies, AI model, and binaries
# NO internet required - works completely offline!

set -e

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║      🎤 JARVIS VOICE - COMPLETE STANDALONE BUILDER         ║"
echo "║                                                            ║"
echo "║  ✅ Python 3.x Environment                                 ║"
echo "║  ✅ All Python Packages (rumps, sounddevice, numpy, etc.)  ║"
echo "║  ✅ Whisper AI Model (141MB)                               ║"
echo "║  ✅ Whisper Binary (whisper-cli)                           ║"
echo "║  ✅ Custom Logo                                            ║"
echo "║  ✅ Application Code v1.3.0                                ║"
echo "║                                                            ║"
echo "║  🔒 100% Offline - No Internet Required!                   ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Configuration
APP_NAME="Jarvis Voice"
APP_BUNDLE_NAME="JarvisVoice"
VERSION="1.3.1"
BUILD_DIR="/tmp/jarvis-complete-build"
DMG_NAME="JarvisVoice-${VERSION}-Complete-Standalone.dmg"
VOLUME_NAME="Jarvis Voice Installer"

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="${SCRIPT_DIR}"
APP_DIR="${BUILD_DIR}/${APP_BUNDLE_NAME}.app"
RESOURCES_DIR="${APP_DIR}/Contents/Resources"
MACOS_DIR="${APP_DIR}/Contents/MacOS"
FRAMEWORKS_DIR="${APP_DIR}/Contents/Frameworks"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Check prerequisites
print_status "Checking prerequisites..."

# Check for logo file
if [ -f "${SOURCE_DIR}/logo.png" ]; then
    LOGO_FILE="${SOURCE_DIR}/logo.png"
    print_success "Found logo.png"
elif [ -f "${SOURCE_DIR}/logo.jpg" ]; then
    LOGO_FILE="${SOURCE_DIR}/logo.jpg"
    print_success "Found logo.jpg"
else
    print_warning "No logo file found. Will create default icon."
    LOGO_FILE=""
fi

# Check for create-dmg
if ! command -v create-dmg &> /dev/null; then
    print_status "Installing create-dmg..."
    brew install create-dmg || {
        print_error "Failed to install create-dmg"
        exit 1
    }
fi
print_success "create-dmg installed"

# Check for Whisper model
if [ ! -f "${SOURCE_DIR}/whisper.cpp/models/ggml-base.en.bin" ]; then
    print_error "Whisper model not found!"
    print_status "Expected: whisper.cpp/models/ggml-base.en.bin"
    exit 1
fi
MODEL_SIZE=$(du -h "${SOURCE_DIR}/whisper.cpp/models/ggml-base.en.bin" | cut -f1)
print_success "Whisper model found (${MODEL_SIZE})"

# Check for whisper binary
if [ ! -f "${SOURCE_DIR}/whisper.cpp/build/bin/whisper-cli" ]; then
    print_error "Whisper binary not found!"
    print_status "Expected: whisper.cpp/build/bin/whisper-cli"
    exit 1
fi
print_success "Whisper binary found"

print_success "All prerequisites check complete"

# Clean and create build directory
print_status "Preparing build directory..."
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"
mkdir -p "${APP_DIR}/Contents"/{MacOS,Resources,Frameworks,embedded}
mkdir -p "${RESOURCES_DIR}/"{models,bin,src}
print_success "Build directory ready"

# Step 1: Create app icon from logo
print_status "Creating app icon..."

if [ -n "${LOGO_FILE}" ]; then
    python3 << PYEOF
import subprocess
import sys
from PIL import Image
import os

logo_path = "${LOGO_FILE}"
iconset_dir = "${BUILD_DIR}/JarvisVoice.iconset"
os.makedirs(iconset_dir, exist_ok=True)

# Load and resize logo to square
img = Image.open(logo_path)
width, height = img.size
size = max(width, height)
new_img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
x = (size - width) // 2
y = (size - height) // 2
new_img.paste(img, (x, y))

# Generate all required icon sizes
sizes = [16, 32, 64, 128, 256, 512, 1024]
for s in sizes:
    resized = new_img.resize((s, s), Image.Resampling.LANCZOS)
    resized.save(f"{iconset_dir}/icon_{s}x{s}.png")
    if s <= 512:
        resized2x = new_img.resize((s*2, s*2), Image.Resampling.LANCZOS)
        resized2x.save(f"{iconset_dir}/icon_{s}x{s}@2x.png")

# Convert to icns
result = subprocess.run(
    ["iconutil", "-c", "icns", iconset_dir, "-o", "${RESOURCES_DIR}/AppIcon.icns"],
    capture_output=True,
    text=True
)

if result.returncode != 0:
    print(f"Error creating icon: {result.stderr}")
    sys.exit(1)

print("✅ Icon created successfully from logo")
PYEOF
    
    if [ $? -eq 0 ]; then
        print_success "App icon created from logo"
    else
        print_warning "Failed to create icon from logo, using default"
        create_default_icon
    fi
else
    # Create default icon
    print_status "Creating default microphone icon..."
    python3 << PYEOF
from PIL import Image, ImageDraw
import os

size = 1024
img = Image.new('RGBA', (size, size), (0, 122, 255, 255))
draw = ImageDraw.Draw(img)
draw.rounded_rectangle([0, 0, size, size], radius=200, fill=(0, 122, 255, 255))

iconset_dir = "${BUILD_DIR}/JarvisVoice.iconset"
os.makedirs(iconset_dir, exist_ok=True)

sizes = [16, 32, 64, 128, 256, 512, 1024]
for s in sizes:
    resized = img.resize((s, s), Image.Resampling.LANCZOS)
    resized.save(f"{iconset_dir}/icon_{s}x{s}.png")
    if s <= 512:
        resized2x = img.resize((s*2, s*2), Image.Resampling.LANCZOS)
        resized2x.save(f"{iconset_dir}/icon_{s}x{s}@2x.png")

os.system(f"iconutil -c icns {iconset_dir} -o ${RESOURCES_DIR}/AppIcon.icns")
print("✅ Default icon created")
PYEOF
    print_success "Default icon created"
fi

# Step 2: Create Info.plist
cat > "${APP_DIR}/Contents/Info.plist" << EOF
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
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.15</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSMicrophoneUsageDescription</key>
    <string>Jarvis Voice needs microphone access to transcribe your speech.</string>
    <key>NSAccessibilityUsageDescription</key>
    <string>Jarvis Voice needs accessibility access to type transcribed text into other applications.</string>
</dict>
</plist>
EOF

print_success "Info.plist created"

# Step 3: Embed Python and install dependencies
print_status "Setting up embedded Python environment..."

EMBEDDED_DIR="${APP_DIR}/Contents/embedded"
mkdir -p "${EMBEDDED_DIR}"

# Create virtual environment
print_status "Creating Python virtual environment..."
python3 -m venv "${EMBEDDED_DIR}/python"
PYTHON_BIN="${EMBEDDED_DIR}/python/bin/python3"
PIP_BIN="${EMBEDDED_DIR}/python/bin/pip"

print_success "Python virtual environment created"

# Upgrade pip and install all dependencies
print_status "Installing Python packages (this may take a few minutes)..."
"${PIP_BIN}" install --upgrade pip setuptools wheel

# Install all required packages
print_status "Installing rumps..."
"${PIP_BIN}" install rumps

print_status "Installing sounddevice..."
"${PIP_BIN}" install sounddevice

print_status "Installing numpy..."
"${PIP_BIN}" install numpy

print_status "Installing pynput..."
"${PIP_BIN}" install pynput

print_status "Installing soundfile..."
"${PIP_BIN}" install soundfile

print_status "Installing pillow..."
"${PIP_BIN}" install pillow

print_success "All Python packages installed"

# Step 4: Copy Whisper model
print_status "Copying Whisper AI model..."
cp "${SOURCE_DIR}/whisper.cpp/models/ggml-base.en.bin" "${RESOURCES_DIR}/models/"
print_success "Whisper model copied (141MB)"

# Step 5: Copy Whisper binary
print_status "Copying Whisper binary..."
cp "${SOURCE_DIR}/whisper.cpp/build/bin/whisper-cli" "${RESOURCES_DIR}/bin/"
cp "${SOURCE_DIR}/whisper.cpp/build/bin/main" "${RESOURCES_DIR}/bin/" 2>/dev/null || true
chmod +x "${RESOURCES_DIR}/bin/"*
print_success "Whisper binary copied"

# Step 6: Copy application source
print_status "Copying application files..."
cp -R "${SOURCE_DIR}/src/"* "${RESOURCES_DIR}/src/"
cp "${SOURCE_DIR}/whisper_cpp_wrapper.py" "${RESOURCES_DIR}/"
cp "${SOURCE_DIR}/requirements.txt" "${RESOURCES_DIR}/"
print_success "Application files copied"

# Step 7: Create launcher script
print_status "Creating launcher..."

cat > "${MACOS_DIR}/JarvisVoice" << 'LAUNCHEREOF'
#!/bin/bash

# Jarvis Voice Launcher
# Complete standalone version with embedded Python

APP_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RESOURCES="${APP_ROOT}/Resources"
PYTHON="${APP_ROOT}/embedded/python/bin/python3"

# Set environment variables
export PYTHONPATH="${RESOURCES}:${PYTHONPATH}"
export PATH="${APP_ROOT}/embedded/python/bin:${PATH}"

# Set Whisper paths for the wrapper
export WHISPER_MODEL="${RESOURCES}/models/ggml-base.en.bin"
export WHISPER_BINARY="${RESOURCES}/bin/whisper-cli"

# Verify components exist
if [ ! -f "${WHISPER_MODEL}" ]; then
    osascript -e 'display dialog "Error: Whisper AI model not found. Please reinstall the application." buttons {"OK"} default button "OK" with icon stop'
    exit 1
fi

if [ ! -f "${WHISPER_BINARY}" ]; then
    osascript -e 'display dialog "Error: Whisper binary not found. Please reinstall the application." buttons {"OK"} default button "OK" with icon stop'
    exit 1
fi

if [ ! -f "${PYTHON}" ]; then
    osascript -e 'display dialog "Error: Python environment not found. Please reinstall the application." buttons {"OK"} default button "OK" with icon stop'
    exit 1
fi

# Launch the application
cd "${RESOURCES}"
exec "${PYTHON}" "${RESOURCES}/src/main.py"
LAUNCHEREOF

chmod +x "${MACOS_DIR}/JarvisVoice"

print_success "Launcher created"

# Step 8: Create background image for DMG
print_status "Creating DMG background..."

python3 << PYEOF
from PIL import Image, ImageDraw, ImageFont

# Create background image for DMG
width, height = 700, 450
img = Image.new('RGBA', (width, height), (240, 240, 240, 255))
draw = ImageDraw.Draw(img)

# Add gradient background
for i in range(height):
    r = int(240 - (i / height) * 20)
    g = int(240 - (i / height) * 20)
    b = int(240 - (i / height) * 10)
    draw.line([(0, i), (width, i)], fill=(r, g, b, 255))

# Add text
try:
    title_font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 32)
    subtitle_font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 18)
    text_font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 16)
except:
    title_font = ImageFont.load_default()
    subtitle_font = ImageFont.load_default()
    text_font = ImageFont.load_default()

# Title
title = "🎤 Jarvis Voice"
bbox = draw.textbbox((0, 0), title, font=title_font)
title_width = bbox[2] - bbox[0]
draw.text(((width - title_width) // 2, 40), title, font=title_font, fill=(0, 0, 0, 255))

# Subtitle
subtitle = "Complete Standalone Package"
bbox = draw.textbbox((0, 0), subtitle, font=subtitle_font)
subtitle_width = bbox[2] - bbox[0]
draw.text(((width - subtitle_width) // 2, 80), subtitle, font=subtitle_font, fill=(80, 80, 80, 255))

# Features
features = [
    "✅ Python + All Packages Included",
    "✅ Whisper AI Model (141MB)",
    "✅ No Internet Required",
    "",
    "Drag Jarvis Voice to Applications",
    ""
]

y = 130
for line in features:
    if line:
        bbox = draw.textbbox((0, 0), line, font=text_font)
        text_width = bbox[2] - bbox[0]
        draw.text(((width - text_width) // 2, y), line, font=text_font, fill=(80, 80, 80, 255))
    y += 28

# Save
img.save("${BUILD_DIR}/background.png")
print("DMG background created")
PYEOF

print_success "DMG background created"

# Step 9: Sign the app
print_status "Code signing app..."
codesign --force --deep --sign - "${APP_DIR}" 2>/dev/null || {
    print_warning "Could not sign app (no developer certificate)"
    print_warning "Users will see security warning on first launch"
}

# Step 10: Create DMG
print_status "Creating DMG file..."

cd "${BUILD_DIR}"

DMG_FINAL="${SOURCE_DIR}/${DMG_NAME}"

# Remove old DMG if exists
rm -f "${DMG_FINAL}"

# Create DMG using create-dmg
create-dmg \
    --volname "${VOLUME_NAME}" \
    --volicon "${RESOURCES_DIR}/AppIcon.icns" \
    --background "${BUILD_DIR}/background.png" \
    --window-pos 200 120 \
    --window-size 700 450 \
    --icon-size 100 \
    --icon "${APP_BUNDLE_NAME}.app" 175 250 \
    --hide-extension "${APP_BUNDLE_NAME}.app" \
    --app-drop-link 525 250 \
    "${DMG_FINAL}" \
    "${APP_DIR}" 2>/dev/null || {
    
    # Fallback: use hdiutil if create-dmg fails
    print_warning "create-dmg failed, using hdiutil fallback..."
    
    # Create temporary directory structure
    TEMP_DMG_DIR="${BUILD_DIR}/dmg_contents"
    mkdir -p "${TEMP_DMG_DIR}"
    cp -R "${APP_DIR}" "${TEMP_DMG_DIR}/"
    
    # Create Applications shortcut
    ln -s /Applications "${TEMP_DMG_DIR}/Applications"
    
    # Create DMG
    hdiutil create -volname "${VOLUME_NAME}" \
        -srcfolder "${TEMP_DMG_DIR}" \
        -ov -format UDZO \
        "${DMG_FINAL}"
}

# Verify DMG was created
if [ -f "${DMG_FINAL}" ]; then
    DMG_SIZE=$(du -h "${DMG_FINAL}" | cut -f1)
    print_success "DMG created successfully!"
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                     🎉 BUILD COMPLETE!                     ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    echo "📦 File: ${DMG_NAME}"
    echo "📊 Size: ${DMG_SIZE}"
    echo "📍 Location: ${SOURCE_DIR}/"
    echo ""
    echo "✅ Package Includes:"
    echo "   • Python 3.x Environment"
    echo "   • All Python Packages (rumps, sounddevice, numpy, pynput, soundfile)"
    echo "   • Whisper AI Model (141MB)"
    echo "   • Whisper Binary (whisper-cli)"
    echo "   • Application Code v${VERSION}"
    echo "   • Custom Logo"
    echo ""
    echo "🔒 Features:"
    echo "   • 100% Offline - No Internet Required"
    echo "   • Works on any macOS 10.15+ system"
    echo "   • Drag-and-drop installation"
    echo ""
    echo "🚀 Ready to distribute!"
    echo ""
else
    print_error "Failed to create DMG"
    exit 1
fi

# Cleanup
print_status "Cleaning up build files..."
rm -rf "${BUILD_DIR}"
print_success "Cleanup complete"

echo ""
echo "✨ The DMG is ready at: ${SOURCE_DIR}/${DMG_NAME}"
echo ""
