import Foundation

/// Public service endpoints shared by the desktop and mobile clients.
public enum ServiceEndpoints {
    public static let api = URL(string: "https://api.lumiere.host")!

    public static func photographerSite(subdomain: String) -> URL? {
        guard subdomain.range(of: "^[a-z0-9]+(?:-[a-z0-9]+)*$", options: .regularExpression) != nil,
              !["api", "www"].contains(subdomain) else { return nil }
        return URL(string: "https://\(subdomain).lumiere.host")
    }
}
