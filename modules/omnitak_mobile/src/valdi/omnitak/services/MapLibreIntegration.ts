/**
 * MapLibreIntegration - Bridge between MarkerManager and MapLibre GL
 *
 * Manages:
 * - GeoJSON source updates for markers
 * - Layer configuration (symbols, clusters, accuracy circles, labels)
 * - Map event handlers (click, hover, zoom)
 * - Real-time marker rendering
 *
 * This is a TypeScript interface definition. The actual MapLibre GL Native
 * integration will be implemented in platform-specific code (iOS/Android).
 */

import {
  MapMarker,
  MarkerGeoJSON,
  MarkerGeoJSONFeature,
  MarkerEvent,
  MarkerEventPayload,
  MarkerZoomLevel,
  getZoomLevel,
} from '../models/MarkerModel';
import { MarkerManager } from './MarkerManager';
import { SymbolRenderer } from './SymbolRenderer';

/**
 * MapLibre map instance interface (simplified)
 * In production, this would be the actual MapLibre GL types
 */
export interface MapLibreMap {
  // Source management
  addSource(id: string, source: any): void;
  getSource(id: string): any;
  removeSource(id: string): void;

  // Layer management
  addLayer(layer: any, beforeId?: string): void;
  getLayer(id: string): any;
  removeLayer(id: string): void;
  setLayoutProperty(layerId: string, name: string, value: any): void;
  setPaintProperty(layerId: string, name: string, value: any): void;

  // Event handling
  on(event: string, layerId: string | undefined, handler: (e: any) => void): void;
  off(event: string, layerId: string | undefined, handler: (e: any) => void): void;

  // Map state
  getZoom(): number;
  getCenter(): { lng: number; lat: number };
  getBounds(): {
    getNorth(): number;
    getSouth(): number;
    getEast(): number;
    getWest(): number;
  };

  // Camera
  flyTo(options: any): void;
  easeTo(options: any): void;
}

/**
 * Configuration for MapLibre integration
 */
export interface MapLibreIntegrationConfig {
  // Source IDs
  markersSourceId?: string;
  accuracySourceId?: string;
  headingSourceId?: string;

  // Layer IDs
  accuracyLayerId?: string;
  headingLayerId?: string;
  symbolLayerId?: string;
  clusterLayerId?: string;
  clusterCountLayerId?: string;
  labelLayerId?: string;

  // Clustering
  enableClustering?: boolean;
  clusterRadius?: number;
  clusterMaxZoom?: number;

  // Auto-update
  autoUpdate?: boolean;
  updateInterval?: number; // ms
}

/**
 * MapLibreIntegration manages the connection between markers and the map
 */
export class MapLibreIntegration {
  private map: MapLibreMap;
  private markerManager: MarkerManager;
  private symbolRenderer: SymbolRenderer;
  private config: Required<MapLibreIntegrationConfig>;
  private updateTimer?: number;
  private eventHandlers: Map<string, any> = new Map();
  private unsubscribers: (() => void)[] = [];

  constructor(
    map: MapLibreMap,
    markerManager: MarkerManager,
    symbolRenderer: SymbolRenderer,
    config?: MapLibreIntegrationConfig
  ) {
    this.map = map;
    this.markerManager = markerManager;
    this.symbolRenderer = symbolRenderer;

    this.config = {
      markersSourceId: config?.markersSourceId ?? 'markers',
      accuracySourceId: config?.accuracySourceId ?? 'marker-accuracy',
      headingSourceId: config?.headingSourceId ?? 'marker-heading',
      accuracyLayerId: config?.accuracyLayerId ?? 'marker-accuracy-layer',
      headingLayerId: config?.headingLayerId ?? 'marker-heading-layer',
      symbolLayerId: config?.symbolLayerId ?? 'marker-symbols',
      clusterLayerId: config?.clusterLayerId ?? 'marker-clusters',
      clusterCountLayerId: config?.clusterCountLayerId ?? 'marker-cluster-count',
      labelLayerId: config?.labelLayerId ?? 'marker-labels',
      enableClustering: config?.enableClustering ?? true,
      clusterRadius: config?.clusterRadius ?? 50,
      clusterMaxZoom: config?.clusterMaxZoom ?? 14,
      autoUpdate: config?.autoUpdate ?? true,
      updateInterval: config?.updateInterval ?? 1000,
    };

    this.initialize();
  }

