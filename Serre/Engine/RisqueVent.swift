import Foundation

/// Evaluation du vent pour une plante.
///
/// Les alertes meteo publiques parlent de la station : elles annoncent une
/// rafale a dix metres, en terrain degage. Ce qui compte pour un pot, c'est la
/// rafale a l'endroit ou il est pose, et le rapport entre cette rafale et sa
/// prise au vent. Un pot bas et lourd dans un fond de cour ignore ce qui
/// renverse un bananier sur un balcon d'etage.
struct EvaluationVent: Hashable, Sendable {
    let planteID: UUID
    let nom: String
    let niveau: NiveauRisque
    /// Rafale annoncee pour la station, en km/h.
    let rafaleAnnoncee: Double
    /// Rafale estimee a l'endroit de la plante, en km/h.
    let rafaleSurPlace: Double
    let seuil: Double
    let quand: Date

    var geste: String {
        switch niveau {
        case .critique, .danger:
            return "Coucher le pot, l'attacher, ou le rentrer"
        case .inconfort:
            return "Deplacer contre un mur ou baisser le pot"
        case .surveiller:
            return "Verifier que rien ne peut basculer"
        case .aucun:
            return "Rien a faire"
        }
    }
}

enum MoteurVent {

    /// Vent a partir duquel les grandes feuilles se dechirent, quelle que soit
    /// la stabilite du pot. Bananier, colocasia, ricin, hosta de grande taille.
    static let seuilDechirure: Double = 40

    static func evaluer(plante: Plante, heures: [ConditionHoraire]) -> EvaluationVent? {
        guard let pire = heures.max(by: { $0.rafale < $1.rafale }) else { return nil }

        let facteur = plante.exposition.facteurRafale
        let surPlace = pire.rafale * facteur
        var seuil = plante.seuilRafale

        // Une plante en pleine terre ne bascule pas ; seul son feuillage souffre.
        if plante.assise == .pleineTerre {
            seuil = max(seuil, seuilDechirure)
        }
        // Un pot couche ou range ne risque plus rien.
        if plante.assise == .protege {
            return nil
        }

        let rapport = surPlace / seuil
        let niveau: NiveauRisque
        if rapport >= 1.3 {
            niveau = .critique
        } else if rapport >= 1.0 {
            niveau = .danger
        } else if rapport >= 0.8 {
            niveau = .inconfort
        } else if rapport >= 0.6 {
            niveau = .surveiller
        } else {
            niveau = .aucun
        }

        return EvaluationVent(planteID: plante.id,
                              nom: plante.nom,
                              niveau: niveau,
                              rafaleAnnoncee: pire.rafale,
                              rafaleSurPlace: surPlace,
                              seuil: seuil,
                              quand: pire.date)
    }

    static func evaluer(plantes: [Plante], heures: [ConditionHoraire]) -> [EvaluationVent] {
        plantes
            .filter { $0.estDehors || $0.emplacement == .acclimatation }
            .compactMap { evaluer(plante: $0, heures: heures) }
            .filter { $0.niveau > .aucun }
            .sorted { $0.niveau > $1.niveau }
    }
}
