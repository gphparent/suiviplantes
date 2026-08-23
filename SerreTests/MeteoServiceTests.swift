import Foundation
import Testing
@testable import Serre

/// La conversion est isolee de la couche reseau exprès : elle se teste a partir
/// d'un extrait de reponse, sans jamais ouvrir de connexion.
struct MeteoServiceTests {

    private func charge(_ json: String) throws -> ChargeOpenMeteo {
        try JSONDecoder().decode(ChargeOpenMeteo.self, from: Data(json.utf8))
    }

    private let complet = """
    {
      "latitude": 45.5, "longitude": -73.57, "timezone": "America/Montreal",
      "hourly": {
        "time": [1747800000, 1747803600, 1747807200],
        "temperature_2m": [8.1, 5.4, 3.2],
        "dew_point_2m": [1.0, 0.5, 0.2],
        "cloud_cover": [80, 20, 0],
        "wind_speed_10m": [14, 6, 2],
        "wind_gusts_10m": [31, 15, 6],
        "precipitation": [0.2, 0.0, 0.0]
      }
    }
    """

    @Test("Une reponse complete devient une serie horaire")
    func conversionComplete() throws {
        let previsions = try OpenMeteoService.convertir(charge(complet))
        #expect(previsions.heures.count == 3)
        #expect(previsions.identifiantFuseau == "America/Montreal")
        #expect(previsions.heures[0].temperature == 8.1)
        #expect(previsions.heures[2].nebulosite == 0)
        #expect(previsions.heures[0].rafale == 31)
    }

    @Test("La serie est triee par date croissante")
    func serieTriee() throws {
        let previsions = try OpenMeteoService.convertir(charge(complet))
        let dates = previsions.heures.map(\.date)
        #expect(dates == dates.sorted())
    }

    @Test("Une heure incomplete est ecartee, pas comblee")
    func heureIncomplete() throws {
        // Une valeur inventee au creux de la nuit produirait exactement la
        // fausse alerte qu'on cherche a eviter.
        let troue = """
        {
          "latitude": 45.5, "longitude": -73.57, "timezone": "America/Montreal",
          "hourly": {
            "time": [1747800000, 1747803600],
            "temperature_2m": [8.1, null],
            "dew_point_2m": [1.0, 0.5],
            "cloud_cover": [80, 20],
            "wind_speed_10m": [14, 6],
            "wind_gusts_10m": [31, 15],
            "precipitation": [0.2, 0.0]
          }
        }
        """
        let previsions = try OpenMeteoService.convertir(charge(troue))
        #expect(previsions.heures.count == 1)
    }

    @Test("Une precipitation absente vaut zero, pas un rejet")
    func precipitationAbsente() throws {
        let sansPluie = """
        {
          "latitude": 45.5, "longitude": -73.57, "timezone": "America/Montreal",
          "hourly": {
            "time": [1747800000],
            "temperature_2m": [8.1], "dew_point_2m": [1.0], "cloud_cover": [80],
            "wind_speed_10m": [14], "wind_gusts_10m": [31], "precipitation": [null]
          }
        }
        """
        let previsions = try OpenMeteoService.convertir(charge(sansPluie))
        #expect(previsions.heures.count == 1)
        #expect(previsions.heures[0].precipitation == 0)
    }

