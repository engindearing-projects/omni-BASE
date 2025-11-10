//
// PluginMain.swift
// My Plugin
//
// Main entry point for the plugin
//

import Foundation
import UIKit
import OmniTAKPluginSystem

/// Main plugin class
@objc public class PluginMain: NSObject, OmniTAKPlugin {

    public var manifest: PluginManifest {
        // Load manifest from bundle
        guard let manifestURL = Bundle(for: type(of: self)).url(forResource: "plugin", withExtension: "json"),
              let data = try? Data(contentsOf: manifestURL),
              let manifest = try? PluginManifest.parse(from: data) else {
            fatalError("Failed to load plugin manifest")
        }
        return manifest
    }

    private weak var context: PluginContext?
    private var cotHandler: MyCotHandler?
    private var uiProvider: MyUIProvider?

    public override init() {
        super.init()
    }

    public func initialize(context: PluginContext) throws {
        self.context = context
        context.logger.info("Plugin initializing...")

        // Initialize plugin components
        cotHandler = MyCotHandler(context: context)
        uiProvider = MyUIProvider(context: context)

        context.logger.info("Plugin initialized successfully")
    }

    public func activate() throws {
        guard let context = context else {
            throw PluginError.runtimeError("Context not available")
        }

        context.logger.info("Plugin activating...")

        // Register CoT handler if permission granted
        if context.permissions.has(.cotRead), let handler = cotHandler {
            let cotManager = try context.cotManager
            try cotManager?.registerHandler(handler)
            context.logger.info("CoT handler registered")
        }

        // Register UI provider if permission granted
        if context.permissions.has(.uiCreate), let provider = uiProvider {
            let uiManager = try context.uiManager
            try uiManager?.registerProvider(provider)
            context.logger.info("UI provider registered")
        }

        context.logger.info("Plugin activated successfully")
    }

    public func deactivate() throws {
        guard let context = context else {
            throw PluginError.runtimeError("Context not available")
        }

        context.logger.info("Plugin deactivating...")

        // Cleanup will be handled by the plugin system

        context.logger.info("Plugin deactivated")
    }

    public func cleanup() throws {
        guard let context = context else {
            throw PluginError.runtimeError("Context not available")
        }

        context.logger.info("Plugin cleaning up...")

        // Release resources
        cotHandler = nil
        uiProvider = nil
        self.context = nil

        context.logger.info("Plugin cleaned up")
    }
}

/// CoT message handler implementation
class MyCotHandler: CoTHandler {
    private weak var context: PluginContext?

    init(context: PluginContext) {
        self.context = context
    }

    func handleCoTMessage(_ message: CoTMessage) -> CoTHandlerResult {
        guard let context = context else { return .passthrough }

        context.logger.debug("Received CoT message: \(message.uid)")

        // Process CoT message
        // TODO: Add your CoT processing logic here

        // Return .processed to prevent further processing
        // Return .passthrough to let other handlers process
        // Return .blocked to prevent this message from being processed
        return .passthrough
    }
}

/// UI provider implementation
class MyUIProvider: UIProvider {
    private weak var context: PluginContext?

    init(context: PluginContext) {
        self.context = context
    }

    func createToolbarItem() -> UIView? {
        guard let context = context else { return nil }

        context.logger.debug("Creating toolbar item")

        // Create a simple button
        let button = UIButton(type: .system)
        button.setTitle("My Plugin", for: .normal)
        button.addTarget(self, action: #selector(toolbarButtonTapped), for: .touchUpInside)

        return button
    }

    func createPanel() -> UIViewController? {
        guard let context = context else { return nil }

        context.logger.debug("Creating panel")

        // Create a simple view controller
        let viewController = UIViewController()
        viewController.title = "My Plugin"
        viewController.view.backgroundColor = .systemBackground

        let label = UILabel()
        label.text = "Hello from My Plugin!"
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        viewController.view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: viewController.view.centerYAnchor)
        ])

        return viewController
    }

    func createSettingsView() -> UIView? {
        guard let context = context else { return nil }

        context.logger.debug("Creating settings view")

        // Create settings UI
        let view = UIView()
        view.backgroundColor = .systemBackground

        // TODO: Add your settings UI here

        return view
    }

    @objc private func toolbarButtonTapped() {
        guard let context = context else { return }
        context.logger.info("Toolbar button tapped")

        // Handle button tap
        // TODO: Add your button action here
    }
}
