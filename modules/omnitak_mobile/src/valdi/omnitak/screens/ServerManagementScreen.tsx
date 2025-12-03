import { Component } from 'valdi_core/src/Component';
import { Label, View, ScrollView } from 'valdi_tsx/src/NativeTemplateElements';
import { Style } from 'valdi_core/src/Style';
import { systemFont, systemBoldFont } from 'valdi_core/src/SystemFont';

/**
 * @ExportModel({
 *   ios: 'ServerConnection',
 *   android: 'com.engindearing.omnitak.ServerConnection'
 * })
 */
export interface ServerConnection {
  id: string;
  name: string;
  host: string;
  port: number;
  protocol: string;
  status: string;
  lastConnected?: string;
}

/**
 * @ViewModel
 * @ExportModel({
 *   ios: 'ServerManagementViewModel',
 *   android: 'com.engindearing.omnitak.ServerManagementViewModel'
 * })
 */
export interface ServerManagementViewModel {
  servers: ServerConnection[];
  showAddDialog: boolean;
  editingServer?: ServerConnection;
}

/**
 * @Context
 * @ExportModel({
 *   ios: 'ServerManagementContext',
 *   android: 'com.engindearing.omnitak.ServerManagementContext'
 * })
 */
export interface ServerManagementContext {
  onBack?: () => void;
  onConnect?: (serverId: string) => void;
  onDisconnect?: (serverId: string) => void;
  onAddServer?: (server: any) => void;
  onEditServer?: (serverId: string) => void;
  onDeleteServer?: (serverId: string) => void;
  onShowAddDialog?: () => void;
  onHideAddDialog?: () => void;
}

/**
 * @Component
 * @ExportModel({
 *   ios: 'ServerManagementScreen',
 *   android: 'com.engindearing.omnitak.ServerManagementScreen'
 * })
 *
 * ATAK-style server/network connection management screen.
 * Allows users to view, add, edit, and connect to TAK servers.
 */
export class ServerManagementScreen extends Component<
  ServerManagementViewModel,
  ServerManagementContext
