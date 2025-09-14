# Tessera Mobile - Development Guide

> **Note**: This is part of the Tessera multi-repository workspace.  
> For workspace overview and cross-repo operations, see `$TESSERA_WORKSPACE/CLAUDE.md`  
> Default workspace: `/workspace/canvas`

## Development Environment

**Primary Development**: Linux with local Flutter installation
**iOS Testing**: Mac Mini M1 (periodic testing only)
**CI/CD**: GitHub Actions with containerized builds

## Development Workflow

### Local Development (Linux)

```bash
# Install Flutter locally (not containerized for better DX)
flutter doctor

# Run on Android emulator
flutter run -d android

# Run on Chrome for quick UI testing
flutter run -d chrome

# Run tests
flutter test
```

### Platform-Specific Code Philosophy

**CRITICAL**: Write platform-agnostic code by default. Only use platform-specific code when required for:
- Performance optimization (e.g., Metal on iOS, Vulkan on Android)
- Battery efficiency (e.g., background task APIs)
- Native UI patterns (e.g., iOS swipe gestures)

Example structure:
```dart
// Default implementation
class BatteryManager {
  void optimize() => _defaultOptimization();
}

// Only if needed for performance
if (Platform.isIOS) {
  // iOS-specific optimization
} else if (Platform.isAndroid) {
  // Android-specific optimization
}
```

## CI/CD Setup

### GitHub Actions Configuration

```yaml
# .github/workflows/flutter.yml
name: Flutter CI

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter test

  build-android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter build apk

  build-ios:
    runs-on: macos-latest  # Free for public repos
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter build ios --no-codesign
```

**Note**: macOS runners are FREE for public repositories (2,000 minutes/month)

## Testing Strategy

1. **Continuous (Linux)**:
   - Android emulator for mobile features
   - Chrome for responsive design
   - Unit and widget tests

2. **Periodic (Mac Mini M1)**:
   - iOS Simulator testing
   - Performance profiling
   - iOS-specific features

3. **Automated (CI)**:
   - Test on every commit
   - Build validation for both platforms
   - Release builds via GitHub Actions

## Project Structure

```
tessera-mobile/
├── lib/
│   ├── core/           # Platform-agnostic business logic
│   ├── features/       # UI components (minimize platform code)
│   └── platform/       # Platform-specific implementations (only when necessary)
├── test/               # Unit and widget tests
├── integration_test/   # Integration tests
└── .github/workflows/  # CI/CD configuration
```

## Key Commands

```bash
# Development (Linux)
flutter run -d android          # Primary development target
flutter run -d chrome           # Quick UI testing
flutter test                    # Run all tests
flutter analyze                 # Static analysis

# Periodic iOS Testing (Mac Mini)
flutter run -d ios              # iOS Simulator
flutter build ios --simulator   # Build for testing

# Building
flutter build apk --release     # Android release
flutter build ios --release     # iOS release (Mac only)
```

## Performance Guidelines

1. **Rendering**: Use CustomPainter for tile rendering (platform-agnostic)
2. **WebSocket**: Use web_socket_channel (works on all platforms)
3. **Storage**: Use shared_preferences (unified API)
4. **Battery**: Create abstraction layer, implement per-platform only if needed

## Development Rules

1. **Never commit iOS builds from Linux** (they won't work)
2. **Always test on Android first** (primary development platform)
3. **Use CI for iOS validation** (free macOS runners)
4. **Minimize platform-specific code** (only for performance/battery)
5. **Document any platform-specific behavior** in code comments

## Quick Start

```bash
# Clone and setup
git clone git@github.com:paulgid/tessera-mobile.git
cd tessera-mobile
flutter pub get

# Connect to local backend
# Edit lib/core/network/api_client.dart and websocket_manager.dart
# Change localhost:8081 to your backend address

# Run on Android
flutter run -d android

# View available devices
flutter devices
```

## Backend Connection

The app connects to the Tessera backend (default: `localhost:8081`). 
For testing on physical devices, update the host to your machine's IP address.

## Important Notes

- Flutter hot reload works best with local installation (not containerized)
- Android emulator requires KVM on Linux for performance
- iOS development/testing requires macOS (use Mac Mini or CI)
- GitHub Actions provides free macOS runners for public repos
- Focus on platform-agnostic code to minimize testing overhead