import Foundation
import Observation
import SwiftUI

/// Etat central : plantes, reglages, lieu, previsions, plan du jour.
/// Tout le reste de l'interface lit d'ici.
@MainActor
@Observable
final class AppModel {

    // MARK: - Etat publie

    private(set) var plantes: [Plante] = []
    var reglages: Reglages {
        didSet {
            guard reglages != oldValue else { return }
            store.enregistrer(reglages, pour: .reglages)
            reconstruirePlan()
        }
    }

    private(set) var lieu: Lieu?
    /// Lieu fixe a la main, qui court-circuite la geolocalisation.
    private(set) var lieuManuel: Lieu?
    private(set) var previsions: Previsions?
    private(set) var plan: PlanDeLaNuit?
    private(set) var saison: Saison = .croissance
    private(set) var derniereErreur: String?
    private(set) var enChargement = false

    let localisation = LocationService()
    let notifications = NotificationService()

    // MARK: - Dependances

    private let store: Store
    private let meteo: any MeteoProviding

    init(store: Store = Store(), meteo: any MeteoProviding = OpenMeteoService()) {
        self.store = store
        self.meteo = meteo
        self.reglages = store.charger(Reglages.self, pour: .reglages) ?? .defaut
        self.plantes = store.charger([Plante].self, pour: .plantes) ?? []
        self.lieuManuel = store.charger(Lieu.self, pour: .lieuManuel)
        self.previsions = store.charger(Previsions.self, pour: .dernieresPrevisions)
        self.lieu = lieuManuel
    }

    // MARK: - Cycle de vie

    func demarrer() async {
        await notifications.rafraichirAutorisation()
        await rafraichir()
    }

    func rafraichir() async {
        enChargement = true
        defer { enChargement = false }

        if lieuManuel == nil {
            do {
                let position = try await localisation.position()
                lieu = position
            } catch {
                // Sans position, on retombe sur le dernier lieu connu, ou sur
                // rien du tout. L'interface le dit clairement plutot que
                // d'afficher les chiffres d'un endroit ou personne ne se
                // trouve.
                derniereErreur = error.localizedDescription
            }
        } else {
            lieu = lieuManuel
        }

        guard let lieu else { return }
        saison = Saison.courante(latitude: lieu.latitude)

        do {
            let arrondi = lieu.arrondi
            let recues = try await meteo.previsions(latitude: arrondi.latitude,
                                                    longitude: arrondi.longitude)
            previsions = recues
            store.enregistrer(recues, pour: .dernieresPrevisions)
            derniereErreur = nil
        } catch {
            derniereErreur = error.localizedDescription
            // Le cache reste en place : des previsions d'hier valent mieux que
            // rien, a condition de le signaler.
            if previsions != nil {
                previsions?.horsLigne = true
            }
        }

        reconstruirePlan()
        await programmerLesAlertes()
    }

    private func reconstruirePlan() {
        guard let previsions else { plan = nil; return }
        plan = MoteurPlan.construire(plantes: plantes,
                                     previsions: previsions,
                                     reglages: reglages)
    }

    private func programmerLesAlertes() async {
        guard let plan else { return }
        await notifications.programmer(plan: plan, reglages: reglages)
    }

    // MARK: - Plantes

    func ajouter(_ plante: Plante) {
        plantes.append(plante)
        enregistrerPlantes()
    }

    func modifier(_ plante: Plante) {
        guard let index = plantes.firstIndex(where: { $0.id == plante.id }) else { return }
        plantes[index] = plante
        enregistrerPlantes()
    }

    func supprimer(_ plante: Plante) {
        plantes.removeAll { $0.id == plante.id }
        enregistrerPlantes()
    }

    func plante(id: UUID) -> Plante? {
        plantes.first { $0.id == id }
    }

    private func enregistrerPlantes() {
        store.enregistrer(plantes, pour: .plantes)
        reconstruirePlan()
        Task { await programmerLesAlertes() }
    }

    // MARK: - Demenagements

