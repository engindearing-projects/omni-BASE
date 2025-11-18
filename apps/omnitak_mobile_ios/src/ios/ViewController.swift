//
//  ViewController.swift
//  OmniTAK Mobile iOS
//
//  Main view controller for testing OmniTAK Mobile functionality.
//  Demonstrates MapLibre integration and TAK server connectivity.
//

import UIKit
import MapLibre

class ViewController: UIViewController {

    // MARK: - Properties

    private var mapView: MLNMapView!
    private var statusLabel: UILabel!
    private var connectButton: UIButton!
    private var enrollButton: UIButton!
    private var testButton: UIButton!

    private var omnitakBridge: OmniTAKNativeBridge?
    private var currentConnectionId: Int?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "OmniTAK Mobile"
        view.backgroundColor = .systemBackground

        setupUI()
        setupOmniTAK()

        print("[OmniTAK] ViewController loaded")
    }

    // MARK: - UI Setup

    private func setupUI() {
        // Create MapLibre map view
        let mapURL = URL(string: "https://demotiles.maplibre.org/style.json")!
        mapView = MLNMapView(frame: view.bounds, styleURL: mapURL)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.delegate = self

        // Set initial camera position (centered on US)
        mapView.setCenter(
            CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795),
            zoomLevel: 4,
            animated: false
        )

        view.addSubview(mapView)

        // Create status label
        statusLabel = UILabel()
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        statusLabel.textColor = .white
        statusLabel.font = .systemFont(ofSize: 12)
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.text = "Initializing..."
        view.addSubview(statusLabel)

        // Create connect button
        connectButton = createButton(title: "Connect to TAK Server", action: #selector(connectButtonTapped))
        view.addSubview(connectButton)

        // Create enroll button
        enrollButton = createButton(title: "Enroll with TAK Server", action: #selector(enrollButtonTapped))
        enrollButton.backgroundColor = .systemGreen
        view.addSubview(enrollButton)

        // Create test button
        testButton = createButton(title: "Send Test CoT", action: #selector(testButtonTapped))
        testButton.isEnabled = false
        view.addSubview(testButton)

        // Layout constraints
        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            statusLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 60),

            connectButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            connectButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            connectButton.bottomAnchor.constraint(equalTo: enrollButton.topAnchor, constant: -12),
            connectButton.heightAnchor.constraint(equalToConstant: 50),

            enrollButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            enrollButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            enrollButton.bottomAnchor.constraint(equalTo: testButton.topAnchor, constant: -12),
            enrollButton.heightAnchor.constraint(equalToConstant: 50),

            testButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            testButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            testButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            testButton.heightAnchor.constraint(equalToConstant: 50),
        ])
    }

    private func createButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 16)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    // MARK: - OmniTAK Setup

    private func setupOmniTAK() {
        omnitakBridge = OmniTAKNativeBridge()

        let version = omnitakBridge?.getVersion() ?? "Unknown"
        updateStatus("OmniTAK v\(version)\nReady to connect")

        print("[OmniTAK] Native bridge initialized, version: \(version)")
    }

    // MARK: - Actions

    @objc private func connectButtonTapped() {
        guard let bridge = omnitakBridge else {
            updateStatus("Error: Bridge not initialized")
            return
        }

        // Check if already connected
        if currentConnectionId != nil {
            disconnect()
            return
        }

        updateStatus("Connecting to TAK server...")
        connectButton.isEnabled = false

        // Example TAK server configuration
        // For testing, you'll need to update these values
        let config: [String: Any] = [
            "host": "tak-server.example.com", // Update with your TAK server
            "port": 8089,
            "protocol": "tcp",
            "useTls": false,
            "reconnect": true,
            "reconnectDelayMs": 5000
        ]

        bridge.connect(config: config) { [weak self] connectionId in
            DispatchQueue.main.async {
                guard let self = self else { return }

                if let connId = connectionId {
                    self.currentConnectionId = connId.intValue
                    self.updateStatus("Connected! ID: \(connId)")
                    self.connectButton.setTitle("Disconnect", for: .normal)
                    self.connectButton.backgroundColor = .systemRed
                    self.testButton.isEnabled = true

                    // Register callback for incoming CoT
                    bridge.registerCotCallback(connectionId: connId.intValue) { cotXml in
                        print("[OmniTAK] Received CoT: \(cotXml)")
                        // Handle incoming CoT messages here
                        // You could parse and display on map
                    }

                    print("[OmniTAK] Connected successfully, ID: \(connId)")
                } else {
                    self.updateStatus("Connection failed")
                    print("[OmniTAK] Connection failed")
                }

                self.connectButton.isEnabled = true
            }
        }
    }

    @objc private func enrollButtonTapped() {
        // Show enrollment dialog
        let alert = UIAlertController(title: "Enroll with TAK Server", message: "Enter your credentials to obtain a certificate", preferredStyle: .alert)

        alert.addTextField { textField in
            textField.placeholder = "Server URL (https://...)"
            textField.text = "https://tak-server.example.com:8443"
            textField.keyboardType = .URL
        }

        alert.addTextField { textField in
            textField.placeholder = "Username"
            textField.autocapitalizationType = .none
        }

        alert.addTextField { textField in
            textField.placeholder = "Password"
            textField.isSecureTextEntry = true
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        alert.addAction(UIAlertAction(title: "Enroll", style: .default) { [weak self] _ in
            guard let self = self,
                  let bridge = self.omnitakBridge,
                  let serverUrl = alert.textFields?[0].text,
                  let username = alert.textFields?[1].text,
                  let password = alert.textFields?[2].text,
                  !serverUrl.isEmpty, !username.isEmpty, !password.isEmpty else {
                self?.updateStatus("Invalid enrollment credentials")
                return
            }

            self.updateStatus("Enrolling with \(serverUrl)...")
            self.enrollButton.isEnabled = false

            bridge.enrollCertificate(
                serverUrl: serverUrl,
                username: username,
                password: password,
                validityDays: 365
            ) { [weak self] certId, error in
                DispatchQueue.main.async {
                    guard let self = self else { return }

                    self.enrollButton.isEnabled = true

                    if let certId = certId {
                        self.updateStatus("Enrollment successful! Certificate ID: \(certId)")
                        print("[OmniTAK] Enrollment successful, cert ID: \(certId)")

                        // Show success alert
                        let successAlert = UIAlertController(
                            title: "Enrollment Successful",
                            message: "Certificate obtained and saved. You can now connect with TLS using this certificate.",
                            preferredStyle: .alert
                        )
                        successAlert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(successAlert, animated: true)
                    } else {
                        let errorMsg = error ?? "Unknown error"
                        self.updateStatus("Enrollment failed: \(errorMsg)")
                        print("[OmniTAK] Enrollment failed: \(errorMsg)")

                        // Show error alert
                        let errorAlert = UIAlertController(
                            title: "Enrollment Failed",
                            message: errorMsg,
                            preferredStyle: .alert
                        )
                        errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(errorAlert, animated: true)
                    }
                }
            }
        })

        present(alert, animated: true)
    }

    @objc private func testButtonTapped() {
        guard let bridge = omnitakBridge,
              let connId = currentConnectionId else {
            updateStatus("Error: Not connected")
            return
        }

        // Create a simple test CoT message
        let cotXml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <event version="2.0" uid="test-\(UUID().uuidString)" type="a-f-G-E-S" time="\(ISO8601DateFormatter().string(from: Date()))" start="\(ISO8601DateFormatter().string(from: Date()))" stale="\(ISO8601DateFormatter().string(from: Date().addingTimeInterval(300)))" how="m-g">
            <point lat="39.8283" lon="-98.5795" hae="0" ce="9999999" le="9999999"/>
            <detail>
                <contact callsign="TEST-IOS"/>
            </detail>
        </event>
        """

        updateStatus("Sending test CoT...")

        bridge.sendCot(connectionId: connId, cotXml: cotXml) { [weak self] success in
            DispatchQueue.main.async {
                guard let self = self else { return }

                if success {
                    self.updateStatus("Test CoT sent successfully!")
                    print("[OmniTAK] Test CoT sent successfully")
                } else {
                    self.updateStatus("Failed to send CoT")
                    print("[OmniTAK] Failed to send test CoT")
                }
            }
        }
    }

    private func disconnect() {
        guard let bridge = omnitakBridge,
              let connId = currentConnectionId else { return }

        updateStatus("Disconnecting...")

        bridge.disconnect(connectionId: connId) { [weak self] in
            DispatchQueue.main.async {
                guard let self = self else { return }

                self.currentConnectionId = nil
                self.updateStatus("Disconnected")
                self.connectButton.setTitle("Connect to TAK Server", for: .normal)
                self.connectButton.backgroundColor = .systemBlue
                self.testButton.isEnabled = false

                print("[OmniTAK] Disconnected")
            }
        }
    }

    // MARK: - Helpers

    private func updateStatus(_ message: String) {
        DispatchQueue.main.async {
            self.statusLabel.text = message
        }
    }
}

// MARK: - MLNMapViewDelegate

extension ViewController: MLNMapViewDelegate {

    func mapView(_ mapView: MLNMapView, didFinishLoading style: MLNStyle) {
        print("[MapLibre] Map style loaded successfully")
    }

    func mapView(_ mapView: MLNMapView, regionDidChangeAnimated animated: Bool) {
        let center = mapView.centerCoordinate
        let zoom = mapView.zoomLevel
        print("[MapLibre] Camera changed - Lat: \(center.latitude), Lon: \(center.longitude), Zoom: \(zoom)")
    }
}
