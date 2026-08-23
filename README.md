# Serre

Application iOS qui répond à une question précise : **quelles plantes faut-il
rentrer ce soir**, à l'endroit exact où elles sont posées — et **lesquelles
peuvent ressortir demain matin**.

Elle relie trois choses que les applications existantes traitent séparément :
l'inventaire et l'arrosage, les alertes météo géolocalisées, et le va-et-vient
saisonnier entre l'intérieur et l'extérieur.

> Le [relevé du marché](RECHERCHE-APPS-PLANTES.md) qui a précédé ce projet
> détaille ce qui existe déjà, et pourquoi les trous restants justifiaient
> d'écrire notre propre application plutôt que d'empiler deux abonnements.

---

## Ce qu'elle fait

**La nuit qui vient.** Le creux annoncé, le creux réellement subi au niveau du
sol, et l'écart entre les deux — avec la raison de cet écart. La liste des
plantes à rentrer est nommée, cochable, et arrive au milieu de l'après-midi
pendant qu'il fait encore clair.

**La gelée au sol.** Les prévisions donnent la température de l'air sous abri, à
deux mètres, dans un boîtier ventilé. Ce n'est pas ce que subit un pot posé sur
une terrasse. Par nuit dégagée et sans vent, l'écart atteint couramment trois à
cinq degrés : la station annonce 3 °C et il gèle quand même. Au Québec, c'est ce
qui tue les plantes en mai et en septembre, et aucune des applications testées
ne fait cette correction.

**Le vent, par plante et par endroit.** Les alertes publiques parlent de la
station : une rafale à dix mètres en terrain dégagé. Ce qui compte pour un pot,
c'est la rafale là où il est posé, rapportée à sa prise au vent. Un pot bas et
lourd dans un fond de cour ignore ce qui renverse un bananier sur un balcon
d'étage.

**La boucle fermée.** Une plante rentrée hier soir à cause du gel est proposée au
retour dès que la nuit le permet. Le motif du déménagement fait la différence
entre une mise à l'abri pour une nuit et un rangement jusqu'au printemps.

**L'acclimatation.** Une plante qui a passé l'hiver dedans, sous une lumière cent
fois plus faible qu'au dehors, brûle en une après-midi si on la pose au soleil.
La sortie se fait par paliers sur dix jours — et une journée froide, pluvieuse
ou venteuse suspend le programme au lieu de le faire avancer.

**L'arrosage qui suit le déménagement.** Une plante rentrée en octobre change de
régime : moins de lumière, moins d'évaporation, croissance arrêtée. Elle boit
deux à trois fois moins. L'erreur classique de l'automne n'est pas d'oublier
d'arroser, c'est de continuer au rythme de l'été. Le basculement est
automatique, parce que l'application sait qu'on a déplacé la plante.

---

## Le calcul du refroidissement nocturne

C'est le cœur de l'application. Quatre facteurs, dont un frein.

| | Effet |
|---|---|
| **Nébulosité** | Les nuages renvoient vers le sol le rayonnement infrarouge qu'il émet. Ciel couvert : il ne reste qu'un cinquième du refroidissement. |
| **Vent** | Le brassage détruit l'inversion. Dès une vingtaine de km/h, il ne reste presque plus de couche froide. |
| **Assise** | Un pot n'a pas l'inertie du sol, et son support décide de ce qu'il voit du ciel. Un pot surélevé descend plus bas qu'un pot au sol, qui descend plus bas que la pleine terre. |
| **Point de rosée** | Le frein. Quand la température le rejoint, la condensation puis le givre libèrent de la chaleur et ralentissent fortement la chute. |

Ce dernier point est ce qui sépare une application utilisable d'une application
qu'on désinstalle : une nuit humide ne gèle presque jamais aussi fort que
l'extrapolation le laisse croire, et une fausse alerte par semaine suffit à
faire ignorer toutes les autres.

S'y ajoute le **seuil racinaire**. La règle horticole courante retire environ
deux zones de rusticité — soit cinq degrés — à une plante cultivée en pot, dont
la motte est à l'air libre de tous les côtés. Elle ne s'applique qu'aux plantes
qui ont de la rusticité à perdre : une tropicale qui meurt déjà à 4 °C n'a rien
de plus à céder.

