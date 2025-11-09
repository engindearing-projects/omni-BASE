# MapLibreView Usage Examples

Collection of practical examples for using MapLibreView in OmniTAK Mobile.

## Table of Contents

1. [Basic Map](#basic-map)
2. [Map with Markers](#map-with-markers)
3. [Dynamic Marker Updates](#dynamic-marker-updates)
4. [Camera Control](#camera-control)
5. [CoT Integration](#cot-integration)
6. [User Interaction](#user-interaction)
7. [Custom Styling](#custom-styling)
8. [Performance Optimization](#performance-optimization)

---

## Basic Map

Minimal map setup with default settings.

```typescript
import { Component } from 'valdi_core/src/Component';
import { View } from 'valdi_tsx/src/NativeTemplateElements';
import { Style } from 'valdi_core/src/Style';
import { MapLibreView } from '../components/MapLibreView';

export class SimpleMapScreen extends Component<{}, {}> {
  onRender(): void {
    <view style={styles.container}>
      <MapLibreView
        camera={{
          latitude: 39.8283,
          longitude: -98.5795,
          zoom: 4
        }}
      />
    </view>;
  }
}

const styles = {
  container: new Style<View>({
    width: '100%',
    height: '100%',
  }),
};
```

---

## Map with Markers

Display static markers on the map.

```typescript
import { MapLibreView, MapMarker } from '../components/MapLibreView';

export class MarkerMapScreen extends Component<{}, {}> {
  private markers: MapMarker[] = [
    {
      id: 'dc',
      latitude: 38.8977,
      longitude: -77.0365,
      title: 'Washington, DC',
      subtitle: 'Capital',
      color: '#0000FF'
    },
    {
      id: 'nyc',
      latitude: 40.7128,
      longitude: -74.0060,
      title: 'New York City',
      subtitle: 'Metropolitan',
      color: '#FF0000'
    },
    {
      id: 'sf',
      latitude: 37.7749,
      longitude: -122.4194,
      title: 'San Francisco',
      subtitle: 'Tech Hub',
      color: '#00FF00'
    }
  ];

  onRender(): void {
    <view style={styles.container}>
      <MapLibreView
        camera={{
          latitude: 39.8283,
          longitude: -98.5795,
          zoom: 4
        }}
        markers={this.markers}
        onMarkerTap={(id) => console.log('Tapped marker:', id)}
        onMapReady={() => console.log('Map loaded with markers')}
      />
    </view>;
  }
}
```

---

## Dynamic Marker Updates

Add, update, and remove markers programmatically.

```typescript
interface DynamicMapViewModel {
  markers: MapMarker[];
  selectedMarkerId?: string;
}

export class DynamicMapScreen extends Component<DynamicMapViewModel, {}> {
  private mapRef: MapLibreView | null = null;

  onCreate(): void {
    this.viewModel = {
      markers: []
    };
  }

  onRender(): void {
    const { markers } = this.viewModel;

    <view style={styles.container}>
      <MapLibreView
        ref={(ref) => this.mapRef = ref}
        markers={markers}
        camera={{
          latitude: 38.8977,
          longitude: -77.0365,
          zoom: 10
        }}
        onMarkerTap={(id) => this.handleMarkerTap(id)}
      />

      {/* Control buttons */}
      <view style={styles.controls}>
        <button onPress={() => this.addRandomMarker()}>
          Add Marker
        </button>
        <button onPress={() => this.clearAllMarkers()}>
          Clear All
        </button>
      </view>
    </view>;
  }

  private addRandomMarker(): void {
    const newMarker: MapMarker = {
      id: `marker-${Date.now()}`,
      latitude: 38.8977 + (Math.random() - 0.5) * 0.1,
      longitude: -77.0365 + (Math.random() - 0.5) * 0.1,
      title: `Marker ${this.viewModel.markers.length + 1}`,
      color: '#' + Math.floor(Math.random() * 16777215).toString(16)
    };

    this.mapRef?.addMarker(newMarker);
  }

  private clearAllMarkers(): void {
    this.mapRef?.clearMarkers();
  }

  private handleMarkerTap(markerId: string): void {
    console.log('Marker tapped:', markerId);

    // Update marker appearance
    this.mapRef?.updateMarker(markerId, {
      color: '#FFFF00', // Highlight in yellow
      subtitle: 'Selected'
    });

    this.updateViewModel({ selectedMarkerId: markerId });
  }

  private updateViewModel(updates: Partial<DynamicMapViewModel>): void {
    this.viewModel = { ...this.viewModel, ...updates };
    this.requestRender();
  }
}
```

---

## Camera Control

Programmatically control camera position with animations.

```typescript
export class CameraControlScreen extends Component<{}, {}> {
  private mapRef: MapLibreView | null = null;

  private locations = {
    dc: { latitude: 38.8977, longitude: -77.0365, zoom: 12 },
    nyc: { latitude: 40.7128, longitude: -74.0060, zoom: 12 },
    sf: { latitude: 37.7749, longitude: -122.4194, zoom: 12 }
  };

  onRender(): void {
    <view style={styles.container}>
      <MapLibreView
        ref={(ref) => this.mapRef = ref}
        camera={this.locations.dc}
        onCameraChanged={(camera) => this.handleCameraChange(camera)}
      />

      {/* Location buttons */}
      <view style={styles.locationButtons}>
        <button onPress={() => this.flyTo('dc')}>
          Washington DC
        </button>
        <button onPress={() => this.flyTo('nyc')}>
          New York
        </button>
        <button onPress={() => this.flyTo('sf')}>
          San Francisco
        </button>
      </view>
    </view>;
  }

  private flyTo(location: 'dc' | 'nyc' | 'sf'): void {
    const camera = {
      ...this.locations[location],
      animated: true
    };
    this.mapRef?.setCamera(camera);
  }

  private handleCameraChange(camera: MapCamera): void {
    console.log('Camera position:', camera.latitude, camera.longitude);
    console.log('Zoom level:', camera.zoom);
  }
}
```

---

## CoT Integration

Real-world example integrating with TAK CoT messages.

```typescript
import { takService } from '../services/TakService';
import { parseCotXml } from '../services/CotParser';
import { MapLibreView, MapMarker, createMarkerFromCot } from '../components/MapLibreView';

interface CotMapViewModel {
  markers: Map<string, MapMarker>;
  connectionId?: number;
  isConnected: boolean;
}

export class CotMapScreen extends Component<CotMapViewModel, {}> {
  private mapRef: MapLibreView | null = null;
  private cotUnsubscribe?: () => void;

  onCreate(): void {
    this.viewModel = {
      markers: new Map(),
      isConnected: false
    };

    this.connectToTakServer();
  }

  onDestroy(): void {
    if (this.cotUnsubscribe) {
      this.cotUnsubscribe();
    }
  }

  onRender(): void {
    const { markers, isConnected } = this.viewModel;
    const markerArray = Array.from(markers.values());

    <view style={styles.container}>
      <MapLibreView
        ref={(ref) => this.mapRef = ref}
        options={{
          style: 'https://demotiles.maplibre.org/style.json',
          interactive: true,
          showUserLocation: true
        }}
        camera={{
          latitude: 38.8977,
          longitude: -77.0365,
          zoom: 10
        }}
        markers={markerArray}
        onMarkerTap={(id) => this.showCotDetails(id)}
        onMapReady={() => console.log('Map ready for CoT display')}
      />

      {/* Status indicator */}
      <view style={styles.statusBar}>
        <view
          style={{
            width: 12,
            height: 12,
            borderRadius: 6,
            backgroundColor: isConnected ? '#00FF00' : '#FF0000'
          }}
        />
        <label value={isConnected ? 'Connected' : 'Disconnected'} />
        <label value={`Markers: ${markers.size}`} />
      </view>
    </view>;
  }

  private async connectToTakServer(): Promise<void> {
    try {
      const connectionId = await takService.connect({
        host: 'tak.example.com',
        port: 8089,
        protocol: 'tls'
      });

      if (connectionId !== null) {
        this.updateViewModel({ connectionId, isConnected: true });
        this.subscribeToCot(connectionId);
      }
    } catch (error) {
      console.error('Failed to connect to TAK server:', error);
    }
  }

  private subscribeToCot(connectionId: number): void {
    this.cotUnsubscribe = takService.onCotReceived(
      connectionId,
      (xml: string) => this.handleCotMessage(xml)
    );
  }

  private handleCotMessage(xml: string): void {
    const event = parseCotXml(xml);
    if (!event) return;

    const marker = createMarkerFromCot(
      event.uid,
      event.point.lat,
      event.point.lon,
      event.detail?.contact?.callsign,
      event.type
    );

    // Update or add marker
    const markers = new Map(this.viewModel.markers);
    markers.set(event.uid, marker);
    this.updateViewModel({ markers });

    console.log(`Updated marker: ${event.uid} at ${event.point.lat}, ${event.point.lon}`);
  }

  private showCotDetails(markerId: string): void {
    const marker = this.viewModel.markers.get(markerId);
    if (marker) {
      console.log('CoT Details:', marker);
      // TODO: Show details modal or panel
    }
  }

  private updateViewModel(updates: Partial<CotMapViewModel>): void {
    this.viewModel = { ...this.viewModel, ...updates };
    this.requestRender();
  }
}
```

---

## User Interaction

Handle map taps, long presses, and gestures.

```typescript
interface InteractiveMapViewModel {
  lastTapLocation?: { latitude: number; longitude: number };
  markers: MapMarker[];
}

export class InteractiveMapScreen extends Component<InteractiveMapViewModel, {}> {
  private mapRef: MapLibreView | null = null;

  onCreate(): void {
    this.viewModel = {
      markers: []
    };
  }

  onRender(): void {
    const { lastTapLocation, markers } = this.viewModel;

    <view style={styles.container}>
      <MapLibreView
        ref={(ref) => this.mapRef = ref}
        markers={markers}
        camera={{
          latitude: 38.8977,
          longitude: -77.0365,
          zoom: 10
        }}
        onMapTap={(event) => this.handleMapTap(event)}
        onMarkerTap={(id) => this.handleMarkerTap(id)}
        onCameraChanged={(camera) => this.handleCameraChange(camera)}
      />

      {/* Show tap location */}
      {lastTapLocation && (
        <view style={styles.locationDisplay}>
          <label value={`Lat: ${lastTapLocation.latitude.toFixed(4)}`} />
          <label value={`Lon: ${lastTapLocation.longitude.toFixed(4)}`} />
          <button onPress={() => this.addMarkerAtTap()}>
            Add Marker Here
          </button>
        </view>
      )}
    </view>;
  }

  private handleMapTap(event: MapTapEvent): void {
    console.log('Map tapped at:', event.latitude, event.longitude);
    this.updateViewModel({
      lastTapLocation: {
        latitude: event.latitude,
        longitude: event.longitude
      }
    });
  }

  private handleMarkerTap(markerId: string): void {
    console.log('Marker tapped:', markerId);
    // TODO: Show marker info or delete option
  }

  private handleCameraChange(camera: MapCamera): void {
    console.log('Camera changed - zoom:', camera.zoom);
  }

  private addMarkerAtTap(): void {
    const { lastTapLocation } = this.viewModel;
    if (!lastTapLocation) return;

    const newMarker: MapMarker = {
      id: `tap-marker-${Date.now()}`,
      latitude: lastTapLocation.latitude,
      longitude: lastTapLocation.longitude,
      title: 'Tap Marker',
      color: '#FF00FF'
    };

    this.mapRef?.addMarker(newMarker);
    this.updateViewModel({ lastTapLocation: undefined });
  }

  private updateViewModel(updates: Partial<InteractiveMapViewModel>): void {
    this.viewModel = { ...this.viewModel, ...updates };
    this.requestRender();
  }
}
```

---

## Custom Styling

Use different map styles and themes.

```typescript
interface StyledMapViewModel {
  currentStyle: string;
}

export class StyledMapScreen extends Component<StyledMapViewModel, {}> {
  private mapRef: MapLibreView | null = null;

  private mapStyles = {
    osm: 'https://demotiles.maplibre.org/style.json',
    satellite: 'https://tiles.stadiamaps.com/styles/alidade_satellite.json',
    dark: 'https://tiles.stadiamaps.com/styles/alidade_smooth_dark.json',
    light: 'https://tiles.stadiamaps.com/styles/alidade_smooth.json'
  };

  onCreate(): void {
    this.viewModel = {
      currentStyle: this.mapStyles.osm
    };
  }

  onRender(): void {
    const { currentStyle } = this.viewModel;

    <view style={styles.container}>
      <MapLibreView
        ref={(ref) => this.mapRef = ref}
        options={{
          style: currentStyle,
          interactive: true,
          showCompass: true,
          showScaleBar: true
        }}
        camera={{
          latitude: 38.8977,
          longitude: -77.0365,
          zoom: 10
        }}
      />

      {/* Style selector */}
      <view style={styles.styleSelector}>
        <button onPress={() => this.changeStyle('osm')}>
          OpenStreetMap
        </button>
        <button onPress={() => this.changeStyle('satellite')}>
          Satellite
        </button>
        <button onPress={() => this.changeStyle('dark')}>
          Dark
        </button>
        <button onPress={() => this.changeStyle('light')}>
          Light
        </button>
      </view>
    </view>;
  }

  private changeStyle(styleKey: keyof typeof this.mapStyles): void {
    const newStyle = this.mapStyles[styleKey];
    this.mapRef?.setOptions({ style: newStyle });
    this.updateViewModel({ currentStyle: newStyle });
  }

  private updateViewModel(updates: Partial<StyledMapViewModel>): void {
    this.viewModel = { ...this.viewModel, ...updates };
    this.requestRender();
  }
}
```

---

## Performance Optimization

Handle large marker sets efficiently.

```typescript
import { MapLibreView, MapMarker, createCameraFromMarkers } from '../components/MapLibreView';

interface OptimizedMapViewModel {
  allMarkers: MapMarker[];
  visibleMarkers: MapMarker[];
  currentCamera?: MapCamera;
  markerLimit: number;
}

export class OptimizedMapScreen extends Component<OptimizedMapViewModel, {}> {
  private mapRef: MapLibreView | null = null;

  onCreate(): void {
    this.viewModel = {
      allMarkers: this.generateLargeMarkerSet(),
      visibleMarkers: [],
      markerLimit: 100
    };

    // Set initial camera to show all markers
    const camera = createCameraFromMarkers(this.viewModel.allMarkers);
    if (camera) {
      this.updateViewModel({ currentCamera: camera });
    }
  }

  onRender(): void {
    const { visibleMarkers, currentCamera } = this.viewModel;

    <view style={styles.container}>
      <MapLibreView
        ref={(ref) => this.mapRef = ref}
        markers={visibleMarkers}
        camera={currentCamera}
        onCameraChanged={(camera) => this.handleCameraChange(camera)}
        onMapReady={() => this.updateVisibleMarkers()}
      />

      <view style={styles.stats}>
        <label value={`Total: ${this.viewModel.allMarkers.length}`} />
        <label value={`Visible: ${visibleMarkers.length}`} />
      </view>
    </view>;
  }

  private generateLargeMarkerSet(): MapMarker[] {
    const markers: MapMarker[] = [];

    // Generate 1000 random markers around DC area
    for (let i = 0; i < 1000; i++) {
      markers.push({
        id: `marker-${i}`,
        latitude: 38.8977 + (Math.random() - 0.5) * 2,
        longitude: -77.0365 + (Math.random() - 0.5) * 2,
        title: `Unit ${i}`,
        subtitle: `ID: ${i}`
      });
    }

    return markers;
  }

  private handleCameraChange(camera: MapCamera): void {
    this.updateViewModel({ currentCamera: camera });
    this.updateVisibleMarkers();
  }

  private updateVisibleMarkers(): void {
    const { allMarkers, currentCamera, markerLimit } = this.viewModel;
    if (!currentCamera) return;

    // Calculate viewport bounds based on zoom
    const latRange = this.getLatRangeForZoom(currentCamera.zoom);
    const lonRange = this.getLonRangeForZoom(currentCamera.zoom);

    // Filter markers in viewport
    const visible = allMarkers.filter(marker => {
      const inLatRange = Math.abs(marker.latitude - currentCamera.latitude) < latRange;
      const inLonRange = Math.abs(marker.longitude - currentCamera.longitude) < lonRange;
      return inLatRange && inLonRange;
    });

    // Limit to prevent performance issues
    const limitedVisible = visible.slice(0, markerLimit);

    this.updateViewModel({ visibleMarkers: limitedVisible });
  }

  private getLatRangeForZoom(zoom: number): number {
    // Rough approximation - adjust based on actual testing
    return 180 / Math.pow(2, zoom);
  }

  private getLonRangeForZoom(zoom: number): number {
    return 360 / Math.pow(2, zoom);
  }

  private updateViewModel(updates: Partial<OptimizedMapViewModel>): void {
    this.viewModel = { ...this.viewModel, ...updates };
    this.requestRender();
  }
}

const styles = {
  container: new Style<View>({
    width: '100%',
    height: '100%',
  }),
  stats: new Style<View>({
    position: 'absolute',
    top: 60,
    left: 12,
    padding: 8,
    backgroundColor: 'rgba(0, 0, 0, 0.7)',
    borderRadius: 4,
  }),
};
```

---

## Additional Examples

### Clustering Markers

For very large datasets, implement marker clustering:

```typescript
private clusterMarkers(markers: MapMarker[], zoom: number): MapMarker[] {
  // Simple grid-based clustering
  const gridSize = 0.1 / Math.pow(2, zoom - 10);
  const clusters = new Map<string, MapMarker[]>();

  markers.forEach(marker => {
    const gridKey = `${Math.floor(marker.latitude / gridSize)},${Math.floor(marker.longitude / gridSize)}`;

    if (!clusters.has(gridKey)) {
      clusters.set(gridKey, []);
    }
    clusters.get(gridKey)!.push(marker);
  });

  // Create cluster markers
  return Array.from(clusters.values()).map(group => {
    if (group.length === 1) {
      return group[0];
    }

    // Create cluster marker
    const avgLat = group.reduce((sum, m) => sum + m.latitude, 0) / group.length;
    const avgLon = group.reduce((sum, m) => sum + m.longitude, 0) / group.length;

    return {
      id: `cluster-${group[0].id}`,
      latitude: avgLat,
      longitude: avgLon,
      title: `${group.length} markers`,
      subtitle: 'Cluster',
      metadata: { count: group.length, markers: group }
    };
  });
}
```

### Fit Bounds to Markers

Automatically zoom to show all markers:

```typescript
private fitBoundsToMarkers(markers: MapMarker[]): void {
  const camera = createCameraFromMarkers(markers, 1.2);
  if (camera) {
    this.mapRef?.setCamera({ ...camera, animated: true });
  }
}
```

### Track User Location

Follow user's current location:

```typescript
private followUserLocation: boolean = true;

// In onRender:
<MapLibreView
  options={{
    showUserLocation: true
  }}
  onCameraChanged={(camera) => {
    if (!this.followUserLocation) {
      // User moved map manually
    }
  }}
/>
```

---

For more examples and detailed API documentation, see the [MapLibreView component source](./MapLibreView.tsx).
