import SwiftUI

struct PlanteDetailView: View {

    @Environment(AppModel.self) private var modele
    @State private var brouillon: Plante

    init(plante: Plante) {
        _brouillon = State(initialValue: plante)
    }

    var body: some View {
        Form {
            Section("Identite") {
                TextField("Nom", text: $brouillon.nom)
                if let latin = brouillon.nomLatin {
                    LabeledContent("Espece", value: latin)
                        .foregroundStyle(.secondary)
                }
                Picker("Categorie", selection: $brouillon.categorie) {
                    ForEach(Categorie.allCases) { Text($0.nom).tag($0) }
                }
            }

            Section {
                Picker("Emplacement", selection: $brouillon.emplacement) {
                    ForEach(Emplacement.allCases) { Text($0.nom).tag($0) }
                }
                Picker("Assise", selection: $brouillon.assise) {
                    ForEach(Assise.allCases) { Text($0.nom).tag($0) }
                }
                Picker("Exposition au vent", selection: $brouillon.exposition) {
                    ForEach(ExpositionAuVent.allCases) { Text($0.nom).tag($0) }
                }
                Picker("Prise au vent", selection: $brouillon.priseAuVent) {
                    ForEach(PriseAuVent.allCases) { Text($0.nom).tag($0) }
                }
            } header: {
                Text("Ou elle est posee")
            } footer: {
                Text(brouillon.assise.explication)
            }

            Section {
                Stepper(value: $brouillon.seuilConfort, in: -40...45, step: 1) {
                    HStack {
                        Text("Confort")
                        Spacer()
                        Degres(valeur: brouillon.seuilConfort)
                            .foregroundStyle(.secondary)
                    }
                }

                Stepper(value: $brouillon.seuilCritique, in: -45...45, step: 1) {
                    HStack {
                        Text("Critique")
                        Spacer()
                        Degres(valeur: brouillon.seuilCritique)
                            .foregroundStyle(.secondary)
                    }
                }

                if brouillon.seuilCritiqueEffectif != brouillon.seuilCritique {
                    HStack {
                        Text("Retenu pour le calcul")
                        Spacer()
                        Degres(valeur: brouillon.seuilCritiqueEffectif)
                            .foregroundStyle(.orange)
                    }
                }
            } header: {
                Text("Seuils")
            } footer: {
                Text("En pot, la motte est a l'air libre de tous les cotes. La regle horticole courante retire environ deux zones de rusticite, soit cinq degres, aux plantes qui en ont a perdre.")
            }

            Section("Arrosage") {
                Stepper("Ete : tous les \(brouillon.arrosageEte) jours",
                        value: $brouillon.arrosageEte, in: 1...60)
                Stepper("Hiver a l'interieur : tous les \(brouillon.arrosageHiver) jours",
                        value: $brouillon.arrosageHiver, in: 1...90)
                if let dernier = brouillon.dernierArrosage {
                    LabeledContent("Dernier arrosage",
                                   value: dernier.formatted(date: .abbreviated, time: .omitted))
                }
                Button("Arrosee aujourd'hui") {
                    modele.arroser(brouillon)
                    brouillon.dernierArrosage = Date()
                }
            }

            sectionAcclimatation

            Section("Notes") {
                TextField("Notes", text: $brouillon.notes, axis: .vertical)
                    .lineLimit(3...8)
            }

            if !brouillon.demenagements.isEmpty {
                Section("Journal des demenagements") {
                    ForEach(brouillon.demenagements.sorted { $0.date > $1.date }) { evenement in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Label(evenement.sens.nom,
                                      systemImage: evenement.sens == .sortie
                                        ? "arrow.up.forward" : "arrow.down.backward")
                                Spacer()
                                Text(evenement.date.formatted(date: .abbreviated, time: .omitted))
                                    .foregroundStyle(.secondary)
                            }
                            .font(.subheadline)
                            HStack(spacing: 4) {
                                Text(evenement.motif.nom)
                                if let temperature = evenement.temperature {
                                    Text("·")
                                    Degres(valeur: temperature, style: .caption)
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle(brouillon.nom)
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { modele.modifier(brouillon) }
    }

    @ViewBuilder
    private var sectionAcclimatation: some View {
        Section {
            if let acclimatation = brouillon.acclimatation {
                ProgressView(value: acclimatation.progression)
                    .tint(.orange)
                if let etape = MoteurAcclimatation.etape(jour: acclimatation.jourCourant) {
                    LabeledContent("Jour", value: "\(etape.jour) sur \(Acclimatation.duree)")
                    Text(etape.consigne).font(.footnote).foregroundStyle(.secondary)
                }
                Button("Abandonner l'acclimatation", role: .destructive) {
                    modele.annulerAcclimatation(brouillon)
                    brouillon.acclimatation = nil
                    brouillon.emplacement = .interieur
                }
            } else {
                Button("Commencer l'acclimatation") {
                    modele.commencerAcclimatation(brouillon)
                    brouillon.acclimatation = Acclimatation()
                    brouillon.emplacement = .acclimatation
                }
            }
        } header: {
            Text("Acclimatation")
        } footer: {
            Text("Une plante qui a passe l'hiver dedans, sous une lumiere cent fois plus faible qu'au dehors, brule en une apres-midi si on la pose au soleil. La sortie se fait par paliers sur dix jours, et une journee mauvaise suspend le programme au lieu de le faire avancer.")
        }
    }
}
