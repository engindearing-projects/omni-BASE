# MapLibre GL Native Integration for OmniTAK Mobile

This directory contains the iOS native wrapper for MapLibre GL Native, providing high-performance map rendering for OmniTAK Mobile via the Valdi framework.

## Overview

The MapLibre integration provides:

- **Native Map Rendering**: Hardware-accelerated map rendering using MapLibre GL Native
- **Dynamic Markers**: Real-time CoT marker placement and updates
- **Camera Control**: Programmatic camera positioning (pan, zoom, rotate, tilt)
- **Touch Events**: Interactive map with tap callbacks
- **View Pooling**: Optimized for Valdi's view recycling system
- **Custom Styles**: Support for Mapbox styles, OpenStreetMap, and custom tile servers

## Files

### SCMapLibreMapView.h
Header file defining the public interface for the MapLibre wrapper view.

**Key Properties:**
- `mapView`: The underlying MLNMapView instance
- `styleURL`: Map style URL (default: OpenStreetMap)
- `userInteractionEnabled`: Enable/disable user gestures
- `showUserLocation`: Display user location blue dot

### SCMapLibreMapView.m
Implementation file with complete MapLibre integration.

**Valdi Attributes:**
- `options`: JSON object with map configuration
- `camera`: JSON object with camera position (lat, lon, zoom, bearing, pitch)
- `markers`: JSON array of marker definitions
- `onMapReady`: Callback when map finishes loading
- `onMarkerTap`: Callback when marker is tapped (receives marker ID)
- `onMapTap`: Callback when map is tapped (receives coordinates)
- `onCameraChanged`: Callback when camera moves (receives camera state)

**Key Methods:**
- `+bindAttributes:`: Registers Valdi attribute bindings
- `willEnqueueIntoValdiPool`: Enables view recycling
- `MLNMapViewDelegate` methods for event handling

## Dependencies

### MapLibre GL Native

The MapLibre GL Native SDK must be added to your Xcode project. There are two options:

#### Option 1: Swift Package Manager (Recommended)

1. Open your Xcode project
2. Go to **File > Add Packages...**
3. Enter the MapLibre repository URL:
   ```
   https://github.com/maplibre/maplibre-gl-native-distribution
   ```
4. Select version: `6.0.0` or later
5. Add to your target

#### Option 2: CocoaPods

Add to your `Podfile`:

```ruby
pod 'MapLibre', '~> 6.0'
```

Then run:
```bash
pod install
```

### Valdi Core

The implementation requires Valdi Core framework headers:
- `valdi_core/SCValdiView.h`
- `valdi_core/SCValdiAttributesBinderBase.h`
- `valdi_core/SCValdiAnimatorProtocol.h`
- `valdi_core/SCValdiViewLayoutAttributes.h`

These are automatically available in Valdi projects.

## Integration Steps

### 1. Add MapLibre Dependency

Follow the dependency installation steps above (Swift Package Manager or CocoaPods).

### 2. Add Source Files to Xcode Project

Add both files to your Xcode target:
- `SCMapLibreMapView.h`
- `SCMapLibreMapView.m`

In Xcode:
1. Right-click your project in the navigator
2. Select **Add Files to "YourProject"...**
3. Select both `SCMapLibreMapView.h` and `SCMapLibreMapView.m`
4. Ensure "Copy items if needed" is checked
5. Add to your app target

### 3. Update Build Settings

Ensure your project has proper import paths:

**Header Search Paths:**
```
$(inherited)
$(SRCROOT)/../../../valdi_core/src/valdi_core/ios
```

**Other Linker Flags:**
```
$(inherited)
-ObjC
```

### 4. Register with Valdi Runtime

In your iOS app initialization code (typically in `AppDelegate` or view controller):

**Using ViewFactory (Recommended):**

```objectivec
#import "SCMapLibreMapView.h"

// Create ViewFactory for MapLibre
id<SCValdiViewFactory> mapLibreFactory =
    [runtime makeViewFactoryWithBlock:^UIView *{
        return [[SCMapLibreMapView alloc] initWithFrame:CGRectZero];
    }
    attributesBinder:nil
    forClass:[SCMapLibreMapView class]];

// Pass to context
MapLibreViewContext *context = [MapLibreViewContext new];
context.mapLibreViewFactory = mapLibreFactory;
```

**Using Class Mapping (Alternative):**

The view can be instantiated directly by class name. Ensure the class is:
1. Linked into the binary (not stripped by linker)
2. Has `initWithFrame:` initializer
3. Implements `+bindAttributes:` class method

No additional registration needed - Valdi will find it automatically.

### 5. Use in TypeScript

Import and use the MapLibreView component:

```typescript
import { MapLibreView, MapMarker, MapCamera } from './components/MapLibreView';

// In your component's onRender():
const markers: MapMarker[] = [
  {
    id: 'marker-1',
    latitude: 37.7749,
    longitude: -122.4194,
    title: 'San Francisco',
    color: '#FF0000'
  }
];

const camera: MapCamera = {
  latitude: 37.7749,
  longitude: -122.4194,
  zoom: 12
};

<MapLibreView
  options={{
    style: 'https://demotiles.maplibre.org/style.json',
    interactive: true,
    showUserLocation: true
  }}
  camera={camera}
  markers={markers}
  onMapReady={() => console.log('Map is ready!')}
  onMarkerTap={(id) => console.log('Tapped marker:', id)}
/>
```

