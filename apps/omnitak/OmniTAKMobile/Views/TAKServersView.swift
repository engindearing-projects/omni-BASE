//
//  TAKServersView.swift
//  OmniTAKMobile
//
//  TAK Server management view matching ATAK design
//

import SwiftUI
import Network

// MARK: - TAK Servers View (ATAK Style)

struct TAKServersView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var serverManager = ServerManager.shared
    @State private var showMenu = false
    @State private var showAddServer = false
    @State private var selectedServer: TAKServer?
    @State private var localIPAddress = "0.0.0.0"

    var body: some View {
        NavigationView {
            ZStack {
                // ATAK-style black background
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Cyan accent bar
                    Rectangle()
                        .fill(Color(hex: "#00BCD4"))
                        .frame(height: 2)

                    // IP Address header (ATAK style)
                    HStack {
                        Text("My Primary IP Address: \(localIPAddress)")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "#CCCCCC"))
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(hex: "#0A0A0A"))

                    // Server list
                    if serverManager.servers.isEmpty {
                        emptyState
                    } else {
                        serverList
                    }

                    Spacer()
                }
            }
            .navigationTitle("ATAK")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Settings/Network Preferences")
                                .font(.system(size: 14))
                        }
                        .foregroundColor(.white)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button(action: { /* Sort */ }) {
                            Image(systemName: "arrow.up.arrow.down")
                                .foregroundColor(.white)
                        }

                        Button(action: { showMenu.toggle() }) {
                            Image(systemName: "ellipsis.circle")
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .overlay(alignment: .topTrailing) {
                if showMenu {
                    serverMenu
                        .padding(.top, 100)
                        .padding(.trailing, 16)
                }
            }
        }
        .sheet(isPresented: $showAddServer) {
            QuickConnectView()
        }
        .sheet(item: $selectedServer) { server in
            ServerDetailView(server: server)
        }
        .onAppear {
            loadLocalIPAddress()
        }
    }

    // MARK: - Server List

    private var serverList: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(serverManager.servers) { server in
                    ServerRow(
                        server: server,
                        isConnected: serverManager.activeServer?.id == server.id,
                        onTap: { selectedServer = server },
                        onEdit: { selectedServer = server },
                        onDelete: { deleteServer(server) }
                    )

                    Divider()
                        .background(Color(hex: "#222222"))
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "server.rack")
                .font(.system(size: 60))
                .foregroundColor(Color(hex: "#666666"))

            Text("No TAK Servers")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)

            Text("Tap the menu to add your first server")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#999999"))

            Button(action: { showAddServer = true }) {
                Text("Add Server")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color(hex: "#00BCD4"))
                    .cornerRadius(8)
            }
            .padding(.top, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Server Menu (ATAK Style)

    private var serverMenu: some View {
        VStack(spacing: 0) {
            MenuButton(title: "Add", action: {
                showMenu = false
                showAddServer = true
            })

            Divider().background(Color(hex: "#444444"))

            MenuButton(title: "Remove All", action: {
                showMenu = false
                removeAllServers()
            })

            Divider().background(Color(hex: "#444444"))

            MenuButton(title: "Quick Connect", action: {
                showMenu = false
                showAddServer = true
            })

            Divider().background(Color(hex: "#444444"))

            MenuButton(title: "Data Package", action: {
                showMenu = false
                // TODO: Implement data package
            })
        }
        .background(Color(hex: "#2A2A2A"))
        .cornerRadius(4)
        .shadow(color: Color.black.opacity(0.5), radius: 8, x: 0, y: 4)
        .frame(width: 200)
        .onTapGesture {
            showMenu = false
        }
    }

    // MARK: - Helper Functions

    private func loadLocalIPAddress() {
        localIPAddress = getLocalIPAddress() ?? "0.0.0.0"
    }

    private func deleteServer(_ server: TAKServer) {
        serverManager.deleteServer(server)
    }

    private func removeAllServers() {
        serverManager.servers.forEach { server in
            serverManager.deleteServer(server)
        }
    }

    private func getLocalIPAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?

        guard getifaddrs(&ifaddr) == 0 else { return nil }
        guard let firstAddr = ifaddr else { return nil }

        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family

            if addrFamily == UInt8(AF_INET) {
                let name = String(cString: interface.ifa_name)
                if name == "en0" || name == "en1" {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                               &hostname, socklen_t(hostname.count),
                               nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostname)
                }
            }
        }

        freeifaddrs(ifaddr)
        return address
    }
}

