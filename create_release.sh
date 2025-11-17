#!/bin/bash

set -e

# Version can be passed as argument, defaults to 1.0.0
VERSION=${1:-"1.0.0"}

echo "🚀 Creating release build v${VERSION}..."
echo ""

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf ClaudeUsageTracker.app ClaudeUsageTracker_binary

# Build the app
echo "🔨 Building app..."
./build.sh

# Create DMG
echo "📦 Creating DMG package..."
./create_dmg.sh "$VERSION"

DMG_NAME="ClaudeUsageTracker-v${VERSION}.dmg"

# Create release notes template
cat > release/RELEASE_NOTES.md << EOF
# Claude Usage Tracker v${VERSION}

## 🎉 What's New

- [Add your changes here]

## 🐛 Bug Fixes

- [Add bug fixes here]

## 📦 Installation

1. Download \`${DMG_NAME}\`
2. Open the DMG file (double-click)
3. Drag \`ClaudeUsageTracker.app\` to the \`Applications\` folder shortcut
4. Remove macOS security block:
   \`\`\`bash
   xattr -cr /Applications/ClaudeUsageTracker.app
   \`\`\`
5. Right-click the app in Applications and select "Open" (first time only)
6. Look for the 💰 icon in your menu bar

## ✅ Verification

**SHA-256 Checksum:**
\`\`\`
$(cat release/${DMG_NAME}.sha256)
\`\`\`

## 📋 Requirements

- macOS 13.0 (Ventura) or later
- Claude Code CLI installed

---

**Full Changelog**: https://github.com/SergioBanuls/ClaudeUsageTracker/compare/v${VERSION}...v${VERSION}
EOF

echo ""
echo "✅ Release v${VERSION} created successfully!"
echo ""
echo "📦 Release package:"
echo "   - DMG: release/${DMG_NAME}"
echo "   - Checksum: release/${DMG_NAME}.sha256"
echo "   - Notes: release/RELEASE_NOTES.md"
echo ""
echo "📋 Next steps:"
echo "   1. Test the DMG:"
echo "      open release/${DMG_NAME}"
echo ""
echo "   2. Verify checksum:"
echo "      cd release && shasum -a 256 -c ${DMG_NAME}.sha256"
echo ""
echo "   3. Create a GitHub release:"
echo "      - Go to https://github.com/SergioBanuls/ClaudeUsageTracker/releases/new"
echo "      - Tag version: v${VERSION}"
echo "      - Upload: release/${DMG_NAME}"
echo "      - Copy contents from: release/RELEASE_NOTES.md"
echo ""
