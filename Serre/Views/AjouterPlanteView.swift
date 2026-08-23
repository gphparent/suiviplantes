import SwiftUI

struct AjouterPlanteView: View {

    @Environment(AppModel.self) private var modele
    @Environment(\.dismiss) private var fermer

    @State private var recherche = ""
    @State private var categorie: Categorie?

    private var resultats: [Espece] {
        let base = Catalogue.rechercher(recherche)
        guard let categorie else { return base }
        return base.filter { $0.categorie == categorie }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Categorie", selection: $categorie) {
                        Text("Toutes").tag(Categorie?.none)
                        ForEach(Categorie.allCases) { Text($0.nom).tag(Categorie?.some($0)) }
                    }
                    .pickerStyle(.menu)
                }

                ForEach(resultats) { espece in
                    Button {
                        modele.ajouter(Plante(espece: espece))
                        fermer()
                    } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(espece.nom).font(.body.weight(.medium))
                            Text(espece.nomLatin).font(.caption).italic()
                                .foregroundStyle(.secondary)
                            HStack(spacing: 4) {
                                Text("Confort")
                                Degres(valeur: espece.seuilConfort, style: .caption2)
                                Text("· critique")
                                Degres(valeur: espece.seuilCritique, style: .caption2)
                            }
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            if let note = espece.note {
                                Text(note).font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }

                Section {
                    Button {
                        modele.ajouter(Plante(nom: recherche.isEmpty ? "Nouvelle plante" : recherche,
                                              seuilConfort: 10, seuilCritique: 2))
                        fermer()
                    } label: {
                        Label("Ajouter a la main", systemImage: "square.and.pencil")
                    }
                } footer: {
                    Text("Les seuils du catalogue sont des reperes horticoles courants, pas des constantes : ils varient selon le cultivar, l'age du sujet et son endurcissement. Ils restent modifiables plante par plante.")
                }
            }
            .searchable(text: $recherche, prompt: "Chercher une espece")
            .navigationTitle("Ajouter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { fermer() }
                }
            }
        }
    }
}
