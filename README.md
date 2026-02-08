# 🎤 Jarvis Voice

A fast, local speech-to-text app for macOS that types directly into any application.

## ✨ Features

- 🎙️ **Voice to Text** - Speak naturally, text appears instantly
- ⚡ **Fast & Local** - Uses Whisper AI locally (no internet needed)
- 🎯 **Smart Hotkey** - Press and hold RIGHT OPTION key to activate
- ⌨️ **Types Anywhere** - Works in any app (chat, documents, browser, etc.)
- 🔒 **100% Private** - All processing happens on your Mac
- 🎨 **Minimal UI** - Clean pill-shaped window shows status

## 🚀 Quick Start

### Installation (3 Steps)

1. **Download the repository**
   ```bash
   git clone <repository-url>
   cd jarvis-voice
   ```

2. **Run the installer**
   ```bash
   ./install.sh
   ```
   This will:
   - Install required dependencies (Homebrew, Python packages)
   - Download the Whisper AI model (~150MB)
   - Set up the app

3. **Grant permissions** (macOS will ask)
   - **Microphone** - To hear your voice
   - **Accessibility** - To type into other apps
   
   Go to: System Preferences → Privacy & Security → Grant access

### Usage

**Launch from Terminal:**
```bash
~/Applications/JarvisVoice/start.sh
```

**Or create an alias for easy access:**
```bash
echo 'alias jarvis-transcribe="~/Applications/JarvisVoice/start.sh"' >> ~/.zshrc
source ~/.zshrc
# Then just type: jarvis-transcribe
```

**How to use:**
1. Click where you want text to appear
2. **Press and hold RIGHT OPTION key** (⌥ on the right side of keyboard)
3. **Speak** - red pill window appears
4. **Release RIGHT OPTION** - text appears automatically!

## ⚙️ Configuration

Edit settings in `~/.jarvisvoice/config.json`:

```json
{
  "hotkey": "alt_r",          // Right Option key (hardcoded in this version)
  "model_size": "base",       // Options: "tiny", "base", "small", "medium", "large-v3"
  "language": "en",           // Language code (en, es, fr, de, etc.)
  "auto_paste": true,         // Auto-add space after text
  "typing_delay": 0.01        // Delay before typing (seconds)
}
```

### Hotkey Configuration

**Right OPTION Key** (default)
- Press and hold the RIGHT OPTION key (⌥ on right side)
- Speak while holding
- Release to transcribe

**Note:** This version is configured to use the RIGHT OPTION key specifically for better control. The left Option key is intentionally ignored to avoid conflicts with system shortcuts.

### Available Models

| Model | Size | Speed | Accuracy |
|-------|------|-------|----------|
| tiny | ~39MB | ⚡ Fastest | Basic |
| base | ~150MB | ⚡ Fast | Good ✅ (default) |
| small | ~466MB | 🐢 Slower | Better |
| medium | ~1.5GB | 🐢 Slow | High |
| large-v3 | ~3GB | 🐌 Slowest | Best |

**Recommendation:** Use `base` for best speed/accuracy balance

## 🛠️ Troubleshooting

### "Text not appearing"
- Grant **Accessibility** permission in System Preferences
- Grant **Microphone** permission in System Preferences
- Launch from Terminal, not Spotlight

### "App only works from Terminal"
This is expected! macOS security requires Terminal permissions. Always launch via:
```bash
~/Applications/JarvisVoice/start.sh
```

### "Permission denied" errors
Run the installer again:
```bash
./install.sh
```

### "Model not loading"
The model will download automatically on first run (~150MB). Be patient!

## 📁 File Structure

```
jarvis-voice/
├── install.sh          # Main installer
├── start.sh            # Quick launcher
├── requirements.txt    # Python dependencies
├── src/
│   └── main.py         # Main application
├── README.md           # This file
└── demo.py             # Demo to test UI
```

## 🔧 Requirements

- macOS 10.15 (Catalina) or later
- Python 3.10+ (installed automatically)
- Microphone access
- ~200MB disk space (for app + model)

## 📝 Notes

- **Always launch from Terminal** for best results
- First run may take 1-2 minutes to download the AI model
- The app runs in the background with a 🎤 icon in the menu bar
- Supports 99 languages (change in config)

## 🤝 Support

If you encounter issues:
1. Check permissions in System Preferences
2. Restart the app: `pkill -f src/main.py && ~/Applications/JarvisVoice/start.sh`
3. Re-run installer: `./install.sh`

## 📄 License

MIT License - Free to use and modify!

---

**Made with ❤️ for fast voice typing on macOS**
