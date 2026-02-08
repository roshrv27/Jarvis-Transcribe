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
- Python 3.10+ (will be installed if not present)
- ~800MB disk space (for app + distil-large-v3 model)
- Terminal access
- Internet connection (for model download)

### Install from GitHub (3 Steps)

1. **Clone the repository**
   ```bash
   git clone https://github.com/roshrv27/Jarvis-Transcribe.git
   cd Jarvis-Transcribe
   ```

2. **Run the installer**
   ```bash
   ./install.sh
   ```
   
   The installer will:
   - Check/install Homebrew (if needed)
   - Install Python 3.10 (if needed)
   - Install Python dependencies
   - Download Whisper AI model (~150MB)
   - Set up the application
   
   ⏱️ **First install takes 5-10 minutes** (downloads model)

3. **Grant permissions** ⚠️ **IMPORTANT**

   After installation, macOS will ask for permissions. You MUST grant these:
   
   **A. Microphone Access**
   - System Preferences → Privacy & Security → Microphone
   - Enable **Terminal** (or Python)
   
   **B. Accessibility Access** (Required for typing)
   - System Preferences → Privacy & Security → Accessibility
   - Click **+** button
   - Navigate to: `/Library/Frameworks/Python.framework/Versions/3.10/bin/`
   - Select **python3.10**
   - Enable the checkbox ✅
   
   **C. (Optional) Screen Recording**
   - Some macOS versions may require this for window detection

## 🎮 Usage

### Launch the App
```bash
~/Applications/JarvisVoice/start.sh
```

**Or create an alias for easy access:**
```bash
echo 'alias jarvis="~/Applications/JarvisVoice/start.sh"' >> ~/.zshrc
source ~/.zshrc
# Then just type: jarvis
```

### How to Use
1. Click where you want text to appear
2. **Press and hold RIGHT OPTION key** (⌥ on the right side of keyboard)
3. **Speak** - red pill window appears at the top
4. **Release RIGHT OPTION** - text appears automatically!

### Tips
- The app runs in the background with a 🎤 icon in the menu bar
- Right-click the 🎤 icon for settings
- Always launch from Terminal, not Spotlight
- First transcription may take a few seconds (model warmup)

## ⚙️ Configuration

Edit `~/.jarvisvoice/config.json`:
```json
{
  "hotkey": "alt_r",          // Right Option key (hardcoded)
  "model_size": "distil-large-v3",  // Default: 6x faster than base, minimal quality loss
  "language": "en",           // Language code (en, es, fr, de, etc.)
  "auto_paste": true,         // Auto-add space after text
  "typing_delay": 0.01        // Delay before typing
}
```

**Model Options:**
- `distil-large-v3` (Default) - 6x faster than base, ~756MB, excellent quality
- `distil-small.en` - Ultra fast, ~166MB, good for resource-constrained devices
- `base` - Original model, ~150MB, good baseline
- `tiny` - Fastest, ~39MB, basic quality

**Note:** Changing the hotkey requires editing `src/main.py` and restarting the app.

### Available Models

| Model | Size | Speed | Accuracy | Best For |
|-------|------|-------|----------|----------|
| **distil-large-v3** | ~756MB | ⚡⚡ 6x faster | Excellent ✅ | **Default** - Best speed/quality balance |
| distil-small.en | ~166MB | ⚡⚡⚡ 8x faster | Good | Resource-constrained devices |
| base | ~150MB | ⚡ Fast | Good | Good baseline |
| tiny | ~39MB | ⚡⚡⚡ Fastest | Basic | Testing only |

**Why Distil-Whisper?**
- **6x faster** than standard Whisper
- **49% smaller** than full Whisper Large
- Only **1% word error rate** difference vs full model
- Perfect for real-time transcription

**Note:** First run will download ~756MB model (distil-large-v3). This takes 2-3 minutes depending on internet speed.

## 🛠️ Troubleshooting

### "Text not appearing in the right window"
- Make sure you **click where you want text** BEFORE pressing Right Option
- Grant **Accessibility** permission (see Installation Step 3)
- The app types to whichever window was last clicked

### "No sound detected"
- Grant **Microphone** permission (see Installation Step 3)
- Check your microphone is working in System Preferences
- Speak louder or closer to the microphone

### "App won't start"
```bash
# Try running the installer again
./install.sh

# Or check Python is installed correctly
/Library/Frameworks/Python.framework/Versions/3.10/bin/python3 --version
```

### "Permission denied" errors
```bash
# Make scripts executable
chmod +x install.sh start.sh
./install.sh
```

### "Model loading slowly"
- **Normal on first run!** Downloads ~150MB Whisper model
- Wait 1-2 minutes, it only happens once
- Check internet connection

### "This process is not trusted" error
- You missed Step 3 (Grant Accessibility permission)
- Go to System Preferences → Privacy & Security → Accessibility
- Add Python 3.10 as described above

### "Red pill not appearing"
- Check the app is running: Look for 🎤 in menu bar
- Try clicking on a text field first
- Press **Right Option key** (not Left Option)

## 🔄 Reinstalling

To start fresh:
```bash
# Remove old installation
rm -rf ~/Applications/JarvisVoice
rm -rf ~/.jarvisvoice

# Reinstall
cd Jarvis-Transcribe
./install.sh
```

## 📁 File Structure

```
jarvis-voice/
├── install.sh          # Main installer
├── start.sh            # Launch script  
├── requirements.txt    # Python dependencies
├── src/
│   └── main.py         # Main application
├── README.md           # This file
└── .git/               # Git repository
```

## 🔧 System Requirements

- **OS:** macOS 10.15+ (Catalina, Big Sur, Monterey, Ventura, Sonoma)
- **RAM:** 4GB minimum, 8GB recommended
- **Storage:** ~200MB for app + model
- **Internet:** Only needed for first install (model download)

## 📄 License

MIT License - Free to use and modify!

---

**Made with ❤️ for fast voice typing on macOS**

**Quick Links:**
- GitHub: https://github.com/roshrv27/Jarvis-Transcribe
- Issues: Report problems on GitHub Issues
