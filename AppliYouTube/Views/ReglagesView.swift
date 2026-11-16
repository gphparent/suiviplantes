import SwiftUI

/// Seulement la cle d'API. Les criteres du juge ne se reglent pas ici : ils
/// sont dans le code (voir `Juge.consignes`).
struct ReglagesView: View {

    @State private var cle = ""
    @State private var cleEnregistree = Trousseau.lire() != nil

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if cleEnregistree {
                        Label("Clé enregistrée sur cet appareil", systemImage: "key.fill")
                        Button("Effacer la clé", role: .destructive) {
                            Trousseau.effacer()
                            cleEnregistree = false
                        }
                    } else {
                        SecureField("sk-ant-…", text: $cle)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        Button("Enregistrer") {
                            Trousseau.ecrire(cle.trimmingCharacters(in: .whitespacesAndNewlines))
                            cle = ""
                            cleEnregistree = true
                        }
                        .disabled(cle.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                } header: {
                    Text("Clé d'API Anthropic")
                } footer: {
                    Text("Crée-la sur console.anthropic.com. Elle reste dans le trousseau de l'appareil et ne sert qu'à interroger le juge (\(Juge.modele)).")
                }

                Section {
                    Text("Les critères du juge sont écrits dans le code de l'appli. Pour les changer, il faut un commit et une nouvelle version TestFlight — c'est voulu.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Critères")
                }
            }
            .navigationTitle("Réglages")
        }
    }
}
