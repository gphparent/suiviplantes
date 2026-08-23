import Foundation
import Testing
@testable import Serre

struct PlanDeLaNuitTests {

    private let calendrier = Aide.calendrierMontreal
    private let jour = Aide.date(2026, 5, 20)

    private func plan(plantes: [Plante],
                      heures: [ConditionHoraire],
                      maintenant: Date = Aide.date(2026, 5, 20, 18),
                      reglages: Reglages = .defaut) -> PlanDeLaNuit {
        MoteurPlan.construire(plantes: plantes,
                              previsions: Aide.previsions(heures: heures),
                              reglages: reglages,
                              maintenant: maintenant,
                              calendrier: calendrier)
    }

    // MARK: - Fenetre de la nuit

    @Test("La nuit va du milieu de l'apres-midi au milieu de la matinee suivante")
    func fenetre() {
        let fenetre = MoteurPlan.fenetreNocturne(pour: Aide.date(2026, 5, 20, 18),
                                                 calendrier: calendrier)
        #expect(calendrier.component(.hour, from: fenetre.start) == 15)
        #expect(calendrier.component(.day, from: fenetre.start) == 20)
        #expect(calendrier.component(.hour, from: fenetre.end) == 9)
        #expect(calendrier.component(.day, from: fenetre.end) == 21)
    }

    @Test("Avant neuf heures du matin, la nuit qui vient est celle qui est en cours")
    func fenetreAuPetitMatin() {
        // Quelqu'un qui ouvre l'application a six heures veut savoir ce qui se
        // passe maintenant, pas ce soir.
        let fenetre = MoteurPlan.fenetreNocturne(pour: Aide.date(2026, 5, 21, 6),
                                                 calendrier: calendrier)
        #expect(calendrier.component(.day, from: fenetre.start) == 20)
        #expect(calendrier.component(.day, from: fenetre.end) == 21)
    }

    @Test("A quinze heures pile, l'alerte porte deja sur la nuit qui vient")
    func fenetreALHeureDeLAlerte() {
        let fenetre = MoteurPlan.fenetreNocturne(pour: Aide.date(2026, 5, 20, 15),
                                                 calendrier: calendrier)
        #expect(calendrier.component(.day, from: fenetre.start) == 20)
    }

    // MARK: - A rentrer

    @Test("Une nuit froide designe les plantes a rentrer, nommees")
    func aRentrer() {
        let plantes = [
            Aide.plante(nom: "Basilic", confort: 12, critique: 4),
            Aide.plante(nom: "Lavande", confort: -10, critique: -25, assise: .pleineTerre),
        ]
        let resultat = plan(plantes: plantes, heures: Aide.nuit(du: jour, temperature: 5))
        #expect(resultat.aRentrer.map(\.nom) == ["Basilic"])
        #expect(resultat.demandeUnGeste)
    }

    @Test("Une nuit douce ne demande aucun geste")
    func nuitDouce() {
        let plantes = [Aide.plante(nom: "Hibiscus", confort: 10, critique: 4)]
        let resultat = plan(plantes: plantes,
                            heures: Aide.nuit(du: jour, temperature: 22,
                                              nebulosite: 100, vent: 20))
        #expect(resultat.aRentrer.isEmpty)
        #expect(!resultat.demandeUnGeste)
    }

    @Test("Le minimum de reference est celui de la pleine terre")
    func minimumDeReference() {
        let resultat = plan(plantes: [Aide.plante()],
                            heures: Aide.nuit(du: jour, temperature: 3))
        let reference = resultat.minimumReference
        #expect(reference != nil)
        #expect(reference?.temperatureAnnoncee == 3)
        #expect((reference?.temperatureCorrigee ?? 0) < 3)
    }

    // MARK: - La boucle fermee

    @Test("Une plante rentree pour le gel est proposee au retour des que la nuit le permet")
    func boucleFermee() {
        // C'est ce que rien d'autre ne fait : personne ne sait que les pots
        // rentres hier soir attendent pres de la porte.
        let rentree = Aide.plante(nom: "Hibiscus", confort: 10, critique: 4,
                                  emplacement: .interieur,
                                  demenagements: [Demenagement(date: Aide.date(2026, 5, 19, 16),
                                                               sens: .rentree, motif: .gel)])
        let resultat = plan(plantes: [rentree],
                            heures: Aide.nuit(du: jour, temperature: 22,
                                              nebulosite: 100, vent: 20))
        #expect(resultat.aRessortir.map(\.nom) == ["Hibiscus"])
    }

