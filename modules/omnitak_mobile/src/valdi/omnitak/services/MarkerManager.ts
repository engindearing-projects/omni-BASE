/**
 * MarkerManager - Central marker lifecycle and state management
 *
 * Handles all marker operations:
 * - Creating, updating, and removing markers
 * - Stale marker cleanup
 * - Event subscriptions
 * - Statistics tracking
 * - Filtering and queries
 */

import {
  MapMarker,
  MarkerState,
  MarkerEvent,
  MarkerEventPayload,
  MarkerOptions,
  MarkerStats,
  MarkerFilter,
  MarkerZoomLevel,
  cotToMarker,
  markerMatchesFilter,
  getZoomLevel,
} from '../models/MarkerModel';
import { CotEvent } from './CotParser';

export type MarkerEventCallback = (payload: MarkerEventPayload) => void;

/**
 * Configuration for MarkerManager
 */
export interface MarkerManagerConfig {
  staleCheckInterval?: number; // ms, default 5000
  autoRemoveStaleAfter?: number; // ms after stale time, default 60000
  maxMarkers?: number; // Maximum markers to keep, default 10000
}

/**
 * MarkerManager manages all map markers and their lifecycle
 */
export class MarkerManager {
  private markers: Map<string, MapMarker> = new Map();
  private listeners: Map<MarkerEvent, Set<MarkerEventCallback>> = new Map();
  private staleCheckTimer?: number;
  private config: Required<MarkerManagerConfig>;

  constructor(config?: MarkerManagerConfig) {
    this.config = {
      staleCheckInterval: config?.staleCheckInterval ?? 5000,
      autoRemoveStaleAfter: config?.autoRemoveStaleAfter ?? 60000,
      maxMarkers: config?.maxMarkers ?? 10000,
    };

    // Initialize event listener maps
    Object.values(MarkerEvent).forEach((event) => {
      this.listeners.set(event, new Set());
    });

    this.startStaleCheck();
  }

  /**
   * Create or update marker from CoT event
   */
  public processCoT(event: CotEvent, options?: MarkerOptions): MapMarker {
    const existing = this.markers.get(event.uid);

    if (existing) {
      return this.updateMarker(event.uid, event, options);
    } else {
      return this.createMarker(event, options);
    }
  }

  /**
   * Create a new marker
   */
  private createMarker(event: CotEvent, options?: MarkerOptions): MapMarker {
    // Check max markers limit
    if (this.markers.size >= this.config.maxMarkers) {
      this.removeOldestStaleMarker();
    }

    const marker = cotToMarker(event, options);
    this.markers.set(marker.uid, marker);

    this.emitEvent({
      event: MarkerEvent.Created,
      marker,
      timestamp: new Date(),
    });

    return marker;
  }

  /**
   * Update existing marker
   */
  private updateMarker(
    uid: string,
    event: CotEvent,
    options?: MarkerOptions
  ): MapMarker {
    const existing = this.markers.get(uid);
    if (!existing) {
      // Marker was removed, create new one
      return this.createMarker(event, options);
    }

    const previousMarker = { ...existing };
    const now = new Date();

    // Update marker data
    existing.type = event.type;
    existing.callsign = event.detail?.contact?.callsign || existing.callsign;
    existing.lat = event.point.lat;
    existing.lon = event.point.lon;
    existing.hae = event.point.hae;
    existing.ce = event.point.ce;
    existing.le = event.point.le;
    existing.speed = event.detail?.track?.speed;
    existing.course = event.detail?.track?.course;
    existing.updated = now;
    existing.stale = event.stale;
    existing.state = event.stale > now ? MarkerState.Active : MarkerState.Stale;

    // Apply options
    if (options?.color) existing.color = options.color;
    if (options?.sidc) existing.sidc = options.sidc;
    if (options?.detail) existing.detail = { ...existing.detail, ...options.detail };
    if (options?.selected !== undefined) existing.selected = options.selected;

    this.emitEvent({
      event: MarkerEvent.Updated,
      marker: existing,
      previousMarker,
      timestamp: now,
    });

    return existing;
  }

