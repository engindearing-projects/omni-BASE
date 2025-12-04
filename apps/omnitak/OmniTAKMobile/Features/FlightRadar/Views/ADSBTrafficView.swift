//
//  ADSBTrafficView.swift
//  OmniTAKMobile
//
//  Configuration and status view for ADS-B flight tracking
//

import SwiftUI
import CoreLocation

struct ADSBTrafficView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var trafficService = ADSBTrafficService.shared
    @State private var zipCodeInput = ""
    @State private var isLookingUpZip = false
    @State private var zipLookupError: String?
    @State private var showAPISettings = false
    @State private var apiUsername = ""
    @State private var apiPassword = ""

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Master Toggle Card
                        masterToggleCard

                        if trafficService.settings.isEnabled {
                            // Location Settings Card
                            locationCard

                            // Display Settings Card
                            displaySettingsCard

                            // API Settings Card
                            apiSettingsCard

                            // Status Card
                            statusCard

                            // Aircraft List
                            if !trafficService.aircraft.isEmpty {
                                aircraftListCard
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Flight Radar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "#FFFC00"))
                }
            }
        }
    }

    // MARK: - Master Toggle Card

    private var masterToggleCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "airplane")
                    .font(.system(size: 32))
                    .foregroundColor(trafficService.settings.isEnabled ? Color(hex: "#FFFC00") : .gray)

                VStack(alignment: .leading, spacing: 4) {
                    Text("ADS-B Traffic")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Show aircraft on map")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }

                Spacer()

                Toggle("", isOn: Binding(
                    get: { trafficService.settings.isEnabled },
                    set: { newValue in
                        var settings = trafficService.settings
                        settings.isEnabled = newValue
                        trafficService.settings = settings
                    }
                ))
                .labelsHidden()
                .tint(Color(hex: "#FFFC00"))
            }

            if trafficService.settings.isEnabled {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                    Text("Data from OpenSky Network")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(white: 0.12))
        .cornerRadius(12)
    }

    // MARK: - Location Card

    private var locationCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("LOCATION")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.gray)

            // Use Current Location Toggle
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(trafficService.settings.useCurrentLocation ? .blue : .gray)
                Text("Use Current Location")
                    .foregroundColor(.white)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { trafficService.settings.useCurrentLocation },
                    set: { newValue in
                        var settings = trafficService.settings
                        settings.useCurrentLocation = newValue
                        trafficService.settings = settings
                    }
                ))
                .labelsHidden()
                .tint(Color(hex: "#FFFC00"))
            }

            // Custom Zip Code (when not using current location)
            if !trafficService.settings.useCurrentLocation {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Or enter ZIP code:")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)

                    HStack {
                        TextField("ZIP Code", text: $zipCodeInput)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 120)

                        Button(action: lookupZipCode) {
                            if isLookingUpZip {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Set Location")
                                    .font(.system(size: 14, weight: .medium))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(hex: "#FFFC00"))
                        .foregroundColor(.black)
                        .cornerRadius(8)
                        .disabled(zipCodeInput.isEmpty || isLookingUpZip)

                        Spacer()
                    }

                    if let error = zipLookupError {
                        Text(error)
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                    }

                    if let lat = trafficService.settings.customLatitude,
                       let lon = trafficService.settings.customLongitude {
                        Text("Set to: \(String(format: "%.4f", lat)), \(String(format: "%.4f", lon))")
                            .font(.system(size: 12))
                            .foregroundColor(.green)
                    }
                }
            }

            Divider().background(Color.gray.opacity(0.3))

            // Radius Slider
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Search Radius")
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(Int(trafficService.settings.radiusNM)) NM")
                        .foregroundColor(Color(hex: "#FFFC00"))
                        .font(.system(size: 14, weight: .semibold))
                }

                Slider(
                    value: Binding(
                        get: { trafficService.settings.radiusNM },
                        set: { newValue in
                            var settings = trafficService.settings
                            settings.radiusNM = newValue
                            trafficService.settings = settings
                        }
                    ),
                    in: 10...200,
                    step: 10
                )
                .tint(Color(hex: "#FFFC00"))

                HStack {
                    Text("10 NM")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                    Spacer()
                    Text("200 NM")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color(white: 0.12))
        .cornerRadius(12)
    }

    // MARK: - Display Settings Card

    private var displaySettingsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("DISPLAY OPTIONS")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.gray)

            // Show Ground Traffic
            HStack {
                Image(systemName: "airplane.arrival")
                    .foregroundColor(.gray)
                Text("Show Ground Traffic")
                    .foregroundColor(.white)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { trafficService.settings.showOnGround },
                    set: { newValue in
                        var settings = trafficService.settings
                        settings.showOnGround = newValue
                        trafficService.settings = settings
                    }
                ))
                .labelsHidden()
                .tint(Color(hex: "#FFFC00"))
            }

            Divider().background(Color.gray.opacity(0.3))

            // Refresh Interval
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Refresh Interval")
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(trafficService.settings.refreshIntervalSeconds)s")
                        .foregroundColor(Color(hex: "#FFFC00"))
                        .font(.system(size: 14, weight: .semibold))
                }

                Picker("", selection: Binding(
                    get: { trafficService.settings.refreshIntervalSeconds },
                    set: { newValue in
                        var settings = trafficService.settings
                        // Enforce minimum based on API tier
                        let minInterval = settings.minimumRefreshInterval
                        settings.refreshIntervalSeconds = max(newValue, minInterval)
                        trafficService.settings = settings
                    }
                )) {
                    // Only show 5s option if user has API credentials
                    if trafficService.settings.hasAPICredentials {
                        Text("5s").tag(5)
                    }
                    Text("10s").tag(10)
                    Text("15s").tag(15)
                    Text("30s").tag(30)
                    Text("60s").tag(60)
                }
                .pickerStyle(.segmented)

                if !trafficService.settings.hasAPICredentials {
                    Text("Add API key for faster refresh rates")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color(white: 0.12))
        .cornerRadius(12)
    }

    // MARK: - API Settings Card

    private var apiSettingsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("API ACCESS")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.gray)

                Spacer()

                // Tier indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(trafficService.settings.hasAPICredentials ? .green : .orange)
                        .frame(width: 8, height: 8)
                    Text(trafficService.settings.hasAPICredentials ? "Enhanced" : "Free Tier")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(trafficService.settings.hasAPICredentials ? .green : .orange)
                }
            }

            // Current tier info
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Requests/Day")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                    Text(trafficService.settings.requestsPerDay)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Min Refresh")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                    Text("\(trafficService.settings.minimumRefreshInterval)s")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }

                Spacer()
            }

            // Toggle to show/hide API settings
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showAPISettings.toggle()
                    if showAPISettings {
                        apiUsername = trafficService.settings.apiUsername
                        apiPassword = trafficService.settings.apiPassword
                    }
                }
            }) {
                HStack {
                    Image(systemName: "key.fill")
                        .foregroundColor(Color(hex: "#FFFC00"))
                    Text(trafficService.settings.hasAPICredentials ? "Edit API Credentials" : "Add OpenSky API Key")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: showAPISettings ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }

            if showAPISettings {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Get free API credentials at opensky-network.org")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)

                    TextField("Username", text: $apiUsername)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)

                    SecureField("Password", text: $apiPassword)
                        .textFieldStyle(.roundedBorder)

                    HStack {
                        Button(action: {
                            var settings = trafficService.settings
                            settings.apiUsername = apiUsername
                            settings.apiPassword = apiPassword
                            trafficService.settings = settings
                            showAPISettings = false
                        }) {
                            Text("Save")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.black)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(Color(hex: "#FFFC00"))
                                .cornerRadius(8)
                        }

                        if trafficService.settings.hasAPICredentials {
                            Button(action: {
                                var settings = trafficService.settings
                                settings.apiUsername = ""
                                settings.apiPassword = ""
                                // Bump up refresh interval if it was set to 5s (API-only option)
                                if settings.refreshIntervalSeconds < 10 {
                                    settings.refreshIntervalSeconds = 10
                                }
                                trafficService.settings = settings
                                apiUsername = ""
                                apiPassword = ""
                            }) {
                                Text("Remove")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                                    .background(Color.red.opacity(0.2))
                                    .cornerRadius(8)
                            }
                        }

                        Spacer()
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(white: 0.12))
        .cornerRadius(12)
    }

    // MARK: - Status Card

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("STATUS")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.gray)

                Spacer()

                Button(action: {
                    trafficService.fetchAircraft()
                }) {
                    HStack(spacing: 4) {
                        if trafficService.isLoading {
                            ProgressView()
                                .scaleEffect(0.7)
                                .tint(.white)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text("Refresh")
                    }
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#FFFC00"))
                }
                .disabled(trafficService.isLoading)
            }

            HStack(spacing: 20) {
                VStack {
                    Text("\(trafficService.aircraft.count)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color(hex: "#FFFC00"))
                    Text("Aircraft")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }

                Spacer()

                if let lastUpdate = trafficService.lastUpdate {
                    VStack(alignment: .trailing) {
                        Text("Last Update")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                        Text(lastUpdate, style: .time)
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    }
                }
            }

            if let error = trafficService.error {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(Color(white: 0.12))
        .cornerRadius(12)
    }

    // MARK: - Aircraft List Card

    private var aircraftListCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("NEARBY AIRCRAFT")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.gray)

            // Category summary chips
            if !trafficService.aircraft.isEmpty {
                categoryChipsView
            }

            ForEach(trafficService.aircraft.prefix(10)) { aircraft in
                AircraftRow(aircraft: aircraft)
            }

            if trafficService.aircraft.count > 10 {
                Text("+ \(trafficService.aircraft.count - 10) more aircraft")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color(white: 0.12))
        .cornerRadius(12)
    }

    private var categoryChipsView: some View {
        let categoryCounts = Dictionary(grouping: trafficService.aircraft) { aircraft in
            AircraftTypeDetector.detectCategory(
                callsign: aircraft.callsign,
                velocity: aircraft.velocity,
                altitude: aircraft.altitude,
                verticalRate: aircraft.verticalRate,
                onGround: aircraft.onGround,
                originCountry: aircraft.originCountry
            )
        }.mapValues { $0.count }

        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categoryCounts.sorted(by: { $0.value > $1.value }), id: \.key) { category, count in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(category.baseColor)
                            .frame(width: 8, height: 8)
                        Text("\(count)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                        Text(category.displayName)
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(white: 0.18))
                    .cornerRadius(16)
                }
            }
        }
        .frame(height: 32)
    }

    // MARK: - Actions

    private func lookupZipCode() {
        guard !zipCodeInput.isEmpty else { return }
        isLookingUpZip = true
        zipLookupError = nil

        trafficService.lookupZipCode(zipCodeInput) { coordinate in
            isLookingUpZip = false
            if let coord = coordinate {
                var settings = trafficService.settings
                settings.customLatitude = coord.latitude
                settings.customLongitude = coord.longitude
                trafficService.settings = settings
                trafficService.fetchAircraft()
            } else {
                zipLookupError = "Could not find location for ZIP code"
            }
        }
    }
}

