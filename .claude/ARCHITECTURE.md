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

## 3. Schéma de base de données (Drift, `schemaVersion = 1`)

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

Les clés étrangères sont activées via `PRAGMA foreign_keys = ON`.

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
