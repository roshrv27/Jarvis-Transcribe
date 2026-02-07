#!/bin/bash

# Jarvis Voice - Complete Installer for macOS
# This script installs Jarvis Voice and all dependencies

set -e  # Exit on error

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║              🎤 JARVIS VOICE INSTALLER                     ║"
echo "║         Local Speech-to-Text for macOS                     ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
INSTALL_DIR="${HOME}/Applications/JarvisVoice"
APP_NAME="Jarvis Voice"
CONFIG_DIR="${HOME}/.jarvisvoice"
REQUIRED_NODE_VERSION="14"

# Function to print status
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

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This installer is for macOS only!"
    exit 1
fi

# Get macOS version
MACOS_VERSION=$(sw_vers -productVersion)
print_status "Detected macOS version: $MACOS_VERSION"

# Check if Homebrew is installed
print_status "Checking for Homebrew..."
if ! command -v brew &> /dev/null; then
    print_warning "Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for Apple Silicon Macs
    if [[ -d "/opt/homebrew/bin" ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    print_success "Homebrew installed!"
else
    print_success "Homebrew found!"
fi

# Install system dependencies
print_status "Installing system dependencies (this may take a few minutes)..."
brew install portaudio ffmpeg python@3.10 2>&1 | grep -v "already installed" || true
print_success "System dependencies installed!"

# Check Python version
print_status "Checking Python version..."
PYTHON_PATH=$(which python3.10 || which python3)
PYTHON_VERSION=$($PYTHON_PATH --version 2>&1 | awk '{print $2}')
print_status "Using Python $PYTHON_VERSION"

# Create installation directory
print_status "Creating installation directory..."
mkdir -p "$INSTALL_DIR"
mkdir -p "$CONFIG_DIR"
mkdir -p "$CONFIG_DIR/models"
print_success "Directories created!"

# Copy application files
print_status "Copying application files..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cp -r "$SCRIPT_DIR/src" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/requirements.txt" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/start.sh" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/README.md" "$INSTALL_DIR/"

# Create virtual environment
print_status "Creating Python virtual environment..."
cd "$INSTALL_DIR"
$PYTHON_PATH -m venv venv
source venv/bin/activate

# Upgrade pip
pip install --upgrade pip -q

# Install Python packages
print_status "Installing Python packages (this may take 5-10 minutes)..."
pip install -r requirements.txt -q

print_success "Python packages installed!"

# Download Whisper model
print_status "Downloading Whisper model (base, ~150MB)..."
python3 -c "
from faster_whisper import WhisperModel
import os
model_dir = os.path.expanduser('~/.jarvisvoice/models')
print('Downloading model to:', model_dir)
WhisperModel('base', device='cpu', compute_type='int8', download_root=model_dir)
print('Model downloaded successfully!')
" 2>&1 | tail -3

# Create default config
print_status "Creating default configuration..."
cat > "$CONFIG_DIR/config.json" << 'EOF'
{
  "hotkey": "ctrl",
  "model_size": "base",
  "language": "en",
  "typing_delay": 0.01,
  "auto_paste": true
}
EOF

print_success "Configuration created!"

# Create launch script
cat > "$INSTALL_DIR/JarvisVoice" << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
source venv/bin/activate
exec python3 src/main.py
EOF
chmod +x "$INSTALL_DIR/JarvisVoice"

# Create macOS app bundle
print_status "Creating macOS app bundle..."
APP_BUNDLE="${HOME}/Applications/${APP_NAME}.app"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Create Info.plist
cat > "$APP_BUNDLE/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>JarvisVoice</string>
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

# Create app launcher
cat > "$APP_BUNDLE/Contents/MacOS/JarvisVoice" << EOF
#!/bin/bash
cd "$INSTALL_DIR"
source venv/bin/activate
exec python3 src/main.py
EOF
chmod +x "$APP_BUNDLE/Contents/MacOS/JarvisVoice"

# Create uninstaller script
cat > "$INSTALL_DIR/uninstall.sh" << 'EOF'
#!/bin/bash
echo "Uninstalling Jarvis Voice..."
rm -rf "$HOME/Applications/Jarvis Voice.app"
rm -rf "$HOME/Applications/JarvisVoice"
echo "✅ Jarvis Voice has been uninstalled."
echo "Note: Configuration files in ~/.jarvisvoice were preserved."
echo "To remove them, run: rm -rf ~/.jarvisvoice"
EOF
chmod +x "$INSTALL_DIR/uninstall.sh"

print_success "Installation complete!"

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║              ✅ INSTALLATION SUCCESSFUL                    ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "📍 Installation Location:"
echo "   $INSTALL_DIR"
echo ""
echo "🚀 How to launch Jarvis Voice:"
echo ""
echo "   Option 1 - Menu Bar App:"
echo "   • Open Launchpad or Applications folder"
echo "   • Click 'Jarvis Voice' app"
echo ""
echo "   Option 2 - Terminal:"
echo "   cd '$INSTALL_DIR'"
echo "   ./start.sh"
echo "   or"
echo "   ./JarvisVoice"
echo ""
echo "🎮 How to use:"
echo "   1. Press and HOLD Ctrl (or your configured hotkey)"
echo "   2. Speak - you'll see a pill-shaped window appear"
echo "   3. Release Ctrl - text types automatically!"
echo ""
echo "⚙️  Configuration:"
echo "   Edit: ~/.jarvisvoice/config.json"
echo "   Change hotkey, language, or model size"
echo ""
echo "🗑️  To uninstall:"
echo "   Run: $INSTALL_DIR/uninstall.sh"
echo ""
echo "📖 Documentation:"
echo "   $INSTALL_DIR/README.md"
echo ""
echo "⚠️  IMPORTANT - First Time Setup:"
echo ""
echo "   When you first run Jarvis Voice, macOS will ask for:"
echo ""
echo "   1. 🔴 MICROPHONE ACCESS"
echo "      • Click 'OK' when prompted"
echo "      • Or go to: System Preferences → Security & Privacy → Microphone"
echo "      • Enable Jarvis Voice"
echo ""
echo "   2. 🔵 ACCESSIBILITY ACCESS (to type into other apps)"
echo "      • Go to: System Preferences → Security & Privacy → Privacy → Accessibility"
echo "      • Click the lock to make changes"
echo "      • Add and enable 'Jarvis Voice'"
echo ""
echo "   3. 🟢 SCREEN RECORDING (sometimes required)"
echo "      • May be needed to detect active window"
echo "      • Go to: System Preferences → Security & Privacy → Screen Recording"
echo "      • Add 'Jarvis Voice' if prompted"
echo ""
echo "🎯 That's it! Jarvis Voice is ready to use!"
echo ""
echo "💡 Pro Tip: The app runs in the background with a 🎤 icon in your menu bar."
echo ""

# Ask if user wants to launch now
read -p "🚀 Launch Jarvis Voice now? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    print_status "Launching Jarvis Voice..."
    open "$APP_BUNDLE"
    print_success "Jarvis Voice launched! Look for the 🎤 icon in your menu bar."
    print_warning "Remember to grant permissions when prompted!"
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "            Thank you for installing Jarvis Voice!            "
echo "═══════════════════════════════════════════════════════════════"
echo ""
