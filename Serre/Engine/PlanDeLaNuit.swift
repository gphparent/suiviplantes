import Foundation

/// Ce qu'il y a a faire ce soir, et ce qui peut ressortir demain.
///
/// C'est la boucle que rien d'autre ne ferme. Les applications d'alertes disent
/// « il va geler » ; les applications de soin disent « cette plante est
/// dehors ». Aucune ne sait que les six pots rentres hier soir attendent
/// quelque part pres de la porte, et qu'il faut les ressortir ce matin.
struct PlanDeLaNuit: Sendable {
    let nuit: DateInterval
    /// Le creux de la nuit pour un point de reference en pleine terre, qui sert
    /// a annoncer la nuit en un chiffre.
    let minimumReference: MinimumNocturne?
    /// Plantes qu'il faut rentrer ou proteger ce soir.
    let aRentrer: [EvaluationGel]
    /// Plantes a garder a l'oeil sans geste obligatoire.
    let aSurveiller: [EvaluationGel]
    /// Risques de vent, pour les plantes qui restent dehors.
    let vent: [EvaluationVent]
    /// Plantes rentrees a cause de la meteo, que la nuit qui vient permet de
    /// ressortir.
    let aRessortir: [PlanteARessortir]
    /// Etapes d'acclimatation du jour.
    let acclimatations: [EtapeDuJour]

    var demandeUnGeste: Bool { !aRentrer.isEmpty || vent.contains { $0.niveau.exigeUnGeste } }
    var estCalme: Bool {
        aRentrer.isEmpty && aRessortir.isEmpty && vent.isEmpty && acclimatations.isEmpty
    }

    struct PlanteARessortir: Hashable, Sendable {
        let planteID: UUID
        let nom: String
        let rentreeLe: Date
        let motif: Demenagement.Motif
        let minimumAttendu: Double
    }

    struct EtapeDuJour: Hashable, Sendable {
        let planteID: UUID
        let nom: String
        let jour: Int
        let etape: EtapeAcclimatation?
        let raisonDuReport: String?

        var favorable: Bool { etape != nil && raisonDuReport == nil }
    }
}

enum MoteurPlan {

    /// Bornes de la nuit : du milieu de l'apres-midi au milieu de la matinee
    /// suivante. La fenetre commence tot exprès, pour que l'alerte de quinze
    /// heures porte deja sur la bonne nuit.
    static let debutNuit = 15
    static let finNuit = 9

    /// Fenetre de la nuit qui suit une date donnee.
    ///
    /// Avant neuf heures du matin, la « nuit qui vient » est encore celle qui
    /// est en cours : quelqu'un qui ouvre l'application a six heures veut
    /// savoir ce qui se passe maintenant, pas ce soir.
    static func fenetreNocturne(pour date: Date,
                                calendrier: Calendar) -> DateInterval {
        let cal = calendrier
        let heure = cal.component(.hour, from: date)
        let jourDeReference = heure < finNuit
            ? cal.date(byAdding: .day, value: -1, to: date) ?? date
            : date

        let debut = cal.date(bySettingHour: debutNuit, minute: 0, second: 0,
                             of: jourDeReference) ?? jourDeReference
        let lendemain = cal.date(byAdding: .day, value: 1, to: jourDeReference) ?? jourDeReference
        let fin = cal.date(bySettingHour: finNuit, minute: 0, second: 0,
                           of: lendemain) ?? lendemain
        return DateInterval(start: debut, end: max(fin, debut.addingTimeInterval(3600)))
    }

    /// Fenetre de la journee en cours, pour l'acclimatation.
    static func fenetreDiurne(pour date: Date, calendrier: Calendar) -> DateInterval {
        let debut = calendrier.date(bySettingHour: 7, minute: 0, second: 0, of: date) ?? date
        let fin = calendrier.date(bySettingHour: 19, minute: 0, second: 0, of: date) ?? date
        return DateInterval(start: debut, end: max(fin, debut.addingTimeInterval(3600)))
    }