> {
  onCreate(): void {
    console.log('ServerManagementScreen onCreate');
  }

  onRender(): void {
    const { servers, showAddDialog } = this.viewModel;

    <view style={styles.container}>
      {/* Header */}
      <view style={styles.header}>
        <view style={styles.backButton} onTap={this.handleBack.bind(this)}>
          <label value="←" font={systemFont(24)} color="#FFFFFF" />
        </view>
        <label
          value="Network Connections"
          font={systemBoldFont(20)}
          color="#FFFFFF"
        />
        <view
          style={styles.addButton}
          onTap={this.handleShowAddDialog.bind(this)}
        >
          <label value="+" font={systemFont(28)} color="#FFFC00" />
        </view>
      </view>

      {/* Server list */}
      <view style={styles.scrollView}>
        <view style={styles.content}>
          {servers.length === 0 ? (
            <view style={styles.emptyState}>
              <label
                value="No servers configured"
                font={systemFont(16)}
                color="#999999"
                marginBottom={8}
              />
              <label
                value="Tap + to add a TAK server"
                font={systemFont(14)}
                color="#666666"
              />
            </view>
          ) : (
            servers.map((server) => this.renderServerItem(server))
          )}
        </view>
      </view>

      {/* Add/Edit server dialog */}
      {showAddDialog && this.renderAddServerDialog()}
    </view>;
  }

  private renderServerItem(server: ServerConnection): void {
    const statusColor = this.getStatusColor(server.status);
    const statusText = this.getStatusText(server.status);

    <view style={styles.serverItem}>
      {/* Server info */}
      <view style={styles.serverInfo}>
        <view style={styles.serverHeader}>
          <label
            value={server.name}
            font={systemBoldFont(16)}
            color="#FFFFFF"
          />
          <view style={styles.statusBadge}>
            <view
              width={8}
              height={8}
              borderRadius={4}
              backgroundColor={statusColor}
              marginRight={6}
            />
            <label
              value={statusText}
              font={systemFont(11)}
              color={statusColor}
            />
          </view>
        </view>

        <label
          value={`${server.host}:${server.port}`}
          font={systemFont(14)}
          color="#CCCCCC"
          marginTop={4}
        />

        <label
          value={`Protocol: ${server.protocol.toUpperCase()}`}
          font={systemFont(12)}
          color="#999999"
          marginTop={2}
        />

        {server.lastConnected && (
          <label
            value={`Last connected: ${server.lastConnected}`}
            font={systemFont(11)}
            color="#666666"
            marginTop={2}
          />
        )}
      </view>

      {/* Action buttons */}
      <view style={styles.serverActions}>
        {server.status === 'connected' ? (
          <view
            style={styles.actionButton}
            onTap={() => this.handleDisconnect(server.id)}
          >
            <label
              value="Disconnect"
              font={systemBoldFont(12)}
              color="#FF5252"
            />
          </view>
        ) : (
          <view
            style={styles.actionButton}
            onTap={() => this.handleConnect(server.id)}
          >
            <label
              value="Connect"
              font={systemBoldFont(12)}
              color="#4ADE80"
            />
          </view>
        )}

        <view
          style={styles.iconButton}
          onTap={() => this.handleEdit(server.id)}
        >
          <label value="✏️" font={systemFont(16)} />
        </view>

        <view
          style={styles.iconButton}
          onTap={() => this.handleDelete(server.id)}
        >
          <label value="🗑️" font={systemFont(16)} />
        </view>
      </view>
    </view>;
  }

  private renderAddServerDialog(): void {
    <view style={styles.dialogOverlay}>
      <view style={styles.dialog}>
        <view style={styles.dialogHeader}>
          <label
            value="Add TAK Server"
            font={systemBoldFont(18)}
            color="#FFFFFF"
          />
          <view
            style={styles.closeButton}
            onTap={this.handleHideAddDialog.bind(this)}
          >
            <label value="✕" font={systemFont(20)} color="#FFFFFF" />
          </view>
        </view>

        <view style={styles.dialogContent}>
          <label
            value="Server Name"
            font={systemFont(12)}
            color="#CCCCCC"
            marginBottom={4}
          />
          {/* TODO: Replace with proper Valdi input component */}
          <view style={styles.input}>
            <label value="TAK Server 1" font={systemFont(14)} color="#FFFFFF" />
          </view>

          <label
            value="Host / IP Address"
            font={systemFont(12)}
            color="#CCCCCC"
            marginTop={16}
            marginBottom={4}
          />
          <view style={styles.input}>
            <label value="192.168.1.100" font={systemFont(14)} color="#FFFFFF" />
          </view>

          <label
            value="Port"
            font={systemFont(12)}
            color="#CCCCCC"
            marginTop={16}
            marginBottom={4}
          />
          <view style={styles.input}>
            <label value="8087" font={systemFont(14)} color="#FFFFFF" />
          </view>

          <label
            value="Protocol"
            font={systemFont(12)}
            color="#CCCCCC"
            marginTop={16}
            marginBottom={8}
          />
          <view style={styles.protocolOptions}>
            <view style={styles.protocolOption}>
              <label value="TCP" font={systemFont(14)} color="#FFFFFF" />
            </view>
            <view style={styles.protocolOption}>
              <label value="SSL" font={systemFont(14)} color="#FFFFFF" />
            </view>
            <view style={styles.protocolOption}>
              <label value="UDP" font={systemFont(14)} color="#FFFFFF" />
            </view>
          </view>
        </view>

        <view style={styles.dialogActions}>
          <view
            style={styles.dialogButton}
            onTap={this.handleHideAddDialog.bind(this)}
          >
            <label
              value="Cancel"
              font={systemFont(14)}
              color="#999999"
            />
          </view>
          <view
            style={styles.dialogButtonPrimary}
            onTap={this.handleAddServer.bind(this)}
          >
            <label
              value="Add Server"
              font={systemBoldFont(14)}
              color="#1E1E1E"
            />
          </view>
        </view>
      </view>
    </view>;
  }

  private getStatusColor(status: string): string {
    switch (status) {
      case 'connected':
        return '#4ADE80';
      case 'connecting':
        return '#FFA500';
      case 'error':
        return '#FF5252';
      default:
        return '#666666';
    }
  }

  private getStatusText(status: string): string {
    switch (status) {
      case 'connected':
        return 'Connected';
      case 'connecting':
        return 'Connecting...';
      case 'error':
        return 'Error';
      default:
        return 'Disconnected';
    }
  }

  private handleBack(): void {
    if (this.context.onBack) {
      this.context.onBack();
    }
  }

  private handleConnect(serverId: string): void {
    if (this.context.onConnect) {
      this.context.onConnect(serverId);
    }
  }

  private handleDisconnect(serverId: string): void {
    if (this.context.onDisconnect) {
      this.context.onDisconnect(serverId);
    }
  }

  private handleEdit(serverId: string): void {
    if (this.context.onEditServer) {
      this.context.onEditServer(serverId);
    }
  }

  private handleDelete(serverId: string): void {
    if (this.context.onDeleteServer) {
      this.context.onDeleteServer(serverId);
    }
  }

  private handleShowAddDialog(): void {
    if (this.context.onShowAddDialog) {
      this.context.onShowAddDialog();
    }
  }

  private handleHideAddDialog(): void {
    if (this.context.onHideAddDialog) {
      this.context.onHideAddDialog();
    }
  }

  private handleAddServer(): void {
    // TODO: Collect form data and call onAddServer
    if (this.context.onAddServer) {
      this.context.onAddServer({
        name: 'New Server',
        host: '192.168.1.100',
        port: 8087,
        protocol: 'tcp',
        status: 'disconnected',
      });
    }
  }
}

