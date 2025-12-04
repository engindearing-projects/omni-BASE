//
//  ADSBModels.swift
//  OmniTAKMobile
//
//  ADS-B aircraft data models for flight tracking
//

import Foundation
import CoreLocation
import MapKit

// MARK: - Aircraft Model

struct Aircraft: Identifiable, Equatable {
    let id: String  // ICAO24 address
    let callsign: String
    let originCountry: String
    let coordinate: CLLocationCoordinate2D
    let altitude: Double  // meters
    let velocity: Double  // m/s
    let heading: Double   // degrees from north
    let verticalRate: Double  // m/s
    let onGround: Bool
    let lastUpdate: Date

    var altitudeFeet: Int {
        Int(altitude * 3.28084)
    }

    var speedKnots: Int {
        Int(velocity * 1.94384)
    }

    var speedMPH: Int {
        Int(velocity * 2.23694)
    }

    var formattedAltitude: String {
        if onGround {
            return "Ground"
        }
        return "\(altitudeFeet.formatted()) ft"
    }

    var formattedSpeed: String {
        "\(speedKnots) kts"
    }

    var climbDescendIndicator: String {
        if verticalRate > 1 {
            return "↑"
        } else if verticalRate < -1 {
            return "↓"
        }
        return "→"
    }

    static func == (lhs: Aircraft, rhs: Aircraft) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - OpenSky API Response

struct OpenSkyResponse: Codable {
    let time: Int
    let states: [[OpenSkyState]]?
}

enum OpenSkyState: Codable {
    case string(String)
    case double(Double)
    case bool(Bool)
    case int(Int)
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
            return
        }
        if let value = try? container.decode(String.self) {
            self = .string(value)
            return
        }
        if let value = try? container.decode(Double.self) {
            self = .double(value)
            return
        }
        if let value = try? container.decode(Bool.self) {
            self = .bool(value)
            return
        }
        if let value = try? container.decode(Int.self) {
            self = .int(value)
            return
        }
        self = .null
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .double(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        case .int(let value): try container.encode(value)
        case .null: try container.encodeNil()
        }
    }

    var stringValue: String? {
        if case .string(let value) = self { return value }
        return nil
    }

    var doubleValue: Double? {
        switch self {
        case .double(let value): return value
        case .int(let value): return Double(value)
        default: return nil
        }
    }

    var boolValue: Bool? {
        if case .bool(let value) = self { return value }
        return nil
    }
}

// MARK: - Traffic Settings

struct ADSBTrafficSettings: Codable {
    var isEnabled: Bool = false
    var radiusNM: Double = 50  // Nautical miles
    var useCurrentLocation: Bool = true
    var customZipCode: String = ""
    var customLatitude: Double?
    var customLongitude: Double?
    var refreshIntervalSeconds: Int = 10
    var showOnGround: Bool = false
    var minAltitudeFeet: Int = 0
    var maxAltitudeFeet: Int = 60000

    // API Authentication (optional for enhanced access)
    var apiUsername: String = ""
    var apiPassword: String = ""

    var hasAPICredentials: Bool {
        !apiUsername.isEmpty && !apiPassword.isEmpty
    }

    var radiusKM: Double {
        radiusNM * 1.852
    }

    var radiusDegrees: Double {
        // Approximate conversion: 1 degree ≈ 111 km at equator
        radiusKM / 111.0
    }

    // Free tier: 10 seconds minimum, with API: 5 seconds minimum
    var minimumRefreshInterval: Int {
        hasAPICredentials ? 5 : 10
    }

    // Free tier allows ~100 requests/day, with API: ~4000/day
    var requestsPerDay: String {
        hasAPICredentials ? "~4,000" : "~100"
    }
}
