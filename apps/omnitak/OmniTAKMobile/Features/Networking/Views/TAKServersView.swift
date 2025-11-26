//
//  TAKServersView.swift
//  OmniTAKMobile
//
//  TAK Server management screen with ATAK-style design
//

import SwiftUI

// MARK: - TAK Servers View

struct TAKServersView: View {
    @StateObject private var serverManager = ServerManager.shared
    @ObservedObject var takService: TAKService
    @Environment(\.dismiss) private var dismiss

    @State private var showAddServer = false
    @State private var editingServer: TAKServer?
    @State private var isRefreshing = false

    var body: some View {
        NavigationView {
            ZStack {
                // Dark background
                Color.black.ignoresSafeArea()

                ZStack(alignment: .bottomTrailing) {
                    if serverManager.servers.isEmpty {
                        emptyStateView
                    } else {
                        ScrollView {
                            VStack(spacing: 0) {
                                // Connected section
                                if !connectedServers.isEmpty {
                                    serverSection(title: "CONNECTED", servers: connectedServers, statusColor: Color(hex: "#4CAF50"))
                                }

                                // Available section
                                if !availableServers.isEmpty {
                                    serverSection(title: "AVAILABLE", servers: availableServers, statusColor: Color(hex: "#999999"))
                                }

                                // Offline section
                                if !offlineServers.isEmpty {
                                    serverSection(title: "OFFLINE", servers: offlineServers, statusColor: Color(hex: "#666666"))
                                }
                            }
                            .padding(.bottom, 80)
                        }
                        .refreshable {
                            await refreshServers()
                        }
                    }

                    // Floating add button
                    Button(action: { showAddServer = true }) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "#FFFC00"))
                                .frame(width: 60, height: 60)
                                .shadow(color: Color(hex: "#FFFC00").opacity(0.3), radius: 8, x: 0, y: 4)

                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.black)
                        }
                    }
                    .padding(24)
                    .accessibilityLabel("Add Server")
                }
            }
            .navigationTitle("Servers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(Color(hex: "#FFFC00"))
                    }
                    .accessibilityLabel("Settings")
                }
            }
        }
        .sheet(isPresented: $showAddServer) {
            ServerConfigEditor(server: nil, onSave: { newServer in
                serverManager.addServer(newServer)
                showAddServer = false
            })
        }
        .sheet(item: $editingServer) { server in
            ServerConfigEditor(server: server, onSave: { updatedServer in
                serverManager.updateServer(updatedServer)
                editingServer = nil
            })
        }
    }

    // MARK: - Server Sections

    private func serverSection(title: String, servers: [TAKServer], statusColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color(hex: "#888888"))
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 8)

            // Server cards
            ForEach(servers) { server in
                ServerCard(
                    server: server,
                    isActive: serverManager.activeServer?.id == server.id,
                    isConnected: takService.isConnected && serverManager.activeServer?.id == server.id,
                    onTap: {
                        serverManager.setActiveServer(server)
                    },
                    onEdit: {
                        editingServer = server
                    },
                    onDelete: {
                        serverManager.deleteServer(server)
                    }
                )
            }
        }
    }

    // MARK: - Server Categories

    private var connectedServers: [TAKServer] {
        guard let activeServer = serverManager.activeServer, takService.isConnected else {
            return []
        }
        return [activeServer]
    }

    private var availableServers: [TAKServer] {
        serverManager.servers.filter { server in
            if takService.isConnected && serverManager.activeServer?.id == server.id {
                return false
            }
            return true
        }
    }

    private var offlineServers: [TAKServer] {
        // For now, all non-connected servers are considered available
        // In future, implement ping/health check to determine offline status
        return []
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "network.slash")
                .font(.system(size: 80))
                .foregroundColor(Color(hex: "#666666"))

            Text("No Servers")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Color(hex: "#CCCCCC"))

            Text("Tap the + button to add your first TAK server")
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "#999999"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    // MARK: - Actions

    private func refreshServers() async {
        isRefreshing = true
        // Simulate discovery delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        isRefreshing = false
    }
}

// MARK: - Server Card

struct ServerCard: View {
    let server: TAKServer
    let isActive: Bool
    let isConnected: Bool
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var pulseAnimation = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // LED Status indicator
                ZStack {
                    if isConnected {
                        Circle()
                            .fill(statusColor.opacity(0.3))
                            .frame(width: 28, height: 28)
                            .scaleEffect(pulseAnimation ? 1.4 : 1.0)
                            .opacity(pulseAnimation ? 0.0 : 1.0)
                    }

                    Circle()
                        .fill(statusColor)
                        .frame(width: 12, height: 12)
                        .shadow(color: statusColor, radius: 4)
                }
                .frame(width: 28, height: 28)

                // Server info
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(server.name)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)

                        // Protocol badge
                        Text(protocolText)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(protocolColor)
                            .cornerRadius(4)

                        // Certificate indicator
                        if server.useTLS {
                            Image(systemName: server.certificateName != nil ? "lock.shield.fill" : "lock.fill")
                                .font(.system(size: 12))
                                .foregroundColor(server.certificateName != nil ? Color(hex: "#4CAF50") : Color(hex: "#FFA726"))
                        }
                    }

                    HStack(spacing: 4) {
                        Text("\(server.host):\(server.port)")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "#CCCCCC"))

                        if isActive {
                            Text("• ACTIVE")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color(hex: "#FFFC00"))
                        }
                    }
                }

                Spacer()

                // Signal strength (mock for now)
                if isConnected {
                    NetworkSignalStrengthIndicator(strength: 5)
                }
            }
            .padding(16)
            .background(isActive ? Color(hex: "#2A2A2A") : Color(hex: "#1E1E1E"))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isActive ? Color(hex: "#FFFC00") : Color(hex: "#3A3A3A"), lineWidth: isActive ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Button(action: onEdit) {
                Label("Edit", systemImage: "pencil")
            }

            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }

            Button(action: onEdit) {
                Label("Edit", systemImage: "pencil")
            }
            .tint(Color(hex: "#00BCD4"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .onAppear {
            if isConnected {
                startPulseAnimation()
            }
        }
        .onChange(of: isConnected) { newValue in
            if newValue {
                startPulseAnimation()
            }
        }
    }

    private var statusColor: Color {
        if isConnected {
            return Color(hex: "#4CAF50") // Green
        } else if isActive {
            return Color(hex: "#FFA726") // Yellow/Orange
        } else {
            return Color(hex: "#666666") // Gray
        }
    }

    private var protocolText: String {
        if server.useTLS {
            return "TLS"
        } else {
            return server.protocolType.uppercased()
        }
    }

    private var protocolColor: Color {
        if server.useTLS {
            return Color(hex: "#4CAF50")
        } else if server.protocolType.lowercased() == "tcp" {
            return Color(hex: "#00BCD4")
        } else {
            return Color(hex: "#999999")
        }
    }

    private func startPulseAnimation() {
        withAnimation(Animation.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
            pulseAnimation = true
        }
    }
}

// MARK: - Signal Strength Indicator

struct NetworkSignalStrengthIndicator: View {
    let strength: Int // 0-5

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(index < strength ? Color(hex: "#4CAF50") : Color(hex: "#3A3A3A"))
                    .frame(width: 3, height: CGFloat(8 + index * 3))
            }
        }
        .accessibilityLabel("Signal strength: \(strength) out of 5")
    }
}

// MARK: - Preview

#if DEBUG
struct TAKServersView_Previews: PreviewProvider {
    static var previews: some View {
        TAKServersView(takService: TAKService())
            .preferredColorScheme(.dark)
    }
}
#endif
