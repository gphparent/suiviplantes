# Appli YouTube

Application iOS personnelle : **YouTube, mais seulement ce qu'un juge a
approuvé.**

Bloquer YouTube complètement ne tient pas : on finit par contourner, et on
replonge. Cette appli remplace le tout-ou-rien par une porte gardée. On colle le
lien d'une vidéo ou d'une chaîne, on explique pourquoi on veut la regarder, et
Claude tranche selon des critères stricts. Seul ce qu'il approuve devient
visible.

---

## Ce qu'elle fait

**Fil.** Les nouvelles vidéos des chaînes approuvées, tirées de leur flux RSS.
Pas de recherche, pas de suggestions, pas d'accueil personnalisé : c'est par là
que la spirale commence.

**Demander.** Une conversation avec le juge. L'appli lit elle-même la page de la
vidéo ou de la chaîne (titre, description, durée, dernières vidéos) et la lui
transmet ; il ne tranche jamais sur la seule parole de l'utilisateur. On peut
plaider avec des faits, pas avec de l'insistance.

**Approuvé.** Tout ce qui a été ouvert. On peut retirer une chaîne ou une vidéo ;
rien ne s'y ajoute autrement que par un verdict du juge.

**Lecteur.** Le lecteur intégré officiel de YouTube, dans une vue qui ne mène
nulle part ailleurs : pas de lien vers YouTube, pas de nouvel onglet.

## Les critères

Écrits dans [`Juge.swift`](AppliYouTube/Services/Juge.swift), pas dans un
réglage. Les changer exige un commit et une nouvelle version TestFlight — c'est
voulu : un réglage se contourne en dix secondes, un commit non.

- Contenu parlé **en français** seulement.
- Apprentissage, foi et théologie, professionnel (photo, affaires,
  développement), musique sacrée ou classique.
- Refusé : divertissement, humour, vlogs, réactions, actualité, polémiques,
  jeux vidéo, sport, Shorts, titres racoleurs.

## Mise en route

1. **App Store Connect** : créer la fiche de l'app avec le Bundle ID
   `ca.appliyoutube` (Apps → « + » → Nouvelle app). L'API d'Apple ne permet pas
   de la créer à notre place.
2. **GitHub Actions** : onglet Actions → « Envoi vers TestFlight » → *Run
   workflow*. Les secrets App Store Connect du dépôt servent tels quels.
3. **TestFlight** : s'ajouter comme testeur interne. Aucune revue d'Apple n'est
   nécessaire pour les testeurs internes, et l'appli n'est jamais publiée.
4. **Dans l'appli**, onglet Réglages : coller une clé d'API Anthropic, créée sur
   [console.anthropic.com](https://console.anthropic.com). Elle reste dans le
   trousseau de l'appareil.

## Développement

Le projet Xcode utilise des groupes synchronisés : tout fichier ajouté dans
`AppliYouTube/` ou `AppliYouTubeTests/` est compilé sans toucher au projet.

- `Tools/fabriquer-icone.py` régénère l'icône.
- `Tools/tester-cle-asc.py` éprouve la clé App Store Connect avant l'envoi.
