# Flutter core and embedding keep rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class com.envivn.envivn.MainActivity { *; }

# Ignore optional Play Store deferred component classes referenced by Flutter embedding
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# Keep Google Play Services / Geolocator reflection hooks
-keep class com.google.android.gms.location.** { *; }
-dontwarn com.google.android.gms.**

# Keep Kotlin coroutines and reflection metadata used by plugins
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod
-keep class kotlin.Metadata { *; }
-dontwarn java.lang.invoke.StringConcatFactory
