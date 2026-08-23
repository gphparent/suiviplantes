import Foundation
import Testing
@testable import Serre

struct MoteurArrosageTests {

    private let calendrier = Aide.calendrierMontreal
    private let maintenant = Aide.date(2026, 7, 15, 12)

    private func ilYA(_ jours: Int, de reference: Date? = nil) -> Date {
        Aide.calendrierMontreal.date(byAdding: .day, value: -jours,
                                     to: reference ?? Aide.date(2026, 7, 15, 12))!
    }

    // MARK: - Intervalle de base

    @Test("Dehors, la plante suit toujours le rythme d'ete")
    func rythmeDehors() {
        let plante = Aide.plante(emplacement: .exterieur, arrosageEte: 3, arrosageHiver: 15)
        #expect(MoteurArrosage.intervalle(plante: plante, saison: .croissance) == 3)
        #expect(MoteurArrosage.intervalle(plante: plante, saison: .repos) == 3)
    }

    @Test("Rentree en saison de repos, elle boit deux a trois fois moins")
    func rythmeInterieurHiver() {
        // C'est l'erreur classique de novembre : continuer au rythme de l'ete
        // et pourrir les racines d'une plante qui ne pousse plus.
        let plante = Aide.plante(emplacement: .interieur, arrosageEte: 3, arrosageHiver: 15)
        #expect(MoteurArrosage.intervalle(plante: plante, saison: .repos) == 15)
    }

    @Test("Rentree en saison de croissance, le rythme reste celui de l'ete")
    func rythmeInterieurEte() {
        let plante = Aide.plante(emplacement: .interieur, arrosageEte: 3, arrosageHiver: 15)
        #expect(MoteurArrosage.intervalle(plante: plante, saison: .croissance) == 3)
    }

    @Test("Un demenagement bascule le rythme a lui seul")
    func demenagementBasculeLeRythme() {
        var plante = Aide.plante(emplacement: .exterieur, arrosageEte: 3, arrosageHiver: 15)
        let dehors = MoteurArrosage.intervalle(plante: plante, saison: .repos)
        plante.emplacement = .interieur
        let dedans = MoteurArrosage.intervalle(plante: plante, saison: .repos)
        #expect(dehors == 3)
        #expect(dedans == 15)
    }

    // MARK: - Correction meteo

    @Test("Sans prevision, l'intervalle n'est pas corrige")
    func facteurNeutre() {
        #expect(MoteurArrosage.facteurMeteo(heures: []) == 1)
    }

    @Test("Une canicule resserre l'intervalle")
    func facteurChaud() {
        let chaud = Aide.nuit(du: Aide.date(2026, 7, 15), temperature: 32, vent: 10)
        #expect(MoteurArrosage.facteurMeteo(heures: chaud) < 1)
    }

    @Test("Une semaine fraiche l'allonge")
    func facteurFrais() {
        let frais = Aide.nuit(du: Aide.date(2026, 9, 20), temperature: 10, vent: 10)
        #expect(MoteurArrosage.facteurMeteo(heures: frais) > 1)
    }

    @Test("Le facteur reste borne : on ajuste, on ne recalcule pas une evapotranspiration")
    func facteurBorne() {
        let extreme = Aide.nuit(du: Aide.date(2026, 7, 15), temperature: 60, vent: 120)
        let glacial = Aide.nuit(du: Aide.date(2026, 1, 15), temperature: -40, vent: 0)
        #expect(MoteurArrosage.facteurMeteo(heures: extreme) >= 0.6)
        #expect(MoteurArrosage.facteurMeteo(heures: glacial) <= 1.6)
    }

    // MARK: - Pluie recue

    @Test("Un pot a decouvert recoit toute la pluie")
    func pluieDecouvert() {
        let plante = Aide.plante(emplacement: .exterieur, assise: .potAuSol)
        let heures = Aide.nuit(du: Aide.date(2026, 7, 14), temperature: 18, precipitation: 2)
        #expect(MoteurArrosage.pluieRecue(plante: plante, heures: heures) > 30)
    }

