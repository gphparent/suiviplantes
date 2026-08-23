import SwiftUI

struct ArrosageView: View {

    @Environment(AppModel.self) private var modele

    var body: some View {
        NavigationStack {
            List {
                if modele.plantes.isEmpty {
                    RienAFaire(titre: "Aucune plante",
                               detail: "Ajoutez vos plantes pour suivre leur arrosage.",
                               symbole: "drop")
                } else {
                    let etats = modele.etatsArrosage
                    let dus = etats.filter(\.aArroser)
                    let aVenir = etats.filter { !$0.aArroser }

                    if !dus.isEmpty {
                        Section {
                            ForEach(dus, id: \.planteID) { etat in
                                LigneArrosage(etat: etat)
                            }
                        } header: {
                            Label("A arroser", systemImage: "drop.fill")
                                .foregroundStyle(.blue)
                        }
                    }

                    if !aVenir.isEmpty {
                        Section("A venir") {
                            ForEach(aVenir, id: \.planteID) { etat in
                                LigneArrosage(etat: etat)
                            }
                        }
                    }

                    Section {
                        Explication(texte: saisonExpliquee, symbole: "calendar")
                    }
                }
            }
            .navigationTitle("Arrosage")
            .refreshable { await modele.rafraichir() }
        }
    }

    private var saisonExpliquee: String {
        switch modele.saison {
        case .croissance:
            return "Saison de croissance : le jour est assez long pour que les plantes poussent, et boivent."
        case .repos:
            return "Saison de repos : le jour est court, la croissance s'arrete, les plantes rentrees boivent deux a trois fois moins. C'est en continuant au rythme de l'ete qu'on pourrit les racines en novembre."
        }
    }
}

struct LigneArrosage: View {

    @Environment(AppModel.self) private var modele
    let etat: EtatArrosage

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(etat.nom).font(.body.weight(.medium))
                Spacer()
                Text(echeance)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(etat.enRetard ? .red : (etat.aujourdHui ? .blue : .secondary))
            }
            Text(etat.raison).font(.caption).foregroundStyle(.secondary)
        }
        .swipeActions {
            Button("Arrosee") {
                if let plante = modele.plante(id: etat.planteID) {
                    modele.arroser(plante)
                }
            }
            .tint(.blue)
        }
    }

    private var echeance: String {
        if etat.enRetard {
            let retard = -etat.joursRestants
            return retard == 1 ? "1 jour de retard" : "\(retard) jours de retard"
        }
        if etat.aujourdHui { return "Aujourd'hui" }
        return etat.joursRestants == 1 ? "Demain" : "Dans \(etat.joursRestants) jours"
    }
}
