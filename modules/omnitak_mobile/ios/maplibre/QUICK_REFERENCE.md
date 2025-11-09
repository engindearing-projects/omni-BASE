# MapLibreView Quick Reference

One-page reference for common MapLibreView operations in OmniTAK Mobile.

## Installation

### Swift Package Manager (Recommended)
```
https://github.com/maplibre/maplibre-gl-native-distribution
Version: 6.0.0+
```

### CocoaPods
```ruby
pod 'MapLibre', '~> 6.0'
```

## Basic Import

```typescript
import { MapLibreView, MapMarker, MapCamera } from '../components/MapLibreView';
```

## Quick Start

```typescript
<MapLibreView
  camera={{ latitude: 38.8977, longitude: -77.0365, zoom: 12 }}
  onMapReady={() => console.log('Ready!')}
/>
```

## Common Operations

### Set Camera Position

```typescript
mapRef?.setCamera({
  latitude: 38.8977,
  longitude: -77.0365,
  zoom: 12,
  bearing: 45,     // optional: heading in degrees
  pitch: 30,       // optional: tilt in degrees
  animated: true   // optional: animate transition
});
```

### Add Marker

```typescript
mapRef?.addMarker({
  id: 'marker-1',
  latitude: 38.8977,
  longitude: -77.0365,
  title: 'Washington DC',
  subtitle: 'Capital',
  color: '#FF0000'
});
```

### Remove Marker

```typescript
mapRef?.removeMarker('marker-1');
```

### Update Marker

```typescript
mapRef?.updateMarker('marker-1', {
  title: 'Updated Title',
  color: '#00FF00'
});
```

### Clear All Markers

```typescript
mapRef?.clearMarkers();
```

### Change Map Style

```typescript
mapRef?.setOptions({
  style: 'https://demotiles.maplibre.org/style.json'
});
```

## Callbacks

### Map Ready

```typescript
<MapLibreView
  onMapReady={() => {
    console.log('Map finished loading');
  }}
/>
```

### Marker Tap

```typescript
<MapLibreView
  onMarkerTap={(markerId: string) => {
    console.log('Tapped:', markerId);
  }}
/>
```

### Map Tap

```typescript
<MapLibreView
  onMapTap={(event: MapTapEvent) => {
    console.log('Tapped at:', event.latitude, event.longitude);
  }}
/>
```

### Camera Changed

```typescript
<MapLibreView
  onCameraChanged={(camera: MapCamera) => {
    console.log('New position:', camera.latitude, camera.longitude);
    console.log('New zoom:', camera.zoom);
  }}
/>
```

## Interfaces

### MapCamera

```typescript
interface MapCamera {
  latitude: number;      // -90 to 90
  longitude: number;     // -180 to 180
  zoom: number;          // 0 (world) to 22 (street)
  bearing?: number;      // 0 (north) to 360
  pitch?: number;        // 0 (flat) to 60 (max tilt)
  animated?: boolean;    // animate transition
}
```

### MapMarker

```typescript
interface MapMarker {
  id: string;            // unique identifier
  latitude: number;      // -90 to 90
  longitude: number;     // -180 to 180
  title?: string;        // callout title
  subtitle?: string;     // callout subtitle
  icon?: string;         // future: icon name/url
  color?: string;        // hex color (e.g., '#FF0000')
  metadata?: Record<string, any>;  // custom data
}
```

### MapLibreViewOptions

```typescript
interface MapLibreViewOptions {
  style?: string;              // style URL
  interactive?: boolean;       // enable gestures
  showUserLocation?: boolean;  // show location dot
  showCompass?: boolean;       // show compass
  showScaleBar?: boolean;      // show scale
  minZoom?: number;            // min zoom level
  maxZoom?: number;            // max zoom level
}
```

## Helper Functions

### Create Marker from CoT

```typescript
import { createMarkerFromCot } from '../components/MapLibreView';

const marker = createMarkerFromCot(
  cotEvent.uid,
  cotEvent.point.lat,
  cotEvent.point.lon,
  cotEvent.detail?.contact?.callsign,
  cotEvent.type
);
```

### Fit Camera to Markers

```typescript
import { createCameraFromMarkers } from '../components/MapLibreView';

const camera = createCameraFromMarkers(markers, 1.2);
if (camera) {
  mapRef?.setCamera({ ...camera, animated: true });
}
```

## Map Styles

### OpenStreetMap (Default)
```typescript
style: 'https://demotiles.maplibre.org/style.json'
```

### Satellite
```typescript
style: 'https://tiles.stadiamaps.com/styles/alidade_satellite.json'
```

### Dark Theme
```typescript
style: 'https://tiles.stadiamaps.com/styles/alidade_smooth_dark.json'
```

