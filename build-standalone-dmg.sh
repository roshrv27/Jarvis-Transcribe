#!/bin/bash

# Jarvis Voice - Standalone DMG Creator
# Creates a self-contained DMG with Python, AI model, and all dependencies
# Users can install by dragging to Applications folder

set -e

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║      🎤 JARVIS VOICE - STANDALONE DMG CREATOR              ║"
echo "║   Self-Contained Installer with Embedded Python            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Configuration
APP_NAME="Jarvis Voice"
APP_BUNDLE_NAME="JarvisVoice"
VERSION="1.3"
BUILD_DIR="/tmp/jarvis-build"
DMG_NAME="JarvisVoice-${VERSION}-Standalone.dmg"
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
elif [ -f "${SOURCE_DIR}/assets/logo.png" ]; then
    LOGO_FILE="${SOURCE_DIR}/assets/logo.png"
    print_success "Found assets/logo.png"
else
    print_warning "No logo file found. Will create default icon."
    LOGO_FILE=""
fi

# Check for required tools
if ! command -v create-dmg &> /dev/null; then
    print_status "Installing create-dmg..."
    brew install create-dmg || {
        print_error "Failed to install create-dmg. Please install it manually: brew install create-dmg"
        exit 1
    }
fi

print_success "Prerequisites check complete"

# Clean and create build directory
print_status "Preparing build directory..."
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"
mkdir -p "${APP_DIR}/Contents"/{MacOS,Resources,Frameworks,embedded}
print_success "Build directory ready"

# Step 1: Create app icon from logo
print_status "Creating app icon..."

if [ -n "${LOGO_FILE}" ]; then
    # Create icon from provided logo
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
# Make it square by cropping or padding
width, height = img.size
size = max(width, height)
new_img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
# Center the image
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

print("Icon created successfully")
PYEOF
    
    if [ $? -eq 0 ]; then
        print_success "App icon created from logo"
    else
        print_warning "Failed to create icon from logo, using default"
        create_default_icon
    fi
else
    # Create default microphone icon
    print_status "Creating default microphone icon..."
    python3 << PYEOF
from PIL import Image, ImageDraw, ImageFont
import os

size = 1024
img = Image.new('RGBA', (size, size), (255, 59, 48, 255))
draw = ImageDraw.Draw(img)

# Draw rounded rectangle background
draw.rounded_rectangle([0, 0, size, size], radius=200, fill=(0, 122, 255, 255))

# Draw microphone symbol
try:
    font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 500)
except:
    font = ImageFont.load_default()

text = "🎤"
bbox = draw.textbbox((0, 0), text, font=font)
text_width = bbox[2] - bbox[0]
text_height = bbox[3] - bbox[1]
x = (size - text_width) // 2
y = (size - text_height) // 2
draw.text((x, y), text, font=font, fill=(255, 255, 255, 255))

# Save iconset
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
print("Default icon created")
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

# Step 3: Embed Python and create virtual environment
print_status "Setting up embedded Python environment..."

# Check if we have a working Python
PYTHON_VERSION=$(python3 --version 2>&1 | grep -o '3\.[0-9]*' | head -1)
print_status "Using Python ${PYTHON_VERSION}"

# Create embedded Python structure
EMBEDDED_DIR="${APP_DIR}/Contents/embedded"
mkdir -p "${EMBEDDED_DIR}"

# Copy Python framework
PYTHON_FRAMEWORK="/Library/Frameworks/Python.framework/Versions/${PYTHON_VERSION}"
if [ -d "${PYTHON_FRAMEWORK}" ]; then
    print_status "Copying Python framework..."
    cp -R "${PYTHON_FRAMEWORK}" "${EMBEDDED_DIR}/python" 2>/dev/null || {
        print_warning "Could not copy full framework, using minimal approach"
        # Alternative: Create venv with all dependencies
        python3 -m venv "${EMBEDDED_DIR}/venv"
    }
else
    print_status "Creating virtual environment..."
    python3 -m venv "${EMBEDDED_DIR}/venv"
fi

