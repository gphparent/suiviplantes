import SwiftUI

struct PlantesView: View {

    @Environment(AppModel.self) private var modele
    @State private var ajout = false

    var body: some View {
        NavigationStack {
            List {
                if modele.plantes.isEmpty {
                    RienAFaire(titre: "Aucune plante",
                               detail: "Commencez par celles qui passent l'ete dehors et l'hiver dedans.")
                }
                ForEach(Emplacement.allCases) { emplacement in
                    let groupe = modele.plantes.filter { $0.emplacement == emplacement }
                    if !groupe.isEmpty {
                        Section {
                            ForEach(groupe) { plante in
                                NavigationLink(value: plante.id) {
                                    LignePlante(plante: plante)
                                }
                            }
                            .onDelete { indices in
                                for index in indices { modele.supprimer(groupe[index]) }
                            }
                        } header: {
                            Label(emplacement.nom, systemImage: emplacement.symbole)
                        }
                    }
                }
            }
            .navigationTitle("Mes plantes")
            .navigationDestination(for: UUID.self) { id in
                if let plante = modele.plante(id: id) {
                    PlanteDetailView(plante: plante)
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { ajout = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $ajout) { AjouterPlanteView() }
        }
    }
}

struct LignePlante: View {
    let plante: Plante

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(plante.nom).font(.body.weight(.medium))
            HStack(spacing: 4) {
                Text("Critique a")
                Degres(valeur: plante.seuilCritiqueEffectif, style: .caption)
                if plante.assise.racinesExposees && plante.seuilCritique < 0 {
                    Image(systemName: "arrow.up.circle")
                        .help("Releve parce que la motte est exposee")
                }
                Text("· \(plante.assise.nom)")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if let acclimatation = plante.acclimatation {
                ProgressView(value: acclimatation.progression) {
                    Text("Acclimatation, jour \(acclimatation.jourCourant) sur \(Acclimatation.duree)")
                        .font(.caption2)
                }
                .tint(.orange)
            }
        }
    }
}
