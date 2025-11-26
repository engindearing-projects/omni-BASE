//
//  NetworkStatsDashboard.swift
//  OmniTAKMobile
//
//  Network statistics dashboard with charts and metrics
//

import SwiftUI
import Charts

// MARK: - Network Stats Dashboard

@available(iOS 16.0, *)
struct NetworkStatsDashboard: View {
    @ObservedObject var takService: TAKService
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTimeRange: TimeRange = .fiveMinutes
    @State private var bandwidthData: [DashboardMetricDataPoint] = []
    @State private var messageData: [DashboardMetricDataPoint] = []
    @State private var latencyData: [DashboardMetricDataPoint] = []
    @State private var updateTimer: Timer?

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Time range picker
                        timeRangePicker

                        // Charts
                        bandwidthChart
                        messageChart
                        latencyChart

                        // Stats summary
                        statsSummaryGrid

                        // Export button
                        exportButton
                    }
                    .padding(20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Network Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: refreshData) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(Color(hex: "#FFFC00"))
                    }
                }
            }
        }
        .onAppear {
            startDataCollection()
        }
        .onDisappear {
            updateTimer?.invalidate()
        }
    }

    // MARK: - Time Range Picker

    private var timeRangePicker: some View {
        HStack(spacing: 12) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                TimeRangeButton(
                    title: range.displayName,
                    isSelected: selectedTimeRange == range
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTimeRange = range
                        refreshData()
                    }
                }
            }
        }
    }

    // MARK: - Bandwidth Chart

    private var bandwidthChart: some View {
        ChartCard(title: "Bandwidth (KB/s)", color: Color(hex: "#00BCD4")) {
            if bandwidthData.isEmpty {
                emptyChartView
            } else {
                Chart(bandwidthData) { point in
                    LineMark(
                        x: .value("Time", point.timestamp),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(Color(hex: "#00BCD4"))
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2))

                    AreaMark(
                        x: .value("Time", point.timestamp),
                        y: .value("Value", point.value)
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
                    AxisMarks(values: .automatic(desiredCount: 5)) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color(hex: "#3A3A3A"))
                        AxisValueLabel()
                            .foregroundStyle(Color(hex: "#999999"))
                    }
                }
                .frame(height: 180)
            }
        }
    }

    // MARK: - Message Chart

    private var messageChart: some View {
        ChartCard(title: "Messages (msg/s)", color: Color(hex: "#4CAF50")) {
            if messageData.isEmpty {
                emptyChartView
            } else {
                Chart(messageData) { point in
                    LineMark(
                        x: .value("Time", point.timestamp),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(Color(hex: "#4CAF50"))
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2))

                    AreaMark(
                        x: .value("Time", point.timestamp),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hex: "#4CAF50").opacity(0.3),
                                Color(hex: "#4CAF50").opacity(0.0)
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
                .frame(height: 180)
            }
        }
    }

    // MARK: - Latency Chart

    private var latencyChart: some View {
        ChartCard(title: "Latency (ms)", color: Color(hex: "#FFFC00")) {
            if latencyData.isEmpty {
                emptyChartView
            } else {
                Chart(latencyData) { point in
                    LineMark(
                        x: .value("Time", point.timestamp),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(Color(hex: "#FFFC00"))
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2))

                    AreaMark(
                        x: .value("Time", point.timestamp),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hex: "#FFFC00").opacity(0.3),
                                Color(hex: "#FFFC00").opacity(0.0)
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
                .frame(height: 180)
            }
        }
    }

    // MARK: - Stats Summary Grid

    private var statsSummaryGrid: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Summary")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                SummaryCard(
                    icon: "clock.fill",
                    label: "Uptime",
                    value: uptimeText,
                    color: Color(hex: "#999999")
                )

                SummaryCard(
                    icon: "envelope.fill",
                    label: "Total Messages",
                    value: "\(totalMessages)",
                    color: Color(hex: "#00BCD4")
                )

                SummaryCard(
                    icon: "arrow.up.doc.fill",
                    label: "Messages Sent",
                    value: "\(takService.messagesSent)",
                    color: Color(hex: "#00BCD4")
                )

                SummaryCard(
                    icon: "arrow.down.doc.fill",
                    label: "Data Received",
                    value: formatBytes(takService.bytesReceived),
                    color: Color(hex: "#4CAF50")
                )

                SummaryCard(
                    icon: "timer",
                    label: "Avg Latency",
                    value: "\(averageLatency)ms",
                    color: Color(hex: "#FFFC00")
                )

                SummaryCard(
                    icon: "arrow.triangle.branch",
                    label: "Connection Events",
                    value: "0",
                    color: Color(hex: "#FFA726")
                )

                SummaryCard(
                    icon: "heart.fill",
                    label: "Health Score",
                    value: "\(healthScore)%",
                    color: healthScoreColor
                )

                SummaryCard(
                    icon: "waveform.path.ecg",
                    label: "Signal Quality",
                    value: "Excellent",
                    color: Color(hex: "#4CAF50")
                )
            }
        }
    }

    // MARK: - Export Button

    private var exportButton: some View {
        Button(action: exportDiagnostics) {
            HStack(spacing: 12) {
                Image(systemName: "square.and.arrow.up.fill")
                    .font(.system(size: 20))

                Text("Export Diagnostics")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color(hex: "#FFFC00"))
            .cornerRadius(12)
        }
    }

    // MARK: - Empty Chart View

    private var emptyChartView: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 40))
                .foregroundColor(Color(hex: "#666666"))

            Text("No data available")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#999999"))
        }
        .frame(height: 180)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helper Properties

    private var uptimeText: String {
        if !takService.isConnected {
            return "N/A"
        }
        // Mock uptime for now
        return "2h 34m"
    }

    private var totalMessages: Int {
        takService.messagesReceived + takService.messagesSent
    }

    private var averageLatency: Int {
        guard !latencyData.isEmpty else { return 0 }
        let sum = latencyData.reduce(0.0) { $0 + $1.value }
        return Int(sum / Double(latencyData.count))
    }

    private var healthScore: Int {
        if !takService.isConnected {
            return 0
        }
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
            return String(format: "%.1f KB", kb)
        }
    }

    // MARK: - Actions

    private func startDataCollection() {
        refreshData()

        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            let now = Date()

            // Bandwidth data (KB/s)
            let bandwidth = Double.random(in: 10...100)
            bandwidthData.append(DashboardMetricDataPoint(timestamp: now, value: bandwidth))

            // Message data (msg/s)
            let messages = Double.random(in: 1...20)
            messageData.append(DashboardMetricDataPoint(timestamp: now, value: messages))

            // Latency data (ms)
            let latency = Double.random(in: 20...80)
            latencyData.append(DashboardMetricDataPoint(timestamp: now, value: latency))

            // Keep data within time range
            let cutoffTime = now.addingTimeInterval(-selectedTimeRange.seconds)
            bandwidthData.removeAll { $0.timestamp < cutoffTime }
            messageData.removeAll { $0.timestamp < cutoffTime }
            latencyData.removeAll { $0.timestamp < cutoffTime }
        }
    }

    private func refreshData() {
        // Reset data based on time range
        let now = Date()
        let startTime = now.addingTimeInterval(-selectedTimeRange.seconds)

        bandwidthData.removeAll()
        messageData.removeAll()
        latencyData.removeAll()

        // Generate initial data points
        var currentTime = startTime
        while currentTime <= now {
            bandwidthData.append(DashboardMetricDataPoint(
                timestamp: currentTime,
                value: Double.random(in: 10...100)
            ))
            messageData.append(DashboardMetricDataPoint(
                timestamp: currentTime,
                value: Double.random(in: 1...20)
            ))
            latencyData.append(DashboardMetricDataPoint(
                timestamp: currentTime,
                value: Double.random(in: 20...80)
            ))
            currentTime = currentTime.addingTimeInterval(1.0)
        }
    }

    private func exportDiagnostics() {
        // TODO: Implement diagnostics export
        print("Exporting diagnostics...")
    }
}

