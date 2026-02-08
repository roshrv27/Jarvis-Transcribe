#!/bin/bash

# Jarvis Voice Launcher

cd "$(dirname "$0")"

# Start the app using system Python
echo "🎤 Starting Jarvis Voice..."
echo "   Press and hold RIGHT Option key to record"
echo ""

/Library/Frameworks/Python.framework/Versions/3.10/bin/python3 -u src/main.py
