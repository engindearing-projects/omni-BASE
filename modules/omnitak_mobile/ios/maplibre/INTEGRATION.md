# MapLibre Integration Guide for OmniTAK Mobile

Complete step-by-step guide for integrating MapLibre GL Native into the OmniTAK Mobile iOS application.

## Prerequisites

- macOS 12.0 or later
- Xcode 15.0 or later
- iOS 12.0+ deployment target
- Swift Package Manager or CocoaPods
- Valdi framework (already integrated in omni-BASE)

## Step 1: Add MapLibre Dependency

### Option A: Swift Package Manager (Recommended)

Swift Package Manager is the recommended approach for Xcode projects.

1. **Open Xcode Project**
   ```bash
   cd /Users/iesouskurios/Downloads/omni-BASE
   open ios/OmniTAK.xcodeproj
   ```

2. **Add Package Dependency**
   - In Xcode, select your project in the navigator
   - Select your app target
   - Go to "Package Dependencies" tab
   - Click the "+" button

3. **Enter Package URL**
   ```
   https://github.com/maplibre/maplibre-gl-native-distribution
   ```

4. **Select Version**
   - Dependency Rule: "Up to Next Major Version"
   - Version: 6.0.0
   - Click "Add Package"

5. **Verify Installation**
   - Check that "MapLibre" appears under Package Dependencies
   - Build the project to download and link the framework

### Option B: CocoaPods

If your project uses CocoaPods:

1. **Add to Podfile**
   ```ruby
   target 'OmniTAK' do
     use_frameworks!

     # Existing pods...

     # MapLibre GL Native
     pod 'MapLibre', '~> 6.0'
   end
   ```

2. **Install**
   ```bash
   cd ios
   pod install
   ```

3. **Open Workspace**
   ```bash
   open OmniTAK.xcworkspace
   ```

### Option C: Bazel Build System

If using Bazel (as indicated by `BUILD.bazel` in the module):

1. **Update WORKSPACE**

   Add to `/Users/iesouskurios/Downloads/omni-BASE/WORKSPACE`:

   ```python
   # MapLibre GL Native for iOS
   http_archive(
       name = "maplibre_ios",
       urls = ["https://github.com/maplibre/maplibre-gl-native-distribution/releases/download/ios-v6.0.0/MapLibre-6.0.0.xcframework.zip"],
       sha256 = "...",  # Add checksum
       build_file = "@//third_party/maplibre:BUILD.maplibre",
   )
   ```

2. **Create BUILD file**

   Create `/Users/iesouskurios/Downloads/omni-BASE/third_party/maplibre/BUILD.maplibre`:

   ```python
   objc_framework(
       name = "MapLibre",
       framework_imports = glob(["MapLibre.xcframework/**/*"]),
       visibility = ["//visibility:public"],
   )
   ```

3. **Update module BUILD.bazel**

   Modify `/Users/iesouskurios/Downloads/omni-BASE/modules/omnitak_mobile/BUILD.bazel`:

   ```python
   load("//build_defs:valdi.bzl", "valdi_module")

   valdi_module(
       name = "omnitak_mobile",
       srcs = glob([
           "src/**/*.ts",
           "src/**/*.tsx",
       ]),
       ios_srcs = glob([
           "ios/**/*.h",
           "ios/**/*.m",
       ]),
       ios_deps = [
           "//valdi_core:valdi_core_ios",
           "@maplibre_ios//:MapLibre",
       ],
       ios_frameworks = [
           "UIKit",
           "CoreLocation",
           "QuartzCore",
       ],
       resources = glob(["res/**/*"]),
   )
   ```

## Step 2: Add Source Files to Project

### For Xcode Projects

1. **Add files to Xcode**
   - In Xcode, right-click your project folder
   - Select "Add Files to 'OmniTAK'..."
   - Navigate to: `/Users/iesouskurios/Downloads/omni-BASE/modules/omnitak_mobile/ios/maplibre/`
   - Select both:
     - `SCMapLibreMapView.h`
     - `SCMapLibreMapView.m`
   - Check "Copy items if needed"
   - Ensure your app target is selected
   - Click "Add"

2. **Verify Files Are Included**
   - Select your target in Xcode
   - Go to "Build Phases" > "Compile Sources"
   - Confirm `SCMapLibreMapView.m` is listed
   - Go to "Build Phases" > "Headers"
   - Confirm `SCMapLibreMapView.h` is listed

### For Bazel Projects

Files are automatically included via the `ios_srcs` glob pattern in `BUILD.bazel`. No manual steps needed.

## Step 3: Configure Build Settings

### Update Header Search Paths

1. Select your target in Xcode
2. Go to "Build Settings"
3. Search for "Header Search Paths"
4. Add (if not already present):
   ```
   $(SRCROOT)/../valdi_core/src/valdi_core/ios
   $(inherited)
   ```