    static func construire(plantes: [Plante],
                           previsions: Previsions,
                           reglages: Reglages,
                           maintenant: Date = Date(),
                           calendrier: Calendar? = nil) -> PlanDeLaNuit {

        var cal = calendrier ?? Calendar.current
        if calendrier == nil { cal.timeZone = previsions.fuseau }

        let nuit = fenetreNocturne(pour: maintenant, calendrier: cal)
        let heuresNuit = previsions.heures(de: nuit.start, a: nuit.end)
        let jour = fenetreDiurne(pour: maintenant, calendrier: cal)
        let heuresJour = previsions.heures(de: jour.start, a: jour.end)

        let reference = RefroidissementNocturne.minimumNocturne(heures: heuresNuit,
                                                                assise: .pleineTerre)

        let evaluations = MoteurGel.evaluer(plantes: plantes,
                                            heures: heuresNuit,
                                            reglages: reglages)
        let aRentrer = evaluations.filter { $0.niveau.exigeUnGeste }
        let seuilSurveillance: NiveauRisque = reglages.alerterAuConfort ? .surveiller : .inconfort
        let aSurveiller = evaluations.filter {
            !$0.niveau.exigeUnGeste && $0.niveau >= seuilSurveillance
        }

        let vent = reglages.alerterAuVent
            ? MoteurVent.evaluer(plantes: plantes, heures: heuresNuit)
            : []

        let aRessortir = candidatsAuRetour(plantes: plantes,
                                           heuresNuit: heuresNuit,
                                           marge: reglages.margeSecurite)

        let acclimatations = etapesDuJour(plantes: plantes, heuresJour: heuresJour,
                                          calendrier: cal, maintenant: maintenant)

        return PlanDeLaNuit(nuit: nuit,
                            minimumReference: reference,
                            aRentrer: aRentrer,
                            aSurveiller: aSurveiller,
                            vent: vent,
                            aRessortir: aRessortir,
                            acclimatations: acclimatations)
    }

    /// Plantes rentrees pour cause de meteo, que la nuit qui vient permet de
    /// ressortir.
    ///
    /// Une plante rentree pour l'hiver, elle, n'est pas candidate : le motif du
    /// dernier demenagement fait la difference entre « mise a l'abri pour une
    /// nuit » et « rangee jusqu'au printemps ».
    static func candidatsAuRetour(plantes: [Plante],
                                  heuresNuit: [ConditionHoraire],
                                  marge: Double) -> [PlanDeLaNuit.PlanteARessortir] {
        plantes.compactMap { plante -> PlanDeLaNuit.PlanteARessortir? in
            guard plante.emplacement == .interieur,
                  let dernier = plante.demenagements.max(by: { $0.date < $1.date }),
                  dernier.sens == .rentree,
                  dernier.motif == .gel || dernier.motif == .vent || dernier.motif == .chaleur,
                  MoteurGel.peutRessortir(plante: plante, heures: heuresNuit, marge: marge),
                  let minimum = RefroidissementNocturne.minimumNocturne(heures: heuresNuit,
                                                                        assise: plante.assise)
            else { return nil }

            return PlanDeLaNuit.PlanteARessortir(planteID: plante.id,
                                                 nom: plante.nom,
                                                 rentreeLe: dernier.date,
                                                 motif: dernier.motif,
                                                 minimumAttendu: minimum.temperatureCorrigee)
        }
    }

    static func etapesDuJour(plantes: [Plante],
                             heuresJour: [ConditionHoraire],
                             calendrier: Calendar,
                             maintenant: Date) -> [PlanDeLaNuit.EtapeDuJour] {
        plantes.compactMap { plante -> PlanDeLaNuit.EtapeDuJour? in
            guard let acclimatation = plante.acclimatation, !acclimatation.termine else { return nil }
            guard !acclimatation.valideeAujourdhui(calendrier: calendrier, maintenant: maintenant)
            else { return nil }

            switch MoteurAcclimatation.verdict(plante: plante,
                                               acclimatation: acclimatation,
                                               heuresDuJour: heuresJour) {
            case .allezY(let etape):
                return PlanDeLaNuit.EtapeDuJour(planteID: plante.id, nom: plante.nom,
                                                jour: acclimatation.jourCourant,
                                                etape: etape, raisonDuReport: nil)
            case .reporte(let raison):
                return PlanDeLaNuit.EtapeDuJour(planteID: plante.id, nom: plante.nom,
                                                jour: acclimatation.jourCourant,
                                                etape: MoteurAcclimatation.etape(jour: acclimatation.jourCourant),
                                                raisonDuReport: raison)
            case .termine:
                return nil
            }
        }
    }
}
