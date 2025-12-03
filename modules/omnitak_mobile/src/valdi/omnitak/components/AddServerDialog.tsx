import { Component } from 'valdi_core/src/Component';
import { Label, View } from 'valdi_tsx/src/NativeTemplateElements';
import { Style } from 'valdi_core/src/Style';
import { systemFont, systemBoldFont } from 'valdi_core/src/SystemFont';

/**
 * @ViewModel
 * @ExportModel({
 *   ios: 'AddServerViewModel',
 *   android: 'com.engindearing.omnitak.AddServerViewModel'
 * })
 */
export interface AddServerViewModel {
  serverName: string;
  host: string;
  port: number;
  protocol: 'tcp' | 'ssl' | 'udp';

  // Certificate options (only for SSL)
  certificateOption: 'none' | 'enroll' | 'import';
  selectedCertificateId?: string;

  // Show sub-dialogs
  showEnrollmentDialog: boolean;
  showImportDialog: boolean;
}

/**
 * @Context
 * @ExportModel({
 *   ios: 'AddServerContext',
 *   android: 'com.engindearing.omnitak.AddServerContext'
 * })
 */
export interface AddServerContext {
  onCancel?: () => void;
  onAddServer?: (server: any) => void;
  onFieldChange?: (field: string, value: any) => void;
  onShowEnrollment?: () => void;
  onShowImport?: () => void;
  onSelectCertificate?: () => void;
}

/**
 * @Component
 * @ExportModel({
 *   ios: 'AddServerDialog',
 *   android: 'com.engindearing.omnitak.AddServerDialog'
 * })
 *
 * Enhanced Add Server dialog with certificate enrollment/import options.
 */
export class AddServerDialog extends Component<
  AddServerViewModel,
  AddServerContext