// MARK: - Server Row (ATAK Style)

struct ServerRow: View {
    let server: TAKServer
    let isConnected: Bool
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Connection status indicator (ATAK style - green/red dot)
                Circle()
                    .fill(isConnected ? Color(hex: "#00FF00") : Color(hex: "#666666"))
                    .frame(width: 12, height: 12)

                // TAK server icon
                Image(systemName: "server.rack")
                    .font(.system(size: 20))
                    .foregroundColor(.white)

                // Server info
                VStack(alignment: .leading, spacing: 4) {
                    // Server name
                    Text("TAK 5.5")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)

                    // Connection details
                    Text("\(server.host):\(server.port):\(server.useTLS ? "ssl" : "tcp")")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#CCCCCC"))

                    // Version
                    Text("5.5.58-RELEASE")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#999999"))
                }

                Spacer()

                // Action buttons (ATAK style)
                HStack(spacing: 8) {
                    Button(action: onDelete) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color(hex: "#D32F2F"))
                            .cornerRadius(8)
                    }

                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color(hex: "#1976D2"))
                            .cornerRadius(8)
                    }

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(isConnected ? Color(hex: "#00BCD4") : Color(hex: "#333333"))
                }
            }
            .padding(16)
            .background(Color(hex: "#0A0A0A"))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Menu Button

struct MenuButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .background(Color(hex: "#2A2A2A"))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Server Detail View

struct ServerDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let server: TAKServer

    @State private var serverName: String
    @State private var serverHost: String
    @State private var serverPort: String
    @State private var useTLS: Bool

    init(server: TAKServer) {
        self.server = server
        _serverName = State(initialValue: server.name)
        _serverHost = State(initialValue: server.host)
        _serverPort = State(initialValue: String(server.port))
        _useTLS = State(initialValue: server.useTLS)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Server icon
                        Image(systemName: "server.rack")
                            .font(.system(size: 60))
                            .foregroundColor(Color(hex: "#00BCD4"))
                            .padding(.top, 20)

                        // Form fields
                        VStack(spacing: 16) {
                            FormField(label: "Server Name", text: $serverName, placeholder: "My TAK Server")
                            FormField(label: "Host", text: $serverHost, placeholder: "tak.example.com")
                            FormField(label: "Port", text: $serverPort, placeholder: "8089", keyboardType: .numberPad)

                            Toggle(isOn: $useTLS) {
                                HStack {
                                    Image(systemName: "lock.shield.fill")
                                        .foregroundColor(useTLS ? Color(hex: "#00FF00") : Color(hex: "#666666"))
                                    Text("Use TLS/SSL")
                                        .font(.system(size: 15))
                                        .foregroundColor(.white)
                                }
                            }
                            .tint(Color(hex: "#00BCD4"))
                            .padding(16)
                            .background(Color(hex: "#1A1A1A"))
                            .cornerRadius(10)
                        }

                        // Save button
                        Button(action: saveChanges) {
                            Text("Save Changes")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color(hex: "#00BCD4"))
                                .cornerRadius(12)
                        }
                        .padding(.top, 10)
                    }
                    .padding(20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }

    private func saveChanges() {
        let updatedServer = TAKServer(
            id: server.id,
            name: serverName,
            host: serverHost,
            port: UInt16(serverPort) ?? server.port,
            protocolType: useTLS ? "ssl" : "tcp",
            useTLS: useTLS,
            isDefault: server.isDefault,
            certificatePassword: server.certificatePassword
        )

        ServerManager.shared.updateServer(updatedServer)
        dismiss()
    }
}

// MARK: - Preview

#if DEBUG
struct TAKServersView_Previews: PreviewProvider {
    static var previews: some View {
        TAKServersView()
            .preferredColorScheme(.dark)
    }
}
#endif
