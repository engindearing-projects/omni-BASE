import { Component } from 'valdi_core/src/Component';
import { Label, View } from 'valdi_tsx/src/NativeTemplateElements';
import { Style } from 'valdi_core/src/Style';
import { systemFont, systemBoldFont } from 'valdi_core/src/SystemFont';

/**
 * @ViewModel
 * @ExportModel({
 *   ios: 'CertificateEnrollmentViewModel',
 *   android: 'com.engindearing.omnitak.CertificateEnrollmentViewModel'
 * })
 */
export interface CertificateEnrollmentViewModel {
  serverUrl: string;
  username: string;
  password: string;
  validityDays: number;
  isEnrolling: boolean;
  error?: string;
  success?: boolean;
}

/**
 * @Context
 * @ExportModel({
 *   ios: 'CertificateEnrollmentContext',
 *   android: 'com.engindearing.omnitak.CertificateEnrollmentContext'
 * })
 */
export interface CertificateEnrollmentContext {
  onEnroll?: (username: string, password: string, validityDays: number) => void;
  onCancel?: () => void;
  onUsernameChange?: (value: string) => void;
  onPasswordChange?: (value: string) => void;
  onValidityChange?: (days: number) => void;
}

/**
 * @Component
 * @ExportModel({
 *   ios: 'CertificateEnrollmentDialog',
 *   android: 'com.engindearing.omnitak.CertificateEnrollmentDialog'
 * })
 *
 * Dialog for enrolling and obtaining a certificate from a TAK server.
 * Uses username/password authentication to request a client certificate.
 */
export class CertificateEnrollmentDialog extends Component<
  CertificateEnrollmentViewModel,
  CertificateEnrollmentContext
> {
  onCreate(): void {
    console.log('CertificateEnrollmentDialog onCreate');
  }

  onRender(): void {
    const { serverUrl, username, password, validityDays, isEnrolling, error, success } = this.viewModel;

    <view style={styles.overlay}>
      <view style={styles.dialog}>
        {/* Header */}
        <view style={styles.header}>
          <label
            value="Certificate Enrollment"
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
          {/* Server URL display */}
          <label
            value="TAK Server"
            font={systemFont(12)}
            color="#CCCCCC"
            marginBottom={4}
          />
          <view style={styles.serverUrlBox}>
            <label
              value={serverUrl}
              font={systemFont(14)}
              color="#4ADE80"
            />
          </view>

          {/* Instructions */}
          <view style={styles.instructionBox}>
            <label
              value="Enter your TAK server credentials to obtain a client certificate."
              font={systemFont(12)}
              color="#CCCCCC"
            />
          </view>

          {/* Username */}
          <label
            value="Username"
            font={systemFont(12)}
            color="#CCCCCC"
            marginTop={16}
            marginBottom={4}
          />
          <view style={styles.input}>
            {/* TODO: Replace with actual Valdi TextInput when available */}
            <label
              value={username || 'Enter username...'}
              font={systemFont(14)}
              color={username ? '#FFFFFF' : '#666666'}
            />
          </view>

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
              value={password ? '•'.repeat(password.length) : 'Enter password...'}
              font={systemFont(14)}
              color={password ? '#FFFFFF' : '#666666'}
            />
          </view>

          {/* Validity period */}
          <label
            value="Certificate Validity"
            font={systemFont(12)}
            color="#CCCCCC"
            marginTop={16}
            marginBottom={4}
          />
          <view style={styles.validityOptions}>
            {this.renderValidityOption(30, validityDays === 30)}
            {this.renderValidityOption(90, validityDays === 90)}
            {this.renderValidityOption(365, validityDays === 365)}
            {this.renderValidityOption(730, validityDays === 730)}
          </view>

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
                value="Certificate enrolled successfully!"
                font={systemFont(12)}
                color="#4ADE80"
              />
            </view>
          )}

          {/* Loading indicator */}
          {isEnrolling && (
            <view style={styles.loadingBox}>
              <label
                value="Contacting TAK server..."
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
            style={isEnrolling ? styles.enrollButtonDisabled : styles.enrollButton}
            onTap={isEnrolling ? undefined : this.handleEnroll.bind(this)}
          >
            <label
              value={isEnrolling ? "Enrolling..." : "Enroll & Save"}
              font={systemBoldFont(14)}
              color={isEnrolling ? "#666666" : "#1E1E1E"}
            />
          </view>
        </view>
      </view>
    </view>;
  }

  private renderValidityOption(days: number, selected: boolean): void {
    const label = days === 30 ? '30 days' : days === 90 ? '90 days' : days === 365 ? '1 year' : '2 years';

    <view
      style={selected ? styles.validityOptionSelected : styles.validityOption}
      onTap={() => this.handleValidityChange(days)}
    >
      <label
        value={label}
        font={systemFont(12)}
        color={selected ? '#1E1E1E' : '#FFFFFF'}
      />
    </view>;
  }

  private handleEnroll(): void {
    const { username, password, validityDays } = this.viewModel;

    if (!username || !password) {
      return;
    }

    if (this.context.onEnroll) {
      this.context.onEnroll(username, password, validityDays);
    }
  }

  private handleCancel(): void {
    if (this.context.onCancel) {
      this.context.onCancel();
    }
  }

  private handleValidityChange(days: number): void {
    if (this.context.onValidityChange) {
      this.context.onValidityChange(days);
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

  serverUrlBox: new Style<View>({
    backgroundColor: '#1E1E1E',
    padding: 12,
    borderRadius: 4,
    borderWidth: 1,
    borderColor: '#4ADE80',
    marginBottom: 8,
  }),

  instructionBox: new Style<View>({
    backgroundColor: '#1E1E1E',
    padding: 12,
    borderRadius: 4,
    borderLeftWidth: 3,
    borderLeftColor: '#FFFC00',
  }),

  input: new Style<View>({
    backgroundColor: '#1E1E1E',
    padding: 12,
    borderRadius: 4,
    borderWidth: 1,
    borderColor: '#3A3A3A',
  }),

  validityOptions: new Style<View>({
    flexDirection: 'row',
    justifyContent: 'space-between',
  }),

  validityOption: new Style<View>({
    flex: 1,
    padding: 10,
    backgroundColor: '#1E1E1E',
    borderRadius: 4,
    borderWidth: 1,
    borderColor: '#3A3A3A',
    alignItems: 'center',
    marginRight: 8,
  }),

  validityOptionSelected: new Style<View>({
    flex: 1,
    padding: 10,
    backgroundColor: '#FFFC00',
    borderRadius: 4,
    borderWidth: 1,
    borderColor: '#FFFC00',
    alignItems: 'center',
    marginRight: 8,
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

  enrollButton: new Style<View>({
    paddingLeft: 20,
    paddingRight: 20,
    paddingTop: 10,
    paddingBottom: 10,
    backgroundColor: '#FFFC00',
    borderRadius: 4,
  }),

  enrollButtonDisabled: new Style<View>({
    paddingLeft: 20,
    paddingRight: 20,
    paddingTop: 10,
    paddingBottom: 10,
    backgroundColor: '#3A3A3A',
    borderRadius: 4,
  }),
};
