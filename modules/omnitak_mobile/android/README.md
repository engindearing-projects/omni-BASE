# OmniTAK Mobile - Android MapLibre Integration

Complete Android implementation of MapLibre GL Native for OmniTAK Mobile using Valdi's custom-view pattern.

## Overview

This module provides a native Android MapLibre integration that can be used from TypeScript/Valdi components. It includes:

- **MapLibreMapView.kt**: Custom view wrapping MapLibre GL Native MapView
- **MapLibreMapViewAttributesBinder.kt**: Valdi attributes binder for declarative configuration
- **MapLibreView.tsx**: TypeScript component for cross-platform usage

## Architecture

```
┌─────────────────────────────────────┐
│   TypeScript (Valdi)                │
│   MapLibreView.tsx                  │
│   - Component wrapper               │
│   - Type-safe API                   │
└──────────────┬──────────────────────┘
               │
               │ Valdi Bridge
               │
┌──────────────▼──────────────────────┐
│   Kotlin (Android)                  │
│   MapLibreMapView.kt                │
│   - Extends ValdiView               │
│   - Lifecycle management            │
│   - Event handling                  │
└──────────────┬──────────────────────┘
               │
               │ Native API
               │
┌──────────────▼──────────────────────┐
│   MapLibre GL Native                │
│   - Map rendering                   │
│   - Marker management               │
│   - Camera controls                 │
└─────────────────────────────────────┘
```

## Files Structure

```
modules/omnitak_mobile/
├── android/
│   ├── maplibre/
│   │   ├── MapLibreMapView.kt              # Main view implementation
│   │   └── MapLibreMapViewAttributesBinder.kt  # Attributes binder
│   ├── build.gradle                         # Gradle dependencies
│   ├── AndroidManifest.xml                  # Permissions
│   ├── proguard-rules.pro                   # ProGuard configuration
│   └── README.md                            # This file
└── src/valdi/omnitak/
    ├── components/
    │   └── MapLibreView.tsx                 # TypeScript component
    └── screens/
        └── MapScreenWithMapLibre.tsx        # Example usage
```

## Installation

### 1. Add to Gradle Dependencies

The `build.gradle` file already includes:

```gradle
dependencies {
    implementation 'org.maplibre.gl:android-sdk:11.8.0'
    implementation 'org.maplibre.gl:android-plugin-annotation-v9:3.0.0'
}
```

### 2. Configure Maven Repository

Ensure your project's root `build.gradle` includes:

```gradle
allprojects {
    repositories {
        google()
        mavenCentral()
        maven {
            url 'https://maven.mapbox.com/releases/com/mapbox/mapboxsdk/'
        }
    }
}
```

### 3. Add Permissions

Already configured in `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### 4. ProGuard Configuration

Already configured in `proguard-rules.pro`:

```proguard
-keep class com.mapbox.** { *; }
-keep class org.maplibre.** { *; }
-keep class com.engindearing.omnitak.maplibre.MapLibreMapView { *; }
```

## Usage

### TypeScript Component

```typescript
import { MapLibreView, MapMarker } from '../components/MapLibreView';

export class MyMapScreen extends Component<{}, {}> {
  onRender(): void {
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
        options: {
          center: { lat: 38.8977, lon: -77.0365 },
          zoom: 10,
        },
        markers: markers,
        onMapClick: (lat, lon) => console.log('Clicked:', lat, lon),
        onMarkerTap: (id, lat, lon) => console.log('Marker:', id),
      }}
      context={{}}
    />;
  }
}
```

### Direct Android Usage (Advanced)

If you need to use the view directly in Android:

```kotlin
import com.engindearing.omnitak.maplibre.MapLibreMapView
import com.engindearing.omnitak.maplibre.MapLibreMapViewAttributesBinder

val mapView = MapLibreMapView(context)

// Set options
mapView.setStyleUrl("https://demotiles.maplibre.org/style.json")
mapView.setMapOptions("""
{
  "center": {"lat": 38.8977, "lon": -77.0365},
  "zoom": 10
}
""")

