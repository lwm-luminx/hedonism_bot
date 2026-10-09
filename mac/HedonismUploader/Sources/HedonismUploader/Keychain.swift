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