# Determine Python path
if [ -d "${EMBEDDED_DIR}/python" ]; then
    PYTHON_BIN="${EMBEDDED_DIR}/python/bin/python3"
else
    PYTHON_BIN="${EMBEDDED_DIR}/venv/bin/python3"
fi

print_success "Python environment set up"

# Step 4: Install dependencies
print_status "Installing Python dependencies..."

# Upgrade pip and install requirements
"${PYTHON_BIN}" -m pip install --upgrade pip setuptools wheel

# Install requirements
if [ -f "${SOURCE_DIR}/requirements.txt" ]; then
    "${PYTHON_BIN}" -m pip install -r "${SOURCE_DIR}/requirements.txt"
fi

# Install additional dependencies
"${PYTHON_BIN}" -m pip install \
    rumps \
    sounddevice \
    numpy \
    pynput \
    py2app \
    pillow

print_success "Dependencies installed"

# Step 5: Download and include Whisper model
print_status "Setting up Whisper model..."

MODELS_DIR="${RESOURCES_DIR}/models"
mkdir -p "${MODELS_DIR}"

# Check if whisper.cpp is built
WHISPER_DIR="${SOURCE_DIR}/whisper.cpp"
if [ -d "${WHISPER_DIR}" ]; then
    print_status "Found whisper.cpp directory"
    
    # Copy whisper.cpp binaries if they exist
    if [ -f "${WHISPER_DIR}/main" ]; then
        cp "${WHISPER_DIR}/main" "${MACOS_DIR}/whisper-cpp"
        chmod +x "${MACOS_DIR}/whisper-cpp"
        print_success "Whisper binary copied"
    fi
    
    # Check for existing model or download base model
    if [ -f "${WHISPER_DIR}/models/ggml-base.en.bin" ]; then
        print_status "Copying existing model..."
        cp "${WHISPER_DIR}/models/ggml-base.en.bin" "${MODELS_DIR}/"
        print_success "Model copied (base.en)"
    elif [ -f "${WHISPER_DIR}/models/ggml-base.bin" ]; then
        print_status "Copying existing model..."
        cp "${WHISPER_DIR}/models/ggml-base.bin" "${MODELS_DIR}/"
        print_success "Model copied (base)"
    else
        print_status "Downloading base model (this may take a few minutes)..."
        cd "${MODELS_DIR}"
        curl -L -o ggml-base.en.bin \
            "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin" \
            --progress-bar || {
            print_error "Failed to download model"
            print_warning "You may need to manually download the model later"
        }
        cd "${SCRIPT_DIR}"
        print_success "Model downloaded"
    fi
else
    print_warning "whisper.cpp directory not found. Model must be downloaded manually."
fi

# Step 6: Copy application source
print_status "Copying application files..."

# Create app structure
mkdir -p "${RESOURCES_DIR}/src"
cp -R "${SOURCE_DIR}/src/"* "${RESOURCES_DIR}/src/"
cp "${SOURCE_DIR}/whisper_cpp_wrapper.py" "${RESOURCES_DIR}/" 2>/dev/null || true
cp "${SOURCE_DIR}/requirements.txt" "${RESOURCES_DIR}/"

print_success "Application files copied"

# Step 7: Create launcher script
print_status "Creating launcher..."

cat > "${MACOS_DIR}/JarvisVoice" << 'LAUNCHEREOF'
#!/bin/bash

# Jarvis Voice Launcher
# Self-contained with embedded Python

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
RESOURCES_DIR="${APP_ROOT}/Resources"
EMBEDDED_DIR="${APP_ROOT}/embedded"

# Set up environment
export PATH="${EMBEDDED_DIR}/venv/bin:${PATH}"
export PYTHONPATH="${RESOURCES_DIR}:${PYTHONPATH}"

# Find Python
if [ -f "${EMBEDDED_DIR}/venv/bin/python3" ]; then
    PYTHON="${EMBEDDED_DIR}/venv/bin/python3"
elif [ -f "${EMBEDDED_DIR}/python/bin/python3" ]; then
    PYTHON="${EMBEDDED_DIR}/python/bin/python3"
else
    # Fallback to system Python
    PYTHON="python3"
