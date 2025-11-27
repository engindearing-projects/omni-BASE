//
//  QuickConnectView.swift
//  OmniTAKMobile
//
//  Consolidated server management - redirects to ServersView
//

import SwiftUI

// MARK: - Quick Connect View (Legacy wrapper)
// This view now redirects to the consolidated ServersView
// Kept for backwards compatibility with existing navigation paths

struct QuickConnectView: View {
    var body: some View {
        ServersView()
    }
}

// MARK: - Reusable Components
// These components are used by SimpleEnrollView and other views

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(color)
                .frame(width: 56, height: 56)
                .background(color.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)

                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#CCCCCC"))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(white: 0.1))
        .cornerRadius(12)
    }
}

struct FormField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(hex: "#CCCCCC"))

            if isSecure {
                SecureField(placeholder, text: $text)
                    .textFieldStyle(CustomTextFieldStyle())
            } else {
                TextField(placeholder, text: $text)
                    .textFieldStyle(CustomTextFieldStyle())
                    .keyboardType(keyboardType)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
        }
    }
}

struct HowToCard: View {
    let steps: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(Color(hex: "#FFFC00"))
                Text("How it works")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.black)
                            .frame(width: 24, height: 24)
                            .background(Color(hex: "#FFFC00"))
                            .clipShape(Circle())

                        Text(step)
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "#CCCCCC"))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(white: 0.08))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "#FFFC00").opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#if DEBUG
struct QuickConnectView_Previews: PreviewProvider {
    static var previews: some View {
        QuickConnectView()
            .preferredColorScheme(.dark)
    }
}
#endif
