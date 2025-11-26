//
//  CertificateFormatConverter.swift
//  OmniTAKMobile
//
//  Certificate format detection and analysis
//  Identifies encryption algorithms and iOS compatibility issues
//

import Foundation

// MARK: - Certificate Format Information

struct CertificateFormatInfo {
    let encryptionAlgorithm: String
    let isLegacyFormat: Bool
    let needsConversion: Bool
    let issueDescription: String

    var description: String {
        return "\(encryptionAlgorithm) (legacy: \(isLegacyFormat), needs conversion: \(needsConversion))"
    }
}

// MARK: - Certificate Format Converter

class CertificateFormatConverter {

    // MARK: - Format Detection

    /// Detects certificate format and determines if conversion is needed
    /// - Parameters:
    ///   - data: Certificate data
    ///   - password: Certificate password (optional, for deeper inspection)
    /// - Returns: Format information including conversion requirements
    func detectFormat(_ data: Data, password: String? = nil) -> CertificateFormatInfo {

        // Check for PKCS#12 signature
        guard isPKCS12(data) else {
            return CertificateFormatInfo(
                encryptionAlgorithm: "Unknown",
                isLegacyFormat: false,
                needsConversion: false,
                issueDescription: "Not a valid PKCS#12 file"
            )
        }

        // Try to detect encryption algorithm from ASN.1 structure
        if let algorithm = detectEncryptionAlgorithm(data) {
            return analyzeAlgorithm(algorithm)
        }

        // Note: OpenSSL command-line inspection not available on iOS
        // We rely on binary OID detection instead

        // Default: assume modern format if we can't detect
        return CertificateFormatInfo(
            encryptionAlgorithm: "Unknown (assumed modern)",
            isLegacyFormat: false,
            needsConversion: true, // Try conversion if direct import fails
            issueDescription: "Could not determine encryption algorithm"
        )
    }

    // MARK: - PKCS#12 Validation

    private func isPKCS12(_ data: Data) -> Bool {
        // PKCS#12 files start with ASN.1 sequence tag (0x30)
        guard data.count > 2 else { return false }
        return data[0] == 0x30
    }

    // MARK: - Algorithm Detection (Binary Analysis)

    private func detectEncryptionAlgorithm(_ data: Data) -> String? {
        let hexString = data.map { String(format: "%02x", $0) }.joined()

        // Look for OID patterns in hex dump
        // RC2-40-CBC OID: 2a 86 48 86 f7 0d 01 05 06
        if hexString.contains("2a864886f70d010506") {
            return "RC2-40-CBC"
        }

        // RC2-CBC OID: 2a 86 48 86 f7 0d 03 02
        if hexString.contains("2a864886f70d0302") {
            return "RC2-CBC"
        }

        // 3DES-CBC OID: 2a 86 48 86 f7 0d 03 07
        if hexString.contains("2a864886f70d0307") {
            return "3DES-CBC"
        }

        // AES-256-CBC OID: 60 86 48 01 65 03 04 01 2a
        if hexString.contains("6086480165030401") {
            return "AES-256-CBC"
        }

        // AES-128-CBC OID: 60 86 48 01 65 03 04 01 02
        if hexString.contains("60864801650304010") {
            return "AES-128-CBC"
        }

        return nil
    }

    // MARK: - Algorithm Analysis

    private func analyzeAlgorithm(_ algorithm: String) -> CertificateFormatInfo {
        switch algorithm {
        case "RC2-40-CBC":
            return CertificateFormatInfo(
                encryptionAlgorithm: "RC2-40-CBC",
                isLegacyFormat: true,
                needsConversion: true,
                issueDescription: "Legacy export-grade encryption (1990s) - not supported by iOS Security framework"
            )

        case "RC2-CBC":
            return CertificateFormatInfo(
                encryptionAlgorithm: "RC2-CBC",
                isLegacyFormat: true,
                needsConversion: true,
                issueDescription: "Legacy RC2 encryption - limited iOS support"
            )

        case "3DES-CBC", "DES-EDE3-CBC":
            return CertificateFormatInfo(
                encryptionAlgorithm: "3DES-CBC",
                isLegacyFormat: false,
                needsConversion: false,
                issueDescription: "3DES encryption - compatible with iOS"
            )

        case "AES-128-CBC":
            return CertificateFormatInfo(
                encryptionAlgorithm: "AES-128-CBC",
                isLegacyFormat: false,
                needsConversion: false,
                issueDescription: "Modern AES-128 encryption - fully compatible"
            )

        case "AES-256-CBC":
            return CertificateFormatInfo(
                encryptionAlgorithm: "AES-256-CBC",
                isLegacyFormat: false,
                needsConversion: false,
                issueDescription: "Modern AES-256 encryption - fully compatible"
            )

        default:
            return CertificateFormatInfo(
                encryptionAlgorithm: algorithm,
                isLegacyFormat: false,
                needsConversion: true,
                issueDescription: "Unknown algorithm - conversion recommended"
            )
        }
    }
}
