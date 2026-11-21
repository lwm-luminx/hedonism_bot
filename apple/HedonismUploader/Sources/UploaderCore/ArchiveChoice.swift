import Foundation

/// An archive (photographer) the signed-in person administers.
public struct ArchiveOption: Identifiable, Hashable, Sendable {
    public let subdomain: String
    public let name: String
    public var id: String { subdomain }

    public init(subdomain: String, name: String) {
        self.subdomain = subdomain
        self.name = name
    }
}

/// What a Facebook or Apple sign-in returns. People who administer one archive get its credential
/// straight away; people with several pick one, then the app calls `ArchiveChoice.choose`.
public enum SignInOutcome: Sendable {
    case credential(String)
    case chooseArchive(selection: String, archives: [ArchiveOption])

    /// Reads the server's sign-in JSON: `{ token }`, or `{ selection, photographers: [{ subdomain, name }] }`.
    public init(json: [String: Any]) throws {
        if let token = json["token"] as? String, !token.isEmpty {
            self = .credential(token)
        } else if let selection = json["selection"] as? String,
                  let list = json["photographers"] as? [[String: Any]] {
            let archives = list.compactMap { item -> ArchiveOption? in
                guard let subdomain = item["subdomain"] as? String else { return nil }
                return ArchiveOption(subdomain: subdomain, name: item["name"] as? String ?? subdomain)
            }
            guard !archives.isEmpty else { throw HedonismClientError.unexpectedResponse("No archives to sign in to") }
            self = .chooseArchive(selection: selection, archives: archives)
        } else {
            throw HedonismClientError.unexpectedResponse(json["error"] as? String ?? "Could not complete sign-in")
        }
    }
}

/// A sign-in that is waiting for the person to pick one of their archives.
public struct PendingArchiveChoice: Sendable {
    public let server: URL
    public let selection: String
    public let archives: [ArchiveOption]

    public init(server: URL, selection: String, archives: [ArchiveOption]) {
        self.server = server
        self.selection = selection
        self.archives = archives
    }
}

public enum ArchiveChoice {
    /// Exchanges the selection from a sign-in for a credential for the chosen archive.
    public static func choose(server: URL, selection: String, subdomain: String) async throws -> String {
        var request = URLRequest(url: server.appendingPathComponent("auth/archives/select"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["selection": selection, "photographer": subdomain])
        let (data, response) = try await URLSession.shared.data(for: request)
        let json = (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
        guard (response as? HTTPURLResponse)?.statusCode == 200, let token = json["token"] as? String else {
            throw HedonismClientError.unexpectedResponse(json["error"] as? String ?? "Could not open that archive. Sign in again.")
        }
        return token
    }

    /// Redeems the one-time code from a browser (Facebook) sign-in with its PKCE verifier.
    public static func exchangeBrowserCode(server: URL, code: String, verifier: String) async throws -> SignInOutcome {
        var request = URLRequest(url: server.appendingPathComponent("auth/native/exchange"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["code": code, "verifier": verifier])
        let (data, response) = try await URLSession.shared.data(for: request)
        let json = (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw HedonismClientError.unexpectedResponse(json["error"] as? String ?? "Sign-in exchange failed")
        }
        return try SignInOutcome(json: json)
    }
}