Le modèle est un ordre de grandeur, pas une mesure. Un thermomètre à minima posé
à côté des pots reste le seul juge, et la correction est désactivable dans les
réglages — précisément pour qu'on puisse comparer.

---

## Ouvrir et lancer

```bash
open Serre.xcodeproj
```

Xcode 16 ou plus récent, iOS 18 minimum. **Sans Mac**, la compilation et les
tests tournent de toute façon sur les exécuteurs macOS de GitHub à chaque
poussée — voir `.github/workflows/build.yml`. Le projet utilise des groupes
synchronisés avec le système de fichiers : ajouter un fichier Swift dans
`Serre/` suffit, il n'y a pas de liste de sources à tenir à jour.

Deux réglages avant de lancer sur un appareil :

1. **Équipe de signature** — `DEVELOPMENT_TEAM` est vide dans les deux cibles.
2. **Identifiant de paquet** — `ca.serre`, celui de la fiche App Store Connect.
   Il ne se change plus une fois la fiche créée.

Les tests :

```bash
xcodebuild test -scheme Serre -destination 'platform=iOS Simulator,name=iPhone 16'
```

Sans Mac sous la main, la compilation et les tests tournent sur les exécuteurs
macOS de GitHub à chaque poussée (`.github/workflows/build.yml`).

---

## Architecture

```
Serre/
├── Models/     Plante · Emplacement · Assise · ExpositionAuVent · PriseAuVent
│               Espece + Catalogue · Reglages · ZoneRusticite · Lieu
├── Engine/     RefroidissementNocturne · MoteurGel · MoteurVent
│               MoteurAcclimatation · MoteurArrosage · MoteurPlan · Saison
├── Services/   AppModel · AppleWeatherService · OpenMeteoService
│               LocationService · NotificationService · Store
└── Views/      Nuit · Plantes · PlanteDetail · AjouterPlante
                Arrosage · Reglages · Composants
```

`Engine/` ne dépend que de Foundation : aucun accès réseau, aucun état global,
aucune interface. C'est là que vit toute la physique, et c'est ce qui la rend
testable.

`AppModel` est le seul état partagé, exposé via `@Observable` et l'environnement
SwiftUI.

## Données

**Prévisions** — deux implémentations du même protocole `MeteoProviding`, et le
moteur ne sait pas laquelle il consomme.

`OpenMeteoService` est la source **par défaut**. Aucune clé, aucune capacité à
activer, aucune équipe de signature : le projet se compile et s'exécute tel
quel, dès le premier clonage. Son usage gratuit est réservé aux projets non
commerciaux, ce qui convient parfaitement à un usage familial.

`AppleWeatherService` est la source **pour une diffusion publique**, puisque
l'App Store sort du cadre non commercial d'Open-Meteo. Les 500 000 appels
mensuels sont inclus dans l'adhésion au programme développeur que la publication
exige de toute façon. Le passage se fait en trois étapes, dans l'ordre, et elles
sont détaillées en tête de `Serre.entitlements` : activer la capacité WeatherKit
pour `ca.serre` dans le portail développeur, l'ajouter dans *Signing &
Capabilities*, puis remplacer `OpenMeteoService()` par `AppleWeatherService()`
dans `AppModel.init`.

Sauter la première étape fait échouer la signature — et Xcode l'affiche comme un
échec de compilation, ce qui égare. C'est pourquoi l'entitlement n'est pas câblé
dans les réglages de build par défaut.

Deux écarts entre les deux fournisseurs sont isolés dans
`AppleWeatherService.Conversion`, parce que ce sont les seuls endroits où l'on
peut réellement se tromper : WeatherKit exprime la nébulosité de 0 à 1 là où le
moteur raisonne en pourcentage, et sa rafale est facultative — une heure sans
rafale annoncée retombe sur le vent moyen, jamais sur zéro, qui ferait passer un
coup de vent pour une nuit tranquille.

**Zones de rusticité** — celles de Ressources naturelles Canada, de 2b à 5b pour
le Québec.

