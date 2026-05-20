#!/usr/bin/env bash
# AuraSound - Setup Script
# Run: chmod +x setup.sh && ./setup.sh

set -e

echo ""
echo "  ╔═══════════════════════════════════╗"
echo "  ║      AuraSound — Setup Script     ║"
echo "  ╚═══════════════════════════════════╝"
echo ""

# Check Flutter
if ! command -v flutter &> /dev/null; then
  echo "❌  Flutter not found. Install from https://flutter.dev"
  exit 1
fi

echo "✅  Flutter found: $(flutter --version | head -1)"

# Create asset directories
echo ""
echo "📁  Creating asset directories..."
mkdir -p assets/images
mkdir -p assets/icons
mkdir -p assets/animations
mkdir -p assets/fonts

# Create placeholder images
echo "🖼   Creating placeholder assets..."
touch assets/images/.gitkeep
touch assets/icons/.gitkeep
touch assets/animations/.gitkeep

# Download Inter font via curl if available
if command -v curl &> /dev/null; then
  echo ""
  echo "🔤  Attempting to download Inter font..."

  FONT_BASE="https://github.com/rsms/inter/releases/download/v4.0"

  download_font() {
    local url="$1"
    local dest="$2"
    if [ ! -f "$dest" ]; then
      curl -sL "$url" -o "$dest" && echo "  ✅  Downloaded $dest" || echo "  ⚠️   Could not download $dest"
    else
      echo "  ⏭   Already exists: $dest"
    fi
  }

  # Use Google Fonts CDN as fallback
  GFONTS="https://fonts.gstatic.com/s/inter/v13"
  download_font "${GFONTS}/UcCO3FwrK3iLTeHuS_fvQtMwCp50KnMw2boKoduKmMEVuLyfAZ9hiJ-Ek-_EeA.woff2" "assets/fonts/Inter-Regular.ttf" || true
  echo "  ℹ️   Please manually place Inter font TTF files in assets/fonts/"
  echo "      Download: https://fonts.google.com/specimen/Inter"
  echo "      Files needed:"
  echo "        - Inter-Regular.ttf"
  echo "        - Inter-Medium.ttf"
  echo "        - Inter-SemiBold.ttf"
  echo "        - Inter-Bold.ttf"
  echo "        - Inter-ExtraBold.ttf"
fi

# Install dependencies
echo ""
echo "📦  Running flutter pub get..."
flutter pub get

# Check for issues
echo ""
echo "🔍  Running flutter doctor..."
flutter doctor

echo ""
echo "╔═══════════════════════════════════════════════════╗"
echo "║               Setup Complete! 🎵                  ║"
echo "╠═══════════════════════════════════════════════════╣"
echo "║  Next steps:                                      ║"
echo "║  1. Place Inter font files in assets/fonts/       ║"
echo "║  2. Configure Spotify credentials in:             ║"
echo "║     lib/core/constants/app_constants.dart         ║"
echo "║  3. Run: flutter run -d android                   ║"
echo "║          flutter run -d windows                   ║"
echo "║          flutter run -d chrome                    ║"
echo "╚═══════════════════════════════════════════════════╝"
echo ""