    @Test("Une plante rangee pour l'hiver n'est pas proposee au retour")
    func rangementSaisonnier() {
        // Le motif du dernier demenagement fait toute la difference entre une
        // mise a l'abri pour une nuit et un rangement jusqu'au printemps.
        let rangee = Aide.plante(nom: "Laurier-rose", confort: 5, critique: -5,
                                 emplacement: .interieur,
                                 demenagements: [Demenagement(date: Aide.date(2025, 10, 15),
                                                              sens: .rentree, motif: .saison)])
        let resultat = plan(plantes: [rangee],
                            heures: Aide.nuit(du: jour, temperature: 22,
                                              nebulosite: 100, vent: 20))
        #expect(resultat.aRessortir.isEmpty)
    }

    @Test("Une plante rentree pour le gel reste dedans tant que la nuit reste froide")
    func retourPrematureRefuse() {
        let rentree = Aide.plante(nom: "Hibiscus", confort: 10, critique: 4,
                                  emplacement: .interieur,
                                  demenagements: [Demenagement(date: Aide.date(2026, 5, 19, 16),
                                                               sens: .rentree, motif: .gel)])
        let resultat = plan(plantes: [rentree], heures: Aide.nuit(du: jour, temperature: 8))
        #expect(resultat.aRessortir.isEmpty)
    }

    @Test("Une plante jamais sortie n'est pas candidate au retour")
    func jamaisSortie() {
        let neuve = Aide.plante(nom: "Neuve", emplacement: .interieur)
        let resultat = plan(plantes: [neuve],
                            heures: Aide.nuit(du: jour, temperature: 22,
                                              nebulosite: 100, vent: 20))
        #expect(resultat.aRessortir.isEmpty)
    }

    // MARK: - Reglages

    @Test("Les alertes de vent se coupent depuis les reglages")
    func ventDesactive() {
        var reglages = Reglages.defaut
        reglages.alerterAuVent = false
        let plante = Aide.plante(exposition: .exposee, prise: .forte)
        let heures = Aide.nuit(du: jour, temperature: 18, rafale: 90)
        #expect(plan(plantes: [plante], heures: heures, reglages: reglages).vent.isEmpty)
        #expect(!plan(plantes: [plante], heures: heures, reglages: .defaut).vent.isEmpty)
    }

    @Test("Sans alerte de confort, seules les plantes qui souffrent vraiment remontent")
    func confortDesactive() {
        var reglages = Reglages.defaut
        reglages.alerterAuConfort = false
        let plante = Aide.plante(nom: "Tiede", confort: 10, critique: -20, assise: .pleineTerre)
        let heures = Aide.nuit(du: jour, temperature: 12, nebulosite: 100, vent: 25)
        #expect(plan(plantes: [plante], heures: heures, reglages: reglages).aSurveiller.isEmpty)
        #expect(!plan(plantes: [plante], heures: heures).aSurveiller.isEmpty)
    }

    // MARK: - Acclimatation

    @Test("L'etape du jour figure au plan")
    func etapeAuPlan() {
        let plante = Aide.plante(nom: "Echeveria", confort: 8, emplacement: .acclimatation,
                                 acclimatation: Acclimatation())
        let resultat = plan(plantes: [plante],
                            heures: Aide.nuit(du: jour, temperature: 20, rafale: 10))
        #expect(resultat.acclimatations.count == 1)
        #expect(resultat.acclimatations.first?.jour == 1)
    }

    @Test("Une etape deja validee aujourd'hui ne revient pas")
    func etapeDejaValidee() {
        let plante = Aide.plante(emplacement: .acclimatation,
                                 acclimatation: Acclimatation(joursValides: 2,
                                                              derniereValidation: Aide.date(2026, 5, 20, 10)))
        let resultat = plan(plantes: [plante],
                            heures: Aide.nuit(du: jour, temperature: 20, rafale: 10))
        #expect(resultat.acclimatations.isEmpty)
    }

    // MARK: - Nuit calme

    @Test("Une nuit sans rien a faire se declare calme")
    func nuitCalme() {
        let resultat = plan(plantes: [Aide.plante(confort: 5, critique: -5)],
                            heures: Aide.nuit(du: jour, temperature: 22,
                                              nebulosite: 100, vent: 20))
        #expect(resultat.estCalme)
    }
}
