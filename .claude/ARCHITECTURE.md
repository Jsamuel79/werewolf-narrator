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
├── main.dart                        # bootstrap : secure storage → clé → DB → ProviderScope
├── app.dart                         # MaterialApp, thème, routes nommées
│
├── core/                            # transverse à toutes les features
│   ├── database/
│   │   ├── app_database.dart        # @DriftDatabase, migrations, DAOs
│   │   ├── tables.dart              # définition des 4 tables
│   │   └── database_opener.dart     # ouverture SQLCipher (PRAGMA key) + fallback
│   ├── security/
│   │   ├── key_store.dart           # génération/lecture de la clé DB (secure storage)
│   │   └── crypto_service.dart      # AES-GCM + PBKDF2 pour l'export/import
│   ├── providers/
│   │   └── core_providers.dart      # providers racine (database, uuid, services)
│   ├── errors/
│   │   └── app_exception.dart       # hiérarchie d'exceptions métier
│   ├── theme/
│   │   └── app_theme.dart           # Material 3, thème sombre « nuit »
│   └── utils/
│       └── formatters.dart          # dates FR, pluriels
│
└── features/
    ├── games/                       # parties, joueurs, rôles
    │   ├── domain/
    │   │   ├── role.dart            # catalogue extensible de rôles
    │   │   ├── game_entities.dart   # Game, Player, GameSnapshot (entités pures)
    │   │   └── games_repository.dart
    │   ├── data/
    │   │   └── games_repository_impl.dart
    │   └── presentation/
    │       ├── home_screen.dart
    │       ├── game_setup_screen.dart
    │       ├── game_detail_screen.dart
    │       ├── controllers/…
    │       └── widgets/…
    │
    ├── nights/                      # nuits, actions, résolution
    │   ├── domain/
    │   │   ├── night_action_type.dart   # catalogue des types d'action
    │   │   ├── night_entities.dart      # Night, NightAction, NightOutcome
    │   │   ├── night_resolver.dart      # ⚙️ moteur de résolution (pur, testable)
    │   │   └── nights_repository.dart
    │   ├── data/
    │   │   └── nights_repository_impl.dart
    │   └── presentation/
    │       ├── night_screen.dart
    │       ├── controllers/…
    │       └── widgets/…
    │
    ├── history/
    │   └── presentation/history_screen.dart
    │
    └── export/
        ├── domain/game_archive.dart     # DTO sérialisable d'une partie complète
        ├── data/export_service.dart     # build JSON → chiffrer → fichier → share
        └── presentation/export_dialog.dart, import_dialog.dart
```

**Règle de dépendance** : `presentation → domain ← data`.
La couche `domain` ne dépend ni de Flutter ni de Drift (sauf les entités mappées),
ce qui rend le moteur de résolution des nuits testable en pur Dart.

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
| **D8** | Les tests utilisent `NativeDatabase.memory()` (SQLite standard, non chiffré) | SQLCipher n'est pas disponible sur la VM Dart de test ; le chiffrement est une propriété de l'**ouverture** du fichier, orthogonale à la logique testée. |

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

- [ ] **E0 — Setup** : SDK Flutter, scaffold du projet, dépendances, CI locale (analyze+test)
- [ ] **E1 — Noyau sécurité & DB** : `KeyStore`, ouverture SQLCipher, tables Drift, DAOs
- [ ] **E2 — Catalogue de rôles** : `RoleDefinition` + liste extensible
- [ ] **E3 — Feature games** : repository, providers, écran d'accueil (actives/archivées)
- [ ] **E4 — Création de partie** : nom → joueurs → assignation des rôles
- [ ] **E5 — Détail de partie** : vue joueurs, statut, couples, actions rapides
- [ ] **E6 — Feature nights** : moteur de résolution + repository + persistance
- [ ] **E7 — Écran nuit** : formulaire dynamique selon rôles vivants + résumé de fin
- [ ] **E8 — Historique** : chronologie complète d'une partie
- [ ] **E9 — Export chiffré** : JSON → AES-GCM → partage
- [ ] **E10 — Import chiffré** : lecture d'un export + restauration
- [ ] **E11 — Archivage / suppression** de partie
- [ ] **E12 — Finalisation** : `flutter analyze` clean, tests verts, build APK release, docs
