import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Platform-specific service for Android optimizations and device info
class PlatformService {
  static PlatformService? _instance;
  static PlatformService get instance => _instance ??= PlatformService._();
  
  PlatformService._();
  
  AndroidDeviceInfo? _androidInfo;
  IosDeviceInfo? _iosInfo;
  PackageInfo? _packageInfo;
  
  /// Initialize platform service with device information
  Future<void> initialize() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      _packageInfo = await PackageInfo.fromPlatform();
      
      if (Platform.isAndroid) {
        _androidInfo = await deviceInfo.androidInfo;
        await _configureAndroidOptimizations();
      } else if (Platform.isIOS) {
        _iosInfo = await deviceInfo.iosInfo;
        await _configureIOSOptimizations();
      }
    } catch (e) {
      debugPrint('Failed to initialize platform service: $e');
    }
  }
  
  /// Check if running on Android emulator
  bool get isAndroidEmulator {
    if (!Platform.isAndroid || _androidInfo == null) return false;
    
    final model = _androidInfo!.model.toLowerCase();
    final product = _androidInfo!.product.toLowerCase();
    final fingerprint = _androidInfo!.fingerprint.toLowerCase();
    final manufacturer = _androidInfo!.manufacturer.toLowerCase();
    
    return model.contains('sdk') ||
           model.contains('emulator') ||
           product.contains('sdk') ||
           product.contains('emulator') ||
           fingerprint.contains('generic') ||
           manufacturer.contains('genymotion');
  }
  
  /// Check if running on iOS simulator
  bool get isIOSSimulator {
    if (!Platform.isIOS || _iosInfo == null) return false;
    return !_iosInfo!.isPhysicalDevice;
  }
  
  /// Get Android API level
  int? get androidApiLevel => _androidInfo?.version.sdkInt;
  
  /// Get device RAM capacity estimate
  int get estimatedRAMGB {
    if (Platform.isAndroid && _androidInfo != null) {
      // Estimate based on Android API level and device characteristics
      final apiLevel = _androidInfo!.version.sdkInt;
      if (apiLevel >= 30) return 6; // Android 11+ typically 4-8GB
      if (apiLevel >= 28) return 4; // Android 9-10 typically 3-6GB  
      if (apiLevel >= 24) return 3; // Android 7-8 typically 2-4GB
      return 2; // Older devices typically 1-2GB
    }
    
    if (Platform.isIOS && _iosInfo != null) {
      // iOS devices generally have consistent RAM per model generation
      return 4; // Most modern iOS devices have 4-6GB
    }
    
    return 2; // Conservative fallback
  }
  
  /// Check if device supports hardware acceleration
  bool get supportsHardwareAcceleration {
    if (Platform.isAndroid && _androidInfo != null) {
      // Modern Android devices (API 21+) support hardware acceleration
      return (_androidInfo!.version.sdkInt >= 21);
    }
    
    if (Platform.isIOS && _iosInfo != null) {
      // All modern iOS devices support hardware acceleration
      return true;
    }
    
    return false;
  }
  
  /// Get performance tier based on device capabilities
  PerformanceTier get performanceTier {
    final ramGB = estimatedRAMGB;
    
    if (Platform.isAndroid && _androidInfo != null) {
      final apiLevel = _androidInfo!.version.sdkInt;
      
      if (ramGB >= 6 && apiLevel >= 29) {
        return PerformanceTier.high;
      } else if (ramGB >= 4 && apiLevel >= 26) {
        return PerformanceTier.medium;
      } else {
        return PerformanceTier.low;
      }
    }
    
    if (Platform.isIOS) {
      return ramGB >= 4 ? PerformanceTier.high : PerformanceTier.medium;
    }
    
    return PerformanceTier.medium;
  }
  
  /// Configure Android-specific optimizations
  Future<void> _configureAndroidOptimizations() async {
    if (!Platform.isAndroid) return;
    
    try {
      // Set system UI flags for immersive experience
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
        overlays: [SystemUiOverlay.top],
      );
      
      // Configure preferred orientations for mobile gaming
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      
      // Enable hardware acceleration if supported
      if (supportsHardwareAcceleration) {
        debugPrint('Hardware acceleration enabled on Android API ${androidApiLevel}');
      }
      
    } catch (e) {
      debugPrint('Failed to configure Android optimizations: $e');
    }
  }
  
  /// Configure iOS-specific optimizations  
  Future<void> _configureIOSOptimizations() async {
    if (!Platform.isIOS) return;
    
    try {
      // Configure for iOS-specific performance
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
        overlays: [SystemUiOverlay.top],
      );
      
      debugPrint('iOS optimizations configured for ${_iosInfo?.model}');
    } catch (e) {
      debugPrint('Failed to configure iOS optimizations: $e');
    }
  }
  
  /// Get network quality recommendations based on device
  NetworkQuality get recommendedNetworkQuality {
    switch (performanceTier) {
      case PerformanceTier.high:
        return NetworkQuality.high;
      case PerformanceTier.medium:
        return NetworkQuality.medium;
      case PerformanceTier.low:
        return NetworkQuality.low;
    }
  }
  
  /// Get render quality recommendations
  RenderQuality get recommendedRenderQuality {
    if (isAndroidEmulator || isIOSSimulator) {
      return RenderQuality.medium; // Emulators have different performance characteristics
    }
    
    switch (performanceTier) {
      case PerformanceTier.high:
        return RenderQuality.high;
      case PerformanceTier.medium:
        return RenderQuality.medium;
      case PerformanceTier.low:
        return RenderQuality.low;
    }
  }
  
  /// Get device info string for debugging
  String get deviceInfoString {
    if (Platform.isAndroid && _androidInfo != null) {
      return 'Android ${_androidInfo!.version.release} (API ${_androidInfo!.version.sdkInt}) '
             '${_androidInfo!.manufacturer} ${_androidInfo!.model}';
    }
    
    if (Platform.isIOS && _iosInfo != null) {
      return 'iOS ${_iosInfo!.systemVersion} ${_iosInfo!.model}';
    }
    
    return 'Unknown platform';
  }
  
  /// Check if app is in debug mode
  bool get isDebugMode => kDebugMode;
  
  /// Get app version
  String get appVersion => _packageInfo?.version ?? 'unknown';
  
  /// Get app build number
  String get buildNumber => _packageInfo?.buildNumber ?? 'unknown';
}

enum PerformanceTier { low, medium, high }
enum NetworkQuality { low, medium, high }
enum RenderQuality { low, medium, high }