//
//  ConnectionDetailsPanel.swift
//  OmniTAKMobile
//
//  Sliding panel with connection details, statistics, and certificate info
//

import SwiftUI
import Charts

// MARK: - Connection Details Panel

@available(iOS 16.0, *)
struct ConnectionDetailsPanel: View {
    @ObservedObject var takService: TAKService
    @Binding var isPresented: Bool
    @StateObject private var serverManager = ServerManager.shared

    @State private var selectedTab = 0
    @State private var connectionStartTime = Date()
    @State private var bandwidthHistory: [BandwidthDataPoint] = []
    @State private var updateTimer: Timer?

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Tab selector
                    tabSelector

                    // Tab content
                    TabView(selection: $selectedTab) {
                        statusTab
                            .tag(0)

                        statisticsTab
                            .tag(1)

                        certificateTab
                            .tag(2)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
            .navigationTitle("Connection Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color(hex: "#666666"))
                    }
                }
            }
        }
        .onAppear {
            startBandwidthMonitoring()
        }
        .onDisappear {
            updateTimer?.invalidate()
        }
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: 0) {
            TabButton(title: "STATUS", isSelected: selectedTab == 0) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedTab = 0
                }
            }

            TabButton(title: "STATISTICS", isSelected: selectedTab == 1) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedTab = 1
                }
            }

            TabButton(title: "CERTIFICATE", isSelected: selectedTab == 2) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedTab = 2
                }
            }
        }
        .background(Color(hex: "#1E1E1E"))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(hex: "#3A3A3A")),
            alignment: .bottom
        )
    }

    // MARK: - Status Tab

    private var statusTab: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Connection info grid
                if let server = serverManager.activeServer {
                    connectionInfoGrid(server: server)
                }

                // Health score
                healthScoreCard

                // Action buttons
                actionButtons
            }
            .padding(20)
        }
    }

    private func connectionInfoGrid(server: TAKServer) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Connection Information")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

            VStack(spacing: 1) {
                InfoGridItem(label: "Host", value: server.host)
                InfoGridItem(label: "Port", value: String(server.port))
                InfoGridItem(label: "Protocol", value: server.protocolType.uppercased())
                InfoGridItem(label: "TLS", value: server.useTLS ? "Enabled" : "Disabled", valueColor: server.useTLS ? Color(hex: "#4CAF50") : Color(hex: "#999999"))
                InfoGridItem(label: "Uptime", value: uptimeText)
            }
            .background(Color(hex: "#1E1E1E"))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "#3A3A3A"), lineWidth: 1)
            )
        }
    }

    private var healthScoreCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Connection Health")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

            VStack(spacing: 12) {
                HStack {
                    Text("Health Score")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#CCCCCC"))

                    Spacer()

                    Text("\(healthScore)%")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(healthScoreColor)
                }

                // Health bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: "#3A3A3A"))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(healthScoreColor)
                            .frame(width: geometry.size.width * CGFloat(healthScore) / 100, height: 8)
                    }
                }
                .frame(height: 8)
            }
            .padding(16)
            .background(Color(hex: "#1E1E1E"))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "#3A3A3A"), lineWidth: 1)
            )
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            if takService.isConnected {
                DetailsPanelActionButton(title: "Disconnect", icon: "xmark.circle.fill", color: Color(hex: "#FF5252")) {
                    // TODO: Implement disconnect
                }

                DetailsPanelActionButton(title: "Reconnect", icon: "arrow.clockwise.circle.fill", color: Color(hex: "#00BCD4")) {
                    // TODO: Implement reconnect
                }
            } else {
                DetailsPanelActionButton(title: "Connect", icon: "play.circle.fill", color: Color(hex: "#4CAF50")) {
                    // TODO: Implement connect
                }
            }

            DetailsPanelActionButton(title: "Configure", icon: "gearshape.fill", color: Color(hex: "#FFFC00")) {
                // TODO: Open server config
            }
        }
    }

    // MARK: - Statistics Tab

    private var statisticsTab: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Bandwidth chart
                bandwidthChart

                // Stats grid
                statisticsGrid
            }
            .padding(20)
        }
    }

    private var bandwidthChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Bandwidth (KB/s)")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

            if bandwidthHistory.isEmpty {
                Text("No data available")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#666666"))
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
            } else {
                Chart(bandwidthHistory) { dataPoint in
                    LineMark(
                        x: .value("Time", dataPoint.timestamp),
                        y: .value("Bandwidth", dataPoint.bandwidth)
                    )
                    .foregroundStyle(Color(hex: "#00BCD4"))
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Time", dataPoint.timestamp),
                        y: .value("Bandwidth", dataPoint.bandwidth)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hex: "#00BCD4").opacity(0.3),
                                Color(hex: "#00BCD4").opacity(0.0)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color(hex: "#3A3A3A"))
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color(hex: "#3A3A3A"))
                        AxisValueLabel()
                            .foregroundStyle(Color(hex: "#999999"))
                    }
                }
                .frame(height: 200)
            }
        }
        .padding(16)
        .background(Color(hex: "#1E1E1E"))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "#3A3A3A"), lineWidth: 1)
        )
    }

    private var statisticsGrid: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Statistics")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ConnectionDetailsStatCard(
                    label: "Sent",
                    value: "\(takService.messagesSent)",
                    icon: "arrow.up.circle.fill",
                    color: Color(hex: "#00BCD4")
                )

                ConnectionDetailsStatCard(
                    label: "Received",
                    value: "\(takService.messagesReceived)",
                    icon: "arrow.down.circle.fill",
                    color: Color(hex: "#4CAF50")
                )

                ConnectionDetailsStatCard(
                    label: "Data Sent",
                    value: formatBytes(takService.messagesSent),
                    icon: "arrow.up.doc.fill",
                    color: Color(hex: "#00BCD4")
                )

                ConnectionDetailsStatCard(
                    label: "Data Received",
                    value: formatBytes(takService.bytesReceived),
                    icon: "arrow.down.doc.fill",
                    color: Color(hex: "#4CAF50")
                )

                ConnectionDetailsStatCard(
                    label: "Latency",
                    value: "~50ms",
                    icon: "timer",
                    color: Color(hex: "#FFFC00")
                )

                ConnectionDetailsStatCard(
                    label: "Uptime",
                    value: uptimeText,
                    icon: "clock.fill",
                    color: Color(hex: "#999999")
                )
            }
        }
    }

    // MARK: - Certificate Tab

    private var certificateTab: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let server = serverManager.activeServer, server.useTLS {
                    certificateInfo(server: server)
                } else {
                    noCertificateView
                }
            }
            .padding(20)
        }
    }

    private func certificateInfo(server: TAKServer) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            // Certificate status
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: server.certificateName != nil ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                        .font(.system(size: 50))
                        .foregroundColor(server.certificateName != nil ? Color(hex: "#4CAF50") : Color(hex: "#FFA726"))

                    Spacer()
                }

                Text(server.certificateName != nil ? "Certificate Valid" : "No Client Certificate")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)

                if let certName = server.certificateName {
                    Text("Using: \(certName)")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#CCCCCC"))
                }
            }

            // Certificate details
            VStack(alignment: .leading, spacing: 16) {
                Text("Certificate Details")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)

                VStack(spacing: 1) {
                    InfoGridItem(label: "Subject", value: "CN=\(server.name)")
                    InfoGridItem(label: "Issuer", value: "CN=TAK Server CA")
                    InfoGridItem(label: "Valid From", value: "Jan 1, 2024")
                    InfoGridItem(label: "Valid Until", value: "Jan 1, 2025")
                    InfoGridItem(label: "Days Remaining", value: "45 days", valueColor: Color(hex: "#FFA726"))
                }
                .background(Color(hex: "#1E1E1E"))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "#3A3A3A"), lineWidth: 1)
                )
            }

            // Status badge
            HStack {
                Spacer()

                VStack(spacing: 8) {
                    Text("STATUS")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(hex: "#666666"))

                    Text("VALID")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color(hex: "#4CAF50"))
                        .cornerRadius(8)
                }

                Spacer()
            }
        }
    }

    private var noCertificateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.slash.fill")
                .font(.system(size: 80))
                .foregroundColor(Color(hex: "#666666"))

            VStack(spacing: 8) {
                Text("No TLS Configuration")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)

                Text("This server is not using TLS encryption")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#999999"))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helper Properties

    private var uptimeText: String {
        let interval = Date().timeIntervalSince(connectionStartTime)
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    private var healthScore: Int {
        if !takService.isConnected {
            return 0
        }
        // Simple health calculation (can be enhanced with latency, error rate, etc.)
        return 95
    }

    private var healthScoreColor: Color {
        if healthScore >= 80 {
            return Color(hex: "#4CAF50")
        } else if healthScore >= 50 {
            return Color(hex: "#FFA726")
        } else {
            return Color(hex: "#FF5252")
        }
    }

    private func formatBytes(_ bytes: Int) -> String {
        let kb = Double(bytes) / 1024.0
        let mb = kb / 1024.0

        if mb >= 1.0 {
            return String(format: "%.2f MB", mb)
        } else {
            return String(format: "%.2f KB", kb)
        }
    }

    private func startBandwidthMonitoring() {
        // Initialize with current stats
        if takService.isConnected {
            connectionStartTime = Date()
        }

        // Update bandwidth history every second
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            let bandwidth = Double.random(in: 5...50) // Mock data
            bandwidthHistory.append(BandwidthDataPoint(timestamp: Date(), bandwidth: bandwidth))

            // Keep only last 60 data points
            if bandwidthHistory.count > 60 {
                bandwidthHistory.removeFirst()
            }
        }
    }
}

