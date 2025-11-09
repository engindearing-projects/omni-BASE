import { Component } from 'valdi_core/src/Component';
import { Label, View } from 'valdi_tsx/src/NativeTemplateElements';
import { Style } from 'valdi_core/src/Style';
import { systemFont } from 'valdi_core/src/SystemFont';
import { takService } from '../services/TakService';
import { parseCotXml, getAffiliation, getAffiliationColor } from '../services/CotParser';
import { MarkerManager } from '../services/MarkerManager';
import { SymbolRenderer } from '../services/SymbolRenderer';
import { MarkerEvent } from '../models/MarkerModel';

/**
 * @ViewModel
 * @ExportModel({
 *   ios: 'MapScreenPlaceholderViewModel',
 *   android: 'com.engindearing.omnitak.MapScreenPlaceholderViewModel'
 * })
 */
export interface MapScreenViewModel {
  markerCount: number;
  activeMarkers: number;
  staleMarkers: number;
  lastUpdate: string;
  isConnected: boolean;
}

/**
 * @Context
 */
export interface MapScreenContext {
  initialCenter?: { lat: number; lon: number };
  initialZoom?: number;
}

/**
 * @Component
 * @ExportModel({
 *   ios: 'MapScreenPlaceholder',
 *   android: 'com.engindearing.omnitak.MapScreenPlaceholder'
 * })
 *
 * Placeholder map screen (superseded by MapScreenWithMapLibre).
 */
export class MapScreen extends Component<MapScreenViewModel, MapScreenContext> {
  private cotUnsubscribe?: () => void;
  private markerManager!: MarkerManager;
  private symbolRenderer!: SymbolRenderer;
  private markerEventUnsubscribers: (() => void)[] = [];

  onCreate(): void {
    console.log('MapScreen onCreate');

    // Initialize services
    this.markerManager = new MarkerManager({
      staleCheckInterval: 5000,
      autoRemoveStaleAfter: 60000,
      maxMarkers: 10000,
    });
    this.symbolRenderer = new SymbolRenderer();

    // Subscribe to marker events
    this.subscribeToMarkerEvents();

    // Subscribe to CoT messages (when connection exists)
    this.subscribeToCot();
  }

  onDestroy(): void {
    console.log('MapScreen onDestroy');

    // Unsubscribe from CoT
    if (this.cotUnsubscribe) {
      this.cotUnsubscribe();
    }

    // Unsubscribe from marker events
    this.markerEventUnsubscribers.forEach((unsubscribe) => unsubscribe());
    this.markerEventUnsubscribers = [];

    // Cleanup marker manager
    this.markerManager.destroy();
  }

  onRender(): void {
    const { markerCount, activeMarkers, staleMarkers, lastUpdate, isConnected } = this.viewModel;

    <view style={styles.container}>
      {/* Map placeholder - will be replaced with MapLibre custom-view */}
      <view style={styles.mapPlaceholder}>
        <label
          value='🗺️'
          font={systemFont(48)}
        />
        <label
          value='Map rendering coming soon'
          font={systemFont(14)}
          color='#666666'
          marginTop={12}
        />
      </view>

      {/* Map overlay toolbar */}
      <view style={styles.toolbar}>
        <view style={styles.toolbarItem}>
          <label
            value={`Markers: ${markerCount}`}
            font={systemFont(12)}
            color='#FFFFFF'
          />
        </view>
        <view style={styles.toolbarItem}>
          <label
            value={`Active: ${activeMarkers}`}
            font={systemFont(12)}
            color='#00FF00'
          />
        </view>
        <view style={styles.toolbarItem}>
          <label
            value={`Stale: ${staleMarkers}`}
            font={systemFont(12)}
            color='#FFA500'
          />
        </view>
        <view style={styles.toolbarItem}>
          <label
            value={`Last: ${lastUpdate}`}
            font={systemFont(12)}
            color='#FFFFFF'
          />
        </view>
        <view style={styles.toolbarItem}>
          <view
            width={8}
            height={8}
            borderRadius={4}
            backgroundColor={isConnected ? '#00FF00' : '#FF0000'}
            marginRight={4}
          />
          <label
            value={isConnected ? 'Online' : 'Offline'}
            font={systemFont(12)}
            color='#FFFFFF'
          />
        </view>
      </view>

      {/* Action buttons */}
      <view style={styles.actionButtons}>
        <view style={styles.actionButton}>
          <label value='📍' font={systemFont(24)} />
        </view>
        <view style={styles.actionButton}>
          <label value='➕' font={systemFont(24)} />
        </view>
        <view style={styles.actionButton}>
          <label value='🔍' font={systemFont(24)} />
        </view>
      </view>
    </view>;
  }

