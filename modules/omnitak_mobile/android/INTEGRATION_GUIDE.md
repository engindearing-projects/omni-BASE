# MapLibre Android Integration - Quick Start Guide

Step-by-step guide to integrate MapLibre GL Native into your Valdi-based OmniTAK Mobile app.

## Prerequisites

- Android Studio Arctic Fox or later
- Minimum SDK: 21 (Android 5.0)
- Target SDK: 34 (Android 14)
- Kotlin 1.8.0+
- Valdi framework installed

## Step 1: Add Dependencies

### Option A: Using Gradle (Recommended)

Add to your app's `build.gradle`:

```gradle
repositories {
    maven {
        url 'https://maven.mapbox.com/releases/com/mapbox/mapboxsdk/'
    }
}

dependencies {
    implementation 'org.maplibre.gl:android-sdk:11.8.0'
    implementation 'org.maplibre.gl:android-plugin-annotation-v9:3.0.0'
}
```

### Option B: Using Bazel

Add to your `BUILD.bazel`:

```python
android_library(
    name = "maplibre",
    srcs = glob(["maplibre/*.kt"]),
    deps = [
        "@maven//:org_maplibre_gl_android_sdk",
        "@maven//:org_maplibre_gl_android_plugin_annotation_v9",
        "//valdi_core:valdi_core_android",
    ],
)
```

## Step 2: Add Permissions

Add to your `AndroidManifest.xml`:

```xml
<!-- Required -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

<!-- Optional but recommended -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

## Step 3: Configure ProGuard

Add to `proguard-rules.pro`:

```proguard
# MapLibre
-keep class com.mapbox.** { *; }
-keep class org.maplibre.** { *; }

# OmniTAK custom views
-keep class com.engindearing.omnitak.maplibre.MapLibreMapView { *; }
-keep class com.engindearing.omnitak.maplibre.MapLibreMapViewAttributesBinder { *; }

# Keep @Keep annotated classes
-keep @androidx.annotation.Keep class * { *; }
```

## Step 4: Copy Implementation Files

Copy these files to your project:

```
android/
├── maplibre/
│   ├── MapLibreMapView.kt
│   └── MapLibreMapViewAttributesBinder.kt
└── build.gradle
```

Adjust package names if needed:

```kotlin
// Change this line in both files
package com.engindearing.omnitak.maplibre
// To your package, e.g.:
package com.yourcompany.yourapp.maplibre
```

## Step 5: Register with Valdi Runtime

### Automatic Registration

The `@RegisterAttributesBinder` annotation automatically registers the binder:

```kotlin
@RegisterAttributesBinder
class MapLibreMapViewAttributesBinder(context: Context) : AttributesBinder<MapLibreMapView>
```

### Manual Registration (if needed)

```kotlin
import com.snap.valdi.ValdiRuntime
import com.engindearing.omnitak.maplibre.MapLibreMapView
import com.engindearing.omnitak.maplibre.MapLibreMapViewAttributesBinder

class MyApplication : Application() {
    override fun onCreate() {
        super.onCreate()

        val runtime = ValdiRuntime.getInstance(this)

        // Register MapLibre view factory
        val viewFactory = runtime.createViewFactory(
            MapLibreMapView::class.java,
            { context -> MapLibreMapView(context) },
            MapLibreMapViewAttributesBinder(this)
        )
    }
}
```

## Step 6: Use in TypeScript

### Import the Component

```typescript
import { MapLibreView, MapMarker } from './components/MapLibreView';
```

### Basic Usage

```typescript
export class MyMapComponent extends Component<{}, {}> {
  onRender(): void {
    <MapLibreView
      viewModel={{
        styleUrl: 'https://demotiles.maplibre.org/style.json',
        options: {
          center: { lat: 38.8977, lon: -77.0365 },
          zoom: 10,
        },
        markers: [],
      }}
      context={{}}
    />;
  }
}
```

### With Markers

```typescript
const markers: MapMarker[] = [
  {
    id: 'marker1',
    lat: 38.8977,
    lon: -77.0365,
    title: 'Washington DC',
    color: '#FF0000',
  },
];

<MapLibreView
  viewModel={{
    styleUrl: 'https://demotiles.maplibre.org/style.json',
    options: { center: { lat: 38.8977, lon: -77.0365 }, zoom: 10 },
    markers: markers,
  }}
  context={{}}
/>;
```

### With Event Handlers

```typescript
<MapLibreView
  viewModel={{
    styleUrl: 'https://demotiles.maplibre.org/style.json',
    options: { center: { lat: 38.8977, lon: -77.0365 }, zoom: 10 },
    markers: [],
    onMapClick: (lat, lon) => {
      console.log(`Map clicked at: ${lat}, ${lon}`);
    },
    onMarkerTap: (id, lat, lon) => {
      console.log(`Marker ${id} tapped at: ${lat}, ${lon}`);
    },
    onCameraChange: (position) => {
      console.log('Camera changed:', position);
    },
  }}
  context={{}}
