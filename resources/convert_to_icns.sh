#!/bin/bash
# Convert image to .icns format

if [ -z "$1" ]; then
    echo "Usage: ./convert_to_icns.sh path/to/your/logo.png"
    exit 1
fi

INPUT_IMAGE="$1"
ICONSET_NAME="icon.iconset"

# Create iconset directory
mkdir -p "${ICONSET_NAME}"

# Generate different sizes
sips -z 16 16   "${INPUT_IMAGE}" --out "${ICONSET_NAME}/icon_16x16.png"
sips -z 32 32   "${INPUT_IMAGE}" --out "${ICONSET_NAME}/icon_16x16@2x.png"
sips -z 32 32   "${INPUT_IMAGE}" --out "${ICONSET_NAME}/icon_32x32.png"
sips -z 64 64   "${INPUT_IMAGE}" --out "${ICONSET_NAME}/icon_32x32@2x.png"
sips -z 128 128 "${INPUT_IMAGE}" --out "${ICONSET_NAME}/icon_128x128.png"
sips -z 256 256 "${INPUT_IMAGE}" --out "${ICONSET_NAME}/icon_128x128@2x.png"
sips -z 256 256 "${INPUT_IMAGE}" --out "${ICONSET_NAME}/icon_256x256.png"
sips -z 512 512 "${INPUT_IMAGE}" --out "${ICONSET_NAME}/icon_256x256@2x.png"
sips -z 512 512 "${INPUT_IMAGE}" --out "${ICONSET_NAME}/icon_512x512.png"
sips -z 1024 1024 "${INPUT_IMAGE}" --out "${ICONSET_NAME}/icon_512x512@2x.png"

# Convert to icns
iconutil -c icns "${ICONSET_NAME}" -o AppIcon.icns

# Clean up
rm -rf "${ICONSET_NAME}"

echo "✅ Created AppIcon.icns"
echo "Place this file in the resources/ folder"
