# 🎤 Jarvis Voice

A fast, local speech-to-text app for macOS that types directly into any application using your voice.

## ✨ Features

- 🎙️ **Voice to Text** - Speak naturally, text appears instantly
- ⚡ **Fast & Local** - Uses Whisper AI locally (no internet needed)
- 🎯 **Right Option Key** - Press and hold RIGHT OPTION (⌥) to activate
- ⌨️ **Types Anywhere** - Works in any app (chat, documents, browser, etc.)
- 🔒 **100% Private** - All processing happens on your Mac
- 🎨 **Minimal UI** - Clean pill-shaped window shows recording status

## 🚀 Installation

### Prerequisites
- macOS 10.15 (Catalina) or later
- ~200MB disk space

### Install (3 Steps)

1. **Clone the repository**
   ```bash
   git clone https://github.com/roshrv27/Jarvis-Transcribe.git
   cd Jarvis-Transcribe
   ```

2. **Run the installer**
   ```bash
   ./install.sh
   ```
   This will install dependencies and download the Whisper AI model (~150MB).

3. **Grant permissions** (System Preferences → Privacy & Security)
   - **Microphone** - To hear your voice
   - **Accessibility** - To type into other apps

## 🎮 Usage

### Launch
```bash
~/Applications/JarvisVoice/start.sh
```

Or create an alias:
```bash
echo 'alias jarvis="~/Applications/JarvisVoice/start.sh"' >> ~/.zshrc
source ~/.zshrc
# Then just type: jarvis
```

### How to Use
1. Click where you want text to appear
2. **Press and hold RIGHT OPTION key** (⌥ on the right side)
3. **Speak** - red pill window appears
4. **Release RIGHT OPTION** - text appears automatically!

## ⚙️ Configuration

Edit `~/.jarvisvoice/config.json`:
```json
{
  "hotkey": "alt_r",          // Right Option key (hardcoded)
  "model_size": "base",       // Options: tiny, base, small, medium, large-v3
  "language": "en",           // Language code (en, es, fr, de, etc.)
  "auto_paste": true,         // Auto-add space after text
  "typing_delay": 0.01        // Delay before typing
}
```

### Available Models
| Model | Size | Speed | Accuracy |
|-------|------|-------|----------|
| tiny | ~39MB | ⚡ Fastest | Basic |
| base | ~150MB | ⚡ Fast | Good ✅ (default) |
| small | ~466MB | 🐢 Slower | Better |
| medium | ~1.5GB | 🐢 Slow | High |
| large-v3 | ~3GB | 🐌 Slowest | Best |

## 🛠️ Troubleshooting

**Text not appearing?**
- Grant Accessibility & Microphone permissions in System Preferences
- Launch from Terminal (not Spotlight)

**App won't start?**
- Run installer again: `./install.sh`
- Check permissions in System Preferences → Security & Privacy

**First run slow?**
- Model downloads automatically (~150MB). Be patient!

## 📁 File Structure

```
jarvis-voice/
├── install.sh          # Main installer
├── start.sh            # Launch script
├── requirements.txt    # Python dependencies
├── src/main.py         # Main application
└── README.md           # This file
```

## 📄 License

MIT License - Free to use and modify!

---

**Made with ❤️ for fast voice typing on macOS**
