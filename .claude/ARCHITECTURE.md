# 🏗️ Architecture — Werewolf Narrator

Application Flutter **offline-first** destinée au narrateur d'une partie de Loup-Garou.
Elle suit en temps réel les rôles distribués, les actions de chaque nuit, les couples,
les morts, les votes du village, et conserve l'historique complet des parties dans une
base SQLite **chiffrée AES-256 (SQLCipher)**.

> Ce document est la référence vivante du projet. Il est mis à jour après **chaque**
> feature livrée.

---

## 1. Stack technique

| Domaine | Choix | Justification |
|---------|-------|---------------|
| Framework | Flutter 3.47.3 / Dart 3.13.3 | Dernière stable au moment du build |
| State management / DI | `flutter_riverpod` | Injection de dépendances + état réactif, testable sans widget |
| Base de données | `drift` (SQLite typé) | Requêtes typées, streams réactifs, tests en mémoire |
| Chiffrement DB | `sqlite3` ^3.5 en mode `source: sqlcipher` | Build SQLCipher (AES-256) sélectionné via les *hooks* Dart — remplace `sqlcipher_flutter_libs`, déprécié |
| Stockage de la clé | `flutter_secure_storage` | Keystore Android / Keychain iOS |
| Chiffrement export | `encrypt` (AES-GCM) + `pointycastle` (PBKDF2) | AEAD authentifié + dérivation de clé depuis mot de passe |
| UUID | `uuid` v4 | Identifiants stables, hors-ligne |
| Partage de fichier | `share_plus` | Export natif Android/iOS |
| Sélection de fichier | `file_picker` | Import d'un export chiffré |
| Tests | `flutter_test` + `mocktail` + `drift` (NativeDatabase.memory) | Unitaires, DAO et widgets |

### Sélection du build SQLCipher

Depuis `package:sqlite3` 3.x, les paquets `sqlcipher_flutter_libs` / `sqlite3_flutter_libs`
sont dépréciés (`0.7.0+eol`). Le build natif est désormais choisi via les *hooks* Dart,
dans le `pubspec.yaml` :

```yaml
hooks:
  user_defines:
    sqlite3:
      source: sqlcipher
```

Le binaire SQLCipher (community edition, AES-256) est alors compilé/téléchargé au moment
du build et embarqué dans l'application — y compris pour `flutter test`, ce qui permet de
**tester réellement le chiffrement au repos**.

### Aucune dépendance réseau

Aucun package de la liste n'effectue d'appel réseau au runtime. Les analytics du SDK
Flutter sont désactivées (`flutter config --no-analytics`, `dart --disable-analytics`).
L'`AndroidManifest.xml` **ne déclare pas** la permission `INTERNET`.

---

## 2. Structure du code — feature-first + couches

