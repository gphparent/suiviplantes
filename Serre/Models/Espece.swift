import Foundation

/// Grande famille de culture, qui sert a regrouper le catalogue et a proposer
/// des reglages de depart coherents.
enum Categorie: String, Codable, CaseIterable, Sendable, Identifiable {
    case tropicale
    case mediterraneenne
    case annuelleFleur
    case potager
    case finesHerbes
    case succulente
    case rustique

    var id: String { rawValue }

    var nom: String {
        switch self {
        case .tropicale: return "Tropicale"
        case .mediterraneenne: return "Mediterraneenne"
        case .annuelleFleur: return "Annuelle fleurie"
        case .potager: return "Potager"
        case .finesHerbes: return "Fines herbes"
        case .succulente: return "Succulente et cactus"
        case .rustique: return "Rustique au Quebec"
        }
    }
}

/// Une espece du catalogue interne.
///
/// Les deux seuils sont des reperes horticoles courants, pas des constantes
/// physiques : une meme espece varie selon le cultivar, l'age du sujet et son
/// endurcissement. Ils sont modifiables plante par plante, et c'est la valeur
/// de la plante qui fait foi dans tous les calculs.
struct Espece: Codable, Hashable, Sendable, Identifiable {
    let id: String
    let nom: String
    let nomLatin: String
    let categorie: Categorie
    /// En dessous, la plante souffre : croissance arretee, feuilles marquees.
    let seuilConfort: Double
    /// En dessous, les degats sont graves ou mortels.
    let seuilCritique: Double
    /// Jours entre deux arrosages, en pleine croissance, par temps ordinaire.
    let arrosageEte: Int
    /// Jours entre deux arrosages a l'interieur en hiver, quand la lumiere
    /// baisse et que la plante ne pousse plus.
    let arrosageHiver: Int
    let priseAuVent: PriseAuVent
    let note: String?

    init(id: String, nom: String, nomLatin: String, categorie: Categorie,
         seuilConfort: Double, seuilCritique: Double,
         arrosageEte: Int, arrosageHiver: Int,
         priseAuVent: PriseAuVent = .moyenne, note: String? = nil) {
        self.id = id
        self.nom = nom
        self.nomLatin = nomLatin
        self.categorie = categorie
        self.seuilConfort = seuilConfort
        self.seuilCritique = seuilCritique
        self.arrosageEte = arrosageEte
        self.arrosageHiver = arrosageHiver
        self.priseAuVent = priseAuVent
        self.note = note
    }
}

/// Catalogue de depart, choisi pour ce qui se cultive reellement au Quebec :
/// des plantes qu'on sort en mai et qu'on rentre en septembre, des annuelles
/// qui ne passent pas l'hiver, et les vivaces d'interieur les plus repandues.
enum Catalogue {

