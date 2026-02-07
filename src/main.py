#!/usr/bin/env python3
"""
Jarvis Voice - A macOS speech-to-text app with local Whisper
Similar to Aqua Voice - Simple interface with rounded corners
"""

import sys
import os
import threading
import json
import time
from pathlib import Path
from typing import Optional

import rumps
import sounddevice as sd
import numpy as np
from pynput import keyboard
from pynput.keyboard import Controller as KeyboardController, Key
from faster_whisper import WhisperModel
from PyQt6.QtWidgets import QApplication, QWidget, QVBoxLayout, QLabel
from PyQt6.QtCore import Qt, QTimer, pyqtSignal, QObject, QRectF
from PyQt6.QtGui import QFont, QPainter, QColor, QBrush, QPainterPath

# Configuration
CONFIG_DIR = Path.home() / ".jarvisvoice"
CONFIG_FILE = CONFIG_DIR / "config.json"
DEFAULT_CONFIG = {
    "hotkey": "ctrl",
    "model_size": "base",
    "language": "en",
    "typing_delay": 0.01,
    "auto_paste": True,
}


class AudioRecorder:
    """Handles audio recording"""

    def __init__(self):
        self.recording = False
        self.audio_data = []
        self.sample_rate = 16000

    def start_recording(self):
        """Start recording audio"""
        self.recording = True
        self.audio_data = []
        try:
            self.stream = sd.InputStream(
                samplerate=self.sample_rate,
                channels=1,
                dtype=np.float32,
                callback=self._audio_callback,
                blocksize=1024,
            )
            self.stream.start()
            return True
        except Exception as e:
            print(f"Error starting recording: {e}")
            self.recording = False
            return False

    def stop_recording(self):
        """Stop recording and return audio data"""
        self.recording = False
        if hasattr(self, "stream"):
            try:
                self.stream.stop()
                self.stream.close()
            except:
                pass
        return np.concatenate(self.audio_data) if self.audio_data else np.array([])

    def _audio_callback(self, indata, frames, time_info, status):
        """Callback for audio stream"""
        if self.recording:
            self.audio_data.append(indata.copy())


class WhisperTranscriber:
    """Handles Whisper transcription"""

    def __init__(self, model_size="base"):
        self.model_size = model_size
        self.model = None
        self._load_model()

    def _load_model(self):
        """Load the Whisper model"""
        print(f"Loading Whisper model: {self.model_size}...")
        model_dir = CONFIG_DIR / "models"
        model_dir.mkdir(parents=True, exist_ok=True)

        try:
            self.model = WhisperModel(
                self.model_size,
                device="cpu",
                compute_type="int8",
                download_root=str(model_dir),
            )
            print("Model loaded successfully!")
        except Exception as e:
            print(f"Error loading model: {e}")
            raise

    def transcribe(self, audio_data: np.ndarray, language: str = "en") -> str:
        """Transcribe audio to text"""
        if len(audio_data) == 0:
            return ""

        segments, _ = self.model.transcribe(
            audio_data, language=language, beam_size=5, vad_filter=True
        )

        text = " ".join([segment.text for segment in segments])
        return text.strip()


