import { Component } from 'valdi_core/src/Component';
import { Label, View } from 'valdi_tsx/src/NativeTemplateElements';
import { Style } from 'valdi_core/src/Style';
import { systemFont } from 'valdi_core/src/SystemFont';

/**
 * @ViewModel
 * @ExportModel({
 *   ios: 'OmniTAKAppViewModel',
 *   android: 'com.engindearing.omnitak.OmniTAKAppViewModel'
 * })
 */
export interface OmniTAKAppViewModel {
  appName: string;
  version: string;
  connectionStatus: string;
}

/**
 * @Context
 * @ExportModel({
 *   ios: 'OmniTAKAppContext',
 *   android: 'com.engindearing.omnitak.OmniTAKAppContext'
 * })
 */
export interface OmniTAKAppContext {
  isDebugMode?: boolean;
}

export enum ConnectionStatus {
  Disconnected = 'DISCONNECTED',
  Connecting = 'CONNECTING',
  Connected = 'CONNECTED',
  Error = 'ERROR',
}

/**
 * @Component
 * @ExportModel({
 *   ios: 'OmniTAKApp',
 *   android: 'com.engindearing.omnitak.OmniTAKApp'
 * })
 */
export class OmniTAKApp extends Component<
  OmniTAKAppViewModel,
  OmniTAKAppContext
> {
  onCreate(): void {
    console.log('OmniTAK Mobile onCreate!');
    // viewModel will be provided by Valdi framework
  }

  onRender(): void {
    const { appName, version, connectionStatus } = this.viewModel;

    <view style={styles.container}>
      {/* Header */}
      <view style={styles.header}>
        <label
          style={styles.title}
          value={appName}
          font={systemFont(24)}
        />
        <label
          style={styles.version}
          value={`v${version}`}
          font={systemFont(12)}
        />
      </view>

      {/* Connection Status Indicator */}
      <view style={styles.statusContainer}>
        <view
          style={this.getStatusIndicatorStyle(connectionStatus)}
          width={12}
          height={12}
          borderRadius={6}
          marginRight={8}
        />
        <label
          value={this.getStatusText(connectionStatus)}
          font={systemFont(14)}
          color={this.getStatusColor(connectionStatus)}
        />
      </view>

      {/* Main Content Area - Placeholder for MapScreen */}
      <view style={styles.content}>
        <label
          style={styles.placeholder}
          value='Map View Coming Soon...'
          font={systemFont(16)}
        />
        <label
          style={styles.description}
          value='Cross-platform TAK client with full CoT support'
          font={systemFont(12)}
        />
      </view>

      {/* Footer Info */}
      <view style={styles.footer}>
        <label
          value='Powered by Valdi + omni-TAK'
          font={systemFont(10)}
          color='#666666'
        />
      </view>
    </view>;
  }

  private getStatusText(status: string): string {
    switch (status) {
      case 'CONNECTED':
        return 'Connected to TAK Server';
      case 'CONNECTING':
        return 'Connecting...';
      case 'ERROR':
        return 'Connection Error';
      default:
        return 'Not Connected';
    }
  }

  private getStatusColor(status: string): string {
    switch (status) {
      case 'CONNECTED':
        return '#00AA00';
      case 'CONNECTING':
        return '#FFA500';
      case 'ERROR':
        return '#FF0000';
      default:
        return '#666666';
    }
  }

  private getStatusIndicatorStyle(status: string): Style<View> {
    const backgroundColor = this.getStatusColor(status);
    return new Style<View>({ backgroundColor });
  }
}

const styles = {
  container: new Style<View>({
    height: '100%',
    width: '100%',
    backgroundColor: '#F5F5F5',
    flexDirection: 'column',
  }),

  header: new Style<View>({
    backgroundColor: '#1E1E1E',
    padding: 20,
    paddingTop: 60, // Account for status bar
    alignItems: 'center',
  }),

  title: new Style<Label>({
    color: '#FFFC00', // Snap yellow
    accessibilityCategory: 'header',
  }),

  version: new Style<Label>({
    color: '#CCCCCC',
    marginTop: 4,
  }),

  statusContainer: new Style<View>({
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    padding: 12,
    backgroundColor: '#FFFFFF',
  }),

  content: new Style<View>({
    alignItems: 'center',
    justifyContent: 'center',
    padding: 20,
  }),

  placeholder: new Style<Label>({
    color: '#333333',
    textAlign: 'center',
    marginBottom: 12,
  }),

  description: new Style<Label>({
    color: '#666666',
    textAlign: 'center',
  }),

  footer: new Style<View>({
    padding: 16,
    alignItems: 'center',
    backgroundColor: '#FFFFFF',
  }),
};
