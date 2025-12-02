//
//  MeshtasticDevicePickerView.swift
//  OmniTAK Mobile
//
//  Device picker wrapper - redirects to simplified TCP connection view
//  Only TCP/Network connections are supported on iOS
//

import SwiftUI

struct MeshtasticDevicePickerView: View {
    @ObservedObject var manager: MeshtasticManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        MeshtasticTCPConnectionView(manager: manager)
    }
}

// MARK: - Preview

struct MeshtasticDevicePickerView_Previews: PreviewProvider {
    static var previews: some View {
        MeshtasticDevicePickerView(manager: MeshtasticManager())
    }
}