  /**
   * Initialize map sources and layers
   */
  private initialize(): void {
    this.setupSources();
    this.setupLayers();
    this.setupEventHandlers();
    this.subscribeToMarkerEvents();

    if (this.config.autoUpdate) {
      this.startAutoUpdate();
    }

    // Initial render
    this.update();
  }

  /**
   * Setup GeoJSON sources
   */
  private setupSources(): void {
    // Markers source
    this.map.addSource(this.config.markersSourceId, {
      type: 'geojson',
      data: this.createEmptyGeoJSON(),
      cluster: this.config.enableClustering,
      clusterRadius: this.config.clusterRadius,
      clusterMaxZoom: this.config.clusterMaxZoom,
    });

    // Accuracy circles source
    this.map.addSource(this.config.accuracySourceId, {
      type: 'geojson',
      data: this.createEmptyGeoJSON(),
    });

    // Heading arrows source
    this.map.addSource(this.config.headingSourceId, {
      type: 'geojson',
      data: this.createEmptyGeoJSON(),
    });
  }

  /**
   * Setup map layers
   */
  private setupLayers(): void {
    // Accuracy circles layer (bottom)
    this.map.addLayer({
      id: this.config.accuracyLayerId,
      type: 'fill',
      source: this.config.accuracySourceId,
      paint: {
        'fill-color': ['get', 'color'],
        'fill-opacity': ['get', 'opacity'],
      },
    });

    // Heading arrows layer
    this.map.addLayer({
      id: this.config.headingLayerId,
      type: 'line',
      source: this.config.headingSourceId,
      paint: {
        'line-color': ['get', 'color'],
        'line-width': ['get', 'width'],
      },
    });

    // Cluster circles
    if (this.config.enableClustering) {
      this.map.addLayer({
        id: this.config.clusterLayerId,
        type: 'circle',
        source: this.config.markersSourceId,
        filter: ['has', 'point_count'],
        paint: {
          'circle-color': [
            'step',
            ['get', 'point_count'],
            '#51bbd6', // < 10
            10,
            '#f1f075', // 10-30
            30,
            '#f28cb1', // > 30
          ],
          'circle-radius': [
            'step',
            ['get', 'point_count'],
            20, // < 10
            10,
            30, // 10-30
            30,
            40, // > 30
          ],
        },
      });

      // Cluster count
      this.map.addLayer({
        id: this.config.clusterCountLayerId,
        type: 'symbol',
        source: this.config.markersSourceId,
        filter: ['has', 'point_count'],
        layout: {
          'text-field': '{point_count_abbreviated}',
          'text-font': ['Arial Unicode MS Bold'],
          'text-size': 12,
        },
        paint: {
          'text-color': '#ffffff',
        },
      });
    }

    // Individual marker symbols
    this.map.addLayer({
      id: this.config.symbolLayerId,
      type: 'symbol',
      source: this.config.markersSourceId,
      filter: ['!', ['has', 'point_count']],
      layout: {
        'icon-image': ['get', 'iconSvg'], // Would use pre-rendered icons
        'icon-size': 1,
        'icon-allow-overlap': true,
        'icon-ignore-placement': false,
      },
      paint: {
        'icon-opacity': [
          'case',
          ['==', ['get', 'state'], 'stale'],
          0.5,
          1.0,
        ],
      },
    });

    // Labels
    this.map.addLayer({
      id: this.config.labelLayerId,
      type: 'symbol',
      source: this.config.markersSourceId,
      filter: ['!', ['has', 'point_count']],
      layout: {
        'text-field': ['get', 'callsign'],
        'text-font': ['Arial Unicode MS Regular'],
        'text-size': 12,
        'text-offset': [0, 1.5],
        'text-anchor': 'top',
      },
      paint: {
        'text-color': '#ffffff',
        'text-halo-color': '#000000',
        'text-halo-width': 2,
      },
    });
  }

