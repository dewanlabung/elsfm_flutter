#!/bin/bash

# ELSFM Flutter - One-Command Deploy Script
# This script helps you build, download, and deploy the APK to USB

set -e

echo "🎵 ELSFM Flutter Deploy Helper"
echo "================================"
echo ""

# Step 1: Check if GitHub remote exists
echo "📌 Step 1: Setting up GitHub..."
if ! git remote | grep -q origin; then
    echo "⚠️  No GitHub remote found."
    echo "Enter your GitHub username (e.g., dewanlabung):"
    read GITHUB_USER

    echo "Setting remote: https://github.com/$GITHUB_USER/elsfm_flutter.git"
    git remote add origin "https://github.com/$GITHUB_USER/elsfm_flutter.git"
fi

# Step 2: Push to GitHub
echo ""
echo "📤 Step 2: Pushing code to GitHub..."
git branch -M main 2>/dev/null || true
git push -u origin main

echo "✅ Code pushed! GitHub Actions should start building automatically."
echo ""
echo "⏳ Build will take ~10-15 minutes."
echo "   Watch progress at: $(git remote get-url origin | sed 's|\.git||')/actions"
echo ""

# Step 3: List USB drives
echo "📱 Step 3: Checking for USB drives..."
echo ""
diskutil list | grep "External"

if [ $? -ne 0 ]; then
    echo "⚠️  No external USB drives detected."
    echo "   Please insert your USB drive and try again."
    exit 1
fi

echo ""
echo "✨ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Wait for GitHub Actions to complete the build"
echo "2. Download the APK from: GitHub Actions > Artifacts"
echo "3. Connect your USB drive"
echo "4. Run: cp ~/Downloads/app-release.apk /Volumes/YOUR_USB_NAME/"
echo "5. Run: adb install /Volumes/YOUR_USB_NAME/app-release.apk"
echo ""
echo "For detailed instructions, see: DEPLOY_GUIDE.md"