## Usage Examples

### Basic Map

```typescript
<MapLibreView
  camera={{
    latitude: 39.8283,
    longitude: -98.5795,
    zoom: 4
  }}
/>
```

### Map with Markers

```typescript
const cotMarkers = cotEvents.map(event => ({
  id: event.uid,
  latitude: event.point.lat,
  longitude: event.point.lon,
  title: event.detail?.contact?.callsign || event.uid,
  color: getAffiliationColor(event.type)
}));

<MapLibreView
  markers={cotMarkers}
  onMarkerTap={(id) => showMarkerDetails(id)}
/>
```

### Dynamic Camera Updates

```typescript
// In your component class:
private mapViewRef: MapLibreView | null = null;

// Move camera programmatically
this.mapViewRef?.setCamera({
  latitude: 38.8977,
  longitude: -77.0365,
  zoom: 14,
  bearing: 45,
  pitch: 30,
  animated: true
});
```

### Custom Map Style

```typescript
<MapLibreView
  options={{
    style: 'https://tiles.stadiamaps.com/styles/alidade_smooth.json',
    showCompass: true,
    showScaleBar: true
  }}
/>
```

## Bazel Integration

If using Bazel build system, add the MapLibre dependency to your `BUILD.bazel`:

```python
objc_library(
    name = "maplibre_wrapper",
    srcs = ["ios/maplibre/SCMapLibreMapView.m"],
    hdrs = ["ios/maplibre/SCMapLibreMapView.h"],
    deps = [
        "//valdi_core:valdi_core_ios",
        "@maplibre_ios//:MapLibre",
    ],
    sdk_frameworks = [
        "UIKit",
        "CoreLocation",
    ],
)
```

Add to your workspace `WORKSPACE` file:

```python
# MapLibre GL Native
http_archive(
    name = "maplibre_ios",
    urls = ["https://github.com/maplibre/maplibre-gl-native/archive/refs/tags/ios-v6.0.0.tar.gz"],
    strip_prefix = "maplibre-gl-native-ios-v6.0.0",
)
```

## Troubleshooting

### Map Not Rendering

**Issue**: Map view appears but stays blank or gray.

**Solutions**:
1. Check that MapLibre framework is properly linked
2. Verify style URL is accessible (test in browser)
3. Check Console for MapLibre errors
4. Ensure `onMapReady` callback is fired

### Markers Not Appearing

**Issue**: Markers array is set but nothing shows on map.

**Solutions**:
1. Verify marker coordinates are valid (lat: -90 to 90, lon: -180 to 180)
2. Check marker IDs are unique
3. Ensure map is fully loaded before adding markers
4. Look for warnings in Xcode console

### Build Errors

**Issue**: Compiler errors about missing MapLibre headers.

**Solutions**:
1. Clean build folder (Product > Clean Build Folder)
2. Verify MapLibre is in your Package Dependencies
3. Check Header Search Paths in Build Settings
4. Re-add MapLibre package if needed

### Memory Issues

**Issue**: App crashes or high memory usage with many markers.

**Solutions**:
1. Limit visible markers (use clustering)
2. Remove off-screen markers
3. Use view pooling (already implemented)
4. Profile with Instruments to identify leaks

## Performance Optimization

### View Pooling

The implementation includes `willEnqueueIntoValdiPool` to support Valdi's view recycling:

```objectivec
- (BOOL)willEnqueueIntoValdiPool {
    [self cleanup];  // Remove markers, clear callbacks
    return YES;      // Allow pooling
}
```

This dramatically reduces memory usage when views are created/destroyed frequently.

### Marker Clustering

For large marker sets (>100), consider implementing clustering:

```typescript
// Group nearby markers
const clustered = clusterMarkers(allMarkers, zoomLevel);
<MapLibreView markers={clustered} />
```

### Lazy Loading

Only load map when visible:

```typescript
{isMapVisible && <MapLibreView ... />}
```

## API Reference

### Valdi Attributes (Objective-C)

| Attribute | Type | Description |
|-----------|------|-------------|
| `options` | NSDictionary | Map configuration (style, interaction, UI controls) |
| `camera` | NSDictionary | Camera position (latitude, longitude, zoom, bearing, pitch) |
| `markers` | NSArray | Array of marker dictionaries (id, latitude, longitude, title, subtitle) |
| `onMapReady` | Block | Callback fired when map finishes loading |
| `onMarkerTap` | Block | Callback with marker ID when annotation is tapped |
| `onMapTap` | Block | Callback with coordinates when map is tapped |
| `onCameraChanged` | Block | Callback with camera state when viewport changes |

### TypeScript Interfaces

See `MapLibreView.tsx` for complete interface definitions:
- `MapCamera`: Camera position and orientation
- `MapMarker`: Marker/annotation definition
- `MapLibreViewOptions`: Map configuration options
- `MapTapEvent`: Map tap event data

## License

This integration code is part of OmniTAK Mobile and is licensed under the MIT License.

MapLibre GL Native is licensed under the BSD-2-Clause license.

## Support

For issues with:
- **OmniTAK integration**: Open an issue in the omni-TAK repository
- **MapLibre SDK**: See [MapLibre documentation](https://maplibre.org/maplibre-gl-native/ios/)
- **Valdi framework**: See [Valdi documentation](https://github.com/Snapchat/valdi)
