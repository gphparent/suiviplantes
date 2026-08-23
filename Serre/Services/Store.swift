import Foundation

/// Persistance locale. Le volume est minuscule et strictement prive : quelques
/// dizaines de plantes, leurs seuils et leur journal. Un fichier JSON dans le
/// conteneur de l'application suffit, sans base de donnees ni compte ni
/// synchronisation.
struct Store {

    enum Cle: String {
        case plantes = "plantes.v1"
        case reglages = "reglages.v1"
        case lieuManuel = "lieu.manuel.v1"
        case dernieresPrevisions = "previsions.cache.v1"
    }

    private let defaults: UserDefaults
    private let encodeur = JSONEncoder()
    private let decodeur = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func charger<T: Decodable>(_ type: T.Type, pour cle: Cle) -> T? {
        guard let donnees = defaults.data(forKey: cle.rawValue) else { return nil }
        return try? decodeur.decode(T.self, from: donnees)
    }

    func enregistrer<T: Encodable>(_ valeur: T, pour cle: Cle) {
        guard let donnees = try? encodeur.encode(valeur) else { return }
        defaults.set(donnees, forKey: cle.rawValue)
    }

    func retirer(_ cle: Cle) {
        defaults.removeObject(forKey: cle.rawValue)
    }
}
