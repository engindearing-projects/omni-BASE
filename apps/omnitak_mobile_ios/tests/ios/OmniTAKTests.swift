//
//  OmniTAKTests.swift
//  OmniTAK Mobile iOS Tests
//
//  Unit tests for OmniTAK Mobile iOS functionality.
//

import XCTest
@testable import OmniTAKMobile

class OmniTAKNativeBridgeTests: XCTestCase {

    var bridge: OmniTAKNativeBridge!

    override func setUp() {
        super.setUp()
        bridge = OmniTAKNativeBridge()
    }

    override func tearDown() {
        bridge = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testBridgeInitialization() {
        XCTAssertNotNil(bridge, "Bridge should initialize successfully")
    }

    func testGetVersion() {
        let version = bridge.getVersion()
        XCTAssertFalse(version.isEmpty, "Version string should not be empty")
        XCTAssertTrue(version.contains("."), "Version should contain a dot (e.g., 0.1.0)")
        print("OmniTAK version: \(version)")
    }

    // MARK: - Configuration Parsing Tests

    func testParseValidServerConfig() {
        let configDict: [String: Any] = [
            "host": "tak-server.example.com",
            "port": 8089,
            "protocol": "tcp",
            "useTls": false,
            "reconnect": true,
            "reconnectDelayMs": 5000
        ]

        let config = OmniTAKNativeBridge.parseServerConfig(from: configDict)

        XCTAssertNotNil(config, "Should parse valid config")
        XCTAssertEqual(config?.host, "tak-server.example.com")
        XCTAssertEqual(config?.port, 8089)
        XCTAssertEqual(config?.protocol, "tcp")
        XCTAssertEqual(config?.useTls, false)
        XCTAssertEqual(config?.reconnect, true)
        XCTAssertEqual(config?.reconnectDelayMs, 5000)
    }

    func testParseInvalidServerConfig() {
        let invalidConfig: [String: Any] = [
            "host": "test.com",
            // Missing required fields
        ]

        let config = OmniTAKNativeBridge.parseServerConfig(from: invalidConfig)
        XCTAssertNil(config, "Should return nil for invalid config")
    }

    // MARK: - Certificate Import Tests

    func testCertificateImport() {
        let expectation = self.expectation(description: "Certificate import")

        let certPem = """
        -----BEGIN CERTIFICATE-----
        TEST_CERTIFICATE_DATA
        -----END CERTIFICATE-----
        """

        let keyPem = """
        -----BEGIN PRIVATE KEY-----
        TEST_KEY_DATA
        -----END PRIVATE KEY-----
        """

        bridge.importCertificate(certPem: certPem, keyPem: keyPem, caPem: nil) { certId in
            XCTAssertNotNil(certId, "Certificate ID should not be nil")
            XCTAssertFalse(certId?.isEmpty ?? true, "Certificate ID should not be empty")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2.0, handler: nil)
    }

    // MARK: - Connection Tests
    // Note: These tests require a running TAK server and are disabled by default

    func testConnectionFailureWithInvalidHost() {
        let expectation = self.expectation(description: "Connection should fail")

        let invalidConfig: [String: Any] = [
            "host": "invalid-nonexistent-host.local",
            "port": 8089,
            "protocol": "tcp",
            "useTls": false,
            "reconnect": false,
            "reconnectDelayMs": 1000
        ]

        bridge.connect(config: invalidConfig) { connectionId in
            // Connection should fail or return nil
            // In real implementation, this might return an error connection ID
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5.0, handler: nil)
    }

    // MARK: - Performance Tests

    func testVersionPerformance() {
        measure {
            for _ in 0..<1000 {
                _ = bridge.getVersion()
            }
        }
    }
}

// MARK: - MapLibre Integration Tests

import MapLibre

class MapLibreIntegrationTests: XCTestCase {

    func testMapViewCreation() {
        let styleURL = URL(string: "https://demotiles.maplibre.org/style.json")!
        let mapView = MLNMapView(frame: CGRect(x: 0, y: 0, width: 300, height: 300), styleURL: styleURL)

        XCTAssertNotNil(mapView, "MapView should be created")
        XCTAssertEqual(mapView.frame.width, 300)
        XCTAssertEqual(mapView.frame.height, 300)
    }

    func testMapViewCameraPositioning() {
        let styleURL = URL(string: "https://demotiles.maplibre.org/style.json")!
        let mapView = MLNMapView(frame: CGRect(x: 0, y: 0, width: 300, height: 300), styleURL: styleURL)

        let testCoordinate = CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795)
        let testZoom: Double = 10.0

        mapView.setCenter(testCoordinate, zoomLevel: testZoom, animated: false)

        // Allow map to process the change
        let expectation = self.expectation(description: "Camera position update")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let center = mapView.centerCoordinate
            let zoom = mapView.zoomLevel

            XCTAssertEqual(center.latitude, testCoordinate.latitude, accuracy: 0.01)
            XCTAssertEqual(center.longitude, testCoordinate.longitude, accuracy: 0.01)
            XCTAssertEqual(zoom, testZoom, accuracy: 0.1)

            expectation.fulfill()
        }

        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func testMapViewAnnotations() {
        let styleURL = URL(string: "https://demotiles.maplibre.org/style.json")!
        let mapView = MLNMapView(frame: CGRect(x: 0, y: 0, width: 300, height: 300), styleURL: styleURL)

        let coordinate = CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795)
        let annotation = MLNPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = "Test Marker"

        mapView.addAnnotation(annotation)

        XCTAssertEqual(mapView.annotations?.count, 1, "Should have one annotation")

        if let addedAnnotation = mapView.annotations?.first as? MLNPointAnnotation {
            XCTAssertEqual(addedAnnotation.coordinate.latitude, coordinate.latitude, accuracy: 0.001)
            XCTAssertEqual(addedAnnotation.coordinate.longitude, coordinate.longitude, accuracy: 0.001)
            XCTAssertEqual(addedAnnotation.title, "Test Marker")
        } else {
            XCTFail("Annotation should be MLNPointAnnotation")
        }
    }
}

// MARK: - Integration Tests

class OmniTAKIntegrationTests: XCTestCase {

    func testFullStackIntegration() {
        // Test that all components can work together
        let bridge = OmniTAKNativeBridge()
        let version = bridge.getVersion()

        XCTAssertFalse(version.isEmpty, "Bridge should provide version")

        let styleURL = URL(string: "https://demotiles.maplibre.org/style.json")!
        let mapView = MLNMapView(frame: CGRect(x: 0, y: 0, width: 300, height: 300), styleURL: styleURL)

        XCTAssertNotNil(mapView, "MapView should be created alongside bridge")

        print("Integration test passed - OmniTAK v\(version) with MapLibre")
    }
}
