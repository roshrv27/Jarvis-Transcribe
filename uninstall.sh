#!/bin/bash
echo "Uninstalling Jarvis Voice..."
rm -rf "$HOME/Applications/Jarvis Voice.app"
rm -rf "$HOME/Applications/JarvisVoice"
echo "✅ Jarvis Voice has been uninstalled."
echo "Note: Configuration files in ~/.jarvisvoice were preserved."
echo "To remove them, run: rm -rf ~/.jarvisvoice"
