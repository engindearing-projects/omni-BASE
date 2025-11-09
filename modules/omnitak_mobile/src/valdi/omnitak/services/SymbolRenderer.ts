/**
 * SymbolRenderer - SVG rendering for military symbols
 *
 * Generates SVG symbols for different zoom levels:
 * - Far: Simple dots with affiliation colors
 * - Medium: Basic icons with minimal detail
 * - Close: Full military symbols (uses milsymbol when available)
 * - Very Close: Maximum detail with labels and metadata
 *
 * Also generates accuracy circles, heading arrows, and labels.
 */

import {
  MapMarker,
  MarkerZoomLevel,
  RenderedSymbol,
  GeoJSONCircle,
  GeoJSONArrow,
  SymbolLabel,
} from '../models/MarkerModel';
import { getAffiliationColor } from './CotParser';

/**
 * Configuration for symbol rendering
 */
export interface SymbolRendererConfig {
  // Size multipliers for different zoom levels
  dotSize?: number; // Far zoom, default 8
  iconSize?: number; // Medium zoom, default 24
  symbolSize?: number; // Close zoom, default 32
  detailSize?: number; // Very close zoom, default 48

  // Enable/disable features
  showAccuracyCircle?: boolean; // default true
  showHeadingArrow?: boolean; // default true
  showLabels?: boolean; // default true

  // Accuracy circle settings
  accuracyCircleMinRadius?: number; // meters, default 10
  accuracyCircleOpacity?: number; // 0-1, default 0.3

  // Heading arrow settings
  headingArrowLength?: number; // meters, default 50
  headingArrowWidth?: number; // pixels, default 2
}

/**
 * SymbolRenderer generates visual representations of markers
 */
export class SymbolRenderer {
  private config: Required<SymbolRendererConfig>;

  // Placeholder for milsymbol library integration
  // In production, this would be: import milsymbol from 'milsymbol';
  private milsymbol: any = null;

  constructor(config?: SymbolRendererConfig) {
    this.config = {
      dotSize: config?.dotSize ?? 8,
      iconSize: config?.iconSize ?? 24,
      symbolSize: config?.symbolSize ?? 32,
      detailSize: config?.detailSize ?? 48,
      showAccuracyCircle: config?.showAccuracyCircle ?? true,
      showHeadingArrow: config?.showHeadingArrow ?? true,
      showLabels: config?.showLabels ?? true,
      accuracyCircleMinRadius: config?.accuracyCircleMinRadius ?? 10,
      accuracyCircleOpacity: config?.accuracyCircleOpacity ?? 0.3,
      headingArrowLength: config?.headingArrowLength ?? 50,
      headingArrowWidth: config?.headingArrowWidth ?? 2,
    };

    this.initializeMilsymbol();
  }

  /**
   * Initialize milsymbol library (placeholder)
   */
  private initializeMilsymbol(): void {
    // TODO: Import and initialize milsymbol library
    // this.milsymbol = new milsymbol.Symbol();
    console.log('SymbolRenderer: milsymbol integration pending');
  }

  /**
   * Render complete symbol with all layers
   */
  public renderSymbol(marker: MapMarker): RenderedSymbol {
    const zoomLevel = marker.zoomLevel || MarkerZoomLevel.Medium;
    const color = marker.color || getAffiliationColor(marker.affiliation as any);

    let svg: string;
    let size: number;

    // Generate SVG based on zoom level
    switch (zoomLevel) {
      case MarkerZoomLevel.Far:
        svg = this.renderDot(marker, color);
        size = this.config.dotSize;
        break;

      case MarkerZoomLevel.Medium:
        svg = this.renderIcon(marker, color);
        size = this.config.iconSize;
        break;

      case MarkerZoomLevel.Close:
        svg = this.renderMilSymbol(marker, color);
        size = this.config.symbolSize;
        break;

      case MarkerZoomLevel.VeryClose:
        svg = this.renderDetailedSymbol(marker, color);
        size = this.config.detailSize;
        break;

      default:
        svg = this.renderIcon(marker, color);
        size = this.config.iconSize;
    }

    const rendered: RenderedSymbol = {
      svg,
      width: size,
      height: size,
      anchorX: 0.5,
      anchorY: 0.5,
    };

    // Add accuracy circle if enabled and CE is valid
    if (
      this.config.showAccuracyCircle &&
      marker.ce > 0 &&
      marker.ce < 9999999
    ) {
      rendered.accuracyCircle = this.renderAccuracyCircle(marker, color);
    }

    // Add heading arrow if enabled and course is available
    if (
      this.config.showHeadingArrow &&
      marker.course !== undefined &&
      marker.speed !== undefined &&
      marker.speed > 0.5 // Only show if moving (> 0.5 m/s)
    ) {
      rendered.headingArrow = this.renderHeadingArrow(marker, color);
    }

    // Add label if enabled and callsign available
    if (
      this.config.showLabels &&
      marker.callsign &&
      zoomLevel !== MarkerZoomLevel.Far
    ) {
      rendered.label = this.renderLabel(marker, color);
    }

    return rendered;
  }

