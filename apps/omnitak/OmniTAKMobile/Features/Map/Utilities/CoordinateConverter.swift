//
//  CoordinateConverter.swift
//  OmniTAKMobile
//
//  Military-grade coordinate conversion utility
//  Supports lat/lon, MGRS, UTM, and other military coordinate systems
//

import Foundation
import CoreLocation

// MARK: - Coordinate Precision

enum CoordinatePrecision: Int {
    case oneKm = 1000       // 1000m precision
    case hundredM = 100     // 100m precision
    case tenM = 10          // 10m precision
    case oneM = 1           // 1m precision
    case tenCm = 0          // 0.1m precision

    var mgrsDigits: Int {
        switch self {
        case .oneKm: return 2         // 2 digits (e.g., 64 19)
        case .hundredM: return 3      // 3 digits
        case .tenM: return 4          // 4 digits
        case .oneM: return 5          // 5 digits (standard)
        case .tenCm: return 6         // 6 digits
        }
    }
}

// MARK: - UTM Coordinate

struct UTMCoordinate {
    let zone: Int
    let hemisphere: Hemisphere
    let easting: Double
    let northing: Double

    enum Hemisphere: String {
        case north = "N"
        case south = "S"
    }

    var description: String {
        "\(zone)\(hemisphere.rawValue) \(Int(easting)) \(Int(northing))"
    }

    var formattedDescription: String {
        let eastingStr = String(format: "%.0f", easting)
        let northingStr = String(format: "%.0f", northing)
        return "\(zone)\(hemisphere.rawValue) \(eastingStr)mE \(northingStr)mN"
    }
}

// MARK: - MGRS Coordinate

struct MGRSCoordinate {
    let zone: Int
    let band: String
    let grid: String
    let easting: String
    let northing: String
    let precision: CoordinatePrecision

    var description: String {
        "\(zone)\(band)\(grid)\(easting)\(northing)"
    }

    var formattedDescription: String {
        "\(zone)\(band) \(grid) \(easting) \(northing)"
    }

    init(zone: Int, band: String, grid: String, easting: String, northing: String, precision: CoordinatePrecision = .oneM) {
        self.zone = zone
        self.band = band
        self.grid = grid
        self.easting = easting
        self.northing = northing
        self.precision = precision
    }

    init?(from string: String) {
        // Parse MGRS string (e.g., "11SMS6419734196" or "11S MS 64197 34196")
        let cleaned = string.replacingOccurrences(of: " ", with: "").uppercased()

        // Extract components
        guard cleaned.count >= 5 else { return nil }

        // Zone (1-2 digits)
        var index = cleaned.startIndex
        var zoneStr = ""
        while index < cleaned.endIndex && cleaned[index].isNumber {
            zoneStr.append(cleaned[index])
            index = cleaned.index(after: index)
        }

        guard let zoneNum = Int(zoneStr), zoneNum >= 1 && zoneNum <= 60 else {
            return nil
        }

        self.zone = zoneNum

        // Band (1 letter, C-X excluding I and O)
        guard index < cleaned.endIndex, cleaned[index].isLetter else { return nil }
        self.band = String(cleaned[index])
        index = cleaned.index(after: index)

        // Grid (2 letters)
        guard cleaned.distance(from: index, to: cleaned.endIndex) >= 2 else { return nil }
        let gridEnd = cleaned.index(index, offsetBy: 2)
        self.grid = String(cleaned[index..<gridEnd])
        index = gridEnd

        // Easting and northing (remaining digits, split evenly)
        let remaining = String(cleaned[index...])
        guard remaining.count % 2 == 0 && remaining.count >= 2 else { return nil }

        let halfCount = remaining.count / 2
        self.easting = String(remaining.prefix(halfCount))
        self.northing = String(remaining.suffix(halfCount))

        // Determine precision based on digit count
        switch halfCount {
        case 2: self.precision = .oneKm
        case 3: self.precision = .hundredM
        case 4: self.precision = .tenM
        case 5: self.precision = .oneM
        case 6: self.precision = .tenCm
        default: self.precision = .oneM
        }
    }
}

// MARK: - Coordinate Converter

class CoordinateConverter {

    // MARK: - Decimal Degrees (DD)

    static func formatDecimal(_ coordinate: CLLocationCoordinate2D, decimals: Int = 6) -> String {
        let latStr = String(format: "%.\(decimals)f", coordinate.latitude)
        let lonStr = String(format: "%.\(decimals)f", coordinate.longitude)
        return "\(latStr), \(lonStr)"
    }

