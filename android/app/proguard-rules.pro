# Proguard rules for Nexal App release build minification/shrinking

# Flutter Wrapper / Engine rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }

# Google Play Services / ML Kit Keep Rules
-keep class com.google.android.gms.** { *; }
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.odml.** { *; }

# Speech to Text keep rules
-keep class com.csdcorp.speech_to_text.** { *; }
-keep class class.of.speech.recognition.** { *; }

# WebView Flutter keep rules
-keep class android.webkit.** { *; }
-keep class io.flutter.plugins.webviewflutter.** { *; }

# Audio players JNI and reflect keep rules
-keep class xyz.luan.audioplayers.** { *; }

# Suppress warnings for missing Google Play Core classes (used by Flutter's deferred components wrapper)
-dontwarn com.google.android.play.core.**