```
lib/
├── main.dart                          # bootstrap : clé → base chiffrée → ProviderScope
├── app.dart                           # MaterialApp, thème, locale fr_FR, écran d'échec
│
├── core/                              # transverse à toutes les features
│   ├── database/
│   │   ├── tables.dart                # les 4 tables Drift
│   │   ├── app_database.dart          # @DriftDatabase, migrations, PRAGMA foreign_keys
│   │   ├── app_database.g.dart        # généré par build_runner (versionné, cf. D7)
│   │   └── database_opener.dart       # ouverture SQLCipher (PRAGMA key)
│   ├── security/
│   │   ├── key_store.dart             # clé DB : génération + Keystore/Keychain
│   │   └── crypto_service.dart        # AES-256-GCM + PBKDF2 pour l'export
│   ├── providers/core_providers.dart  # appDatabaseProvider, uuidProvider, clockProvider
│   ├── errors/app_exception.dart      # hiérarchie scellée d'exceptions métier
│   ├── theme/app_theme.dart           # Material 3 sombre + couleurs de camps
│   └── utils/
│       ├── formatters.dart            # dates FR, pluriels
│       └── ui_feedback.dart           # runGuarded / showMessage
│
└── features/
    ├── games/
    │   ├── domain/
    │   │   ├── role.dart                    # catalogue de 26 rôles
    │   │   ├── game_entities.dart           # Game, Player, GameSnapshot
    │   │   └── games_repository.dart        # interface + PlayerDraft
    │   ├── data/
    │   │   ├── game_mappers.dart            # rows Drift ↔ entités
    │   │   └── games_repository_impl.dart
    │   └── presentation/
    │       ├── home_screen.dart
    │       ├── game_setup_screen.dart
    │       ├── game_detail_screen.dart
    │       ├── controllers/
    │       │   ├── games_providers.dart
    │       │   ├── game_setup_controller.dart
    │       │   └── game_board_controller.dart
    │       └── widgets/
    │           ├── game_card.dart
    │           ├── player_tile.dart
    │           ├── player_actions_sheet.dart
    │           ├── role_badge.dart
    │           └── role_picker_sheet.dart
    │
    ├── nights/
    │   ├── domain/
    │   │   ├── night_action_type.dart       # catalogue de 21 types d'actions
    │   │   ├── night_entities.dart          # Night, NightAction, NightOutcome
    │   │   ├── night_resolver.dart          # ⚙️ moteur de résolution (pur)
    │   │   └── nights_repository.dart
    │   ├── data/
    │   │   ├── night_mappers.dart
    │   │   └── nights_repository_impl.dart  # + NightContext (vue pour l'écran)
    │   └── presentation/
    │       ├── night_screen.dart
    │       ├── controllers/nights_providers.dart
    │       └── widgets/
    │           ├── action_entry_dialog.dart
    │           └── night_outcome_view.dart
    │
    ├── victory/
    │   ├── domain/
    │   │   ├── victory_entities.dart         # VictoryCamp, VictoryResult
    │   │   └── victory_engine.dart           # ⚖️ règles de fin de partie (pur)
    │   ├── data/victory_recorder.dart        # évalue + clôt la partie en base
    │   └── presentation/victory_screen.dart
    │
    ├── history/
    │   └── presentation/history_screen.dart
    │
    └── export/
        ├── domain/game_archive.dart         # DTO sérialisable d'une partie complète
        ├── data/export_service.dart         # archive → chiffrement → fichier ; et retour
        └── presentation/
            ├── export_actions.dart          # parcours export / import
            ├── password_dialog.dart
            └── controllers/export_providers.dart
```

**Règle de dépendance** : `presentation → domain ← data`.
La couche `domain` ne dépend ni de Flutter ni de Drift, ce qui rend le moteur de
résolution des nuits testable en pur Dart.

Les features se composent au niveau `presentation` uniquement : l'écran de partie
(`games`) affiche la liste des nuits (`nights`) et ouvre l'historique (`history`),
mais aucun repository ne dépend d'une autre feature.

### Miroir des tests

`test/` reprend l'arborescence de `lib/`, plus un dossier `test/security/` qui
garde les promesses de sécurité (pas de permission réseau, pas de socket).

---

## 3. Schéma de base de données (Drift, `schemaVersion = 3`)

### `games`
| Colonne | Type | Notes |
|---------|------|-------|
| `id` | TEXT PK | UUID v4 |
| `name` | TEXT | nom de la partie |
| `createdAt` | DATETIME | |
| `updatedAt` | DATETIME | |
| `status` | TEXT | `setup` \| `inProgress` \| `finished` |
| `isArchived` | BOOL | défaut `false` |
| `notes` | TEXT? | notes libres du narrateur |
| `winnerCampId` | TEXT? | *(v2)* camp vainqueur — `village`, `werewolves`, `lovers`, `nobody`, `lastStanding` ou l'id d'un rôle solo |
| `winnerReason` | TEXT? | *(v2)* la phrase lue par le narrateur à l'annonce du résultat |

