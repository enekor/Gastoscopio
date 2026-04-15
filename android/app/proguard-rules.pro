# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# Keep main activity and all classes in app package
-keep class com.N3k0chan.cashly.** { *; }

# Keep NotificationListenerService subclasses (reflectively instantiated by Android)
-keep class * extends android.service.notification.NotificationListenerService { *; }

# Google Play Core (deferred components / split install) — referenced by Flutter
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Firebase (FlutterFire)
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Google Sign-In / Play services
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Kotlin
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings {
    <fields>;
}

# Keep annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Keep JSON model fields (reflection-based serialization)
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# SQLite / Floor
-keep class androidx.room.** { *; }
-keep class * extends androidx.room.RoomDatabase { *; }
-dontwarn androidx.room.paging.**

# Suppress warnings from common libs
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**
