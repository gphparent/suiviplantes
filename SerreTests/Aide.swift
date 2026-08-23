import Foundation
@testable import Serre

/// Fabriques communes aux suites de tests.
enum Aide {

    static var calendrierMontreal: Calendar {
        var calendrier = Calendar(identifier: .gregorian)
        calendrier.timeZone = TimeZone(identifier: "America/Montreal")!
        return calendrier
    }

    static func date(_ annee: Int, _ mois: Int, _ jour: Int,
                     _ heure: Int = 0, _ minute: Int = 0,
                     fuseau: String = "America/Montreal") -> Date {
        var composants = DateComponents()
        composants.year = annee; composants.month = mois; composants.day = jour
        composants.hour = heure; composants.minute = minute
        var calendrier = Calendar(identifier: .gregorian)
        calendrier.timeZone = TimeZone(identifier: fuseau)!
        return calendrier.date(from: composants)!
    }

    /// Un point horaire, avec des valeurs par defaut anodines.
    static func heure(_ date: Date,
                      temperature: Double,
                      pointDeRosee: Double = -20,
                      nebulosite: Double = 0,
                      vent: Double = 0,
                      rafale: Double = 0,
                      precipitation: Double = 0) -> ConditionHoraire {
        ConditionHoraire(date: date, temperature: temperature, pointDeRosee: pointDeRosee,
                         nebulosite: nebulosite, vent: vent, rafale: rafale,
                         precipitation: precipitation)
    }

    /// Une nuit entiere a temperature constante, de quinze heures a neuf heures.
    static func nuit(du jour: Date,
                     temperature: Double,
                     pointDeRosee: Double = -20,
                     nebulosite: Double = 0,
                     vent: Double = 0,
                     rafale: Double = 0,
                     precipitation: Double = 0,
                     calendrier: Calendar = calendrierMontreal) -> [ConditionHoraire] {
        let debut = calendrier.date(bySettingHour: 15, minute: 0, second: 0, of: jour)!
        return (0...18).map { decalage in
            heure(debut.addingTimeInterval(TimeInterval(decalage * 3600)),
                  temperature: temperature, pointDeRosee: pointDeRosee,
                  nebulosite: nebulosite, vent: vent, rafale: rafale,
                  precipitation: precipitation)
        }
    }

    static func previsions(heures: [ConditionHoraire],
                           fuseau: String = "America/Montreal") -> Previsions {
        Previsions(recupereesLe: Date(), latitude: 45.5, longitude: -73.57,
                   identifiantFuseau: fuseau, heures: heures)
    }

    static func plante(nom: String = "Sujet",
                       confort: Double = 10,
                       critique: Double = 2,
                       emplacement: Emplacement = .exterieur,
                       assise: Assise = .potAuSol,
                       exposition: ExpositionAuVent = .normale,
                       prise: PriseAuVent = .moyenne,
                       arrosageEte: Int = 4,
                       arrosageHiver: Int = 12,
                       dernierArrosage: Date? = nil,
                       demenagements: [Demenagement] = [],
                       acclimatation: Acclimatation? = nil) -> Plante {
        Plante(nom: nom,
               seuilConfort: confort,
               seuilCritique: critique,
               emplacement: emplacement,
               assise: assise,
               exposition: exposition,
               priseAuVent: prise,
               arrosageEte: arrosageEte,
               arrosageHiver: arrosageHiver,
               dernierArrosage: dernierArrosage,
               demenagements: demenagements,
               acclimatation: acclimatation)
    }
}
