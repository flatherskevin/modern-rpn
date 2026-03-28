import SwiftUI
import UIKit

@main
struct Modern_RPNApp: App {
    @UIApplicationDelegateAdaptor(OrientationLockingAppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

final class OrientationLockingAppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        OrientationCoordinator.shared.supportedOrientations
    }
}
