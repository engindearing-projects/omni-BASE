//
//  ADSBTrafficService.swift
//  OmniTAKMobile
//
//  Service for fetching ADS-B aircraft traffic data from OpenSky Network
//

import Foundation
import CoreLocation
import Combine

class ADSBTrafficService: ObservableObject {
    static let shared = ADSBTrafficService()

    // MARK: - Published Properties

    @Published var aircraft: [Aircraft] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var lastUpdate: Date?
    @Published var settings: ADSBTrafficSettings = ADSBTrafficSettings() {
        didSet {
            saveSettings()

            // Restart tracking if enabled and settings changed
            if settings.isEnabled {
                // Check if refresh interval changed - need to restart timer
                let intervalChanged = oldValue.refreshIntervalSeconds != settings.refreshIntervalSeconds
                let locationChanged = oldValue.useCurrentLocation != settings.useCurrentLocation ||
                                     oldValue.customLatitude != settings.customLatitude ||
                                     oldValue.customLongitude != settings.customLongitude
                let radiusChanged = oldValue.radiusNM != settings.radiusNM

                if intervalChanged || !oldValue.isEnabled {
                    // Restart timer with new interval
                    startTracking()
                } else if locationChanged || radiusChanged {
                    // Just refetch with new parameters
                    fetchAircraft()
                }
            } else {
                stopTracking()
            }
        }
    }

    // MARK: - Private Properties

    private var refreshTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private let userDefaults = UserDefaults.standard
    private let settingsKey = "adsb_traffic_settings"

    // OpenSky Network API (free, no API key required for limited usage)
    private let baseURL = "https://opensky-network.org/api/states/all"

    // MARK: - Initialization

    private init() {
        // Load saved settings
        let savedSettings = loadSettings()
        self.settings = savedSettings
        if savedSettings.isEnabled {
            startTracking()
        }
    }

    // MARK: - Public Methods

    func startTracking() {
        stopTracking()
        guard settings.isEnabled else { return }

        // Fetch immediately
        fetchAircraft()

        // Set up refresh timer
        refreshTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(settings.refreshIntervalSeconds), repeats: true) { [weak self] _ in
            self?.fetchAircraft()
        }
    }

    func stopTracking() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        aircraft = []
    }

    func fetchAircraft() {
        guard settings.isEnabled else { return }

        let center = getSearchCenter()
        guard let center = center else {
            error = "Unable to determine location"
            return
        }

        isLoading = true
        error = nil

        // Calculate bounding box
        let radiusDeg = settings.radiusDegrees
        let minLat = center.latitude - radiusDeg
        let maxLat = center.latitude + radiusDeg
        let minLon = center.longitude - radiusDeg
        let maxLon = center.longitude + radiusDeg

        // Build URL with bounding box
        let urlString = "\(baseURL)?lamin=\(minLat)&lomin=\(minLon)&lamax=\(maxLat)&lomax=\(maxLon)"

        guard let url = URL(string: urlString) else {
            error = "Invalid URL"
            isLoading = false
            return
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 30

        // Add authentication if API credentials provided
        if settings.hasAPICredentials {
            let credentials = "\(settings.apiUsername):\(settings.apiPassword)"
            if let credentialsData = credentials.data(using: .utf8) {
                let base64Credentials = credentialsData.base64EncodedString()
                request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
            }
        }

        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .tryMap { [weak self] data -> [Aircraft] in
                guard let self = self else { return [] }
                return try self.parseOpenSkyResponse(data: data, center: center)
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let err) = completion {
                        self?.error = err.localizedDescription
                    }
                },
                receiveValue: { [weak self] aircraft in
                    self?.aircraft = aircraft
                    self?.lastUpdate = Date()
                    self?.error = nil
                }
            )
            .store(in: &cancellables)
    }

    func lookupZipCode(_ zipCode: String, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(zipCode) { placemarks, error in
            DispatchQueue.main.async {
                if let location = placemarks?.first?.location?.coordinate {
                    completion(location)
                } else {
                    completion(nil)
                }
            }
        }
    }

    // MARK: - Private Methods

    private func getSearchCenter() -> CLLocationCoordinate2D? {
        if settings.useCurrentLocation {
            // Get from LocationManager
            return LocationManager.shared.location?.coordinate
        } else if let lat = settings.customLatitude, let lon = settings.customLongitude {
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
        return nil
    }

    private func parseOpenSkyResponse(data: Data, center: CLLocationCoordinate2D) throws -> [Aircraft] {
        // OpenSky returns an array of arrays, need custom parsing
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let states = json["states"] as? [[Any]] else {
            return []
        }

        var aircraftList: [Aircraft] = []
        let centerLocation = CLLocation(latitude: center.latitude, longitude: center.longitude)

        for state in states {
            guard state.count >= 17 else { continue }

            // Parse state vector
            // Index: 0=icao24, 1=callsign, 2=origin_country, 3=time_position, 4=last_contact,
            // 5=longitude, 6=latitude, 7=baro_altitude, 8=on_ground, 9=velocity,
            // 10=true_track, 11=vertical_rate, 12=sensors, 13=geo_altitude, 14=squawk,
            // 15=spi, 16=position_source

            guard let icao24 = state[0] as? String,
                  let longitude = state[5] as? Double,
                  let latitude = state[6] as? Double else {
                continue
            }

            let callsign = (state[1] as? String)?.trimmingCharacters(in: .whitespaces) ?? ""
            let originCountry = state[2] as? String ?? ""
            let altitude = state[7] as? Double ?? state[13] as? Double ?? 0
            let onGround = state[8] as? Bool ?? false
            let velocity = state[9] as? Double ?? 0
            let heading = state[10] as? Double ?? 0
            let verticalRate = state[11] as? Double ?? 0

            // Filter by altitude
            let altitudeFeet = Int(altitude * 3.28084)
            if altitudeFeet < settings.minAltitudeFeet || altitudeFeet > settings.maxAltitudeFeet {
                continue
            }

            // Filter ground aircraft if setting disabled
            if onGround && !settings.showOnGround {
                continue
            }

            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)

            // Check if within radius (more accurate than bounding box)
            let aircraftLocation = CLLocation(latitude: latitude, longitude: longitude)
            let distanceKM = centerLocation.distance(from: aircraftLocation) / 1000
            if distanceKM > settings.radiusKM {
                continue
            }

            let aircraft = Aircraft(
                id: icao24,
                callsign: callsign,
                originCountry: originCountry,
                coordinate: coordinate,
                altitude: altitude,
                velocity: velocity,
                heading: heading,
                verticalRate: verticalRate,
                onGround: onGround,
                lastUpdate: Date()
            )

            aircraftList.append(aircraft)
        }

        return aircraftList.sorted { $0.altitude > $1.altitude }
    }

    // MARK: - Settings Persistence

    private func saveSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            userDefaults.set(data, forKey: settingsKey)
        }
    }

    private func loadSettings() -> ADSBTrafficSettings {
        guard let data = userDefaults.data(forKey: settingsKey),
              let settings = try? JSONDecoder().decode(ADSBTrafficSettings.self, from: data) else {
            return ADSBTrafficSettings()
        }
        return settings
    }
}