    /// Rentre une plante et note pourquoi.
    ///
    /// Le motif n'est pas decoratif : c'est lui qui distingue une mise a l'abri
    /// pour une nuit d'un rangement pour l'hiver, et donc qui decide si
    /// l'application proposera de la ressortir demain matin.
    func rentrer(_ plante: Plante, motif: Demenagement.Motif = .manuel) {
        guard var copie = self.plante(id: plante.id) else { return }
        let temperature = plan?.aRentrer.first { $0.planteID == plante.id }?
            .minimum.temperatureCorrigee
        copie.demenagements.append(Demenagement(sens: .rentree, motif: motif,
                                                temperature: temperature))
        copie.emplacement = .interieur
        modifier(copie)
    }

    func sortir(_ plante: Plante, motif: Demenagement.Motif = .manuel) {
        guard var copie = self.plante(id: plante.id) else { return }
        copie.demenagements.append(Demenagement(sens: .sortie, motif: motif))
        copie.emplacement = .exterieur
        modifier(copie)
    }

    /// Rentre d'un coup tout ce que le plan du soir designe.
    func rentrerTout() {
        guard let plan else { return }
        for evaluation in plan.aRentrer {
            guard let plante = self.plante(id: evaluation.planteID) else { continue }
            rentrer(plante, motif: .gel)
        }
    }

    func ressortirTout() {
        guard let plan else { return }
        for candidat in plan.aRessortir {
            guard let plante = self.plante(id: candidat.planteID) else { continue }
            sortir(plante, motif: .saison)
        }
    }

    // MARK: - Acclimatation

    func commencerAcclimatation(_ plante: Plante, sens: Demenagement.Sens = .sortie) {
        guard var copie = self.plante(id: plante.id) else { return }
        copie.acclimatation = Acclimatation(sens: sens)
        copie.emplacement = .acclimatation
        modifier(copie)
    }

    /// Valide l'etape du jour. Une seule par jour.
    func validerEtape(_ plante: Plante) {
        guard var copie = self.plante(id: plante.id),
              var acclimatation = copie.acclimatation,
              !acclimatation.valideeAujourdhui() else { return }

        acclimatation.joursValides += 1
        acclimatation.derniereValidation = Date()

        if acclimatation.joursValides >= Acclimatation.duree {
            copie.acclimatation = nil
            copie.emplacement = acclimatation.sens == .sortie ? .exterieur : .interieur
            copie.demenagements.append(Demenagement(sens: acclimatation.sens, motif: .saison))
        } else {
            copie.acclimatation = acclimatation
        }
        modifier(copie)
    }

    func annulerAcclimatation(_ plante: Plante) {
        guard var copie = self.plante(id: plante.id) else { return }
        copie.acclimatation = nil
        copie.emplacement = .interieur
        modifier(copie)
    }

    // MARK: - Arrosage

    func arroser(_ plante: Plante, le date: Date = Date()) {
        guard var copie = self.plante(id: plante.id) else { return }
        copie.dernierArrosage = date
        modifier(copie)
    }

    /// Les vingt-quatre dernieres heures de prevision, qui servent a corriger
    /// l'arrosage de la pluie recue et de la chaleur subie.
    var heuresPassees: [ConditionHoraire] {
        guard let previsions else { return [] }
        let maintenant = Date()
        return previsions.heures(de: maintenant.addingTimeInterval(-86_400), a: maintenant)
    }

    var etatsArrosage: [EtatArrosage] {
        MoteurArrosage.etats(plantes: plantes, saison: saison, heuresPassees: heuresPassees)
    }

    var arrosagesDus: [EtatArrosage] {
        etatsArrosage.filter(\.aArroser)
    }

    // MARK: - Lieu

    func fixerLieu(_ lieu: Lieu?) {
        lieuManuel = lieu
        if let lieu {
            store.enregistrer(lieu, pour: .lieuManuel)
            self.lieu = lieu
        } else {
            store.retirer(.lieuManuel)
        }
        Task { await rafraichir() }
    }
}
