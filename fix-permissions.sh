#!/bin/bash

echo "🔧 Fixing Jarvis Voice Permissions..."
echo ""

# First, let's add to accessibility permissions manually
# Note: This requires user approval in System Preferences

echo "📋 Instructions to grant permissions:"
echo ""
echo "1. Open System Preferences → Privacy & Security → Privacy → Accessibility"
echo "2. Click the lock 🔒 and enter your password"
echo "3. Click '+' to add an app"
echo "4. Navigate to: ~/Applications/JarvisVoice/"
echo "5. Select 'python3' from the venv/bin folder"
echo "6. Check the box to enable it"
echo ""
echo "Alternative - Grant via Terminal (requires password):"
echo ""

# Try to add using tccutil (may not work on newer macOS)
# This is a helper script that opens the right settings page

echo "Opening System Preferences..."
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"

echo ""
echo "Please grant Accessibility permission to:"
echo "• Terminal (if running from terminal)"
echo "• Python (if using the .app)"
echo ""
echo "After granting permission, restart Jarvis Voice."
