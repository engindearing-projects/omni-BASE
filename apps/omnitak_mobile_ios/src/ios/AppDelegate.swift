//
//  AppDelegate.swift
//  OmniTAK Mobile iOS
//
//  Main app delegate for OmniTAK Mobile iOS test app.
//  Integrates Valdi framework with MapLibre and OmniTAK native libraries.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Initialize window
        window = UIWindow(frame: UIScreen.main.bounds)

        // Create and set root view controller
        let rootViewController = ViewController()
        let navigationController = UINavigationController(rootViewController: rootViewController)

        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()

        // Log app launch
        print("[OmniTAK] Application launched successfully")
        print("[OmniTAK] iOS Version: \(UIDevice.current.systemVersion)")
        print("[OmniTAK] Device Model: \(UIDevice.current.model)")

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        print("[OmniTAK] Application will resign active")
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        print("[OmniTAK] Application did enter background")
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        print("[OmniTAK] Application will enter foreground")
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        print("[OmniTAK] Application did become active")
    }

    func applicationWillTerminate(_ application: UIApplication) {
        print("[OmniTAK] Application will terminate")
    }
}
