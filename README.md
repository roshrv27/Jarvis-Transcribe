# 🎤 Jarvis Voice

A blazing-fast, local speech-to-text app for macOS that uses **whisper.cpp with Metal GPU acceleration** to type directly into any application.

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     JARVIS VOICE ARCHITECTURE                    │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  USER INTERFACE LAYER (Python + Qt6 + rumps)                    │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────────────┐   │
│  │   Menu Bar  │  │ Floating UI  │  │  Audio Recorder      │   │
│  │   (🎤 Icon) │  │ (Red Pill)   │  │  (sounddevice)       │   │
│  └──────┬──────┘  └──────┬───────┘  └──────────┬───────────┘   │
│         │                │                     │               │
│         └────────────────┴─────────────────────┘               │
│                         │                                      │
│         Right Option Key Press Detection (pynput)              │
└─────────────────────────┬──────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│  BRIDGE LAYER (Python Wrapper)                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │           whisper_cpp_wrapper.py                            │ │
│  │  • Converts numpy audio → WAV format                        │ │
│  • Validates language codes (security)                        │ │
│  • Manages temporary files                                     │ │
│  • Calls whisper-cli subprocess                                │ │
│  └────────────────────────┬────────────────────────────────────┘ │
└───────────────────────────┼──────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│  CORE ENGINE (C++ whisper.cpp with Metal)                       │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  WHISPER.CPP (OpenAI Whisper in C++)                        │ │
│  │  ┌─────────────────┐  ┌──────────────────┐  ┌──────────┐  │ │
│  │  │  Audio Encoder  │→│  Text Decoder    │→│  Output  │  │ │
│  │  │  (Metal GPU)    │  │  (Transformer)   │  │  Text    │  │ │
│  │  └─────────────────┘  └──────────────────┘  └──────────┘  │ │
│  │                                                              │ │
│  │  Model: ggml-base.en.bin (~141MB)                           │ │
│  │  • 512-dimensional embeddings                               │ │
│  │  • 6 encoder layers                                         │ │
│  │  • 6 decoder layers                                         │ │
│  │  • Optimized for Apple Silicon                              │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│  HARDWARE ACCELERATION (Apple Silicon)                          │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  APPLE M1/M2 GPU (Metal Framework)                          │ │
│  │  • SIMD vector operations                                   │ │
│  │  • Unified memory architecture                              │ │
│  │  • 3-4x faster than CPU-only inference                      │ │
│  │  • Zero memory copies (GPU ↔ CPU)                           │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## ⚡ Performance Benchmark

| Component | Python (faster-whisper) | C++ (whisper.cpp + Metal) | Improvement |
|-----------|------------------------|---------------------------|-------------|
| **Load Time** | ~3s | ~0.12s | **25x faster** |
| **Transcription** | ~5s | ~1.75s | **3x faster** |
| **Memory Usage** | ~400MB | ~150MB | **2.7x less** |
| **CPU Usage** | High | Low (GPU offload) | **Much cooler** |

**Real-world test:** 11 seconds of speech transcribed in **1.75 seconds** on Apple M1!

## ✨ Features

- 🚀 **C++ Performance** - whisper.cpp runs 3-4x faster than Python
- 🎮 **Metal GPU Acceleration** - Uses Apple M1/M2 GPU for inference
- 🎯 **Right Option Key** - Press and hold RIGHT OPTION (⌥) to activate
- ⌨️ **Types Anywhere** - Works in any app (chat, documents, browser, etc.)
- 🔒 **100% Private** - All processing happens locally on your Mac
- 🎨 **Minimal UI** - Clean pill-shaped floating window
- 📝 **Auto-Corrections** - Teach the app your words (add/view/delete)
- ⚡ **Real-time** - Sub-2-second transcription for short phrases

## 🔧 Technology Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Frontend** | Python 3.10 + rumps + PyQt6 | Menu bar, floating UI, audio recording |
| **Bridge** | whisper_cpp_wrapper.py | Python-to-C++ interface |
| **Core** | whisper.cpp (C++17) | Whisper model inference |
| **GPU** | Metal (Apple framework) | Hardware acceleration |
| **Audio** | sounddevice | Real-time audio capture |
| **Model** | ggml-base.en.bin | OpenAI Whisper base model |

## 🚀 Installation

### Prerequisites
- macOS 10.15+ (Catalina or later)
- Apple Silicon Mac (M1/M2/M3) for Metal acceleration
- ~500MB disk space
- Internet connection (for model download)

### Quick Install (3 Steps)

1. **Clone the repository**
   ```bash
   git clone https://github.com/roshrv27/Jarvis-Transcribe.git
   cd Jarvis-Transcribe
   ```

2. **Run the installer**
   ```bash
   ./install.sh
   ```
   This will:
   - Install whisper.cpp with Metal support
   - Download base.en model (~141MB)
   - Set up Python dependencies
   - Configure the application
   
   ⏱️ Takes ~3-5 minutes on first run

