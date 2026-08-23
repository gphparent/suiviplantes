import Foundation
import Testing
@testable import Serre

struct RisqueVentTests {

    private let jour = Aide.date(2026, 7, 10)

    private func evaluer(rafale: Double, plante: Plante) -> EvaluationVent? {
        MoteurVent.evaluer(plante: plante,
                           heures: Aide.nuit(du: jour, temperature: 18, rafale: rafale))
    }

    @Test("Un fond de cour recoit une fraction de la rafale annoncee")
    func expositionAbritee() {
        let plante = Aide.plante(exposition: .abritee)
        let evaluation = evaluer(rafale: 100, plante: plante)
        #expect(evaluation?.rafaleAnnoncee == 100)
        #expect(abs((evaluation?.rafaleSurPlace ?? 0) - 55) < 1e-9)
    }

    @Test("Un balcon en etage peut en recevoir davantage")
    func expositionExposee() {
        let plante = Aide.plante(exposition: .exposee)
        let evaluation = evaluer(rafale: 100, plante: plante)
        #expect((evaluation?.rafaleSurPlace ?? 0) > 100)
    }

    @Test("La meme rafale ne dit pas la meme chose selon l'endroit")
    func memeRafaleDeuxVerdicts() {
        // C'est tout le probleme des alertes de vent publiques : elles parlent
        // de la station, pas du pot.
        let abritee = Aide.plante(exposition: .abritee, prise: .moyenne)
        let exposee = Aide.plante(exposition: .exposee, prise: .moyenne)
        #expect(evaluer(rafale: 50, plante: abritee)?.niveau == .aucun)
        #expect((evaluer(rafale: 50, plante: exposee)?.niveau ?? .aucun) >= .danger)
    }

    @Test("Une plante a forte prise au vent bascule bien plus tot")
    func priseAuVent() {
        let bananier = Aide.plante(prise: .forte)
        let potLourd = Aide.plante(prise: .faible)
        #expect((evaluer(rafale: 50, plante: bananier)?.niveau ?? .aucun) >= .danger)
        #expect(evaluer(rafale: 50, plante: potLourd)?.niveau == .aucun)
    }

    @Test("En pleine terre, rien ne bascule : seul le feuillage se dechire")
    func pleineTerre() {
        let enTerre = Aide.plante(assise: .pleineTerre, prise: .forte)
        let evaluation = evaluer(rafale: 60, plante: enTerre)
        // Le seuil remonte au seuil de dechirure du feuillage, plus haut que le
        // seuil de renversement d'un pot.
        #expect(evaluation?.seuil == MoteurVent.seuilDechirure)
    }

    @Test("Une plante rangee n'a plus de risque de vent")
    func plantesRangees() {
        let rangee = Aide.plante(assise: .protege)
        #expect(evaluer(rafale: 120, plante: rangee) == nil)
    }

    @Test("Le geste propose suit la gravite")
    func gesteProposeSuitLaGravite() {
        let plante = Aide.plante(exposition: .exposee, prise: .forte)
        let grave = evaluer(rafale: 90, plante: plante)
        #expect(grave?.niveau == .critique)
        #expect(grave?.geste.contains("rentrer") == true)
    }

    @Test("Les plantes a l'interieur sont ecartees de la liste")
    func plantesInterieures() {
        let plantes = [
            Aide.plante(nom: "Dehors", emplacement: .exterieur, exposition: .exposee, prise: .forte),
            Aide.plante(nom: "Dedans", emplacement: .interieur, exposition: .exposee, prise: .forte),
        ]
        let resultats = MoteurVent.evaluer(plantes: plantes,
                                           heures: Aide.nuit(du: jour, temperature: 18, rafale: 80))
        #expect(resultats.count == 1)
        #expect(resultats.first?.nom == "Dehors")
    }

    @Test("Les niveaux nuls ne polluent pas la liste")
    func niveauxNulsEcartes() {
        let plantes = [Aide.plante(exposition: .abritee, prise: .faible)]
        let resultats = MoteurVent.evaluer(plantes: plantes,
                                           heures: Aide.nuit(du: jour, temperature: 18, rafale: 20))
        #expect(resultats.isEmpty)
    }

    @Test("Sans prevision, pas d'evaluation")
    func sansPrevision() {
        #expect(MoteurVent.evaluer(plante: Aide.plante(), heures: []) == nil)
    }
}