### Light Theme
```typescript
style: 'https://tiles.stadiamaps.com/styles/alidade_smooth.json'
```

## Component Pattern

```typescript
export class MapScreen extends Component<MapScreenViewModel, {}> {
  private mapRef: MapLibreView | null = null;

  onRender(): void {
    <MapLibreView
      ref={(ref) => this.mapRef = ref}
      camera={this.viewModel.camera}
      markers={this.viewModel.markers}
      onMarkerTap={(id) => this.handleMarkerTap(id)}
    />;
  }

  private handleMarkerTap(markerId: string): void {
    // Handle marker tap
  }
}
```

## Performance Tips

### Limit Visible Markers

```typescript
// Filter markers in viewport
const visibleMarkers = allMarkers.filter(m =>
  isInViewport(m, camera)
);

<MapLibreView markers={visibleMarkers} />
```

### Viewport Check

```typescript
function isInViewport(
  marker: MapMarker,
  camera: MapCamera
): boolean {
  const latRange = 180 / Math.pow(2, camera.zoom);
  const lonRange = 360 / Math.pow(2, camera.zoom);

  return (
    Math.abs(marker.latitude - camera.latitude) < latRange &&
    Math.abs(marker.longitude - camera.longitude) < lonRange
  );
}
```

### Debounce Camera Changes

```typescript
private cameraDebounce?: number;

handleCameraChange(camera: MapCamera): void {
  if (this.cameraDebounce) {
    clearTimeout(this.cameraDebounce);
  }

  this.cameraDebounce = setTimeout(() => {
    this.updateVisibleMarkers(camera);
  }, 300);
}
```

## Troubleshooting

### Map Not Rendering
- Check MapLibre framework is linked
- Verify style URL is accessible
- Look for errors in Console

### Markers Not Appearing
- Ensure coordinates are valid (-90 to 90 lat, -180 to 180 lon)
- Check marker IDs are unique
- Wait for onMapReady before adding markers

### Build Errors
- Clean build folder (Cmd+Shift+K)
- Check Header Search Paths
- Verify MapLibre in Package Dependencies

### Performance Issues
- Limit markers to <200 visible
- Implement marker clustering
- Remove off-screen markers
- Profile with Instruments

## Common Patterns

### Follow User Location

```typescript
<MapLibreView
  options={{
    showUserLocation: true
  }}
  camera={this.viewModel.userLocation}
/>

// Update camera when location changes
onLocationUpdate(lat: number, lon: number): void {
  this.mapRef?.setCamera({
    latitude: lat,
    longitude: lon,
    zoom: 15,
    animated: true
  });
}
```

### Search and Focus

```typescript
searchLocation(query: string): void {
  // Geocode query to coordinates
  const result = geocode(query);

  // Fly to location
  this.mapRef?.setCamera({
    latitude: result.lat,
    longitude: result.lon,
    zoom: 14,
    animated: true
  });

  // Add marker
  this.mapRef?.addMarker({
    id: 'search-result',
    latitude: result.lat,
    longitude: result.lon,
    title: query
  });
}
```

### Show Marker Details

```typescript
<MapLibreView
  markers={markers}
  onMarkerTap={(id) => {
    const marker = markers.find(m => m.id === id);
    if (marker) {
      this.showDetailsModal(marker);
    }
  }}
/>
```

### Real-time Updates

```typescript
// Subscribe to CoT messages
takService.onCotReceived(connectionId, (xml) => {
  const event = parseCotXml(xml);
  const marker = createMarkerFromCot(
    event.uid,
    event.point.lat,
    event.point.lon,
    event.detail?.contact?.callsign,
    event.type
  );

  // Update existing or add new
  const existing = markers.get(event.uid);
  if (existing) {
    mapRef?.updateMarker(event.uid, marker);
  } else {
    mapRef?.addMarker(marker);
  }
});
```

## File Locations

**iOS Native**:
- Header: `ios/maplibre/SCMapLibreMapView.h`
- Implementation: `ios/maplibre/SCMapLibreMapView.m`

**TypeScript**:
- Component: `src/valdi/omnitak/components/MapLibreView.tsx`

**Documentation**:
- Overview: `ios/maplibre/README.md`
- Integration: `ios/maplibre/INTEGRATION.md`
- Examples: `ios/maplibre/EXAMPLES.md`
- Summary: `ios/maplibre/IMPLEMENTATION_SUMMARY.md`

## Links

- [Full Documentation](./README.md)
- [Integration Guide](./INTEGRATION.md)
- [Code Examples](./EXAMPLES.md)
- [MapLibre Docs](https://maplibre.org/maplibre-gl-native/ios/)
- [Valdi Docs](https://github.com/Snapchat/valdi)

---

**Quick Reference Version**: 1.0
**Last Updated**: 2025-11-08
