import Foundation

/// Une plante suivie, avec ses seuils, sa position du moment et son historique.
struct Plante: Codable, Hashable, Sendable, Identifiable {
    var id: UUID
    var nom: String
    /// Identifiant du catalogue, s'il vient de la. Une plante saisie a la main
    /// n'en a pas.
    var especeID: String?
    var nomLatin: String?
    var categorie: Categorie

    // MARK: Seuils, en degres Celsius

    /// En dessous, la plante souffre sans mourir. C'est le seuil qui declenche
    /// l'avertissement doux, celui qui laisse le choix.
    var seuilConfort: Double
    /// En dessous, les degats sont graves. C'est le seuil qui declenche
    /// l'alerte d'action.
    var seuilCritique: Double

    // MARK: Position

    var emplacement: Emplacement
    var assise: Assise
    var exposition: ExpositionAuVent
    var priseAuVent: PriseAuVent

    // MARK: Arrosage

    /// Jours entre deux arrosages en pleine croissance.
    var arrosageEte: Int
    /// Jours entre deux arrosages a l'interieur, en hiver.
    var arrosageHiver: Int
    var dernierArrosage: Date?

    // MARK: Suivi

    var demenagements: [Demenagement]
    var acclimatation: Acclimatation?
    var notes: String
    var ajouteeLe: Date

    init(id: UUID = UUID(),
         nom: String,
         especeID: String? = nil,
         nomLatin: String? = nil,
         categorie: Categorie = .tropicale,
         seuilConfort: Double,
         seuilCritique: Double,
         emplacement: Emplacement = .interieur,
         assise: Assise = .potAuSol,
         exposition: ExpositionAuVent = .normale,
         priseAuVent: PriseAuVent = .moyenne,
         arrosageEte: Int = 5,
         arrosageHiver: Int = 12,
         dernierArrosage: Date? = nil,
         demenagements: [Demenagement] = [],
         acclimatation: Acclimatation? = nil,
         notes: String = "",
         ajouteeLe: Date = Date()) {
        self.id = id
        self.nom = nom
        self.especeID = especeID
        self.nomLatin = nomLatin
        self.categorie = categorie
        self.seuilConfort = seuilConfort
        self.seuilCritique = seuilCritique
        self.emplacement = emplacement
        self.assise = assise
        self.exposition = exposition
        self.priseAuVent = priseAuVent
        self.arrosageEte = arrosageEte
        self.arrosageHiver = arrosageHiver
        self.dernierArrosage = dernierArrosage
        self.demenagements = demenagements
        self.acclimatation = acclimatation
        self.notes = notes
        self.ajouteeLe = ajouteeLe
    }

    /// Cree une plante a partir d'une espece du catalogue.
    init(espece: Espece, nom: String? = nil, emplacement: Emplacement = .interieur) {
        self.init(nom: nom ?? espece.nom,
                  especeID: espece.id,
                  nomLatin: espece.nomLatin,
                  categorie: espece.categorie,
                  seuilConfort: espece.seuilConfort,
                  seuilCritique: espece.seuilCritique,
                  emplacement: emplacement,
                  priseAuVent: espece.priseAuVent,
                  arrosageEte: espece.arrosageEte,
                  arrosageHiver: espece.arrosageHiver)
    }

    /// Seuil critique corrige pour les racines.
    ///
    /// La regle horticole courante retire environ deux zones de rusticite a une
    /// plante cultivee en pot, ce qui represente a peu pres cinq degres. Elle ne
    /// s'applique qu'aux plantes dont la motte est reellement a l'air libre, et
    /// seulement a celles qui ont une reserve de rusticite : une tropicale qui
    /// meurt deja a 4 degres n'a rien de plus a perdre.
    var seuilCritiqueEffectif: Double {
        guard assise.racinesExposees, seuilCritique < 0 else { return seuilCritique }
        return seuilCritique + 5
    }

    /// Rafale, a hauteur de plante, au-dela de laquelle il faut agir.
    var seuilRafale: Double { priseAuVent.seuilRafale }

    var estDehors: Bool { emplacement == .exterieur }

    /// Vrai si la plante dort dehors cette nuit. Une plante en acclimatation
    /// rentre chaque soir jusqu'a la fin de la periode.
    var dortDehorsCetteNuit: Bool {
        switch emplacement {
        case .exterieur: return true
        case .interieur: return false
        case .acclimatation: return acclimatation?.nuitDehors ?? false
        }
    }
}

/// Un passage de l'interieur vers l'exterieur, ou l'inverse.
///
/// C'est l'evenement que les autres applications ne modelisent pas : elles ont
/// un champ « lieu » qu'on ecrase, sans trace de la transition ni de ce qui
/// doit l'accompagner.
struct Demenagement: Codable, Hashable, Sendable, Identifiable {
    enum Sens: String, Codable, Sendable {
        case sortie
        case rentree

        var nom: String {
            switch self {
            case .sortie: return "Sortie"
            case .rentree: return "Rentree"
            }
        }
    }

    enum Motif: String, Codable, Sendable {
        case saison
        case gel
        case vent
        case chaleur
        case manuel

        var nom: String {
            switch self {
            case .saison: return "Changement de saison"
            case .gel: return "Risque de gel"
            case .vent: return "Coup de vent"
            case .chaleur: return "Chaleur excessive"
            case .manuel: return "Decision manuelle"
            }
        }
    }

    var id: UUID
    var date: Date
    var sens: Sens
    var motif: Motif
    /// Temperature qui a motive le geste, quand il y en a une.
    var temperature: Double?

    init(id: UUID = UUID(), date: Date = Date(), sens: Sens,
         motif: Motif = .manuel, temperature: Double? = nil) {
        self.id = id
        self.date = date
        self.sens = sens
        self.motif = motif
        self.temperature = temperature
    }
}
