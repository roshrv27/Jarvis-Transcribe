#!/bin/bash

# Jarvis Voice Setup Script for macOS

echo "🎤 Setting up Jarvis Voice..."

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "❌ Homebrew not found. Please install Homebrew first:"
    echo "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    exit 1
fi

# Check Python version
PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
echo "📍 Found Python $PYTHON_VERSION"

# Install required system dependencies
echo "📦 Installing system dependencies..."
brew install portaudio ffmpeg || true

# Create virtual environment
echo "🐍 Creating virtual environment..."
cd "$(dirname "$0")"
python3 -m venv venv
source venv/bin/activate

# Upgrade pip
echo "⬆️  Upgrading pip..."
pip install --upgrade pip

# Install Python dependencies
echo "📥 Installing Python packages..."
pip install -r requirements.txt

# Download Whisper model
echo "🤖 Downloading Whisper model (this may take a while)..."
python3 -c "from faster_whisper import WhisperModel; WhisperModel('base', device='cpu', compute_type='int8', download_root='models')"

# Make main.py executable
chmod +x src/main.py

echo ""
echo "✅ Setup complete!"
echo ""
echo "To start Jarvis Voice:"
echo "   ./start.sh"
echo ""
echo "Or manually:"
echo "   source venv/bin/activate && python src/main.py"
echo ""
echo "💡 Press Fn key to start/stop recording"