  /**
   * Render simple dot for far zoom
   */
  private renderDot(marker: MapMarker, color: string): string {
    const size = this.config.dotSize;
    const radius = size / 2;

    return `
      <svg width="${size}" height="${size}" xmlns="http://www.w3.org/2000/svg">
        <circle cx="${radius}" cy="${radius}" r="${radius - 1}"
          fill="${color}" stroke="#FFFFFF" stroke-width="1" />
      </svg>
    `.trim();
  }

  /**
   * Render basic icon for medium zoom
   */
  private renderIcon(marker: MapMarker, color: string): string {
    const size = this.config.iconSize;
    const shape = this.getAffiliationShape(marker.affiliation);
    const icon = this.getDimensionIcon(marker.dimension);

    return `
      <svg width="${size}" height="${size}" xmlns="http://www.w3.org/2000/svg">
        ${this.renderShape(shape, size, color)}
        <text x="${size / 2}" y="${size / 2 + 2}"
          font-family="Arial" font-size="12"
          fill="#FFFFFF" text-anchor="middle"
          dominant-baseline="middle">${icon}</text>
      </svg>
    `.trim();
  }

  /**
   * Render military symbol using milsymbol library
   */
  private renderMilSymbol(marker: MapMarker, color: string): string {
    // If milsymbol is available, use it
    if (this.milsymbol && marker.sidc) {
      try {
        // TODO: Use actual milsymbol library
        // const symbol = new this.milsymbol.Symbol(marker.sidc, {
        //   size: this.config.symbolSize,
        //   fill: color,
        // });
        // return symbol.asSVG();
      } catch (error) {
        console.error('Error rendering milsymbol:', error);
      }
    }

    // Fallback to basic icon
    return this.renderIcon(marker, color);
  }

  /**
   * Render detailed symbol with metadata
   */
  private renderDetailedSymbol(marker: MapMarker, color: string): string {
    const size = this.config.detailSize;
    const baseSymbol = this.renderMilSymbol(marker, color);

    // For now, just return larger version
    // In production, add speed rings, status indicators, etc.
    return baseSymbol;
  }

  /**
   * Get affiliation shape (friend = rect, hostile = diamond, etc.)
   */
  private getAffiliationShape(
    affiliation: string
  ): 'rect' | 'diamond' | 'circle' | 'clover' {
    switch (affiliation.toLowerCase()) {
      case 'f': // Friend
      case 'a': // Assumed friend
        return 'rect';
      case 'h': // Hostile
        return 'diamond';
      case 'n': // Neutral
        return 'rect';
      case 'u': // Unknown
      case 'p': // Pending
        return 'clover';
      default:
        return 'circle';
    }
  }

  /**
   * Get dimension icon character
   */
  private getDimensionIcon(dimension: string): string {
    switch (dimension.toLowerCase()) {
      case 'a':
        return '✈'; // Air
      case 'g':
        return '⬛'; // Ground
      case 's':
        return '⚓'; // Sea/Subsurface
      default:
        return '?';
    }
  }

  /**
   * Render shape based on affiliation
   */
  private renderShape(
    shape: 'rect' | 'diamond' | 'circle' | 'clover',
    size: number,
    color: string
  ): string {
    const center = size / 2;
    const shapeSize = size * 0.8;
    const half = shapeSize / 2;

    switch (shape) {
      case 'rect':
        return `<rect x="${center - half}" y="${center - half}"
          width="${shapeSize}" height="${shapeSize}"
          fill="${color}" stroke="#FFFFFF" stroke-width="2" />`;

      case 'diamond':
        const points = `${center},${center - half} ${center + half},${center} ${center},${center + half} ${center - half},${center}`;
        return `<polygon points="${points}"
          fill="${color}" stroke="#FFFFFF" stroke-width="2" />`;

      case 'circle':
        return `<circle cx="${center}" cy="${center}" r="${half}"
          fill="${color}" stroke="#FFFFFF" stroke-width="2" />`;

      case 'clover':
        // Four-leaf clover shape for unknown
        return `<g fill="${color}" stroke="#FFFFFF" stroke-width="2">
          <circle cx="${center}" cy="${center - half / 2}" r="${half / 2}" />
          <circle cx="${center + half / 2}" cy="${center}" r="${half / 2}" />
          <circle cx="${center}" cy="${center + half / 2}" r="${half / 2}" />
          <circle cx="${center - half / 2}" cy="${center}" r="${half / 2}" />
        </g>`;

      default:
        return '';
    }
  }