  private subscribeToCot(): void {
    // Get all connections and subscribe to first one for now
    const connections = takService.getConnections();
    if (connections.length > 0) {
      const connectionId = connections[0];
      this.cotUnsubscribe = takService.onCotReceived(
        connectionId,
        this.handleCotMessage.bind(this)
      );
      this.updateViewModel({ isConnected: true });
    }
  }

  private subscribeToMarkerEvents(): void {
    // Update UI when markers change
    const events = [
      MarkerEvent.Created,
      MarkerEvent.Updated,
      MarkerEvent.Removed,
    ];

    events.forEach((event) => {
      const unsubscribe = this.markerManager.on(event, () => {
        this.updateMarkerStats();
      });
      this.markerEventUnsubscribers.push(unsubscribe);
    });
  }

  private updateMarkerStats(): void {
    const stats = this.markerManager.getStats();
    this.updateViewModel({
      markerCount: stats.total,
      activeMarkers: stats.active,
      staleMarkers: stats.stale,
    });
  }

  private handleCotMessage(xml: string): void {
    const event = parseCotXml(xml);
    if (event) {
      console.log(`Received CoT: ${event.uid} (${event.type})`);

      // Process CoT through marker manager
      const marker = this.markerManager.processCoT(event);

      // Update last update time
      this.updateViewModel({
        lastUpdate: new Date().toLocaleTimeString(),
      });

      // Log marker details
      console.log(
        `  Position: ${marker.lat}, ${marker.lon}`
      );
      console.log(`  Affiliation: ${marker.affiliation} (${marker.color})`);
      if (marker.callsign) {
        console.log(`  Callsign: ${marker.callsign}`);
      }
      if (marker.course !== undefined && marker.speed !== undefined) {
        console.log(`  Course: ${marker.course}°, Speed: ${marker.speed} m/s`);
      }

      // Render symbol (for debugging)
      const rendered = this.symbolRenderer.renderSymbol(marker);
      console.log(`  Rendered symbol: ${rendered.width}x${rendered.height}px`);
    }
  }

  private updateViewModel(updates: Partial<MapScreenViewModel>): void {
    // In Valdi, viewModel is readonly and updated by parent component
    // For now, just log the updates - proper implementation requires StatefulComponent
    console.log('ViewModel update requested:', updates);
    this.scheduleRender();
  }
}

const styles = {
  container: new Style<View>({
    width: '100%',
    height: '100%',
    backgroundColor: '#EEEEEE',
  }),

  mapPlaceholder: new Style<View>({
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#D0D0D0',
  }),

  toolbar: new Style<View>({
    position: 'absolute',
    top: 60,
    left: 12,
    right: 12,
    flexDirection: 'row',
    backgroundColor: 'rgba(0, 0, 0, 0.7)',
    borderRadius: 8,
    padding: 12,
    justifyContent: 'space-between',
  }),

  toolbarItem: new Style<View>({
    flexDirection: 'row',
    alignItems: 'center',
  }),

  actionButtons: new Style<View>({
    position: 'absolute',
    bottom: 24,
    right: 12,
    flexDirection: 'column',
  }),

  actionButton: new Style<View>({
    width: 56,
    height: 56,
    borderRadius: 28,
    backgroundColor: '#FFFFFF',
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 12,
  }),
};
