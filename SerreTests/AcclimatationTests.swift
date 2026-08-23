import Foundation
import Testing
@testable import Serre

struct AcclimatationTests {

    private let jour = Aide.date(2026, 5, 15)

    // MARK: - Le programme

    @Test("Le programme compte dix etapes, et pas une de plus")
    func longueurDuProgramme() {
        for jour in 1...Acclimatation.duree {
            #expect(MoteurAcclimatation.etape(jour: jour) != nil)
        }
        #expect(MoteurAcclimatation.etape(jour: 0) == nil)
        #expect(MoteurAcclimatation.etape(jour: Acclimatation.duree + 1) == nil)
    }

    @Test("La duree dehors ne recule jamais")
    func dureeCroissante() {
        let heures = (1...Acclimatation.duree).compactMap {
            MoteurAcclimatation.etape(jour: $0)?.heures
        }
        for (precedent, suivant) in zip(heures, heures.dropFirst()) {
            #expect(suivant >= precedent)
        }
    }

    @Test("Les premiers jours se passent a l'ombre")
    func debutALOmbre() {
        #expect(MoteurAcclimatation.etape(jour: 1)?.lumiere == .ombre)
        #expect(MoteurAcclimatation.etape(jour: 2)?.lumiere == .ombre)
    }

    @Test("La premiere nuit dehors n'arrive qu'apres une semaine")
    func premiereNuitTardive() {
        for jour in 1...7 {
            #expect(MoteurAcclimatation.etape(jour: jour)?.nuitDehors == false)
        }
        #expect(MoteurAcclimatation.etape(jour: 8)?.nuitDehors == true)
    }

    // MARK: - Progression

    @Test("Le jour courant suit le nombre d'etapes validees")
    func jourCourant() {
        #expect(Acclimatation(joursValides: 0).jourCourant == 1)
        #expect(Acclimatation(joursValides: 5).jourCourant == 6)
    }

    @Test("Le jour courant ne depasse pas la fin du programme")
    func jourCourantBorne() {
        #expect(Acclimatation(joursValides: 40).jourCourant == Acclimatation.duree)
    }

    @Test("Le programme se termine a la dixieme etape")
    func fin() {
        #expect(!Acclimatation(joursValides: 9).termine)
        #expect(Acclimatation(joursValides: 10).termine)
    }

    @Test("Une etape validee aujourd'hui ne peut pas l'etre deux fois")
    func uneEtapeParJour() {
        let acclimatation = Acclimatation(joursValides: 3, derniereValidation: Date())
        #expect(acclimatation.valideeAujourdhui())
        let hier = Acclimatation(joursValides: 3,
                                 derniereValidation: Date().addingTimeInterval(-86_400 * 2))
        #expect(!hier.valideeAujourdhui())
    }

    @Test("Sans validation, rien n'a ete fait aujourd'hui")
    func aucuneValidation() {
        #expect(!Acclimatation().valideeAujourdhui())
    }

    // MARK: - Verdict du jour

    @Test("Une belle journee fait avancer le programme")
    func journeeFavorable() {
        let plante = Aide.plante(confort: 10, emplacement: .acclimatation)
        let verdict = MoteurAcclimatation.verdict(
            plante: plante,
            acclimatation: Acclimatation(),
            heuresDuJour: Aide.nuit(du: jour, temperature: 20, rafale: 10))
        #expect(verdict.estFavorable)
    }

    @Test("Le froid suspend le programme au lieu de le faire avancer")
    func journeeFroide() {
        // Une journee passee a lutter contre le froid n'endurcit rien.
        let plante = Aide.plante(confort: 12, emplacement: .acclimatation)
        let verdict = MoteurAcclimatation.verdict(
            plante: plante,
            acclimatation: Acclimatation(),
            heuresDuJour: Aide.nuit(du: jour, temperature: 6))
        #expect(!verdict.estFavorable)
        if case .reporte(let raison) = verdict {
            #expect(raison.contains("froid"))
        } else {
            Issue.record("Le verdict devrait etre un report.")
        }
    }

    @Test("Une pluie battante reporte la sortie")
    func journeePluvieuse() {
        let plante = Aide.plante(confort: 8, emplacement: .acclimatation)
        let verdict = MoteurAcclimatation.verdict(
            plante: plante,
            acclimatation: Acclimatation(),
            heuresDuJour: Aide.nuit(du: jour, temperature: 18, precipitation: 3))
        #expect(!verdict.estFavorable)
    }

    @Test("Un grand vent casse un sujet non endurci")
    func journeeVenteuse() {
        let plante = Aide.plante(confort: 8, emplacement: .acclimatation, prise: .forte)
        let verdict = MoteurAcclimatation.verdict(
            plante: plante,
            acclimatation: Acclimatation(),
            heuresDuJour: Aide.nuit(du: jour, temperature: 18, rafale: 45))
        #expect(!verdict.estFavorable)
        if case .reporte(let raison) = verdict {
            #expect(raison.contains("Rafales"))
        } else {
            Issue.record("Le verdict devrait etre un report.")
        }
    }

    @Test("Sans prevision, on ne fait pas avancer le programme a l'aveugle")
    func sansPrevision() {
        let verdict = MoteurAcclimatation.verdict(plante: Aide.plante(),
                                                  acclimatation: Acclimatation(),
                                                  heuresDuJour: [])
        #expect(!verdict.estFavorable)
    }

    @Test("Un programme termine ne propose plus rien")
    func programmeTermine() {
        let verdict = MoteurAcclimatation.verdict(
            plante: Aide.plante(),
            acclimatation: Acclimatation(joursValides: Acclimatation.duree),
            heuresDuJour: Aide.nuit(du: jour, temperature: 20))
        #expect(verdict == .termine)
    }

    @Test("La premiere nuit dehors exige une nuit franchement douce")
    func premiereNuitExigeante() {
        let plante = Aide.plante(confort: 10, emplacement: .acclimatation)
        // Onze degres : assez pour une journee, pas pour la premiere nuit.
        let verdict = MoteurAcclimatation.verdict(
            plante: plante,
            acclimatation: Acclimatation(joursValides: 7),
            heuresDuJour: Aide.nuit(du: jour, temperature: 11))
        #expect(!verdict.estFavorable)
    }
}
