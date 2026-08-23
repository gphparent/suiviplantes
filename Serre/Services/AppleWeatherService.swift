import CoreLocation
import Foundation
import Observation
import WeatherKit

/// Acces aux previsions par WeatherKit.
///
/// C'est la source retenue pour une diffusion publique : l'usage gratuit
/// d'Open-Meteo est reserve aux projets non commerciaux, ce qui exclut l'App
/// Store meme pour une application gratuite. WeatherKit accorde 500 000 appels
/// par mois avec l'adhesion au programme developpeur que la publication exige
/// de toute facon.
///
/// Les six series dont le moteur a besoin sont toutes disponibles. Deux
/// differences d'unites avec Open-Meteo, et une seule vraie subtilite :
/// WeatherKit exprime la nebulosite de zero a un, la ou le moteur raisonne en
/// pourcentage, et la rafale est facultative — une heure sans rafale annoncee
/// retombe sur le vent moyen plutot que sur zero, qui ferait passer un coup de
/// vent pour un calme plat.
///
/// L'attribution a Apple Weather est obligatoire : voir `AttributionMeteo` et
/// la section correspondante des reglages.
struct AppleWeatherService: MeteoProviding {

    /// Trois jours de passe pour l'arrosage, sept de prevision pour planifier
    /// une rentree d'automne.
    static let joursPasses = 3
    static let joursPrevus = 7

    func previsions(latitude: Double, longitude: Double,
                    fuseau: TimeZone? = nil) async throws -> Previsions {

        let position = CLLocation(latitude: latitude, longitude: longitude)
        let maintenant = Date()
        let debut = maintenant.addingTimeInterval(-Double(Self.joursPasses) * 86_400)
        let fin = maintenant.addingTimeInterval(Double(Self.joursPrevus) * 86_400)

        let serie = try await WeatherService.shared.weather(
            for: position,
            including: .hourly(startDate: debut, endDate: fin))

        let heures = serie.forecast.map(Self.convertir)
        guard !heures.isEmpty else { throw MeteoErreur.serieVide }

        return Previsions(recupereesLe: maintenant,
                          latitude: latitude,
                          longitude: longitude,
                          identifiantFuseau: (fuseau ?? .current).identifier,
                          heures: heures.sorted { $0.date < $1.date })
    }

    /// Conversion d'une heure WeatherKit.
    ///
    /// `HourWeather` n'a pas d'initialiseur public : ce corps-ci ne peut pas
    /// etre couvert par un test. Les deux endroits ou l'on peut reellement se
    /// tromper sont donc sortis dans `Conversion`, qui, lui, se verifie.
    static func convertir(_ heure: HourWeather) -> ConditionHoraire {
        ConditionHoraire(
            date: heure.date,
            temperature: heure.temperature.converted(to: .celsius).value,
            pointDeRosee: heure.dewPoint.converted(to: .celsius).value,
            nebulosite: Conversion.nebulosite(fraction: heure.cloudCover),
            vent: heure.wind.speed.converted(to: .kilometersPerHour).value,
            rafale: Conversion.rafale(
                rafale: heure.wind.gust?.converted(to: .kilometersPerHour).value,
                vent: heure.wind.speed.converted(to: .kilometersPerHour).value),
            precipitation: heure.precipitationAmount.converted(to: .millimeters).value)
    }

    /// Les deux ecarts entre ce que WeatherKit fournit et ce que le moteur
    /// attend.
    enum Conversion {

        /// WeatherKit exprime la nebulosite de zero a un ; le moteur raisonne en
        /// pourcentage, comme Open-Meteo. Une valeur hors bornes est ramenee
        /// dans l'intervalle plutot que propagee : le facteur de ciel doit
        /// rester entre 0,2 et 1.
        static func nebulosite(fraction: Double) -> Double {
            min(max(fraction, 0), 1) * 100
        }

        /// Une rafale absente n'est pas une rafale nulle.
        ///
        /// Traiter le silence comme un calme plat ferait passer un coup de vent
        /// pour une nuit tranquille, ce qui est exactement l'erreur a ne pas
        /// commettre dans une application d'alertes. On retombe sur le vent
        /// moyen, qui est un plancher honnete.
        static func rafale(rafale: Double?, vent: Double) -> Double {
            guard let rafale, rafale > 0 else { return vent }
            return max(rafale, vent)
        }
    }
}

/// Attribution obligatoire d'Apple Weather.
///
/// WeatherKit impose d'afficher la marque et de mener a la page des sources de
/// donnees. Ce n'est pas une politesse : c'est une condition d'utilisation du
/// service.
@MainActor
@Observable
final class AttributionMeteo {

    private(set) var marqueClaire: URL?
    private(set) var marqueSombre: URL?
    private(set) var pageLegale: URL?
    private(set) var nomDuService: String?

    func charger() async {
        guard pageLegale == nil else { return }
        guard let attribution = try? await WeatherService.shared.attribution else { return }
        marqueClaire = attribution.combinedMarkLightURL
        marqueSombre = attribution.combinedMarkDarkURL
        pageLegale = attribution.legalPageURL
        nomDuService = attribution.serviceName
    }
}