> {
  onCreate(): void {
    console.log('AddServerDialog onCreate');
  }

  onRender(): void {
    const {
      serverName,
      host,
      port,
      protocol,
      certificateOption,
      selectedCertificateId,
    } = this.viewModel;

    <view style={styles.overlay}>
      <view style={styles.dialog}>
        {/* Header */}
        <view style={styles.header}>
          <label
            value="Add TAK Server"
            font={systemBoldFont(18)}
            color="#FFFFFF"
          />
          <view
            style={styles.closeButton}
            onTap={this.handleCancel.bind(this)}
          >
            <label value="✕" font={systemFont(20)} color="#FFFFFF" />
          </view>
        </view>

        {/* Content */}
        <view style={styles.content}>
          {/* Server Name */}
          <label
            value="Server Name"
            font={systemFont(12)}
            color="#CCCCCC"
            marginBottom={4}
          />
          <view style={styles.input}>
            <label
              value={serverName || 'TAK Server 1'}
              font={systemFont(14)}
              color={serverName ? '#FFFFFF' : '#666666'}
            />
          </view>

          {/* Host */}
          <label
            value="Host / IP Address"
            font={systemFont(12)}
            color="#CCCCCC"
            marginTop={16}
            marginBottom={4}
          />
          <view style={styles.input}>
            <label
              value={host || 'tak.example.com'}
              font={systemFont(14)}
              color={host ? '#FFFFFF' : '#666666'}
            />
          </view>

          {/* Port */}
          <label
            value="Port"
            font={systemFont(12)}
            color="#CCCCCC"
            marginTop={16}
            marginBottom={4}
          />
          <view style={styles.input}>
            <label
              value={port ? port.toString() : '8087'}
              font={systemFont(14)}
              color={port ? '#FFFFFF' : '#666666'}
            />
          </view>

          {/* Protocol */}
          <label
            value="Protocol"
            font={systemFont(12)}
            color="#CCCCCC"
            marginTop={16}
            marginBottom={8}
          />
          <view style={styles.protocolOptions}>
            {this.renderProtocolOption('tcp', 'TCP', protocol === 'tcp')}
            {this.renderProtocolOption('ssl', 'SSL/TLS', protocol === 'ssl')}
            {this.renderProtocolOption('udp', 'UDP', protocol === 'udp')}
          </view>

          {/* Certificate Setup (only for SSL) */}
          {protocol === 'ssl' && this.renderCertificateSetup(certificateOption, selectedCertificateId)}
        </view>

        {/* Actions */}
        <view style={styles.actions}>
          <view
            style={styles.cancelButton}
            onTap={this.handleCancel.bind(this)}
          >
            <label
              value="Cancel"
              font={systemFont(14)}
              color="#999999"
            />
          </view>
          <view
            style={styles.addButton}
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

  private renderProtocolOption(value: string, label: string, selected: boolean): void {
    <view
      style={selected ? styles.protocolOptionSelected : styles.protocolOption}
      onTap={() => this.handleFieldChange('protocol', value)}
    >
      <label
        value={label}
        font={systemFont(14)}
        color={selected ? '#1E1E1E' : '#FFFFFF'}
      />
    </view>;
  }

  private renderCertificateSetup(option: string, selectedCertId?: string): void {
    <view style={styles.certSection}>
      {/* Section Header */}
      <view style={styles.certHeader}>
        <label
          value="🔒 Certificate Setup"
          font={systemBoldFont(14)}
          color="#FFFC00"
        />
      </view>

      {/* Certificate Options */}
      <view style={styles.certOptions}>
        {/* Option 1: No certificate (testing only) */}
        <view
          style={option === 'none' ? styles.certOptionSelected : styles.certOption}
          onTap={() => this.handleFieldChange('certificateOption', 'none')}
        >
          <view style={styles.radioButton}>
            {option === 'none' && <view style={styles.radioSelected} />}
          </view>
          <view style={styles.certOptionContent}>
            <label
              value="No certificate"
              font={systemBoldFont(13)}
              color={option === 'none' ? '#FFFFFF' : '#CCCCCC'}
            />
            <label
              value="(Testing only - not secure)"
              font={systemFont(11)}
              color="#FF5252"
              marginTop={2}
            />
          </view>
        </view>

        {/* Option 2: Get certificate from server */}
        <view
          style={option === 'enroll' ? styles.certOptionSelected : styles.certOption}
          onTap={() => this.handleFieldChange('certificateOption', 'enroll')}
        >
          <view style={styles.radioButton}>
            {option === 'enroll' && <view style={styles.radioSelected} />}
          </view>
          <view style={styles.certOptionContent}>
            <label
              value="Get certificate from server"
              font={systemBoldFont(13)}
              color={option === 'enroll' ? '#FFFFFF' : '#CCCCCC'}
            />
            <label
              value="Use username/password to enroll"
              font={systemFont(11)}
              color="#4ADE80"
              marginTop={2}
            />
          </view>
          {option === 'enroll' && (
            <view
              style={styles.configureButton}
              onTap={this.handleShowEnrollment.bind(this)}
            >
              <label
                value="Configure →"
                font={systemFont(12)}
                color="#FFFC00"
              />
            </view>
          )}
        </view>

        {/* Option 3: Import existing certificate */}
        <view
          style={option === 'import' ? styles.certOptionSelected : styles.certOption}
          onTap={() => this.handleFieldChange('certificateOption', 'import')}
        >
          <view style={styles.radioButton}>
            {option === 'import' && <view style={styles.radioSelected} />}
          </view>
          <view style={styles.certOptionContent}>
            <label
              value="Import existing certificate"
              font={systemBoldFont(13)}
              color={option === 'import' ? '#FFFFFF' : '#CCCCCC'}
            />
            <label
              value="From file or PKCS#12 bundle"
              font={systemFont(11)}
              color="#4ADE80"
              marginTop={2}
            />
          </view>
          {option === 'import' && (
            <view
              style={styles.configureButton}
              onTap={this.handleShowImport.bind(this)}
            >
              <label
                value="Import →"
                font={systemFont(12)}
                color="#FFFC00"
              />
            </view>
          )}
        </view>

        {/* Selected certificate display */}
        {selectedCertId && (
          <view style={styles.selectedCertBox}>
            <label value="✓" font={systemBoldFont(16)} color="#4ADE80" marginRight={8} />
            <label
              value={`Certificate configured: ${selectedCertId}`}
              font={systemFont(12)}
              color="#4ADE80"
            />
          </view>
        )}
      </view>
    </view>;
  }

  private handleFieldChange(field: string, value: any): void {
    if (this.context.onFieldChange) {
      this.context.onFieldChange(field, value);
    }
  }

  private handleShowEnrollment(): void {
    if (this.context.onShowEnrollment) {
      this.context.onShowEnrollment();
    }
  }

  private handleShowImport(): void {
    if (this.context.onShowImport) {
      this.context.onShowImport();
    }
  }

  private handleAddServer(): void {
    const { serverName, host, port, protocol, certificateOption, selectedCertificateId } = this.viewModel;

    if (this.context.onAddServer) {
      this.context.onAddServer({
        name: serverName,
        host,
        port,
        protocol,
        useTls: protocol === 'ssl',
        certificateId: protocol === 'ssl' ? selectedCertificateId : undefined,
      });
    }
  }

  private handleCancel(): void {
    if (this.context.onCancel) {
      this.context.onCancel();
    }
  }
}

const styles = {
  overlay: new Style<View>({
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
    maxHeight: '90%',
    backgroundColor: '#2A2A2A',
    borderRadius: 12,
  }),

  header: new Style<View>({
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

  content: new Style<View>({
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
    justifyContent: 'space-between',
  }),

  protocolOption: new Style<View>({
    flex: 1,
    padding: 12,
    backgroundColor: '#1E1E1E',
    borderRadius: 4,
    borderWidth: 1,
    borderColor: '#3A3A3A',
    alignItems: 'center',
    marginRight: 8,
  }),

  protocolOptionSelected: new Style<View>({
    flex: 1,
    padding: 12,
    backgroundColor: '#FFFC00',
    borderRadius: 4,
    borderWidth: 1,
    borderColor: '#FFFC00',
    alignItems: 'center',
    marginRight: 8,
  }),

  certSection: new Style<View>({
    marginTop: 20,
    paddingTop: 20,
    borderTopWidth: 1,
    borderTopColor: '#3A3A3A',
  }),

  certHeader: new Style<View>({
    marginBottom: 12,
  }),

  certOptions: new Style<View>({}),

  certOption: new Style<View>({
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#1E1E1E',
    padding: 12,
    borderRadius: 4,
    borderWidth: 1,
    borderColor: '#3A3A3A',
    marginBottom: 8,
  }),

  certOptionSelected: new Style<View>({
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#2A2A2A',
    padding: 12,
    borderRadius: 4,
    borderWidth: 2,
    borderColor: '#FFFC00',
    marginBottom: 8,
  }),

  radioButton: new Style<View>({
    width: 20,
    height: 20,
    borderRadius: 10,
    borderWidth: 2,
    borderColor: '#FFFC00',
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 12,
  }),

  radioSelected: new Style<View>({
    width: 10,
    height: 10,
    borderRadius: 5,
    backgroundColor: '#FFFC00',
  }),

  certOptionContent: new Style<View>({
    flex: 1,
  }),

  configureButton: new Style<View>({
    paddingLeft: 12,
    paddingRight: 12,
    paddingTop: 6,
    paddingBottom: 6,
    backgroundColor: '#3A3A3A',
    borderRadius: 4,
  }),

  selectedCertBox: new Style<View>({
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(76, 175, 80, 0.1)',
    padding: 12,
    borderRadius: 4,
    borderWidth: 1,
    borderColor: '#4ADE80',
    marginTop: 8,
  }),

  actions: new Style<View>({
    flexDirection: 'row',
    justifyContent: 'flex-end',
    padding: 20,
  }),

  cancelButton: new Style<View>({
    paddingLeft: 20,
    paddingRight: 20,
    paddingTop: 10,
    paddingBottom: 10,
    borderRadius: 4,
    marginRight: 12,
  }),

  addButton: new Style<View>({
    paddingLeft: 20,
    paddingRight: 20,
    paddingTop: 10,
    paddingBottom: 10,
    backgroundColor: '#FFFC00',
    borderRadius: 4,
  }),
};
