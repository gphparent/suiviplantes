import SwiftUI

struct ReglagesView: View {

    @Environment(AppModel.self) private var modele
    @State private var latitudeSaisie = ""
    @State private var longitudeSaisie = ""

    var body: some View {
        @Bindable var modele = modele

        NavigationStack {
            Form {
                Section {
                    DatePicker("Alerte d'action",
                               selection: liaisonHeure(heure: $modele.reglages.heureAlerteSoir,
                                                       minute: $modele.reglages.minuteAlerteSoir),
                               displayedComponents: .hourAndMinute)
                    DatePicker("Bilan du matin",
                               selection: liaisonHeure(heure: $modele.reglages.heureBilanMatin,
                                                       minute: $modele.reglages.minuteBilanMatin),
                               displayedComponents: .hourAndMinute)
                } header: {
                    Text("Alertes")
                } footer: {
                    Text("L'alerte d'action tombe au milieu de l'apres-midi et non le soir : une notification a vingt et une heures qui annonce du gel a trois heures du matin arrive alors qu'il fait noir et froid, et que le mal est a moitie fait.")
                }

                Section {
                    Toggle("Alerter aussi au seuil de confort",
                           isOn: $modele.reglages.alerterAuConfort)
                    Toggle("Alerter des coups de vent",
                           isOn: $modele.reglages.alerterAuVent)
                    Stepper(value: $modele.reglages.margeSecurite, in: 0...5, step: 0.5) {
                        HStack {
                            Text("Marge de securite")
                            Spacer()
                            Degres(valeur: modele.reglages.margeSecurite)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Sensibilite")
                } footer: {
                    Text("La marge s'ajoute aux deux seuils de chaque plante. Une prevision n'est jamais exacte au degre pres.")
                }

                Section {
                    Toggle("Corriger le refroidissement au sol",
                           isOn: $modele.reglages.correctionRadiative)
                } header: {
                    Text("Calcul")
                } footer: {
                    Text("Desactivez pour comparer avec la temperature brute annoncee par les previsions. C'est la difference entre les deux qui explique pourquoi une plante gele une nuit ou la station annoncait trois degres.")
                }

                Section {
                    Picker("Zone de rusticite", selection: $modele.reglages.zone) {
                        ForEach(ZoneRusticite.allCases) { zone in
                            Text("\(zone.nom) — \(zone.exemples)").tag(zone)
                        }
                    }
                } header: {
                    Text("Zone")
                } footer: {
                    Text("Zones de Ressources naturelles Canada. Elles servent de repere pour les dates normales de gel quand les previsions ne portent pas assez loin.")
                }

                sectionLieu

                Section("Notifications") {
                    LabeledContent("Autorisation", value: autorisationLisible)
                    if modele.notifications.autorisation != .authorized {
                        Button("Demander l'autorisation") {
                            Task { await modele.notifications.demanderAutorisation() }
                        }
                    }
                }

                Section {
                    Text("Serre garde tout sur l'appareil. Seules des coordonnees arrondies au kilometre partent vers Open-Meteo pour aller chercher les previsions. Aucun compte, aucun serveur, aucune synchronisation.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Reglages")
        }
    }

    @ViewBuilder
    private var sectionLieu: some View {
        Section {
            if let lieu = modele.lieu {
                LabeledContent("Latitude", value: String(format: "%.2f", lieu.arrondi.latitude))
                LabeledContent("Longitude", value: String(format: "%.2f", lieu.arrondi.longitude))
            } else {
                Text("Lieu inconnu").foregroundStyle(.secondary)
            }

            HStack {
                TextField("Latitude", text: $latitudeSaisie)
                    .keyboardType(.numbersAndPunctuation)
                TextField("Longitude", text: $longitudeSaisie)
                    .keyboardType(.numbersAndPunctuation)
            }
            Button("Fixer ce lieu") {
                guard let latitude = Double(latitudeSaisie.replacingOccurrences(of: ",", with: ".")),
                      let longitude = Double(longitudeSaisie.replacingOccurrences(of: ",", with: "."))
                else { return }
                modele.fixerLieu(Lieu(latitude: latitude, longitude: longitude,
                                      nom: nil, identifiantFuseau: TimeZone.current.identifier))
            }
            .disabled(latitudeSaisie.isEmpty || longitudeSaisie.isEmpty)

            if modele.lieuManuel != nil {
                Button("Revenir a la position du telephone", role: .destructive) {
                    modele.fixerLieu(nil)
                }
            }
        } header: {
            Text("Lieu")
        } footer: {
            Text("Un lieu fixe a la main court-circuite la geolocalisation, ce qui permet de s'en passer completement, ou de preparer un depart.")
        }
    }

    private var autorisationLisible: String {
        switch modele.notifications.autorisation {
        case .authorized, .provisional, .ephemeral: return "Accordee"
        case .denied: return "Refusee"
        case .notDetermined: return "Pas encore demandee"
        @unknown default: return "Inconnue"
        }
    }

    /// Relie deux entiers, heure et minute, a un `Date` que `DatePicker` sait
    /// manipuler.
    private func liaisonHeure(heure: Binding<Int>, minute: Binding<Int>) -> Binding<Date> {
        Binding {
            var composants = DateComponents()
            composants.hour = heure.wrappedValue
            composants.minute = minute.wrappedValue
            return Calendar.current.date(from: composants) ?? Date()
        } set: { nouvelle in
            let composants = Calendar.current.dateComponents([.hour, .minute], from: nouvelle)
            heure.wrappedValue = composants.hour ?? heure.wrappedValue
            minute.wrappedValue = composants.minute ?? minute.wrappedValue
        }
    }
}
