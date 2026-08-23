import Foundation
import Testing
@testable import Serre

/// Le modele de refroidissement nocturne est un ordre de grandeur, pas une
/// mesure. Ce qui se teste, ce sont ses proprietes : le sens des variations, les
/// bornes, et le comportement du frein humide. Les valeurs de reference — trois
/// a cinq degres d'ecart entre l'abri et le sol par nuit degagee et calme —
/// viennent de la litterature courante sur les gelees de rayonnement.
struct RefroidissementNocturneTests {

    private let midi = Aide.date(2026, 5, 20, 3)

    // MARK: - Facteurs

    @Test("Un ciel degage conserve tout le refroidissement")
    func cielDegage() {
        #expect(RefroidissementNocturne.facteurCiel(nebulosite: 0) == 1.0)
    }

    @Test("Un ciel couvert en conserve un cinquieme, pas zero")
    func cielCouvert() {
        let facteur = RefroidissementNocturne.facteurCiel(nebulosite: 100)
        #expect(abs(facteur - 0.2) < 1e-9)
    }

    @Test("Le facteur de ciel decroit avec la nebulosite")
    func cielMonotone() {
        let valeurs = stride(from: 0.0, through: 100.0, by: 10)
            .map { RefroidissementNocturne.facteurCiel(nebulosite: $0) }
        for (precedent, suivant) in zip(valeurs, valeurs.dropFirst()) {
            #expect(suivant < precedent)
        }
    }

    @Test("Une nebulosite hors bornes est ramenee dans l'intervalle")
    func cielBorne() {
        #expect(RefroidissementNocturne.facteurCiel(nebulosite: -30) == 1.0)
        #expect(abs(RefroidissementNocturne.facteurCiel(nebulosite: 250) - 0.2) < 1e-9)
    }

    @Test("Sans vent, le refroidissement est entier")
    func ventNul() {
        #expect(RefroidissementNocturne.facteurVent(vent: 0) == 1.0)
    }

    @Test("Au vent caracteristique, il en reste la moitie")
    func ventCaracteristique() {
        let facteur = RefroidissementNocturne.facteurVent(
            vent: RefroidissementNocturne.ventCaracteristique)
        #expect(abs(facteur - 0.5) < 1e-9)
    }

    @Test("Un vent fort efface presque l'inversion")
    func ventFort() {
        #expect(RefroidissementNocturne.facteurVent(vent: 30) < 0.05)
    }

    // MARK: - Cas de reference

    @Test("Nuit degagee et calme : environ quatre degres de moins au sol en pot")
    func nuitDeRayonnement() {
        let condition = Aide.heure(midi, temperature: 3, pointDeRosee: -10,
                                   nebulosite: 0, vent: 2)
        let subie = RefroidissementNocturne.temperatureAuSol(condition: condition,
                                                             assise: .potAuSol)
        // Ciel degage, vent quasi nul, pot au sol : l'ecart doit etre franc et
        // faire passer sous zero une nuit annoncee a trois degres. C'est
        // exactement le cas qui tue les plantes en mai.
        #expect(subie < 0)
        #expect(subie > -3)
    }

    @Test("Nuit couverte et ventee : l'ecart s'efface")
    func nuitCouverte() {
        let condition = Aide.heure(midi, temperature: 3, pointDeRosee: 1,
                                   nebulosite: 100, vent: 25)
        let ecart = RefroidissementNocturne.ecart(condition: condition, assise: .potAuSol)
        #expect(ecart < 0.2)
    }

    @Test("La correction ne rechauffe jamais")
    func jamaisPositive() {
        for nebulosite in stride(from: 0.0, through: 100.0, by: 25) {
            for vent in stride(from: 0.0, through: 40.0, by: 10) {
                for assise in Assise.allCases {
                    let condition = Aide.heure(midi, temperature: 5, pointDeRosee: -5,
                                               nebulosite: nebulosite, vent: vent)
                    let subie = RefroidissementNocturne.temperatureAuSol(condition: condition,
                                                                         assise: assise)
                    #expect(subie <= condition.temperature + 1e-9)
                }
            }
        }
    }

    // MARK: - Assises