    /// Parse decimal coordinate string
    static func parseDecimal(_ string: String) -> CLLocationCoordinate2D? {
        let components = string.components(separatedBy: ",")
        guard components.count == 2,
              let lat = Double(components[0].trimmingCharacters(in: .whitespaces)),
              let lon = Double(components[1].trimmingCharacters(in: .whitespaces)),
              abs(lat) <= 90,
              abs(lon) <= 180 else {
            return nil
        }

        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    // MARK: - Degrees Minutes Seconds (DMS)

    static func formatDMS(_ coordinate: CLLocationCoordinate2D) -> String {
        let latDMS = decimalToDMS(abs(coordinate.latitude))
        let lonDMS = decimalToDMS(abs(coordinate.longitude))

        let latDir = coordinate.latitude >= 0 ? "N" : "S"
        let lonDir = coordinate.longitude >= 0 ? "E" : "W"

        return "\(latDMS.0)°\(latDMS.1)'\(String(format: "%.2f", latDMS.2))\"\(latDir) " +
               "\(lonDMS.0)°\(lonDMS.1)'\(String(format: "%.2f", lonDMS.2))\"\(lonDir)"
    }

    private static func decimalToDMS(_ decimal: Double) -> (Int, Int, Double) {
        let degrees = Int(decimal)
        let minutesDecimal = (decimal - Double(degrees)) * 60
        let minutes = Int(minutesDecimal)
        let seconds = (minutesDecimal - Double(minutes)) * 60
        return (degrees, minutes, seconds)
    }

    // MARK: - Degrees Decimal Minutes (DDM)

    static func formatDDM(_ coordinate: CLLocationCoordinate2D) -> String {
        let latDDM = decimalToDDM(abs(coordinate.latitude))
        let lonDDM = decimalToDDM(abs(coordinate.longitude))

        let latDir = coordinate.latitude >= 0 ? "N" : "S"
        let lonDir = coordinate.longitude >= 0 ? "E" : "W"

        return "\(latDDM.0)°\(String(format: "%.3f", latDDM.1))'\(latDir) " +
               "\(lonDDM.0)°\(String(format: "%.3f", lonDDM.1))'\(lonDir)"
    }

    private static func decimalToDDM(_ decimal: Double) -> (Int, Double) {
        let degrees = Int(decimal)
        let minutes = (decimal - Double(degrees)) * 60
        return (degrees, minutes)
    }

    // MARK: - MGRS (Military Grid Reference System)

    static func formatMGRS(_ coordinate: CLLocationCoordinate2D, precision: CoordinatePrecision = .oneM) -> String {
        // Convert to UTM first
        let utm = convertToUTM(coordinate)

        // Get MGRS grid zone designator (band letter)
        let band = getMGRSBand(coordinate.latitude)

        // Get 100km grid square letters
        let gridSquare = getMGRSGridSquare(utm: utm)

        // Format easting and northing with appropriate precision
        let digits = precision.mgrsDigits
        let easting = formatMGRSComponent(utm.easting, digits: digits)
        let northing = formatMGRSComponent(utm.northing, digits: digits)

        return "\(utm.zone)\(band)\(gridSquare)\(easting)\(northing)"
    }

    private static func getMGRSBand(_ latitude: Double) -> String {
        // MGRS bands: C-X (excluding I and O)
        // Each band is 8° wide, starting at -80°
        let bands = ["C", "D", "E", "F", "G", "H", "J", "K", "L", "M",
                     "N", "P", "Q", "R", "S", "T", "U", "V", "W", "X"]

        let index = Int((latitude + 80) / 8)
        let clampedIndex = max(0, min(index, bands.count - 1))
        return bands[clampedIndex]
    }

    private static func getMGRSGridSquare(utm: UTMCoordinate) -> String {
        // Simplified grid square calculation
        // In a full implementation, this would use proper MGRS lookup tables
        let eastingLetters = ["A", "B", "C", "D", "E", "F", "G", "H"]
        let northingLetters = ["A", "B", "C", "D", "E", "F", "G", "H", "J", "K",
                               "L", "M", "N", "P", "Q", "R", "S", "T", "U", "V"]

        let eastingIndex = Int(utm.easting / 100000) % eastingLetters.count
        let northingIndex = Int(utm.northing / 100000) % northingLetters.count

        return eastingLetters[eastingIndex] + northingLetters[northingIndex]
    }

    private static func formatMGRSComponent(_ value: Double, digits: Int) -> String {
        // Take only the portion within the 100km grid square
        let inGridSquare = Int(value) % 100000

        // Format with leading zeros
        let formatted = String(format: "%05d", inGridSquare)

        // Return specified precision (first N digits)
        return String(formatted.prefix(digits))
    }

    /// Parse MGRS coordinate string
    static func parseMGRS(_ string: String) -> CLLocationCoordinate2D? {
        guard let mgrs = MGRSCoordinate(from: string) else {
            return nil
        }

        // Convert MGRS to UTM, then to lat/lon
        // This is a simplified conversion - full implementation would use proper MGRS tables
        let utm = mgrsToUTM(mgrs)
        return convertFromUTM(utm)
    }

    private static func mgrsToUTM(_ mgrs: MGRSCoordinate) -> UTMCoordinate {
        // Simplified conversion
        // Get base easting/northing from grid square
        let gridLetters = Array(mgrs.grid)
        let eastingLetter = String(gridLetters[0])
        let northingLetter = String(gridLetters[1])

        let eastingLetters = ["A", "B", "C", "D", "E", "F", "G", "H"]
        let northingLetters = ["A", "B", "C", "D", "E", "F", "G", "H", "J", "K",
                               "L", "M", "N", "P", "Q", "R", "S", "T", "U", "V"]

        let eastingBase = (eastingLetters.firstIndex(of: eastingLetter) ?? 0) * 100000
        let northingBase = (northingLetters.firstIndex(of: northingLetter) ?? 0) * 100000

        // Parse easting/northing values and add to base
        let eastingValue = Double(mgrs.easting.padding(toLength: 5, withPad: "0", startingAt: 0)) ?? 0
        let northingValue = Double(mgrs.northing.padding(toLength: 5, withPad: "0", startingAt: 0)) ?? 0

        let finalEasting = Double(eastingBase) + eastingValue
        let finalNorthing = Double(northingBase) + northingValue

        // Determine hemisphere from band
        let hemisphere: UTMCoordinate.Hemisphere = mgrs.band < "N" ? .south : .north

        return UTMCoordinate(
            zone: mgrs.zone,
            hemisphere: hemisphere,
            easting: finalEasting,
            northing: finalNorthing
        )
    }

    // MARK: - UTM (Universal Transverse Mercator)

    static func formatUTM(_ coordinate: CLLocationCoordinate2D) -> String {
        let utm = convertToUTM(coordinate)
        return utm.description
    }

    static func convertToUTM(_ coordinate: CLLocationCoordinate2D) -> UTMCoordinate {
        let lat = coordinate.latitude * .pi / 180
        let lon = coordinate.longitude * .pi / 180

        // Calculate UTM zone
        let zone = Int((coordinate.longitude + 180) / 6) + 1

        // Central meridian of zone
        let lonOrigin = Double(zone - 1) * 6 - 180 + 3
        let lonOriginRad = lonOrigin * .pi / 180

        // WGS84 ellipsoid parameters
        let a = 6378137.0           // semi-major axis
        let e = 0.081819190842621   // eccentricity
        let k0 = 0.9996             // scale factor

        let N = a / sqrt(1 - pow(e * sin(lat), 2))
        let T = pow(tan(lat), 2)
        let C = (pow(e, 2) / (1 - pow(e, 2))) * pow(cos(lat), 2)
        let A = (lon - lonOriginRad) * cos(lat)

        let M = a * ((1 - pow(e, 2) / 4 - 3 * pow(e, 4) / 64 - 5 * pow(e, 6) / 256) * lat
                     - (3 * pow(e, 2) / 8 + 3 * pow(e, 4) / 32 + 45 * pow(e, 6) / 1024) * sin(2 * lat)
                     + (15 * pow(e, 4) / 256 + 45 * pow(e, 6) / 1024) * sin(4 * lat)
                     - (35 * pow(e, 6) / 3072) * sin(6 * lat))

        let easting = k0 * N * (A + (1 - T + C) * pow(A, 3) / 6
                                + (5 - 18 * T + pow(T, 2) + 72 * C - 58 * (pow(e, 2) / (1 - pow(e, 2)))) * pow(A, 5) / 120) + 500000

        var northing = k0 * (M + N * tan(lat) * (pow(A, 2) / 2 + (5 - T + 9 * C + 4 * pow(C, 2)) * pow(A, 4) / 24
                                                  + (61 - 58 * T + pow(T, 2) + 600 * C - 330 * (pow(e, 2) / (1 - pow(e, 2)))) * pow(A, 6) / 720))

        let hemisphere: UTMCoordinate.Hemisphere
        if coordinate.latitude < 0 {
            northing += 10000000 // False northing for southern hemisphere
            hemisphere = .south
        } else {
            hemisphere = .north
        }

        return UTMCoordinate(zone: zone, hemisphere: hemisphere, easting: easting, northing: northing)
    }

    static func convertFromUTM(_ utm: UTMCoordinate) -> CLLocationCoordinate2D {
        // WGS84 ellipsoid parameters
        let a = 6378137.0
        let e = 0.081819190842621
        let k0 = 0.9996

        let x = utm.easting - 500000
        var y = utm.northing
        if utm.hemisphere == .south {
            y -= 10000000
        }

        // Central meridian
        let lonOrigin = Double(utm.zone - 1) * 6 - 180 + 3

        let M = y / k0
        let mu = M / (a * (1 - pow(e, 2) / 4 - 3 * pow(e, 4) / 64 - 5 * pow(e, 6) / 256))

        let e1 = (1 - sqrt(1 - pow(e, 2))) / (1 + sqrt(1 - pow(e, 2)))
        let phi1 = mu + (3 * e1 / 2 - 27 * pow(e1, 3) / 32) * sin(2 * mu)
                      + (21 * pow(e1, 2) / 16 - 55 * pow(e1, 4) / 32) * sin(4 * mu)
                      + (151 * pow(e1, 3) / 96) * sin(6 * mu)
                      + (1097 * pow(e1, 4) / 512) * sin(8 * mu)

        let C1 = (pow(e, 2) / (1 - pow(e, 2))) * pow(cos(phi1), 2)
        let T1 = pow(tan(phi1), 2)
        let N1 = a / sqrt(1 - pow(e * sin(phi1), 2))
        let R1 = a * (1 - pow(e, 2)) / pow(1 - pow(e * sin(phi1), 2), 1.5)
        let D = x / (N1 * k0)

        let lat = phi1 - (N1 * tan(phi1) / R1) * (pow(D, 2) / 2
                                                    - (5 + 3 * T1 + 10 * C1 - 4 * pow(C1, 2) - 9 * (pow(e, 2) / (1 - pow(e, 2)))) * pow(D, 4) / 24
                                                    + (61 + 90 * T1 + 298 * C1 + 45 * pow(T1, 2) - 252 * (pow(e, 2) / (1 - pow(e, 2))) - 3 * pow(C1, 2)) * pow(D, 6) / 720)

        let lon = (D - (1 + 2 * T1 + C1) * pow(D, 3) / 6
                   + (5 - 2 * C1 + 28 * T1 - 3 * pow(C1, 2) + 8 * (pow(e, 2) / (1 - pow(e, 2))) + 24 * pow(T1, 2)) * pow(D, 5) / 120) / cos(phi1)

        let latitude = lat * 180 / .pi
        let longitude = lonOrigin + lon * 180 / .pi

        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    // MARK: - GARS (Global Area Reference System)

    static func formatGARS(_ coordinate: CLLocationCoordinate2D) -> String {
        // GARS divides the world into 30' x 30' cells
        let lonBand = Int((coordinate.longitude + 180) / 0.5) + 1
        let latBand = Int((coordinate.latitude + 90) / 0.5) + 1

        // Each 30' cell is divided into 4 quadrants (15' x 15')
        let lonQuad = Int((coordinate.longitude - floor(coordinate.longitude / 0.5) * 0.5) / 0.25) + 1
        let latQuad = Int((coordinate.latitude - floor(coordinate.latitude / 0.5) * 0.5) / 0.25) + 1

        let quadrant = (latQuad - 1) * 2 + lonQuad

        // Each quadrant is divided into 9 keynodes (5' x 5')
        let lonKey = Int((coordinate.longitude - floor(coordinate.longitude / 0.25) * 0.25) / (5.0/60.0)) + 1
        let latKey = Int((coordinate.latitude - floor(coordinate.latitude / 0.25) * 0.25) / (5.0/60.0)) + 1

        let keynode = (latKey - 1) * 3 + lonKey

        return String(format: "%03d%s%d%d", lonBand, latBandToLetter(latBand), quadrant, keynode)
    }

    private static func latBandToLetter(_ band: Int) -> String {
        let letters = ["AA", "AB", "AC", "AD", "AE", "AF", "AG", "AH", "AJ",
                       "AK", "AL", "AM", "AN", "AP", "AQ", "AR", "AS", "AT"]
        let index = min(max(band / 10, 0), letters.count - 1)
        return letters[index]
    }

    // MARK: - Distance and Bearing

    /// Calculate distance between two coordinates (in meters)
    static func distance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation)
    }

    /// Calculate bearing from one coordinate to another (in degrees, 0-360)
    static func bearing(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let lat1 = from.latitude * .pi / 180
        let lon1 = from.longitude * .pi / 180
        let lat2 = to.latitude * .pi / 180
        let lon2 = to.longitude * .pi / 180

        let dLon = lon2 - lon1

        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)

        var bearing = atan2(y, x) * 180 / .pi
        bearing = fmod(bearing + 360, 360)

        return bearing
    }
}
