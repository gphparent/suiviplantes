import SwiftUI

struct RacineView: View {

    @Environment(AppModel.self) private var modele

    var body: some View {
        TabView {
            NuitView()
                .tabItem { Label("La nuit", systemImage: "moon.stars") }
                .badge(modele.plan?.aRentrer.count ?? 0)

            PlantesView()
                .tabItem { Label("Plantes", systemImage: "leaf") }

            ArrosageView()
                .tabItem { Label("Arrosage", systemImage: "drop") }
                .badge(modele.arrosagesDus.count)

            ReglagesView()
                .tabItem { Label("Reglages", systemImage: "gearshape") }
        }
    }
}
