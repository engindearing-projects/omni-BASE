import { Component } from 'valdi_core/src/Component';
import { Label, View } from 'valdi_tsx/src/NativeTemplateElements';
import { Style } from 'valdi_core/src/Style';
import { systemFont, systemBoldFont } from 'valdi_core/src/SystemFont';

/**
 * @ExportModel({
 *   ios: 'StoredCertificate',
 *   android: 'com.engindearing.omnitak.StoredCertificate'
 * })
 */
export interface StoredCertificate {
  id: string;
  name: string;
  commonName: string;
  issuer: string;
  validFrom: string;
  validUntil: string;
  status: 'valid' | 'expiring_soon' | 'expired';
  daysUntilExpiry?: number;
  associatedServers?: string[];
}

/**
 * @ViewModel
 * @ExportModel({
 *   ios: 'CertificateManagementViewModel',
 *   android: 'com.engindearing.omnitak.CertificateManagementViewModel'
 * })
 */
export interface CertificateManagementViewModel {
  certificates: StoredCertificate[];
  showDeleteConfirmation: boolean;
  deletingCertId?: string;
}

/**
 * @Context
 * @ExportModel({
 *   ios: 'CertificateManagementContext',
 *   android: 'com.engindearing.omnitak.CertificateManagementContext'
 * })
 */
export interface CertificateManagementContext {
  onBack?: () => void;
  onAddCertificate?: () => void;
  onViewDetails?: (certId: string) => void;
  onDeleteCertificate?: (certId: string) => void;
  onConfirmDelete?: (certId: string) => void;
  onCancelDelete?: () => void;
}

/**
 * @Component
 * @ExportModel({
 *   ios: 'CertificateManagementScreen',
 *   android: 'com.engindearing.omnitak.CertificateManagementScreen'
 * })
 *
 * Screen for managing stored client certificates.
 * Shows certificate status, expiration warnings, and allows adding/removing certificates.
 */
export class CertificateManagementScreen extends Component<
  CertificateManagementViewModel,
  CertificateManagementContext