  /**
   * Setup map event handlers
   */
  private setupEventHandlers(): void {
    // Click on marker
    const clickHandler = (e: any) => {
      if (e.features && e.features.length > 0) {
        const feature = e.features[0];
        const uid = feature.properties.uid;

        // Deselect all others
        this.markerManager.deselectAll();

        // Select clicked marker
        this.markerManager.selectMarker(uid);

        // Optionally fly to marker
        this.flyToMarker(uid);
      }
    };

    this.map.on('click', this.config.symbolLayerId, clickHandler);
    this.eventHandlers.set('click', clickHandler);

    // Hover effect
    const mouseEnterHandler = () => {
      (this.map as any).getCanvas().style.cursor = 'pointer';
    };

    const mouseLeaveHandler = () => {
      (this.map as any).getCanvas().style.cursor = '';
    };

    this.map.on('mouseenter', this.config.symbolLayerId, mouseEnterHandler);
    this.map.on('mouseleave', this.config.symbolLayerId, mouseLeaveHandler);
    this.eventHandlers.set('mouseenter', mouseEnterHandler);
    this.eventHandlers.set('mouseleave', mouseLeaveHandler);

    // Cluster click to zoom
    if (this.config.enableClustering) {
      const clusterClickHandler = (e: any) => {
        const features = (this.map as any).queryRenderedFeatures?.(e.point, {
          layers: [this.config.clusterLayerId],
        });

        if (features && features.length > 0) {
          const clusterId = features[0].properties.cluster_id;
          const source = this.map.getSource(this.config.markersSourceId);

          // Get cluster expansion zoom
          (source as any).getClusterExpansionZoom(clusterId, (err: any, zoom: number) => {
            if (err) return;

            this.map.easeTo({
              center: features[0].geometry.coordinates,
              zoom: zoom,
            });
          });
        }
      };

      this.map.on('click', this.config.clusterLayerId, clusterClickHandler);
      this.eventHandlers.set('cluster-click', clusterClickHandler);
    }

    // Zoom change - update marker zoom levels
    const zoomHandler = () => {
      const zoom = this.map.getZoom();
      this.markerManager.updateZoomLevel(zoom);
      this.update(); // Re-render at new zoom level
    };

    this.map.on('zoom', undefined, zoomHandler);
    this.eventHandlers.set('zoom', zoomHandler);
  }

  /**
   * Subscribe to marker manager events
   */
  private subscribeToMarkerEvents(): void {
    // Update map when markers change
    const events = [
      MarkerEvent.Created,
      MarkerEvent.Updated,
      MarkerEvent.Removed,
      MarkerEvent.Selected,
      MarkerEvent.Deselected,
    ];

    events.forEach((event) => {
      const unsubscribe = this.markerManager.on(event, () => {
        if (!this.config.autoUpdate) {
          this.update();
        }
      });
      this.unsubscribers.push(unsubscribe);
    });
  }

  /**
   * Update map with current markers
   */
  public update(): void {
    const markers = this.markerManager.getAllMarkers();

    // Update markers source
    const markersGeoJSON = this.createMarkersGeoJSON(markers);
    const source = this.map.getSource(this.config.markersSourceId);
    if (source) {
      (source as any).setData(markersGeoJSON);
    }

    // Update accuracy circles
    const accuracyGeoJSON = this.createAccuracyGeoJSON(markers);
    const accuracySource = this.map.getSource(this.config.accuracySourceId);
    if (accuracySource) {
      (accuracySource as any).setData(accuracyGeoJSON);
    }

    // Update heading arrows
    const headingGeoJSON = this.createHeadingGeoJSON(markers);
    const headingSource = this.map.getSource(this.config.headingSourceId);
    if (headingSource) {
      (headingSource as any).setData(headingGeoJSON);
    }
  }

  /**
   * Create GeoJSON for markers
   */
  private createMarkersGeoJSON(markers: MapMarker[]): MarkerGeoJSON {
    const features: MarkerGeoJSONFeature[] = markers.map((marker) => {
      const rendered = this.symbolRenderer.renderSymbol(marker);

      return {
        type: 'Feature',
        id: marker.uid,
        geometry: {
          type: 'Point',
          coordinates: [marker.lon, marker.lat],
        },
        properties: {
          uid: marker.uid,
          type: marker.type,
          callsign: marker.callsign,
          affiliation: marker.affiliation,
          dimension: marker.dimension,
          state: marker.state,
          course: marker.course,
          speed: marker.speed,
          color: marker.color,
          sidc: marker.sidc,
          iconSvg: rendered.svg,
          selected: marker.selected,
          hovered: marker.hovered,
        },
      };
    });

    return {
      type: 'FeatureCollection',
      features,
    };
  }