class FloatingWindow(QWidget):
    """Minimal floating window with rounded corners"""

    status_changed = pyqtSignal(str)

    def __init__(self):
        super().__init__()
        self.setWindowFlags(
            Qt.WindowType.FramelessWindowHint
            | Qt.WindowType.WindowStaysOnTopHint
            | Qt.WindowType.Tool
        )
        self.setAttribute(Qt.WidgetAttribute.WA_TranslucentBackground)

        # Window dimensions
        self.window_width = 320
        self.window_height = 42
        self.corner_radius = 21  # Half of height for perfect pill shape

        # Colors
        self.colors = {
            "recording": QColor(255, 59, 48, 230),  # Red
            "processing": QColor(0, 122, 255, 230),  # Blue
            "typing": QColor(52, 199, 89, 230),  # Green
            "ready": QColor(40, 40, 40, 230),  # Dark
        }
        self.current_color = self.colors["ready"]
        self.current_text = "🎤 Ready"

        # Connect signals
        self.status_changed.connect(self._update_status)

        # Position at top-center of screen
        screen = QApplication.primaryScreen().geometry()
        self.move((screen.width() - self.window_width) // 2, 100)
        self.resize(self.window_width, self.window_height)

    def paintEvent(self, event):
        """Draw rounded rectangle window"""
        painter = QPainter(self)
        painter.setRenderHint(QPainter.RenderHint.Antialiasing)

        # Create rounded rectangle path
        path = QPainterPath()
        rect = QRectF(0, 0, self.window_width, self.window_height)
        path.addRoundedRect(rect, self.corner_radius, self.corner_radius)

        # Fill with background color
        painter.fillPath(path, QBrush(self.current_color))

        # Draw text
        painter.setPen(QColor(255, 255, 255))
        font = QFont("SF Pro", 16, QFont.Weight.Medium)
        painter.setFont(font)

        # Center text
        text_rect = QRectF(0, 0, self.window_width, self.window_height)
        painter.drawText(text_rect, Qt.AlignmentFlag.AlignCenter, self.current_text)

        painter.end()

    def _update_status(self, status):
        """Update the status display"""
        status_map = {
            "recording": ("🔴 Recording", self.colors["recording"]),
            "processing": ("⚙️ Processing...", self.colors["processing"]),
            "typing": ("⌨️ Typing...", self.colors["typing"]),
            "ready": ("🎤 Ready", self.colors["ready"]),
        }

        if status in status_map:
            self.current_text, self.current_color = status_map[status]
            if status == "ready":
                self.hide()
            else:
                self.show()
                self.update()  # Redraw


class Communicate(QObject):
    """Helper class for thread communication"""

    update_status = pyqtSignal(str)
    type_text = pyqtSignal(str)


class JarvisVoiceApp:
    """Main application class"""

    def __init__(self):
        # Ensure config directory exists
        CONFIG_DIR.mkdir(parents=True, exist_ok=True)

        # Load config
        self.config = self._load_config()

        # Initialize components
        self.recorder = AudioRecorder()
        self.transcriber = None
        self.keyboard = KeyboardController()

        # Qt app for floating window
        self.qt_app = QApplication(sys.argv)
        self.floating_window = FloatingWindow()
        self.comm = Communicate()
        self.comm.update_status.connect(self.floating_window.status_changed)
        self.comm.type_text.connect(self._type_text)

        # State
        self.is_recording = False
        self.hotkey_pressed = False
        self.model_loaded = False

        # Menu bar app
        self.app = rumps.App("Jarvis Voice", "🎤")
        self._setup_menu()

        # Start hotkey listener
        self._start_hotkey_listener()

        # Load model in background
        self.status_item = rumps.MenuItem("Status: Loading model...")
        threading.Thread(target=self._init_model, daemon=True).start()

    def _load_config(self) -> dict:
        """Load or create config"""
        if CONFIG_FILE.exists():
            with open(CONFIG_FILE, "r") as f:
                return {**DEFAULT_CONFIG, **json.load(f)}
        else:
            with open(CONFIG_FILE, "w") as f:
                json.dump(DEFAULT_CONFIG, f, indent=2)
            return DEFAULT_CONFIG.copy()

    def _save_config(self):
        """Save config to file"""
        with open(CONFIG_FILE, "w") as f:
            json.dump(self.config, f, indent=2)

    def _init_model(self):
        """Initialize Whisper model"""
        try:
            self.transcriber = WhisperTranscriber(self.config.get("model_size", "base"))
            self.model_loaded = True
            self.status_item.title = "Status: Ready"
        except Exception as e:
            print(f"Error loading model: {e}")
            self.status_item.title = f"Status: Error - {e}"

    def _setup_menu(self):
        """Setup menu bar menu"""
        self.app.menu = [
            self.status_item,
            None,
            rumps.MenuItem("Start Recording", callback=self._toggle_recording),
            None,
            rumps.MenuItem("Settings", callback=self._show_settings),
            rumps.MenuItem("Open Config Folder", callback=self._open_config),
            None,
            rumps.MenuItem("About", callback=self._show_about),
            rumps.MenuItem("Quit", callback=self._quit),
        ]

    def _get_hotkey_key(self):
        """Get the hotkey key from config"""
        hotkey_map = {
            "fn": None,  # Special handling
            "ctrl": keyboard.Key.ctrl,
            "alt": keyboard.Key.alt,
            "cmd": keyboard.Key.cmd,
            "shift": keyboard.Key.shift,
            "space": keyboard.Key.space,
            "tab": keyboard.Key.tab,
            "esc": keyboard.Key.esc,
        }
        hotkey = self.config.get("hotkey", "ctrl")
        return hotkey_map.get(hotkey, keyboard.Key.ctrl)

    def _start_hotkey_listener(self):
        """Start listening for global hotkeys"""
        hotkey = self.config.get("hotkey", "ctrl")

        if hotkey == "fn":
            print("Note: Fn key detection is limited on macOS. Using Ctrl instead.")
            hotkey = "ctrl"

        target_key = self._get_hotkey_key()

        def on_press(key):
            try:
                if key == target_key or (hasattr(key, "name") and key.name == hotkey):
                    if not self.hotkey_pressed:
                        self.hotkey_pressed = True
                        self._toggle_recording()
            except:
                pass

        def on_release(key):
            try:
                if key == target_key or (hasattr(key, "name") and key.name == hotkey):
                    self.hotkey_pressed = False
                    if self.is_recording:
                        self._toggle_recording()
            except:
                pass

        self.hotkey_listener = keyboard.Listener(
            on_press=on_press, on_release=on_release
        )
        self.hotkey_listener.daemon = True
        self.hotkey_listener.start()
        print(f"Hotkey listener started. Press and hold '{hotkey}' to record.")

    def _toggle_recording(self, _=None):
        """Toggle recording on/off"""
        if not self.is_recording:
            self._start_recording()
        else:
            self._stop_recording()

    def _start_recording(self):
        """Start recording"""
        if not self.model_loaded:
            rumps.notification(
                "Jarvis Voice", "Please wait", "Model is still loading..."
            )
            return

        if not self.transcriber:
            rumps.notification(
                "Jarvis Voice", "Error", "Model not loaded. Check console."
            )
            return

        self.is_recording = True
        self.comm.update_status.emit("recording")

        if self.recorder.start_recording():
            print("Recording started...")
        else:
            self.is_recording = False
            self.comm.update_status.emit("ready")
            rumps.notification(
                "Jarvis Voice",
                "Error",
                "Could not access microphone. Check permissions.",
            )

    def _stop_recording(self):
        """Stop recording and process"""
        if not self.is_recording:
            return

        self.is_recording = False
        self.comm.update_status.emit("processing")

        audio_data = self.recorder.stop_recording()
        print("Recording stopped. Processing...")

        threading.Thread(
            target=self._process_audio, args=(audio_data,), daemon=True
        ).start()

    def _process_audio(self, audio_data: np.ndarray):
        """Process audio and type text"""
        try:
            language = self.config.get("language", "en")
            text = self.transcriber.transcribe(audio_data, language)

            if text:
                print(f"Transcribed: {text}")
                self.comm.update_status.emit("typing")
                self.comm.type_text.emit(text)
            else:
                print("No speech detected")
                self.comm.update_status.emit("ready")

        except Exception as e:
            print(f"Error processing audio: {e}")
            self.comm.update_status.emit("ready")

    def _type_text(self, text: str):
        """Type text into active application"""
        try:
            time.sleep(0.1)
            self.keyboard.type(text)

            if self.config.get("auto_paste", True):
                time.sleep(0.05)
                self.keyboard.tap(Key.space)

            self.comm.update_status.emit("ready")

        except Exception as e:
            print(f"Error typing text: {e}")
            self.comm.update_status.emit("ready")

    def _show_settings(self, _):
        """Show settings window"""
        hotkey = self.config["hotkey"]
        model = self.config["model_size"]

        settings_text = f"""
Current Settings:

Hotkey: {hotkey}
Model: {model}
Language: {self.config.get("language", "en")}

To change settings, edit:
{CONFIG_FILE}

Valid hotkeys: fn, ctrl, alt, cmd, shift, space, tab, esc
Valid models: tiny, base, small, medium, large-v3

After editing, restart Jarvis Voice.
"""
        rumps.alert(title="Settings", message=settings_text)

    def _open_config(self, _):
        """Open config folder in Finder"""
        os.system(f'open "{CONFIG_DIR}"')

    def _show_about(self, _):
        """Show about dialog"""
        hotkey = self.config.get("hotkey", "ctrl")
        rumps.alert(
            title="About Jarvis Voice",
            message=f"Jarvis Voice v1.2\n\nLocal speech-to-text for macOS\n\nPress and hold '{hotkey}' to record.\n\nPowered by OpenAI Whisper",
        )

    def _quit(self, _):
        """Quit the app"""
        if hasattr(self, "hotkey_listener"):
            self.hotkey_listener.stop()
        self.qt_app.quit()
        rumps.quit_application()

    def run(self):
        """Run the application"""
        qt_thread = threading.Thread(target=self.qt_app.exec, daemon=True)
        qt_thread.start()

        self.app.run()


def main():
    """Main entry point"""
    try:
        app = JarvisVoiceApp()
        app.run()
    except KeyboardInterrupt:
        print("\nShutting down...")
        sys.exit(0)
    except Exception as e:
        print(f"Fatal error: {e}")
        rumps.alert(title="Jarvis Voice Error", message=f"Fatal error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
