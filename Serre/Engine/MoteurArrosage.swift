import Foundation

/// Etat d'arrosage d'une plante.
struct EtatArrosage: Hashable, Sendable {
    let planteID: UUID
    let nom: String
    let prochainArrosage: Date
    let intervalle: Int
    /// Negatif quand la plante est en retard.
    let joursRestants: Int
    /// Explication du calcul, montree a l'utilisateur.
    let raison: String

    var enRetard: Bool { joursRestants < 0 }
    var aujourdHui: Bool { joursRestants == 0 }
    var aArroser: Bool { joursRestants <= 0 }
}

/// Calcule quand arroser.
///
/// L'intervalle de base vient de l'espece, mais deux choses le deplacent, et
/// c'est la que les applications d'arrosage et les applications de meteo se
/// ratent mutuellement.
///
/// **Le demenagement.** Une plante rentree en octobre change completement de
/// regime : moins de lumiere, moins d'evaporation, croissance arretee. Elle boit
/// deux a trois fois moins. L'erreur classique de l'automne n'est pas d'oublier
/// d'arroser, c'est de continuer au rythme de l'ete et de pourrir les racines.
/// Aucune application de soin ne fait ce basculement automatiquement au moment
/// ou l'on deplace la plante, parce qu'aucune ne sait qu'on l'a deplacee.
///
/// **La pluie.** Une plante dehors qui vient de recevoir vingt millimetres n'a
/// besoin de rien. Une plante sous un auvent ne recoit rien, meme sous l'orage.
enum MoteurArrosage {

    /// Pluie, en millimetres sur les dernieres vingt-quatre heures, qui vaut un
    /// arrosage complet pour un pot laisse a decouvert.
    static let pluieEquivalente: Double = 15

    /// Intervalle de base selon l'emplacement et la saison.
    static func intervalle(plante: Plante, saison: Saison) -> Int {
        switch plante.emplacement {
        case .exterieur, .acclimatation:
            // Dehors, la plante pousse et l'air la seche : rythme d'ete.
            return plante.arrosageEte
        case .interieur:
            switch saison {
            case .croissance:
                return plante.arrosageEte
            case .repos:
                return plante.arrosageHiver
            }
        }
    }

    /// Correction liee a la chaleur et au vent des derniers jours.
    ///
    /// Une canicule raccourcit l'intervalle, une semaine fraiche l'allonge. Le
    /// facteur reste borne : le but est d'ajuster, pas de recalculer une
    /// evapotranspiration qu'on n'a pas les moyens de mesurer.
    static func facteurMeteo(heures: [ConditionHoraire]) -> Double {
        guard !heures.isEmpty else { return 1 }
        let temperatures = heures.map(\.temperature)
        let moyenne = temperatures.reduce(0, +) / Double(temperatures.count)
        let ventMoyen = heures.map(\.vent).reduce(0, +) / Double(heures.count)

        // Reference : vingt degres, vent faible.
        var facteur = 1.0
        facteur -= (moyenne - 20) * 0.02   // un degre de plus retire 2 %
        facteur -= (ventMoyen - 10) * 0.005
        return min(max(facteur, 0.6), 1.6)
    }

    /// Pluie utile recue par la plante, en millimetres.
    ///
    /// Une plante a l'interieur, sous un abri ou contre un mur ne recoit qu'une
    /// fraction de ce qui tombe.
    static func pluieRecue(plante: Plante, heures: [ConditionHoraire]) -> Double {
        guard plante.emplacement != .interieur else { return 0 }
        let totale = heures.map(\.precipitation).reduce(0, +)
        switch plante.assise {
        case .abrite, .protege: return 0
        case .contreUnMur: return totale * 0.5
        case .pleineTerre, .potAuSol, .potSureleve: return totale
        }
    }