  /**
   * Remove marker by UID
   */
  public removeMarker(uid: string): boolean {
    const marker = this.markers.get(uid);
    if (!marker) return false;

    marker.state = MarkerState.Removing;
    this.markers.delete(uid);

    this.emitEvent({
      event: MarkerEvent.Removed,
      marker,
      timestamp: new Date(),
    });

    return true;
  }

  /**
   * Get marker by UID
   */
  public getMarker(uid: string): MapMarker | undefined {
    return this.markers.get(uid);
  }

  /**
   * Get all markers
   */
  public getAllMarkers(): MapMarker[] {
    return Array.from(this.markers.values());
  }

  /**
   * Get markers matching filter
   */
  public getMarkers(filter?: MarkerFilter): MapMarker[] {
    const markers = this.getAllMarkers();
    if (!filter) return markers;

    return markers.filter((marker) => markerMatchesFilter(marker, filter));
  }

  /**
   * Get marker count
   */
  public getMarkerCount(): number {
    return this.markers.size;
  }

  /**
   * Get marker statistics
   */
  public getStats(): MarkerStats {
    const markers = this.getAllMarkers();
    const stats: MarkerStats = {
      total: markers.length,
      active: 0,
      stale: 0,
      byAffiliation: {},
      byDimension: {},
      byType: {},
    };

    markers.forEach((marker) => {
      // Count by state
      if (marker.state === MarkerState.Active) {
        stats.active++;
      } else if (marker.state === MarkerState.Stale) {
        stats.stale++;
      }

      // Count by affiliation
      stats.byAffiliation[marker.affiliation] =
        (stats.byAffiliation[marker.affiliation] || 0) + 1;

      // Count by dimension
      stats.byDimension[marker.dimension] =
        (stats.byDimension[marker.dimension] || 0) + 1;

      // Count by type
      stats.byType[marker.type] = (stats.byType[marker.type] || 0) + 1;
    });

    return stats;
  }

  /**
   * Select marker
   */
  public selectMarker(uid: string): boolean {
    const marker = this.markers.get(uid);
    if (!marker) return false;

    const previousMarker = { ...marker };
    marker.selected = true;

    this.emitEvent({
      event: MarkerEvent.Selected,
      marker,
      previousMarker,
      timestamp: new Date(),
    });

    return true;
  }

  /**
   * Deselect marker
   */
  public deselectMarker(uid: string): boolean {
    const marker = this.markers.get(uid);
    if (!marker) return false;

    const previousMarker = { ...marker };
    marker.selected = false;

    this.emitEvent({
      event: MarkerEvent.Deselected,
      marker,
      previousMarker,
      timestamp: new Date(),
    });

    return true;
  }

  /**
   * Deselect all markers
   */
  public deselectAll(): void {
    this.markers.forEach((marker) => {
      if (marker.selected) {
        this.deselectMarker(marker.uid);
      }
    });
  }

  /**
   * Update marker zoom level for all markers
   */
  public updateZoomLevel(zoom: number): void {
    const zoomLevel = getZoomLevel(zoom);
    this.markers.forEach((marker) => {
      marker.zoomLevel = zoomLevel;
    });
  }

  /**
   * Subscribe to marker events
   */
  public on(event: MarkerEvent, callback: MarkerEventCallback): () => void {
    const listeners = this.listeners.get(event);
    if (listeners) {
      listeners.add(callback);
    }

    // Return unsubscribe function
    return () => {
      const listeners = this.listeners.get(event);
      if (listeners) {
        listeners.delete(callback);
      }
    };
  }

  /**
   * Emit marker event to all listeners
   */
  private emitEvent(payload: MarkerEventPayload): void {
    const listeners = this.listeners.get(payload.event);
    if (listeners) {
      listeners.forEach((callback) => {
        try {
          callback(payload);
        } catch (error) {
          console.error(`Error in marker event listener for ${payload.event}:`, error);
        }
      });
    }
  }

  /**
   * Start periodic stale marker check
   */
  private startStaleCheck(): void {
    this.staleCheckTimer = setInterval(() => {
      this.checkStaleMarkers();
    }, this.config.staleCheckInterval);
  }

