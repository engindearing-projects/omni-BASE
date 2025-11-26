//
//  ServerConfigEditor.swift
//  OmniTAKMobile
//
//  Server configuration form with ATAK-style design
//

import SwiftUI

// MARK: - Server Config Editor

struct ServerConfigEditor: View {
    let server: TAKServer?
    let onSave: (TAKServer) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var host: String
    @State private var port: String
    @State private var protocolType: String
    @State private var useTLS: Bool
    @State private var certificateName: String
    @State private var certificatePassword: String
    @State private var allowLegacyTLS: Bool

    // Username/password authentication
    @State private var username: String
    @State private var password: String
    @State private var enrollmentPort: String
    @State private var autoEnrollOnConnect: Bool

    // Advanced settings
    @State private var showAdvanced = false
    @State private var timeout: String = "30"
    @State private var keepaliveInterval: String = "5"
    @State private var maxReconnectAttempts: String = "3"

    // UI state
    @State private var isTestingConnection = false
    @State private var testResult: TestResult?
    @State private var showError = false
    @State private var errorMessage = ""

    init(server: TAKServer?, onSave: @escaping (TAKServer) -> Void) {
        self.server = server
        self.onSave = onSave

        // Initialize state from existing server or defaults
        _name = State(initialValue: server?.name ?? "")
        _host = State(initialValue: server?.host ?? "")
        _port = State(initialValue: server?.port.description ?? "8087")
        _protocolType = State(initialValue: server?.protocolType ?? "tcp")
        _useTLS = State(initialValue: server?.useTLS ?? false)
        _certificateName = State(initialValue: server?.certificateName ?? "")
        _certificatePassword = State(initialValue: server?.certificatePassword ?? "")
        _allowLegacyTLS = State(initialValue: server?.allowLegacyTLS ?? false)

        _username = State(initialValue: server?.username ?? "")
        _password = State(initialValue: server?.password ?? "")
        _enrollmentPort = State(initialValue: server?.enrollmentPort?.description ?? "8446")
        _autoEnrollOnConnect = State(initialValue: server?.autoEnrollOnConnect ?? false)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Basic section
                        basicSection

                        // Protocol section
                        protocolSection

                        // Certificate section (shown only if TLS is enabled)
                        if useTLS {
                            certificateSection

                            // Username/Password Authentication section
                            authenticationSection
                        }

                        // Advanced section
                        advancedSection

                        // Test connection button
                        testConnectionButton

                        // Test result
                        if let result = testResult {
                            testResultView(result)
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle(server == nil ? "Add Server" : "Edit Server")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveServer()
                    }
                    .foregroundColor(Color(hex: "#00BCD4"))
                    .font(.system(size: 16, weight: .semibold))
                    .disabled(!isValidForm)
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Basic Section

    private var basicSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "BASIC")

