import Foundation
import Observation

/// Low Power Mode as something a view can observe. `ProcessInfo` only posts a
/// notification, and autoplay decisions are taken while a view body is being
/// evaluated.
///
/// Deliberately not actor-isolated: the flag is also read from the escaping
/// closures the carousel takes. Only the main queue ever writes it.
@Observable
public final class LowPowerMode: @unchecked Sendable {
    public static let shared = LowPowerMode()

    public private(set) var isEnabled: Bool

    @ObservationIgnored private var observer: NSObjectProtocol?

    private init() {
        isEnabled = ProcessInfo.processInfo.isLowPowerModeEnabled

        observer = NotificationCenter.default.addObserver(
            forName: .NSProcessInfoPowerStateDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isEnabled = ProcessInfo.processInfo.isLowPowerModeEnabled
        }
    }
}
