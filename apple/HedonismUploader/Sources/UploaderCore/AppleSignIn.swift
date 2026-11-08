import CryptoKit
import Foundation
import Security

/// Sign in with Apple against hedonism_bot. The app shows Apple's button with `nonce.hashed` as the
/// request nonce, then hands the identity token and `nonce.raw` to the server, which checks Apple's
/// signature, the app's bundle ID and the nonce before issuing a photographer credential.
public enum AppleSignIn {
    public struct Nonce: Sendable {
        public let raw: String
        public var hashed: String { SHA256.hash(data: Data(raw.utf8)).map { String(format: "%02x", $0) }.joined() }

        public init() {
            var bytes = [UInt8](repeating: 0, count: 32)
            if SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes) != errSecSuccess {
                bytes = (0..<32).map { _ in UInt8.random(in: .min ... .max) }
            }
            raw = Data(bytes).base64EncodedString()
        }
    }

    /// Exchanges an Apple identity token for a credential for `photographer`. Returns the bearer token.
    public static func signIn(server: URL, photographer: String, identityToken: Data, nonce: Nonce) async throws -> String {
        let json = try await post(server.appendingPathComponent("auth/apple/exchange"), body: [
            "identity_token": String(decoding: identityToken, as: UTF8.self),
            "nonce": nonce.raw,
            "photographer": photographer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
        ], expecting: 200)
        guard let token = json["token"] as? String else {
            throw HedonismClientError.unexpectedResponse("Could not complete Sign in with Apple")
        }
        return token
    }

    /// Links the Apple ID to the person behind an existing credential, so it can sign in on its own later.
    public static func link(server: URL, credential: String, identityToken: Data, nonce: Nonce) async throws {
        _ = try await post(server.appendingPathComponent("auth/apple/link"), body: [
            "identity_token": String(decoding: identityToken, as: UTF8.self),
            "nonce": nonce.raw,
        ], bearer: credential, expecting: 204)
    }

    private static func post(_ url: URL, body: [String: String], bearer: String? = nil, expecting status: Int) async throws -> [String: Any] {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let bearer { request.setValue("Bearer \(bearer)", forHTTPHeaderField: "Authorization") }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let response = response as? HTTPURLResponse else {
            throw HedonismClientError.unexpectedResponse("Could not reach the sign-in server")
        }
        let json = (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
        guard response.statusCode == status else {
            throw HedonismClientError.unexpectedResponse(json["error"] as? String ?? "Sign in with Apple failed. Please try again.")
        }
        return json
    }
}
