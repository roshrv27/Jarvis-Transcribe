# 🎤 Jarvis Voice - DMG Distribution Guide

This guide explains how to create a distributable DMG file for Jarvis Voice that users can install by dragging to Applications.

## 📋 Prerequisites

Before building the DMG:

1. **macOS** (10.15 or later)
2. **Homebrew** installed (https://brew.sh)
3. **create-dmg** tool:
   ```bash
   brew install create-dmg
   ```
4. **Python 3.8+** with pip
5. **Logo file** (optional but recommended):
   - Place your logo as `logo.png` or `logo.jpg` in this directory
   - Or in `assets/logo.png`

## 🚀 Quick Start (Recommended)

Use the simple DMG builder that installs dependencies on first run:

```bash
cd /Users/rv/Applications/JarvisVoice
./create-dmg.sh
```

**What it does:**
- Creates app bundle with your logo
- Includes Whisper model
- Sets up automatic dependency installation
- Creates professional-looking DMG

**Output:** `JarvisVoice-1.3.dmg` (~100-200MB depending on model)

## 📦 Build Options

We provide **three** different build approaches:

### Option 1: Simple DMG (Recommended) ⭐
**File:** `create-dmg.sh`

**Best for:** Quick distribution, smaller file size

**How it works:**
- Creates app bundle
- Includes Whisper model
- Installs Python dependencies on first launch
- File size: ~100-200MB

**Pros:**
- ✅ Smaller file size
- ✅ Faster build time
- ✅ Automatically downloads missing models
- ✅ Easy to update dependencies

**Cons:**
- ⚠️ Requires internet on first run (~50MB download)
- ⚠️ Slight delay on first launch

**Usage:**
```bash
./create-dmg.sh
```

---

### Option 2: Fully Standalone DMG
**File:** `build-standalone-dmg.sh`

**Best for:** Complete offline installation, no internet required

**How it works:**
- Embeds entire Python interpreter
- Includes all dependencies
- Includes Whisper model
- File size: ~300-500MB

**Pros:**
- ✅ Works completely offline
- ✅ No internet required ever
- ✅ Consistent environment

**Cons:**
- ⚠️ Large file size (300-500MB)
- ⚠️ Slower build time
- ⚠️ Harder to update

**Usage:**
```bash
./build-standalone-dmg.sh
```

---

### Option 3: Py2app Build (Advanced)
**File:** `setup.py`

**Best for:** Developers, maximum optimization

**How it works:**
- Uses py2app to convert Python to native app
- Most optimized binary
- File size: ~150-250MB

**Prerequisites:**
```bash
pip3 install py2app
```

**Usage:**
```bash
python3 setup.py py2app
# Creates dist/JarvisVoice.app
# Then manually create DMG or use create-dmg
```

**Pros:**
- ✅ Most optimized
- ✅ Native macOS app
- ✅ Professional result

**Cons:**
- ⚠️ Requires py2app knowledge
- ⚠️ Complex troubleshooting
- ⚠️ Manual DMG creation needed

---

## 📥 Installation for End Users

The DMG is designed to be user-friendly:

### Step 1: Download DMG
Users download `JarvisVoice-1.3.dmg`

### Step 2: Open DMG
Double-click to mount the disk image

### Step 3: Install
Drag "Jarvis Voice" to the Applications folder shortcut

### Step 4: Launch
1. Open Applications folder
2. Double-click Jarvis Voice
3. **First time only:** Grant permissions
   - Click "Open" if security warning appears
   - Grant Microphone access
   - Grant Accessibility access

### Step 5: Use
Press and hold **Right Option key** to record

---

## 🔧 Troubleshooting

### "App can't be opened" Security Warning

**Solution 1:** Right-click → Open → Click "Open"

**Solution 2:**
1. System Settings → Privacy & Security
2. Scroll to "Security" section
3. Click "Open Anyway" next to Jarvis Voice

**Solution 3 (Advanced):**
```bash
xattr -dr com.apple.quarantine /Applications/JarvisVoice.app
```

### Missing Whisper Model

If the app shows "model not found":

1. Download manually:
   ```bash
   curl -L -o ggml-base.en.bin \
     "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin"
   ```

2. Place in:
   - For Simple DMG: `~/.jarvisvoice/models/`
   - For Standalone: `JarvisVoice.app/Contents/Resources/models/`

### First Run Setup Issues

If dependencies fail to install:

```bash
# Manual setup
mkdir -p ~/.jarvisvoice
python3 -m venv ~/.jarvisvoice/venv
source ~/.jarvisvoice/venv/bin/activate
pip install rumps sounddevice numpy pynput
```

---

## 📊 Comparison Table

| Feature | Simple DMG | Standalone | Py2app |
|---------|-----------|------------|---------|
| File Size | ~150MB | ~400MB | ~200MB |
| Build Time | 2 min | 10 min | 5 min |
| Internet Required | First run only | Never | Never |
| Update Difficulty | Easy | Hard | Medium |
| Offline Use | After first run | Always | Always |
| Recommended | ⭐⭐⭐ | ⭐⭐ | ⭐⭐ |

---

## 🎨 Customization

### Change App Icon

Place your logo in the JarvisVoice directory:
- `logo.png` (recommended)
- `logo.jpg`
- `assets/logo.png`

The build script will automatically convert it to macOS icon format.

### Change App Name

Edit the build scripts and change:
```bash
APP_NAME="Jarvis Voice"  # Change this
APP_BUNDLE_NAME="JarvisVoice"  # And this
```

### Change Version

Update version in all files:
- `create-dmg.sh`: `VERSION="1.3"`
- `build-standalone-dmg.sh`: `VERSION="1.3"`
- `setup.py`: `VERSION = '1.3'`

---

## 📤 Distribution

Once you have the DMG, you can distribute it via:

- **Email** (if under 25MB)
- **Google Drive / Dropbox** (share link)
- **Website download**
- **GitHub Releases**

### GitHub Release Example

1. Go to GitHub repository
2. Click "Releases" → "Create new release"
3. Upload `JarvisVoice-1.3.dmg`
4. Add release notes
5. Publish

---

## 🔒 Security Notes

- DMG is code-signed with ad-hoc signature
- First launch shows security warning (normal for unsigned apps)
- App requests microphone and accessibility permissions
- All code is open source and auditable

---

## 💡 Tips

1. **Test the DMG** on a clean macOS installation before distributing
2. **Include clear instructions** for first-time users
3. **Mention system requirements** (macOS 10.15+, microphone, accessibility)
4. **Provide support contact** for users who get stuck

---

## 🆘 Support

If you encounter issues:

1. Check terminal output for error messages
2. Verify all prerequisites are installed
3. Try a different build option
4. Check the logs in the build directory

---

**Ready to build?** Start with the Simple DMG:
```bash
./create-dmg.sh
```
