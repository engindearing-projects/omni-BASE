//
//  HamburgerMenuButton.swift
//  OmniTAKMobile
//
//  ATAK-style three-bar hamburger menu button
//

import SwiftUI

struct HamburgerMenuButton: View {
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()

            action()
        }) {
            VStack(spacing: 3) {
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 18, height: 2)
                    .cornerRadius(1)

                Rectangle()
                    .fill(Color.white)
                    .frame(width: 18, height: 2)
                    .cornerRadius(1)

                Rectangle()
                    .fill(Color.white)
                    .frame(width: 18, height: 2)
                    .cornerRadius(1)
            }
            .frame(width: 32, height: 32)
            .background(
                Circle()
                    .fill(isPressed ? Color.black.opacity(0.7) : Color.black.opacity(0.5))
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
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
        .accessibilityLabel("Menu")
        .accessibilityHint("Opens navigation menu")
    }
}

// MARK: - Preview

#if DEBUG
struct HamburgerMenuButton_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black

            HamburgerMenuButton {
                print("Menu tapped")
            }
        }
        .preferredColorScheme(.dark)
    }
}
#endif
