import Foundation
import Security

/// Stores the service account token in the login keychain.
enum Keychain {
    private static let service = "social.hotmess.hedonism-uploader"
    private static let account = "service-account-token"

    static func token(accountID: String = account) -> String? {
        var query = query(accountID)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess, let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func setToken(_ token: String?, accountID: String = account) -> Bool {
        let baseQuery = query(accountID)
        guard let token, !token.isEmpty else {
            let result = SecItemDelete(baseQuery as CFDictionary)
            return result == errSecSuccess || result == errSecItemNotFound
        }
        let data = Data(token.utf8)
        let result = SecItemUpdate(baseQuery as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        if result == errSecSuccess { return true }
        guard result == errSecItemNotFound else { return false }
        var item = baseQuery
        item[kSecValueData as String] = data
        item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        return SecItemAdd(item as CFDictionary, nil) == errSecSuccess
    }

    private static func query(_ accountID: String) -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: accountID]
    }
}

/// Photographer credentials shared by Chip (iPhone, iPad and Mac) and Cogsworth through the
/// `host.lumiere.shared` keychain access group. Items sync with iCloud Keychain, so signing in to
/// one Lumière app on any of the person's devices signs the other apps in too; signing out of one
/// removes the shared credential everywhere.
enum SharedCredentials {
    struct Credential: Equatable {
        let server: URL
        let subdomain: String
        let name: String
        let token: String
    }

    static let accessGroup = "DWVXMLB45Y.host.lumiere.shared"
    private static let service = "host.lumiere.photographer-credential"

    static func all() -> [Credential] {
        var query = baseQuery()
        query[kSecMatchLimit as String] = kSecMatchLimitAll
        query[kSecReturnAttributes as String] = true
        query[kSecReturnData as String] = true
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let items = result as? [[String: Any]] else { return [] }
        return items.compactMap { item in
            guard let key = item[kSecAttrAccount as String] as? String,
                  let separator = key.lastIndex(of: "|"),
                  let server = URL(string: String(key[..<separator])),
                  let data = item[kSecValueData as String] as? Data,
                  let token = String(data: data, encoding: .utf8), !token.isEmpty else { return nil }
            return Credential(server: server, subdomain: String(key[key.index(after: separator)...]),
                              name: item[kSecAttrLabel as String] as? String ?? "", token: token)
        }
    }

    /// Saves or replaces the credential for this server and photographer. Returns false when the app
    /// isn't signed with the shared group (unsigned test builds); the app's own keychain still works.
    @discardableResult
    static func save(_ credential: Credential) -> Bool {
        var query = baseQuery()
        query[kSecAttrAccount as String] = key(server: credential.server, subdomain: credential.subdomain)
        let update: [String: Any] = [kSecValueData as String: Data(credential.token.utf8), kSecAttrLabel as String: credential.name]
        let result = SecItemUpdate(query as CFDictionary, update as CFDictionary)
        if result == errSecSuccess { return true }
        guard result == errSecItemNotFound else { return false }
        query.merge(update) { $1 }
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    /// Removes every shared credential carrying this token (the one a sign-out revokes).
    static func remove(token: String) {
        for credential in all() where credential.token == token {
            var query = baseQuery()
            query[kSecAttrAccount as String] = key(server: credential.server, subdomain: credential.subdomain)
            SecItemDelete(query as CFDictionary)
        }
    }

    private static func key(server: URL, subdomain: String) -> String {
        "\(server.absoluteString)|\(subdomain)"
    }

    private static func baseQuery() -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service,
         kSecAttrAccessGroup as String: accessGroup,
         kSecAttrSynchronizable as String: kCFBooleanTrue!,
         kSecUseDataProtectionKeychain as String: true]
    }
}
