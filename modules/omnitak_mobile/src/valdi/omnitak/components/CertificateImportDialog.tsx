import { Component } from 'valdi_core/src/Component';
import { Label, View } from 'valdi_tsx/src/NativeTemplateElements';
import { Style } from 'valdi_core/src/Style';
import { systemFont, systemBoldFont } from 'valdi_core/src/SystemFont';

/**
 * @ExportModel({
 *   ios: 'CertificateFile',
 *   android: 'com.engindearing.omnitak.CertificateFile'
 * })
 */
export interface CertificateFile {
  type: 'client_cert' | 'private_key' | 'ca_cert' | 'pkcs12';
  filename?: string;
  content?: string;
}

/**
 * @ViewModel
 * @ExportModel({
 *   ios: 'CertificateImportViewModel',
 *   android: 'com.engindearing.omnitak.CertificateImportViewModel'
 * })
 */
export interface CertificateImportViewModel {
  importMethod: 'pem' | 'pkcs12';
  clientCert?: CertificateFile;
  privateKey?: CertificateFile;
  caCert?: CertificateFile;
  pkcs12File?: CertificateFile;
  pkcs12Password?: string;
  isImporting: boolean;
  error?: string;
  success?: boolean;
}

/**
 * @Context
 * @ExportModel({
 *   ios: 'CertificateImportContext',
 *   android: 'com.engindearing.omnitak.CertificateImportContext'
 * })
 */
export interface CertificateImportContext {
  onImport?: (method: string, files: any) => void;
  onCancel?: () => void;
  onMethodChange?: (method: 'pem' | 'pkcs12') => void;
  onSelectFile?: (type: string) => void;
  onPasswordChange?: (password: string) => void;
}

/**
 * @Component
 * @ExportModel({
 *   ios: 'CertificateImportDialog',
 *   android: 'com.engindearing.omnitak.CertificateImportDialog'
 * })
 *
 * Dialog for importing existing certificates from files.
 * Supports both individual PEM files and PKCS#12 bundles.
 */
export class CertificateImportDialog extends Component<
  CertificateImportViewModel,
  CertificateImportContext