    @Test("Un pot sous un abri n'en recoit aucune, meme sous l'orage")
    func pluieAbritee() {
        let plante = Aide.plante(emplacement: .exterieur, assise: .abrite)
        let heures = Aide.nuit(du: Aide.date(2026, 7, 14), temperature: 18, precipitation: 5)
        #expect(MoteurArrosage.pluieRecue(plante: plante, heures: heures) == 0)
    }

    @Test("Contre un mur, elle en recoit la moitie")
    func pluieContreUnMur() {
        let mur = Aide.plante(emplacement: .exterieur, assise: .contreUnMur)
        let decouvert = Aide.plante(emplacement: .exterieur, assise: .potAuSol)
        let heures = Aide.nuit(du: Aide.date(2026, 7, 14), temperature: 18, precipitation: 2)
        let recueMur = MoteurArrosage.pluieRecue(plante: mur, heures: heures)
        let recueDecouvert = MoteurArrosage.pluieRecue(plante: decouvert, heures: heures)
        #expect(abs(recueMur - recueDecouvert / 2) < 1e-9)
    }

    @Test("Une plante a l'interieur ne recoit rien")
    func pluieInterieur() {
        let plante = Aide.plante(emplacement: .interieur, assise: .potAuSol)
        let heures = Aide.nuit(du: Aide.date(2026, 7, 14), temperature: 18, precipitation: 5)
        #expect(MoteurArrosage.pluieRecue(plante: plante, heures: heures) == 0)
    }

    // MARK: - Echeance

    @Test("Une plante arrosee il y a exactement un intervalle est due aujourd'hui")
    func echeanceAujourdhui() {
        let plante = Aide.plante(emplacement: .exterieur, arrosageEte: 4,
                                 dernierArrosage: ilYA(4))
        let etat = MoteurArrosage.etat(plante: plante, saison: .croissance,
                                       maintenant: maintenant, calendrier: calendrier)
        #expect(etat.joursRestants == 0)
        #expect(etat.aujourdHui)
        #expect(etat.aArroser)
    }

    @Test("Une plante oubliee est signalee en retard")
    func echeanceEnRetard() {
        let plante = Aide.plante(emplacement: .exterieur, arrosageEte: 4,
                                 dernierArrosage: ilYA(10))
        let etat = MoteurArrosage.etat(plante: plante, saison: .croissance,
                                       maintenant: maintenant, calendrier: calendrier)
        #expect(etat.joursRestants == -6)
        #expect(etat.enRetard)
    }

    @Test("Une plante arrosee hier attend encore")
    func echeanceAVenir() {
        let plante = Aide.plante(emplacement: .exterieur, arrosageEte: 4,
                                 dernierArrosage: ilYA(1))
        let etat = MoteurArrosage.etat(plante: plante, saison: .croissance,
                                       maintenant: maintenant, calendrier: calendrier)
        #expect(etat.joursRestants == 3)
        #expect(!etat.aArroser)
    }

    @Test("Une bonne pluie remet le compteur a zero")
    func pluieRemetAZero() {
        let plante = Aide.plante(emplacement: .exterieur, assise: .potAuSol,
                                 arrosageEte: 4, dernierArrosage: ilYA(10))
        // Vingt heures a un millimetre : bien au-dela du seuil d'equivalence.
        let debut = calendrier.date(byAdding: .hour, value: -20, to: maintenant)!
        let pluie = (0..<20).map { decalage in
            Aide.heure(debut.addingTimeInterval(TimeInterval(decalage * 3600)),
                       temperature: 18, vent: 10, precipitation: 1)
        }
        let etat = MoteurArrosage.etat(plante: plante, saison: .croissance,
                                       heuresPassees: pluie,
                                       maintenant: maintenant, calendrier: calendrier)
        #expect(!etat.enRetard)
        #expect(etat.raison.contains("pluie"))
    }

