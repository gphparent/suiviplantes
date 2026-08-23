import Foundation

enum MeteoErreur: LocalizedError {
    case mauvaiseReponse(Int)
    case charieIllisible
    case seriesIncoherentes
    case serieVide

    var errorDescription: String? {
        switch self {
        case .mauvaiseReponse(let code):
            return "Le service meteo a repondu avec le code \(code)."
        case .charieIllisible:
            return "La reponse du service meteo est illisible."
        case .seriesIncoherentes:
            return "Les series de prevision ne concordent pas."
        case .serieVide:
            return "Le service meteo n'a renvoye aucune heure de prevision."
        }
    }
}

protocol MeteoProviding: Sendable {
    /// Nom du service, affiche dans les reglages. Crediter sa source n'est pas
    /// une politesse : c'est une condition d'utilisation, chez Apple comme chez
    /// Open-Meteo.
    var nomDuService: String { get }

    /// - Parameter fuseau: fuseau du lieu, quand l'appelant le connait deja.
    ///   Les services qui le resolvent eux-memes l'ignorent.
    func previsions(latitude: Double, longitude: Double,
                    fuseau: TimeZone?) async throws -> Previsions
}

/// Acces aux previsions d'Open-Meteo.
///
/// Open-Meteo ne demande pas de cle. Son usage gratuit est reserve aux projets
/// non commerciaux, ce qui convient a un usage familial ; une diffusion sur
/// l'App Store demanderait un abonnement, ou un basculement vers WeatherKit.
///
/// Six series suffisent, et chacune sert a quelque chose de precis :
/// temperature et point de rosee pour la chute nocturne, nebulosite et vent
/// pour son ampleur, rafales pour le renversement des pots, precipitations pour
/// l'arrosage.
struct OpenMeteoService: MeteoProviding {

    let nomDuService = "Open-Meteo"

    /// Trois jours de passe pour l'arrosage, sept de prevision pour planifier
    /// une rentree d'automne.
    static let joursPasses = 3
    static let joursPrevus = 7

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Open-Meteo resout le fuseau lui-meme, et mieux que l'appelant : l'indice
    /// est donc ignore.
    func previsions(latitude: Double, longitude: Double,
                    fuseau: TimeZone? = nil) async throws -> Previsions {
        var composants = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        composants.queryItems = [
            URLQueryItem(name: "latitude", value: String(format: "%.4f", latitude)),
            URLQueryItem(name: "longitude", value: String(format: "%.4f", longitude)),
            URLQueryItem(name: "hourly", value: "temperature_2m,dew_point_2m,cloud_cover,"
                         + "wind_speed_10m,wind_gusts_10m,precipitation"),
            URLQueryItem(name: "wind_speed_unit", value: "kmh"),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "timeformat", value: "unixtime"),
            URLQueryItem(name: "past_days", value: String(Self.joursPasses)),
            URLQueryItem(name: "forecast_days", value: String(Self.joursPrevus)),
        ]

        let (donnees, reponse) = try await session.data(from: composants.url!)
        guard let http = reponse as? HTTPURLResponse else { throw MeteoErreur.charieIllisible }
        guard http.statusCode == 200 else { throw MeteoErreur.mauvaiseReponse(http.statusCode) }

        let charge = try JSONDecoder().decode(ChargeOpenMeteo.self, from: donnees)
        return try Self.convertir(charge)
    }

    /// Conversion isolee de la couche reseau, pour qu'elle soit testable a
    /// partir d'un fichier JSON.
    static func convertir(_ charge: ChargeOpenMeteo) throws -> Previsions {
        let h = charge.hourly
        let n = h.time.count
        guard h.temperature_2m.count == n, h.dew_point_2m.count == n,
              h.cloud_cover.count == n, h.wind_speed_10m.count == n,
              h.wind_gusts_10m.count == n, h.precipitation.count == n else {
            throw MeteoErreur.seriesIncoherentes
        }

        var heures: [ConditionHoraire] = []
        heures.reserveCapacity(n)
        for i in 0..<n {
            // Les series d'Open-Meteo admettent des trous. Une heure incomplete
            // est ecartee plutot que comblee : une valeur inventee au creux de
            // la nuit produirait exactement la fausse alerte qu'on cherche a
            // eviter.
            guard let t = h.temperature_2m[i], let rosee = h.dew_point_2m[i],
                  let nuages = h.cloud_cover[i], let vent = h.wind_speed_10m[i],
                  let rafale = h.wind_gusts_10m[i] else { continue }

            heures.append(ConditionHoraire(date: Date(timeIntervalSince1970: TimeInterval(h.time[i])),
                                           temperature: t,
                                           pointDeRosee: rosee,
                                           nebulosite: nuages,
                                           vent: vent,
                                           rafale: rafale,
                                           precipitation: h.precipitation[i] ?? 0))
        }

        return Previsions(recupereesLe: Date(),
                          latitude: charge.latitude,
                          longitude: charge.longitude,
                          identifiantFuseau: charge.timezone,
                          heures: heures.sorted { $0.date < $1.date })
    }
}

/// Reponse d'Open-Meteo, telle qu'elle arrive.
struct ChargeOpenMeteo: Decodable, Sendable {
    let latitude: Double
    let longitude: Double
    let timezone: String
    let hourly: Series

    struct Series: Decodable, Sendable {
        let time: [Int]
        let temperature_2m: [Double?]
        let dew_point_2m: [Double?]
        let cloud_cover: [Double?]
        let wind_speed_10m: [Double?]
        let wind_gusts_10m: [Double?]
        let precipitation: [Double?]
    }
}
