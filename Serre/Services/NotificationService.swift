import Foundation
import Observation
import UserNotifications

/// Programmation des alertes locales.
///
/// Deux rendez-vous quotidiens, et un seul principe : prevenir pendant qu'il
/// reste du temps pour agir.
///
/// L'alerte d'action tombe au milieu de l'apres-midi, pas le soir. Une
/// notification a vingt et une heures qui annonce du gel a trois heures du
/// matin arrive alors qu'il fait noir, qu'il fait deja froid, et que personne
/// n'a envie de sortir porter six pots. A quinze heures, il fait encore clair.
///
/// Le bilan du matin ferme la boucle, et c'est ce qu'aucune autre application
/// ne fait : il rappelle de ressortir ce qui a ete rentre la veille.
@MainActor
@Observable
final class NotificationService {

    enum Identifiant {
        static let alerteSoir = "alerte.soir"
        static let bilanMatin = "bilan.matin"
        static let ventImminent = "vent.imminent"
    }

    private(set) var autorisation: UNAuthorizationStatus = .notDetermined

    private let centre = UNUserNotificationCenter.current()

    func rafraichirAutorisation() async {
        autorisation = await centre.notificationSettings().authorizationStatus
    }

    @discardableResult
    func demanderAutorisation() async -> Bool {
        do {
            let accorde = try await centre.requestAuthorization(options: [.alert, .sound, .badge])
            await rafraichirAutorisation()
            return accorde
        } catch {
            await rafraichirAutorisation()
            return false
        }
    }

    /// Depose les deux rendez-vous quotidiens, avec le contenu calcule a partir
    /// du plan du jour.
    func programmer(plan: PlanDeLaNuit, reglages: Reglages) async {
        await annuler([Identifiant.alerteSoir, Identifiant.bilanMatin])
        guard autorisation == .authorized || autorisation == .provisional else { return }

        if let contenu = Self.contenuDuSoir(plan: plan) {
            await deposer(identifiant: Identifiant.alerteSoir, contenu: contenu,
                          heure: reglages.heureAlerteSoir, minute: reglages.minuteAlerteSoir)
        }
        if let contenu = Self.contenuDuMatin(plan: plan) {
            await deposer(identifiant: Identifiant.bilanMatin, contenu: contenu,
                          heure: reglages.heureBilanMatin, minute: reglages.minuteBilanMatin)
        }
    }

    /// L'alerte d'action : ce qu'il faut rentrer, nomme.
    ///
    /// Une notification qui dit « risque de gel » oblige a ouvrir l'application,
    /// a lire une liste, a se rappeler ce qu'on avait decide. Une notification
    /// qui nomme les plantes se suffit a elle-meme.
    nonisolated static func contenuDuSoir(plan: PlanDeLaNuit) -> UNMutableNotificationContent? {
        let ventGrave = plan.vent.filter { $0.niveau.exigeUnGeste }
        guard !plan.aRentrer.isEmpty || !ventGrave.isEmpty else { return nil }

        let contenu = UNMutableNotificationContent()

        if !plan.aRentrer.isEmpty {
            let minimum = plan.aRentrer[0].minimum.temperatureCorrigee
            let arrondi = String(format: "%.0f", minimum)
            contenu.title = plan.aRentrer.count == 1
                ? "Une plante a rentrer"
                : "\(plan.aRentrer.count) plantes a rentrer"
            contenu.subtitle = "Jusqu'a \(arrondi) degres au sol cette nuit"
            contenu.body = liste(plan.aRentrer.map(\.nom))
        } else {
            let rafale = String(format: "%.0f", ventGrave[0].rafaleSurPlace)
            contenu.title = ventGrave.count == 1
                ? "Une plante a mettre a l'abri du vent"
                : "\(ventGrave.count) plantes a mettre a l'abri du vent"
            contenu.subtitle = "Rafales estimees a \(rafale) km/h sur place"
            contenu.body = liste(ventGrave.map(\.nom))
        }

        contenu.sound = .default
        return contenu
    }

    /// Le bilan du matin : ce qui peut ressortir, et l'etape d'acclimatation du
    /// jour.
    nonisolated static func contenuDuMatin(plan: PlanDeLaNuit) -> UNMutableNotificationContent? {
        let etapes = plan.acclimatations.filter(\.favorable)
        guard !plan.aRessortir.isEmpty || !etapes.isEmpty else { return nil }

        let contenu = UNMutableNotificationContent()
        var lignes: [String] = []

        if !plan.aRessortir.isEmpty {
            contenu.title = plan.aRessortir.count == 1
                ? "Une plante peut ressortir"
                : "\(plan.aRessortir.count) plantes peuvent ressortir"
            lignes.append(liste(plan.aRessortir.map(\.nom)))
        } else {
            contenu.title = "Acclimatation du jour"
        }

        for etape in etapes {
            guard let detail = etape.etape else { continue }
            let heures = detail.heures >= 24
                ? "toute la journee"
                : String(format: "%.0f h", detail.heures)
            lignes.append("\(etape.nom) : jour \(etape.jour), \(heures) en \(detail.lumiere.nom.lowercased()).")
        }

        contenu.body = lignes.joined(separator: "\n")
        contenu.sound = .default
        return contenu
    }

    nonisolated static func liste(_ noms: [String]) -> String {
        guard noms.count > 1 else { return noms.first ?? "" }
        let debut = noms.dropLast().joined(separator: ", ")
        return "\(debut) et \(noms[noms.count - 1])"
    }

    private func deposer(identifiant: String, contenu: UNNotificationContent,
                         heure: Int, minute: Int) async {
        var composants = DateComponents()
        composants.hour = heure
        composants.minute = minute
        let declencheur = UNCalendarNotificationTrigger(dateMatching: composants, repeats: false)
        let requete = UNNotificationRequest(identifier: identifiant,
                                            content: contenu,
                                            trigger: declencheur)
        try? await centre.add(requete)
    }

    func annuler(_ identifiants: [String]) async {
        centre.removePendingNotificationRequests(withIdentifiers: identifiants)
    }

    func toutAnnuler() async {
        centre.removeAllPendingNotificationRequests()
    }
}