    @Test("Une petite pluie ne compte pas pour un arrosage")
    func petitePluieIgnoree() {
        let plante = Aide.plante(emplacement: .exterieur, assise: .potAuSol,
                                 arrosageEte: 4, dernierArrosage: ilYA(10))
        let debut = calendrier.date(byAdding: .hour, value: -20, to: maintenant)!
        let bruine = (0..<20).map { decalage in
            Aide.heure(debut.addingTimeInterval(TimeInterval(decalage * 3600)),
                       temperature: 18, vent: 10, precipitation: 0.1)
        }
        let etat = MoteurArrosage.etat(plante: plante, saison: .croissance,
                                       heuresPassees: bruine,
                                       maintenant: maintenant, calendrier: calendrier)
        #expect(etat.enRetard)
    }

    @Test("L'intervalle ne descend jamais sous un jour")
    func intervalleMinimum() {
        let plante = Aide.plante(emplacement: .exterieur, arrosageEte: 1)
        let chaud = Aide.nuit(du: Aide.date(2026, 7, 15), temperature: 38, vent: 40)
        let etat = MoteurArrosage.etat(plante: plante, saison: .croissance,
                                       heuresPassees: chaud,
                                       maintenant: maintenant, calendrier: calendrier)
        #expect(etat.intervalle >= 1)
    }

    @Test("Les etats sont tries du plus urgent au moins urgent")
    func triDesEtats() {
        let plantes = [
            Aide.plante(nom: "Recente", emplacement: .exterieur, arrosageEte: 4,
                        dernierArrosage: ilYA(1)),
            Aide.plante(nom: "Oubliee", emplacement: .exterieur, arrosageEte: 4,
                        dernierArrosage: ilYA(12)),
        ]
        let etats = MoteurArrosage.etats(plantes: plantes, saison: .croissance,
                                         maintenant: maintenant, calendrier: calendrier)
        #expect(etats.first?.nom == "Oubliee")
    }
}

struct SaisonTests {

    @Test("Au solstice d'ete, le jour dure plus de quinze heures a Montreal")
    func solsticeEte() {
        let duree = Saison.longueurDuJour(jourDeLAnnee: 172, latitude: 45.5)
        #expect(abs(duree - 15.7) < 0.3)
    }

    @Test("Au solstice d'hiver, il en dure moins de neuf")
    func solsticeHiver() {
        let duree = Saison.longueurDuJour(jourDeLAnnee: 355, latitude: 45.5)
        #expect(abs(duree - 8.7) < 0.3)
    }

    @Test("A l'equinoxe, le jour et la nuit s'equilibrent")
    func equinoxe() {
        let duree = Saison.longueurDuJour(jourDeLAnnee: 80, latitude: 45.5)
        #expect(abs(duree - 12) < 0.3)
    }

    @Test("A l'equateur, le jour dure douze heures toute l'annee")
    func equateur() {
        for jour in stride(from: 1, through: 365, by: 30) {
            let duree = Saison.longueurDuJour(jourDeLAnnee: jour, latitude: 0)
            #expect(abs(duree - 12) < 0.2)
        }
    }

    @Test("L'ete est une saison de croissance, decembre une saison de repos")
    func bascule() {
        let calendrier = Aide.calendrierMontreal
        #expect(Saison.courante(date: Aide.date(2026, 7, 1), latitude: 45.5,
                                calendrier: calendrier) == .croissance)
        #expect(Saison.courante(date: Aide.date(2026, 12, 15), latitude: 45.5,
                                calendrier: calendrier) == .repos)
    }

    @Test("La bascule depend de la latitude, pas du calendrier")
    func basculeSelonLatitude() {
        // Sous les tropiques, le jour ne descend jamais sous onze heures : la
        // plante ne connait pas de saison de repos lumineuse.
        let calendrier = Aide.calendrierMontreal
        #expect(Saison.courante(date: Aide.date(2026, 12, 15), latitude: 10,
                                calendrier: calendrier) == .croissance)
    }
}