    @Test("Des series de longueurs differentes sont refusees")
    func seriesIncoherentes() throws {
        let bancal = """
        {
          "latitude": 45.5, "longitude": -73.57, "timezone": "America/Montreal",
          "hourly": {
            "time": [1747800000, 1747803600],
            "temperature_2m": [8.1], "dew_point_2m": [1.0, 0.5], "cloud_cover": [80, 20],
            "wind_speed_10m": [14, 6], "wind_gusts_10m": [31, 15], "precipitation": [0.2, 0.0]
          }
        }
        """
        let donnees = try charge(bancal)
        #expect(throws: MeteoErreur.self) {
            _ = try OpenMeteoService.convertir(donnees)
        }
    }

    @Test("Les previsions retrouvent une heure par sa date")
    func rechercheParDate() throws {
        let previsions = try OpenMeteoService.convertir(charge(complet))
        let cible = Date(timeIntervalSince1970: 1_747_803_000)
        #expect(previsions.condition(a: cible)?.temperature == 5.4)
    }

    @Test("Une fenetre ne rend que les heures qu'elle contient")
    func fenetre() throws {
        let previsions = try OpenMeteoService.convertir(charge(complet))
        let heures = previsions.heures(de: Date(timeIntervalSince1970: 1_747_803_600),
                                       a: Date(timeIntervalSince1970: 1_747_807_200))
        #expect(heures.count == 2)
    }
}

struct LieuTests {

    @Test("Les coordonnees partent arrondies au kilometre")
    func arrondi() {
        // Assez precis pour la prevision, trop grossier pour designer une
        // adresse.
        let lieu = Lieu(latitude: 45.50193, longitude: -73.56742, nom: nil,
                        identifiantFuseau: "America/Montreal")
        #expect(lieu.arrondi.latitude == 45.5)
        #expect(lieu.arrondi.longitude == -73.57)
    }

    @Test("Un fuseau inconnu retombe sur celui de l'appareil")
    func fuseauInconnu() {
        let lieu = Lieu(latitude: 45.5, longitude: -73.57, nom: nil,
                        identifiantFuseau: "Pas/UnFuseau")
        #expect(lieu.fuseau == TimeZone.current)
    }
}

struct StoreTests {

    private func storeIsole() -> Store {
        let suite = "SerreTests." + UUID().uuidString
        return Store(defaults: UserDefaults(suiteName: suite)!)
    }

    @Test("Une plante survit a l'aller-retour vers le disque")
    func allerRetourPlante() {
        let store = storeIsole()
        let plante = Aide.plante(nom: "Citronnier", confort: 7, critique: 2,
                                 emplacement: .exterieur, assise: .potSureleve)
        store.enregistrer([plante], pour: .plantes)
        let relues = store.charger([Plante].self, pour: .plantes)
        #expect(relues?.count == 1)
        #expect(relues?.first?.nom == "Citronnier")
        #expect(relues?.first?.assise == .potSureleve)
        #expect(relues?.first?.id == plante.id)
    }

    @Test("Les reglages survivent aussi")
    func allerRetourReglages() {
        let store = storeIsole()
        var reglages = Reglages.defaut
        reglages.margeSecurite = 2.5
        reglages.zone = .z4b
        store.enregistrer(reglages, pour: .reglages)
        #expect(store.charger(Reglages.self, pour: .reglages)?.margeSecurite == 2.5)
        #expect(store.charger(Reglages.self, pour: .reglages)?.zone == .z4b)
    }

    @Test("Une cle absente rend nil plutot que de planter")
    func cleAbsente() {
        #expect(storeIsole().charger([Plante].self, pour: .plantes) == nil)
    }

    @Test("Le journal des demenagements traverse l'encodage")
    func journalConserve() {
        let store = storeIsole()
        let plante = Aide.plante(demenagements: [
            Demenagement(date: Aide.date(2026, 5, 19), sens: .rentree, motif: .gel, temperature: -1.5),
        ])
        store.enregistrer([plante], pour: .plantes)
        let relue = store.charger([Plante].self, pour: .plantes)?.first
        #expect(relue?.demenagements.first?.motif == .gel)
        #expect(relue?.demenagements.first?.temperature == -1.5)
    }

    @Test("Un retrait efface bien la cle")
    func retrait() {
        let store = storeIsole()
        store.enregistrer(Reglages.defaut, pour: .reglages)
        store.retirer(.reglages)
        #expect(store.charger(Reglages.self, pour: .reglages) == nil)
    }
}
