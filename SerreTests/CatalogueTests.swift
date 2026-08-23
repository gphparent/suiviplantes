import Foundation
import Testing
@testable import Serre

struct CatalogueTests {

    @Test("Les identifiants du catalogue sont uniques")
    func identifiantsUniques() {
        let identifiants = Catalogue.especes.map(\.id)
        #expect(Set(identifiants).count == identifiants.count)
    }

    @Test("Le seuil de confort est toujours au-dessus du seuil critique")
    func seuilsCoherents() {
        for espece in Catalogue.especes {
            #expect(espece.seuilConfort >= espece.seuilCritique,
                    "\(espece.nom) : confort \(espece.seuilConfort), critique \(espece.seuilCritique)")
        }
    }

    @Test("Les intervalles d'arrosage sont positifs, et l'hiver est plus espace")
    func arrosageCoherent() {
        for espece in Catalogue.especes {
            #expect(espece.arrosageEte > 0)
            #expect(espece.arrosageHiver >= espece.arrosageEte,
                    "\(espece.nom) boirait plus l'hiver que l'ete")
        }
    }

    @Test("Aucun nom n'est vide")
    func nomsRemplis() {
        for espece in Catalogue.especes {
            #expect(!espece.nom.isEmpty)
            #expect(!espece.nomLatin.isEmpty)
        }
    }

    @Test("Chaque categorie compte au moins une espece")
    func categoriesPeuplees() {
        for categorie in Categorie.allCases {
            #expect(!Catalogue.especes(categorie: categorie).isEmpty,
                    "Categorie vide : \(categorie.nom)")
        }
    }

    @Test("Les tropicales meurent au-dessus de zero, les rustiques bien en dessous")
    func coherenceParCategorie() {
        for espece in Catalogue.especes(categorie: .tropicale) {
            #expect(espece.seuilCritique > 0, "\(espece.nom) devrait craindre le gel")
        }
        for espece in Catalogue.especes(categorie: .rustique) {
            #expect(espece.seuilCritique < -5, "\(espece.nom) devrait passer l'hiver dehors")
        }
    }

    @Test("La recherche ignore la casse et les accents")
    func recherche() {
        #expect(Catalogue.rechercher("HIBISCUS").contains { $0.id == "hibiscus" })
        #expect(Catalogue.rechercher("bougainvillee").contains { $0.id == "bougainvillee" })
        #expect(Catalogue.rechercher("Bougainvillée").contains { $0.id == "bougainvillee" })
    }

    @Test("La recherche porte aussi sur le nom latin")
    func rechercheLatine() {
        #expect(Catalogue.rechercher("Nerium").contains { $0.id == "laurier-rose" })
        #expect(Catalogue.rechercher("rosa-sinensis").contains { $0.id == "hibiscus" })
    }

    @Test("Une recherche vide rend tout le catalogue")
    func rechercheVide() {
        #expect(Catalogue.rechercher("").count == Catalogue.especes.count)
        #expect(Catalogue.rechercher("   ").count == Catalogue.especes.count)
    }

    @Test("Une recherche sans resultat ne rend rien")
    func rechercheInfructueuse() {
        #expect(Catalogue.rechercher("zzzzz").isEmpty)
    }

    @Test("Une espece se retrouve par son identifiant")
    func parIdentifiant() {
        #expect(Catalogue.espece(id: "basilic")?.nom == "Basilic")
        #expect(Catalogue.espece(id: "inexistant") == nil)
    }

    @Test("Une plante creee depuis le catalogue en herite les seuils")
    func heritageDesSeuils() {
        let basilic = Catalogue.espece(id: "basilic")
        #expect(basilic != nil)
        guard let basilic else { return }
        let plante = Plante(espece: basilic)
        #expect(plante.seuilConfort == basilic.seuilConfort)
        #expect(plante.seuilCritique == basilic.seuilCritique)
        #expect(plante.especeID == "basilic")
        #expect(plante.emplacement == .interieur)
    }

    @Test("Le basilic est bien la premiere plante a rentrer")
    func basilicFragile() {
        // Il noircit a quatre degres, bien avant le gel. C'est le cas type que
        // les alertes de gel publiques manquent completement.
        let basilic = Catalogue.espece(id: "basilic")
        #expect(basilic?.seuilCritique ?? 0 > 0)
        #expect(basilic?.seuilConfort ?? 0 >= 10)
    }
}
