import Foundation

/// Une etape du programme d'acclimatation.
struct EtapeAcclimatation: Hashable, Sendable {
    let jour: Int
    /// Duree dehors, en heures.
    let heures: Double
    let lumiere: Lumiere
    /// Vrai a partir du moment ou la plante peut passer la nuit dehors.
    let nuitDehors: Bool
    let consigne: String

    enum Lumiere: String, Codable, Sendable {
        case ombre
        case miOmbre
        case soleilDuMatin
        case pleinSoleil

        var nom: String {
            switch self {
            case .ombre: return "Ombre complete"
            case .miOmbre: return "Mi-ombre"
            case .soleilDuMatin: return "Soleil du matin"
            case .pleinSoleil: return "Plein soleil"
            }
        }
    }
}

/// Programme d'acclimatation en cours pour une plante.
///
/// Une plante qui a passe l'hiver dedans, sous une lumiere cent fois plus faible
/// qu'au dehors, brule en une apres-midi si on la pose au soleil. La sortie se
/// fait par paliers, sur une a deux semaines. C'est un savoir horticole
/// elementaire, present dans les applications de semis potager, et absent de
/// toutes les applications de soin des plantes en pot.
///
/// Une journee ne compte que si la meteo l'a permise : un jour de pluie battante
/// ou de grand vent ne fait pas progresser le programme, il le suspend.
struct Acclimatation: Codable, Hashable, Sendable {
    var dateDebut: Date
    /// Nombre de journees reellement effectuees.
    var joursValides: Int
    /// Jour ou la derniere etape a ete validee, pour ne pas en compter deux le
    /// meme jour.
    var derniereValidation: Date?
    /// Sens du programme : sortir au printemps ou rentrer a l'automne.
    var sens: Demenagement.Sens

    init(dateDebut: Date = Date(), joursValides: Int = 0,
         derniereValidation: Date? = nil, sens: Demenagement.Sens = .sortie) {
        self.dateDebut = dateDebut
        self.joursValides = joursValides
        self.derniereValidation = derniereValidation
        self.sens = sens
    }

    /// Le programme complet fait dix etapes.
    static let duree = 10

    var jourCourant: Int { min(joursValides + 1, Self.duree) }
    var termine: Bool { joursValides >= Self.duree }
    var progression: Double { Double(joursValides) / Double(Self.duree) }

    /// Vrai si la plante peut deja passer la nuit dehors.
    var nuitDehors: Bool { MoteurAcclimatation.etape(jour: jourCourant)?.nuitDehors ?? false }

    /// Vrai si l'etape du jour a deja ete validee aujourd'hui.
    func valideeAujourdhui(calendrier: Calendar = .current, maintenant: Date = Date()) -> Bool {
        guard let derniereValidation else { return false }
        return calendrier.isDate(derniereValidation, inSameDayAs: maintenant)
    }
}

enum MoteurAcclimatation {

    /// Le programme, etape par etape.
    ///
    /// La progression est deliberement lente au debut : c'est la brulure du
    /// feuillage, pas le froid, qui fait echouer une sortie de printemps.
    static func etape(jour: Int) -> EtapeAcclimatation? {
        switch jour {
        case 1:
            return EtapeAcclimatation(jour: 1, heures: 1, lumiere: .ombre, nuitDehors: false,
                                      consigne: "Une heure dehors, a l'ombre complete, a l'abri du vent.")
        case 2:
            return EtapeAcclimatation(jour: 2, heures: 2, lumiere: .ombre, nuitDehors: false,
                                      consigne: "Deux heures a l'ombre. Verifier le feuillage au retour.")
        case 3:
            return EtapeAcclimatation(jour: 3, heures: 3, lumiere: .miOmbre, nuitDehors: false,
                                      consigne: "Trois heures, un peu de lumiere indirecte.")
        case 4:
            return EtapeAcclimatation(jour: 4, heures: 4, lumiere: .soleilDuMatin, nuitDehors: false,
                                      consigne: "Le soleil du matin seulement. Jamais celui de midi.")
        case 5:
            return EtapeAcclimatation(jour: 5, heures: 6, lumiere: .soleilDuMatin, nuitDehors: false,
                                      consigne: "Six heures, matin au soleil puis ombre l'apres-midi.")
        case 6:
            return EtapeAcclimatation(jour: 6, heures: 8, lumiere: .miOmbre, nuitDehors: false,
                                      consigne: "Huit heures. Arroser un peu plus : le vent asseche vite.")
        case 7:
            return EtapeAcclimatation(jour: 7, heures: 10, lumiere: .pleinSoleil, nuitDehors: false,
                                      consigne: "Journee complete au soleil, rentree pour la nuit.")
        case 8:
            return EtapeAcclimatation(jour: 8, heures: 24, lumiere: .pleinSoleil, nuitDehors: true,
                                      consigne: "Premiere nuit dehors, si la nuit est douce.")
        case 9:
            return EtapeAcclimatation(jour: 9, heures: 24, lumiere: .pleinSoleil, nuitDehors: true,
                                      consigne: "Deuxieme nuit dehors.")
        case 10:
            return EtapeAcclimatation(jour: 10, heures: 24, lumiere: .pleinSoleil, nuitDehors: true,
                                      consigne: "Derniere etape. La plante est acclimatee.")
        default:
            return nil
        }
    }

    /// Verdict sur la journee qui vient.
    enum Verdict: Hashable, Sendable {
        case allezY(EtapeAcclimatation)
        case reporte(raison: String)
        case termine

        var estFavorable: Bool {
            if case .allezY = self { return true }
            return false
        }
    }

    /// Decide si la journee permet de faire progresser le programme.
    ///
    /// Les trois motifs de report sont ceux qui ruinent une sortie : le froid,
    /// qui annule le benefice ; la pluie battante, qui noie la motte et couche
    /// le feuillage ; le vent, qui dessache et casse un sujet encore tendre.
    static func verdict(plante: Plante,
                        acclimatation: Acclimatation,
                        heuresDuJour: [ConditionHoraire]) -> Verdict {

        if acclimatation.termine { return .termine }
        guard let etape = etape(jour: acclimatation.jourCourant) else { return .termine }
        guard !heuresDuJour.isEmpty else {
            return .reporte(raison: "Pas de prevision pour aujourd'hui.")
        }

        let minimum = heuresDuJour.map(\.temperature).min() ?? 0
        let pluie = heuresDuJour.map(\.precipitation).reduce(0, +)
        let rafale = (heuresDuJour.map(\.rafale).max() ?? 0) * plante.exposition.facteurRafale

        // La journee ne sert a rien si la plante passe son temps a lutter
        // contre le froid : le seuil de confort tient lieu de plancher.
        if minimum < plante.seuilConfort {
            let arrondi = String(format: "%.0f", minimum)
            return .reporte(raison: "Trop froid aujourd'hui : \(arrondi) degres attendus.")
        }
        if pluie > 12 {
            return .reporte(raison: "Pluie abondante attendue. La motte n'a pas besoin de ca.")
        }
        if rafale > plante.seuilRafale * 0.8 {
            let arrondi = String(format: "%.0f", rafale)
            return .reporte(raison: "Rafales de \(arrondi) km/h. Un sujet non endurci casse.")
        }
        // Une nuit dehors se decide sur la nuit, pas sur la journee.
        if etape.nuitDehors && minimum < plante.seuilConfort + 2 {
            return .reporte(raison: "La nuit est encore trop fraiche pour la laisser dehors.")
        }
        return .allezY(etape)
    }
}
