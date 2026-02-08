#!/bin/bash

# Quick DMG Builder for Jarvis Voice
# Simple version that works with existing setup

set -e

echo "🎤 Jarvis Voice - Quick DMG Builder"
echo "===================================="
echo ""

# Check for logo
if [ -f "logo.png" ]; then
    echo "✅ Found logo.png"
    LOGO="logo.png"
elif [ -f "logo.jpg" ]; then
    echo "✅ Found logo.jpg"
    LOGO="logo.jpg"
else
    echo "⚠️  No logo found, will use default icon"
    LOGO=""
fi

# Check dependencies
echo ""
echo "Checking dependencies..."

# Check for create-dmg
if ! command -v create-dmg &> /dev/null; then
    echo "Installing create-dmg..."
    brew install create-dmg || {
        echo "❌ Failed to install create-dmg"
        echo "Please install manually: brew install create-dmg"
        exit 1
    }
fi

echo "✅ create-dmg installed"

# Check for whisper model
if [ ! -f "whisper.cpp/models/ggml-base.en.bin" ] && [ ! -f "whisper.cpp/models/ggml-base.bin" ]; then
    echo ""
    echo "⚠️  WARNING: No Whisper model found!"
    echo "The app needs a model to work."
    echo ""
    echo "Options:"
    echo "1. Download now (automatic)"
    echo "2. Skip and include later"
    echo ""
    read -p "Download model now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Downloading base model..."
        mkdir -p whisper.cpp/models
        cd whisper.cpp/models
        curl -L -o ggml-base.en.bin \
            "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin" \
            --progress-bar || {
            echo "❌ Failed to download model"
            exit 1
        }
        cd ../..
        echo "✅ Model downloaded"
    fi
fi

# Create app bundle
echo ""
echo "Creating app bundle..."

APP_NAME="JarvisVoice"
APP_DIR="/tmp/${APP_NAME}.app"
rm -rf "${APP_DIR}"
mkdir -p "${APP_DIR}/Contents/"{MacOS,Resources,Models}

# Create icon
echo "Creating app icon..."
if [ -n "$LOGO" ]; then
    python3 << PYEOF
from PIL import Image
import os
import subprocess

# Load logo
img = Image.open("$LOGO")

# Make square
width, height = img.size
size = max(width, height)
new_img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
x = (size - width) // 2
y = (size - height) // 2
new_img.paste(img, (x, y))

# Create iconset
iconset_dir = "/tmp/JarvisVoice.iconset"
os.makedirs(iconset_dir, exist_ok=True)

sizes = [16, 32, 64, 128, 256, 512, 1024]
for s in sizes:
    resized = new_img.resize((s, s), Image.Resampling.LANCZOS)
    resized.save(f"{iconset_dir}/icon_{s}x{s}.png")
    if s <= 512:
        resized2x = new_img.resize((s*2, s*2), Image.Resampling.LANCZOS)
        resized2x.save(f"{iconset_dir}/icon_{s}x{s}@2x.png")

# Convert to icns
result = subprocess.run(
    ["iconutil", "-c", "icns", iconset_dir, "-o", "${APP_DIR}/Contents/Resources/AppIcon.icns"],
    capture_output=True,
    text=True
)

if result.returncode == 0:
    print("✅ Icon created successfully")
else:
    print(f"Warning: Could not create icon: {result.stderr}")
PYEOF
else
    # Create default icon
    python3 << PYEOF
from PIL import Image, ImageDraw
import os

size = 1024
img = Image.new('RGBA', (size, size), (0, 122, 255, 255))
draw = ImageDraw.Draw(img)
draw.rounded_rectangle([0, 0, size, size], radius=200, fill=(0, 122, 255, 255))

iconset_dir = "/tmp/JarvisVoice.iconset"
os.makedirs(iconset_dir, exist_ok=True)

sizes = [16, 32, 64, 128, 256, 512, 1024]
for s in sizes:
    resized = img.resize((s, s), Image.Resampling.LANCZOS)
    resized.save(f"{iconset_dir}/icon_{s}x{s}.png")
    if s <= 512:
        resized2x = img.resize((s*2, s*2), Image.Resampling.LANCZOS)
        resized2x.save(f"{iconset_dir}/icon_{s}x{s}@2x.png")

os.system(f"iconutil -c icns {iconset_dir} -o ${APP_DIR}/Contents/Resources/AppIcon.icns")
print("✅ Default icon created")
PYEOF
fi

# Create Info.plist
cat > "${APP_DIR}/Contents/Info.plist" << 'EOF'
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
    <string>1.3</string>
    <key>CFBundleVersion</key>
    <string>1.3</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.15</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSMicrophoneUsageDescription</key>
    <string>Jarvis Voice needs microphone access to transcribe your speech.</string>
    <key>NSAccessibilityUsageDescription</key>
    <string>Jarvis Voice needs accessibility access to type transcribed text.</string>
</dict>
</plist>
EOF

# Copy application files
echo "Copying application files..."
cp -R src "${APP_DIR}/Contents/Resources/"
cp whisper_cpp_wrapper.py "${APP_DIR}/Contents/Resources/" 2>/dev/null || true
cp requirements.txt "${APP_DIR}/Contents/Resources/"