// MARK: - Aircraft Row

struct AircraftRow: View {
    let aircraft: Aircraft

    private var category: AircraftCategory {
        AircraftTypeDetector.detectCategory(
            callsign: aircraft.callsign,
            velocity: aircraft.velocity,
            altitude: aircraft.altitude,
            verticalRate: aircraft.verticalRate,
            onGround: aircraft.onGround,
            originCountry: aircraft.originCountry
        )
    }

    var body: some View {
        HStack(spacing: 10) {
            // Aircraft icon with type-aware styling
            AircraftListIcon(aircraft: aircraft, size: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(aircraft.callsign.isEmpty ? aircraft.id.uppercased() : aircraft.callsign)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)

                HStack(spacing: 6) {
                    Text(category.displayName)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(category.baseColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(category.baseColor.opacity(0.2))
                        .cornerRadius(4)

                    Text(aircraft.originCountry)
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    Text(aircraft.formattedAltitude)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                    Text(aircraft.climbDescendIndicator)
                        .foregroundColor(aircraft.verticalRate > 1 ? .green : (aircraft.verticalRate < -1 ? .orange : .gray))
                }

                Text(aircraft.formattedSpeed)
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#if DEBUG
struct ADSBTrafficView_Previews: PreviewProvider {
    static var previews: some View {
        ADSBTrafficView()
            .preferredColorScheme(.dark)
    }
}
#endif