    static let especes: [Espece] = [

        // MARK: Tropicales qu'on sort l'ete

        Espece(id: "hibiscus", nom: "Hibiscus tropical", nomLatin: "Hibiscus rosa-sinensis",
               categorie: .tropicale, seuilConfort: 10, seuilCritique: 4,
               arrosageEte: 2, arrosageHiver: 7, priseAuVent: .moyenne,
               note: "Laisse tomber ses boutons apres un choc de froid, meme sans gel."),

        Espece(id: "bougainvillee", nom: "Bougainvillee", nomLatin: "Bougainvillea glabra",
               categorie: .tropicale, seuilConfort: 10, seuilCritique: 3,
               arrosageEte: 3, arrosageHiver: 12, priseAuVent: .forte,
               note: "Fleurit mieux un peu a l'etroit et un peu au sec."),

        Espece(id: "bananier", nom: "Bananier", nomLatin: "Musa",
               categorie: .tropicale, seuilConfort: 12, seuilCritique: 2,
               arrosageEte: 2, arrosageHiver: 8, priseAuVent: .forte,
               note: "Les feuilles se dechirent des 40 km/h. Le rhizome de Musa basjoo survit bien plus bas que le feuillage, s'il est paille."),

        Espece(id: "colocasia", nom: "Colocasia", nomLatin: "Colocasia esculenta",
               categorie: .tropicale, seuilConfort: 12, seuilCritique: 5,
               arrosageEte: 1, arrosageHiver: 14, priseAuVent: .forte,
               note: "Boit enormement l'ete. Le tubercule s'entrepose au sec et au frais l'hiver."),

        Espece(id: "citronnier", nom: "Citronnier", nomLatin: "Citrus limon",
               categorie: .tropicale, seuilConfort: 7, seuilCritique: 2,
               arrosageEte: 4, arrosageHiver: 12, priseAuVent: .moyenne,
               note: "Rentre avant les nuits sous 10 degres : le choc fait tomber feuilles et fruits."),

        Espece(id: "monstera", nom: "Monstera", nomLatin: "Monstera deliciosa",
               categorie: .tropicale, seuilConfort: 12, seuilCritique: 5,
               arrosageEte: 7, arrosageHiver: 12, priseAuVent: .forte,
               note: "Le plein soleil brule ses feuilles : a sortir a l'ombre seulement."),

        Espece(id: "ficus", nom: "Ficus lyre", nomLatin: "Ficus lyrata",
               categorie: .tropicale, seuilConfort: 13, seuilCritique: 7,
               arrosageEte: 7, arrosageHiver: 12, priseAuVent: .forte,
               note: "Deteste les changements. Chaque demenagement lui coute des feuilles."),

        Espece(id: "pothos", nom: "Pothos", nomLatin: "Epipremnum aureum",
               categorie: .tropicale, seuilConfort: 12, seuilCritique: 7,
               arrosageEte: 7, arrosageHiver: 12, priseAuVent: .faible),

        Espece(id: "philodendron", nom: "Philodendron", nomLatin: "Philodendron",
               categorie: .tropicale, seuilConfort: 12, seuilCritique: 7,
               arrosageEte: 7, arrosageHiver: 12, priseAuVent: .moyenne),

        Espece(id: "calathea", nom: "Calathea", nomLatin: "Goeppertia",
               categorie: .tropicale, seuilConfort: 15, seuilCritique: 10,
               arrosageEte: 4, arrosageHiver: 6, priseAuVent: .faible,
               note: "Exigeante en humidite de l'air. L'air sec du chauffage brunit le bord des feuilles."),

        Espece(id: "dracaena", nom: "Dracaena", nomLatin: "Dracaena",
               categorie: .tropicale, seuilConfort: 12, seuilCritique: 7,
               arrosageEte: 10, arrosageHiver: 16, priseAuVent: .moyenne),

        Espece(id: "sansevieria", nom: "Sansevieria", nomLatin: "Dracaena trifasciata",
               categorie: .succulente, seuilConfort: 10, seuilCritique: 5,
               arrosageEte: 14, arrosageHiver: 28, priseAuVent: .faible,
               note: "Meurt bien plus souvent d'exces d'eau que de froid."),

        // MARK: Mediterraneennes, plus endurantes

        Espece(id: "laurier-rose", nom: "Laurier-rose", nomLatin: "Nerium oleander",
               categorie: .mediterraneenne, seuilConfort: 5, seuilCritique: -5,
               arrosageEte: 3, arrosageHiver: 14, priseAuVent: .moyenne,
               note: "Hiverne bien au frais et a la noirceur, garage ou sous-sol froid."),

        Espece(id: "olivier", nom: "Olivier", nomLatin: "Olea europaea",
               categorie: .mediterraneenne, seuilConfort: 3, seuilCritique: -8,
               arrosageEte: 5, arrosageHiver: 18, priseAuVent: .moyenne,
               note: "Supporte le froid sec, pas la motte gelee et detrempee."),

        Espece(id: "figuier", nom: "Figuier", nomLatin: "Ficus carica",
               categorie: .mediterraneenne, seuilConfort: 2, seuilCritique: -10,
               arrosageEte: 3, arrosageHiver: 21, priseAuVent: .moyenne,
               note: "Une fois les feuilles tombees, il dort et tolere bien plus bas."),

        Espece(id: "romarin", nom: "Romarin", nomLatin: "Salvia rosmarinus",
               categorie: .mediterraneenne, seuilConfort: 0, seuilCritique: -10,
               arrosageEte: 6, arrosageHiver: 14, priseAuVent: .faible,
               note: "Ne passe pas l'hiver dehors au Quebec, meme s'il en tolere le froid : c'est la motte gelee qui le tue."),

        Espece(id: "palmier-chanvre", nom: "Palmier chanvre", nomLatin: "Trachycarpus fortunei",
               categorie: .mediterraneenne, seuilConfort: 0, seuilCritique: -12,
               arrosageEte: 5, arrosageHiver: 18, priseAuVent: .forte),

        // MARK: Annuelles fleuries

        Espece(id: "geranium", nom: "Geranium (pelargonium)", nomLatin: "Pelargonium",
               categorie: .annuelleFleur, seuilConfort: 5, seuilCritique: 0,
               arrosageEte: 3, arrosageHiver: 12, priseAuVent: .moyenne,
               note: "Se conserve tout l'hiver dans un sous-sol frais, presque sans eau."),

        Espece(id: "fuchsia", nom: "Fuchsia", nomLatin: "Fuchsia",
               categorie: .annuelleFleur, seuilConfort: 7, seuilCritique: 0,
               arrosageEte: 2, arrosageHiver: 10, priseAuVent: .moyenne,
               note: "Souffre autant de la canicule que du froid."),

        Espece(id: "impatiens", nom: "Impatiens", nomLatin: "Impatiens walleriana",
               categorie: .annuelleFleur, seuilConfort: 10, seuilCritique: 2,
               arrosageEte: 1, arrosageHiver: 7, priseAuVent: .faible,
               note: "S'effondre en quelques heures si la motte seche."),

        Espece(id: "petunia", nom: "Petunia", nomLatin: "Petunia",
               categorie: .annuelleFleur, seuilConfort: 4, seuilCritique: -1,
               arrosageEte: 2, arrosageHiver: 10, priseAuVent: .moyenne),

        Espece(id: "begonia", nom: "Begonia", nomLatin: "Begonia",
               categorie: .annuelleFleur, seuilConfort: 8, seuilCritique: 2,
               arrosageEte: 3, arrosageHiver: 12, priseAuVent: .faible),

        // MARK: Potager

        Espece(id: "tomate", nom: "Tomate", nomLatin: "Solanum lycopersicum",
               categorie: .potager, seuilConfort: 10, seuilCritique: 1,
               arrosageEte: 2, arrosageHiver: 7, priseAuVent: .forte,
               note: "En dessous de 10 degres la nuit, la fructification s'arrete meme sans gel."),

        Espece(id: "poivron", nom: "Poivron", nomLatin: "Capsicum annuum",
               categorie: .potager, seuilConfort: 12, seuilCritique: 4,
               arrosageEte: 2, arrosageHiver: 7, priseAuVent: .moyenne),

        Espece(id: "aubergine", nom: "Aubergine", nomLatin: "Solanum melongena",
               categorie: .potager, seuilConfort: 13, seuilCritique: 5,
               arrosageEte: 2, arrosageHiver: 7, priseAuVent: .moyenne),

        Espece(id: "concombre", nom: "Concombre", nomLatin: "Cucumis sativus",
               categorie: .potager, seuilConfort: 12, seuilCritique: 3,
               arrosageEte: 1, arrosageHiver: 7, priseAuVent: .forte),

        Espece(id: "courge", nom: "Courge et courgette", nomLatin: "Cucurbita",
               categorie: .potager, seuilConfort: 12, seuilCritique: 2,
               arrosageEte: 2, arrosageHiver: 7, priseAuVent: .forte),

        Espece(id: "laitue", nom: "Laitue", nomLatin: "Lactuca sativa",
               categorie: .potager, seuilConfort: 2, seuilCritique: -4,
               arrosageEte: 1, arrosageHiver: 5, priseAuVent: .faible,
               note: "Prefere le frais. C'est la chaleur qui la fait monter en graine."),

        Espece(id: "kale", nom: "Chou frise", nomLatin: "Brassica oleracea",
               categorie: .potager, seuilConfort: 0, seuilCritique: -8,
               arrosageEte: 2, arrosageHiver: 6, priseAuVent: .moyenne,
               note: "Meilleur apres les premieres gelees, qui adoucissent son gout."),

        // MARK: Fines herbes

        Espece(id: "basilic", nom: "Basilic", nomLatin: "Ocimum basilicum",
               categorie: .finesHerbes, seuilConfort: 12, seuilCritique: 4,
               arrosageEte: 1, arrosageHiver: 5, priseAuVent: .faible,
               note: "Noircit a 4 degres, bien avant le gel. C'est la premiere plante a rentrer."),

        Espece(id: "persil", nom: "Persil", nomLatin: "Petroselinum crispum",
               categorie: .finesHerbes, seuilConfort: 2, seuilCritique: -6,
               arrosageEte: 2, arrosageHiver: 7, priseAuVent: .faible),

        Espece(id: "ciboulette", nom: "Ciboulette", nomLatin: "Allium schoenoprasum",
               categorie: .rustique, seuilConfort: -5, seuilCritique: -30,
               arrosageEte: 3, arrosageHiver: 10, priseAuVent: .faible,
               note: "Vivace rustique : elle passe l'hiver dehors sans aide."),

        Espece(id: "menthe", nom: "Menthe", nomLatin: "Mentha",
               categorie: .rustique, seuilConfort: -5, seuilCritique: -25,
               arrosageEte: 2, arrosageHiver: 8, priseAuVent: .faible),

        Espece(id: "thym", nom: "Thym", nomLatin: "Thymus vulgaris",
               categorie: .rustique, seuilConfort: -8, seuilCritique: -20,
               arrosageEte: 6, arrosageHiver: 14, priseAuVent: .faible),

        // MARK: Succulentes

        Espece(id: "aloes", nom: "Aloes", nomLatin: "Aloe vera",
               categorie: .succulente, seuilConfort: 8, seuilCritique: 2,
               arrosageEte: 12, arrosageHiver: 30, priseAuVent: .faible),

        Espece(id: "echeveria", nom: "Echeveria", nomLatin: "Echeveria",
               categorie: .succulente, seuilConfort: 5, seuilCritique: 0,
               arrosageEte: 12, arrosageHiver: 30, priseAuVent: .faible,
               note: "Se colore magnifiquement dehors l'ete, a condition d'etre sortie progressivement."),

        Espece(id: "jade", nom: "Arbre de jade", nomLatin: "Crassula ovata",
               categorie: .succulente, seuilConfort: 7, seuilCritique: 2,
               arrosageEte: 14, arrosageHiver: 30, priseAuVent: .faible),

        Espece(id: "cactus", nom: "Cactus de desert", nomLatin: "Cactaceae",
               categorie: .succulente, seuilConfort: 5, seuilCritique: -2,
               arrosageEte: 14, arrosageHiver: 45, priseAuVent: .faible,
               note: "Un hiver froid et parfaitement sec le fait fleurir."),

        // MARK: Rustiques

        Espece(id: "lavande", nom: "Lavande", nomLatin: "Lavandula angustifolia",
               categorie: .rustique, seuilConfort: -10, seuilCritique: -25,
               arrosageEte: 7, arrosageHiver: 21, priseAuVent: .faible,
               note: "Rustique en pleine terre au Quebec ; en pot, la motte gele et c'est autre chose."),

        Espece(id: "hosta", nom: "Hosta", nomLatin: "Hosta",
               categorie: .rustique, seuilConfort: -10, seuilCritique: -35,
               arrosageEte: 4, arrosageHiver: 21, priseAuVent: .faible),

        Espece(id: "hydrangee", nom: "Hydrangee", nomLatin: "Hydrangea paniculata",
               categorie: .rustique, seuilConfort: -15, seuilCritique: -35,
               arrosageEte: 3, arrosageHiver: 21, priseAuVent: .moyenne),
    ]

    static func espece(id: String) -> Espece? {
        especes.first { $0.id == id }
    }

    static func especes(categorie: Categorie) -> [Espece] {
        especes.filter { $0.categorie == categorie }
    }

    /// Recherche insensible a la casse et aux accents, sur le nom courant comme
    /// sur le nom latin.
    static func rechercher(_ texte: String) -> [Espece] {
        let besoin = texte.folding(options: [.diacriticInsensitive, .caseInsensitive],
                                   locale: Locale(identifier: "fr"))
        guard !besoin.trimmingCharacters(in: .whitespaces).isEmpty else { return especes }
        return especes.filter { espece in
            let champs = [espece.nom, espece.nomLatin]
                .map { $0.folding(options: [.diacriticInsensitive, .caseInsensitive],
                                  locale: Locale(identifier: "fr")) }
            return champs.contains { $0.contains(besoin) }
        }
    }
}