# Copy models if they exist
if [ -f "whisper.cpp/models/ggml-base.en.bin" ]; then
    cp "whisper.cpp/models/ggml-base.en.bin" "${APP_DIR}/Contents/Resources/Models/"
    echo "✅ Model included (base.en)"
elif [ -f "whisper.cpp/models/ggml-base.bin" ]; then
    cp "whisper.cpp/models/ggml-base.bin" "${APP_DIR}/Contents/Resources/Models/"
    echo "✅ Model included (base)"
fi

# Create launcher
cat > "${APP_DIR}/Contents/MacOS/JarvisVoice" << 'EOF'
#!/bin/bash

# Jarvis Voice Launcher
APP_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RESOURCES="${APP_ROOT}/Resources"

cd "${RESOURCES}"

# Check if virtual environment exists in user home
VENV_DIR="${HOME}/.jarvisvoice/venv"
if [ ! -d "$VENV_DIR" ]; then
    # Show setup dialog
    osascript -e 'display dialog "Jarvis Voice needs to set up Python dependencies. This will be done automatically." buttons {"Continue"} default button "Continue" with icon note'
    
    # Create virtual environment
    mkdir -p "${HOME}/.jarvisvoice"
    python3 -m venv "$VENV_DIR"
    
    # Install dependencies
    "${VENV_DIR}/bin/pip" install --upgrade pip
    "${VENV_DIR}/bin/pip" install rumps sounddevice numpy pynput
    
    # Copy model if not exists
    if [ ! -f "${HOME}/.jarvisvoice/models/ggml-base.en.bin" ] && [ -f "${RESOURCES}/Models/ggml-base.en.bin" ]; then
        mkdir -p "${HOME}/.jarvisvoice/models"
        cp "${RESOURCES}/Models/ggml-base.en.bin" "${HOME}/.jarvisvoice/models/"
    fi
fi

# Launch application
export PYTHONPATH="${RESOURCES}:${PYTHONPATH}"
exec "${VENV_DIR}/bin/python" "${RESOURCES}/src/main.py"
EOF

chmod +x "${APP_DIR}/Contents/MacOS/JarvisVoice"

# Sign app
echo "Code signing app..."
codesign --force --deep --sign - "${APP_DIR}" 2>/dev/null || echo "⚠️  Could not sign app (will show security warning)"

# Create DMG
echo ""
echo "Creating DMG..."

DMG_NAME="JarvisVoice-1.3.dmg"
rm -f "${DMG_NAME}"

# Create temporary directory for DMG contents
DMG_TEMP="/tmp/jarvis-dmg"
rm -rf "${DMG_TEMP}"
mkdir -p "${DMG_TEMP}"
cp -R "${APP_DIR}" "${DMG_TEMP}/"
ln -s /Applications "${DMG_TEMP}/Applications"

# Create background
python3 << PYEOF
from PIL import Image, ImageDraw, ImageFont

img = Image.new('RGBA', (600, 400), (240, 240, 240, 255))
draw = ImageDraw.Draw(img)

# Gradient background
for i in range(400):
    r = int(240 - (i / 400) * 20)
    g = int(240 - (i / 400) * 20)
    b = int(240 - (i / 400) * 10)
    draw.line([(0, i), (600, i)], fill=(r, g, b, 255))

try:
    font_title = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 28)
    font_text = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 16)
except:
    font_title = ImageFont.load_default()
    font_text = ImageFont.load_default()

# Title
title = "🎤 Jarvis Voice"
bbox = draw.textbbox((0, 0), title, font=font_title)
tw = bbox[2] - bbox[0]
draw.text(((600-tw)//2, 40), title, font=font_title, fill=(0, 0, 0, 255))

# Instructions
lines = [
    "Drag Jarvis Voice to Applications",
    "",
    "First time setup will install",
    "Python dependencies automatically",
    "",
    "Press Right Option key to record"
]

y = 120
for line in lines:
    if line:
        bbox = draw.textbbox((0, 0), line, font=font_text)
        tw = bbox[2] - bbox[0]
        draw.text(((600-tw)//2, y), line, font=font_text, fill=(80, 80, 80, 255))
    y += 30

img.save("/tmp/dmg-background.png")
PYEOF

# Create DMG with create-dmg
create-dmg \
    --volname "Jarvis Voice Installer" \
    --background "/tmp/dmg-background.png" \
    --window-pos 200 120 \
    --window-size 600 400 \
    --icon-size 100 \
    --icon "JarvisVoice.app" 150 200 \
    --hide-extension "JarvisVoice.app" \
    --app-drop-link 450 200 \
    "${DMG_NAME}" \
    "${DMG_TEMP}" 2>/dev/null || {
    
    # Fallback: use hdiutil
    echo "Using fallback DMG creation..."
    hdiutil create -volname "Jarvis Voice Installer" \
        -srcfolder "${DMG_TEMP}" \
        -ov -format UDZO \
        "${DMG_NAME}"
}

# Cleanup
rm -rf "${DMG_TEMP}" "${APP_DIR}" /tmp/JarvisVoice.iconset /tmp/dmg-background.png

echo ""
echo "✅ DMG created successfully!"
echo ""
echo "📦 File: ${DMG_NAME}"
echo "📊 Size: $(du -h "${DMG_NAME}" | cut -f1)"
echo ""
echo "🚀 Ready to distribute!"
echo ""
echo "Note: First run will install Python dependencies (~50MB download)"
echo "      This happens only once per user."
