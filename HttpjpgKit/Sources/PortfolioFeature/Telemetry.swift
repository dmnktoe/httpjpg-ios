import Foundation
import TelemetryDeck

/// The app's whole analytics surface: three signals, no identifiers.
///
/// TelemetryDeck is the iOS stand-in for the web's Umami — privacy-first,
/// cookie-less, no fingerprinting, so it needs no consent banner (the web app
/// gates only the Google tracker behind consent for the same reason). Signals
/// carry a salted anonymous hash, never a user ID, and the app adds nothing
/// beyond the work slug being read.
///
/// Without a `TELEMETRYDECK_APP_ID` in the bundle — it comes through the
/// git-ignored `Secrets.xcconfig` — nothing initialises and every signal is a
/// no-op, so forks and local builds stay silent by default.
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