### `players`
| Colonne | Type | Notes |
|---------|------|-------|
| `id` | TEXT PK | UUID v4 |
| `gameId` | TEXT FK → `games.id` | `ON DELETE CASCADE` |
| `name` | TEXT | |
| `roleId` | TEXT | clé du catalogue de rôles (`werewolf`, `seer`, …) |
| `seatOrder` | INT | ordre autour de la table |
| `isAlive` | BOOL | défaut `true` |
| `isCaptain` | BOOL | défaut `false` (le Capitaine est un **statut**, pas un rôle) |
| `coupledWithPlayerId` | TEXT? | l'autre amoureux (relation symétrique) |
| `isCharmed` | BOOL | Joueur de flûte |
| `deathNightNumber` | INT? | numéro du tour où le joueur est mort |
| `deathCause` | TEXT? | libellé lisible (« dévoré par les loups », …) |
| `notes` | TEXT? | |

### `nights`
Un enregistrement `nights` représente **un tour complet** : la phase de nuit *et* le
vote du village qui la suit. Choix documenté en §7 (décision D2).

| Colonne | Type | Notes |
|---------|------|-------|
| `id` | TEXT PK | UUID v4 |
| `gameId` | TEXT FK → `games.id` | `ON DELETE CASCADE` |
| `nightNumber` | INT | 1, 2, 3… |
| `createdAt` | DATETIME | |
| `resolvedAt` | DATETIME? | non nul = nuit close, actions figées |
| `summaryJson` | TEXT? | `NightOutcome` sérialisé au moment de la résolution |