### Update Framework Search Paths

1. In "Build Settings"
2. Search for "Framework Search Paths"
3. Verify it includes:
   ```
   $(inherited)
   @executable_path/Frameworks
   $(PROJECT_DIR)
   ```

### Update Other Linker Flags

1. In "Build Settings"
2. Search for "Other Linker Flags"
3. Add if not present:
   ```
   -ObjC
   $(inherited)
   ```

### Set Deployment Target

1. In "Build Settings"
2. Search for "iOS Deployment Target"
3. Set to: **iOS 12.0** or higher

## Step 4: Configure Info.plist

If using location features, add required keys:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>OmniTAK needs your location to display your position on the map</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>OmniTAK needs your location for situational awareness</string>
```

## Step 5: Initialize in iOS Code

### Using ViewFactory (Recommended)

**In your AppDelegate or main view controller:**

```objectivec
#import "SCMapLibreMapView.h"
#import "valdi_core/SCValdiRuntime.h"

- (void)setupMapLibre {
    // Get Valdi runtime instance
    id<SCValdiRuntime> runtime = [self getValdiRuntime];

    // Create ViewFactory for MapLibre
    id<SCValdiViewFactory> mapLibreFactory =
        [runtime makeViewFactoryWithBlock:^UIView *{
            return [[SCMapLibreMapView alloc] initWithFrame:CGRectZero];
        }
        attributesBinder:nil
        forClass:[SCMapLibreMapView class]];

    // Store factory or pass to context
    self.mapLibreViewFactory = mapLibreFactory;
}
```

### Using Class Mapping (Alternative)

**No additional setup needed.** The view will be instantiated by class name:
- iOS: `SCMapLibreMapView`
- Android: `com.engindearing.omnitak.MapLibreMapView`

Valdi will automatically discover and instantiate the class when the `<custom-view>` element is rendered.

## Step 6: Use in TypeScript

### Import the Component

```typescript
import { MapLibreView, MapMarker, MapCamera } from '../components/MapLibreView';
```

### Basic Usage

```typescript
export class MapScreen extends Component<MapScreenViewModel, MapScreenContext> {
  onRender(): void {
    <view style={styles.container}>
      <MapLibreView
        camera={{
          latitude: 39.8283,
          longitude: -98.5795,
          zoom: 4
        }}
        onMapReady={() => console.log('Map is ready!')}
      />
    </view>;
  }
}
```

### With Markers

```typescript
const markers: MapMarker[] = [
  {
    id: 'friendly-1',
    latitude: 38.8977,
    longitude: -77.0365,
    title: 'Team Alpha',
    subtitle: 'a-f-G-E-V',
    color: '#0000FF'
  }
];

<MapLibreView
  camera={{ latitude: 38.8977, longitude: -77.0365, zoom: 12 }}
  markers={markers}
  onMarkerTap={(id) => this.handleMarkerTap(id)}
/>
```

### With CoT Integration

```typescript
import { createMarkerFromCot } from '../components/MapLibreView';
import { parseCotXml } from '../services/CotParser';

private handleCotMessage(xml: string): void {
  const event = parseCotXml(xml);
  if (event) {
    const marker = createMarkerFromCot(
      event.uid,
      event.point.lat,
      event.point.lon,
      event.detail?.contact?.callsign,
      event.type
    );

    this.mapViewRef?.addMarker(marker);
  }
}
```

## Step 7: Build and Test

### Build the Project

**Xcode:**
```bash
# Clean build
cmd+shift+k

# Build
cmd+b
```

**Bazel:**
```bash
cd /Users/iesouskurios/Downloads/omni-BASE
bazel build //modules/omnitak_mobile:omnitak_mobile --ios_multi_cpus=arm64
```

### Run on Simulator

**Xcode:**
- Select "iPhone 15 Pro" simulator
- Click Run (cmd+r)

**Bazel:**
```bash
bazel run //apps/ios:OmniTAK --ios_sdk=iphonesimulator
```

### Verify Integration

1. **Check Console Output**
   - Look for: `MapLibreView onCreate`
   - Look for: `Map is ready!` (from onMapReady callback)

2. **Test Map Interaction**
   - Map should render with tiles
   - Pan gesture should move map
   - Pinch gesture should zoom
   - Markers should be visible

3. **Test Callbacks**
   - Tap a marker - should log marker ID
   - Move map - should trigger onCameraChanged

## Step 8: Update MapScreen Component

Replace the placeholder map in `MapScreen.tsx`:

```typescript
import { MapLibreView, MapMarker, createMarkerFromCot } from '../components/MapLibreView';

