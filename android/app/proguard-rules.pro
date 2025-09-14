# Flutter-specific ProGuard rules for Tessera Mobile

# Keep Flutter Engine
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep JSON serialization classes
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Keep WebSocket related classes
-keep class ** extends java.net.Socket { *; }
-keep class ** extends javax.net.ssl.SSLSocket { *; }

# Keep connectivity monitoring classes
-keep class android.net.ConnectivityManager { *; }
-keep class android.net.NetworkInfo { *; }

# Preserve line numbers for debugging crashes
-keepattributes SourceFile,LineNumberTable

# Keep custom exception classes
-keep public class * extends java.lang.Exception

# Optimize but don't obfuscate for better crash reports
-dontobfuscate

# Remove debug logging in release
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
    public static int e(...);
}

# Keep native method names
-keepclasseswithmembernames class * {
    native <methods>;
}

# Performance: Remove unused resources
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*