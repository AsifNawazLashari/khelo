#!/bin/bash
# Run this from your project root in Codespace:
#   bash setup_icon.sh
set -e

S=1024
echo "=== Generating A Browser launcher icon ==="

# White background square
convert -size ${S}x${S} xc:white /tmp/bg.png

# Blue globe radial gradient
convert -size ${S}x${S} \
  radial-gradient:"#60C8FF-#0D47A1" \
  -gravity Center \
  \( -size 730x730 xc:none -fill white -draw "circle 365,365 365,0" \) \
  -compose DstIn -composite \
  /tmp/globe.png

# Green orbit ellipse
convert -size ${S}x${S} xc:none \
  -stroke "#34D399" -strokewidth 48 -fill none \
  -draw "ellipse 491,533 450,170 0,360" \
  -background none -rotate 330 \
  -gravity center -extent ${S}x${S} \
  /tmp/green_orbit.png

# Blue orbit ellipse
convert -size ${S}x${S} xc:none \
  -stroke "#1565C0" -strokewidth 38 -fill none \
  -draw "ellipse 491,533 190,450 0,360" \
  -background none -rotate 52 \
  -gravity center -extent ${S}x${S} \
  /tmp/blue_orbit.png

# Letter A
convert -size ${S}x${S} xc:none \
  -fill white \
  -font DejaVu-Sans-Bold -pointsize 220 \
  -gravity center \
  -annotate 0 "A" \
  /tmp/letter_a.png

# Arrow
convert -size ${S}x${S} xc:none \
  -stroke "#34D399" -strokewidth 48 \
  -draw "line 614,399 870,143" \
  -fill "#34D399" -stroke none \
  -draw "polygon 870,143 748,143 870,265" \
  /tmp/arrow.png

# Composite all layers
convert /tmp/bg.png \
  /tmp/globe.png       -gravity center -composite \
  /tmp/green_orbit.png -gravity center -composite \
  /tmp/blue_orbit.png  -gravity center -composite \
  /tmp/letter_a.png    -gravity center -composite \
  /tmp/arrow.png       -gravity center -composite \
  /tmp/icon_1024.png

echo "✓ Icon generated"

# Copy to assets folder (for flutter_launcher_icons)
mkdir -p assets
cp /tmp/icon_1024.png assets/icon.png
echo "✓ Copied to assets/icon.png"

# Append flutter_launcher_icons config to pubspec.yaml (only if not already there)
if ! grep -q "flutter_launcher_icons:" pubspec.yaml; then
cat >> pubspec.yaml << 'EOF'

flutter_launcher_icons:
  android: true
  ios: false
  image_path: "assets/icon.png"
  min_sdk_android: 21
EOF
echo "✓ Added flutter_launcher_icons config to pubspec.yaml"
else
  echo "✓ flutter_launcher_icons already in pubspec.yaml"
fi

# Run the icon generator
echo "=== Running flutter_launcher_icons ==="
dart run flutter_launcher_icons

echo ""
echo "=== All done! Now build: ==="
echo "flutter clean && flutter build apk --release"
