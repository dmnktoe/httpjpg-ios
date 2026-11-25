import Foundation

/// Footer media arrives as pixel art: the site shrinks every image to a grid of
/// CSS pixels and sends it inline as a `data:` PNG. Anything else (an address
/// from an older deploy, a cleared field) is left out rather than fetched, so
/// every surface shows exactly what the web footer shows.
public enum PixelImage {
    public static func data(fromDataURI uri: String?) -> Data? {
        guard let uri, uri.hasPrefix("data:image/"), let marker = uri.range(of: ";base64,") else {
            return nil
        }
        return Data(base64Encoded: String(uri[marker.upperBound...]))
    }
}