**Catalogue** — une quarantaine d'espèces choisies pour ce qui se cultive
réellement ici : les tropicales qu'on sort l'été, les méditerranéennes qui
hivernent au garage, les annuelles fleuries, le potager, les fines herbes, les
succulentes et les vivaces rustiques. Les seuils sont des repères horticoles
courants, pas des constantes : ils varient selon le cultivar, l'âge du sujet et
son endurcissement, et restent modifiables plante par plante.

## Vie privée

Tout reste sur l'appareil. Seules des coordonnées arrondies au centième de degré
— environ un kilomètre — partent vers le service météo pour aller chercher les
prévisions. Aucun compte, aucun serveur, aucune synchronisation. Un lieu fixé à
la main court-circuite entièrement la géolocalisation.

Le manifeste `Serre/PrivacyInfo.xcprivacy` déclare la position comme collectée,
non liée à une identité, sans suivi, au seul titre du fonctionnement de
l'application.

## Publier sans Mac

La compilation, les tests et l'envoi vers TestFlight tournent tous sur les
exécuteurs macOS de GitHub. Aucun Mac n'est nécessaire, et c'est la clé d'API
App Store Connect qui remplace le passage habituel par le Trousseau macOS pour
créer le certificat de distribution.

**1. Créer la clé.** Sur [App Store Connect](https://appstoreconnect.apple.com) →
*Utilisateurs et accès* → onglet *Intégrations* → *App Store Connect API* →
*Clés de l'équipe* → **+**. Rôle **App Manager**, qui suffit pour téléverser.
Le fichier `.p8` ne se télécharge **qu'une seule fois** — perdu, il faut le
révoquer et recommencer. Notez au passage le *Key ID* et l'*Issuer ID* affiché
en haut de la page.

**2. Déposer quatre secrets** dans *Settings → Secrets and variables → Actions* :

| Secret | Contenu |
|---|---|
| `ASC_KEY_ID` | Le *Key ID*, dix caractères |
| `ASC_ISSUER_ID` | L'*Issuer ID*, un UUID |
| `ASC_PRIVATE_KEY` | Le contenu entier du `.p8`, lignes `BEGIN`/`END` comprises |
| `ASC_TEAM_ID` | Le *Team ID*, dix caractères, sous *Membership* du portail développeur |

**3. Lancer** l'action *Envoi vers TestFlight*, onglet *Actions*, bouton *Run
workflow*. Le numéro de build reprend le numéro d'exécution, ce qui garantit
qu'il ne recule jamais — Apple refuse un build dont le numéro n'augmente pas.

Ce workflow est **manuel exprès**. Le dépôt est public : un déclenchement par
poussée exposerait la mécanique de signature à du code venu de l'extérieur.

## Avant une mise en ligne

Ce qui reste à faire, et qui demande des mains humaines :

| | |
|---|---|
| **Icône** | Faite. `Tools/fabriquer-icone.py` la trace pixel par pixel, sans bibliothèque de dessin : une feuille prise par le givre sous un ciel dégagé et une lune haute — les conditions mêmes du refroidissement par rayonnement. |
| **Équipe** | `DEVELOPMENT_TEAM` est vide. L'identifiant `ca.serre` correspond déjà à la fiche App Store Connect. |
| **Politique de confidentialité** | Une URL publique est exigée dès qu'une application touche à la localisation. |
| **Captures d'écran** | Aux formats demandés par App Store Connect. |
| **WeatherKit** | Activer la capacité pour `ca.serre` dans le portail, puis basculer `AppModel` sur `AppleWeatherService` — voir `Serre.entitlements`. |
| **Attribution** | Déjà en place dans les réglages, et adaptée au fournisseur en usage. WeatherKit impose la marque Apple Weather et le lien vers les sources. Ne pas la retirer. |

Un mot sur la responsabilité. Un modèle de gelée qui sous-avertit coûte, chez
soi, une plante qu'on connaît. Publié, il coûte celles d'inconnus qui ont fait
confiance à l'alerte. D'où les marges conservatrices par défaut, et
l'avertissement que l'écran d'explication garde bien en vue : le modèle est un
ordre de grandeur, et un thermomètre à minima posé près des pots reste le seul
juge.