  /**
   * Create GeoJSON for accuracy circles
   */
  private createAccuracyGeoJSON(markers: MapMarker[]): any {
    const features = markers
      .map((marker) => {
        const rendered = this.symbolRenderer.renderSymbol(marker);
        return rendered.accuracyCircle;
      })
      .filter((circle) => circle !== undefined);

    return {
      type: 'FeatureCollection',
      features,
    };
  }

  /**
   * Create GeoJSON for heading arrows
   */
  private createHeadingGeoJSON(markers: MapMarker[]): any {
    const features = markers
      .map((marker) => {
        const rendered = this.symbolRenderer.renderSymbol(marker);
        return rendered.headingArrow;
      })
      .filter((arrow) => arrow !== undefined);

    return {
      type: 'FeatureCollection',
      features,
    };
  }

  /**
   * Create empty GeoJSON
   */
  private createEmptyGeoJSON(): MarkerGeoJSON {
    return {
      type: 'FeatureCollection',
      features: [],
    };
  }

  /**
   * Start auto-update timer
   */
  private startAutoUpdate(): void {
    this.updateTimer = setInterval(() => {
      this.update();
    }, this.config.updateInterval);
  }

  /**
   * Stop auto-update timer
   */
  private stopAutoUpdate(): void {
    if (this.updateTimer) {
      clearInterval(this.updateTimer);
      this.updateTimer = undefined;
    }
  }

  /**
   * Fly to marker
   */
  public flyToMarker(uid: string, zoom?: number): void {
    const marker = this.markerManager.getMarker(uid);
    if (!marker) return;

    this.map.flyTo({
      center: [marker.lon, marker.lat],
      zoom: zoom || 15,
      duration: 1000,
    });
  }

  /**
   * Fit bounds to all markers
   */
  public fitBounds(padding: number = 50): void {
    const markers = this.markerManager.getAllMarkers();
    if (markers.length === 0) return;

    // Calculate bounds
    let north = -90;
    let south = 90;
    let east = -180;
    let west = 180;

    markers.forEach((marker) => {
      north = Math.max(north, marker.lat);
      south = Math.min(south, marker.lat);
      east = Math.max(east, marker.lon);
      west = Math.min(west, marker.lon);
    });

    // Fit to bounds
    this.map.flyTo({
      center: [(east + west) / 2, (north + south) / 2],
      // Calculate appropriate zoom level based on bounds
      duration: 1000,
    });
  }

  /**
   * Set layer visibility
   */
  public setLayerVisibility(layerId: string, visible: boolean): void {
    this.map.setLayoutProperty(
      layerId,
      'visibility',
      visible ? 'visible' : 'none'
    );
  }

  /**
   * Toggle clustering
   */
  public toggleClustering(enabled: boolean): void {
    this.config.enableClustering = enabled;

    // Would need to recreate source with new clustering settings
    // This is a simplified version
    this.setLayerVisibility(this.config.clusterLayerId, enabled);
    this.setLayerVisibility(this.config.clusterCountLayerId, enabled);
  }

  /**
   * Cleanup resources
   */
  public destroy(): void {
    this.stopAutoUpdate();

    // Unsubscribe from marker events
    this.unsubscribers.forEach((unsubscribe) => unsubscribe());
    this.unsubscribers = [];

    // Remove event handlers
    this.eventHandlers.forEach((handler, event) => {
      if (event === 'zoom') {
        this.map.off(event, undefined, handler);
      } else if (event.startsWith('cluster')) {
        this.map.off('click', this.config.clusterLayerId, handler);
      } else if (event === 'mouseenter' || event === 'mouseleave') {
        this.map.off(event, this.config.symbolLayerId, handler);
      } else {
        this.map.off(event, this.config.symbolLayerId, handler);
      }
    });
    this.eventHandlers.clear();

    // Remove layers
    const layers = [
      this.config.labelLayerId,
      this.config.symbolLayerId,
      this.config.clusterCountLayerId,
      this.config.clusterLayerId,
      this.config.headingLayerId,
      this.config.accuracyLayerId,
    ];

    layers.forEach((layerId) => {
      if (this.map.getLayer(layerId)) {
        this.map.removeLayer(layerId);
      }
    });

    // Remove sources
    const sources = [
      this.config.headingSourceId,
      this.config.accuracySourceId,
      this.config.markersSourceId,
    ];

    sources.forEach((sourceId) => {
      if (this.map.getSource(sourceId)) {
        this.map.removeSource(sourceId);
      }
    });
  }
}