  /**
   * Render accuracy circle as GeoJSON
   */
  private renderAccuracyCircle(
    marker: MapMarker,
    color: string
  ): GeoJSONCircle {
    const radius = Math.max(marker.ce, this.config.accuracyCircleMinRadius);
    const coordinates = this.createCircleCoordinates(
      marker.lat,
      marker.lon,
      radius,
      32 // Number of points
    );

    return {
      type: 'Feature',
      geometry: {
        type: 'Polygon',
        coordinates: [coordinates],
      },
      properties: {
        radius,
        color,
        opacity: this.config.accuracyCircleOpacity,
      },
    };
  }

  /**
   * Render heading arrow as GeoJSON
   */
  private renderHeadingArrow(marker: MapMarker, color: string): GeoJSONArrow {
    const course = marker.course!;
    const length = this.config.headingArrowLength;

    // Calculate end point of arrow
    const endPoint = this.calculateDestination(
      marker.lat,
      marker.lon,
      course,
      length
    );

    return {
      type: 'Feature',
      geometry: {
        type: 'LineString',
        coordinates: [
          [marker.lon, marker.lat],
          [endPoint.lon, endPoint.lat],
        ],
      },
      properties: {
        heading: course,
        color,
        width: this.config.headingArrowWidth,
      },
    };
  }

  /**
   * Render text label
   */
  private renderLabel(marker: MapMarker, color: string): SymbolLabel {
    return {
      text: marker.callsign || marker.uid,
      color: '#FFFFFF',
      size: 12,
      offsetX: 0,
      offsetY: 20, // Below symbol
      font: 'Arial, sans-serif',
    };
  }

  /**
   * Create circle coordinates for polygon
   */
  private createCircleCoordinates(
    lat: number,
    lon: number,
    radius: number,
    points: number
  ): number[][] {
    const coordinates: number[][] = [];
    const angleStep = (2 * Math.PI) / points;

    for (let i = 0; i <= points; i++) {
      const angle = i * angleStep;
      const point = this.calculateDestination(lat, lon, (angle * 180) / Math.PI, radius);
      coordinates.push([point.lon, point.lat]);
    }

    return coordinates;
  }

  /**
   * Calculate destination point given distance and bearing
   */
  private calculateDestination(
    lat: number,
    lon: number,
    bearing: number,
    distance: number
  ): { lat: number; lon: number } {
    const R = 6371e3; // Earth radius in meters
    const φ1 = (lat * Math.PI) / 180;
    const λ1 = (lon * Math.PI) / 180;
    const θ = (bearing * Math.PI) / 180;

    const φ2 = Math.asin(
      Math.sin(φ1) * Math.cos(distance / R) +
        Math.cos(φ1) * Math.sin(distance / R) * Math.cos(θ)
    );

    const λ2 =
      λ1 +
      Math.atan2(
        Math.sin(θ) * Math.sin(distance / R) * Math.cos(φ1),
        Math.cos(distance / R) - Math.sin(φ1) * Math.sin(φ2)
      );

    return {
      lat: (φ2 * 180) / Math.PI,
      lon: (λ2 * 180) / Math.PI,
    };
  }

  /**
   * Convert CoT type to SIDC (basic implementation)
   *
   * Full SIDC format: XX-XXXXXX-XX-XXX
   * Example: SG-UCFR---****X (friendly ground unit)
   */
  public cotTypeToSIDC(cotType: string): string {
    const parts = cotType.split('-');
    if (parts.length < 3) {
      return 'SUGP----------'; // Unknown ground point
    }

    const dimension = parts[0]; // a, g, s
    const affiliation = parts[1]; // f, h, n, u
    const category = parts[2] || 'U'; // U = unit/equipment

    // Build basic SIDC
    let sidc = 'S'; // Standard identity

    // Dimension
    switch (dimension.toLowerCase()) {
      case 'a':
        sidc += 'A'; // Air
        break;
      case 'g':
        sidc += 'G'; // Ground
        break;
      case 's':
        sidc += 'S'; // Sea surface
        break;
      default:
        sidc += 'G'; // Default to ground
    }

    // Affiliation
    switch (affiliation.toLowerCase()) {
      case 'f':
        sidc += 'F'; // Friend
        break;
      case 'h':
        sidc += 'H'; // Hostile
        break;
      case 'n':
        sidc += 'N'; // Neutral
        break;
      case 'u':
        sidc += 'U'; // Unknown
        break;
      default:
        sidc += 'U'; // Unknown
    }

    // Battle dimension (simplified)
    sidc += 'P'; // Point

    // Function ID (simplified - would need full CoT to SIDC mapping)
    sidc += '----------';

    return sidc;
  }

  /**
   * Update configuration
   */
  public updateConfig(config: Partial<SymbolRendererConfig>): void {
    this.config = { ...this.config, ...config };
  }

  /**
   * Get current configuration
   */
  public getConfig(): Required<SymbolRendererConfig> {
    return { ...this.config };
  }
}

/**
 * Create a singleton instance for global use
 */
export const symbolRenderer = new SymbolRenderer();
