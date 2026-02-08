#!/usr/bin/env python3
"""
setup.py for Jarvis Voice
Used with py2app to create standalone macOS application
"""

from setuptools import setup
import os
import sys
import shutil

# Ensure we're in the right directory
os.chdir(os.path.dirname(os.path.abspath(__file__)))

# Application metadata
APP_NAME = "Jarvis Voice"
APP_SCRIPT = ["src/main.py"]
VERSION = "1.3"

# Data files to include
DATA_FILES = [
    ("whisper_cpp_wrapper.py", "."),
    ("requirements.txt", "."),
]

# Check for whisper.cpp models
whisper_models = []
if os.path.exists("whisper.cpp/models"):
    for model_file in os.listdir("whisper.cpp/models"):
        if model_file.endswith(".bin"):
            whisper_models.append((f"whisper.cpp/models/{model_file}", "models"))
            print(f"Including model: {model_file}")

if whisper_models:
    DATA_FILES.extend(whisper_models)
else:
    print("WARNING: No whisper.cpp models found!")
    print("The app will need to download models on first run.")

# py2app options
OPTIONS = {
    "argv_emulation": True,
    "packages": ["rumps", "sounddevice", "numpy", "pynput"],
    "includes": [
        "whisper_cpp_wrapper",
        "threading",
        "json",
        "time",
        "re",
        "pathlib",
        "subprocess",
        "collections",
    ],
    "excludes": ["tkinter", "matplotlib", "PyQt5", "PyQt6"],
    "iconfile": "AppIcon.icns" if os.path.exists("AppIcon.icns") else None,
    "plist": {
        "CFBundleName": APP_NAME,
        "CFBundleShortVersionString": VERSION,
        "CFBundleVersion": VERSION,
        "CFBundleIdentifier": "com.jarvisvoice.app",
        "NSHighResolutionCapable": True,
        "NSMicrophoneUsageDescription": "Jarvis Voice needs microphone access to transcribe your speech.",
        "NSAccessibilityUsageDescription": "Jarvis Voice needs accessibility access to type transcribed text into other applications.",
        "LSMinimumSystemVersion": "10.15",
    },
    "strip": True,
    "optimize": 2,
}

setup(
    name=APP_NAME,
    version=VERSION,
    app=APP_SCRIPT,
    data_files=DATA_FILES,
    options={"py2app": OPTIONS},
    setup_requires=["py2app"],
    install_requires=[
        "rumps",
        "sounddevice",
        "numpy",
        "pynput",
    ],
)
