# Android Setup Guide for Tessera Mobile

## Prerequisites

### 1. Java 11 or Higher
```bash
# Check Java version
java -version

# Install Java 11 if needed (Ubuntu/Debian)
sudo apt-get update
sudo apt-get install openjdk-11-jdk

# Set JAVA_HOME
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
export PATH=$PATH:$JAVA_HOME/bin
```

### 2. Android SDK Components
```bash
# Accept Android licenses
flutter doctor --android-licenses

# Install required SDK components
sdkmanager "platform-tools" "platforms;android-33" "build-tools;33.0.0"
sdkmanager "system-images;android-33;google_apis;x86_64"
```

## Setting Up Android Emulator

### Option 1: Using Flutter Commands
```bash
# Create emulator
flutter emulators --create --name tessera_pixel

# Launch emulator
flutter emulators --launch tessera_pixel

# List available emulators
flutter emulators
```

### Option 2: Using AVD Manager
```bash
# Create AVD (Android Virtual Device)
avdmanager create avd \
    -n tessera_emulator \
    -k "system-images;android-33;google_apis;x86_64" \
    -d "pixel_4"

# Start emulator
emulator -avd tessera_emulator
```

### Option 3: Android Studio
1. Open Android Studio
2. Go to Tools → AVD Manager
3. Click "Create Virtual Device"
4. Select a device (e.g., Pixel 4)
5. Download and select a system image (API 33 recommended)
6. Name it "tessera_emulator"
7. Click "Finish" and then "Play" to start

## Running Tessera Mobile on Android

### 1. Start the Backend
```bash
cd $TESSERA_WORKSPACE/tessera
make docker-dev
# Backend will be available at localhost:8081
```

### 2. Run the Flutter App
```bash
cd $TESSERA_WORKSPACE/tessera-mobile

# Get dependencies
flutter pub get

# Run on emulator (debug mode with hot reload)
flutter run

# Or specify device if multiple are connected
flutter run -d emulator-5554
```

### 3. Build APK
```bash
# Debug APK (for testing)
flutter build apk --debug

# Release APK (optimized)
flutter build apk --release

# Install APK on connected device
flutter install
```

## Network Configuration

The app automatically detects Android emulator and uses the correct IP:
- **Emulator**: `10.0.2.2:8081` (host machine's localhost)
- **Physical Device**: Configure actual IP in `network_config.dart`

## Testing on Physical Device

### 1. Enable Developer Options
- Go to Settings → About Phone
- Tap "Build Number" 7 times
- Go back to Settings → Developer Options
- Enable "USB Debugging"

### 2. Connect and Run
```bash
# Check device is connected
flutter devices

# Run on physical device
flutter run -d <device-id>
```

### 3. Network Configuration for Physical Device
Edit `lib/core/config/network_config.dart`:
```dart
// Replace with your machine's IP address
static const String _devServerIp = '192.168.1.100';
```

## Troubleshooting

### Problem: Emulator won't start
```bash
# Enable KVM acceleration (Linux)
sudo modprobe kvm
sudo modprobe kvm_intel  # or kvm_amd

# Check KVM is available
kvm-ok
```

### Problem: Connection refused
1. Ensure backend is running: `docker ps`
2. Check emulator is using `10.0.2.2` for localhost
3. Verify network permissions in AndroidManifest.xml

### Problem: Build fails with Java version error
```bash
# Set Java 11 as default
sudo update-alternatives --config java
# Select Java 11 from the list
```

### Problem: Slow emulator performance
```bash
# Use hardware acceleration
emulator -avd tessera_emulator -gpu host

# Allocate more RAM
emulator -avd tessera_emulator -memory 2048
```

## Performance Tips

1. **Use x86_64 images** for better performance on Intel/AMD CPUs
2. **Enable hardware acceleration** (HAXM on Windows/Mac, KVM on Linux)
3. **Allocate sufficient RAM** (2GB minimum, 4GB recommended)
4. **Use physical device** for best performance testing

## Quick Commands Reference

```bash
# Check setup
flutter doctor

# List devices
flutter devices

# Run app
flutter run

# Hot reload (while app is running)
r

# Hot restart
R

# Quit
q

# Build APK
flutter build apk

# Clean build
flutter clean

# Get dependencies
flutter pub get
```

## Next Steps

1. Run `flutter doctor` to verify setup
2. Create an Android emulator
3. Start the backend server
4. Run the Flutter app
5. Test mosaic functionality

The app is now fully configured for Android development with automatic emulator detection and optimized network configuration!