  /**
   * Stop periodic stale marker check
   */
  private stopStaleCheck(): void {
    if (this.staleCheckTimer) {
      clearInterval(this.staleCheckTimer);
      this.staleCheckTimer = undefined;
    }
  }

  /**
   * Check for stale markers and update/remove them
   */
  private checkStaleMarkers(): void {
    const now = new Date();
    const removeThreshold = new Date(
      now.getTime() - this.config.autoRemoveStaleAfter
    );

    const markersToRemove: string[] = [];

    this.markers.forEach((marker) => {
      // Mark as stale if past stale time
      if (marker.state === MarkerState.Active && marker.stale < now) {
        const previousMarker = { ...marker };
        marker.state = MarkerState.Stale;

        this.emitEvent({
          event: MarkerEvent.Updated,
          marker,
          previousMarker,
          timestamp: now,
        });
      }

      // Remove if stale for too long
      if (marker.state === MarkerState.Stale && marker.stale < removeThreshold) {
        markersToRemove.push(marker.uid);
      }
    });

    // Remove stale markers
    markersToRemove.forEach((uid) => {
      this.removeMarker(uid);
    });

    if (markersToRemove.length > 0) {
      console.log(`Removed ${markersToRemove.length} stale markers`);
    }
  }

  /**
   * Remove oldest stale marker to make room for new ones
   */
  private removeOldestStaleMarker(): void {
    let oldestStale: MapMarker | null = null;

    this.markers.forEach((marker) => {
      if (marker.state === MarkerState.Stale) {
        if (!oldestStale || marker.stale < oldestStale.stale) {
          oldestStale = marker;
        }
      }
    });

    // If no stale markers, remove oldest marker
    if (!oldestStale) {
      let oldest: MapMarker | null = null;
      this.markers.forEach((marker) => {
        if (!oldest || marker.updated < oldest.updated) {
          oldest = marker;
        }
      });
      oldestStale = oldest;
    }

    if (oldestStale) {
      console.warn(
        `Max markers (${this.config.maxMarkers}) reached, removing oldest: ${oldestStale[0]}`
      );
      this.removeMarker(oldestStale[0]);
    }
  }

  /**
   * Clear all markers
   */
  public clear(): void {
    const markers = this.getAllMarkers();
    markers.forEach((marker) => {
      this.removeMarker(marker.uid);
    });
  }

  /**
   * Cleanup resources
   */
  public destroy(): void {
    this.stopStaleCheck();
    this.clear();
    this.listeners.clear();
  }

  /**
   * Get markers within bounds
   */
  public getMarkersInBounds(bounds: {
    north: number;
    south: number;
    east: number;
    west: number;
  }): MapMarker[] {
    return this.getMarkers({ bounds });
  }

  /**
   * Search markers by callsign or UID
   */
  public searchMarkers(query: string): MapMarker[] {
    return this.getMarkers({ search: query });
  }

  /**
   * Get markers by affiliation
   */
  public getMarkersByAffiliation(affiliations: string[]): MapMarker[] {
    return this.getMarkers({ affiliations });
  }

  /**
   * Get markers by dimension
   */
  public getMarkersByDimension(dimensions: string[]): MapMarker[] {
    return this.getMarkers({ dimensions });
  }

  /**
   * Get markers by state
   */
  public getMarkersByState(states: MarkerState[]): MapMarker[] {
    return this.getMarkers({ states });
  }

  /**
   * Export markers as JSON
   */
  public exportMarkers(): string {
    const markers = this.getAllMarkers();
    return JSON.stringify(markers, null, 2);
  }

  /**
   * Get debug info
   */
  public getDebugInfo(): {
    config: Required<MarkerManagerConfig>;
    stats: MarkerStats;
    listenerCounts: Record<string, number>;
  } {
    const listenerCounts: Record<string, number> = {};
    this.listeners.forEach((listeners, event) => {
      listenerCounts[event] = listeners.size;
    });

    return {
      config: this.config,
      stats: this.getStats(),
      listenerCounts,
    };
  }
}

/**
 * Create a singleton instance for global use
 */
export const markerManager = new MarkerManager();
