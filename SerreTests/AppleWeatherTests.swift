import Foundation
import Testing
@testable import Serre

/// `HourWeather` n'a pas d'initialiseur public : le corps de la conversion ne
/// peut pas etre couvert. Ce qui se teste, ce sont les deux endroits ou l'on
/// peut reellement se tromper en passant d'un fournisseur a l'autre.
struct AppleWeatherTests {

    typealias Conversion = AppleWeatherService.Conversion

    @Test("La fraction de nebulosite devient un pourcentage")
    func nebulositeEnPourcentage() {
        // WeatherKit donne 0 a 1, Open-Meteo et le moteur raisonnent en
        // pourcentage. Confondre les deux diviserait le refroidissement par
        // cent, et l'application n'alerterait plus jamais.
        #expect(Conversion.nebulosite(fraction: 0) == 0)
        #expect(Conversion.nebulosite(fraction: 0.35) == 35)
        #expect(Conversion.nebulosite(fraction: 1) == 100)
    }

    @Test("Une fraction hors bornes est ramenee dans l'intervalle")
    func nebulositeBornee() {
        #expect(Conversion.nebulosite(fraction: -0.2) == 0)
        #expect(Conversion.nebulosite(fraction: 1.4) == 100)
    }

    @Test("Le pourcentage converti nourrit correctement le facteur de ciel")
    func nebulositeCoherenteAvecLeMoteur() {
        let couvert = RefroidissementNocturne.facteurCiel(
            nebulosite: Conversion.nebulosite(fraction: 1))
        let degage = RefroidissementNocturne.facteurCiel(
            nebulosite: Conversion.nebulosite(fraction: 0))
        #expect(abs(couvert - 0.2) < 1e-9)
        #expect(degage == 1.0)
    }

    @Test("Une rafale absente retombe sur le vent moyen, pas sur zero")
    func rafaleAbsente() {
        // Traiter le silence comme un calme plat ferait passer un coup de vent
        // pour une nuit tranquille.
        #expect(Conversion.rafale(rafale: nil, vent: 42) == 42)
        #expect(Conversion.rafale(rafale: 0, vent: 42) == 42)
    }

    @Test("Une rafale annoncee est retenue")
    func rafalePresente() {
        #expect(Conversion.rafale(rafale: 75, vent: 30) == 75)
    }

    @Test("Une rafale inferieure au vent moyen n'a pas de sens : le vent gagne")
    func rafaleIncoherente() {
        #expect(Conversion.rafale(rafale: 12, vent: 30) == 30)
    }

    @Test("Une rafale nulle ne fait jamais taire une alerte de vent")
    func rafaleNulleNEteintPasLAlerte() {
        // Verification de bout en bout : sans le plancher, cette plante
        // exposee passerait pour tranquille.
        let plante = Aide.plante(emplacement: .exterieur, exposition: .exposee, prise: .forte)
        let vent = Conversion.rafale(rafale: nil, vent: 70)
        let heures = Aide.nuit(du: Aide.date(2026, 7, 10), temperature: 18,
                               vent: 70, rafale: vent)
        let evaluation = MoteurVent.evaluer(plante: plante, heures: heures)
        #expect((evaluation?.niveau ?? .aucun) >= .danger)
    }
}