    @Test("Un pot sureleve descend plus bas qu'un pot au sol, qui descend plus bas que la pleine terre")
    func classementDesAssises() {
        let condition = Aide.heure(midi, temperature: 2, pointDeRosee: -12,
                                   nebulosite: 10, vent: 3)
        let sureleve = RefroidissementNocturne.temperatureAuSol(condition: condition,
                                                                assise: .potSureleve)
        let auSol = RefroidissementNocturne.temperatureAuSol(condition: condition,
                                                             assise: .potAuSol)
        let terre = RefroidissementNocturne.temperatureAuSol(condition: condition,
                                                             assise: .pleineTerre)
        let mur = RefroidissementNocturne.temperatureAuSol(condition: condition,
                                                           assise: .contreUnMur)
        let protege = RefroidissementNocturne.temperatureAuSol(condition: condition,
                                                               assise: .protege)
        #expect(sureleve < auSol)
        #expect(auSol < terre)
        #expect(terre < mur)
        #expect(mur < protege)
    }

    @Test("Seules les assises en pot exposent les racines")
    func racinesExposees() {
        #expect(Assise.potAuSol.racinesExposees)
        #expect(Assise.potSureleve.racinesExposees)
        #expect(!Assise.pleineTerre.racinesExposees)
        #expect(!Assise.protege.racinesExposees)
    }

    // MARK: - Frein du point de rosee

    @Test("Au-dessus du point de rosee, la chute est libre")
    func chuteLibre() {
        let resultat = RefroidissementNocturne.appliquerFreinHumide(
            temperature: 10, pointDeRosee: 0, refroidissement: 4)
        #expect(abs(resultat - 6) < 1e-9)
    }

    @Test("Sous le point de rosee, la chute est freinee")
    func chuteFreinee() {
        // Trois degres de marge libre, puis deux degres freines a 40 %.
        let resultat = RefroidissementNocturne.appliquerFreinHumide(
            temperature: 3, pointDeRosee: 0, refroidissement: 5)
        #expect(abs(resultat - (0 - 0.4 * 2)) < 1e-9)
    }

    @Test("Une nuit humide gele moins fort qu'une nuit seche, toutes choses egales")
    func humiditeProtege() {
        let seche = Aide.heure(midi, temperature: 2, pointDeRosee: -15,
                               nebulosite: 0, vent: 1)
        let humide = Aide.heure(midi, temperature: 2, pointDeRosee: 1.5,
                                nebulosite: 0, vent: 1)
        let froidSec = RefroidissementNocturne.temperatureAuSol(condition: seche, assise: .potAuSol)
        let froidHumide = RefroidissementNocturne.temperatureAuSol(condition: humide, assise: .potAuSol)
        #expect(froidHumide > froidSec)
    }

    @Test("Un point de rosee superieur a la temperature est ramene, pas propage")
    func roseeIncoherente() {
        // Les series de prevision produisent ce cas par arrondi.
        let resultat = RefroidissementNocturne.appliquerFreinHumide(
            temperature: 1, pointDeRosee: 3, refroidissement: 2)
        #expect(abs(resultat - (1 - 0.4 * 2)) < 1e-9)
    }

    @Test("Un refroidissement nul laisse la temperature intacte")
    func refroidissementNul() {
        let resultat = RefroidissementNocturne.appliquerFreinHumide(
            temperature: 7, pointDeRosee: 2, refroidissement: 0)
        #expect(resultat == 7)
    }

    // MARK: - Minimum sur une nuit

    @Test("Le minimum retient l'heure la plus froide apres correction")
    func minimumSurLaNuit() {
        let debut = Aide.date(2026, 5, 20, 20)
        let heures = [
            Aide.heure(debut, temperature: 8, nebulosite: 100, vent: 20),
            Aide.heure(debut.addingTimeInterval(3600), temperature: 5, nebulosite: 0, vent: 1),
            Aide.heure(debut.addingTimeInterval(7200), temperature: 6, nebulosite: 100, vent: 20),
        ]
        let minimum = RefroidissementNocturne.minimumNocturne(heures: heures, assise: .potAuSol)
        #expect(minimum?.temperatureAnnoncee == 5)
        #expect(minimum?.nuitDeRayonnement == true)
    }

    @Test("Une nuit sans prevision ne produit pas de minimum")
    func minimumVide() {
        #expect(RefroidissementNocturne.minimumNocturne(heures: [], assise: .potAuSol) == nil)
        #expect(RefroidissementNocturne.minimumBrut(heures: []) == nil)
    }

    @Test("Le minimum brut ne corrige rien")
    func minimumBrut() {
        let heures = Aide.nuit(du: Aide.date(2026, 5, 20), temperature: 3)
        let brut = RefroidissementNocturne.minimumBrut(heures: heures)
        #expect(brut?.temperatureCorrigee == 3)
        #expect(brut?.ecart == 0)
    }
}
