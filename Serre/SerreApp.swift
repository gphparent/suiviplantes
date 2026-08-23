import SwiftUI

@main
struct SerreApp: App {

    @State private var modele = AppModel()

    var body: some Scene {
        WindowGroup {
            RacineView()
                .environment(modele)
                .task { await modele.demarrer() }
        }
    }
}
