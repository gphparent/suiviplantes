import Foundation

/// Correction du refroidissement nocturne par rayonnement.
///
/// C'est le calcul autour duquel l'application existe. Les previsions donnent
/// la temperature de l'air sous abri, a deux metres du sol, dans un boitier
/// ventile. Ce n'est pas ce que subit une plante posee sur une terrasse.
///
/// Par nuit degagee et sans vent, la surface rayonne vers le ciel bien plus
/// qu'elle ne recoit, une couche d'air froid s'installe au ras du sol, et
/// l'ecart avec l'abri atteint couramment trois a cinq degres. C'est la gelee
/// dite « au sol », ou « blanche » : la station annonce 3 degres et il gele
/// quand meme. Au Quebec, c'est ce qui tue les plantes en mai et en septembre,
/// et c'est precisement le cas qu'aucune application testee ne couvre.
///
/// Trois facteurs commandent l'ampleur du phenomene, et un quatrieme le freine.
///
/// **La nebulosite.** Les nuages renvoient vers le sol le rayonnement infrarouge
/// qu'il emet. Sous un ciel couvert, la perte nette est faible ; sous un ciel
/// degage, elle est maximale. La dependance est proche de la lineaire, avec un
/// coefficient d'environ 0,8 pour la nebulosite totale.
///
/// **Le vent.** Le brassage mecanique detruit l'inversion : l'air froid du sol
/// se melange a l'air plus doux au-dessus. Des trois metres par seconde, il n'y
/// a pratiquement plus de couche froide. La decroissance suit une loi en
/// puissance inverse, avec une vitesse caracteristique voisine de 1,5 m/s, soit
/// environ 5 km/h.
///
/// **L'assise.** Un pot n'a pas l'inertie du sol, et son support decide de ce
/// qu'il voit du ciel. Voir `Assise.facteurRadiatif`.
///
/// **Le point de rosee.** C'est le frein. Quand la temperature rejoint le point
/// de rosee, la vapeur se condense — puis se depose en givre — et la chaleur
/// latente ainsi liberee ralentit fortement la chute. Une nuit humide ne gele
/// presque jamais aussi fort que l'extrapolation le laisse croire. C'est la
/// regle de base de la prevision des gelees, et l'ignorer produit de fausses
/// alertes a repetition, qui sont la meilleure facon de faire desinstaller une
/// application d'alertes.
enum RefroidissementNocturne {

    /// Amplitude maximale de l'ecart entre l'abri et le niveau du sol, en
    /// degres, par nuit parfaitement degagee et parfaitement calme.
    static let amplitudeMaximale: Double = 4.5

    /// Vitesse de vent, en km/h, a laquelle le brassage a deja retire la moitie
    /// de l'inversion.
    static let ventCaracteristique: Double = 5.5

    /// Coefficient de contre-rayonnement des nuages. Un ciel totalement couvert
    /// conserve un cinquieme du refroidissement, pas zero.
    static let effetNuages: Double = 0.8

    /// Fraction du refroidissement qui subsiste une fois le point de rosee
    /// atteint.
    static let freinPointDeRosee: Double = 0.4

    /// Part du refroidissement conservee malgre les nuages, de 0,2 a 1.
    static func facteurCiel(nebulosite: Double) -> Double {
        let fraction = min(max(nebulosite, 0), 100) / 100
        return 1 - effetNuages * fraction
    }

    /// Part du refroidissement conservee malgre le vent, de 0 a 1.
    static func facteurVent(vent: Double) -> Double {
        let u = max(vent, 0)
        return 1 / (1 + pow(u / ventCaracteristique, 2))
    }

    /// Temperature reellement subie a l'endroit ou la plante est posee.
    ///
    /// - Parameters:
    ///   - condition: le point horaire le plus froid de la nuit.
    ///   - assise: la facon dont la plante est posee.
    /// - Returns: la temperature corrigee, toujours inferieure ou egale a celle
    ///   annoncee.
    static func temperatureAuSol(condition: ConditionHoraire, assise: Assise) -> Double {
        let brut = amplitudeMaximale
            * facteurCiel(nebulosite: condition.nebulosite)
            * facteurVent(vent: condition.vent)
            * assise.facteurRadiatif

        return appliquerFreinHumide(temperature: condition.temperature,
                                    pointDeRosee: condition.pointDeRosee,
                                    refroidissement: brut)
    }

