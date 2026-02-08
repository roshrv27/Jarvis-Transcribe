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
import re
from pathlib import Path
from typing import Optional
from subprocess import run

import rumps
import sounddevice as sd
import numpy as np
from pynput import keyboard
from pynput.keyboard import Controller as KeyboardController, Key
from pynput.mouse import Controller as MouseController, Button

# Add whisper.cpp wrapper to path
sys.path.insert(0, str(Path.home() / "Applications" / "JarvisVoice"))
from whisper_cpp_wrapper import WhisperCPP
from PyQt6.QtWidgets import QApplication, QWidget, QVBoxLayout, QLabel
from PyQt6.QtCore import Qt, QTimer, pyqtSignal, QObject, QRectF
from PyQt6.QtGui import QFont, QPainter, QColor, QBrush, QPainterPath

# Configuration
CONFIG_DIR = Path.home() / ".jarvisvoice"
CONFIG_FILE = CONFIG_DIR / "config.json"
VOCAB_FILE = CONFIG_DIR / "vocabulary.json"
CORRECTIONS_FILE = CONFIG_DIR / "corrections.json"

DEFAULT_CONFIG = {
    "hotkey": "ctrl",
    "model_size": "base",
    "language": "en",
    "typing_delay": 0.01,
    "auto_paste": True,
}

DEFAULT_VOCABULARY = {
    "custom_words": [],  # Words to boost recognition
    "context_phrases": [],  # Domain-specific phrases
}