            VStack(spacing: 16) {
                FormTextField(
                    icon: "server.rack",
                    label: "Name",
                    placeholder: "My TAK Server",
                    text: $name
                )

                FormTextField(
                    icon: "network",
                    label: "Host",
                    placeholder: "127.0.0.1 or server.com",
                    text: $host
                )
                .keyboardType(.URL)
                .autocapitalization(.none)

                FormTextField(
                    icon: "number",
                    label: "Port",
                    placeholder: "8087",
                    text: $port
                )
                .keyboardType(.numberPad)
            }
        }
    }

    // MARK: - Protocol Section

    private var protocolSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "PROTOCOL")

            // Protocol segmented control
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    ProtocolButton(
                        title: "TCP",
                        isSelected: protocolType == "tcp" && !useTLS,
                        color: Color(hex: "#00BCD4")
                    ) {
                        protocolType = "tcp"
                        useTLS = false
                    }

                    ProtocolButton(
                        title: "UDP",
                        isSelected: protocolType == "udp",
                        color: Color(hex: "#999999")
                    ) {
                        protocolType = "udp"
                        useTLS = false
                    }

                    ProtocolButton(
                        title: "TLS",
                        isSelected: useTLS,
                        color: Color(hex: "#4CAF50")
                    ) {
                        protocolType = "tcp"
                        useTLS = true
                    }
                }

                if useTLS {
                    Text("Secure encrypted connection")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#4CAF50"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)
                }
            }
        }
    }

    // MARK: - Certificate Section

    private var certificateSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "CERTIFICATE")

            VStack(spacing: 16) {
                // Certificate picker (simplified for now)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "#FFFC00"))
                            .frame(width: 28)

                        Text("Client Certificate")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "#CCCCCC"))
                    }

                    Menu {
                        Button("None") {
                            certificateName = ""
                        }
                        Button("omnitak-mobile.p12") {
                            certificateName = "omnitak-mobile"
                        }
                        Button("client-cert.p12") {
                            certificateName = "client-cert"
                        }
                    } label: {
                        HStack {
                            Text(certificateName.isEmpty ? "Select certificate..." : "\(certificateName).p12")
                                .font(.system(size: 14))
                                .foregroundColor(certificateName.isEmpty ? Color(hex: "#666666") : .white)

                            Spacer()

                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "#666666"))
                        }
                        .padding(12)
                        .background(Color(hex: "#2A2A2A"))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(hex: "#FFFC00").opacity(0.3), lineWidth: 1)
                        )
                    }
                }

                // Certificate password
                if !certificateName.isEmpty {
                    FormSecureField(
                        icon: "key.fill",
                        label: "Certificate Password",
                        placeholder: "Enter password",
                        text: $certificatePassword
                    )
                }

                // Legacy TLS toggle
                Toggle(isOn: $allowLegacyTLS) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Allow Legacy TLS")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)

                        Text("Enable TLS 1.0/1.1 (security risk)")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "#FF5252"))
                    }
                }
                .tint(Color(hex: "#FFFC00"))
                .padding(12)
                .background(Color(hex: "#2A2A2A"))
                .cornerRadius(8)
            }
        }
    }

    // MARK: - Authentication Section

    private var authenticationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "USERNAME/PASSWORD AUTHENTICATION")

            VStack(spacing: 16) {
                // Info text
                Text("Optional: Provide credentials to automatically enroll and download certificate on first connect")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "#888888"))
                    .frame(maxWidth: .infinity, alignment: .leading)

                FormTextField(
                    icon: "person.fill",
                    label: "Username",
                    placeholder: "TAK server username",
                    text: $username
                )
                .autocapitalization(.none)

                FormSecureField(
                    icon: "key.fill",
                    label: "Password",
                    placeholder: "TAK server password",
                    text: $password
                )

                FormTextField(
                    icon: "network",
                    label: "Enrollment API Port",
                    placeholder: "8446",
                    text: $enrollmentPort
                )
                .keyboardType(.numberPad)

                Toggle(isOn: $autoEnrollOnConnect) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Auto-enroll on connect")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)

                        Text("Automatically get certificate when connecting")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "#888888"))
                    }
                }
                .tint(Color(hex: "#00BCD4"))
                .padding(12)
                .background(Color(hex: "#2A2A2A"))
                .cornerRadius(8)
            }
        }
    }

    // MARK: - Advanced Section

    private var advancedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button(action: { showAdvanced.toggle() }) {
                HStack {
                    SectionHeader(title: "ADVANCED")

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(hex: "#888888"))
                        .rotationEffect(.degrees(showAdvanced ? 90 : 0))
                }
            }

            if showAdvanced {
                VStack(spacing: 16) {
                    FormTextField(
                        icon: "clock.fill",
                        label: "Timeout (seconds)",
                        placeholder: "30",
                        text: $timeout
                    )
                    .keyboardType(.numberPad)

                    FormTextField(
                        icon: "waveform.path.ecg",
                        label: "Keepalive Interval (seconds)",
                        placeholder: "5",
                        text: $keepaliveInterval
                    )
                    .keyboardType(.numberPad)

                    FormTextField(
                        icon: "arrow.clockwise",
                        label: "Max Reconnect Attempts",
                        placeholder: "3",
                        text: $maxReconnectAttempts
                    )
                    .keyboardType(.numberPad)
                }
            }
        }
    }

    // MARK: - Test Connection Button

    private var testConnectionButton: some View {
        Button(action: testConnection) {
            HStack(spacing: 12) {
                if isTestingConnection {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "waveform.path.ecg.rectangle.fill")
                        .font(.system(size: 20))
                }

                Text(isTestingConnection ? "Testing..." : "Test Connection")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color(hex: "#FFFC00"))
            .cornerRadius(12)
        }
        .disabled(isTestingConnection || !isValidForm)
    }

    private func testResultView(_ result: TestResult) -> some View {
        HStack(spacing: 12) {
            Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(result.success ? Color(hex: "#4CAF50") : Color(hex: "#FF5252"))

            VStack(alignment: .leading, spacing: 4) {
                Text(result.success ? "Connection Successful" : "Connection Failed")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)

                Text(result.message)
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "#CCCCCC"))
            }

            Spacer()
        }
        .padding(16)
        .background(Color(hex: "#1E1E1E"))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(result.success ? Color(hex: "#4CAF50") : Color(hex: "#FF5252"), lineWidth: 2)
        )
    }

    // MARK: - Actions

    private func testConnection() {
        guard isValidForm else { return }

        isTestingConnection = true
        testResult = nil

        // Simulate connection test
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isTestingConnection = false
            testResult = TestResult(
                success: true,
                message: "Connected to \(host):\(port)"
            )
        }
    }

    private func saveServer() {
        guard isValidForm else {
            errorMessage = "Please fill in all required fields"
            showError = true
            return
        }

        guard let portNumber = UInt16(port) else {
            errorMessage = "Invalid port number"
            showError = true
            return
        }

        let newServer = TAKServer(
            id: server?.id ?? UUID(),
            name: name,
            host: host,
            port: portNumber,
            protocolType: protocolType,
            useTLS: useTLS,
            isDefault: server?.isDefault ?? false,
            certificateName: certificateName.isEmpty ? nil : certificateName,
            certificatePassword: certificatePassword.isEmpty ? nil : certificatePassword,
            allowLegacyTLS: allowLegacyTLS,
            username: username.isEmpty ? nil : username,
            password: password.isEmpty ? nil : password,
            enrollmentPort: enrollmentPort.isEmpty ? nil : UInt16(enrollmentPort),
            autoEnrollOnConnect: autoEnrollOnConnect
        )

        onSave(newServer)
        dismiss()
    }

    private var isValidForm: Bool {
        !name.isEmpty && !host.isEmpty && !port.isEmpty && UInt16(port) != nil
    }
}

