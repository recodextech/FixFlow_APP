# FixFlow App Setup & Build Guide

## Step 1: Install Flutter

Since Flutter is not currently installed on your system, follow these steps:

### macOS Installation

1. **Download Flutter SDK:**
   ```bash
   cd ~/development
   curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_arm64_3.24.5-stable.zip
   unzip flutter_macos_arm64_3.24.5-stable.zip
   ```
   
   Or download from: https://docs.flutter.dev/get-started/install/macos

2. **Add Flutter to PATH:**
   ```bash
   export PATH="$PATH:$HOME/development/flutter/bin"
   ```
   
   Add this to your shell profile (~/.zshrc):
   ```bash
   echo 'export PATH="$PATH:$HOME/development/flutter/bin"' >> ~/.zshrc
   source ~/.zshrc
   ```

3. **Verify installation:**
   ```bash
   flutter --version
   flutter doctor
   ```

4. **Install dependencies:**
   ```bash
   flutter doctor --android-licenses  # Accept Android licenses
   ```

## Step 2: Setup Development Tools

### For Android Development:
- Install Android Studio from: https://developer.android.com/studio
- Open Android Studio → Preferences → Plugins → Install Flutter and Dart plugins
- Install Android SDK and accept licenses

### For iOS Development (macOS only):
- Install Xcode from App Store
- Install command line tools:
  ```bash
  sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
  sudo xcodebuild -runFirstLaunch
  ```
- Install CocoaPods:
  ```bash
  sudo gem install cocoapods
  ```

## Step 3: Install Project Dependencies

Navigate to the project directory and install dependencies:

```bash
cd /Users/damindu/Personal/go/src/github.com/recodextech/fixflow-app
flutter pub get
```

## Step 4: Run the App in Development

### On Android Emulator:
```bash
# Start Android Emulator from Android Studio or use:
flutter emulators --launch <emulator_id>

# Run the app
flutter run
```

### On iOS Simulator (macOS only):
```bash
# List available simulators
xcrun simctl list devices

# Start a simulator
open -a Simulator

# Run the app
flutter run
```

### On Physical Device:
```bash
# List connected devices
flutter devices

# Run on specific device
flutter run -d <device-id>
```

## Step 5: Build Production Apps

### Android Builds

#### Option 1: Build APK (for direct installation)
```bash
# Build release APK
flutter build apk --release

# Output location:
# build/app/outputs/flutter-apk/app-release.apk
```

#### Option 2: Build App Bundle (for Google Play Store)
```bash
# Build release App Bundle
flutter build appbundle --release

# Output location:
# build/app/outputs/bundle/release/app-release.aab
```

#### Build for specific architecture:
```bash
# ARM 64-bit (most modern devices)
flutter build apk --release --target-platform android-arm64

# Split APKs per architecture (recommended for Play Store)
flutter build apk --release --split-per-abi
```

### iOS Builds (macOS only)

#### Option 1: Build for Testing
```bash
# Build iOS app
flutter build ios --release

# Open in Xcode to install on device
open ios/Runner.xcworkspace
```

#### Option 2: Build IPA for Distribution
```bash
# Build IPA file
flutter build ipa --release

# Output location:
# build/ios/ipa/fixflow_app.ipa
```

## Step 6: Install APK on Android Device

### Via USB:
```bash
# Install the APK
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Via File Transfer:
1. Copy `build/app/outputs/flutter-apk/app-release.apk` to your device
2. Open the APK file on your device
3. Allow installation from unknown sources if prompted
4. Install the app

## Step 7: Distribute iOS App

### For testing (TestFlight):
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select "Any iOS Device" as target
3. Product → Archive
4. Upload to App Store Connect
5. Add testers in TestFlight

### For App Store:
1. Create app in App Store Connect
2. Archive and upload via Xcode
3. Submit for review

## Troubleshooting

### Flutter not found after installation:
```bash
which flutter
echo $PATH
# Add Flutter to PATH in ~/.zshrc
```

### Android build issues:
```bash
flutter clean
flutter pub get
cd android && ./gradlew clean
cd .. && flutter build apk
```

### iOS build issues:
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter clean
flutter build ios
```

### Device not detected:
```bash
# Android
adb devices
adb kill-server && adb start-server

# iOS
idevice_id -l
```

## Quick Build Commands Summary

```bash
# Get dependencies
flutter pub get

# Run in development
flutter run

# Build Android APK
flutter build apk --release

# Build Android App Bundle
flutter build appbundle --release

# Build iOS IPA
flutter build ipa --release

# Clean project
flutter clean
```

## App Features

✅ Add clients (Name, Email, Phone, Company)
✅ View all clients in a list
✅ Edit client information
✅ Delete clients
✅ Local SQLite database
✅ Material Design 3 UI
✅ Cross-platform (Android & iOS)

## Next Steps

1. Install Flutter SDK
2. Run `flutter doctor` to verify setup
3. Navigate to project directory
4. Run `flutter pub get`
5. Test with `flutter run`
6. Build production apps with commands above

For more help, visit: https://docs.flutter.dev/