### `night_actions`
| Colonne | Type | Notes |
|---------|------|-------|
| `id` | TEXT PK | UUID v4 |
| `nightId` | TEXT FK → `nights.id` | `ON DELETE CASCADE` |
| `gameId` | TEXT | dénormalisé (requêtes d'historique) |
| `type` | TEXT | clé du catalogue d'actions |
| `actorPlayerId` | TEXT? | qui agit |
| `targetPlayerId` | TEXT? | cible principale |
| `secondaryTargetPlayerId` | TEXT? | 2ᵉ cible (couple Cupidon, …) |
| `detailsJson` | TEXT? | payload libre (rôle vu par la Voyante, …) |
| `orderIndex` | INT | ordre de saisie dans la nuit |
| `createdAt` | DATETIME | horodatage de la saisie |

### `game_role_selections` *(v3)*
Les rôles autorisés dans une partie — une ligne par rôle coché.

| Colonne | Type | Notes |
|---------|------|-------|
| `gameId` | TEXT FK → `games.id` | `ON DELETE CASCADE`, PK composite |
| `roleId` | TEXT | clé du catalogue, PK composite |

**Aucune ligne** pour une partie = pas de composition explicite (partie créée par la
v1) : l'application lit alors le catalogue entier, ce qui préserve le comportement
d'origine.

Les clés étrangères sont activées via `PRAGMA foreign_keys = ON`.

### Migrations

`onUpgrade` n'ajoute que des colonnes et des tables ; aucune table n'est jamais recréée,
donc une partie enregistrée par une version antérieure survit à la mise à jour.

| Version | Contenu |
|---------|---------|
| 1 | schéma initial du MVP (4 tables) |
| 2 | `games.winnerCampId`, `games.winnerReason` — mémorisation du camp vainqueur |
| 3 | table `game_role_selections` — rôles autorisés par partie |

---

## 4. Catalogue de rôles (extensible)

Défini dans `features/games/domain/role.dart` sous forme de `const List<RoleDefinition>`.
Chaque rôle porte : `id`, `label` (FR), `description` courte, `team`
(`village` / `werewolves` / `solo`), `emoji`, `actsAtNight`, `firstNightOnly`.

Ajouter un rôle = ajouter une entrée dans la liste **et** (si le rôle agit la nuit) un
type d'action dans `night_action_type.dart`. Aucune migration DB nécessaire : `roleId`
est un `TEXT` libre, et un rôle inconnu retombe sur un `RoleDefinition.unknown`.

---

## 5. Moteur de résolution d'une nuit

`NightResolver.resolve(players, actions, nightNumber) → NightOutcome`

Fonction **pure** (aucune I/O), donc entièrement testable :

1. Collecte des attaques létales : loups, potion de mort, Loup Blanc, vote du village,
   tir du Chasseur.
2. Application des protections : Salvateur (`guardProtect`) et potion de vie
   (`witchHeal`) annulent l'attaque des loups ; la potion de mort et le vote ne sont
   **pas** protégeables.
3. Cascade des amoureux : la mort d'un amoureux entraîne celle de l'autre (chagrin),
   récursivement.
4. Production du `NightOutcome` : morts (avec cause), sauvetages, nouveaux couples,
   révélations de la Voyante, joueurs charmés.
5. Le repository applique ensuite l'outcome : `isAlive`, `deathNightNumber`,
   `deathCause`, `coupledWithPlayerId`, `isCharmed`.

---

## 4 bis. Distribution aléatoire des rôles *(v2)*

`RoleDealer.deal(playerCount, allowedRoleIds, random) → List<String>` — une fonction
**pure** de `games/domain`, un rôle par siège, mélangé. Le bouton « Distribution
aléatoire » n'est qu'un appel de plus : rien n'est verrouillé, chaque assignation reste
modifiable à la main, et re-cliquer redistribue tout depuis zéro.

### Nombre de Loups-Garous par taille de table

| Joueurs | Loups |
|---------|-------|
| 3 – 6 | 1 |
| 7 – 9 | 2 |
| 10 – 12 | 3 |
| 13 – 15 | 4 |
| 16 – 18 | 5 |
| 19 et + | 6 |

La meute est en plus plafonnée à `(n-1) ~/ 2` : les loups ne peuvent jamais commencer une
partie en position de victoire immédiate. Cette table remplace l'ancienne heuristique
`(n/4).round()` de l'écran de création, qui vit maintenant dans le même endroit.

### Seuils par rôle

Chaque `RoleDefinition` porte deux champs de distribution :

- `dealCopies` — nombre d'exemplaires distribués (`0` = « autant que nécessaire », pour le
  Villageois et le Loup-Garou ; `2` pour les Deux Sœurs, `3` pour les Trois Frères ; `1`
  pour tous les autres, d'où `isUnique`) ;
- `minPlayers` — table minimale en dessous de laquelle le distributeur ignore le rôle.

| Seuil | Rôles |
|-------|-------|
| 4 | Voyante |
| 5 | Sorcière |
| 6 | Chasseur, Cupidon |
| 8 | Salvateur, Petite Fille |
| 9 | Voleur, Ancien, Idiot du Village, Renard, Enfant sauvage, Ange, Deux Sœurs |
| 10 | Bouc émissaire, Chevalier, Montreur d'ours, Juge bègue, Corbeau, Servante, Grand Méchant Loup |
| 11 | Trois Frères |
| 12 | Infect Père des Loups, Loup-Garou Blanc, Joueur de Flûte |

En dessous du seuil, le rôle reste **assignable à la main** : seul le tirage au sort
l'ignore.

### Déroulé du tirage

1. La meute : les variantes de loup (Grand Méchant Loup, Infect Père des Loups,
   Loup-Garou Blanc) prennent une place **dans** le quota, jamais en plus, et seulement si
   la meute compte au moins 2 places — un pack sans Loup-Garou ordinaire n'aurait pas de
   sens.
2. Les rôles spéciaux : les classiques d'abord (Voyante, Sorcière, Chasseur, Cupidon,
   Salvateur), puis les autres dans un ordre aléatoire, tant qu'il reste des places
   au-delà du plancher de `max(1, n ~/ 4)` Villageois simples.
3. Le reste de la table reçoit Villageois.
4. L'ensemble est mélangé.