    static func etat(plante: Plante,
                     saison: Saison,
                     heuresPassees: [ConditionHoraire] = [],
                     maintenant: Date = Date(),
                     calendrier: Calendar = .current) -> EtatArrosage {

        let base = intervalle(plante: plante, saison: saison)
        let facteur = facteurMeteo(heures: heuresPassees)
        let ajuste = max(1, Int((Double(base) * facteur).rounded()))

        var raison: String
        switch plante.emplacement {
        case .interieur where saison == .repos:
            raison = "Rythme d'hiver : moins de lumiere, croissance arretee."
        case .interieur:
            raison = "Rythme d'interieur en saison de croissance."
        case .exterieur, .acclimatation:
            raison = "Rythme d'exterieur."
        }
        if ajuste < base {
            raison += " Resserre par la chaleur des derniers jours."
        } else if ajuste > base {
            raison += " Espace par la fraicheur des derniers jours."
        }

        // Une bonne pluie remet le compteur a zero.
        let pluie = pluieRecue(plante: plante, heures: heuresPassees)
        var depart = plante.dernierArrosage ?? plante.ajouteeLe
        if pluie >= pluieEquivalente,
           let derniereHeurePluvieuse = heuresPassees.last(where: { $0.precipitation > 0 })?.date,
           derniereHeurePluvieuse > depart {
            depart = derniereHeurePluvieuse
            let arrondi = String(format: "%.0f", pluie)
            raison = "\(arrondi) mm de pluie recus : compteur remis a zero."
        }

        let prochain = calendrier.date(byAdding: .day, value: ajuste, to: depart) ?? depart
        let jours = calendrier.dateComponents([.day],
                                              from: calendrier.startOfDay(for: maintenant),
                                              to: calendrier.startOfDay(for: prochain)).day ?? 0

        return EtatArrosage(planteID: plante.id,
                            nom: plante.nom,
                            prochainArrosage: prochain,
                            intervalle: ajuste,
                            joursRestants: jours,
                            raison: raison)
    }

    static func etats(plantes: [Plante],
                      saison: Saison,
                      heuresPassees: [ConditionHoraire] = [],
                      maintenant: Date = Date(),
                      calendrier: Calendar = .current) -> [EtatArrosage] {
        plantes
            .map { etat(plante: $0, saison: saison, heuresPassees: heuresPassees,
                        maintenant: maintenant, calendrier: calendrier) }
            .sorted { $0.joursRestants < $1.joursRestants }
    }
}

/// Saison au sens vegetal, pas au sens du calendrier.
enum Saison: String, Codable, Sendable {
    case croissance
    case repos

    var nom: String {
        switch self {
        case .croissance: return "Croissance"
        case .repos: return "Repos"
        }
    }

    /// Determinee par la longueur du jour plutot que par la date : c'est la
    /// lumiere qui commande le repos vegetatif, et elle depend de la latitude.
    ///
    /// Le seuil de onze heures place la bascule vers la mi-octobre et la
    /// mi-fevrier a la latitude du Quebec meridional.
    static func courante(date: Date = Date(), latitude: Double,
                         calendrier: Calendar = .current) -> Saison {
        let jour = calendrier.ordinality(of: .day, in: .year, for: date) ?? 1
        let dureeDuJour = longueurDuJour(jourDeLAnnee: jour, latitude: latitude)
        return dureeDuJour >= 11 ? .croissance : .repos
    }

    /// Duree du jour en heures, formule de Brock, suffisante ici a une
    /// dizaine de minutes pres.
    static func longueurDuJour(jourDeLAnnee: Int, latitude: Double) -> Double {
        let phi = latitude * .pi / 180
        let theta = 0.2163108 + 2 * atan(0.9671396 * tan(0.00860 * Double(jourDeLAnnee - 186)))
        let declinaison = asin(0.39795 * cos(theta))
        let argument = (sin(0.8333 * .pi / 180) + sin(phi) * sin(declinaison))
            / (cos(phi) * cos(declinaison))
        let borne = min(max(argument, -1), 1)
        return 24 - (24 / .pi) * acos(borne)
    }
}
