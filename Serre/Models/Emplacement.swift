import Foundation

/// Ou la plante se trouve en ce moment.
///
/// C'est l'axe autour duquel tourne l'application : les autres applications de
/// soin traitent le lieu comme une etiquette figee, alors que le probleme reel
/// est un aller-retour saisonnier avec une periode de transition au milieu.
enum Emplacement: String, Codable, CaseIterable, Sendable, Identifiable {
    case interieur
    case acclimatation
    case exterieur

    var id: String { rawValue }

    var nom: String {
        switch self {
        case .interieur: return "A l'interieur"
        case .acclimatation: return "En acclimatation"
        case .exterieur: return "Dehors"
        }
    }

    var symbole: String {
        switch self {
        case .interieur: return "house"
        case .acclimatation: return "arrow.left.arrow.right"
        case .exterieur: return "sun.max"
        }
    }

    /// Une plante en acclimatation dort dehors seulement une fois la periode
    /// terminee ; tant qu'elle dure, elle rentre chaque soir.
    var passeLaNuitDehors: Bool { self == .exterieur }
}

/// Comment la plante est posee dehors. Determine a quel point elle subit le
/// refroidissement nocturne par rayonnement.
///
/// La distinction la plus importante est celle du pot : un pot n'a presque
/// aucune inertie thermique et offre ses parois a l'air libre de tous les
/// cotes. La motte gele a des temperatures que le sol, lui, n'atteint jamais.
enum Assise: String, Codable, CaseIterable, Sendable, Identifiable {
    /// Plante en pleine terre : le sol restitue sa chaleur toute la nuit.
    case pleineTerre
    /// Pot pose au sol : les racines perdent le benefice de l'inertie du sol.
    case potAuSol
    /// Pot sur une table, une rampe, un support : l'air circule dessous.
    case potSureleve
    /// Contre un mur de la maison, qui rayonne sa chaleur et masque une partie
    /// du ciel.
    case contreUnMur
    /// Sous un arbre, un auvent, une galerie : la voute celeste est masquee, et
    /// c'est elle qui refroidit.
    case abrite
    /// Chassis froid, garage non chauffe, cabanon, serre froide.
    case protege

    var id: String { rawValue }

    var nom: String {
        switch self {
        case .pleineTerre: return "En pleine terre"
        case .potAuSol: return "Pot au sol"
        case .potSureleve: return "Pot sureleve"
        case .contreUnMur: return "Contre un mur"
        case .abrite: return "Sous un abri"
        case .protege: return "Chassis froid ou garage"
        }
    }

    var explication: String {
        switch self {
        case .pleineTerre:
            return "Le sol restitue la nuit la chaleur emmagasinee le jour. Les racines sont a l'abri ; seul le feuillage subit le refroidissement."
        case .potAuSol:
            return "Un pot n'a presque aucune inertie thermique et perd de la chaleur par toutes ses parois. La motte descend plus bas que la terre du jardin."
        case .potSureleve:
            return "Pire encore qu'un pot au sol : l'air circule aussi par-dessous, et le contact avec la terre est rompu."
        case .contreUnMur:
            return "Le mur rayonne pendant la nuit ce qu'il a absorbe le jour, et masque une partie du ciel froid."
        case .abrite:
            return "Le refroidissement nocturne vient du ciel. Tout ce qui le masque, feuillage ou toiture, en retire une bonne part."
        case .protege:
            return "Volume ferme : le rayonnement vers le ciel est coupe, et l'air enferme conserve sa chaleur."
        }
    }

    /// Facteur applique a l'amplitude du refroidissement radiatif.
    ///
    /// Un pot ne refroidit pas l'air autour de lui davantage qu'un massif ; ce
    /// que ce facteur represente, c'est l'ecart entre la temperature de l'abri
    /// meteorologique, a deux metres, et celle que subit reellement la plante,
    /// motte comprise, a l'endroit ou elle est posee.
    var facteurRadiatif: Double {
        switch self {
        case .pleineTerre: return 1.00
        case .potAuSol: return 1.15
        case .potSureleve: return 1.25
        case .contreUnMur: return 0.60
        case .abrite: return 0.40
        case .protege: return 0.15
        }
    }

    /// Vrai lorsque la motte est exposee a l'air libre. Les racines sont
    /// nettement moins rustiques que les parties aeriennes : la regle
    /// horticole courante retire environ deux zones de rusticite a une plante
    /// cultivee en pot.
    var racinesExposees: Bool {
        switch self {
        case .potAuSol, .potSureleve: return true
        case .pleineTerre, .contreUnMur, .abrite, .protege: return false
        }
    }
}

/// A quel point l'endroit est degage face au vent.
enum ExpositionAuVent: String, Codable, CaseIterable, Sendable, Identifiable {
    case abritee
    case normale
    case exposee

    var id: String { rawValue }

    var nom: String {
        switch self {
        case .abritee: return "Abritee"
        case .normale: return "Normale"
        case .exposee: return "Tres exposee"
        }
    }

    var precision: String {
        switch self {
        case .abritee: return "Coin de cour, entre deux murs, derriere une haie"
        case .normale: return "Terrasse ou parterre ordinaire"
        case .exposee: return "Balcon en hauteur, bord de lac, champ ouvert"
        }
    }

    /// Multiplie la rafale annoncee pour la station, qui est mesuree a dix
    /// metres en terrain degage. Un fond de cour en recoit une fraction ; un
    /// balcon en etage peut en recevoir davantage par effet de couloir.
    var facteurRafale: Double {
        switch self {
        case .abritee: return 0.55
        case .normale: return 0.85
        case .exposee: return 1.15
        }
    }
}

/// Prise au vent de la plante : hauteur, largeur du feuillage, stabilite du
/// contenant.
enum PriseAuVent: String, Codable, CaseIterable, Sendable, Identifiable {
    /// Plante basse et large, ou pot lourd : rien ne bascule.
    case faible
    /// Format courant : un metre, un pot de terre cuite.
    case moyenne
    /// Haute et etroite, ou grandes feuilles qui font voile : bananier,
    /// colocasia, agrume sur tige, tomate tuteuree.
    case forte

    var id: String { rawValue }

    var nom: String {
        switch self {
        case .faible: return "Faible"
        case .moyenne: return "Moyenne"
        case .forte: return "Forte"
        }
    }

    var precision: String {
        switch self {
        case .faible: return "Basse et large, ou pot lourd et stable"
        case .moyenne: return "Hauteur d'environ un metre, pot ordinaire"
        case .forte: return "Haute et etroite, ou grandes feuilles qui font voile"
        }
    }

    /// Rafale, en km/h, a partir de laquelle il vaut mieux coucher le pot,
    /// l'attacher ou le rentrer. Mesuree a hauteur de plante, donc apres
    /// application du facteur d'exposition.
    var seuilRafale: Double {
        switch self {
        case .faible: return 75
        case .moyenne: return 50
        case .forte: return 35
        }
    }
}