Cupidon distribué ne crée **aucun couple** : le randomiseur distribue des rôles, pas des
actions. Le couple reste une action de la première nuit, proposée automatiquement par la
séquence de cartes tant que Cupidon est vivant.

---

## 4 ter. Composition d'une partie *(v2)*

Avant de distribuer, le narrateur choisit **quels rôles** du catalogue sont autorisés dans
cette partie précise. `GameComposition` (domain) définit les invariants :

- `mandatoryRoleIds` = `{villager, werewolf}` — les fondations du jeu, cochées et
  **non décochables** ;
- `defaultRoleIds` = la boîte de base (Villageois, Loup-Garou, Voyante, Sorcière,
  Chasseur, Cupidon, Salvateur, Petite Fille) ;
- `normalize()` retire les rôles inconnus et remet les fondations, quoi qu'on lui passe.

L'écran `CompositionScreen` est une simple liste à cocher groupée par camp, avec deux
raccourcis (« Tout » / « Base ») et un indicateur « table trop petite » sur les rôles dont
le `minPlayers` dépasse la taille de la table — ces rôles restent cochables et assignables
à la main, seul le tirage au sort les ignore.

**Réutilisation** : `loadLastComposition()` renvoie la composition de la partie créée le
plus récemment, et sert de valeur par défaut à la création suivante — y compris au
« Nouvelle partie » après une victoire. À défaut de partie antérieure, c'est la boîte de
base.

---

## 5 bis. Moteur de fin de partie *(v2)*

`VictoryEngine.evaluate(players) → VictoryResult?` — fonction **pure**, sans base ni
widget, testée seule.

Le moteur est une **liste ordonnée de règles** (`VictoryRule`) plutôt qu'une cascade de
`if` : ajouter un rôle solo avec sa propre condition de victoire = ajouter un objet à la
liste. La position dans la liste *est* la priorité.

