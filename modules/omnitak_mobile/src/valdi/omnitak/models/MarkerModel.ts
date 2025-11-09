/**
 * MarkerModel - Type definitions for map markers and rendering
 *
 * Defines all interfaces and types for the OmniTAK marker rendering system.
 * These models bridge CoT data with map visualization.
 */

import { CotEvent } from '../services/CotParser';

/**
 * Zoom level categories for adaptive rendering
 */
export enum MarkerZoomLevel {
  Far = 'far',       // < 8: Simple dots
  Medium = 'medium', // 8-12: Icons with minimal detail
  Close = 'close',   // 12-15: Full symbols
  VeryClose = 'very_close' // > 15: Maximum detail with labels
}

/**
 * Current state of a marker
 */
export enum MarkerState {
  Active = 'active',     // Recently updated
  Stale = 'stale',       // Past stale time but not yet removed
  Removing = 'removing'  // Marked for removal
}

/**
 * Marker lifecycle events
 */
export enum MarkerEvent {
  Created = 'created',
  Updated = 'updated',
  Removed = 'removed',
  Selected = 'selected',
  Deselected = 'deselected'
}

/**
 * Core marker representation for map rendering
 */
export interface MapMarker {
  // Identity
  uid: string;
  type: string; // CoT type code
  callsign?: string;

  // Position
  lat: number;
  lon: number;
  hae: number; // Height above ellipsoid

  // Accuracy
  ce: number; // Circular error (horizontal accuracy)
  le: number; // Linear error (vertical accuracy)

  // Movement
  speed?: number; // m/s
  course?: number; // degrees (0-360, 0=north)

  // Metadata
  affiliation: string; // 'f', 'h', 'n', 'u', etc.
  dimension: string; // 'a' (air), 'g' (ground), 's' (sea/subsurface)

  // Lifecycle
  state: MarkerState;
  created: Date;
  updated: Date;
  stale: Date;

  // Rendering hints
  zoomLevel?: MarkerZoomLevel;
  color?: string;
  sidc?: string; // MIL-STD-2525 Symbol ID Code

  // Additional data
  detail?: Record<string, any>;

  // UI state
  selected?: boolean;
  hovered?: boolean;
}

/**
 * Options for marker creation/update
 */
export interface MarkerOptions {
  // Override default rendering
  color?: string;
  sidc?: string;

  // Custom metadata
  detail?: Record<string, any>;

  // UI hints
  selected?: boolean;
}

/**
 * Marker statistics for monitoring
 */
export interface MarkerStats {
  total: number;
  active: number;
  stale: number;
  byAffiliation: Record<string, number>;
  byDimension: Record<string, number>;
  byType: Record<string, number>;
}

/**
 * Marker event callback payload
 */
export interface MarkerEventPayload {
  event: MarkerEvent;
  marker: MapMarker;
  previousMarker?: MapMarker; // For updates
  timestamp: Date;
}

/**
 * Symbol rendering output
 */
export interface RenderedSymbol {
  // SVG or image data
  svg?: string;
  imageUrl?: string;

  // Size in pixels
  width: number;
  height: number;

  // Anchor point (0-1 normalized)
  anchorX: number;
  anchorY: number;

  // Additional layers
  accuracyCircle?: GeoJSONCircle;
  headingArrow?: GeoJSONArrow;
  label?: SymbolLabel;
}

/**
 * GeoJSON circle for accuracy visualization
 */
export interface GeoJSONCircle {
  type: 'Feature';
  geometry: {
    type: 'Polygon';
    coordinates: number[][][]; // [[[lon, lat], ...]]
  };
  properties: {
    radius: number; // meters
    color: string;
    opacity: number;
  };
}

/**
 * GeoJSON arrow for heading/course visualization
 */
export interface GeoJSONArrow {
  type: 'Feature';
  geometry: {
    type: 'LineString';
    coordinates: number[][]; // [[lon, lat], ...]
  };
  properties: {
    heading: number; // degrees
    color: string;
    width: number;
  };
}

/**
 * Symbol text label
 */
export interface SymbolLabel {
  text: string;
  color: string;
  size: number;
  offsetX: number;
  offsetY: number;
  font?: string;
}

/**
 * MapLibre GeoJSON source data
 */
export interface MarkerGeoJSON {
  type: 'FeatureCollection';
  features: MarkerGeoJSONFeature[];
}

/**
 * Individual marker as GeoJSON feature
 */
export interface MarkerGeoJSONFeature {
  type: 'Feature';
  id: string; // uid
  geometry: {
    type: 'Point';
    coordinates: [number, number]; // [lon, lat]
  };
  properties: {
    uid: string;
    type: string;
    callsign?: string;
    affiliation: string;
    dimension: string;
    state: MarkerState;
    course?: number;
    speed?: number;
    color?: string;
    sidc?: string;
    iconSvg?: string; // Pre-rendered SVG for this zoom level
    selected?: boolean;
    hovered?: boolean;
  };
}