/>;
```

## Step 7: Build and Run

### Android Studio

1. Sync Gradle: `File > Sync Project with Gradle Files`
2. Build: `Build > Make Project`
3. Run: `Run > Run 'app'`

### Command Line

```bash
# Clean build
./gradlew clean

# Build debug APK
./gradlew assembleDebug

# Install on device
./gradlew installDebug

# Run
adb shell am start -n com.yourcompany.yourapp/.MainActivity
```

### Bazel

```bash
# Build module
bazel build //modules/omnitak_mobile:omnitak_mobile

# Build APK
bazel build //apps/android:OmniTAK

# Install
adb install -r bazel-bin/apps/android/OmniTAK.apk
```

## Step 8: Verify Installation

### Check Logs

```bash
adb logcat | grep -E "MapLibre|OmniTAK"
```

Expected output:

```
D/MapLibreMapView: MapLibreMapView initialized
D/MapLibreMapView: Map ready!
D/MapLibreMapView: Style loaded: https://demotiles.maplibre.org/style.json
```

### Test Markers

Add a test marker and verify it appears on the map:

```typescript
const testMarker: MapMarker = {
  id: 'test',
  lat: 38.8977,
  lon: -77.0365,
  title: 'Test Marker',
  color: '#00FF00',
};
```

## Troubleshooting

### Issue: Map not displaying

**Solution 1**: Check internet connection
```bash
adb shell ping -c 3 google.com
```

**Solution 2**: Verify style URL is accessible
```bash
curl https://demotiles.maplibre.org/style.json
```

**Solution 3**: Check logcat for errors
```bash
adb logcat | grep -i "error"
```

### Issue: Build fails with "package com.mapbox does not exist"

**Solution**: Ensure Maven repository is added to `build.gradle`:

```gradle
repositories {
    maven {
        url 'https://maven.mapbox.com/releases/com/mapbox/mapboxsdk/'
    }
}
```

### Issue: View not found in Valdi

**Solution**: Verify package name matches in TypeScript and Kotlin:

```typescript
// TypeScript
androidClass='com.engindearing.omnitak.maplibre.MapLibreMapView'
```

```kotlin
// Kotlin
package com.engindearing.omnitak.maplibre
```

### Issue: ProGuard strips classes in release build

**Solution**: Add keep rules:

```proguard
-keep class com.engindearing.omnitak.maplibre.** { *; }
-keep @androidx.annotation.Keep class * { *; }
```

### Issue: Lifecycle crashes

**Solution**: Ensure parent activity/fragment calls lifecycle methods:

```kotlin
override fun onResume() {
    super.onResume()
    mapView.onResume()
}

override fun onPause() {
    super.onPause()
    mapView.onPause()
}
```

## Advanced Configuration

### Custom Tile Server

```typescript
styleUrl: 'https://your-tile-server.com/style.json'
```

### Offline Maps

1. Download map region:
```kotlin
val offlineManager = OfflineManager.getInstance(context)
// Configure offline region
```

2. Use offline style:
```typescript
styleUrl: 'asset://offline-style.json'
```

### Custom Marker Icons

1. Add icons to MapLibre style JSON
2. Reference in marker:
```typescript
{
  id: 'marker1',
  lat: 38.8977,
  lon: -77.0365,
  icon: 'custom-icon-name'
}
```

### Performance Tuning

```kotlin
// In MapLibreMapView.kt
mapView.setMaximumFps(60)
mapView.setRenderTextureMode(true)  // For better performance on some devices
```

## Next Steps

1. **Add Location Services**: Integrate GPS for user location
2. **Implement Clustering**: For large numbers of markers
3. **Add Drawing Tools**: Lines, polygons, circles
4. **Offline Support**: Download and cache map tiles
5. **Custom Symbology**: MIL-STD-2525 icons for TAK

## Resources

- [MapLibre Documentation](https://maplibre.org/maplibre-gl-native/android/)
- [Valdi Documentation](https://github.com/Snapchat/valdi)
- [Example Code](../src/valdi/omnitak/screens/MapScreenWithMapLibre.tsx)

## Support

- GitHub Issues: [omni-TAK Repository](https://github.com/engindearing-projects/omni-TAK)
- Valdi Support: [Valdi GitHub](https://github.com/Snapchat/valdi)
- MapLibre Support: [MapLibre Slack](https://slack.openstreetmap.us/)
