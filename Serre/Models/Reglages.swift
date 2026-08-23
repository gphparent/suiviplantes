import Foundation

/// Zones de rusticite du Quebec, telles que definies par Ressources naturelles
/// Canada. Elles servent de repere pour les dates normales de gel, quand les
/// previsions ne portent pas encore assez loin.
enum ZoneRusticite: String, Codable, CaseIterable, Sendable, Identifiable {
    case z2b = "2b"
    case z3a = "3a"
    case z3b = "3b"
    case z4a = "4a"
    case z4b = "4b"
    case z5a = "5a"
    case z5b = "5b"

    var id: String { rawValue }

    var nom: String { "Zone \(rawValue)" }

    var exemples: String {
        switch self {
        case .z2b: return "Chibougamau, Fermont"
        case .z3a: return "Val-d'Or, Saguenay"
        case .z3b: return "Rimouski, La Tuque"
        case .z4a: return "Mont-Laurier, Sept-Iles"
        case .z4b: return "Quebec, Sherbrooke, Trois-Rivieres"
        case .z5a: return "Gatineau, Saint-Jerome, Joliette"
        case .z5b: return "Montreal, Laval, Longueuil"
        }
    }

    /// Date normale du dernier gel printanier, en jour de l'annee.
    /// Moyennes des normales climatiques ; l'ecart d'une annee a l'autre est
    /// large, ce qui est exactement pourquoi l'application prefere les
    /// previsions reelles quand elle en a.
    var dernierGelPrintemps: DateComponents {
        switch self {
        case .z2b: return DateComponents(month: 6, day: 15)
        case .z3a: return DateComponents(month: 6, day: 8)
        case .z3b: return DateComponents(month: 6, day: 1)
        case .z4a: return DateComponents(month: 5, day: 25)
        case .z4b: return DateComponents(month: 5, day: 18)
        case .z5a: return DateComponents(month: 5, day: 12)
        case .z5b: return DateComponents(month: 5, day: 5)
        }
    }

    /// Date normale du premier gel automnal.
    var premierGelAutomne: DateComponents {
        switch self {
        case .z2b: return DateComponents(month: 9, day: 5)
        case .z3a: return DateComponents(month: 9, day: 12)
        case .z3b: return DateComponents(month: 9, day: 20)
        case .z4a: return DateComponents(month: 9, day: 26)
        case .z4b: return DateComponents(month: 10, day: 1)
        case .z5a: return DateComponents(month: 10, day: 6)
        case .z5b: return DateComponents(month: 10, day: 12)
        }
    }
}

/// Preferences de l'utilisateur.
struct Reglages: Codable, Hashable, Sendable {

    /// Heure de l'alerte d'action, celle qui dit quoi rentrer ce soir.
    ///
    /// Quinze heures, et non vingt et une : le but est de prevenir pendant
    /// qu'il fait encore clair et qu'on a le temps de porter six pots, pas de
    /// reveiller quelqu'un au moment ou le mal est fait.
    var heureAlerteSoir: Int
    var minuteAlerteSoir: Int

    /// Heure du bilan du matin, qui dit ce qui peut ressortir.
    var heureBilanMatin: Int
    var minuteBilanMatin: Int

    var zone: ZoneRusticite

    /// Applique la correction de refroidissement radiatif. Desactivable pour
    /// comparer avec la temperature brute annoncee.
    var correctionRadiative: Bool

    /// Avertit aussi pour le seuil de confort, pas seulement pour le critique.
    var alerterAuConfort: Bool

    /// Avertit des coups de vent.
    var alerterAuVent: Bool

    /// Marge de securite ajoutee au seuil de chaque plante, en degres.
    var margeSecurite: Double

    static let defaut = Reglages(
        heureAlerteSoir: 15, minuteAlerteSoir: 0,
        heureBilanMatin: 8, minuteBilanMatin: 0,
        zone: .z5a,
        correctionRadiative: true,
        alerterAuConfort: true,
        alerterAuVent: true,
        margeSecurite: 1.0)
}

/// Un lieu resolu, avec ses coordonnees et son nom lisible.
struct Lieu: Codable, Hashable, Sendable {
    var latitude: Double
    var longitude: Double
    var nom: String?
    var identifiantFuseau: String?

    var fuseau: TimeZone {
        guard let identifiantFuseau, let zone = TimeZone(identifier: identifiantFuseau) else {
            return .current
        }
        return zone
    }

    /// Coordonnees arrondies au centieme de degre, soit environ un kilometre.
    /// C'est ce qui part vers le service meteo : assez precis pour la
    /// prevision, trop grossier pour designer une adresse.
    var arrondi: (latitude: Double, longitude: Double) {
        ((latitude * 100).rounded() / 100, (longitude * 100).rounded() / 100)
    }

    static let montreal = Lieu(latitude: 45.5019, longitude: -73.5674,
                               nom: "Montreal", identifiantFuseau: "America/Montreal")
}
