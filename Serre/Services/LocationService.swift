import CoreLocation
import Foundation
import Observation

/// Position de l'utilisateur.
///
/// L'application n'a besoin de la position qu'une fois de temps en temps, et
/// grossierement : les coordonnees partent arrondies au centieme de degre, soit
/// environ un kilometre. Un lieu fixe a la main remplace entierement le service,
/// ce qui permet de s'en passer.
@MainActor
@Observable
final class LocationService: NSObject, CLLocationManagerDelegate {

    private(set) var autorisation: CLAuthorizationStatus
    private(set) var derniereErreur: String?

    private let gestionnaire = CLLocationManager()
    private var continuations: [CheckedContinuation<Lieu, Error>] = []

    enum Erreur: LocalizedError {
        case refusee
        case indisponible

        var errorDescription: String? {
            switch self {
            case .refusee:
                return "L'acces a la position est refuse. Fixez un lieu a la main dans les reglages."
            case .indisponible:
                return "La position n'a pas pu etre determinee."
            }
        }
    }

    override init() {
        autorisation = gestionnaire.authorizationStatus
        super.init()
        gestionnaire.delegate = self
        gestionnaire.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func demanderAutorisation() {
        gestionnaire.requestWhenInUseAuthorization()
    }

    func position() async throws -> Lieu {
        switch autorisation {
        case .notDetermined:
            gestionnaire.requestWhenInUseAuthorization()
        case .denied, .restricted:
            throw Erreur.refusee
        default:
            break
        }

        return try await withCheckedThrowingContinuation { continuation in
            continuations.append(continuation)
            gestionnaire.requestLocation()
        }
    }

    private func resoudre(_ resultat: Result<Lieu, Error>) {
        let enAttente = continuations
        continuations.removeAll()
        for continuation in enAttente {
            continuation.resume(with: resultat)
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let statut = manager.authorizationStatus
        Task { @MainActor in
            self.autorisation = statut
            if statut == .denied || statut == .restricted {
                self.resoudre(.failure(Erreur.refusee))
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didUpdateLocations locations: [CLLocation]) {
        guard let derniere = locations.last else { return }
        let latitude = derniere.coordinate.latitude
        let longitude = derniere.coordinate.longitude
        Task { @MainActor in
            let lieu = Lieu(latitude: latitude, longitude: longitude,
                            nom: nil, identifiantFuseau: TimeZone.current.identifier)
            self.derniereErreur = nil
            self.resoudre(.success(lieu))
            await self.nommer(lieu)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.derniereErreur = error.localizedDescription
            self.resoudre(.failure(Erreur.indisponible))
        }
    }

    /// Nom lisible du lieu, obtenu apres coup. L'echec est sans consequence :
    /// les previsions n'ont besoin que des coordonnees.
    private(set) var dernierNom: String?

    private func nommer(_ lieu: Lieu) async {
        let position = CLLocation(latitude: lieu.latitude, longitude: lieu.longitude)
        let geocodeur = CLGeocoder()
        guard let reperes = try? await geocodeur.reverseGeocodeLocation(position),
              let repere = reperes.first else { return }
        dernierNom = repere.locality ?? repere.subAdministrativeArea ?? repere.administrativeArea
    }
}
