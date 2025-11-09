# ProGuard rules for OmniTAK Mobile Android module

# Keep MapLibre classes
-keep class com.mapbox.** { *; }
-dontwarn com.mapbox.**

-keep class org.maplibre.** { *; }
-dontwarn org.maplibre.**

# Keep OmniTAK custom views (prevent stripping by ProGuard/R8)
-keep @androidx.annotation.Keep class * { *; }

-keep class com.engindearing.omnitak.maplibre.MapLibreMapView { *; }
-keep class com.engindearing.omnitak.maplibre.MapLibreMapViewAttributesBinder { *; }

# Keep Valdi-related classes
-keep class com.snap.valdi.** { *; }
-dontwarn com.snap.valdi.**

# Keep Kotlin metadata
-keep class kotlin.Metadata { *; }

# Keep annotation processors
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}
