//
//  SCMapLibreMapView.h
//  OmniTAK Mobile - MapLibre GL Native Integration
//
//  iOS native wrapper for MapLibre GL Native map view.
//  Provides custom-view integration with Valdi framework.
//

#import "valdi_core/SCValdiView.h"
#import <UIKit/UIKit.h>

@import MapLibre;

NS_ASSUME_NONNULL_BEGIN

/**
 * SCMapLibreMapView provides a Valdi custom-view wrapper around MLNMapView.
 *
 * This view integrates MapLibre GL Native with the Valdi framework, enabling
 * TypeScript-driven map rendering for OmniTAK Mobile. It supports dynamic
 * camera positioning, marker management, and interactive callbacks.
 *
 * Features:
 * - Camera control (center, zoom, bearing, pitch)
 * - Marker/annotation management with custom icons
 * - Touch event callbacks (tap, long press)
 * - MapLibre delegate event forwarding to TypeScript
 * - View pooling support for performance
 *
 * Valdi Attributes:
 * - options: JSON object with map configuration
 * - markers: JSON array of marker definitions
 * - camera: JSON object with camera position
 * - onMapReady: Callback fired when map is ready
 * - onMarkerTap: Callback fired when marker is tapped
 * - onMapTap: Callback fired when map is tapped
 * - onCameraChanged: Callback fired when camera moves
 */
@interface SCMapLibreMapView : SCValdiView <MLNMapViewDelegate>

/**
 * The underlying MapLibre map view instance.
 * Created lazily on first access.
 */
@property (nonatomic, strong, readonly) MLNMapView *mapView;

/**
 * Style URL for the map (e.g., Mapbox Streets, OpenStreetMap).
 * Default: OpenStreetMap Positron style
 */
@property (nonatomic, copy, nullable) NSString *styleURL;

/**
 * Enable user interaction (pan, zoom, rotate).
 * Default: YES
 */
@property (nonatomic, assign) BOOL userInteractionEnabled;

/**
 * Show user location on the map.
 * Default: NO
 */
@property (nonatomic, assign) BOOL showUserLocation;

@end

NS_ASSUME_NONNULL_END
