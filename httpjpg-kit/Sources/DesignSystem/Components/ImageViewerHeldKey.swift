import SwiftUI

public struct ImageViewerHeldKey: PreferenceKey {
    public static var defaultValue = false

    public static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}
