//
//  VerticalQuickActionMenu.swift
//  OmniTAKMobile
//
//  ATAK-style horizontal quick action menu with semi-transparent circular buttons
//  Positioned in top-right area
//

import SwiftUI
import CoreLocation

struct VerticalQuickActionMenu: View {
    // Map state bindings
    @Binding var showMeasurement: Bool
    @Binding var showDrawingPanel: Bool
    @Binding var showLayersPanel: Bool
    @Binding var showEmergencySOS: Bool
    @Binding var showToolsMenu: Bool
    @Binding var isCursorModeActive: Bool

    // Location for zoom action
    let userLocation: CLLocationCoordinate2D?
    let onZoomToSelf: () -> Void
    let onDropPoint: () -> Void

    @State private var isVisible = true

    var body: some View {
        HStack(spacing: 6) {
            // Zoom to Self
            QuickActionCircularButton(
                icon: "location.fill",
                isActive: false,
                color: .white,
                action: {
                    onZoomToSelf()
                }
            )
            .accessibilityLabel("Zoom to my location")

            // Drop Point
            QuickActionCircularButton(
                icon: "mappin.circle.fill",
                isActive: isCursorModeActive,
                color: .white,
                action: {
                    onDropPoint()
                }
            )
            .accessibilityLabel("Drop waypoint")

            // Measure Tool
            QuickActionCircularButton(
                icon: "ruler",
                isActive: showMeasurement,
                color: .white,
                action: {
                    showMeasurement.toggle()
                }
            )
            .accessibilityLabel("Measurement tool")

            // Drawing Tools
            QuickActionCircularButton(
                icon: "pencil.tip.crop.circle",
                isActive: showDrawingPanel,
                color: .white,
                action: {
                    showDrawingPanel.toggle()
                }
            )
            .accessibilityLabel("Drawing tools")

            // Layers
            QuickActionCircularButton(
                icon: "square.3.layers.3d",
                isActive: showLayersPanel,
                color: .white,
                action: {
                    showLayersPanel.toggle()
                }
            )
            .accessibilityLabel("Map layers")

            // Emergency SOS (Red accent)
            QuickActionCircularButton(
                icon: "exclamationmark.triangle.fill",
                isActive: showEmergencySOS,
                color: Color(hex: "#FF5252"),
                action: {
                    showEmergencySOS.toggle()
                }
            )
            .accessibilityLabel("Emergency SOS")

            // Tools Menu
            QuickActionCircularButton(
                icon: "ellipsis.circle",
                isActive: showToolsMenu,
                color: .white,
                action: {
                    showToolsMenu.toggle()
                }
            )
            .accessibilityLabel("More tools")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.5))
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
        )
        .opacity(isVisible ? 1.0 : 0.0)
        .scaleEffect(isVisible ? 1.0 : 0.8)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isVisible)
        .onAppear {
            withAnimation {
                isVisible = true
            }
        }
    }
}

// MARK: - Circular Action Button

private struct QuickActionCircularButton: View {
    let icon: String
    let isActive: Bool
    let color: Color
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()

            action()
        }) {
            ZStack {
                // Background circle
                Circle()
                    .fill(isActive ? Color(hex: "#FFFC00").opacity(0.3) : Color.black.opacity(0.6))
                    .frame(width: 36, height: 36)

                // Active border
                if isActive {
                    Circle()
                        .strokeBorder(Color(hex: "#FFFC00"), lineWidth: 1.5)
                        .frame(width: 36, height: 36)
                        .shadow(color: Color(hex: "#FFFC00").opacity(0.5), radius: 3, x: 0, y: 0)
                }

                // Icon
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(isActive ? Color(hex: "#FFFC00") : color)
            }
            .scaleEffect(isPressed ? 0.9 : 1.0)
            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
        )
    }
}

// MARK: - Preview

#if DEBUG
struct VerticalQuickActionMenu_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            // Simulate map background
            Color.gray.edgesIgnoringSafeArea(.all)

            HStack {
                Spacer()

                VerticalQuickActionMenu(
                    showMeasurement: .constant(false),
                    showDrawingPanel: .constant(false),
                    showLayersPanel: .constant(true),
                    showEmergencySOS: .constant(false),
                    showToolsMenu: .constant(false),
                    isCursorModeActive: .constant(false),
                    userLocation: CLLocationCoordinate2D(latitude: 38.8977, longitude: -77.0365),
                    onZoomToSelf: { print("Zoom to self") },
                    onDropPoint: { print("Drop point") }
                )
                .padding(.trailing, 16)
                .padding(.bottom, 140)
            }
        }
        .preferredColorScheme(.dark)
    }
}
#endif