    /// Ecart, en degres, entre la temperature annoncee et celle subie.
    static func ecart(condition: ConditionHoraire, assise: Assise) -> Double {
        condition.temperature - temperatureAuSol(condition: condition, assise: assise)
    }

    /// Applique le frein de la chaleur latente.
    ///
    /// Tant que la temperature reste au-dessus du point de rosee, la chute est
    /// libre. En dessous, la condensation puis le givre liberent de la chaleur
    /// et le refroidissement ne poursuit qu'a une fraction de son rythme.
    static func appliquerFreinHumide(temperature: Double,
                                     pointDeRosee: Double,
                                     refroidissement: Double) -> Double {
        guard refroidissement > 0 else { return temperature }

        // Un point de rosee superieur a la temperature n'a pas de sens
        // physique ; les series de prevision en produisent tout de meme, par
        // arrondi. On le ramene a la temperature plutot que de propager
        // l'incoherence.
        let rosee = min(pointDeRosee, temperature)
        let margeLibre = temperature - rosee

        if refroidissement <= margeLibre {
            return temperature - refroidissement
        }
        let reste = refroidissement - margeLibre
        return rosee - freinPointDeRosee * reste
    }

    /// Minimum de la nuit, corrige, sur une fenetre donnee.
    ///
    /// - Returns: `nil` si la fenetre ne contient aucune prevision.
    static func minimumNocturne(heures: [ConditionHoraire], assise: Assise) -> MinimumNocturne? {
        guard !heures.isEmpty else { return nil }

        var meilleur: MinimumNocturne?
        for heure in heures {
            let corrigee = temperatureAuSol(condition: heure, assise: assise)
            if meilleur == nil || corrigee < meilleur!.temperatureCorrigee {
                meilleur = MinimumNocturne(date: heure.date,
                                           temperatureAnnoncee: heure.temperature,
                                           temperatureCorrigee: corrigee,
                                           nebulosite: heure.nebulosite,
                                           vent: heure.vent,
                                           pointDeRosee: heure.pointDeRosee)
            }
        }
        return meilleur
    }

    /// Minimum de la nuit sans aucune correction : la temperature annoncee,
    /// telle quelle. Sert de point de comparaison, et de repli quand
    /// l'utilisateur desactive la correction.
    static func minimumBrut(heures: [ConditionHoraire]) -> MinimumNocturne? {
        guard let creux = heures.min(by: { $0.temperature < $1.temperature }) else { return nil }
        return MinimumNocturne(date: creux.date,
                               temperatureAnnoncee: creux.temperature,
                               temperatureCorrigee: creux.temperature,
                               nebulosite: creux.nebulosite,
                               vent: creux.vent,
                               pointDeRosee: creux.pointDeRosee)
    }
}

/// Le creux de la nuit, annonce et corrige.
struct MinimumNocturne: Hashable, Sendable {
    let date: Date
    /// Ce que la prevision annonce, sous abri, a deux metres.
    let temperatureAnnoncee: Double
    /// Ce que la plante subit reellement, a l'endroit ou elle est posee.
    let temperatureCorrigee: Double
    let nebulosite: Double
    let vent: Double
    let pointDeRosee: Double

    var ecart: Double { temperatureAnnoncee - temperatureCorrigee }

    /// Vrai quand les conditions sont celles d'une nuit de rayonnement franche :
    /// ciel degage et vent faible. C'est la nuit ou l'ecart est le plus grand,
    /// et celle qu'il faut expliquer a l'utilisateur.
    var nuitDeRayonnement: Bool { nebulosite < 40 && vent < 8 }

    /// Vrai quand l'humidite de l'air limite reellement la chute.
    var freineParHumidite: Bool { temperatureCorrigee <= pointDeRosee + 0.1 }
}
