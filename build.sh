#!/bin/bash

# FixFlow App - Quick Build Script
# This script builds both Android and iOS versions of the app

set -e

echo "🚀 FixFlow App Builder"
echo "======================"
echo ""

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed!"
    echo "Please install Flutter first: https://docs.flutter.dev/get-started/install"
    exit 1
fi

echo "✅ Flutter found: $(flutter --version | head -n 1)"
echo ""

# Navigate to project directory
cd "$(dirname "$0")"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Run flutter doctor
echo "🔍 Checking Flutter setup..."
flutter doctor

echo ""
echo "Choose build option:"
echo "1) Android APK"
echo "2) Android App Bundle (AAB)"
echo "3) iOS IPA"
echo "4) Both Android & iOS"
echo "5) Development run"
read -p "Enter choice [1-5]: " choice

case $choice in
    1)
        echo "🤖 Building Android APK..."
        flutter build apk --release
        echo "✅ APK built successfully!"
        echo "📱 Location: build/app/outputs/flutter-apk/app-release.apk"
        ;;
    2)
        echo "🤖 Building Android App Bundle..."
        flutter build appbundle --release
        echo "✅ App Bundle built successfully!"
        echo "📱 Location: build/app/outputs/bundle/release/app-release.aab"
        ;;
    3)
        if [[ "$OSTYPE" == "darwin"* ]]; then
            echo "🍎 Building iOS IPA..."
            flutter build ipa --release
            echo "✅ IPA built successfully!"
            echo "📱 Location: build/ios/ipa/fixflow_app.ipa"
        else
            echo "❌ iOS builds are only available on macOS"
            exit 1
        fi
        ;;
    4)
        echo "🤖 Building Android APK..."
        flutter build apk --release
        
        if [[ "$OSTYPE" == "darwin"* ]]; then
            echo "🍎 Building iOS IPA..."
            flutter build ipa --release
            echo "✅ Both apps built successfully!"
            echo "📱 Android APK: build/app/outputs/flutter-apk/app-release.apk"
            echo "📱 iOS IPA: build/ios/ipa/fixflow_app.ipa"
        else
            echo "✅ Android APK built successfully!"
            echo "📱 Location: build/app/outputs/flutter-apk/app-release.apk"
            echo "⚠️  iOS build skipped (requires macOS)"
        fi
        ;;
    5)
        echo "🏃 Running in development mode..."
        flutter run
        ;;
    *)
        echo "❌ Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "✨ Build completed!"
