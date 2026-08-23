import Foundation

/// Gravite d'un risque de froid pour une plante donnee.
enum NiveauRisque: Int, Codable, Comparable, Sendable, CaseIterable {
    case aucun = 0
    case surveiller = 1
    case inconfort = 2
    case danger = 3
    case critique = 4

    static func < (gauche: NiveauRisque, droite: NiveauRisque) -> Bool {
        gauche.rawValue < droite.rawValue
    }

    var nom: String {
        switch self {
        case .aucun: return "Rien a signaler"
        case .surveiller: return "A surveiller"
        case .inconfort: return "Inconfort"
        case .danger: return "Danger"
        case .critique: return "Critique"
        }
    }

    var symbole: String {
        switch self {
        case .aucun: return "checkmark.circle"
        case .surveiller: return "eye"
        case .inconfort: return "thermometer.medium"
        case .danger: return "exclamationmark.triangle"
        case .critique: return "exclamationmark.octagon"
        }
    }

    /// Vrai a partir du moment ou il faut vraiment se lever et aller porter le
    /// pot.
    var exigeUnGeste: Bool { self >= .danger }
}

/// Evaluation du froid pour une plante, une nuit donnee.
struct EvaluationGel: Hashable, Sendable {
    let planteID: UUID
    let nom: String
    let niveau: NiveauRisque
    let minimum: MinimumNocturne
    let seuilConfort: Double
    let seuilCritique: Double

    /// Marge restante avant le seuil critique, en degres. Negative quand il est
    /// franchi.
    var margeAvantCritique: Double { minimum.temperatureCorrigee - seuilCritique }

    var geleeAttendue: Bool { minimum.temperatureCorrigee <= 0 }
}

/// Confronte une nuit de prevision aux seuils de chaque plante.
enum MoteurGel {

    /// Evalue une plante pour une nuit.
    ///
    /// - Parameters:
    ///   - plante: la plante a evaluer.
    ///   - heures: les points horaires de la nuit consideree.
    ///   - marge: marge de securite ajoutee aux deux seuils, en degres.
    ///   - correctionRadiative: quand elle est fausse, on compare a la
    ///     temperature brute annoncee, ce qui permet de montrer la difference.
    static func evaluer(plante: Plante,
                        heures: [ConditionHoraire],
                        marge: Double = 1.0,
                        correctionRadiative: Bool = true) -> EvaluationGel? {

        let minimumOptionnel = correctionRadiative
            ? RefroidissementNocturne.minimumNocturne(heures: heures, assise: plante.assise)
            : RefroidissementNocturne.minimumBrut(heures: heures)
        guard let minimum = minimumOptionnel else { return nil }

        let critique = plante.seuilCritiqueEffectif + marge
        let confort = plante.seuilConfort + marge
        let subie = minimum.temperatureCorrigee

        let niveau: NiveauRisque
        if subie <= critique {
            niveau = .critique
        } else if subie <= critique + 2 {
            niveau = .danger
        } else if subie <= confort {
            niveau = .inconfort
        } else if subie <= confort + 3 {
            niveau = .surveiller
        } else {
            niveau = .aucun
        }

        return EvaluationGel(planteID: plante.id,
                             nom: plante.nom,
                             niveau: niveau,
                             minimum: minimum,
                             seuilConfort: plante.seuilConfort,
                             seuilCritique: plante.seuilCritiqueEffectif)
    }

    /// Evalue toutes les plantes qui dorment dehors, du plus grave au moins
    /// grave.
    static func evaluer(plantes: [Plante],
                        heures: [ConditionHoraire],
                        reglages: Reglages) -> [EvaluationGel] {
        plantes
            .filter { $0.dortDehorsCetteNuit }
            .compactMap {
                evaluer(plante: $0,
                        heures: heures,
                        marge: reglages.margeSecurite,
                        correctionRadiative: reglages.correctionRadiative)
            }
            .sorted { gauche, droite in
                if gauche.niveau != droite.niveau { return gauche.niveau > droite.niveau }
                return gauche.margeAvantCritique < droite.margeAvantCritique
            }
    }

    /// Vrai quand la nuit permet de ressortir une plante rentree la veille.
    ///
    /// On exige une marge nette au-dessus du seuil de confort, pour eviter le
    /// va-et-vient quotidien : sortir puis rentrer une plante deux jours de
    /// suite lui coute plus cher que de la laisser a l'interieur.
    static func peutRessortir(plante: Plante,
                              heures: [ConditionHoraire],
                              marge: Double = 1.0) -> Bool {
        guard let minimum = RefroidissementNocturne.minimumNocturne(heures: heures,
                                                                    assise: plante.assise) else {
            return false
        }
        return minimum.temperatureCorrigee > plante.seuilConfort + marge + 2
    }
}
