import Foundation
import Security

enum WebSubscriptionIdentity {
    private static let service = "com.wavevibro.web-subscription"
    // Keep the previous Keychain namespace as a read-only migration source so
    // existing Stripe subscribers retain their installation identity.
    private static let legacyService = "com.vibromate.web-subscription"
    private static let account = "app-user-id"

    static var appUserId: String {
        if let existing = read(service: service) {
            return existing
        }

        if let migrated = read(service: legacyService) {
            save(migrated, service: service)
            return migrated
        }

        let created = UUID().uuidString.lowercased()
        save(created, service: service)
        return created
    }

    private static func read(service: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data,
              let value = String(data: data, encoding: .utf8),
              !value.isEmpty
        else {
            return nil
        }

        return value
    }

    private static func save(_ value: String, service: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var item = query
            item[kSecValueData as String] = data
            item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
            SecItemAdd(item as CFDictionary, nil)
        }
    }
}
