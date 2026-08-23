import Foundation
import Testing
@testable import Serre

/// Une notification qui dit « risque de gel » oblige a ouvrir l'application, a
/// lire une liste, a se rappeler ce qu'on avait decide. Une notification qui
/// nomme les plantes se suffit a elle-meme. C'est ce que ces tests verifient.
struct NotificationTests {

    private let calendrier = Aide.calendrierMontreal
    private let jour = Aide.date(2026, 5, 20)
    private let maintenant = Aide.date(2026, 5, 20, 18)

    private func plan(plantes: [Plante], heures: [ConditionHoraire]) -> PlanDeLaNuit {
        MoteurPlan.construire(plantes: plantes,
                              previsions: Aide.previsions(heures: heures),
                              reglages: .defaut,
                              maintenant: maintenant,
                              calendrier: calendrier)
    }

    // MARK: - Mise en liste

    @Test("Un seul nom reste seul")
    func listeUnique() {
        #expect(NotificationService.liste(["Basilic"]) == "Basilic")
    }

    @Test("Deux noms sont joints par un et")
    func listeDouble() {
        #expect(NotificationService.liste(["Basilic", "Tomate"]) == "Basilic et Tomate")
    }

    @Test("Trois noms prennent des virgules puis un et")
    func listeTriple() {
        #expect(NotificationService.liste(["Basilic", "Tomate", "Hibiscus"])
                == "Basilic, Tomate et Hibiscus")
    }

    @Test("Une liste vide ne produit pas de texte bancal")
    func listeVide() {
        #expect(NotificationService.liste([]) == "")
    }

    // MARK: - Alerte du soir

    @Test("L'alerte du soir nomme les plantes a rentrer")
    func alerteNomme() {
        let plantes = [
            Aide.plante(nom: "Basilic", confort: 12, critique: 4),
            Aide.plante(nom: "Tomate", confort: 10, critique: 1),
        ]
        let contenu = NotificationService.contenuDuSoir(
            plan: plan(plantes: plantes, heures: Aide.nuit(du: jour, temperature: 2)))
        #expect(contenu != nil)
        #expect(contenu?.body.contains("Basilic") == true)
        #expect(contenu?.body.contains("Tomate") == true)
    }

    @Test("Le titre compte les plantes")
    func alerteCompte() {
        let plantes = [
            Aide.plante(nom: "Basilic", confort: 12, critique: 4),
            Aide.plante(nom: "Tomate", confort: 10, critique: 1),
        ]
        let contenu = NotificationService.contenuDuSoir(
            plan: plan(plantes: plantes, heures: Aide.nuit(du: jour, temperature: 2)))
        #expect(contenu?.title == "2 plantes a rentrer")
    }

    @Test("Une seule plante s'annonce au singulier")
    func alerteSingulier() {
        let contenu = NotificationService.contenuDuSoir(
            plan: plan(plantes: [Aide.plante(nom: "Basilic", confort: 12, critique: 4)],
                       heures: Aide.nuit(du: jour, temperature: 2)))
        #expect(contenu?.title == "Une plante a rentrer")
    }

    @Test("Le sous-titre donne la temperature au sol, pas celle annoncee")
    func alerteSousTitre() {
        let contenu = NotificationService.contenuDuSoir(
            plan: plan(plantes: [Aide.plante(nom: "Basilic", confort: 12, critique: 4)],
                       heures: Aide.nuit(du: jour, temperature: 2)))
        #expect(contenu?.subtitle.contains("au sol") == true)
    }

    @Test("Une nuit tranquille ne produit aucune notification")
    func pasDAlerteInutile() {
        // Une alerte qui ne demande rien est une alerte qu'on apprend a ignorer.
        let contenu = NotificationService.contenuDuSoir(
            plan: plan(plantes: [Aide.plante(nom: "Hibiscus", confort: 10, critique: 4)],
                       heures: Aide.nuit(du: jour, temperature: 22,
                                         nebulosite: 100, vent: 20)))
        #expect(contenu == nil)
    }

    @Test("Sans gel mais avec du vent, l'alerte parle du vent")
    func alerteVent() {
        let plante = Aide.plante(nom: "Bananier", confort: 5, critique: -5,
                                 exposition: .exposee, prise: .forte)
        let contenu = NotificationService.contenuDuSoir(
            plan: plan(plantes: [plante],
                       heures: Aide.nuit(du: jour, temperature: 20,
                                         nebulosite: 100, vent: 30, rafale: 90)))
        #expect(contenu?.title.contains("vent") == true)
        #expect(contenu?.body.contains("Bananier") == true)
    }

    // MARK: - Bilan du matin

    @Test("Le bilan du matin nomme ce qui peut ressortir")
    func bilanRessortir() {
        let rentree = Aide.plante(nom: "Hibiscus", confort: 10, critique: 4,
                                  emplacement: .interieur,
                                  demenagements: [Demenagement(date: Aide.date(2026, 5, 19, 16),
                                                               sens: .rentree, motif: .gel)])
        let contenu = NotificationService.contenuDuMatin(
            plan: plan(plantes: [rentree],
                       heures: Aide.nuit(du: jour, temperature: 22,
                                         nebulosite: 100, vent: 20)))
        #expect(contenu?.title == "Une plante peut ressortir")
        #expect(contenu?.body.contains("Hibiscus") == true)
    }

    @Test("Le bilan du matin porte l'etape d'acclimatation du jour")
    func bilanAcclimatation() {
        let plante = Aide.plante(nom: "Echeveria", confort: 8, emplacement: .acclimatation,
                                 acclimatation: Acclimatation())
        let contenu = NotificationService.contenuDuMatin(
            plan: plan(plantes: [plante],
                       heures: Aide.nuit(du: jour, temperature: 20, rafale: 10)))
        #expect(contenu?.body.contains("Echeveria") == true)
        #expect(contenu?.body.contains("jour 1") == true)
    }

    @Test("Un matin sans rien a faire reste silencieux")
    func bilanSilencieux() {
        let contenu = NotificationService.contenuDuMatin(
            plan: plan(plantes: [Aide.plante(nom: "Hibiscus")],
                       heures: Aide.nuit(du: jour, temperature: 22,
                                         nebulosite: 100, vent: 20)))
        #expect(contenu == nil)
    }
}
