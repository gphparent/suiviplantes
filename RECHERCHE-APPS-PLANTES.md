# Suivi des plantes : est-ce que l'app existe déjà ?

Recherche menée le 23 août 2026. Objectif : déterminer s'il existe une application iOS qui
couvre le besoin décrit — inventaire des plantes de la maison, suivi d'arrosage, **et** alertes
météo géolocalisées (gel nocturne, vent, chaleur) pour les plantes qui passent l'été dehors et
l'hiver dedans — ou s'il faut la construire.

> **Limite méthodologique.** L'environnement de recherche bloque l'accès direct à `apps.apple.com`
> et aux sites des éditeurs. Les fonctionnalités décrites ici proviennent des pages produit et des
> fiches App Store telles que restituées par la recherche web, pas d'un test en main. Avant de
> décider de construire quoi que ce soit, installer les deux ou trois candidates et valider
> (voir « Plan d'action », étape 1).

---

## 1. Résumé exécutif

**Les trois morceaux du besoin existent — mais dans trois familles d'apps différentes.**

| Ce que tu veux | Qui le fait bien | Qui ne le fait pas |
|---|---|---|
| Inventaire + journal d'arrosage/fertilisation | Planta, Greg, Blossom, Plantum, Pluctis (FR) | les apps d'alertes météo |
| Alertes gel / vent / canicule géolocalisées, par plante | My Cozy Plant, Growli, Frost Alert, Frost Watch | les apps de soin (sauf Planta, partiellement) |
| Calendrier semis intérieur → transplantation extérieure | Seed to Spoon, Seedtime, Plant It Planner, Rooted Reminders | les apps de soin |

**Aucune app ne modélise le cycle « je sors mes plantes en mai / je les rentre en septembre » comme
un objet de première classe.** C'est le vrai trou. Les autres trous sont dérivés de celui-là
(acclimatation, gelée au sol, vent sur pots hauts, boucle « rentrée → ressortie »).

**Recommandation : hybride, pas binaire.** Télécharger d'abord (Planta ou Greg + My Cozy Plant ou
Growli), vivre une saison complète avec, et ne construire que si les trous documentés en §4
te font encore mal en octobre. Détails en §6.

---

## 2. Le paysage, par famille

### 2.1 Soin des plantes / arrosage (marché mature, saturé)

| App | Ce qu'elle fait | Météo ? | Prix indicatif |
|---|---|---|---|
| **Planta** | Le plus complet : inventaire par « site », horaires d'arrosage/engrais/rempotage adaptés au type de plante, à la lumière et à la saison. 5 M d'utilisateurs. Interface FR. | **Oui** — utilise la météo locale pour ajuster les horaires et envoie des avertissements « trop chaud / trop froid / tempête / pluie forte / peu de soleil ». Exige la permission de localisation. | ~36 $US/an |
| **Greg** | Meilleur moteur d'arrosage : tient compte de la lumière, du terreau, du format de pot, intérieur/extérieur, et **de la météo locale réelle**. L'algorithme s'ajuste selon ton comportement d'arrosage. | Oui, pour l'arrosage — pas d'alertes de protection | freemium |
| **Blossom, Plantum, PictureThis, Plant Guru** | Identification IA + rappels génériques | marginal | freemium |
| **Plant Daddy, Happy Plant, Plante Arrosage Rappel, Water Plant Reminder** | Rappels d'arrosage simples, journal photo. Légers, gratuits ou presque. | non | gratuit/faible |
| **Gardenize, Plant Diary** | Journal de jardin, plantes intérieures **et** extérieures, plates-bandes, tâches saisonnières | non | freemium |