// Add markers
mapView.setMarkers("""
[
  {
    "id": "marker1",
    "lat": 38.8977,
    "lon": -77.0365,
    "title": "Washington DC"
  }
]
""")
```

## API Reference

### MapLibreMapView Properties

| Property | Type | Description |
|----------|------|-------------|
| `styleUrl` | String | MapLibre style JSON URL |
| `options` | JSON String | Map options (center, zoom, bearing, tilt) |
| `markers` | JSON Array | Array of marker objects |
| `onCameraChange` | Callback | Called when camera position changes |
| `onMapClick` | Callback | Called when map is clicked |
| `onMarkerTap` | Callback | Called when marker is tapped |

### MapOptions Schema

```json
{
  "center": {
    "lat": 38.8977,
    "lon": -77.0365
  },
  "zoom": 10,
  "bearing": 0,
  "tilt": 0
}
```

### Marker Schema

```json
{
  "id": "unique-marker-id",
  "lat": 38.8977,
  "lon": -77.0365,
  "title": "Marker Title",
  "icon": "marker-icon-name",
  "color": "#FF0000"
}
```

## Lifecycle Management

### Critical: MapView Lifecycle

MapLibre's MapView requires proper lifecycle management. The implementation handles this through:

1. **Automatic Lifecycle** (when used in Valdi):
   - `onAttachedToWindow()` → calls `mapView.onStart()`
   - `onDetachedFromWindow()` → calls `mapView.onStop()`

2. **Manual Lifecycle** (if needed):
   ```kotlin
   override fun onResume() {
       super.onResume()
       mapView.onResume()
   }

   override fun onPause() {
       super.onPause()
       mapView.onPause()
   }

   override fun onDestroy() {
       super.onDestroy()
       mapView.onDestroy()
   }
   ```

### Memory Management

The view properly cleans up resources:

```kotlin
fun onDestroy() {
    mapView.onDestroy()
    symbolManager?.onDestroy()
    symbolManager = null
    mapboxMap = null
    isMapReady = false
}
```

## Thread Safety

All MapLibre operations are executed on the main UI thread:

```kotlin
private fun runOnUiThread(action: () -> Unit) {
    if (Looper.myLooper() == Looper.getMainLooper()) {
        action()
    } else {
        mainHandler.post(action)
    }
}
```

## Event Handling

### Camera Changes

```typescript
onCameraChange: (position) => {
  console.log('New position:', position.center.lat, position.center.lon);
  console.log('Zoom:', position.zoom);
}
```

### Map Clicks

```typescript
onMapClick: (lat, lon) => {
  console.log('Clicked at:', lat, lon);
}
```

### Marker Taps

```typescript
onMarkerTap: (markerId, lat, lon) => {
  console.log('Marker tapped:', markerId);
}
```

## Customization

### Custom Map Styles

Use any MapLibre-compatible style JSON:

```typescript
styleUrl: 'https://your-tile-server.com/style.json'
```

### Custom Marker Icons

1. Add icons to MapLibre style JSON
2. Reference in marker data:

```typescript
{
  id: 'marker1',
  lat: 38.8977,
  lon: -77.0365,
  icon: 'custom-icon-name'  // Defined in style JSON
}
```

## TAK Integration

### CoT Marker Display

Example from MapScreenWithMapLibre.tsx:

```typescript
private handleCotMessage(xml: string): void {
  const event = parseCotXml(xml);
  if (event) {
    const marker: MapMarker = {
      id: event.uid,
      lat: event.point.lat,
      lon: event.point.lon,
      title: event.detail?.contact?.callsign,
      color: getAffiliationColor(getAffiliation(event.type)),
    };

    this.mapLibreRef?.addMarker(marker);
  }
}
```

## Performance Considerations

### Marker Updates

- Batch marker updates when possible
- Use `setMarkers()` to replace all markers at once
- Avoid frequent individual marker updates

### Memory

- MapView automatically manages tile cache
- Limit number of visible markers (use clustering for large datasets)
- Call `onLowMemory()` when system memory is low

### Rendering

- Default to hardware acceleration (enabled by Android)
- Smooth 60 FPS rendering on modern devices
- Efficient tile loading and caching

## Troubleshooting

### Map Not Displaying

1. Check internet connectivity (for tile downloads)
2. Verify style URL is accessible
3. Check logcat for MapLibre errors: `adb logcat | grep MapLibre`

### Lifecycle Issues

1. Ensure proper activity/fragment lifecycle calls
2. Check that `onDestroy()` is called to clean up resources
3. Verify no memory leaks with LeakCanary

### ProGuard Issues

If classes are being stripped in release builds:

```proguard
-keep class com.engindearing.omnitak.** { *; }
-keep @androidx.annotation.Keep class * { *; }
```

### Valdi Integration Issues

1. Ensure `@RegisterAttributesBinder` annotation is present
2. Verify package names match in TypeScript and Kotlin
3. Check Valdi runtime can find the view factory

## Examples

See `src/valdi/omnitak/screens/MapScreenWithMapLibre.tsx` for a complete working example.

## Dependencies

- **MapLibre GL Native**: 11.8.0
- **MapLibre Annotation Plugin**: 3.0.0
- **AndroidX Core**: 1.12.0
- **Kotlin**: 1.8.0
- **Valdi**: (provided by parent app)

## Further Reading

- [MapLibre Android SDK Docs](https://maplibre.org/maplibre-gl-native/android/api/)
- [Valdi Custom Views Guide](https://github.com/Snapchat/valdi/blob/main/docs/native-customviews.md)
- [OmniTAK Mobile Architecture](../README.md)

## License

MIT License - See LICENSE file for details