> {
  onCreate(): void {
    console.log('CertificateImportDialog onCreate');
  }

  onRender(): void {
    const {
      importMethod,
      clientCert,
      privateKey,
      caCert,
      pkcs12File,
      pkcs12Password,
      isImporting,
      error,
      success,
    } = this.viewModel;

    <view style={styles.overlay}>
      <view style={styles.dialog}>
        {/* Header */}
        <view style={styles.header}>
          <label
            value="Import Certificate"
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
          {/* Import method selector */}
          <label
            value="Import Method"
            font={systemFont(12)}
            color="#CCCCCC"
            marginBottom={8}
          />
          <view style={styles.methodSelector}>
            <view
              style={importMethod === 'pem' ? styles.methodOptionSelected : styles.methodOption}
              onTap={() => this.handleMethodChange('pem')}
            >
              <label
                value="PEM Files"
                font={systemFont(14)}
                color={importMethod === 'pem' ? '#1E1E1E' : '#FFFFFF'}
              />
              <label
                value="(3 separate files)"
                font={systemFont(10)}
                color={importMethod === 'pem' ? '#666666' : '#999999'}
                marginTop={2}
              />
            </view>
            <view
              style={importMethod === 'pkcs12' ? styles.methodOptionSelected : styles.methodOption}
              onTap={() => this.handleMethodChange('pkcs12')}
            >
              <label
                value="PKCS#12"
                font={systemFont(14)}
                color={importMethod === 'pkcs12' ? '#1E1E1E' : '#FFFFFF'}
              />
              <label
                value="(.p12 or .pfx)"
                font={systemFont(10)}
                color={importMethod === 'pkcs12' ? '#666666' : '#999999'}
                marginTop={2}
              />
            </view>
          </view>

          {/* PEM import UI */}
          {importMethod === 'pem' && this.renderPemImport(clientCert, privateKey, caCert)}

          {/* PKCS#12 import UI */}
          {importMethod === 'pkcs12' && this.renderPkcs12Import(pkcs12File, pkcs12Password)}

          {/* Error message */}
          {error && (
            <view style={styles.errorBox}>
              <label value="⚠️" font={systemFont(16)} marginRight={8} />
              <label
                value={error}
                font={systemFont(12)}
                color="#FF5252"
              />
            </view>
          )}

          {/* Success message */}
          {success && (
            <view style={styles.successBox}>
              <label value="✓" font={systemBoldFont(18)} color="#4ADE80" marginRight={8} />
              <label
                value="Certificate imported successfully!"
                font={systemFont(12)}
                color="#4ADE80"
              />
            </view>
          )}

          {/* Loading indicator */}
          {isImporting && (
            <view style={styles.loadingBox}>
              <label
                value="Importing and validating certificate..."
                font={systemFont(12)}
                color="#FFA500"
              />
            </view>
          )}
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
            style={this.canImport() && !isImporting ? styles.importButton : styles.importButtonDisabled}
            onTap={this.canImport() && !isImporting ? this.handleImport.bind(this) : undefined}
          >
            <label
              value={isImporting ? "Importing..." : "Import & Save"}
              font={systemBoldFont(14)}
              color={this.canImport() && !isImporting ? '#1E1E1E' : '#666666'}
            />
          </view>
        </view>
      </view>
    </view>;
  }

  private renderPemImport(
    clientCert?: CertificateFile,
    privateKey?: CertificateFile,
    caCert?: CertificateFile
  ): void {
    <view>
      {/* Instruction */}
      <view style={styles.instructionBox}>
        <label
          value="Select the three certificate files provided by your TAK server administrator."
          font={systemFont(12)}
          color="#CCCCCC"
        />
      </view>

      {/* Client Certificate */}
      <label
        value="Client Certificate"
        font={systemFont(12)}
        color="#CCCCCC"
        marginTop={16}
        marginBottom={4}
      />
      {this.renderFileSelector('client_cert', clientCert, 'client-cert.pem')}

      {/* Private Key */}
      <label
        value="Private Key"
        font={systemFont(12)}
        color="#CCCCCC"
        marginTop={12}
        marginBottom={4}
      />
      {this.renderFileSelector('private_key', privateKey, 'client-key.pem')}

      {/* CA Certificate */}
      <label
        value="CA Certificate (Optional)"
        font={systemFont(12)}
        color="#CCCCCC"
        marginTop={12}
        marginBottom={4}
      />
      {this.renderFileSelector('ca_cert', caCert, 'ca-cert.pem')}
    </view>;
  }

  private renderPkcs12Import(pkcs12File?: CertificateFile, password?: string): void {
    <view>
      {/* Instruction */}
      <view style={styles.instructionBox}>
        <label
          value="Select a PKCS#12 file (.p12 or .pfx) containing your certificate bundle."
          font={systemFont(12)}
          color="#CCCCCC"
        />
      </view>

      {/* PKCS#12 File */}
      <label
        value="PKCS#12 File"
        font={systemFont(12)}
        color="#CCCCCC"
        marginTop={16}
        marginBottom={4}
      />
      {this.renderFileSelector('pkcs12', pkcs12File, 'certificate.p12')}

      {/* Password */}
      <label
        value="Password"
        font={systemFont(12)}
        color="#CCCCCC"
        marginTop={16}
        marginBottom={4}
      />
      <view style={styles.input}>
        {/* TODO: Replace with actual Valdi SecureTextInput */}
        <label
          value={password ? '•'.repeat(password.length) : 'Enter password (if encrypted)...'}
          font={systemFont(14)}
          color={password ? '#FFFFFF' : '#666666'}
        />
      </view>
    </view>;
  }

  private renderFileSelector(type: string, file?: CertificateFile, placeholder?: string): void {
    <view
      style={file ? styles.fileSelectorWithFile : styles.fileSelector}
      onTap={() => this.handleSelectFile(type)}
    >
      {file ? (
        <view style={styles.fileInfo}>
          <label value="📄" font={systemFont(18)} marginRight={8} />
          <view>
            <label
              value={file.filename || 'Selected file'}
              font={systemFont(14)}
              color="#4ADE80"
            />
            <label
              value="Tap to change"
              font={systemFont(10)}
              color="#999999"
              marginTop={2}
            />
          </view>
          <view style={styles.checkMark}>
            <label value="✓" font={systemBoldFont(16)} color="#4ADE80" />
          </view>
        </view>
      ) : (
        <view style={styles.filePlaceholder}>
          <label value="📁" font={systemFont(20)} marginRight={8} />
          <label
            value={placeholder || 'Tap to select file...'}
            font={systemFont(14)}
            color="#999999"
          />
        </view>
      )}
    </view>;
  }

  private canImport(): boolean {
    const { importMethod, clientCert, privateKey, pkcs12File } = this.viewModel;

    if (importMethod === 'pem') {
      return !!(clientCert && privateKey);
    } else {
      return !!pkcs12File;
    }
  }

  private handleMethodChange(method: 'pem' | 'pkcs12'): void {
    if (this.context.onMethodChange) {
      this.context.onMethodChange(method);
    }
  }

  private handleSelectFile(type: string): void {
    if (this.context.onSelectFile) {
      this.context.onSelectFile(type);
    }
  }

  private handleImport(): void {
    const { importMethod, clientCert, privateKey, caCert, pkcs12File, pkcs12Password } = this.viewModel;

    if (this.context.onImport) {
      if (importMethod === 'pem') {
        this.context.onImport('pem', { clientCert, privateKey, caCert });
      } else {
        this.context.onImport('pkcs12', { pkcs12File, password: pkcs12Password });
      }
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
    backgroundColor: 'rgba(0, 0, 0, 0.8)',
    alignItems: 'center',
    justifyContent: 'center',
    zIndex: 3000,
  }),

  dialog: new Style<View>({
    width: '90%',
    maxWidth: 500,
    backgroundColor: '#2A2A2A',
    borderRadius: 12,
    maxHeight: '90%',
  }),

  header: new Style<View>({
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: 20,
    borderBottomWidth: 1,
    borderBottomColor: '#3A3A3A',
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

  methodSelector: new Style<View>({
    flexDirection: 'row',
    marginBottom: 16,
  }),

  methodOption: new Style<View>({
    flex: 1,
    padding: 12,
    backgroundColor: '#1E1E1E',
    borderRadius: 4,
    borderWidth: 1,
    borderColor: '#3A3A3A',
    alignItems: 'center',
    marginRight: 8,
  }),

  methodOptionSelected: new Style<View>({
    flex: 1,
    padding: 12,
    backgroundColor: '#FFFC00',
    borderRadius: 4,
    borderWidth: 1,
    borderColor: '#FFFC00',
    alignItems: 'center',
    marginRight: 8,
  }),

  instructionBox: new Style<View>({
    backgroundColor: '#1E1E1E',
    padding: 12,
    borderRadius: 4,
    borderLeftWidth: 3,
    borderLeftColor: '#FFFC00',
  }),

  fileSelector: new Style<View>({
    backgroundColor: '#1E1E1E',
    padding: 12,
    borderRadius: 4,
    borderWidth: 1,
    borderColor: '#3A3A3A',
    borderStyle: 'dashed',
  }),

  fileSelectorWithFile: new Style<View>({
    backgroundColor: '#1E1E1E',
    padding: 12,
    borderRadius: 4,
    borderWidth: 1,
    borderColor: '#4ADE80',
  }),

  fileInfo: new Style<View>({
    flexDirection: 'row',
    alignItems: 'center',
  }),

  filePlaceholder: new Style<View>({
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
  }),

  checkMark: new Style<View>({
    marginLeft: 'auto',
  }),

  input: new Style<View>({
    backgroundColor: '#1E1E1E',
    padding: 12,
    borderRadius: 4,
    borderWidth: 1,
    borderColor: '#3A3A3A',
  }),

  errorBox: new Style<View>({
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(255, 82, 82, 0.1)',
    padding: 12,
    borderRadius: 4,
    borderLeftWidth: 3,
    borderLeftColor: '#FF5252',
    marginTop: 16,
  }),

  successBox: new Style<View>({
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(76, 175, 80, 0.1)',
    padding: 12,
    borderRadius: 4,
    borderLeftWidth: 3,
    borderLeftColor: '#4ADE80',
    marginTop: 16,
  }),

  loadingBox: new Style<View>({
    backgroundColor: 'rgba(255, 165, 0, 0.1)',
    padding: 12,
    borderRadius: 4,
    borderLeftWidth: 3,
    borderLeftColor: '#FFA500',
    marginTop: 16,
    alignItems: 'center',
  }),

  actions: new Style<View>({
    flexDirection: 'row',
    justifyContent: 'flex-end',
    padding: 20,
    borderTopWidth: 1,
    borderTopColor: '#3A3A3A',
  }),

  cancelButton: new Style<View>({
    paddingLeft: 20,
    paddingRight: 20,
    paddingTop: 10,
    paddingBottom: 10,
    borderRadius: 4,
    marginRight: 12,
  }),

  importButton: new Style<View>({
    paddingLeft: 20,
    paddingRight: 20,
    paddingTop: 10,
    paddingBottom: 10,
    backgroundColor: '#FFFC00',
    borderRadius: 4,
  }),

  importButtonDisabled: new Style<View>({
    paddingLeft: 20,
    paddingRight: 20,
    paddingTop: 10,
    paddingBottom: 10,
    backgroundColor: '#3A3A3A',
    borderRadius: 4,
  }),
};