**Le point important :** Planta a rattrapé une partie du besoin météo. Ses avertissements couvrent
le froid et la tempête. Mais les critiques d'utilisateurs relèvent une intégration météo faible
et imprécise, l'absence d'avertissements de gel proprement dits (pas d'indication de dernier gel
au printemps, ni d'alerte « rentre cette plante-là ce soir »), et une bibliothèque de plantes
extérieures encore incomplète. Plusieurs demandes explicites d'utilisateurs vont exactement dans
le sens de ton besoin : « entrer mon adresse et recevoir une notification quand je dois rentrer
telle plante parce qu'il va faire trop froid ».

### 2.2 Alertes météo pour le jardin (famille récente, 2025-2026)

| App | Ce qu'elle fait | Trou |
|---|---|---|
| **My Cozy Plant** | **La plus proche de ton besoin côté alertes.** Gel et gel noir, canicule/montée en graine, **rafales et vents forts**, pluie torrentielle et pourriture racinaire, UV, sécheresse, conditions fongiques. Profils par plante (225+ variétés ou profils sur mesure) avec seuils de rusticité. Distingue **pot / pleine terre / protégé** et ajuste le seuil de risque. Deux notifications quotidiennes : bilan matinal 8 h et **alerte d'action 15 h**, assez tôt pour rentrer les pots avant le coucher du soleil. Conseiller d'arrosage (premium) basé sur pluie récente + évaporation + prévisions. | Gratuit = **1 seule plante**. Éditeur très jeune, très petit (variante « UK Frost Alert » = orientation britannique marquée). Pas de vrai journal d'arrosage ni d'historique. Pérennité incertaine. Pro : ~3 £/mois ou ~15 £/an. |
| **Growli** | Tâches quotidiennes calées sur la météo locale, **alertes gel gratuites à vie**, zone USDA / cote RHS / **température minimale de survie pour ~200 plantes**, guides de semis, diagnostic photo | Bibliothèque de 200 plantes seulement; app jeune; orientation UK |
| **Frost Alert, Frost Watch, FrostGuard** | Mono-fonction : minimum nocturne prévu + notification en soirée (19 h par défaut) « rentre tes pots » | Aucun inventaire, aucun suivi, aucune personnalisation par plante |

### 2.3 Planification potagère semis → transplantation

**Seed to Spoon** (dates de plantation calculées automatiquement selon ta localisation, calendrier
codé par couleur intérieur/extérieur, mode « semis intérieur », **alertes météo temps réel pour gel
et canicules**), **Seedtime**, **Plant It Planner** (tâches calées sur tes dates de gel locales :
semer dedans → transplanter → récolter, synchro web/iOS/Android), **Rooted Reminders**, **Planter**.

Cette famille couvre bien le « je commence dedans, je finis dehors » — **mais uniquement pour le
potager annuel**. Rien pour l'hibiscus en pot, le citronnier ou le laurier-rose qui font l'aller-retour
chaque année.

---

## 3. Ce qui se rapproche le plus de ton besoin, aujourd'hui

Aucune app seule. La combinaison la plus proche :

> **Planta** (ou Greg) pour l'inventaire et l'arrosage
> **+ My Cozy Plant** (ou Growli) pour les alertes gel / vent / canicule

Coût combiné : environ **50 à 60 $CA par année**. Couverture estimée du besoin : **~70 %**.
Le prix à payer : deux inventaires à tenir en parallèle, deux abonnements, aucune app ne sait ce
que l'autre sait.

---

## 4. Les trous réels

Classés du plus structurant au plus accessoire.

### 4.1 Le cycle intérieur ↔ extérieur n'est modélisé nulle part

Les apps de soin ont une notion de « site » (intérieur / extérieur), mais c'est un attribut statique,
pas un **événement de déménagement** avec un avant et un après. Conséquences :

- Pas de **période d'acclimatation** progressive (hardening off) pour une plante en pot qui sort au
  printemps — la fonction existe chez Seed to Spoon et Growli, mais réservée aux semis potagers.
- Pas de **rappel d'automne** « la première gelée arrive dans 10 jours, planifie la rentrée » basé
  sur la date de premier gel normale + la tendance des prévisions.
- Pas de **liste de contrôle au retour à l'intérieur** (inspection et traitement antiparasitaire —
  c'est le vecteur classique d'infestation hivernale : pucerons, cochenilles, aleurodes).
- Pas de **boucle fermée** : aucune app ne sait qu'une plante rentrée hier soir doit ressortir ce
  matin, ni ne te le rappelle.

### 4.2 L'alerte est calculée sur un point de grille, pas sur ton microclimat

Le cas qui tue les plantes au Québec en mai et en septembre : **la gelée au sol par rayonnement**.
Ciel dégagé, vent nul, la station annonce 3 °C — et il fait 0 °C ou −1 °C à hauteur de pot au
petit matin. Une alerte réglée sur « minimum prévu ≤ 0 °C » ne se déclenche jamais, et tu perds
la plante.

**Aucune des apps trouvées ne fait cette correction.** My Cozy Plant est la seule à ajuster selon
le contexte (pot / pleine terre / protégé), ce qui va dans la bonne direction mais reste
grossier — pas de correction rayonnement (couverture nuageuse + vent + point de rosée), pas de
capteur, pas d'apprentissage à partir de tes observations.

### 4.3 Le vent est traité de façon générique ou pas du tout

Seule My Cozy Plant émet des avertissements de rafales, et c'est un avertissement de zone, pas de
plante. Rien pour « ce pot de 1,5 m sur la terrasse exposée au sud-ouest se renverse à 50 km/h,
alors que le même pot contre le mur nord s'en fiche ». Ni exposition, ni hauteur, ni prise au vent,
ni distinction rafale / vent soutenu.

