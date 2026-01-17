# FixFlow App - Client Management

A Flutter mobile application for managing clients with support for Android and iOS platforms.

## Features

- ✅ Add new clients with details (name, email, phone, company)
- ✅ View all clients in a list
- ✅ Edit existing client information
- ✅ Delete clients
- ✅ Local database storage using SQLite
- ✅ Material Design 3 UI
- ✅ Cross-platform (Android & iOS)

## Prerequisites

Before building the app, ensure you have:

1. **Flutter SDK** installed (version 3.0.0 or higher)
   - Download from: https://flutter.dev/docs/get-started/install
   - Add Flutter to your PATH

2. **Android Development** (for Android builds):
   - Android Studio with Android SDK
   - Java Development Kit (JDK)
   - Accept Android licenses: `flutter doctor --android-licenses`

3. **iOS Development** (for iOS builds, macOS only):
   - Xcode (latest version)
   - CocoaPods: `sudo gem install cocoapods`
   - iOS Developer account (for distribution)

## Setup

1. Install Flutter dependencies:
```bash
flutter pub get
```

2. Verify your setup:
```bash
flutter doctor
```

## Running the App

### Development Mode

Run on connected device or emulator:
```bash
flutter run
```

Run on specific device:
```bash
flutter devices  # List available devices
flutter run -d <device-id>
```

## Building for Production

### Android Build

**Build APK (for testing):**
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

**Build App Bundle (for Play Store):**
```bash
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab`

**Build for specific architecture:**
```bash
# ARM 64-bit (recommended)
flutter build apk --release --target-platform android-arm64

# Split APKs per architecture
flutter build apk --release --split-per-abi
```

### iOS Build

**Build for device:**
```bash
flutter build ios --release
```

**Create IPA file:**
```bash
flutter build ipa --release
```
Output: `build/ios/ipa/fixflow_app.ipa`

**For development testing:**
```bash
flutter build ios --debug
```

## Project Structure

```
lib/
├── main.dart                      # App entry point
├── models/
│   └── client.dart               # Client data model
├── providers/
│   └── client_provider.dart      # State management
├── services/
│   └── database_service.dart     # SQLite operations
└── screens/
    ├── client_list_screen.dart   # Main list view
    └── add_edit_client_screen.dart  # Add/Edit form
```

## Dependencies

- `provider` - State management
- `sqflite` - Local database
- `path_provider` - File system paths
- `intl` - Date formatting

## Troubleshooting

### Flutter not found
Ensure Flutter is in your PATH:
```bash
export PATH="$PATH:`pwd`/flutter/bin"
```

### Android build issues
Clean and rebuild:
```bash
flutter clean
flutter pub get
flutter build apk
```

### iOS build issues
Clean iOS build:
```bash
cd ios
pod install
cd ..
flutter clean
flutter build ios
```

## Testing

Run tests:
```bash
flutter test
```

## Distribution

### Android
- Upload APK for direct distribution
- Upload AAB to Google Play Console for Play Store

### iOS
- Upload IPA to App Store Connect via Xcode or Transporter app
- Requires Apple Developer account

## License

This project is created for demonstration purposes.
