#!/bin/bash

echo "🔍 JARVIS VOICE DIAGNOSTIC TOOL"
echo "================================"
echo ""

# Check if Jarvis Voice is running
if pgrep -f "src/main.py" > /dev/null; then
    echo "✅ Jarvis Voice process is running"
    PID=$(pgrep -f "src/main.py" | head -1)
    echo "   Process ID: $PID"
else
    echo "❌ Jarvis Voice is NOT running"
    echo "   Please start it first: ~/Applications/JarvisVoice/start.sh"
    exit 1
fi

echo ""
echo "📋 Checking Permissions:"
echo "------------------------"

# Check accessibility permissions
echo "1. Accessibility permissions:"
ACCESSIBILITY=$(sqlite3 ~/Library/Application\ Support/com.apple.TCC/TCC.db "SELECT client FROM access WHERE service='kTCCServiceAccessibility' AND auth_value=2" 2>/dev/null | grep -i "python\|terminal" || echo "None found")
if [ "$ACCESSIBILITY" != "None found" ]; then
    echo "   ✅ Python/Terminal has accessibility permission"
else
    echo "   ❌ Python/Terminal missing accessibility permission"
fi

echo ""
echo "2. Notification permissions:"
NOTIFICATIONS=$(defaults read ~/Library/Containers/com.apple.notificationcenterui/Data/Library/Preferences/com.apple.notificationcenterui.plist 2>/dev/null | grep -i jarvis || echo "Not configured")
if [ "$NOTIFICATIONS" != "Not configured" ]; then
    echo "   ✅ Notifications configured"
else
    echo "   ⚠️  Notifications not configured (this is OK)"
fi

echo ""
echo "🧪 Testing Components:"
echo "---------------------"

cd ~/Applications/JarvisVoice
source venv/bin/activate

echo "3. Testing keyboard listener..."
python3 -c "
from pynput import keyboard
import time

def on_press(key):
    print(f'Key pressed: {key}')
    return False  # Stop after first key

print('Press any key to test (you have 5 seconds)...')
listener = keyboard.Listener(on_press=on_press)
listener.start()
listener.join(timeout=5)
if listener.is_alive():
    listener.stop()
    print('❌ No key detected in 5 seconds')
else:
    print('✅ Keyboard listener is working!')
"

echo ""
echo "4. Testing microphone access..."
python3 -c "
import sounddevice as sd
import numpy as np

try:
    devices = sd.query_devices()
    input_devices = [d for d in devices if d['max_input_channels'] > 0]
    if input_devices:
        print(f'✅ Found {len(input_devices)} input device(s):')
        for d in input_devices:
            print(f'   - {d[\"name\"]}')
    else:
        print('❌ No input devices found')
except Exception as e:
    print(f'❌ Error: {e}')
"

echo ""
echo "5. Testing Whisper model..."
python3 -c "
from faster_whisper import WhisperModel
import os

try:
    model_dir = os.path.expanduser('~/.jarvisvoice/models')
    print('Loading Whisper model (this may take a moment)...')
    model = WhisperModel('base', device='cpu', compute_type='int8', download_root=model_dir)
    print('✅ Whisper model loaded successfully!')
except Exception as e:
    print(f'❌ Error loading model: {e}')
"

echo ""
echo "📱 Quick Hotkey Test:"
echo "--------------------"
echo "Press and release the Ctrl key to test..."
python3 -c "
from pynput import keyboard
import time

count = [0]

def on_press(key):
    if key == keyboard.Key.ctrl or (hasattr(key, 'name') and key.name == 'ctrl'):
        count[0] += 1
        print(f'✅ Ctrl key detected! (press #{count[0]})')
    else:
        print(f'Key: {key}')

def on_release(key):
    if key == keyboard.Key.ctrl or (hasattr(key, 'name') and key.name == 'ctrl'):
        print('✅ Ctrl key released!')

print('Listening for Ctrl key for 10 seconds...')
listener = keyboard.Listener(on_press=on_press, on_release=on_release)
listener.start()
time.sleep(10)
listener.stop()

if count[0] == 0:
    print('❌ No Ctrl key detected in 10 seconds')
    print('   This means the hotkey listener is not working!')
else:
    print(f'✅ Detected Ctrl key {count[0]} time(s)')
"

echo ""
echo "================================"
echo "Diagnostic complete!"
echo ""
echo "If keyboard listener is not working:"
echo "1. Grant accessibility permission to Python again"
echo "2. Restart your Mac and try again"
echo "3. Or use Option 2: Terminal permission instead"