### 4.4 Arrosage et protection sont dans deux mondes séparés

Les apps d'arrosage ne font pas d'alertes de protection sérieuses. Les apps d'alertes ne tiennent
pas de journal d'arrosage sérieux. Pourtant les deux se parlent : une plante rentrée à l'intérieur
en octobre change complètement de régime d'arrosage (moins de lumière, moins d'évaporation,
chauffage sec), et aucune app ne fait cet ajustement automatiquement au moment du déménagement.

### 4.5 Localisation canadienne et québécoise

- Les données officielles existent et sont ouvertes : **zones de rusticité de Ressources naturelles
  Canada** (`planthardiness.gc.ca`, formule à 7 variables incluant la rafale maximale et l'enneigement)
  et **normales climatiques d'ECCC 1991-2020** pour les dates de gel. Zones typiques : Montréal 5b,
  Gatineau 5a, Québec / Sherbrooke / Trois-Rivières 4b.
- Les apps d'alertes sont orientées US ou UK (My Cozy Plant publie une variante « UK Frost Alert »).
  Aucune ne s'appuie sur les zones NRCan.
- Interface française : Planta, Blossom, Plantum et quelques petites apps FR (Pluctis, Plante
  Arrosage Rappel) l'ont. Les apps d'alertes météo-jardin, non.

### 4.6 Empilement d'abonnements

Trois besoins → deux ou trois abonnements. C'est le symptôme du trou, pas une fatalité.

---

## 5. Si on construit : ce que ça prend

C'est un projet **petit**, pas un projet d'app commerciale — à condition de viser l'usage familial.

### Architecture minimale
- **SwiftUI + SwiftData**, 100 % local. Pas de serveur, pas de compte, pas d'infrastructure.
- **WeatherKit** : 500 000 appels/mois inclus dans l'adhésion au programme développeur Apple
  (99 $US/an, que tu paies déjà ou non selon le cas). Couvre le Canada, donne le horaire sur
  plusieurs jours, la couverture nuageuse, le vent, les rafales et le point de rosée — tout ce qu'il
  faut pour la correction rayonnement.
  *Alternative* : **Open-Meteo**, gratuit, sans clé, horaire jusqu'à 16 jours — mais **licence non
  commerciale**, donc parfait pour un usage perso/familial, à revoir si tu publies un jour.
- **Notifications locales + BackgroundTasks** pour le rafraîchissement des prévisions. Aucun push
  serveur nécessaire.

### Modèle de données (le cœur)
```
Plante
  ├─ seuilFroidCritique (°C)         ← température minimale de survie
  ├─ seuilFroidConfort (°C)          ← « stresse en dessous », déclenche l'alerte douce
  ├─ seuilVent (km/h) + priseAuVent  ← hauteur, exposition
  ├─ emplacementActuel               ← Intérieur | Extérieur | En acclimatation
  ├─ historiqueDéménagements[]       ← date, sens, motif (le cycle, enfin modélisé)
  └─ journalArrosage[]               ← + règle d'arrosage qui change selon l'emplacement

MoteurDeRisque (une fois par jour, en après-midi)
  minPrévu
  − correctionRayonnement(couvertureNuageuse, vent, pointDeRosée)
  → compare aux seuils de chaque plante EXTÉRIEURE
  → une seule notification à 15 h : « Rentre ces 6 plantes ce soir » + liste cochable
  → lendemain 8 h : « Il fera 14 °C, tu peux ressortir ces 6 plantes »
```

### MVP réaliste
1. Inventaire de plantes avec deux seuils de température, un seuil de vent et un emplacement.
2. Moteur de risque nocturne avec correction rayonnement.
3. Notification d'action en après-midi, avec liste nommée et cochable.
4. Notification de retour le lendemain matin, si la fenêtre est favorable.
5. Journal d'arrosage simple, dont la fréquence bascule automatiquement au déménagement.

Effort : **2 à 4 fins de semaine** pour une version familiale utilisable. Une version publiable sur
l'App Store (bibliothèque de plantes, identification, onboarding, support), c'est un tout autre
projet — plusieurs mois.

### Ce qu'il ne faut PAS reconstruire
Identification de plantes par photo, diagnostic de maladies, bibliothèque de 30 000 espèces,
guides d'entretien. C'est là que les concurrents ont investi des années, et ce n'est pas ton besoin.

---

## 6. Plan d'action recommandé

**Étape 1 — cette semaine (coût : ~0 $).**
Installer **My Cozy Plant** (version gratuite, 1 plante — assez pour juger de la qualité et du
timing des alertes) et **Growli** (alertes gel gratuites à vie, avec les températures minimales de
survie). Vérifier trois choses concrètes :
- est-ce que les alertes arrivent assez tôt (15 h, pas 21 h) ?
- est-ce que les seuils sont réglables par plante ?
- est-ce que ça fonctionne correctement avec une localisation québécoise ?

**Étape 2 — le reste de la saison (coût : ~36 $US/an).**
Si l'arrosage est le besoin dominant, prendre **Planta** et activer la localisation pour ses
avertissements météo. Sinon, **Greg** gratuit suffit pour l'arrosage.

**Étape 3 — bilan en octobre, après la première rentrée d'automne.**
Poser la seule question qui compte : **est-ce que j'ai perdu ou stressé une plante que l'app aurait
dû me faire rentrer ?** Si oui, c'est presque certainement à cause du trou 4.2 (gelée au sol) ou du
trou 4.1 (aucune app ne ferme la boucle) — et là, construire se justifie, parce que ces deux trous
sont précisément ceux qui se règlent en un week-end de code et que personne ne va combler pour toi.

Si non : garder les deux apps, économiser le temps de développement.

---

## Sources

- [Best Plant Care Apps in 2026 — MyPlantIn](https://myplantin.com/blog/best-plant-care-apps)
- [Best Free Plant Care Apps in 2026 — Garden.gg](https://garden.gg/blog/best-free-plant-care-apps-2026/)
- [My Cozy Plant — site officiel](https://www.mycozyplant.com/)
- [My Cozy Plant: Garden Weather — App Store](https://apps.apple.com/us/app/my-cozy-plant-garden-weather/id6757018818)
- [Growli — hardiness par espèce](https://www.getgrowli.app/hardiness)
- [Growli: Plant & Garden Care — App Store](https://apps.apple.com/us/app/growli-plant-garden-care/id6759293623)
- [Planta — comment l'app utilise les données météo](https://support.getplanta.com/how-does-planta-use-weather-data-to-give-accurate-care-advice/)
- [Planta — quoi de neuf dans cette version](https://support.getplanta.com/whats-new-in-this-version/)
- [Planta — avis utilisateurs](https://justuseapp.com/en/app/1410126781/planta-keep-your-plants-alive/reviews)
- [PlantIn : suivi des plantes intérieures et extérieures — Permies](https://permies.com/t/275756/Plantin-app-review-track-indoor)
- [Greg — App Store](https://apps.apple.com/us/app/greg-plant-identifier-care/id1512912236)
- [Greg app : revue et alternative — Botanical Legacy](https://botanicallegacy.com/blog/greg-app-alternative)
- [Seed to Spoon — Garden Planner, App Store](https://apps.apple.com/us/app/seed-to-spoon-garden-planner/id1312538762)
- [Plant It Planner](https://www.plantitplanner.com/)
- [Rooted Reminders — App Store](https://apps.apple.com/us/app/rooted-reminders/id6751784400)
- [Seedtime: Garden Planner — App Store](https://apps.apple.com/us/app/seedtime-garden-planner-app/id6496536815)
- [Frost Alert — App Store](https://apps.apple.com/us/app/frost-alert/id6787781453)
- [Frost Watch — App Store](https://apps.apple.com/us/app/frost-watch/id6761346646)
- [Blossom — soin des plantes, App Store FR](https://apps.apple.com/fr/app/blossom-soin-des-plantes/id1487453649)
- [Plante Arrosage Rappel — App Store FR](https://apps.apple.com/fr/app/plante-arrosage-rappel/id1592638714)
- [Zones de rusticité du Québec — GrowersGuide.ca](https://growersguide.ca/blog/quebec-hardiness-zones)
- [Zones de rusticité des plantes au Canada — Ressources naturelles Canada](https://natural-resources.canada.ca/stories/simply-science/zone-canada-s-plant-hardiness-zone-maps-website-get-update)
- [Zones de rusticité et dates de gel au Canada — Veseys](https://www.veseys.com/ca/canada-hardiness-zones-frost-dates)
- [Open-Meteo — API météo libre](https://open-meteo.com/)
- [WeatherKit : abonnements — Apple Developer](https://developer.apple.com/news/?id=wsx8rd26)
- [Comparatif des API météo gratuites 2026 — Jua](https://jua.ai/articles/free-weather-api-comparison-2026/)
- [Rentrer les plantes d'intérieur pour l'hiver — UMN Extension](https://extension.umn.edu/yard-and-garden-news/bringing-houseplants-back-inside)
- [Acclimatation des semis — Gardenly](https://gardenly.app/blog/hardening-off-seedlings-guide)
