import SwiftUI
import UIKit

@MainActor
final class OrientationCoordinator {
    static let shared = OrientationCoordinator()

    private(set) var supportedOrientations: UIInterfaceOrientationMask = CalculatorMode.standard.orientation.supportedOrientations
    private(set) var preferredOrientation: UIInterfaceOrientation = CalculatorMode.standard.orientation.targetOrientation
    private var requestedMode: CalculatorMode = .standard
    private var retryTask: DispatchWorkItem?

    private init() {}

    func apply(for mode: CalculatorMode) {
        requestedMode = mode
        supportedOrientations = mode.orientation.supportedOrientations
        preferredOrientation = mode.orientation.targetOrientation
        requestOrientationUpdate(for: mode)

        DispatchQueue.main.async { [supportedOrientations, preferredOrientation] in
            self.requestOrientationUpdate(
                supportedOrientations: supportedOrientations,
                targetOrientation: preferredOrientation
            )
        }

        scheduleVerification(for: mode, remainingAttempts: 6)
    }

    private func requestOrientationUpdate(for mode: CalculatorMode) {
        requestOrientationUpdate(
            supportedOrientations: mode.orientation.supportedOrientations,
            targetOrientation: mode.orientation.targetOrientation
        )
    }

    private func requestOrientationUpdate(
        supportedOrientations: UIInterfaceOrientationMask,
        targetOrientation: UIInterfaceOrientation
    ) {
        let windowScenes = activeWindowScenes()

        for windowScene in windowScenes {
            let rootViewController = windowScene.keyWindow?.rootViewController ?? windowScene.windows.first?.rootViewController
            rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
            rootViewController?.presentedViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()

            if #available(iOS 16.0, *) {
                let preferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: supportedOrientations)
                windowScene.requestGeometryUpdate(preferences) { _ in }
            }
        }

        UIDevice.current.setValue(targetOrientation.rawValue, forKey: "orientation")

        if #unavailable(iOS 16.0) {
            UIViewController.attemptRotationToDeviceOrientation()
        }
    }

    private func scheduleVerification(for mode: CalculatorMode, remainingAttempts: Int) {
        retryTask?.cancel()

        guard remainingAttempts > 0 else { return }

        let task = DispatchWorkItem { [weak self] in
            guard let self else { return }
            guard self.requestedMode == mode else { return }

            if self.activeWindowScenes().contains(where: { self.matches(mode.orientation, scene: $0) }) {
                return
            }

            self.requestOrientationUpdate(for: mode)
            self.scheduleVerification(for: mode, remainingAttempts: remainingAttempts - 1)
        }

        retryTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18, execute: task)
    }

    private func activeWindowScenes() -> [UIWindowScene] {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive || $0.activationState == .foregroundInactive }
    }

    private func matches(_ policy: CalculatorOrientationPolicy, scene: UIWindowScene) -> Bool {
        switch policy {
        case .portrait:
            return scene.interfaceOrientation.isPortrait
        case .landscape:
            return scene.interfaceOrientation.isLandscape
        }
    }
}