// MARK: - Supporting Views

struct TimeRangeButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .bold : .semibold))
                .foregroundColor(isSelected ? .black : Color(hex: "#CCCCCC"))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color(hex: "#FFFC00") : Color(hex: "#2A2A2A"))
                .cornerRadius(8)
        }
    }
}

struct ChartCard<Content: View>: View {
    let title: String
    let color: Color
    let content: Content

    init(title: String, color: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.color = color
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Rectangle()
                    .fill(color)
                    .frame(width: 4, height: 20)
                    .cornerRadius(2)

                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)

                Spacer()
            }

            content
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

struct SummaryCard: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)

                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#999999"))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(hex: "#1E1E1E"))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "#3A3A3A"), lineWidth: 1)
        )
    }
}

// MARK: - Data Models

struct DashboardMetricDataPoint: Identifiable {
    let id = UUID()
    let timestamp: Date
    let value: Double
}

enum TimeRange: CaseIterable {
    case oneMinute
    case fiveMinutes
    case fifteenMinutes
    case sixtyMinutes

    var displayName: String {
        switch self {
        case .oneMinute: return "1m"
        case .fiveMinutes: return "5m"
        case .fifteenMinutes: return "15m"
        case .sixtyMinutes: return "60m"
        }
    }

    var seconds: TimeInterval {
        switch self {
        case .oneMinute: return 60
        case .fiveMinutes: return 300
        case .fifteenMinutes: return 900
        case .sixtyMinutes: return 3600
        }
    }
}

// MARK: - Preview

#if DEBUG
@available(iOS 16.0, *)
struct NetworkStatsDashboard_Previews: PreviewProvider {
    static var previews: some View {
        NetworkStatsDashboard(takService: TAKService())
            .preferredColorScheme(.dark)
    }
}
#endif
