# Android Emulator Configuration for Tessera Mobile

This document outlines all Android-specific configurations implemented to run the Tessera Flutter app on Android emulator with proper backend connectivity.

## Network Configuration

### 1. Platform-Aware Network URLs (`lib/core/config/network_config.dart`)

- **Android Emulator**: Uses `10.0.2.2` to connect to host machine's localhost
- **iOS Simulator**: Uses standard `localhost`
- **Production**: Uses production host
- **Automatic Detection**: Platform detection with fallbacks

### 2. Updated API Client (`lib/core/network/api_client.dart`)

- Uses `NetworkConfig.getBaseUrl()` for platform-specific base URLs
- Platform-aware timeouts (longer for emulators)
- Automatic HTTP configuration

### 3. Updated WebSocket Manager (`lib/core/network/websocket_manager.dart`)

- Platform-specific WebSocket URLs via `NetworkConfig.getWebSocketUrl()`
- Adaptive reconnection delays for emulator development
- Mobile-optimized ping intervals

## Android Permissions (`android/app/src/main/AndroidManifest.xml`)

```xml
<!-- Network permissions -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />

<!-- Network security configuration -->
<application
    android:networkSecurityConfig="@xml/network_security_config"
    android:usesCleartextTraffic="true">
```

## Network Security Configuration

### File: `android/app/src/main/res/xml/network_security_config.xml`

- Allows cleartext traffic to Android emulator IP `10.0.2.2`
- Allows localhost and local network IPs for development
- Secure configuration for production builds
- Debug overrides for development certificates

## Build Configuration (`android/app/build.gradle.kts`)

### Debug Build Optimizations

- `applicationIdSuffix = ".debug"` for side-by-side installation
- `usesCleartextTraffic = "true"` for development
- MultiDex support for large apps
- Hardware acceleration enabled

### Performance Optimizations

- Vector drawable support
- ProGuard configuration for release builds
- Package optimization settings
- Memory management settings

## Mobile Services

### 1. Platform Service (`lib/core/services/platform_service.dart`)

- Android emulator detection
- Device capabilities assessment (RAM, API level, hardware acceleration)
- Performance tier classification
- Platform-specific optimizations

### 2. Battery Service (`lib/core/services/battery_service.dart`)

- Battery level monitoring
- Performance profiles based on battery state
- Adaptive quality settings
- Power-saving modes for mobile devices

### 3. Connection Monitor (`lib/core/services/connection_monitor.dart`)

- Network quality assessment
- Mobile vs WiFi optimization
- Latency monitoring with mobile-specific thresholds
- Connection type detection

### 4. Debug Information (`lib/core/utils/debug_info.dart`)

- Comprehensive debug info for troubleshooting
- Network connectivity testing
- Android emulator specific information
- Real-time diagnostic data

## ProGuard Rules (`android/app/proguard-rules.pro`)

- Flutter engine protection
- WebSocket and network class preservation
- JSON serialization support
- Debug information preservation
- Mobile-specific optimizations

## Development Features

### Debug Panel

- Real-time network quality display
- Battery status monitoring
- Connection troubleshooting tools
- Performance metrics

### Automatic Initialization

- Services initialize on app startup
- Error handling for missing permissions
- Graceful degradation on service failures
- Debug logging for development

## Usage in Android Emulator

### Backend Connection

1. Start the Tessera backend on host machine: `make docker-dev` (port 8081)
2. The app automatically connects to `http://10.0.2.2:8081` on Android emulator
3. WebSocket connects to `ws://10.0.2.2:8081/ws`

### Network Testing

The app includes built-in network testing:

```dart
// Test connectivity from within the app
final results = await DebugInfo.testConnectivity();
print('Socket test: ${results['socketTest']}');
print('HTTP test: ${results['httpTest']}');
```

### Debugging

Enable debug mode to see:

- Network configuration details
- Connection quality metrics
- Battery optimization status
- Platform-specific settings

## Mobile Performance Optimizations

### Memory Management

- Adaptive memory limits based on device RAM
- Object pooling for frequent allocations
- Garbage collection hints
- Virtual scrolling for large lists

### Network Optimization

- Compression for mobile data connections
- Adaptive update intervals based on connection quality
- Aggressive reconnection for mobile network transitions
- Battery-aware networking

### Rendering Optimization

- GPU acceleration when available
- Adaptive quality based on device performance
- Battery-conscious frame rate targeting
- Efficient tile rendering with viewport culling

## Troubleshooting

### Common Issues

1. **Connection Refused**: Ensure backend is running on host machine port 8081
2. **Cleartext Not Permitted**: Check network security config is properly applied
3. **DNS Resolution**: Android emulator uses `10.0.2.2`, not `localhost`
4. **Performance Issues**: Check battery service for performance profile

### Debug Commands

```bash
# Check emulator network
adb shell ping 10.0.2.2

# View app logs
flutter logs

# Check network security
adb shell dumpsys package com.tessera.tessera_mobile.debug | grep -i network
```

## Production Considerations

- Network security config automatically disables cleartext traffic in release builds
- Battery service provides production-optimized performance profiles
- Connection monitor adapts to real mobile network conditions
- All debug features are disabled in release mode

This configuration ensures optimal performance on Android emulator while providing production-ready mobile optimizations for real devices.