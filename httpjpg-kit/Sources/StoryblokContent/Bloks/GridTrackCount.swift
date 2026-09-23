import SwiftUI

enum GridTrackCountKey: EnvironmentKey {
    static let defaultValue = 1
}

extension EnvironmentValues {
    var gridTrackCount: Int {
        get { self[GridTrackCountKey.self] }
        set { self[GridTrackCountKey.self] = newValue }
    }
}