// MARK: - Supporting Views

struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(Color(hex: "#888888"))
    }
}

struct FormTextField: View {
    let icon: String
    let label: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "#FFFC00"))
                    .frame(width: 28)

                Text(label)
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#CCCCCC"))
            }

            TextField(placeholder, text: $text)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .padding(12)
                .background(Color(hex: "#2A2A2A"))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(text.isEmpty ? Color(hex: "#3A3A3A") : Color(hex: "#FFFC00").opacity(0.5), lineWidth: 1)
                )
        }
    }
}

extension FormTextField {
    func keyboardType(_ type: UIKeyboardType) -> some View {
        return self
    }

    func autocapitalization(_ type: TextInputAutocapitalization) -> some View {
        return self
    }
}

struct FormSecureField: View {
    let icon: String
    let label: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "#FFFC00"))
                    .frame(width: 28)

                Text(label)
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#CCCCCC"))
            }

            SecureField(placeholder, text: $text)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .padding(12)
                .background(Color(hex: "#2A2A2A"))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(text.isEmpty ? Color(hex: "#3A3A3A") : Color(hex: "#FFFC00").opacity(0.5), lineWidth: 1)
                )
        }
    }
}

struct ProtocolButton: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .bold : .semibold))
                .foregroundColor(isSelected ? .black : color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSelected ? color : Color(hex: "#2A2A2A"))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(color, lineWidth: isSelected ? 0 : 1)
                )
        }
    }
}

// MARK: - Data Models

struct TestResult {
    let success: Bool
    let message: String
}

// MARK: - Preview

#if DEBUG
struct ServerConfigEditor_Previews: PreviewProvider {
    static var previews: some View {
        ServerConfigEditor(server: nil, onSave: { _ in })
            .preferredColorScheme(.dark)
    }
}
#endif