fi

# Check if first run (model might be missing)
if [ ! -f "${RESOURCES_DIR}/models/ggml-base.en.bin" ] && [ ! -f "${RESOURCES_DIR}/models/ggml-base.bin" ]; then
    osascript -e 'display dialog "Whisper model not found. Please ensure the model file is included in the app bundle." buttons {"OK"} default button "OK" with icon stop'
    exit 1
fi

# Launch the application
cd "${RESOURCES_DIR}"
exec "${PYTHON}" "${RESOURCES_DIR}/src/main.py"
LAUNCHEREOF

chmod +x "${MACOS_DIR}/JarvisVoice"

print_success "Launcher created"

# Step 8: Create background image for DMG
print_status "Creating DMG background..."

python3 << PYEOF
from PIL import Image, ImageDraw, ImageFont
import os

# Create background image for DMG
width, height = 600, 400
img = Image.new('RGBA', (width, height), (240, 240, 240, 255))
draw = ImageDraw.Draw(img)

# Add gradient or design elements
for i in range(height):
    r = int(240 - (i / height) * 20)
    g = int(240 - (i / height) * 20)
    b = int(240 - (i / height) * 10)
    draw.line([(0, i), (width, i)], fill=(r, g, b, 255))

# Add text
try:
    title_font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 32)
    text_font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 18)
except:
    title_font = ImageFont.load_default()
    text_font = ImageFont.load_default()

# Title
title = "Jarvis Voice"
bbox = draw.textbbox((0, 0), title, font=title_font)
title_width = bbox[2] - bbox[0]
draw.text(((width - title_width) // 2, 50), title, font=title_font, fill=(0, 0, 0, 255))

# Instructions
instructions = [
    "Drag Jarvis Voice to Applications",
    "",
    "1. Open Applications folder",
    "2. Double-click Jarvis Voice",
    "3. Grant permissions when prompted",
    "",
    "Press Right Option key to record"
]

y = 120
for line in instructions:
    if line:
        bbox = draw.textbbox((0, 0), line, font=text_font)
        text_width = bbox[2] - bbox[0]
        draw.text(((width - text_width) // 2, y), line, font=text_font, fill=(80, 80, 80, 255))
    y += 30

# Save
img.save("${BUILD_DIR}/background.png")
print("DMG background created")
PYEOF

print_success "DMG background created"

# Step 9: Sign the app (ad-hoc if no developer cert)
print_status "Code signing app..."

codesign --force --deep --sign - "${APP_DIR}" 2>/dev/null || {
    print_warning "Could not sign app (no developer certificate). App will still work but may show security warning."
}

print_success "App ready"

# Step 10: Create DMG
print_status "Creating DMG file..."

cd "${BUILD_DIR}"

# Create temporary DMG
DMG_TEMP="${BUILD_DIR}/temp.dmg"
DMG_FINAL="${SOURCE_DIR}/${DMG_NAME}"

# Remove old DMG if exists
rm -f "${DMG_FINAL}"

# Create DMG using create-dmg
create-dmg \
    --volname "${VOLUME_NAME}" \
    --volicon "${RESOURCES_DIR}/AppIcon.icns" \
    --background "${BUILD_DIR}/background.png" \
    --window-pos 200 120 \
    --window-size 600 400 \
    --icon-size 100 \
    --icon "${APP_BUNDLE_NAME}.app" 150 200 \
    --hide-extension "${APP_BUNDLE_NAME}.app" \
    --app-drop-link 450 200 \
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
    print_success "DMG created successfully!"
    echo ""
    echo "📦 DMG Location: ${DMG_FINAL}"
    echo "📊 File Size: $(du -h "${DMG_FINAL}" | cut -f1)"
    echo ""
    echo "✅ Ready to distribute!"
    echo ""
    echo "Users can:"
    echo "   1. Double-click the DMG"
    echo "   2. Drag Jarvis Voice to Applications"
    echo "   3. Launch from Applications folder"
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
echo "🎉 Build complete!"
echo ""
echo "📦 Output: ${DMG_FINAL}"
echo ""