const styles = {
  container: new Style<View>({
    width: '100%',
    height: '100%',
    backgroundColor: '#1E1E1E',
    flexDirection: 'column',
  }),

  header: new Style<View>({
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: 16,
    paddingTop: 60,
    backgroundColor: '#2A2A2A',
  }),

  backButton: new Style<View>({
    width: 40,
    height: 40,
    alignItems: 'center',
    justifyContent: 'center',
  }),

  addButton: new Style<View>({
    width: 40,
    height: 40,
    alignItems: 'center',
    justifyContent: 'center',
  }),

  scrollView: new Style<View>({
    // flex: 1, // Not supported by Valdi
  }),

  content: new Style<View>({
    padding: 16,
  }),

  emptyState: new Style<View>({
    padding: 40,
    alignItems: 'center',
    justifyContent: 'center',
  }),

  serverItem: new Style<View>({
    backgroundColor: '#2A2A2A',
    borderRadius: 8,
    padding: 16,
    marginBottom: 12,
  }),

  serverInfo: new Style<View>({
    marginBottom: 12,
  }),

  serverHeader: new Style<View>({
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  }),

  statusBadge: new Style<View>({
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#1E1E1E',
    paddingLeft: 8,
    paddingRight: 8,
    paddingTop: 4,
    paddingBottom: 4,
    borderRadius: 4,
  }),

  serverActions: new Style<View>({
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'flex-end',
    // gap removed - not supported by Valdi
  }),

  actionButton: new Style<View>({
    paddingLeft: 16,
    paddingRight: 16,
    paddingTop: 8,
    paddingBottom: 8,
    backgroundColor: '#3A3A3A',
    borderRadius: 4,
  }),

  iconButton: new Style<View>({
    width: 36,
    height: 36,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#3A3A3A',
    borderRadius: 4,
  }),

  dialogOverlay: new Style<View>({
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    backgroundColor: 'rgba(0, 0, 0, 0.7)',
    alignItems: 'center',
    justifyContent: 'center',
    zIndex: 2000,
  }),

  dialog: new Style<View>({
    width: '90%',
    maxWidth: 500,
    backgroundColor: '#2A2A2A',
    borderRadius: 12,
  }),

  dialogHeader: new Style<View>({
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: 20,
  }),

  closeButton: new Style<View>({
    width: 32,
    height: 32,
    alignItems: 'center',
    justifyContent: 'center',
  }),

  dialogContent: new Style<View>({
    padding: 20,
  }),

  input: new Style<View>({
    backgroundColor: '#1E1E1E',
    padding: 12,
    borderRadius: 4,
    borderWidth: 1,
    borderColor: '#3A3A3A',
  }),

  protocolOptions: new Style<View>({
    flexDirection: 'row',
    // gap removed - not supported by Valdi
  }),

  protocolOption: new Style<View>({
    // flex: 1, // Not supported by Valdi
    padding: 12,
    backgroundColor: '#1E1E1E',
    borderRadius: 4,
    borderWidth: 1,
    borderColor: '#3A3A3A',
    alignItems: 'center',
  }),

  dialogActions: new Style<View>({
    flexDirection: 'row',
    justifyContent: 'flex-end',
    // gap removed - not supported by Valdi
    padding: 20,
  }),

  dialogButton: new Style<View>({
    paddingLeft: 20,
    paddingRight: 20,
    paddingTop: 10,
    paddingBottom: 10,
    borderRadius: 4,
  }),

  dialogButtonPrimary: new Style<View>({
    paddingLeft: 20,
    paddingRight: 20,
    paddingTop: 10,
    paddingBottom: 10,
    backgroundColor: '#FFFC00',
    borderRadius: 4,
  }),
};