> {
  onCreate(): void {
    console.log('CertificateManagementScreen onCreate');
  }

  onRender(): void {
    const { certificates, showDeleteConfirmation, deletingCertId } = this.viewModel;

    <view style={styles.container}>
      {/* Header */}
      <view style={styles.header}>
        <view style={styles.backButton} onTap={this.handleBack.bind(this)}>
          <label value="←" font={systemFont(24)} color="#FFFFFF" />
        </view>
        <label
          value="Certificates"
          font={systemBoldFont(20)}
          color="#FFFFFF"
        />
        <view
          style={styles.addButton}
          onTap={this.handleAddCertificate.bind(this)}
        >
          <label value="+" font={systemFont(28)} color="#FFFC00" />
        </view>
      </view>

      {/* Certificate list */}
      <view style={styles.scrollView}>
        <view style={styles.content}>
          {/* Info banner */}
          <view style={styles.infoBanner}>
            <label value="ℹ️" font={systemFont(16)} marginRight={8} />
            <label
              value="Client certificates are used for secure TLS connections to TAK servers."
              font={systemFont(12)}
              color="#CCCCCC"}
            />
          </view>

          {certificates.length === 0 ? (
            <view style={styles.emptyState}>
              <label value="🔒" font={systemFont(48)} marginBottom={12} />
              <label
                value="No certificates stored"
                font={systemFont(16)}
                color="#999999"
                marginBottom={8}
              />
              <label
                value="Tap + to add a certificate"
                font={systemFont(14)}
                color="#666666"
              />
            </view>
          ) : (
            certificates.map((cert) => this.renderCertificateItem(cert))
          )}
        </view>
      </view>

      {/* Delete confirmation dialog */}
      {showDeleteConfirmation && deletingCertId && this.renderDeleteConfirmation(deletingCertId)}
    </view>;
  }

  private renderCertificateItem(cert: StoredCertificate): void {
    const statusColor = this.getStatusColor(cert.status);
    const statusLabel = this.getStatusLabel(cert.status, cert.daysUntilExpiry);

    <view style={styles.certItem}>
      {/* Status indicator */}
      <view style={[styles.statusIndicator, { backgroundColor: statusColor }]} />

      {/* Certificate info */}
      <view style={styles.certInfo}>
        <view style={styles.certHeader}>
          <label
            value={cert.name || cert.commonName}
            font={systemBoldFont(16)}
            color="#FFFFFF"
          />
          <view style={styles.statusBadge}>
            <label
              value={statusLabel}
              font={systemFont(11)}
              color={statusColor}
            />
          </view>
        </view>

        <label
          value={`CN: ${cert.commonName}`}
          font={systemFont(13)}
          color="#CCCCCC"
          marginTop={4}
        />

        <label
          value={`Issuer: ${cert.issuer}`}
          font={systemFont(12)}
          color="#999999"
          marginTop={2}
        />

        <view style={styles.validityInfo}>
          <label
            value={`Valid: ${cert.validFrom} → ${cert.validUntil}`}
            font={systemFont(11)}
            color="#666666"
          />
        </view>

        {/* Associated servers */}
        {cert.associatedServers && cert.associatedServers.length > 0 && (
          <view style={styles.serversInfo}>
            <label
              value={`Used by: ${cert.associatedServers.join(', ')}`}
              font={systemFont(11)}
              color="#4ADE80"
              marginTop={4}
            />
          </view>
        )}

        {/* Expiry warning */}
        {cert.status === 'expiring_soon' && cert.daysUntilExpiry && (
          <view style={styles.warningBox}>
            <label value="⚠️" font={systemFont(14)} marginRight={6} />
            <label
              value={`Expires in ${cert.daysUntilExpiry} days`}
              font={systemFont(11)}
              color="#FFA500"
            />
          </view>
        )}

        {cert.status === 'expired' && (
          <view style={styles.errorBox}>
            <label value="❌" font={systemFont(14)} marginRight={6} />
            <label
              value="Certificate has expired"
              font={systemFont(11)}
              color="#FF5252"
            />
          </view>
        )}
      </view>

      {/* Action buttons */}
      <view style={styles.certActions}>
        <view
          style={styles.iconButton}
          onTap={() => this.handleViewDetails(cert.id)}
        >
          <label value="👁" font={systemFont(16)} />
        </view>
        <view
          style={styles.iconButton}
          onTap={() => this.handleDelete(cert.id)}
        >
          <label value="🗑️" font={systemFont(16)} />
        </view>
      </view>
    </view>;
  }

  private renderDeleteConfirmation(certId: string): void {
    const cert = this.viewModel.certificates.find((c) => c.id === certId);
    if (!cert) return;

    <view style={styles.dialogOverlay}>
      <view style={styles.dialog}>
        <view style={styles.dialogHeader}>
          <label
            value="Delete Certificate?"
            font={systemBoldFont(18)}
            color="#FFFFFF"
          />
        </view>

        <view style={styles.dialogContent}>
          <label
            value={`Are you sure you want to delete the certificate "${cert.name || cert.commonName}"?`}
            font={systemFont(14)}
            color="#CCCCCC"
            marginBottom={12}
          />

          {cert.associatedServers && cert.associatedServers.length > 0 && (
            <view style={styles.warningBox}>
              <label value="⚠️" font={systemFont(16)} marginRight={8} />
              <label
                value={`This certificate is used by ${cert.associatedServers.length} server(s). Those connections will no longer work.`}
                font={systemFont(12)}
                color="#FFA500"
              />
            </view>
          )}
        </view>

        <view style={styles.dialogActions}>
          <view
            style={styles.dialogButton}
            onTap={this.handleCancelDelete.bind(this)}
          >
            <label
              value="Cancel"
              font={systemFont(14)}
              color="#999999"
            />
          </view>
          <view
            style={styles.deleteButton}
            onTap={() => this.handleConfirmDelete(certId)}
          >
            <label
              value="Delete"
              font={systemBoldFont(14)}
              color="#FFFFFF"
            />
          </view>
        </view>
      </view>
    </view>;
  }

  private getStatusColor(status: string): string {
    switch (status) {
      case 'valid':
        return '#4ADE80';
      case 'expiring_soon':
        return '#FFA500';
      case 'expired':
        return '#FF5252';
      default:
        return '#666666';
    }
  }

  private getStatusLabel(status: string, daysUntilExpiry?: number): string {
    switch (status) {
      case 'valid':
        return 'Valid';
      case 'expiring_soon':
        return `Expires in ${daysUntilExpiry} days`;
      case 'expired':
        return 'Expired';
      default:
        return 'Unknown';
    }
  }

  private handleBack(): void {
    if (this.context.onBack) {
      this.context.onBack();
    }
  }

  private handleAddCertificate(): void {
    if (this.context.onAddCertificate) {
      this.context.onAddCertificate();
    }
  }

  private handleViewDetails(certId: string): void {
    if (this.context.onViewDetails) {
      this.context.onViewDetails(certId);
    }
  }

  private handleDelete(certId: string): void {
    if (this.context.onDeleteCertificate) {
      this.context.onDeleteCertificate(certId);
    }
  }

  private handleConfirmDelete(certId: string): void {
    if (this.context.onConfirmDelete) {
      this.context.onConfirmDelete(certId);
    }
  }

  private handleCancelDelete(): void {
    if (this.context.onCancelDelete) {
      this.context.onCancelDelete();
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

  scrollView: new Style<View>({}),

  content: new Style<View>({
    padding: 16,
  }),

  infoBanner: new Style<View>({
    flexDirection: 'row',
    backgroundColor: '#2A2A2A',
    padding: 12,
    borderRadius: 4,
    borderLeftWidth: 3,
    borderLeftColor: '#4ADE80',
    marginBottom: 16,
  }),

  emptyState: new Style<View>({
    padding: 40,
    alignItems: 'center',
    justifyContent: 'center',
  }),

  certItem: new Style<View>({
    flexDirection: 'row',
    backgroundColor: '#2A2A2A',
    borderRadius: 8,
    marginBottom: 12,
    overflow: 'hidden',
  }),

  statusIndicator: new Style<View>({
    width: 4,
  }),

  certInfo: new Style<View>({
    flex: 1,
    padding: 16,
  }),

  certHeader: new Style<View>({
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  }),

  statusBadge: new Style<View>({
    backgroundColor: '#1E1E1E',
    paddingLeft: 8,
    paddingRight: 8,
    paddingTop: 4,
    paddingBottom: 4,
    borderRadius: 4,
  }),

  validityInfo: new Style<View>({
    marginTop: 8,
  }),

  serversInfo: new Style<View>({
    marginTop: 4,
  }),

  warningBox: new Style<View>({
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(255, 165, 0, 0.1)',
    padding: 8,
    borderRadius: 4,
    marginTop: 8,
  }),

  errorBox: new Style<View>({
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(255, 82, 82, 0.1)',
    padding: 8,
    borderRadius: 4,
    marginTop: 8,
  }),

  certActions: new Style<View>({
    flexDirection: 'column',
    justifyContent: 'center',
    padding: 8,
  }),

  iconButton: new Style<View>({
    width: 36,
    height: 36,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#3A3A3A',
    borderRadius: 4,
    marginBottom: 8,
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
    maxWidth: 400,
    backgroundColor: '#2A2A2A',
    borderRadius: 12,
  }),

  dialogHeader: new Style<View>({
    padding: 20,
    borderBottomWidth: 1,
    borderBottomColor: '#3A3A3A',
  }),

  dialogContent: new Style<View>({
    padding: 20,
  }),

  dialogActions: new Style<View>({
    flexDirection: 'row',
    justifyContent: 'flex-end',
    padding: 20,
    borderTopWidth: 1,
    borderTopColor: '#3A3A3A',
  }),

  dialogButton: new Style<View>({
    paddingLeft: 20,
    paddingRight: 20,
    paddingTop: 10,
    paddingBottom: 10,
    borderRadius: 4,
    marginRight: 12,
  }),

  deleteButton: new Style<View>({
    paddingLeft: 20,
    paddingRight: 20,
    paddingTop: 10,
    paddingBottom: 10,
    backgroundColor: '#FF5252',
    borderRadius: 4,
  }),
};