export class MapScreen extends Component<MapScreenViewModel, MapScreenContext> {
  private mapMarkers: MapMarker[] = [];

  onRender(): void {
    const { markerCount, lastUpdate, isConnected } = this.viewModel;

    <view style={styles.container}>
      {/* Replace placeholder with actual map */}
      <MapLibreView
        options={{
          style: 'https://demotiles.maplibre.org/style.json',
          interactive: true,
          showUserLocation: true,
          showCompass: true
        }}
        camera={{
          latitude: 38.8977,
          longitude: -77.0365,
          zoom: 10
        }}
        markers={this.mapMarkers}
        onMapReady={() => console.log('Map ready for CoT display')}
        onMarkerTap={(id) => this.handleMarkerTap(id)}
        onCameraChanged={(camera) => this.handleCameraChanged(camera)}
      />

      {/* Keep existing toolbar and buttons */}
      <view style={styles.toolbar}>
        {/* ... existing toolbar code ... */}
      </view>
    </view>;
  }

  private handleMarkerTap(markerId: string): void {
    console.log('Marker tapped:', markerId);
    // TODO: Show marker details or CoT info
  }

  private handleCameraChanged(camera: MapCamera): void {
    console.log('Camera moved:', camera);
    // TODO: Update visible region, load new markers
  }
}
```

## Troubleshooting

### Common Build Errors

**Error: "No such module 'MapLibre'"**

Solution:
1. Verify MapLibre is in Package Dependencies
2. Clean build folder (cmd+shift+k)
3. Close and reopen Xcode
4. Delete DerivedData: `rm -rf ~/Library/Developer/Xcode/DerivedData`

**Error: "Use of undeclared identifier 'MLNMapView'"**

Solution:
1. Add `@import MapLibre;` to SCMapLibreMapView.m
2. Ensure MapLibre framework is linked in Build Phases
3. Check Framework Search Paths

**Error: "Header 'valdi_core/SCValdiView.h' not found"**

Solution:
1. Verify Valdi Core is properly integrated
2. Check Header Search Paths include Valdi directories
3. Ensure Valdi module is built before omnitak_mobile

### Runtime Issues

**Map appears blank (no tiles)**

Check:
1. Style URL is correct and accessible
2. Device/simulator has internet connection
3. Console for MapLibre error messages
4. Try default style: `https://demotiles.maplibre.org/style.json`

**Markers not appearing**

Check:
1. Marker coordinates are valid (lat: -90 to 90, lon: -180 to 180)
2. Markers have unique IDs
3. Map is fully loaded (wait for onMapReady)
4. Zoom level allows markers to be visible

**App crashes on map interaction**

Check:
1. Callbacks are properly retained
2. No retain cycles in delegate methods
3. Memory warnings in Console
4. Run with Zombies enabled to detect deallocated objects

## Advanced Configuration

### Custom Map Styles

Use custom tile servers:

```typescript
<MapLibreView
  options={{
    style: 'https://tiles.stadiamaps.com/styles/alidade_smooth.json'
  }}
/>
```

Popular styles:
- **OpenStreetMap Positron**: `https://demotiles.maplibre.org/style.json`
- **Stadia Maps**: `https://tiles.stadiamaps.com/styles/alidade_smooth.json`
- **Custom Mapbox**: `mapbox://styles/username/style-id`

### Offline Maps

To support offline operation:

1. Download tile packages
2. Store in app bundle or Documents directory
3. Use file URL for style: `file:///path/to/style.json`

### Performance Tuning

For large marker sets:

```typescript
// Implement marker clustering
const visibleMarkers = markers.filter(m =>
  isInViewport(m.latitude, m.longitude, camera)
);

<MapLibreView markers={visibleMarkers} />
```

## Next Steps

1. **Implement Android Wrapper**: Create equivalent Java/Kotlin wrapper for Android
2. **Add Custom Icons**: Support custom marker images based on CoT type
3. **Implement Clustering**: Group nearby markers at low zoom levels
4. **Add Drawing Tools**: Support polylines, polygons for route planning
5. **Offline Tiles**: Pre-download map tiles for offline operation
6. **3D Terrain**: Enable terrain elevation with pitch/tilt

## Resources

- [MapLibre iOS Documentation](https://maplibre.org/maplibre-gl-native/ios/)
- [Valdi Custom Views Guide](https://github.com/Snapchat/valdi/docs/native-customviews.md)
- [OmniTAK Repository](https://github.com/engindearing-projects/omni-TAK)
- [CoT Message Format](https://www.mitre.org/sites/default/files/pdf/09_4937.pdf)

## Support

For issues or questions:
- **OmniTAK**: Open an issue in the omni-TAK repository
- **MapLibre**: Check MapLibre GitHub issues
- **Valdi**: See Valdi framework documentation
