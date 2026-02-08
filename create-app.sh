#!/bin/bash

# Jarvis Voice macOS App Bundle Creator

echo "🎤 Creating Jarvis Voice App Bundle..."

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
APP_NAME="Jarvis Voice"
APP_DIR="$HOME/Applications/${APP_NAME}.app"

# Create app bundle structure
mkdir -p "${APP_DIR}/Contents/MacOS"
mkdir -p "${APP_DIR}/Contents/Resources"

# Create Info.plist
cat > "${APP_DIR}/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>launcher</string>
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
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.15</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSMicrophoneUsageDescription</key>
    <string>Jarvis Voice needs microphone access to transcribe your speech.</string>
</dict>
</plist>
EOF

# Create launcher script
cat > "${APP_DIR}/Contents/MacOS/launcher" << EOF
#!/bin/bash

# Jarvis Voice Launcher

SCRIPT_DIR="${SCRIPT_DIR}"

# Check if virtual environment exists
if [ ! -d "\${SCRIPT_DIR}/venv" ]; then
    osascript -e 'display dialog "Jarvis Voice needs to be set up first. Run setup.sh in the terminal." buttons {"OK"} default button "OK" with icon stop'
    exit 1
fi

# Activate virtual environment and run
source "\${SCRIPT_DIR}/venv/bin/activate"
cd "\${SCRIPT_DIR}"
exec python3 "\${SCRIPT_DIR}/src/main.py"
EOF

chmod +x "${APP_DIR}/Contents/MacOS/launcher"

# Create a simple icon (text-based for now)
echo "🎨 Creating app icon..."

# Create simple app icon using Python
cat > "/tmp/create_icon.py" << 'PYEOF'
from PIL import Image, ImageDraw, ImageFont
import os

# Create 1024x1024 icon
size = 1024
img = Image.new('RGBA', (size, size), (255, 59, 48, 255))
draw = ImageDraw.Draw(img)

# Draw rounded rectangle background
draw.rounded_rectangle([0, 0, size, size], radius=200, fill=(255, 59, 48, 255))

# Draw microphone emoji in center
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

# Save as .icns (macOS icon format)
iconset_dir = "/tmp/JarvisVoice.iconset"
os.makedirs(iconset_dir, exist_ok=True)

sizes = [16, 32, 64, 128, 256, 512, 1024]
for s in sizes:
    resized = img.resize((s, s), Image.Resampling.LANCZOS)
    resized.save(f"{iconset_dir}/icon_{s}x{s}.png")
    if s <= 512:
        resized2x = img.resize((s*2, s*2), Image.Resampling.LANCZOS)
        resized2x.save(f"{iconset_dir}/icon_{s}x{s}@2x.png")

os.system(f"iconutil -c icns {iconset_dir} -o /tmp/AppIcon.icns")
PYEOF

python3 /tmp/create_icon.py 2>/dev/null || echo "Note: Could not create icon (PIL not installed). App will use default icon."

# Copy icon if it was created
if [ -f "/tmp/AppIcon.icns" ]; then
    cp "/tmp/AppIcon.icns" "${APP_DIR}/Contents/Resources/AppIcon.icns"
    echo "✅ Icon created successfully!"
else
    echo "⚠️  Using default icon (install Pillow for custom icon: pip install Pillow)"
fi

echo ""
echo "✅ Jarvis Voice app bundle created!"
echo ""
echo "📍 Location: ${APP_DIR}"
echo ""
echo "To use:"
echo "   1. Find Jarvis Voice in your Applications folder"
echo "   2. Double-click to launch"
echo "   3. Grant permissions when prompted"
echo ""
echo "Or run from terminal:"
echo "   ./start.sh"