3. **Grant permissions** ⚠️ **CRITICAL**

   **A. Microphone Access**
   - System Preferences → Privacy & Security → Microphone
   - Enable **Terminal**

   **B. Accessibility Access** (Required for keyboard typing)
   - System Preferences → Privacy & Security → Accessibility
   - Click **+** button
   - Press **Cmd+Shift+G** and paste:
     ```
     /opt/homebrew/Cellar/python@3.10/3.10.19_3/Frameworks/Python.framework/Versions/3.10/Resources/
     ```
   - Select **Python** application
   - Enable checkbox ✅

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
1. **Click** where you want text to appear
2. **Press and hold RIGHT OPTION key** (⌥ on right side)
3. **Speak** - red pill window appears
4. **Release** - text types automatically!

### Menu Options
Right-click the 🎤 icon:
- 📝 **Add Correction** - Teach the app your words
- 📚 **View Corrections** - See all saved corrections
- 🗑️ **Delete Correction** - Remove unwanted corrections
- ⚙️ **Settings** - View current configuration
- 📂 **Open Config Folder** - Edit config files

## 🧠 Model Details

**Currently Used:** `ggml-base.en.bin`

| Property | Value |
|----------|-------|
| **Size** | ~141 MB |
| **Parameters** | 74M |
| **Encoder Layers** | 6 |
| **Decoder Layers** | 6 |
| **Embedding Dim** | 512 |
| **Heads** | 8 |
| **Languages** | 99 (multilingual support) |
| **Format** | GGML (optimized for inference) |

**Why base.en?**
- ⚖️ Best speed/accuracy balance
- 📱 Runs smoothly on Apple Silicon
- 🌍 Supports English + 98 other languages
- 💾 Small enough for quick loading

**Performance:**
- **Load time:** ~120ms
- **Transcription:** ~1.75s for 11s audio
- **Memory:** ~150MB GPU memory
- **Accuracy:** ~95% on clean speech

## ⚙️ Configuration

Edit `~/.jarvisvoice/config.json`:
```json
{
  "hotkey": "alt_r",
  "model_size": "base.en",
  "language": "en",
  "auto_paste": true,
  "typing_delay": 0.01
}
```

**Available Models:**

| Model | Size | Speed | Best For |
|-------|------|-------|----------|
| `tiny` | ~39MB | ⚡⚡⚡ | Testing, low-resource |
| `base.en` | ~141MB | ⚡⚡ | **Default** - Great balance |
| `small` | ~466MB | ⚡ | Better accuracy |
| `medium` | ~1.5GB | 🐢 | High accuracy |
| `large-v3` | ~3GB | 🐌 | Maximum accuracy |

## 🛠️ Troubleshooting

### "This process is not trusted"
**Solution:** Add Python to Accessibility permissions (see Installation Step 3)

### "Model not found"
**Solution:** 
```bash
cd ~/Applications/JarvisVoice/whisper.cpp
./models/download-ggml-model.sh base.en
```

### "Red pill not appearing"
**Solution:** 
- Check menu bar for 🎤 icon
- Click on a text field first
- Use **Right** Option key (not Left)

### "Text types in terminal instead of target app"
**Solution:** Click the target window **before** pressing Right Option

### Slow transcription
**Solution:** First run compiles Metal shaders. Second run will be much faster!

## 🔄 Reinstalling

```bash
# Remove everything
rm -rf ~/Applications/JarvisVoice
rm -rf ~/.jarvisvoice
rm -rf ~/Library/Caches/whisper

# Reinstall
cd Jarvis-Transcribe
./install.sh
```

## 📊 System Requirements

| Requirement | Minimum | Recommended |
|-------------|---------|-------------|
| **macOS** | 10.15 (Catalina) | 13+ (Ventura) |
| **Processor** | Apple M1 | Apple M2/M3 |
| **RAM** | 4GB | 8GB |
| **Storage** | 500MB free | 1GB free |
| **Internet** | For initial install | - |

## 📁 File Structure

```
jarvis-voice/
├── install.sh              # Main installer
├── start.sh                # Launch script
├── requirements.txt        # Python dependencies
├── whisper_cpp_wrapper.py  # Python-C++ bridge ⭐
├── src/
│   └── main.py            # Main application
├── whisper.cpp/           # C++ engine (cloned)
│   ├── build/bin/whisper-cli
│   └── models/ggml-base.en.bin
└── README.md              # This file
```

## 🏆 Checkpoints

| Checkpoint | Description | Date |
|------------|-------------|------|
| `checkpoint-Sunday-8-February-9AM` | Initial working version | Feb 8, 2026 |
| `checkpoint-cpp-metal-v1` | **Current** - whisper.cpp + Metal GPU | Feb 8, 2026 |

## 📄 License

MIT License - Free to use and modify!

---

**Made with ❤️ for fast voice typing on macOS**

**Powered by:** [OpenAI Whisper](https://github.com/openai/whisper) + [whisper.cpp](https://github.com/ggerganov/whisper.cpp) + Apple Metal

**GitHub:** https://github.com/roshrv27/Jarvis-Transcribe
