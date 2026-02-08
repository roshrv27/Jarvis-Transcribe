#!/usr/bin/env python3
"""
Jarvis Voice - A macOS speech-to-text app with local Whisper
Simple and efficient - uses notification sounds for feedback
"""

import sys
import os
import threading
import json
import time
import re
from pathlib import Path
from subprocess import run
from collections import deque

import rumps
import sounddevice as sd
import numpy as np
from pynput import keyboard
from pynput.keyboard import Controller as KeyboardController, Key

# Add whisper.cpp wrapper to path
sys.path.insert(0, str(Path.home() / "Applications" / "JarvisVoice"))
from whisper_cpp_wrapper import WhisperCPP

# Configuration
CONFIG_DIR = Path.home() / ".jarvisvoice"
CONFIG_FILE = CONFIG_DIR / "config.json"
CORRECTIONS_FILE = CONFIG_DIR / "corrections.json"

DEFAULT_CONFIG = {
    "hotkey": "ctrl",
    "model_size": "base",
    "language": "en",
    "auto_paste": True,
    "recording_sound": "Ping",
}

AVAILABLE_SOUNDS = [
    ("Basso", "Deep, low alert sound"),
    ("Blow", "Air whoosh sound"),
    ("Bottle", "Cork pop sound"),
    ("Frog", "Ribbit sound"),
    ("Funk", "Short bass sound"),
    ("Glass", "Gentle glass tap"),
    ("Hero", "Triumphant fanfare"),
    ("Morse", "Morse code beeps"),
    ("Ping", "Clean, high-pitched ping"),
    ("Pop", "Bubble pop sound"),
    ("Purr", "Soft vibration sound"),
    ("Sosumi", "Classic Mac sound"),
    ("Submarine", "Sonar ping"),
    ("Tink", "Light metallic tap"),
]

DEFAULT_CORRECTIONS = {"auto_corrections": {}}


