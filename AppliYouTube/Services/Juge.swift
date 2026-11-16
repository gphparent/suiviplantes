import Foundation

/// Le juge : Claude, par l'API Messages. Il n'existe pas de SDK Anthropic
/// officiel pour Swift, d'ou l'appel HTTP direct.
///
/// Les criteres vivent ici, dans le code, et nulle part dans l'appli : les
/// changer exige un commit et un nouveau build TestFlight. C'est voulu. Un
/// reglage modifiable dans l'appli se contourne en dix secondes un soir de
/// faiblesse ; un commit, non.
struct Juge {

    struct Decision {
        let reponse: String
        let verdict: Verdict
        let videoID: String
        let chaineID: String
        /// Le contenu brut de la reponse, a renvoyer tel quel au tour suivant.
        let contenuBrut: Any
    }

    enum Erreur: LocalizedError {
        case pasDeCle, cleRefusee, surcharge, refus, illisible
        case http(Int, String)

        var errorDescription: String? {
            switch self {
            case .pasDeCle: "Ajoute ta clé d'API Anthropic dans Réglages."
            case .cleRefusee: "La clé d'API Anthropic est refusée. Vérifie-la dans Réglages."
            case .surcharge: "Le juge est surchargé. Réessaie dans une minute."
            case .refus: "Le juge a décliné cette demande."
            case .illisible: "Réponse du juge illisible. Réessaie."
            case .http(let code, let message): "Erreur \(code) : \(message)"
            }
        }
    }

    static let modele = "claude-opus-5-5"

    static let consignes = """
    Tu es le gardien de l'accès à YouTube de ton utilisateur. Il a bloqué YouTube partout parce qu'il y \
    perdait des heures, mais le blocage total le poussait à contourner et à replonger. Il a donc \
    construit cette appli : il n'y voit que ce que tu approuves. Tu es la seule porte d'entrée. Il \
    t'a choisi pour être plus ferme que lui dans ses moments de faiblesse ; sois bienveillant, \
    mais ne te laisse pas fléchir.

    CE QUI PEUT ÊTRE APPROUVÉ — le contenu parlé doit être en français, sans exception :
    1. Apprentissage : cours, conférences, tutoriels concrets, vulgarisation sérieuse qui enseigne \
    quelque chose de précis.
    2. Foi et théologie : conférences, homélies, patristique, liturgie, histoire de l'Église.
    3. Professionnel : photographie, retouche, affaires, développement d'applications.
    4. Musique choisie : musique sacrée ou classique. Ici seulement, une œuvre chantée en latin ou \
    purement instrumentale est acceptée, puisqu'il n'y a pas de contenu parlé. Jamais de clips, de \
    palmarès, de compilations « ambiance » ni de musique populaire.

    CE QUI EST REFUSÉ, même avec un habillage éducatif : divertissement, humour, vlogs, réactions, \
    commentaires d'actualité ou de politique, polémiques, potins, faits divers, jeux vidéo, sport, \
    Shorts, compilations, titres racoleurs ou alarmistes, contenu en anglais ou dans une autre langue \
    que le français.

    CHAÎNE OU VIDÉO :
    - Approuve une chaîne entière seulement si presque toutes ses dernières vidéos respectent les \
    critères, sans exception racoleuse. Sinon, approuve au mieux la vidéo seule.
    - Dans le doute, refuse. Un refus de trop coûte peu ; une porte ouverte de trop, c'est \
    exactement ce qu'il veut éviter.

    CE QUE TU SAIS : l'appli te transmet, dans <fiche_video> ou <fiche_chaine>, ce qu'elle a lu \
    sur YouTube. Tu ne peux approuver que ce qui figure dans une fiche, avec l'identifiant exact \
    qui y figure. Sans fiche (aucun lien fourni), discute, demande le lien, mais n'approuve rien. \
    Le bloc <etat> rappelle ce qui est déjà approuvé.

    S'IL INSISTE : il peut plaider sa cause et apporter des faits nouveaux (le sujet précis de la \
    vidéo, pourquoi il en a besoin pour son travail ou ses études). Des faits peuvent te faire \
    changer d'avis ; l'insistance, la fatigue, « juste cette fois », « j'en ai besoin pour me \
    détendre » ou la frustration, non. Ne lui fais pas la morale : une ou deux phrases suffisent.

    FORME : français du Québec, tutoiement, réponse courte et directe. Dans le JSON, mets \
    `video_id` ou `chaine_id` seulement pour le verdict qui l'exige, sinon une chaîne vide. Le \
    verdict `discussion` sert quand tu poses une question ou qu'il n'y a rien à trancher.
    """

