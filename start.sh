#!/bin/bash

# Jarvis Voice Launcher

cd "$(dirname "$0")"

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "❌ Virtual environment not found. Running setup first..."
    ./setup.sh
fi

# Activate virtual environment
source venv/bin/activate

# Start the app
echo "🎤 Starting Jarvis Voice..."
echo "   Press Fn key to start/stop recording"
echo ""

python3 src/main.py
