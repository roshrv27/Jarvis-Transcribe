"""
Whisper.cpp integration for Jarvis Voice
Uses the compiled whisper-cli with Metal GPU acceleration
"""

import subprocess
import tempfile
import os
import numpy as np
import wave
import soundfile as sf
from pathlib import Path


class WhisperCPP:
    """Wrapper for whisper.cpp CLI"""

    def __init__(self, model_name="base.en"):
        """Initialize whisper.cpp transcriber"""
        self.model_name = model_name
        self.whisper_dir = Path.home() / "Applications" / "JarvisVoice" / "whisper.cpp"
        self.model_path = self.whisper_dir / "models" / f"ggml-{model_name}.bin"
        self.cli_path = self.whisper_dir / "build" / "bin" / "whisper-cli"

        if not self.model_path.exists():
            raise FileNotFoundError(f"Model not found: {self.model_path}")

        if not self.cli_path.exists():
            raise FileNotFoundError(f"whisper-cli not found: {self.cli_path}")

    # Valid ISO 639-1 language codes supported by Whisper
    VALID_LANGUAGES = {
        "en",
        "zh",
        "de",
        "es",
        "ru",
        "ko",
        "fr",
        "ja",
        "pt",
        "tr",
        "pl",
        "ca",
        "nl",
        "ar",
        "sv",
        "it",
        "id",
        "hi",
        "fi",
        "vi",
        "he",
        "uk",
        "el",
        "ms",
        "cs",
        "ro",
        "da",
        "hu",
        "ta",
        "no",
        "th",
        "ur",
        "hr",
        "bg",
        "lt",
        "la",
        "mi",
        "ml",
        "cy",
        "sk",
        "te",
        "fa",
        "lv",
        "bn",
        "sr",
        "az",
        "sl",
        "kn",
        "et",
        "mk",
        "br",
        "eu",
        "is",
        "hy",
        "ne",
        "mn",
        "bs",
        "kk",
        "sq",
        "sw",
        "gl",
        "mr",
        "pa",
        "si",
        "km",
        "sn",
        "yo",
        "so",
        "af",
        "oc",
        "ka",
        "be",
        "tg",
        "sd",
        "gu",
        "am",
        "yi",
        "lo",
        "uz",
        "fo",
        "ht",
        "ps",
        "tk",
        "nn",
        "mt",
        "sa",
        "lb",
        "my",
        "bo",
        "tl",
        "mg",
        "as",
        "tt",
        "haw",
        "ln",
        "ha",
        "ba",
        "jw",
        "su",
    }

    def transcribe(self, audio_data: np.ndarray, language: str = "en") -> str:
        """Transcribe audio using whisper.cpp"""
        if len(audio_data) == 0:
            return ""

        # Validate language code to prevent command injection
        if language not in self.VALID_LANGUAGES:
            print(f"Warning: Invalid language code '{language}', defaulting to 'en'")
            language = "en"

        # Create temporary WAV file
        with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp_file:
            tmp_path = tmp_file.name

        try:
            # Save audio as 16-bit PCM WAV file (required by whisper.cpp)
            sf.write(tmp_path, audio_data, 16000, subtype="PCM_16")

            # Run whisper-cli
            cmd = [
                str(self.cli_path),
                "-m",
                str(self.model_path),
                "-f",
                tmp_path,
                "-l",
                language,
                "--no-timestamps",
            ]

            result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)

            if result.returncode != 0:
                print(f"whisper.cpp error: {result.stderr}")
                return ""

            # Extract transcription from output
            lines = result.stdout.strip().split("\n")
            for line in lines:
                if (
                    line
                    and not line.startswith("whisper_")
                    and not line.startswith("ggml_")
                    and not line.startswith("[")
                ):
                    return line.strip()

            return ""

        finally:
            # Clean up temp file
            if os.path.exists(tmp_path):
                os.unlink(tmp_path)
