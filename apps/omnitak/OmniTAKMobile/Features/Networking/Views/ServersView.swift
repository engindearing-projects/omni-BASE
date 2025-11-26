//
//  ServersView.swift
//  OmniTAKMobile
//
//  Unified server management view - ATAK-inspired but simplified
//  One screen for: connection status, server list, add server
//

import SwiftUI

// MARK: - Servers View (Main Entry Point)

struct ServersView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var serverManager = ServerManager.shared
    @ObservedObject private var takService = TAKService.shared

    @State private var showAddServer = false
    @State private var selectedAddMethod: AddServerMethod?

    enum AddServerMethod: String, Identifiable {
        case signIn = "signIn"
        case qrCode = "qrCode"
        case dataPackage = "dataPackage"

        var id: String { rawValue }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Connection Status Card (prominent)
                        connectionStatusCard

                        // Quick Actions (when connected)
                        if takService.isConnected {
                            quickActionsSection
                        }

                        // Server List
                        if !serverManager.servers.isEmpty {
                            serverListSection
                        }

                        // Add Server Section
                        addServerSection
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Servers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color(hex: "#FFFC00"))
                }
            }
        }
        .sheet(item: $selectedAddMethod) { method in
            switch method {
            case .signIn:
                SimpleEnrollView()
            case .qrCode:
                CertificateEnrollmentView()
            case .dataPackage:
                ServerDataPackageImportView()
            }
        }
    }

    // MARK: - Connection Status Card

    private var connectionStatusCard: some View {
        VStack(spacing: 16) {
            // Status indicator
            HStack(spacing: 12) {
                // Green/Red status circle (ATAK style)
                Circle()
                    .fill(takService.isConnected ? Color(hex: "#00FF00") : Color(hex: "#FF4444"))
                    .frame(width: 16, height: 16)
                    .shadow(color: takService.isConnected ? Color(hex: "#00FF00").opacity(0.5) : Color(hex: "#FF4444").opacity(0.5), radius: 4)

                VStack(alignment: .leading, spacing: 2) {
                    Text(takService.isConnected ? "CONNECTED" : "DISCONNECTED")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(takService.isConnected ? Color(hex: "#00FF00") : Color(hex: "#FF4444"))

                    if let activeServer = serverManager.activeServer {
                        Text(activeServer.host)
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "#AAAAAA"))
                    } else {
                        Text("No server configured")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "#666666"))
                    }
                }

                Spacer()

                // Connect/Disconnect button
                if serverManager.activeServer != nil {
                    Button(action: toggleConnection) {
                        Text(takService.isConnected ? "Disconnect" : "Connect")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(takService.isConnected ? Color(hex: "#FF6B6B") : Color(hex: "#00FF00"))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(takService.isConnected ? Color(hex: "#FF6B6B") : Color(hex: "#00FF00"), lineWidth: 1)
                            )
                    }
                }
            }

            // Server info (when connected)
            if takService.isConnected, let server = serverManager.activeServer {
                HStack(spacing: 24) {
                    ServerInfoItem(label: "Protocol", value: server.protocolType.uppercased())
                    ServerInfoItem(label: "Port", value: "\(server.port)")
                    ServerInfoItem(label: "TLS", value: server.useTLS ? "Yes" : "No")
                }
            }
        }
        .padding(16)
        .background(Color(white: 0.08))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(takService.isConnected ? Color(hex: "#00FF00").opacity(0.3) : Color(hex: "#333333"), lineWidth: 1)
        )
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        HStack(spacing: 12) {
            ServerQuickActionButton(
                icon: "arrow.triangle.2.circlepath",
                label: "Reconnect",
                action: { reconnect() }
            )

            ServerQuickActionButton(
                icon: "location.fill",
                label: "Send Position",
                action: { sendPosition() }
            )

            ServerQuickActionButton(
                icon: "info.circle",
                label: "Server Info",
                action: { /* TODO */ }
            )
        }
    }

    // MARK: - Server List

    private var serverListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CONFIGURED SERVERS")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(hex: "#666666"))
                .padding(.horizontal, 4)

            VStack(spacing: 8) {
                ForEach(serverManager.servers) { server in
                    ServerRow(
                        server: server,
                        isActive: server.id == serverManager.activeServer?.id,
                        isConnected: takService.isConnected && server.id == serverManager.activeServer?.id,
                        onSelect: { selectServer(server) },
                        onDelete: { deleteServer(server) },
                        onToggleEnabled: { toggleServerEnabled(server) }
                    )
                }
            }
        }
    }

    // MARK: - Add Server Section

    private var addServerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ADD SERVER")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(hex: "#666666"))
                .padding(.horizontal, 4)

            VStack(spacing: 10) {
                // Primary: Sign In
                AddServerOption(
                    icon: "person.badge.key.fill",
                    title: "Sign In",
                    description: "Enter server credentials",
                    isPrimary: true,
                    action: { selectedAddMethod = .signIn }
                )

                HStack(spacing: 10) {
                    // QR Code
                    AddServerOption(
                        icon: "qrcode.viewfinder",
                        title: "Scan QR",
                        description: "Quick setup",
                        isPrimary: false,
                        action: { selectedAddMethod = .qrCode }
                    )

                    // Data Package
                    AddServerOption(
                        icon: "doc.zipper",
                        title: "Import",
                        description: "Data package",
                        isPrimary: false,
                        action: { selectedAddMethod = .dataPackage }
                    )
                }
            }
        }
    }

    // MARK: - Actions

    private func toggleConnection() {
        if takService.isConnected {
            takService.disconnect()
        } else if let server = serverManager.activeServer {
            connectToServer(server)
        }
    }

    private func reconnect() {
        takService.disconnect()
        if let server = serverManager.activeServer {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.connectToServer(server)
            }
        }
    }

    private func sendPosition() {
        // Trigger position broadcast
        NotificationCenter.default.post(name: Notification.Name("SendPositionNow"), object: nil)
    }

    private func selectServer(_ server: TAKServer) {
        serverManager.setActiveServer(server)
        if !takService.isConnected {
            connectToServer(server)
        }
    }

    private func deleteServer(_ server: TAKServer) {
        serverManager.deleteServer(server)
    }

    private func toggleServerEnabled(_ server: TAKServer) {
        serverManager.toggleServerEnabled(server)

        // If disabling the active connected server, disconnect
        if !server.enabled && takService.isConnected && server.id == serverManager.activeServer?.id {
            takService.disconnect()
        }
    }

    private func connectToServer(_ server: TAKServer) {
        takService.connect(
            host: server.host,
            port: server.port,
            protocolType: server.protocolType,
            useTLS: server.useTLS,
            certificateName: server.certificateName,
            certificatePassword: server.certificatePassword
        )
    }
}

