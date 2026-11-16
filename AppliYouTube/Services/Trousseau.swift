import Foundation
import Security

/// La cle d'API Anthropic vit dans le trousseau de l'appareil, jamais dans le
/// depot : il est public.
enum Trousseau {

    private static let service = "ca.appliyoutube"
    private static let compte = "anthropic"

    static func lire() -> String? {
        let requete: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: compte,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var resultat: AnyObject?
        guard SecItemCopyMatching(requete as CFDictionary, &resultat) == errSecSuccess,
              let donnees = resultat as? Data else { return nil }
        return String(data: donnees, encoding: .utf8)
    }

    static func ecrire(_ cle: String) {
        effacer()
        let attributs: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: compte,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            kSecValueData as String: Data(cle.utf8),
        ]
        SecItemAdd(attributs as CFDictionary, nil)
    }

    static func effacer() {
        let requete: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: compte,
        ]
        SecItemDelete(requete as CFDictionary)
    }
}
