#!/bin/bash

# Jarvis Voice Launcher with proper setup
echo "🎤 Starting Jarvis Voice..."

# Change to app directory
cd "/Users/rv/Applications/JarvisVoice"

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "❌ Virtual environment not found!"
    echo "Please run ./install.sh first"
    exit 1
fi

# Activate virtual environment
source venv/bin/activate

# Hide Python from dock by setting environment variable
export PYTHONDONTWRITEBYTECODE=1

# For macOS: hide dock icon when running from terminal
# This is a workaround until LSUIElement takes effect
if command -v /usr/bin/osascript &> /dev/null; then
    # Try to hide the Terminal/ Python from dock
    /usr/bin/osascript -e 'tell application "System Events" to set visible of application process "Python" to false' 2>/dev/null || true
fi

# Launch the app with unbuffered output for debugging
exec python3 -u src/main.py
