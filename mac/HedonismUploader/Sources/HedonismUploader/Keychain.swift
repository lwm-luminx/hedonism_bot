import Foundation
import Security

/// Stores the service account token in the login keychain.
enum Keychain {
    private static let service = "social.hotmess.hedonism-uploader"
    private static let account = "service-account-token"

    static func token() -> String? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess, let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func setToken(_ token: String?) {
        SecItemDelete(baseQuery as CFDictionary)
        guard let token, !token.isEmpty else { return }
        var item = baseQuery
        item[kSecValueData as String] = Data(token.utf8)
        SecItemAdd(item as CFDictionary, nil)
    }

    private static var baseQuery: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: account]
    }
}
