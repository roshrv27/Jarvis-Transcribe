# 🎤 JARVIS VOICE - INSTALLATION PACKAGE

## 📦 What's Included

This package contains everything you need to install and run Jarvis Voice on your Mac.

### 📁 Files in this package:

1. **📱 Jarvis Voice App** (automatically created)
   - Location: `~/Applications/Jarvis Voice.app`
   - Double-click to launch from Applications folder

2. **📂 Installation Folder**
   - Location: `~/Applications/JarvisVoice/`
   - Contains all app files, Python environment, and models

3. **🔧 Key Scripts:**
   - `install.sh` - Full installer with setup
   - `quick-install.sh` - Quick installer for reinstallation
   - `start.sh` - Launch from terminal
   - `uninstall.sh` - Remove Jarvis Voice

## 🚀 How to Install

### Option 1: Run Installer (Recommended)
```bash
cd "/path/to/this/folder"
./install.sh
```

### Option 2: Quick Install
```bash
cd "/path/to/this/folder"
./quick-install.sh
```

### Option 3: Drag to Applications
- Copy the `Jarvis Voice.app` from your Applications folder to any Mac
- Double-click to run

## 🎮 How to Use

1. **Launch Jarvis Voice**
   - From Applications folder: Double-click "Jarvis Voice"
   - From terminal: `~/Applications/JarvisVoice/start.sh`

2. **First Time Setup** (IMPORTANT!)
   - macOS will ask for **Microphone Access** → Click "OK"
   - macOS will ask for **Accessibility Access** → Go to System Preferences and enable it

3. **Using Jarvis Voice**
   - Press and **HOLD** the RIGHT Option key (⌥ on right side)
   - Speak naturally
   - Release RIGHT Option key
   - Text appears automatically in your active app!

## ⚙️ Configuration

Edit config file:
```bash
open ~/.jarvisvoice/config.json
```

Change settings:
- `hotkey`: "alt_r" (Right Option key - hardcoded in this version)
- `model_size`: "tiny", "base", "small", "medium", "large-v3"
- `language`: "en", "es", "fr", "de", "hi", etc. (99 languages supported!)

Note: This version uses the RIGHT Option key exclusively to avoid conflicts
with system shortcuts and provide better control.

## 🎯 Features

✅ **Local Processing** - Works offline, no internet needed  
✅ **99 Languages** - Supports almost all major languages  
✅ **Auto-Type** - Types directly into any app  
✅ **Pill-Shaped UI** - Minimal, elegant floating window  
✅ **Menu Bar** - Easy access from menu bar  

## 🔐 Required Permissions

Grant these in System Preferences → Security & Privacy:

1. ✅ **Microphone** - To hear your voice
2. ✅ **Accessibility** - To type into other apps
3. ✅ **Screen Recording** - (Sometimes needed) To detect active window

## 🗑️ How to Uninstall

```bash
~/Applications/JarvisVoice/uninstall.sh
```

Or manually delete:
- `~/Applications/Jarvis Voice.app`
- `~/Applications/JarvisVoice/`
- `~/.jarvisvoice/` (config files)

## 🆘 Troubleshooting

**App won't launch?**
- Check System Preferences → Security & Privacy → General
- Click "Open Anyway" if you see a warning

**No sound detected?**
- Check Microphone permissions in System Preferences
- Make sure your microphone is working

**Text not typing?**
- Grant Accessibility permission in System Preferences
- Try restarting the app after granting permissions

**Model loading slowly?**
- First run downloads ~150MB Whisper model
- Be patient, it only happens once

## 📞 Support

- **Config location**: `~/.jarvisvoice/config.json`
- **Models location**: `~/.jarvisvoice/models/`
- **Logs**: Check terminal output when running from command line

## 🎉 Enjoy Jarvis Voice!

Your personal speech-to-text assistant is ready to use!

Press and hold RIGHT Option key and speak to see the magic happen! 🎤✨
