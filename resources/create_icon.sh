#!/bin/bash
# Create a simple app icon from emoji

# Create icon directory
mkdir -p "icon.iconset"

# Generate different sizes using ImageMagick or create from scratch
# Using a simple approach with sips and text

# For now, create a placeholder that tells users to add their own icon
echo "Creating placeholder app icon..."
echo "🎤" | textutil -stdin -stdout -format txt -convert html > /dev/null 2>&1 || true

# Alternative: Create using Swift or just use a placeholder
