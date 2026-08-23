import Foundation
import Testing
@testable import Serre

struct RisqueGelTests {

    private let jour = Aide.date(2026, 5, 20)

    private func evaluer(temperature: Double,
                         plante: Plante = Aide.plante(),
                         marge: Double = 1) -> EvaluationGel? {
        // La correction est desactivee : ce qui se teste ici, c'est la grille
        // des niveaux, pas la physique, qui a sa propre suite.
        MoteurGel.evaluer(plante: plante,
                          heures: Aide.nuit(du: jour, temperature: temperature),
                          marge: marge,
                          correctionRadiative: false)
    }

    // MARK: - Grille des niveaux

    @Test("Sous le seuil critique majore de la marge, le niveau est critique")
    func niveauCritique() {
        #expect(evaluer(temperature: 2)?.niveau == .critique)
        #expect(evaluer(temperature: 3)?.niveau == .critique)
    }

    @Test("Juste au-dessus du critique, le niveau est danger")
    func niveauDanger() {
        #expect(evaluer(temperature: 4)?.niveau == .danger)
        #expect(evaluer(temperature: 5)?.niveau == .danger)
    }

    @Test("Sous le seuil de confort, le niveau est inconfort")
    func niveauInconfort() {
        #expect(evaluer(temperature: 8)?.niveau == .inconfort)
    }

    @Test("Un peu au-dessus du confort, le niveau est surveiller")
    func niveauSurveiller() {
        #expect(evaluer(temperature: 13)?.niveau == .surveiller)
    }

    @Test("Une nuit douce ne declenche rien")
    func niveauAucun() {
        #expect(evaluer(temperature: 20)?.niveau == .aucun)
    }

    @Test("Seuls les niveaux danger et critique exigent un geste")
    func gesteExige() {
        #expect(!NiveauRisque.aucun.exigeUnGeste)
        #expect(!NiveauRisque.surveiller.exigeUnGeste)
        #expect(!NiveauRisque.inconfort.exigeUnGeste)
        #expect(NiveauRisque.danger.exigeUnGeste)
        #expect(NiveauRisque.critique.exigeUnGeste)
    }

    @Test("Une marge plus large declenche plus tot")
    func margeElargie() {
        // Quatre degres : deja un danger avec la marge par defaut, franchement
        // critique des qu'on se donne trois degres de securite.
        #expect(evaluer(temperature: 4, marge: 1)?.niveau == .danger)
        #expect(evaluer(temperature: 4, marge: 3)?.niveau == .critique)
    }

    // MARK: - Seuil racinaire

    @Test("En pot, une plante rustique perd cinq degres de rusticite")
    func seuilRacinaireEnPot() {
        let enPot = Aide.plante(critique: -10, assise: .potAuSol)
        #expect(enPot.seuilCritiqueEffectif == -5)
    }

    @Test("En pleine terre, le seuil reste celui de la plante")
    func seuilRacinairePleineTerre() {
        let enTerre = Aide.plante(critique: -10, assise: .pleineTerre)
        #expect(enTerre.seuilCritiqueEffectif == -10)
    }

    @Test("Une tropicale qui meurt deja au-dessus de zero n'a rien de plus a perdre")
    func seuilRacinaireTropicale() {
        let tropicale = Aide.plante(critique: 4, assise: .potSureleve)
        #expect(tropicale.seuilCritiqueEffectif == 4)
    }

    @Test("Le seuil racinaire est bien celui qui sert au verdict")
    func seuilRacinaireUtilise() {
        let enPot = Aide.plante(confort: 0, critique: -10, assise: .potAuSol)
        let enTerre = Aide.plante(confort: 0, critique: -10, assise: .pleineTerre)
        // Moins six degres : mortel pour la motte en pot, anodin en pleine terre.
        #expect(evaluer(temperature: -6, plante: enPot)?.niveau == .critique)
        #expect(evaluer(temperature: -6, plante: enTerre)?.niveau == .inconfort)
    }

    // MARK: - Selection et tri

    @Test("Seules les plantes qui dorment dehors sont evaluees")
    func selectionDesPlantes() {
        let plantes = [
            Aide.plante(nom: "Dehors", emplacement: .exterieur),
            Aide.plante(nom: "Dedans", emplacement: .interieur),
        ]
        let resultats = MoteurGel.evaluer(plantes: plantes,
                                          heures: Aide.nuit(du: jour, temperature: 0),
                                          reglages: .defaut)
        #expect(resultats.count == 1)
        #expect(resultats.first?.nom == "Dehors")
    }

    @Test("Une plante en acclimatation ne dort dehors qu'a partir du huitieme jour")
    func acclimatationEtNuit() {
        let debut = Aide.plante(emplacement: .acclimatation,
                                acclimatation: Acclimatation(joursValides: 2))
        let fin = Aide.plante(emplacement: .acclimatation,
                              acclimatation: Acclimatation(joursValides: 8))
        #expect(!debut.dortDehorsCetteNuit)
        #expect(fin.dortDehorsCetteNuit)
    }

    @Test("Les evaluations sont triees du plus grave au moins grave")
    func triDesEvaluations() {
        let plantes = [
            Aide.plante(nom: "Rustique", confort: -5, critique: -20),
            Aide.plante(nom: "Fragile", confort: 12, critique: 5),
            Aide.plante(nom: "Moyenne", confort: 5, critique: 0),
        ]
        let resultats = MoteurGel.evaluer(plantes: plantes,
                                          heures: Aide.nuit(du: jour, temperature: 4),
                                          reglages: .defaut)
        #expect(resultats.first?.nom == "Fragile")
        #expect(resultats.last?.nom == "Rustique")
    }

    @Test("Sans prevision, il n'y a pas d'evaluation")
    func sansPrevision() {
        #expect(MoteurGel.evaluer(plante: Aide.plante(), heures: []) == nil)
    }

    // MARK: - Retour dehors

    @Test("Une nuit nettement douce autorise le retour dehors")
    func retourAutorise() {
        let plante = Aide.plante(confort: 10, assise: .protege)
        let douce = Aide.nuit(du: jour, temperature: 18, nebulosite: 100, vent: 20)
        #expect(MoteurGel.peutRessortir(plante: plante, heures: douce))
    }

    @Test("Une nuit tout juste au-dessus du confort ne suffit pas")
    func retourRefuse() {
        // La marge exigee evite le va-et-vient quotidien, qui coute plus cher a
        // la plante que de la laisser a l'interieur.
        let plante = Aide.plante(confort: 10, assise: .protege)
        let limite = Aide.nuit(du: jour, temperature: 11.5, nebulosite: 100, vent: 20)
        #expect(!MoteurGel.peutRessortir(plante: plante, heures: limite))
    }

    @Test("Sans prevision, on ne ressort rien")
    func retourSansPrevision() {
        #expect(!MoteurGel.peutRessortir(plante: Aide.plante(), heures: []))
    }

    @Test("La gelee est annoncee des que la temperature subie passe sous zero")
    func geleeAttendue() {
        let gel = evaluer(temperature: -1)
        let doux = evaluer(temperature: 4)
        #expect(gel?.geleeAttendue == true)
        #expect(doux?.geleeAttendue == false)
    }
}
