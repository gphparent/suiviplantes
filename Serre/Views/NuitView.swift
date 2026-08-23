import SwiftUI

/// L'ecran principal : ce qui se passe cette nuit, et quoi faire.
struct NuitView: View {

    @Environment(AppModel.self) private var modele
    @State private var montrerExplication = false

    var body: some View {
        NavigationStack {
            List {
                if modele.plantes.isEmpty {
                    Section {
                        RienAFaire(titre: "Aucune plante suivie",
                                   detail: "Ajoutez vos plantes pour que l'application sache lesquelles surveiller.")
                    }
                } else {
                    entete
                    if let plan = modele.plan {
                        aRentrer(plan)
                        vent(plan)
                        aRessortir(plan)
                        acclimatation(plan)
                        aSurveiller(plan)
                        if plan.estCalme { sectionCalme }
                    } else {
                        Section {
                            Text("Previsions indisponibles.")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                if let erreur = modele.derniereErreur {
                    Section {
                        Explication(texte: erreur, symbole: "exclamationmark.triangle")
                    }
                }
            }
            .navigationTitle("Cette nuit")
            .refreshable { await modele.rafraichir() }
            .sheet(isPresented: $montrerExplication) { ExplicationRadiativeView() }
        }
    }

    // MARK: - Entete

    @ViewBuilder
    private var entete: some View {
        Section {
            if let minimum = modele.plan?.minimumReference {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Au sol")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Degres(valeur: minimum.temperatureCorrigee, style: .largeTitle.bold())
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Annonce")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Degres(valeur: minimum.temperatureAnnoncee, style: .title3)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if minimum.ecart >= 0.5 {
                        Button {
                            montrerExplication = true
                        } label: {
                            let ecart = String(format: "%.1f", minimum.ecart)
                            Explication(texte: "\(ecart) degres de moins qu'annonce, "
                                        + (minimum.nuitDeRayonnement
                                           ? "parce que le ciel est degage et le vent faible."
                                           : "au niveau du sol."),
                                        symbole: "thermometer.snowflake")
                        }
                        .buttonStyle(.plain)
                    }

                    if minimum.freineParHumidite {
                        Explication(texte: "L'humidite de l'air freine la chute : la rosee puis le givre liberent de la chaleur.",
                                    symbole: "humidity")
                    }
                }
                .padding(.vertical, 4)
            }

            if modele.previsions?.horsLigne == true {
                Explication(texte: "Previsions du cache : le reseau n'a pas repondu.",
                            symbole: "wifi.slash")
            }
        } header: {
            Text(intituleDeLaNuit)
        }
    }

    private var intituleDeLaNuit: String {
        guard let nuit = modele.plan?.nuit else { return "La nuit qui vient" }
        let format = Date.FormatStyle().weekday(.wide).day().month(.wide)
        return "Nuit du \(nuit.start.formatted(format))"
    }

    // MARK: - Sections

    @ViewBuilder
    private func aRentrer(_ plan: PlanDeLaNuit) -> some View {
        if !plan.aRentrer.isEmpty {
            Section {
                ForEach(plan.aRentrer, id: \.planteID) { evaluation in
                    LigneEvaluation(evaluation: evaluation)
                        .swipeActions {
                            Button("Rentree") {
                                if let plante = modele.plante(id: evaluation.planteID) {
                                    modele.rentrer(plante, motif: .gel)
                                }
                            }
                            .tint(.green)
                        }
                }
                Button {
                    modele.rentrerTout()
                } label: {
                    Label("Tout marquer comme rentre", systemImage: "checkmark.circle")
                }
            } header: {
                Label("A rentrer ce soir", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
            } footer: {
                Text("Le geste se pose maintenant, pendant qu'il fait clair.")
            }
        }
    }

    @ViewBuilder
    private func vent(_ plan: PlanDeLaNuit) -> some View {
        if !plan.vent.isEmpty {
            Section("Vent") {
                ForEach(plan.vent, id: \.planteID) { evaluation in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(evaluation.nom).font(.body.weight(.medium))
                            Spacer()
                            Pastille(niveau: evaluation.niveau)
                        }
                        let surPlace = String(format: "%.0f", evaluation.rafaleSurPlace)
                        let annoncee = String(format: "%.0f", evaluation.rafaleAnnoncee)
                        Text("Rafales estimees a \(surPlace) km/h sur place, \(annoncee) km/h annonces.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(evaluation.geste)
                            .font(.caption)
                            .foregroundStyle(evaluation.niveau.couleur)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func aRessortir(_ plan: PlanDeLaNuit) -> some View {
        if !plan.aRessortir.isEmpty {
            Section {
                ForEach(plan.aRessortir, id: \.planteID) { candidat in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(candidat.nom).font(.body.weight(.medium))
                        Text("Rentree le \(candidat.rentreeLe.formatted(date: .abbreviated, time: .omitted)) pour \(candidat.motif.nom.lowercased()).")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Button {
                    modele.ressortirTout()
                } label: {
                    Label("Tout ressortir", systemImage: "sun.max")
                }
            } header: {
                Label("Peuvent ressortir", systemImage: "arrow.up.forward")
                    .foregroundStyle(.green)
            } footer: {
                Text("Rentrees a cause de la meteo, et la nuit qui vient ne leur pose plus de probleme.")
            }
        }
    }

    @ViewBuilder
    private func acclimatation(_ plan: PlanDeLaNuit) -> some View {
        if !plan.acclimatations.isEmpty {
            Section("Acclimatation") {
                ForEach(plan.acclimatations, id: \.planteID) { etape in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(etape.nom).font(.body.weight(.medium))
                            Spacer()
                            Text("Jour \(etape.jour) sur \(Acclimatation.duree)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if let raison = etape.raisonDuReport {
                            Label(raison, systemImage: "pause.circle")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        } else if let detail = etape.etape {
                            Text(detail.consigne)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Button("Marquer l'etape faite") {
                                if let plante = modele.plante(id: etape.planteID) {
                                    modele.validerEtape(plante)
                                }
                            }
                            .font(.caption)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func aSurveiller(_ plan: PlanDeLaNuit) -> some View {
        if !plan.aSurveiller.isEmpty {
            Section("A surveiller") {
                ForEach(plan.aSurveiller, id: \.planteID) { evaluation in
                    LigneEvaluation(evaluation: evaluation)
                }
            }
        }
    }

    private var sectionCalme: some View {
        Section {
            RienAFaire(titre: "Nuit tranquille",
                       detail: "Rien a rentrer, rien a ressortir, pas de vent inquietant.",
                       symbole: "moon.zzz")
        }
    }
}

/// Une ligne d'evaluation de gel.
struct LigneEvaluation: View {
    let evaluation: EvaluationGel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(evaluation.nom).font(.body.weight(.medium))
                Spacer()
                Pastille(niveau: evaluation.niveau)
            }
            HStack(spacing: 4) {
                Degres(valeur: evaluation.minimum.temperatureCorrigee, style: .caption)
                Text("attendus, seuil critique a")
                    .font(.caption)
                Degres(valeur: evaluation.seuilCritique, style: .caption)
            }
            .foregroundStyle(.secondary)
        }
    }
}

/// Page qui explique le calcul. Un chiffre qui contredit l'application meteo du
/// telephone doit se justifier, sinon il n'est pas cru.
struct ExplicationRadiativeView: View {

    @Environment(\.dismiss) private var fermer

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Les previsions donnent la temperature de l'air sous abri, a deux metres du sol, dans un boitier ventile. Ce n'est pas ce que subit une plante posee sur une terrasse.")
                }
                Section("Pourquoi il fait plus froid au sol") {
                    Explication(texte: "Par nuit degagee, le sol rayonne vers le ciel bien plus qu'il ne recoit. Une couche d'air froid s'installe au ras du sol.",
                                symbole: "moon.stars")
                    Explication(texte: "Les nuages renvoient ce rayonnement. Sous un ciel couvert, l'ecart s'efface presque.",
                                symbole: "cloud")
                    Explication(texte: "Le vent brasse et detruit la couche froide. Des vingt kilometres a l'heure, il ne reste plus grand-chose.",
                                symbole: "wind")
                    Explication(texte: "Un pot n'a pas l'inertie du sol : la motte descend plus bas que la terre du jardin, et gele plus tot.",
                                symbole: "square.stack.3d.up")
                }
                Section("Ce qui freine la chute") {
                    Explication(texte: "Quand la temperature rejoint le point de rosee, la vapeur se condense puis se depose en givre. La chaleur ainsi liberee ralentit fortement le refroidissement.",
                                symbole: "humidity")
                    Text("C'est pour cela qu'une nuit humide gele rarement aussi fort que le calcul brut le laisse croire. L'ignorer produit de fausses alertes, et de fausses alertes font desinstaller une application.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Section {
                    Text("Le modele est un ordre de grandeur, pas une mesure. Un thermometre a minima pose a cote de vos pots reste le seul juge. La correction est desactivable dans les reglages.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("La gelee au sol")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fermer") { fermer() }
                }
            }
        }
    }
}
