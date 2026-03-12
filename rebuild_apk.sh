#!/bin/bash

# Helper script to configure backend URL and rebuild APK

echo "================================"
echo "Backend URL Configuration"
echo "================================"
echo ""
echo "Your phone IP: 10.73.189.188"
echo ""
echo "Finding your machine IP on the same network..."
echo ""

# Try to find IPs
if command -v ipconfig.exe &> /dev/null; then
    echo "Windows IPs found:"
    ipconfig.exe | grep "IPv4" | grep "10.73"
elif command -v ip &> /dev/null; then
    echo "Linux IPs found:"
    ip addr | grep "inet " | grep "10.73"
fi

echo ""
echo "Please enter your machine's IP address (e.g., 10.73.189.xxx):"
read -r BACKEND_IP

if [ -z "$BACKEND_IP" ]; then
    echo "Error: No IP provided"
    exit 1
fi

# Validate IP format (basic)
if [[ ! $BACKEND_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Invalid IP format"
    exit 1
fi

BACKEND_URL="http://$BACKEND_IP:8080"

echo ""
echo "Updating backend URL to: $BACKEND_URL"

# Update the config file
CONFIG_FILE="client/app/lib/core/config/api_config.dart"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Config file not found: $CONFIG_FILE"
    exit 1
fi

# Backup original file
cp "$CONFIG_FILE" "$CONFIG_FILE.bak"

# Replace the baseUrl line
sed -i "s|static const String baseUrl = '.*';|static const String baseUrl = '$BACKEND_URL';|g" "$CONFIG_FILE"

echo "✓ Configuration updated"
echo ""
echo "Updated file: $CONFIG_FILE"
echo "(Backup saved as: $CONFIG_FILE.bak)"
echo ""
echo "Now building APK..."
echo ""

cd client/app || exit 1

# Run flutter pub get to ensure dependencies are up to date
flutter pub get

# Build APK
flutter build apk --release

if [ $? -eq 0 ]; then
    echo ""
    echo "================================"
    echo "✓ APK built successfully!"
    echo "================================"
    echo ""
    echo "APK location: client/app/build/app/outputs/flutter-apk/app-release.apk"
    echo ""
    echo "To install on your phone:"
    echo "  adb connect 10.73.189.188"
    echo "  adb install -r client/app/build/app/outputs/flutter-apk/app-release.apk"
    echo ""
    echo "Backend configuration:"
    echo "  URL: $BACKEND_URL"
    echo "  Backend is running: docker-compose ps"
    echo ""
else
    echo ""
    echo "✗ Build failed. Check errors above."
    exit 1
fi
