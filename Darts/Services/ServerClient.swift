import Foundation
import UIKit

enum ServerError: Error, LocalizedError {
    case badImage
    case network(String)
    case http(Int)
    case decode(String)

    var errorDescription: String? {
        switch self {
        case .badImage:           return "Bild konnte nicht aufbereitet werden."
        case .network(let m):     return "Verbindungsfehler: \(m)"
        case .http(let c):        return "Server-Fehler (HTTP \(c))."
        case .decode(let m):      return "Antwort konnte nicht gelesen werden: \(m)"
        }
    }
}

/// Multipart-Upload an `/upload` (siehe CptFrechdachsRpt/V4_Server.py).
final class ServerClient {

    static let shared = ServerClient()
    private init() {}

    /// Production-URL des deployten DartVision-Servers.
    private let endpoint = URL(string: "https://chris-hesse.com/upload")!

    /// Sendet ein Bild + optionale Keypoints. Liefert das dekodierte `ServerResponse` zurück.
    func upload(image: UIImage, keypoints: Keypoints?) async throws -> ServerResponse {
        guard let jpegData = image.jpegData(compressionQuality: 0.85) else {
            throw ServerError.badImage
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // Keypoints als JSON-String (oder leeres Objekt für Erstkalibrierung)
        let kpJSON: String
        if let kp = keypoints,
           let data = try? JSONSerialization.data(withJSONObject: kp.asDict),
           let s = String(data: data, encoding: .utf8) {
            kpJSON = s
        } else {
            kpJSON = "{}"
        }
        body.appendFormField(name: "keypoints", value: kpJSON, boundary: boundary)

        // Bild
        body.appendFileField(name: "file", filename: "dart.jpg", mimeType: "image/jpeg",
                             data: jpegData, boundary: boundary)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw ServerError.network(error.localizedDescription)
        }

        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
            throw ServerError.http(http.statusCode)
        }

        do {
            return try JSONDecoder().decode(ServerResponse.self, from: data)
        } catch {
            throw ServerError.decode(error.localizedDescription)
        }
    }
}

private extension Data {
    mutating func appendFormField(name: String, value: String, boundary: String) {
        append("--\(boundary)\r\n".data(using: .utf8)!)
        append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
        append(value.data(using: .utf8)!)
        append("\r\n".data(using: .utf8)!)
    }
    mutating func appendFileField(name: String, filename: String, mimeType: String,
                                  data: Data, boundary: String) {
        append("--\(boundary)\r\n".data(using: .utf8)!)
        append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        append(data)
        append("\r\n".data(using: .utf8)!)
    }
}
