import Foundation
import TelemetryDeck

enum Telemetry {
    private static var isEnabled = false

    static func start() {
        guard let appID = Bundle.main.object(forInfoDictionaryKey: "TELEMETRYDECK_APP_ID") as? String,
              !appID.isEmpty
        else { return }
        TelemetryDeck.initialize(config: .init(appID: appID))
        isEnabled = true
    }

    static func signal(_ name: String, parameters: [String: String] = [:]) {
        guard isEnabled else { return }
        TelemetryDeck.signal(name, parameters: parameters)
    }
}
