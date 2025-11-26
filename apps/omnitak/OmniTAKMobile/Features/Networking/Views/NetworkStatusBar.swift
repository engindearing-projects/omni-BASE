//
//  NetworkStatusBar.swift
//  OmniTAKMobile
//
//  Compact network status bar with ATAK-style design
//

import SwiftUI

// MARK: - Network Status Bar

@available(iOS 16.0, *)
struct NetworkStatusBar: View {
    @ObservedObject var takService: TAKService
    @StateObject private var serverManager = ServerManager.shared

    @State private var pulseAnimation = false
    @State private var messageRate: Double = 0.0

    // Timer for message rate calculation
    @State private var lastMessageCount = 0
    @State private var updateTimer: Timer?

    // Cached connection state to prevent flickering
    @State private var isConnected: Bool = false
    @State private var displayStatus: String = "Not Connected"

    var body: some View {
        HStack(spacing: 12) {
                // LED with pulse animation
                ZStack {
                    if isConnected {
                        Circle()
                            .fill(statusColor.opacity(0.3))
                            .frame(width: 24, height: 24)
                            .scaleEffect(pulseAnimation ? 1.4 : 1.0)
                            .opacity(pulseAnimation ? 0.0 : 1.0)
                    }

                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                        .shadow(color: statusColor, radius: 3)
                }
                .frame(width: 24, height: 24)

                // Server name or status
                VStack(alignment: .leading, spacing: 2) {
                    if let server = serverManager.activeServer, isConnected {
                        Text(server.name)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    } else {
                        Text(displayStatus)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(hex: "#CCCCCC"))
                    }
                }

                Spacer()

                // Signal strength
                if isConnected {
                    SignalStrengthIndicator(rssi: 5)
                }

                // Message rate
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "#00BCD4"))

                    Text("\(Int(messageRate)) msg/s")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .monospacedDigit()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(hex: "#1E1E1E"))
                .cornerRadius(8)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "#2A2A2A"),
                        Color(hex: "#1E1E1E")
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color(hex: "#3A3A3A")),
                alignment: .bottom
            )
        .frame(height: 44)
        .onAppear {
            // Initialize cached state
            isConnected = takService.isConnected
            updateDisplayStatus(from: takService.connectionState)

            if isConnected {
                startPulseAnimation()
                startMessageRateTimer()
            }
        }
        .onReceive(takService.$connectionState) { newState in
            // Only update if connected state actually changed to prevent flickering
            let wasConnected = isConnected
            isConnected = newState.isConnected

            // Update display status (simplified to reduce flickering)
            updateDisplayStatus(from: newState)

            // Handle animation and timer based on connection state change
            if isConnected && !wasConnected {
                startPulseAnimation()
                startMessageRateTimer()
            } else if !isConnected && wasConnected {
                stopMessageRateTimer()
            }
        }
        .onDisappear {
            stopMessageRateTimer()
        }
        .accessibilityLabel(accessibilityText)
    }

    private var statusColor: Color {
        if isConnected {
            return Color(hex: "#4CAF50")
        } else {
            return Color(hex: "#FF5252")
        }
    }

    private var accessibilityText: String {
        if isConnected, let server = serverManager.activeServer {
            return "Connected to \(server.name), \(Int(messageRate)) messages per second"
        } else {
            return displayStatus
        }
    }

    private func updateDisplayStatus(from state: ConnectionStateSnapshot) {
        // Simplify status text to prevent rapid flickering during reconnection
        if state.isConnected {
            displayStatus = "Connected"
        } else if state.reconnectionState.isReconnecting {
            // Just show "Reconnecting..." without attempt numbers to reduce flickering
            displayStatus = "Reconnecting..."
        } else {
            displayStatus = "Not Connected"
        }
    }

    private func startPulseAnimation() {
        withAnimation(Animation.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
            pulseAnimation = true
        }
    }

    private func startMessageRateTimer() {
        // Only start if not already running
        guard updateTimer == nil else { return }

        // Increased interval from 1.0s to 2.0s to reduce update frequency
        updateTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            let currentCount = takService.messagesReceived + takService.messagesSent
            // Adjusted for 2s interval
            messageRate = Double(currentCount - lastMessageCount) / 2.0
            lastMessageCount = currentCount
        }
    }

    private func stopMessageRateTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
        messageRate = 0.0
    }
}

// MARK: - Preview

#if DEBUG
@available(iOS 16.0, *)
struct NetworkStatusBar_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 0) {
            NetworkStatusBar(takService: TAKService())

            Spacer()
        }
        .background(Color.black)
        .preferredColorScheme(.dark)
    }
}
#endif
