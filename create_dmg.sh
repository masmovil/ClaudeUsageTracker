#!/bin/bash

# Script to create a professional DMG file for ClaudeUsageTracker
# Usage: ./create_dmg.sh <version>
# Example: ./create_dmg.sh 1.0.0

set -e

VERSION=${1:-"1.0.0"}
APP_NAME="ClaudeUsageTracker"
DMG_NAME="${APP_NAME}-v${VERSION}"
APP_PATH="${APP_NAME}.app"

echo "📦 Creating DMG for ${APP_NAME} v${VERSION}..."

# Check if app exists
if [ ! -d "$APP_PATH" ]; then
    echo "❌ Error: ${APP_PATH} not found. Build the app first with ./build.sh"
    exit 1
fi

# Create release directory
mkdir -p release

# Create temporary directory for DMG contents
TMP_DMG_DIR="tmp_dmg"
rm -rf "$TMP_DMG_DIR"
mkdir -p "$TMP_DMG_DIR"

echo "📋 Copying app to temporary directory..."
cp -R "$APP_PATH" "$TMP_DMG_DIR/"

echo "🔗 Creating Applications symlink..."
ln -s /Applications "$TMP_DMG_DIR/Applications"

echo "📝 Creating README..."
cat > "$TMP_DMG_DIR/READ ME FIRST.txt" << 'EOF'
Claude Usage Tracker - Installation Instructions

IMPORTANT: macOS Security Notice
==================================
Since this app is not signed with an Apple Developer certificate,
macOS will block it by default with a "damaged" error message.

Quick Installation (3 steps):
==============================

Step 1: Install to Applications
---------------------------------
→ Drag ClaudeUsageTracker.app to the Applications folder shortcut
→ Wait for the copy to complete

Step 2: Remove Security Block
-------------------------------
→ Open Terminal (Applications > Utilities > Terminal)
→ Copy and paste this command:

   xattr -cr /Applications/ClaudeUsageTracker.app

→ Press Enter

Step 3: Open the App
---------------------
→ Go to Applications folder (⌘ + Shift + A)
→ Right-click ClaudeUsageTracker.app
→ Select "Open" from the menu
→ Click "Open" again when the warning appears
→ Look for the 💰 icon in your menu bar

For detailed instructions and troubleshooting:
https://github.com/masmovil/ClaudeUsageTracker

Enjoy tracking your Claude Code usage! 🎉
EOF

# Create temporary DMG
TMP_DMG="tmp_${DMG_NAME}.dmg"
FINAL_DMG="release/${DMG_NAME}.dmg"

echo "🔨 Creating temporary DMG..."
rm -f "$TMP_DMG"
hdiutil create -srcfolder "$TMP_DMG_DIR" \
    -volname "$APP_NAME" \
    -fs HFS+ \
    -format UDRW \
    "$TMP_DMG"

echo "📐 Mounting DMG to set layout..."
MOUNT_DIR="/Volumes/$APP_NAME"
hdiutil attach "$TMP_DMG" -mountpoint "$MOUNT_DIR"

# Wait a moment for the volume to mount
sleep 2

# Set window properties and icon positions using AppleScript
echo "🎨 Setting DMG window layout..."
osascript <<EOF
tell application "Finder"
    tell disk "$APP_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {400, 100, 1000, 550}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 100
        set position of item "${APP_NAME}.app" of container window to {150, 200}
        set position of item "Applications" of container window to {450, 200}
        set position of item "READ ME FIRST.txt" of container window to {300, 350}
        close
        open
        update without registering applications
        delay 2
    end tell
end tell
EOF

# Sync to ensure changes are written
sync

echo "💿 Unmounting temporary DMG..."
hdiutil detach "$MOUNT_DIR"

echo "🗜️  Converting to compressed DMG..."
rm -f "$FINAL_DMG"
hdiutil convert "$TMP_DMG" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -o "$FINAL_DMG"

# Cleanup
echo "🧹 Cleaning up temporary files..."
rm -f "$TMP_DMG"
rm -rf "$TMP_DMG_DIR"

# Generate checksum
echo "🔐 Generating SHA-256 checksum..."
cd release
shasum -a 256 "${DMG_NAME}.dmg" > "${DMG_NAME}.dmg.sha256"
cd ..

echo ""
echo "✅ DMG created successfully!"
echo ""
echo "📦 File: release/${DMG_NAME}.dmg"
echo "🔐 Checksum: release/${DMG_NAME}.dmg.sha256"
echo ""
echo "SHA-256:"
cat "release/${DMG_NAME}.dmg.sha256"
echo ""
echo "📝 Next steps:"
echo "   1. Test the DMG: open release/${DMG_NAME}.dmg"
echo "   2. Upload to GitHub releases"
echo "   3. Include the SHA-256 checksum in release notes"
echo ""
