# Jarvis Voice - Standalone DMG Builder

This script creates a fully self-contained DMG file that includes:
- Embedded Python interpreter
- All Python dependencies (rumps, sounddevice, numpy, pynput)
- Whisper.cpp speech recognition model
- Application source code
- Custom app icon

## Prerequisites

Before running the build script, ensure you have:

1. **Homebrew** installed (https://brew.sh)
2. **create-dmg** tool:
   ```bash
   brew install create-dmg
   ```
3. **Python 3.8+** with pip
4. **Logo file** (optional but recommended):
   - Place your logo as `logo.png` or `logo.jpg` in the JarvisVoice directory
   - Or place it in `assets/logo.png`
   - If not provided, a default microphone icon will be used

## Building the DMG

1. Navigate to the JarvisVoice directory:
   ```bash
   cd /Users/rv/Applications/JarvisVoice
   ```

2. Run the build script:
   ```bash
   ./build-standalone-dmg.sh
   ```

3. The script will:
   - Create an app icon from your logo (or use default)
   - Set up embedded Python environment
   - Install all dependencies
   - Download Whisper model (if not present)
   - Create the app bundle
   - Build the DMG file

4. **Output**: `JarvisVoice-1.3-Standalone.dmg` in the current directory

## DMG Contents

The generated DMG contains:
- **JarvisVoice.app** - The complete application
- **Applications** shortcut - Drag the app here to install

## Installation for End Users

Users just need to:
1. Double-click the DMG file
2. Drag "Jarvis Voice" to the Applications folder
3. Launch from Applications
4. Grant permissions (Microphone & Accessibility) when prompted

## What's Included

The standalone app includes:
- ✅ Embedded Python 3.10+
- ✅ All Python packages (rumps, sounddevice, numpy, pynput)
- ✅ Whisper.cpp base model for speech recognition
- ✅ Custom app icon
- ✅ Code-signed (ad-hoc, may show security warning on first launch)

## Troubleshooting

### "App can't be opened" security warning

If users see a security warning:
1. Right-click on Jarvis Voice app
2. Select "Open"
3. Click "Open" in the dialog

Or go to System Settings → Privacy & Security → Security and click "Open Anyway"

### Missing Whisper model

If the model download fails during build:
1. Manually download from: https://huggingface.co/ggerganov/whisper.cpp
2. Place `ggml-base.en.bin` in `whisper.cpp/models/`
3. Re-run the build script

### Build fails

Check:
- Python 3 is installed: `python3 --version`
- pip is working: `python3 -m pip --version`
- Sufficient disk space (needs ~500MB)

## File Size

The final DMG is approximately:
- **200-300 MB** with embedded Python and model
- This is normal for standalone Python apps

## Distribution

The generated DMG can be:
- Shared via email (if under 25MB)
- Uploaded to cloud storage (Google Drive, Dropbox)
- Distributed via your website
- Shared through any file sharing service

## Notes

- The app is code-signed with an ad-hoc signature (no developer certificate required)
- First launch may show security warning (normal for unsigned apps)
- App requires macOS 10.15 (Catalina) or later
- Tested on macOS 10.15, 11, 12, 13, 14, and 15
