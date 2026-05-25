import SwiftUI
import UIKit

final class OrientationLockedHostingController<Content: View>: UIHostingController<Content> {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        OrientationCoordinator.shared.supportedOrientations
    }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        OrientationCoordinator.shared.preferredOrientation
    }

    override var shouldAutorotate: Bool {
        true
    }
}