DEFAULT_CORRECTIONS = {
    "auto_corrections": {},  # Empty by default - user adds their own
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
        if not self.audio_data:
            return np.array([], dtype=np.float32)
        # Concatenate and flatten to 1D array
        audio = np.concatenate(self.audio_data)
        audio = audio.flatten()  # Ensure 1D array
        return audio

    def _audio_callback(self, indata, frames, time_info, status):
        """Callback for audio stream"""
        if self.recording:
            self.audio_data.append(indata.copy())


class WhisperTranscriber:
    """Handles Whisper transcription using whisper.cpp"""

    def __init__(self, model_size="base.en"):
        self.model_size = model_size
        self.model = None
        self._load_model()

    def _load_model(self):
        """Load the Whisper model"""
        print(f"Loading Whisper model: {self.model_size}...")

        try:
            self.model = WhisperCPP(self.model_size)
            print("Model loaded successfully!")
        except Exception as e:
            print(f"Error loading model: {e}")
            raise

    def transcribe(self, audio_data: np.ndarray, language: str = "en") -> str:
        """Transcribe audio to text"""
        if len(audio_data) == 0:
            return ""

        return self.model.transcribe(audio_data, language)


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
        font = QFont("Helvetica Neue", 16, QFont.Weight.Medium)
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
                self.raise_()
                self.activateWindow()
                self.update()  # Redraw
                print(f"Window shown: {status}")


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

        # Load vocabulary and corrections
        self.vocabulary = self._load_vocabulary()
        self.corrections = self._load_corrections()

        # Initialize components
        self.recorder = AudioRecorder()
        self.transcriber = None
        self.keyboard = KeyboardController()
        self.mouse = MouseController()

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

        # Create status item first (needed by _setup_menu)
        self.status_item = rumps.MenuItem("Status: Loading model...")

        # Menu bar app
        self.app = rumps.App("Jarvis Voice", "🎤", quit_button=None)
        self._setup_menu()

        # Start hotkey listener with right Option key
        self._start_hotkey_listener()

        # Load model in background
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

    def _load_vocabulary(self) -> dict:
        """Load or create vocabulary"""
        if VOCAB_FILE.exists():
            with open(VOCAB_FILE, "r") as f:
                return {**DEFAULT_VOCABULARY, **json.load(f)}
        else:
            with open(VOCAB_FILE, "w") as f:
                json.dump(DEFAULT_VOCABULARY, f, indent=2)
            return DEFAULT_VOCABULARY.copy()

    def _load_corrections(self) -> dict:
        """Load or create corrections"""
        if CORRECTIONS_FILE.exists():
            with open(CORRECTIONS_FILE, "r") as f:
                return {**DEFAULT_CORRECTIONS, **json.load(f)}
        else:
            with open(CORRECTIONS_FILE, "w") as f:
                json.dump(DEFAULT_CORRECTIONS, f, indent=2)
            return DEFAULT_CORRECTIONS.copy()

    def _save_corrections(self):
        """Save corrections to file"""
        with open(CORRECTIONS_FILE, "w") as f:
            json.dump(self.corrections, f, indent=2)

    def _process_text_with_corrections(self, text: str) -> str:
        """Apply auto-corrections and vocabulary to transcribed text"""
        if not text:
            return text

        # Apply auto-corrections (case-insensitive matching)
        corrections_map = self.corrections.get("auto_corrections", {})

        # Sort by length (longest first) to avoid partial replacements
        for wrong, correct in sorted(
            corrections_map.items(), key=lambda x: len(x[0]), reverse=True
        ):
            # Case-insensitive replacement using pre-imported re module
            pattern = re.compile(re.escape(wrong), re.IGNORECASE)
            text = pattern.sub(correct, text)

        return text

    def _save_config(self):
        """Save config to file"""
        with open(CONFIG_FILE, "w") as f:
            json.dump(self.config, f, indent=2)

    def _init_model(self):
        """Initialize Whisper model"""
        try:
            model_size = self.config.get("model_size", "base")
            print(f"Loading model: {model_size}...", flush=True)
            self.transcriber = WhisperTranscriber(model_size)
            self.model_loaded = True
            self.status_item.title = "Status: Ready"
            print(f"Model loaded successfully: {model_size}", flush=True)
        except Exception as e:
            print(f"Error loading model: {e}", flush=True)
            import traceback

            traceback.print_exc()
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
            rumps.MenuItem("📝 Add Correction", callback=self._add_correction),
            rumps.MenuItem("📚 View Corrections", callback=self._view_corrections),
            rumps.MenuItem("🗑️ Delete Correction", callback=self._delete_correction),
            None,
            rumps.MenuItem("About", callback=self._show_about),
            rumps.MenuItem("Quit", callback=self._quit_app),
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
        """Start listening for global hotkeys - using right Option key"""

        def on_press(key):
            try:
                # Check for right Option key (alt_r)
                if key == keyboard.Key.alt_r:
                    if not self.hotkey_pressed:
                        self.hotkey_pressed = True
                        print("RIGHT Option key pressed - starting recording...")
                        self._toggle_recording()
            except Exception as e:
                print(f"Error in on_press: {e}")

        def on_release(key):
            try:
                # Check for right Option key (alt_r)
                if key == keyboard.Key.alt_r:
                    self.hotkey_pressed = False
                    print("RIGHT Option key released - stopping recording...")
                    if self.is_recording:
                        self._toggle_recording()
            except Exception as e:
                print(f"Error in on_release: {e}")

        self.hotkey_listener = keyboard.Listener(
            on_press=on_press, on_release=on_release
        )
        self.hotkey_listener.daemon = True
        self.hotkey_listener.start()
        print("Hotkey listener started. Press and hold RIGHT Option key to record.")

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
                print(f"Transcribed (raw): {text}")
                # Apply corrections
                text = self._process_text_with_corrections(text)
                print(f"Transcribed (corrected): {text}")
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
            # Click to ensure focus is on the correct window (not terminal)
            self.mouse.click(Button.left)
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

Hotkey: Right Option Key (alt_r)
Model: {model}
Language: {self.config.get("language", "en")}

To change settings, edit:
{CONFIG_FILE}

Note: This version uses Right Option key only
Valid models: tiny, base, small, medium, large-v3

After editing, restart Jarvis Voice.
"""
        rumps.alert(title="Settings", message=settings_text)

    def _open_config(self, _):
        """Open config folder in Finder securely"""
        try:
            run(["open", str(CONFIG_DIR)], check=True)
        except Exception as e:
            print(f"Error opening config folder: {e}")
            rumps.notification("Jarvis Voice", "Error", "Could not open config folder")

    def _show_about(self, _):
        """Show about dialog"""
        rumps.alert(
            title="About Jarvis Voice",
            message="Jarvis Voice v1.2\n\nLocal speech-to-text for macOS\n\nPress and hold RIGHT OPTION KEY to record.\n\nPowered by OpenAI Whisper",
        )

    def _add_correction(self, _):
        """Add a new auto-correction mapping"""
        try:
            # Get what the app typed wrong
            wrong_text = rumps.Window(
                title="Add Correction",
                message="What did the app type incorrectly?\n\n(What it heard)",
                default_text="",
                dimensions=(400, 100),
            ).run()

            if wrong_text.clicked and wrong_text.text:
                wrong = wrong_text.text.strip()

                # Get what it should have typed
                correct_text = rumps.Window(
                    title="Add Correction",
                    message=f"What should '{wrong}' be corrected to?\n\n(What you wanted)",
                    default_text="",
                    dimensions=(400, 100),
                ).run()

                if correct_text.clicked and correct_text.text:
                    correct = correct_text.text.strip()

                    # Add to corrections
                    if "auto_corrections" not in self.corrections:
                        self.corrections["auto_corrections"] = {}

                    self.corrections["auto_corrections"][wrong] = correct
                    self._save_corrections()

                    rumps.notification(
                        "Jarvis Voice",
                        "✅ Correction Added",
                        f"'{wrong}' → '{correct}'",
                    )
                    print(f"Added correction: '{wrong}' → '{correct}'")
        except Exception as e:
            print(f"Error adding correction: {e}")
            rumps.notification(
                "Jarvis Voice", "❌ Error", f"Could not add correction: {e}"
            )

    def _view_corrections(self, _):
        """View all saved corrections"""
        try:
            corrections_map = self.corrections.get("auto_corrections", {})

            if not corrections_map:
                rumps.alert(
                    title="Auto-Corrections",
                    message="No corrections saved yet.\n\nUse '📝 Add Correction' to teach the app your words!",
                )
                return

            # Format corrections list
            corrections_text = "Saved Auto-Corrections:\n\n"
            for wrong, correct in sorted(corrections_map.items()):
                corrections_text += f"'{wrong}' → '{correct}'\n"

            corrections_text += (
                "\n💡 Tip: The app automatically replaces these words when typing."
            )

            rumps.alert(title="Auto-Corrections", message=corrections_text)
        except Exception as e:
            print(f"Error viewing corrections: {e}")
            rumps.notification(
                "Jarvis Voice", "❌ Error", f"Could not view corrections: {e}"
            )

    def _delete_correction(self, _):
        """Delete a correction from the list"""
        try:
            corrections_map = self.corrections.get("auto_corrections", {})

            if not corrections_map:
                rumps.alert(
                    title="Delete Correction",
                    message="No corrections to delete.\n\nThe list is empty!",
                )
                return

            # Create a window to select which correction to delete
            corrections_list = "\n".join(
                [
                    f"{i + 1}. '{wrong}' → '{correct}'"
                    for i, (wrong, correct) in enumerate(
                        sorted(corrections_map.items())
                    )
                ]
            )

            response = rumps.Window(
                title="Delete Correction",
                message=f"Enter the number of the correction to delete:\n\n{corrections_list}",
                default_text="",
                dimensions=(400, 300),
            ).run()

            if response.clicked and response.text:
                try:
                    selection = int(response.text.strip())
                    if 1 <= selection <= len(corrections_map):
                        # Get the key to delete
                        sorted_items = sorted(corrections_map.items())
                        wrong_to_delete = sorted_items[selection - 1][0]
                        correct_value = sorted_items[selection - 1][1]

                        # Delete it
                        del self.corrections["auto_corrections"][wrong_to_delete]
                        self._save_corrections()

                        rumps.notification(
                            "Jarvis Voice",
                            "✅ Correction Deleted",
                            f"Removed: '{wrong_to_delete}' → '{correct_value}'",
                        )
                        print(
                            f"Deleted correction: '{wrong_to_delete}' → '{correct_value}'"
                        )
                    else:
                        rumps.notification(
                            "Jarvis Voice",
                            "❌ Invalid Selection",
                            f"Please enter a number between 1 and {len(corrections_map)}",
                        )
                except ValueError:
                    rumps.notification(
                        "Jarvis Voice",
                        "❌ Invalid Input",
                        "Please enter a valid number",
                    )
        except Exception as e:
            print(f"Error deleting correction: {e}")
            rumps.notification(
                "Jarvis Voice", "❌ Error", f"Could not delete correction: {e}"
            )

    def _quit_app(self, _=None):
        """Quit the app and cleanup resources"""
        print("Quitting Jarvis Voice...")
        if hasattr(self, "hotkey_listener"):
            self.hotkey_listener.stop()
        if hasattr(self, "qt_app"):
            self.qt_app.quit()
        return True  # Allow the quit to proceed

    def run(self):
        """Run the application"""
        try:
            print("Starting run() method...")
            # Hide floating window initially
            self.floating_window.hide()
            print("Floating window hidden")

            # Create a rumps timer to process Qt events periodically
            self._qt_timer = rumps.Timer(self._process_qt_events, 0.016)  # ~60fps
            self._qt_timer.start()
            print("Qt timer started")

            print("Starting rumps app.run()...")
            self.app.run()
            print("rumps app.run() completed")
        except Exception as e:
            print(f"Error in run(): {e}")
            import traceback

            traceback.print_exc()
            raise

    def _process_qt_events(self, _):
        """Process Qt events to keep floating window responsive"""
        self.qt_app.processEvents()


def main():
    """Main entry point"""
    try:
        app = JarvisVoiceApp()
        app.run()
    except KeyboardInterrupt:
        print("\nShutting down...")
        sys.exit(0)
    except Exception as e:
        import traceback

        print(f"Fatal error: {e}")
        traceback.print_exc()
        rumps.alert(title="Jarvis Voice Error", message=f"Fatal error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