| Ordre | Règle | Condition | Vainqueur |
|-------|-------|-----------|-----------|
| 1 | `nobodyLeft` | plus aucun survivant | Personne (la partie s'arrête quand même) |
| 2 | `mixedLovers` | les 2 derniers survivants sont un couple de camps différents | Les Amoureux |
| 3 | `angel` | l'Ange a été éliminé au **tour 1** | L'Ange, seul |
| 4 | `piper` | le Joueur de Flûte est vivant et tous les autres survivants sont charmés | Le Joueur de Flûte |
| 5 | `soloSurvivor` | un unique survivant, de camp `solo` | Ce rôle (Loup-Garou Blanc…) |
| 6 | `village` | plus aucun joueur « côté loup » vivant | Le Village |
| 7 | `werewolves` | `survivants non-loups <= loups vivants` et au moins un loup vivant | Les Loups-Garous |
| 8 | `lastStanding` | filet de sécurité : un seul survivant qu'aucune règle ci-dessus ne couvre | Ce survivant |

« Côté loup » = `RoleDefinition.wolfSide`, un drapeau ajouté au catalogue : il est vrai
pour le Loup-Garou, le Grand Méchant Loup, l'Infect Père des Loups **et** le Loup-Garou
Blanc, qui joue seul mais chasse avec la meute — le Village ne gagne qu'une fois qu'il est
mort lui aussi.

### Quand la vérification se déclenche

`VictoryRecorder.refresh(gameId)` est appelé :

- après la résolution d'une nuit (`DriftNightsRepository.resolveNight`) ;
- après **toute** écriture sur les joueurs (`DriftGamesRepository.savePlayers`), ce qui
  couvre le vote du village, le tir du Chasseur et les retouches manuelles du narrateur ;
- après le retrait d'un joueur de la table.

Quand une règle se déclenche, la partie passe en `finished`, le camp et sa justification
sont écrits sur la ligne `games`, l'écran de partie affiche la bannière de victoire et le
bouton « Nouvelle nuit » disparaît. `startNight` refuse d'ouvrir un tour sur une partie
terminée. Reprendre la partie à la main (menu « Reprendre la partie ») efface le
vainqueur mémorisé : il sera recalculé au prochain mouvement du plateau.

---

## 6. Flux de données

```
Widget ──watch──► StreamProvider/AsyncNotifier (Riverpod)
                        │
                        ▼
                 Repository (interface domain)
                        │
                        ▼
             Drift DAO ──► SQLCipher (AES-256, clé en Keystore)
```

- Les écrans **lisent** via des `StreamProvider` alimentés par les `watch…()` de Drift :
  toute écriture rafraîchit l'UI automatiquement.
- Les écrans **écrivent** via des `Notifier`/`AsyncNotifier` qui appellent le repository.
  Aucune logique métier dans les widgets.

### Bootstrap (`main.dart`)
```
WidgetsFlutterBinding.ensureInitialized()
  → KeyStore.getOrCreateDatabaseKey()      (génère 32 octets aléatoires au 1er lancement)
  → openEncryptedDatabase(key)             (PRAGMA key = "x'<hex>'")
  → ProviderScope(overrides: [appDatabaseProvider.overrideWithValue(db)])
```

---

## 7. Décisions d'architecture

| # | Décision | Raison |
|---|----------|--------|
| **D1** | Le **Capitaine** est un booléen sur `players`, pas un rôle | Le Capitaine est élu et cumule avec un rôle réel ; en faire un rôle empêcherait d'en avoir un autre. |
| **D2** | La table s'appelle `nights` mais porte aussi le **vote du village** du jour suivant | Un tour de jeu = nuit + jour. Éviter une 5ᵉ table pour un seul type d'action. Le type `villageVote` distingue la phase. |
| **D3** | Couches **dans** chaque feature plutôt qu'à la racine | Le brief impose feature-first ; garder `data/domain/presentation` par feature limite le couplage inter-features. |
| **D4** | La DB est ouverte **avant** `runApp` et injectée par override Riverpod | Permet aux tests de fournir une DB en mémoire sans SQLCipher, et évite un état « DB non prête » dans l'UI. |
| **D5** | Export = **AES-256-GCM** avec clé dérivée par **PBKDF2-HMAC-SHA256 (150 000 itérations)** | Le brief impose AES-GCM ; un mot de passe utilisateur ne peut pas servir de clé directement. Sel et nonce aléatoires par export. |
| **D6** | Le catalogue de rôles est du **code**, pas une table | Les rôles ne changent pas par partie ; les mettre en DB imposerait des migrations pour chaque ajout. |
| **D7** | `*.g.dart` reste ignoré **sauf** `lib/core/database/app_database.g.dart`, qui est versionné | Le repo doit compiler depuis un clone frais sans lancer `build_runner` au préalable. C'est le seul fichier généré du projet. |
| **D8** | Les tests de logique utilisent `NativeDatabase.memory()` (non chiffré) | Le chiffrement est une propriété de l'**ouverture** du fichier, orthogonale à la logique testée. Il est vérifié séparément, sur un vrai fichier, par `test/core/database/database_encryption_test.dart`. |
| **D9** | L'en-tête de l'export est passé en **AAD** au chiffrement GCM | Sans cela, un attaquant pourrait réécrire `iterations` ou `version` sans invalider le tag. L'AAD est reconstruit champ par champ, pas depuis le texte JSON, pour qu'un reformatage du fichier ne casse pas un import légitime. |
| **D10** | L'import **régénère tous les identifiants** | Permet d'importer deux fois le même fichier, et garantit qu'un import n'écrase jamais une partie déjà présente. Les couples, les actions et les bilans stockés sont remappés en conséquence. |
| **D11** | Le Capitaine, les charmes et les rôles modifiés sont appliqués par `NightResolver.apply` | Une seule fonction décrit l'effet d'un tour sur le plateau ; le repository n'est plus qu'une traduction en SQL. |
| **D18** | La composition est une **table dédiée** (`game_role_selections`), pas une colonne JSON sur `games` | C'est un ensemble de clés vers le catalogue : SQLite sait faire des ensembles, et une ligne par rôle permet de filtrer/joindre sans désérialiser. Le `ON DELETE CASCADE` nettoie tout seul. |
| **D19** | Aucune ligne de composition = **catalogue entier**, jamais « aucun rôle » | Les parties créées par la v1 n'ont pas de composition : les lire comme « vide » reviendrait à leur retirer des rôles qu'elles utilisent déjà. |
| **D16** | La table « loups par joueurs » et les seuils de rôles vivent dans le **catalogue** (`dealCopies`, `minPlayers`) et dans `RoleDealer`, pas dans l'UI | Ajouter un rôle = une entrée dans `role.dart` ; le distributeur le prend en compte sans être modifié. |
| **D17** | Le Loup-Garou Blanc occupe une place **du quota** de loups, pas une place en plus | Il chasse avec la meute (`wolfSide`) : lui donner un siège supplémentaire déséquilibrerait la table par rapport à la règle de parité. |
| **D13** | La détection de victoire est une **liste de règles ordonnée**, pas un `if/else` village-vs-loups | Les rôles solitaires (Loup Blanc, Joueur de Flûte, Ange) ont chacun leur propre condition ; les ajouter ne doit pas rouvrir le moteur. La priorité des Amoureux mixtes est simplement leur position dans la liste. |
| **D14** | Une partie **sans aucun Loup-Garou** se termine dès la première vérification par une victoire du Village | Le brief demande de ne jamais laisser tourner une partie qui ne peut plus se terminer. La règle officielle est « le Village gagne dès que le dernier loup est éliminé » : avec zéro loup, cette condition est vraie d'emblée. Le libellé annoncé est alors « Aucun Loup-Garou ne menace le village », pour ne pas laisser croire qu'un loup a été tué. L'écran de création affiche en plus un avertissement quand la table ne compte aucun loup — la partie n'est jamais bloquée, mais le narrateur est prévenu. |
| **D15** | `VictoryRecorder` (couche `data` de `victory`) est appelé par les repositories `games` et `nights` | Exception assumée à « aucun repository ne dépend d'une autre feature » : la fin de partie est une règle transverse qui doit s'appliquer **quel que soit** le chemin d'écriture. Les dépendances restent à sens unique (`games`/`nights` → `victory`), sans cycle, et le moteur reste pur et testable seul. |
| **D12** | Les tests de widgets démontent l'arbre **dans** le corps du test | Drift planifie un timer à durée nulle en annulant un stream ; le laisser au teardown fait échouer l'invariant « A Timer is still pending ». Voir SETUP_LOG.md, problème n°2. |

---

## 8. Sécurité

- 🔒 **DB chiffrée** SQLCipher AES-256 ; le fichier `.db` est illisible hors de l'app.
- 🔑 **Clé** : 32 octets de `Random.secure()`, générés au premier lancement, stockés
  **uniquement** dans `flutter_secure_storage` (EncryptedSharedPreferences sur Android,
  Keychain `first_unlock_this_device` sur iOS). Jamais en dur, jamais versionnée.
- 📴 **Zéro réseau** : pas de permission `INTERNET`, aucun package appelant le réseau,
  analytics Flutter désactivées.
- 📦 **Export** : AES-256-GCM, clé PBKDF2 (150k itérations, sel 16 o), nonce 12 o
  aléatoire, tag d'authentification vérifié à l'import. Jamais d'export en clair.
- 🙈 **Logs** : aucun `print`/`debugPrint` de clé, de mot de passe ou de contenu déchiffré.

---

## 9. Roadmap

- [x] **E0 — Setup** : SDK Flutter, scaffold du projet, dépendances, lints
- [x] **E1 — Noyau sécurité & DB** : `KeyStore`, ouverture SQLCipher, tables Drift
- [x] **E2 — Catalogue de rôles** : 26 rôles extensibles, 21 types d'actions
- [x] **E3 — Feature games** : repository, providers, écran d'accueil (actives/archivées)
- [x] **E4 — Création de partie** : nom → joueurs → assignation des rôles
- [x] **E5 — Détail de partie** : vue joueurs, statut, couples, retouches manuelles
- [x] **E6 — Feature nights** : moteur de résolution + repository + persistance
- [x] **E7 — Écran nuit** : formulaire dynamique selon rôles vivants + résumé de fin
- [x] **E8 — Historique** : chronologie complète d'une partie
- [x] **E9 — Export chiffré** : JSON → AES-GCM → partage
- [x] **E10 — Import chiffré** : lecture d'un export + restauration sous de nouveaux ids
- [x] **E11 — Archivage / suppression** de partie
- [x] **E12 — Finalisation** : `flutter analyze` clean, 129 tests verts, APK release, docs

### Pistes pour une version ultérieure

Hors périmètre du MVP, notées ici pour ne pas être oubliées :

- Détection automatique des conditions de victoire (village / loups / solitaires).
- Minuteur de tour de parole pour les débats du village.
- Rappel des pouvoirs passifs au bon moment (Ancien, Idiot du village, Chevalier).
- Signature de release avec un keystore dédié (aujourd'hui la clé de debug).
- Sauvegarde chiffrée automatique après chaque nuit.

---

## 10. Plan de la version 2.0

La V2 corrige un bug bloquant (aucune détection de fin de partie) et refond le tour de
jeu en un parcours guidé : **nuit en cartes swipables → phase de jour → vote → victoire**.

### 10.1 Ordre de livraison

| # | Lot | Contenu | Migration |
|---|-----|---------|-----------|
| **V2-1** | 🐞 Détection de victoire | moteur de règles extensible, camp vainqueur persisté, écran de victoire, plus aucune action quand la partie est finie | `schemaVersion` 1 → 2 |
| **V2-2** | 🎲 Distribution aléatoire | table de correspondance loups/joueurs, rôles uniques, seuils par rôle | — |
| **V2-3** | ✅ Composition de partie | choix des rôles autorisés, réutilisé par le randomiseur et par « Nouvelle partie » | 2 → 3 |
| **V2-4** | ⭐ Capitaine | élection unique, vote double, mort → désignation ou réélection | — |
| **V2-5** | 🃏 Nuit en cartes | séquence ordonnée calculée, pile de cartes swipables, une carte par rôle actif | 3 → 4 |
| **V2-6** | ☀️ Phase de jour | réveil, élection, chronomètre, vote pondéré, conséquences | — |
| **V2-7** | 🏆 Victoire & rejouer | écran de victoire complet, « Nouvelle partie » avec les mêmes joueurs | — |

### 10.2 Nouvelles features (mêmes couches que `games` / `nights`)

```
lib/features/
├── victory/
│   ├── domain/  victory_entities.dart · victory_engine.dart (pur, extensible)
│   ├── data/    victory_recorder.dart  (écrit le camp vainqueur sur `games`)
│   └── presentation/ victory_screen.dart
└── day/
    ├── domain/  day_entities.dart · vote_resolver.dart (vote pondéré + égalité)
    └── presentation/ day_screen.dart + cartes du jour
```

### 10.3 Migrations prévues

- **v2** — `games.winnerCampId`, `games.winnerReason` (camp vainqueur mémorisé).
- **v3** — table `game_role_selections` (rôles autorisés pour une partie).
- **v4** — `night_actions.phase` (nuit/jour, pour résoudre les deux phases séparément),
  `nights.dayResolvedAt`, `nights.daySummaryJson`.

Chaque étape ajoute une branche dans `onUpgrade` ; aucune table n'est recréée, aucune
partie existante n'est perdue.
