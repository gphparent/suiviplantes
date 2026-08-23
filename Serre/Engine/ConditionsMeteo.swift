import Foundation

/// Un point horaire de prevision.
///
/// Volontairement reduit a ce dont les calculs ont besoin. Ce type appartient au
/// moteur, pas au service reseau : c'est ce qui permet de tester toute la
/// physique sans jamais ouvrir une connexion.
struct ConditionHoraire: Codable, Hashable, Sendable {
    let date: Date
    /// Temperature de l'air sous abri, a deux metres, en degres Celsius.
    let temperature: Double
    /// Point de rosee, en degres Celsius.
    let pointDeRosee: Double
    /// Couverture nuageuse totale, de 0 a 100.
    let nebulosite: Double
    /// Vent moyen a dix metres, en km/h.
    let vent: Double
    /// Rafale a dix metres, en km/h.
    let rafale: Double
    /// Precipitations de l'heure, en mm.
    let precipitation: Double

    init(date: Date, temperature: Double, pointDeRosee: Double,
         nebulosite: Double, vent: Double, rafale: Double, precipitation: Double = 0) {
        self.date = date
        self.temperature = temperature
        self.pointDeRosee = pointDeRosee
        self.nebulosite = nebulosite
        self.vent = vent
        self.rafale = rafale
        self.precipitation = precipitation
    }
}

/// Serie de previsions pour un lieu.
struct Previsions: Codable, Hashable, Sendable {
    let recupereesLe: Date
    let latitude: Double
    let longitude: Double
    let identifiantFuseau: String
    /// Serie horaire, triee par date croissante.
    let heures: [ConditionHoraire]
    /// Vrai lorsque la serie vient du cache faute de reseau.
    var horsLigne: Bool = false

    var fuseau: TimeZone { TimeZone(identifier: identifiantFuseau) ?? .current }

    func heures(de debut: Date, a fin: Date) -> [ConditionHoraire] {
        heures.filter { $0.date >= debut && $0.date <= fin }
    }

    func condition(a date: Date) -> ConditionHoraire? {
        heures.min { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }
    }
}