/**
 * Marker cluster for rendering many markers
 */
export interface MarkerCluster {
  id: string;
  lat: number;
  lon: number;
  count: number;
  markers: MapMarker[];
  bounds: {
    north: number;
    south: number;
    east: number;
    west: number;
  };
}

/**
 * Options for marker filtering
 */
export interface MarkerFilter {
  affiliations?: string[]; // Only show these affiliations
  dimensions?: string[]; // Only show these dimensions
  types?: string[]; // Only show these CoT types
  states?: MarkerState[]; // Only show these states
  bounds?: {
    north: number;
    south: number;
    east: number;
    west: number;
  };
  search?: string; // Search by callsign or UID
}

/**
 * Convert CoT event to map marker
 */
export function cotToMarker(event: CotEvent, options?: MarkerOptions): MapMarker {
  const now = new Date();
  const parts = event.type.split('-');
  const dimension = parts[0] || 'g';
  const affiliation = parts[1] || 'u';

  return {
    uid: event.uid,
    type: event.type,
    callsign: event.detail?.contact?.callsign,
    lat: event.point.lat,
    lon: event.point.lon,
    hae: event.point.hae,
    ce: event.point.ce,
    le: event.point.le,
    speed: event.detail?.track?.speed,
    course: event.detail?.track?.course,
    affiliation,
    dimension,
    state: event.stale > now ? MarkerState.Active : MarkerState.Stale,
    created: now,
    updated: now,
    stale: event.stale,
    color: options?.color,
    sidc: options?.sidc,
    detail: options?.detail || event.detail,
    selected: options?.selected || false,
    hovered: false,
  };
}

/**
 * Determine zoom level category from numeric zoom
 */
export function getZoomLevel(zoom: number): MarkerZoomLevel {
  if (zoom < 8) return MarkerZoomLevel.Far;
  if (zoom < 12) return MarkerZoomLevel.Medium;
  if (zoom < 15) return MarkerZoomLevel.Close;
  return MarkerZoomLevel.VeryClose;
}

/**
 * Check if marker matches filter criteria
 */
export function markerMatchesFilter(marker: MapMarker, filter: MarkerFilter): boolean {
  // Affiliation filter
  if (filter.affiliations && !filter.affiliations.includes(marker.affiliation)) {
    return false;
  }

  // Dimension filter
  if (filter.dimensions && !filter.dimensions.includes(marker.dimension)) {
    return false;
  }

  // Type filter
  if (filter.types && !filter.types.includes(marker.type)) {
    return false;
  }

  // State filter
  if (filter.states && !filter.states.includes(marker.state)) {
    return false;
  }

  // Bounds filter
  if (filter.bounds) {
    const { north, south, east, west } = filter.bounds;
    if (marker.lat < south || marker.lat > north ||
        marker.lon < west || marker.lon > east) {
      return false;
    }
  }

  // Search filter
  if (filter.search) {
    const searchLower = filter.search.toLowerCase();
    const matchesCallsign = marker.callsign?.toLowerCase().includes(searchLower);
    const matchesUid = marker.uid.toLowerCase().includes(searchLower);
    if (!matchesCallsign && !matchesUid) {
      return false;
    }
  }

  return true;
}

/**
 * Calculate distance between two points in meters
 */
export function calculateDistance(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number
): number {
  const R = 6371e3; // Earth radius in meters
  const φ1 = (lat1 * Math.PI) / 180;
  const φ2 = (lat2 * Math.PI) / 180;
  const Δφ = ((lat2 - lat1) * Math.PI) / 180;
  const Δλ = ((lon2 - lon1) * Math.PI) / 180;

  const a =
    Math.sin(Δφ / 2) * Math.sin(Δφ / 2) +
    Math.cos(φ1) * Math.cos(φ2) * Math.sin(Δλ / 2) * Math.sin(Δλ / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return R * c;
}

/**
 * Calculate bearing between two points in degrees
 */
export function calculateBearing(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number
): number {
  const φ1 = (lat1 * Math.PI) / 180;
  const φ2 = (lat2 * Math.PI) / 180;
  const Δλ = ((lon2 - lon1) * Math.PI) / 180;

  const y = Math.sin(Δλ) * Math.cos(φ2);
  const x =
    Math.cos(φ1) * Math.sin(φ2) - Math.sin(φ1) * Math.cos(φ2) * Math.cos(Δλ);
  const θ = Math.atan2(y, x);

  return ((θ * 180) / Math.PI + 360) % 360;
}