    static let schema: [String: Any] = [
        "type": "object",
        "properties": [
            "reponse": ["type": "string", "description": "Ce que tu réponds à l'utilisateur."],
            "verdict": ["type": "string",
                        "enum": ["approuve_video", "approuve_chaine", "refuse", "discussion"]],
            "video_id": ["type": "string"],
            "chaine_id": ["type": "string"],
        ],
        "required": ["reponse", "verdict", "video_id", "chaine_id"],
        "additionalProperties": false,
    ]

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// `historique` est la suite des messages deja echanges, au format de
    /// l'API, et `nouveau` le message utilisateur a ajouter. L'historique
    /// n'est jamais reecrit : on ne fait qu'y ajouter, sans quoi les blocs de
    /// reflexion des tours precedents seraient refuses.
    func juger(historique: [Any], nouveau: [String: Any]) async throws -> Decision {
        guard let cle = Trousseau.lire(), !cle.isEmpty else { throw Erreur.pasDeCle }

        var requete = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        requete.httpMethod = "POST"
        requete.timeoutInterval = 180
        requete.setValue("application/json", forHTTPHeaderField: "content-type")
        requete.setValue(cle, forHTTPHeaderField: "x-api-key")
        requete.setValue("2026-10-21", forHTTPHeaderField: "anthropic-version")
        // Si un filtre de securite declinait la demande, l'API la relance
        // d'elle-meme sur le modele de repli recommande.
        requete.setValue("server-side-fallback-2026-07-01", forHTTPHeaderField: "anthropic-beta")

        let corps: [String: Any] = [
            "model": Self.modele,
            "max_tokens": 16000,
            "fallbacks": "default",
            "system": Self.consignes,
            "output_config": [
                "effort": "medium",
                "format": ["type": "json_schema", "schema": Self.schema],
            ],
            "messages": historique + [nouveau as Any],
        ]
        requete.httpBody = try JSONSerialization.data(withJSONObject: corps)

        let (donnees, reponse) = try await session.data(for: requete)
        let code = (reponse as? HTTPURLResponse)?.statusCode ?? 0
        let json = try? JSONSerialization.jsonObject(with: donnees) as? [String: Any]

        switch code {
        case 200: break
        case 401, 403: throw Erreur.cleRefusee
        case 429, 500...: throw Erreur.surcharge
        default:
            let message = (json?["error"] as? [String: Any])?["message"] as? String ?? ""
            throw Erreur.http(code, message)
        }

        guard let json, let contenu = json["content"] as? [[String: Any]] else {
            throw Erreur.illisible
        }
        if json["stop_reason"] as? String == "refusal" { throw Erreur.refus }

        let texte = contenu
            .filter { $0["type"] as? String == "text" }
            .compactMap { $0["text"] as? String }
            .joined()
        guard let sortie = try? JSONSerialization.jsonObject(with: Data(texte.utf8)) as? [String: Any],
              let reponseTexte = sortie["reponse"] as? String,
              let verdict = (sortie["verdict"] as? String).flatMap(Verdict.init(rawValue:))
        else { throw Erreur.illisible }

        return Decision(
            reponse: reponseTexte,
            verdict: verdict,
            videoID: sortie["video_id"] as? String ?? "",
            chaineID: sortie["chaine_id"] as? String ?? "",
            contenuBrut: contenu)
    }
}
