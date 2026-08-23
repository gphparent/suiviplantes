import SwiftUI

extension NiveauRisque {
    var couleur: Color {
        switch self {
        case .aucun: return .green
        case .surveiller: return .mint
        case .inconfort: return .yellow
        case .danger: return .orange
        case .critique: return .red
        }
    }
}

/// Une temperature, arrondie au degre, avec son symbole.
struct Degres: View {
    let valeur: Double
    var style: Font = .body

    var body: some View {
        Text(texte)
            .font(style)
            .monospacedDigit()
    }

    /// Le zero negatif que produit l'arrondi d'un demi-degre sous zero est
    /// ramene a zero : « -0 °C » se lit comme une coquille.
    private var texte: String {
        let arrondi = valeur.rounded()
        let propre = arrondi == 0 ? 0 : arrondi
        return String(format: "%.0f °C", propre)
    }
}

/// Pastille de niveau de risque.
struct Pastille: View {
    let niveau: NiveauRisque

    var body: some View {
        Label(niveau.nom, systemImage: niveau.symbole)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(niveau.couleur.opacity(0.18), in: Capsule())
            .foregroundStyle(niveau.couleur)
    }
}

/// Encadre explicatif, utilise pour dire pourquoi un chiffre differe de celui
/// de l'application meteo du telephone.
struct Explication: View {
    let texte: String
    var symbole: String = "info.circle"

    var body: some View {
        Label {
            Text(texte)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: symbole)
                .foregroundStyle(.secondary)
        }
    }
}

/// Etat vide, avec un geste a poser.
struct RienAFaire: View {
    let titre: String
    let detail: String
    var symbole: String = "leaf"

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: symbole)
                .font(.largeTitle)
                .foregroundStyle(.tint)
            Text(titre).font(.headline)
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

extension Emplacement {
    var couleur: Color {
        switch self {
        case .interieur: return .brown
        case .acclimatation: return .orange
        case .exterieur: return .green
        }
    }
}
