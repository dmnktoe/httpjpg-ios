import Foundation

public enum PixelImage {
    public static func data(fromDataURI uri: String?) -> Data? {
        guard let uri, uri.hasPrefix("data:image/"), let marker = uri.range(of: ";base64,") else {
            return nil
        }
        return Data(base64Encoded: String(uri[marker.upperBound...]))
    }
}
