# Flutter — keep generated code
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Supabase / Ktor (HTTP client)
-keep class io.github.jan.supabase.** { *; }
-keep class io.ktor.** { *; }
-dontwarn io.ktor.**

# WebRTC
-keep class org.webrtc.** { *; }
-dontwarn org.webrtc.**

# Google Sign-In
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# record package (audio recording)
-keep class com.llfbandit.record.** { *; }

# Kotlin coroutines
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
-keepclassmembernames class kotlinx.** {
    volatile <fields>;
}

# Keep Kotlin metadata
-keepattributes *Annotation*, Signature, Exception, InnerClasses, EnclosingMethod