class AudioRecorder:
    """Handles audio recording with memory-efficient buffer"""

    def __init__(self):
        self.recording = False
        self.audio_data = []
        self.sample_rate = 16000
        # Max 60 seconds of audio at 16kHz (safety limit)
        self.max_chunks = int((16000 * 60) / 2048)

    def start_recording(self):
        """Start recording audio"""
        self.recording = True
        # Use deque with maxlen to prevent memory issues on accidental long recordings
        self.audio_data = deque(maxlen=self.max_chunks)
        try:
            self.stream = sd.InputStream(
                samplerate=self.sample_rate,
                channels=1,
                dtype=np.float32,
                callback=self._audio_callback,
                blocksize=2048,
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
        # Convert deque to list then concatenate (faster than iterating)
        return np.concatenate(list(self.audio_data)).flatten()

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


class JarvisVoiceApp:
    """Main application class"""

    def __init__(self):
        # Ensure config directory exists
        CONFIG_DIR.mkdir(parents=True, exist_ok=True)

        # Load config
        self.config = self._load_config()
        self.corrections = self._load_corrections()

        # Initialize components
        self.recorder = AudioRecorder()
        self.transcriber = None
        self.keyboard = KeyboardController()

        # State
        self.is_recording = False
        self.hotkey_pressed = False
        self.model_loaded = False
        self.last_active_app = None

        # Menu storage
        self.sound_menu_items = {}
        self.status_item = rumps.MenuItem("Status: Loading model...")

        # Menu bar app
        self.app = rumps.App("Jarvis Voice", "🎤", quit_button=None)
        self._setup_menu()

        # Start hotkey listener
        self._start_hotkey_listener()

        # Load model in background
        threading.Thread(target=self._init_model, daemon=True).start()

    def _load_config(self):
        """Load or create config"""
        if CONFIG_FILE.exists():
            with open(CONFIG_FILE, "r") as f:
                return {**DEFAULT_CONFIG, **json.load(f)}
        else:
            with open(CONFIG_FILE, "w") as f:
                json.dump(DEFAULT_CONFIG, f, indent=2)
            return DEFAULT_CONFIG.copy()

    def _load_corrections(self):
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

    def _save_config(self):
        """Save config to file"""
        with open(CONFIG_FILE, "w") as f:
            json.dump(self.config, f, indent=2)

    def _process_text_with_corrections(self, text: str) -> str:
        """Apply auto-corrections to transcribed text"""
        if not text:
            return text

        corrections_map = self.corrections.get("auto_corrections", {})
        # Sort by length (longest first) to avoid partial replacements
        for wrong, correct in sorted(
            corrections_map.items(), key=lambda x: len(x[0]), reverse=True
        ):
            pattern = re.compile(re.escape(wrong), re.IGNORECASE)
            text = pattern.sub(correct, text)

        return text

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
            self.status_item.title = f"Status: Error - {e}"

    def _setup_menu(self):
        """Setup menu bar menu"""
        sound_menu = []
        current_sound = self.config.get("recording_sound", "Ping")

        sound_menu.append(
            rumps.MenuItem("🔊 Preview All Sounds", callback=self._preview_all_sounds)
        )
        sound_menu.append(None)

        # Clear stored menu items
        self.sound_menu_items = {}

        for sound_name, description in AVAILABLE_SOUNDS:
            prefix = "✓ " if sound_name == current_sound else "   "
            menu_item = rumps.MenuItem(
                f"{prefix}{sound_name} - {description}",
                callback=lambda sender, name=sound_name: self._select_sound(name),
            )
            self.sound_menu_items[sound_name] = menu_item
            sound_menu.append(menu_item)

        self.app.menu = [
            self.status_item,
            None,
            rumps.MenuItem("Start Recording", callback=self._toggle_recording),
            None,
            {"🔔 Recording Sound": sound_menu},
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

    def _start_hotkey_listener(self):
        """Start listening for global hotkeys"""

        def on_press(key):
            try:
                if key == keyboard.Key.alt_r and not self.hotkey_pressed:
                    self.hotkey_pressed = True
                    print("RIGHT Option key pressed - starting recording...")
                    self._toggle_recording()
            except Exception as e:
                print(f"Error in on_press: {e}")

        def on_release(key):
            try:
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

    def _play_recording_sound(self):
        """Play notification sound"""
        try:
            sound_name = self.config.get("recording_sound", "Ping")
            run(
                ["afplay", f"/System/Library/Sounds/{sound_name}.aiff"],
                capture_output=True,
                timeout=5,
            )
        except Exception as e:
            print(f"Could not play recording sound: {e}")

    def _preview_all_sounds(self, _):
        """Play all sounds"""

        def play_all():
            for sound_name, description in AVAILABLE_SOUNDS:
                try:
                    run(
                        ["afplay", f"/System/Library/Sounds/{sound_name}.aiff"],
                        capture_output=True,
                        timeout=5,
                    )
                    time.sleep(0.3)
                except:
                    pass

        threading.Thread(target=play_all, daemon=True).start()

    def _select_sound(self, sound_name):
        """Select notification sound"""
        try:
            self.config["recording_sound"] = sound_name
            self._save_config()

            # Play selected sound
            run(
                ["afplay", f"/System/Library/Sounds/{sound_name}.aiff"],
                capture_output=True,
                timeout=5,
            )

            rumps.notification(
                "Jarvis Voice", "🔔 Sound Selected", f"Recording sound: {sound_name}"
            )
            self._update_sound_menu_checkmarks()
            print(f"Recording sound: {sound_name}")
        except Exception as e:
            print(f"Could not select sound: {e}")

    def _update_sound_menu_checkmarks(self):
        """Update menu checkmarks"""
        try:
            current_sound = self.config.get("recording_sound", "Ping")
            for sound_name, menu_item in self.sound_menu_items.items():
                prefix = "✓ " if sound_name == current_sound else "   "
                description = dict(AVAILABLE_SOUNDS).get(sound_name, "")
                new_title = f"{prefix}{sound_name} - {description}"
                menu_item.title = new_title
                if hasattr(menu_item, "_menuitem") and menu_item._menuitem:
                    menu_item._menuitem.setTitle_(new_title)
        except Exception as e:
            print(f"Could not update menu: {e}")

    def _get_active_app(self):
        """Get currently active app in background thread"""
        try:
            result = run(
                [
                    "osascript",
                    "-e",
                    'tell application "System Events" to get name of first application process whose frontmost is true',
                ],
                capture_output=True,
                text=True,
                timeout=1,
            )
            if result.returncode == 0:
                self.last_active_app = result.stdout.strip()
            else:
                self.last_active_app = None
        except:
            self.last_active_app = None

    def _start_recording(self):
        """Start recording"""
        if not self.model_loaded:
            rumps.notification(
                "Jarvis Voice", "Please wait", "Model is still loading..."
            )
            return

        if not self.transcriber:
            rumps.notification("Jarvis Voice", "Error", "Model not loaded.")
            return

        # Get active app in background to avoid blocking
        threading.Thread(target=self._get_active_app, daemon=True).start()

        self.is_recording = True
        threading.Thread(target=self._play_recording_sound, daemon=True).start()

        if self.recorder.start_recording():
            print("Recording started...")
        else:
            self.is_recording = False
            rumps.notification("Jarvis Voice", "Error", "Could not access microphone.")

    def _stop_recording(self):
        """Stop recording and process"""
        if not self.is_recording:
            return

        self.is_recording = False
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
                text = self._process_text_with_corrections(text)
                print(f"Corrected: {text}")
                self._type_text(text)
            else:
                print("No speech detected")
        except Exception as e:
            print(f"Error processing audio: {e}")

    def _type_text(self, text: str):
        """Type text into active application"""
        try:
            # Restore focus to original app
            if self.last_active_app and self.last_active_app != "Jarvis Voice":
                try:
                    run(
                        [
                            "osascript",
                            "-e",
                            f'tell application "{self.last_active_app}" to activate',
                        ],
                        capture_output=True,
                        timeout=2,
                    )
                    time.sleep(0.05)
                except:
                    pass

            self.keyboard.type(text)

            if self.config.get("auto_paste", True):
                time.sleep(0.03)
                self.keyboard.tap(Key.space)

        except Exception as e:
            print(f"Error typing text: {e}")

    def _show_settings(self, _):
        """Show settings"""
        model = self.config["model_size"]
        settings_text = f"""
Current Settings:

Hotkey: Right Option Key
Model: {model}
Language: {self.config.get("language", "en")}

To change settings, edit:
{CONFIG_FILE}

Valid models: tiny, base, small, medium, large-v3
"""
        rumps.alert(title="Settings", message=settings_text)

    def _open_config(self, _):
        """Open config folder"""
        try:
            run(["open", str(CONFIG_DIR)], check=True)
        except Exception as e:
            print(f"Error opening config: {e}")

    def _show_about(self, _):
        """Show about dialog"""
        rumps.alert(
            title="About Jarvis Voice",
            message="Jarvis Voice v1.2\n\nLocal speech-to-text for macOS\n\nPress and hold RIGHT OPTION KEY to record.\n\nPowered by OpenAI Whisper",
        )

    def _add_correction(self, _):
        """Add auto-correction"""
        try:
            wrong_text = rumps.Window(
                title="Add Correction",
                message="What did the app hear incorrectly?",
                default_text="",
                dimensions=(400, 100),
            ).run()

            if wrong_text.clicked and wrong_text.text:
                wrong = wrong_text.text.strip()

                correct_text = rumps.Window(
                    title="Add Correction",
                    message=f"What should '{wrong}' be?",
                    default_text="",
                    dimensions=(400, 100),
                ).run()

                if correct_text.clicked and correct_text.text:
                    correct = correct_text.text.strip()
                    self.corrections.setdefault("auto_corrections", {})[wrong] = correct
                    self._save_corrections()
                    rumps.notification(
                        "Jarvis Voice", "✅ Added", f"'{wrong}' → '{correct}'"
                    )
                    print(f"Added: '{wrong}' → '{correct}'")
        except Exception as e:
            print(f"Error adding correction: {e}")

    def _view_corrections(self, _):
        """View corrections"""
        try:
            corrections_map = self.corrections.get("auto_corrections", {})
            if not corrections_map:
                rumps.alert(title="Corrections", message="No corrections saved yet.")
                return

            text = "Saved Corrections:\n\n"
            for wrong, correct in sorted(corrections_map.items()):
                text += f"'{wrong}' → '{correct}'\n"

            rumps.alert(title="Corrections", message=text)
        except Exception as e:
            print(f"Error viewing corrections: {e}")

    def _delete_correction(self, _):
        """Delete correction"""
        try:
            corrections_map = self.corrections.get("auto_corrections", {})
            if not corrections_map:
                rumps.alert(title="Delete", message="No corrections to delete.")
                return

            corrections_list = "\n".join(
                [
                    f"{i + 1}. '{w}' → '{c}'"
                    for i, (w, c) in enumerate(sorted(corrections_map.items()))
                ]
            )

            response = rumps.Window(
                title="Delete Correction",
                message=f"Enter number to delete:\n\n{corrections_list}",
                default_text="",
                dimensions=(400, 300),
            ).run()

            if response.clicked and response.text:
                try:
                    selection = int(response.text.strip())
                    if 1 <= selection <= len(corrections_map):
                        sorted_items = sorted(corrections_map.items())
                        wrong_to_delete = sorted_items[selection - 1][0]
                        correct_value = sorted_items[selection - 1][1]
                        del self.corrections["auto_corrections"][wrong_to_delete]
                        self._save_corrections()
                        rumps.notification(
                            "Jarvis Voice",
                            "✅ Deleted",
                            f"Removed: '{wrong_to_delete}'",
                        )
                        print(f"Deleted: '{wrong_to_delete}'")
                except ValueError:
                    rumps.notification(
                        "Jarvis Voice", "❌ Error", "Enter a valid number"
                    )
        except Exception as e:
            print(f"Error deleting correction: {e}")

    def _quit_app(self, _=None):
        """Quit app"""
        print("Quitting...")
        if hasattr(self, "hotkey_listener"):
            self.hotkey_listener.stop()
        rumps.quit_application()
        return True

    def run(self):
        """Run the application"""
        try:
            print("Starting Jarvis Voice...")
            self.app.run()
        except Exception as e:
            print(f"Error: {e}")
            import traceback

            traceback.print_exc()
            raise


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
        import traceback

        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