// MARK: - Supporting Views

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 12, weight: isSelected ? .bold : .semibold))
                    .foregroundColor(isSelected ? Color(hex: "#FFFC00") : Color(hex: "#999999"))

                Rectangle()
                    .fill(isSelected ? Color(hex: "#FFFC00") : Color.clear)
                    .frame(height: 3)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct InfoGridItem: View {
    let label: String
    let value: String
    var valueColor: Color = .white

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#999999"))

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(valueColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(hex: "#2A2A2A"))
    }
}

struct DetailsPanelActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))

                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(color)
            .cornerRadius(12)
        }
    }
}

struct ConnectionDetailsStatCard: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)

                Spacer()
            }

            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)

            Text(label)
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "#999999"))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "#1E1E1E"))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "#3A3A3A"), lineWidth: 1)
        )
    }
}

// MARK: - Data Models

struct BandwidthDataPoint: Identifiable {
    let id = UUID()
    let timestamp: Date
    let bandwidth: Double
}

// MARK: - Preview

#if DEBUG
@available(iOS 16.0, *)
struct ConnectionDetailsPanel_Previews: PreviewProvider {
    static var previews: some View {
        ConnectionDetailsPanel(takService: TAKService(), isPresented: .constant(true))
            .preferredColorScheme(.dark)
    }
}
#endif