// MARK: - Server Info Item

struct ServerInfoItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(Color(hex: "#666666"))

            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(hex: "#CCCCCC"))
        }
    }
}

// MARK: - Server Quick Action Button

struct ServerQuickActionButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: "#FFFC00"))

                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(hex: "#CCCCCC"))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(white: 0.08))
            .cornerRadius(10)
        }
    }
}

// MARK: - Server Row

struct ServerRow: View {
    let server: TAKServer
    let isActive: Bool
    let isConnected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    let onToggleEnabled: () -> Void

    @State private var showDeleteConfirm = false

    var body: some View {
        HStack(spacing: 12) {
            // Enable/Disable checkbox (ATAK style)
            Button(action: onToggleEnabled) {
                Image(systemName: server.enabled ? "checkmark.square.fill" : "square")
                    .font(.system(size: 22))
                    .foregroundColor(server.enabled ? Color(hex: "#00FF00") : Color(hex: "#666666"))
            }
            .buttonStyle(PlainButtonStyle())

            // Main server button
            Button(action: onSelect) {
                HStack(spacing: 10) {
                    // Status indicator
                    Circle()
                        .fill(isConnected ? Color(hex: "#00FF00") : (isActive && server.enabled ? Color(hex: "#FFFC00") : Color(hex: "#444444")))
                        .frame(width: 10, height: 10)

                    // Server info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(server.name)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(server.enabled ? .white : Color(hex: "#666666"))

                        Text("\(server.host):\(server.port)")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "#888888"))
                    }

                    Spacer()

                    // Active badge
                    if isActive && server.enabled {
                        Text("ACTIVE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(hex: "#FFFC00"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(hex: "#FFFC00").opacity(0.15))
                            .cornerRadius(4)
                    }

                    // Disabled badge
                    if !server.enabled {
                        Text("DISABLED")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(hex: "#666666"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(hex: "#333333"))
                            .cornerRadius(4)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())

            // Delete button
            Button(action: { showDeleteConfirm = true }) {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#666666"))
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(12)
        .background(Color(white: isActive && server.enabled ? 0.1 : 0.06))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isActive && server.enabled ? Color(hex: "#FFFC00").opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .opacity(server.enabled ? 1.0 : 0.6)
        .confirmationDialog("Delete Server", isPresented: $showDeleteConfirm) {
            Button("Delete \(server.name)", role: .destructive) {
                onDelete()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

// MARK: - Add Server Option

struct AddServerOption: View {
    let icon: String
    let title: String
    let description: String
    let isPrimary: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: isPrimary ? 24 : 20))
                    .foregroundColor(Color(hex: "#FFFC00"))
                    .frame(width: isPrimary ? 44 : 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: isPrimary ? 16 : 14, weight: .semibold))
                        .foregroundColor(.white)

                    Text(description)
                        .font(.system(size: isPrimary ? 13 : 11))
                        .foregroundColor(Color(hex: "#888888"))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#444444"))
            }
            .padding(isPrimary ? 16 : 12)
            .background(Color(white: 0.08))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isPrimary ? Color(hex: "#FFFC00").opacity(0.3) : Color(white: 0.15), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Server Data Package Import View (Placeholder)

struct ServerDataPackageImportView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 24) {
                    Image(systemName: "doc.zipper")
                        .font(.system(size: 64))
                        .foregroundColor(Color(hex: "#FFFC00"))

                    Text("Import Data Package")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)

                    Text("Select a .zip data package containing your server configuration and certificates.")
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: "#AAAAAA"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    Button(action: { /* TODO: File picker */ }) {
                        HStack {
                            Image(systemName: "folder")
                            Text("Choose File")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(Color(hex: "#FFFC00"))
                        .cornerRadius(10)
                    }
                }
            }
            .navigationTitle("Import")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color(hex: "#FFFC00"))
                }
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct ServersView_Previews: PreviewProvider {
    static var previews: some View {
        ServersView()
            .preferredColorScheme(.dark)
    }
}
#endif
