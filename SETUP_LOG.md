# 🔧 SETUP LOG — Werewolf Narrator

Journal chronologique des installations, décisions techniques et résolutions de
problèmes rencontrées pendant la construction du projet.

---

## 2026-09-10 — Session de build initiale

### État initial de la machine

| Élément | État |
|---------|------|
| `flutter` | ❌ absent |
| `dart` | ❌ absent |
| `git`, `curl`, `unzip`, `xz` | ✅ présents |
| `java` | ✅ OpenJDK 21.0.12 |
| Android SDK | ✅ présent (`~/Android/Sdk`) |
| `libsqlite3.so` | ✅ présent (`/lib/x86_64-linux-gnu/`) — requis pour `flutter test` sur Linux |
| `ninja`, `clang`, `cmake`, `pkg-config` | ✅ présents |
| Espace disque | ✅ 149 Go libres |

### Installation du SDK Flutter

Flutter n'était pas installé sur la machine. Installation manuelle depuis l'archive
officielle (pas de snap, pour éviter les problèmes de confinement avec le SDK Android) :

```bash
mkdir -p ~/development && cd ~/development
curl -L -o flutter.tar.xz \
  "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.47.3-stable.tar.xz"
tar xf flutter.tar.xz
export PATH="$HOME/development/flutter/bin:$PATH"
```

- **Version installée** : Flutter **3.47.3** (stable) / Dart **3.13.3**
- **Emplacement** : `~/development/flutter`

> ⚠️ Le `PATH` n'a pas été modifié de façon permanente dans le profil de l'utilisateur.
> Pour utiliser Flutter dans un nouveau terminal :
> ```bash
> # bash / zsh
> export PATH="$HOME/development/flutter/bin:$PATH"
> # fish (shell par défaut de cette machine)
> fish_add_path ~/development/flutter/bin
> ```

### Scaffold du projet

```bash
flutter create . --project-name werewolf_narrator --org com.jsamuel --platforms=android,ios \
  --description "Assistant de narration hors-ligne pour le jeu Loup-Garou"
```

Plateformes générées : **Android** et **iOS** uniquement (pas de web/desktop — l'app est
pensée pour un téléphone posé à côté du narrateur, et le web serait incompatible avec
l'exigence de chiffrement local par Keystore).

Les fichiers `lib/main.dart` et `test/widget_test.dart` générés par défaut ont été
supprimés/remplacés par le vrai code de l'application.

### ⚠️ Problème n°1 — `sqlcipher_flutter_libs` est déprécié

Le brief impose SQLCipher. `flutter pub add sqlcipher_flutter_libs` a installé la version
`0.7.0+eol`, dont le README indique :

> This package relates to version 2.x of `package:sqlite3`, and is obsolete after upgrading.
> Starting from version `0.7.0`, this package no longer does anything.

De plus, faire cohabiter `sqlite3_flutter_libs` et `sqlcipher_flutter_libs` provoque un
conflit de symboles natifs (deux copies de SQLite dans le même binaire).

**Résolution** — Depuis `package:sqlite3` 3.x, le build natif se sélectionne via les
[hooks Dart](https://dart.dev/tools/hooks). Les deux paquets `*_flutter_libs` ont été
retirés et remplacés par une déclaration dans `pubspec.yaml` :

```yaml
hooks:
  user_defines:
    sqlite3:
      source: sqlcipher   # build SQLCipher community edition (AES-256)
```

**Vérification** — un test de fumée a confirmé que le binaire chargé est bien SQLCipher et
que le fichier produit est illisible en clair :

```
sqlite version: 3.53.4
header = "PP@5ã C(ýÝS3z"      ← et non "SQLite format 3"
```

Ce test a été conservé sous `test/core/database/database_encryption_test.dart`.

Avantage inattendu : SQLCipher est aussi disponible sous `flutter test` sur Linux, ce qui
permet de tester **réellement** le chiffrement au repos, et pas seulement de le supposer.

### Dépendances retenues

| Paquet | Version | Rôle |
|--------|---------|------|
| `flutter_riverpod` | 3.4.3 | état + injection de dépendances |
| `drift` / `drift_dev` | 2.35.0 | ORM SQLite typé |
| `sqlite3` | 3.5.2 | binaire SQLCipher (via hooks) |
| `flutter_secure_storage` | 11.0.0 | Keystore / Keychain |
| `encrypt` + `pointycastle` | 5.0.3 / 3.9.1 | AES-GCM + PBKDF2 pour l'export |
| `crypto` | 3.0.7 | SHA-256 (empreinte d'export) |
| `share_plus` | 13.3.0 | partage du fichier exporté |
| `file_picker` | 12.2.0 | sélection d'un fichier à importer |
| `uuid` | 4.6.0 | identifiants v4 |
| `path_provider` / `path` | 2.1.6 / 1.9.1 | chemins de stockage |
| `intl` | 0.20.3 | formatage des dates en français |
| `mocktail` | 1.0.5 | doubles de test |

### Télémétrie désactivée

```bash
flutter config --no-analytics
dart --disable-analytics
```

### ⚠️ Problème n°2 — `A Timer is still pending` dans les tests de widgets

Les écrans lisent la base via des `StreamProvider` alimentés par les `watch()` de Drift.
Quand Riverpod détruit le `ProviderScope` en fin de test, Drift annule la souscription et
planifie un `Timer.run(...)` (`StreamQueryStore.markAsClosed`). Le framework de test
détruisait l'arbre *après* le corps du test et échouait aussitôt sur l'invariant
« A Timer is still pending even after the widget tree was disposed », puis le process
`flutter test` restait bloqué (timeout de plusieurs minutes).

**Résolution** — chaque test de widget démonte l'arbre *à l'intérieur* du corps du test,
puis laisse le timer se déclencher :

```dart
Future<void> disposeTree(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();   // pump() seul n'écoule pas le timer à durée nulle
}
```

À noter : `await tester.pump()` ne suffit pas — `pump(Duration.zero)` n'avance pas
l'horloge simulée, donc le timer à durée nulle n'est jamais exécuté. `pumpAndSettle()`
avance par pas de 100 ms et le déclenche.

### ⚠️ Problème n°3 — `find.text` ne voit pas le texte d'un `RichText`

L'historique affiche chaque action dans un `RichText` (libellé + détail dans un
style plus discret). `find.text('Vision de la Voyante')` ne trouvait rien, et
`find.text(..., findRichText: true)` non plus : ce finder exige que **tout** le
texte du `RichText` corresponde, or il contient aussi les cibles et le détail.

**Résolution** — utiliser `find.textContaining(..., findRichText: true)`.

### ⚠️ Problème n°4 — un `const` qui ne l'est pas

`const key = 'ff' * 32;` ne compile pas : l'opérateur `*` sur une `String` n'est
pas évaluable à la compilation en Dart. Remplacé par `final`.

### ⚠️ Problème n°5 — `StreamProviderFamily` n'existe plus

Riverpod 3 a supprimé les classes de famille exportées publiquement
(`StreamProviderFamily`, `AutoDisposeStreamProviderFamily`, …). Annoter
explicitement le type d'un `StreamProvider.family` échoue donc à l'analyse.

**Résolution** — laisser l'inférence faire son travail :

```dart
final gameSnapshotProvider =
    StreamProvider.family<GameSnapshot?, String>((ref, gameId) {
      return ref.watch(gamesRepositoryProvider).watchGame(gameId);
    }, isAutoDispose: true);
```

À noter aussi : en Riverpod 3, `Provider.autoDispose` cède la place au paramètre
`isAutoDispose: true`.

### 🔐 Choix de conception sur l'export chiffré

Le brief impose AES-GCM via `package:encrypt`. Un mot de passe utilisateur ne
pouvant pas servir directement de clé AES-256, il est étiré par **PBKDF2-HMAC-SHA256**
(`pointycastle`), avec un sel aléatoire de 16 octets et 150 000 itérations.

Mesure du coût sur cette machine : **~480 ms pour le chiffrement, ~510 ms pour le
déchiffrement**. C'est volontairement lent (c'est le but d'une KDF) ; l'interface
affiche donc un indicateur de progression bloquant pendant l'opération.

Détail important : l'en-tête de l'enveloppe (version, algorithme de KDF, nombre
d'itérations, sel, nonce) est passé en **AAD** au chiffrement GCM. Sans cela, un
fichier pourrait être réécrit avec `iterations: 1` sans invalider le tag
d'authentification. L'AAD est reconstruit champ par champ plutôt que depuis le
texte JSON, pour qu'un simple reformatage du fichier ne casse pas un import
légitime.

### 📴 Vérification « zéro réseau »

`flutter create` place la permission `INTERNET` dans les manifestes **debug** et
**profile** uniquement (le tooling Flutter en a besoin pour le hot reload). Le
manifeste `main`, celui qui part en release, ne la déclare pas — un commentaire
l'explique désormais explicitement, et
`test/security/offline_guarantee_test.dart` vérifie automatiquement :

1. que le manifeste de release ne contient pas `android.permission.INTERNET` ;
2. que les manifestes debug/profile la contiennent bien (séparation intacte) ;
3. qu'aucun fichier de `lib/` n'ouvre de socket ni de client HTTP.

---

## Build de l'APK de release

### ⚠️ Problème n°6 — `Failed to find target with hash string 'android-37'`

Premier `flutter build apk --release` : Gradle installe tout seul les plateformes
Android 36 puis « 37.0 », puis échoue :

```
Could not determine the dependencies of task
':flutter_secure_storage:compileReleaseJavaWithJavac'.
> Failed to find target with hash string 'android-37' in: ~/Android/Sdk
```

**Cause** — `flutter_secure_storage` **11.0.0** compile contre le SDK Android 37.
Deux problèmes se cumulent :

1. Le SDK manager installe cette plateforme sous le nom `android-37.0`, alors que
   Gradle la cherche sous `android-37`.
2. L'Android Gradle Plugin fourni par le template Flutter 3.47 est le **9.1.0**,
   dont le message d'erreur indique lui-même que « la version maximale
   recommandée de compile SDK est 36 ».

**Tentative intermédiaire (abandonnée)** — forcer `compileSdk = 36` sur tous les
sous-projets Android depuis `android/build.gradle.kts`. La compilation passait,
mais la vérification des métadonnées AAR échouait ensuite :
`Dependency ':flutter_secure_storage' requires ... version 37 or later`.
Cette rustine a été retirée : elle masquait le problème au lieu de le résoudre,
et aurait produit des erreurs incompréhensibles pour toute future dépendance
réclamant légitimement un SDK plus récent.

**Résolution retenue** — épingler `flutter_secure_storage: ^10.3.2`, dernière
version compilant contre le SDK 36, avec un commentaire dans `pubspec.yaml`
expliquant pourquoi. L'API utilisée par l'application est identique.

Bénéfice annexe : en 10.3.2, le constructeur `AndroidOptions()` par défaut
utilise déjà AES-GCM avec enveloppement de clé RSA-OAEP dans le KeyStore
(`encryptedSharedPreferences` y est déprécié). Les options iOS ont été précisées
au passage : `first_unlock_this_device` + `synchronizable: false`, pour que la
clé de la base ne parte jamais dans le trousseau iCloud.

### ✅ Résultat

```
✓ Built build/app/outputs/flutter-apk/app-release.apk (71.8MB)
```

Vérifications faites sur l'APK produit avec `aapt2` et `unzip` :

| Vérification | Résultat |
|---|---|
| Permissions déclarées | `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` uniquement — **pas d'`INTERNET`** |
| `libsqlcipher.so` embarqué | ✅ pour `arm64-v8a`, `armeabi-v7a` et `x86_64` |
| Taille | 71,8 Mo — c'est un APK « gras » contenant les 3 ABI |

L'APK est signé avec la **clé de debug** (configuration par défaut de
`flutter create`). C'est suffisant pour installer l'application sur son propre
téléphone, mais il faudra un keystore dédié pour une publication.

> 💡 `flutter build apk --split-per-abi` produit trois APK d'environ 24 Mo au
> lieu d'un seul de 72 Mo, si la taille compte.

---

## 2026-09-10 — Session V2

### Choix technique — la pile de cartes de la nuit, sans package

Le besoin : une pile de cartes plein écran, balayables, avec la carte suivante qui
dépasse derrière la carte courante, et des boutons « Précédent » / « Passer » comme
solution de repli accessible.

Options examinées :

| Option | Verdict |
|--------|---------|
| `PageView` du SDK | Gratuit et accessible, mais ne sait pas faire dépasser la carte suivante derrière la carte courante ; l'effet « pile » est perdu. |
| `flutter_card_swiper` (package) | Fait le travail, mais ajoute une dépendance transitive à auditer alors que le projet garantit qu'**aucun** paquet ne touche au réseau, et le test `offline_guarantee_test.dart` devrait être étendu à ses transitives. |
| Implémentation maison | ~150 lignes : `GestureDetector` pour le drag, `Transform.translate` + `Transform.rotate` pour la carte du dessus, `Transform.scale` + `Opacity` pour celle de derrière, un `AnimationController` pour l'envol et le retour élastique. |

**Retenu : implémentation maison** (`lib/core/widgets/swipe_card_stack.dart`).
Aucune dépendance ajoutée à `pubspec.yaml` pendant toute la V2 — la promesse « zéro
réseau » reste vérifiable en lisant la liste des paquets, et le widget est contrôlé
(l'index appartient à l'écran), donc testable par des tests de widgets classiques.

### Choix technique — le chronomètre de débat, sans package

`Timer.periodic` du SDK pour le décompte, `HapticFeedback.vibrate()` et
`SystemSound.play(SystemSoundType.alert)` de `package:flutter/services.dart` pour la fin
du temps imparti. Aucun paquet audio n'est nécessaire, donc aucune permission
supplémentaire dans le manifeste Android.

### Choix technique — pas de `DayResolver` séparé

La phase de jour aurait pu recevoir son propre moteur. Elle applique pourtant exactement
les mêmes conséquences que la nuit : protections, cumul d'attaques, cascade de chagrin
entre amoureux, changements de rôle, écharpe du Capitaine. Un second moteur aurait
dupliqué ces règles, avec la garantie qu'elles finiraient par diverger.

**Retenu** : `NightResolver` est appelé **deux fois par tour**, filtré par la nouvelle
colonne `night_actions.phase`. Une seule description des règles, deux moments
d'application (`resolveNight` / `resolveDay`).

### ⚠️ Problème n°4 — la V1 rendait les vieux tours incomplets

Découper un tour en deux moitiés (`resolvedAt` pour la nuit, `dayResolvedAt` pour le
jour) casse les parties existantes : un tour clos par la 1.0.0 n'a pas de
`dayResolvedAt`, il serait donc lu comme « en attente de sa journée », et
`startNight` renverrait éternellement le même tour au lieu d'en ouvrir un nouveau.

**Résolution** — la migration v4 recopie la valeur :

```sql
UPDATE nights SET day_resolved_at = resolved_at WHERE resolved_at IS NOT NULL
```

C'est sémantiquement exact : en 1.0.0, un tour couvrait déjà la nuit **et** le vote du
lendemain (décision D2). Un test reconstruit une base au format 1.0.0 avec `sqlite3`
directement, l'ouvre avec le schéma courant, et vérifie que la partie, ses joueurs, ses
tours et leurs actions ont survécu.

### ⚠️ Problème n°5 — tests de widgets et cartes plus hautes que l'écran

Les cartes de nuit et de jour dépassent la surface de test (600 × 800) : `tester.tap()`
échouait avec « would not hit test on the specified widget » sur les boutons du bas.

**Résolution** — un helper `tapVisible()` dans les tests, qui appelle
`tester.ensureVisible(finder)` avant de taper. Le contenu de chaque carte est déjà dans
un `SingleChildScrollView`, donc le comportement réel sur téléphone est correct ; c'est
uniquement la taille de la surface de test qui demandait ce détour.

À noter aussi : la pile dessine la **carte suivante derrière** la carte courante, si bien
qu'un `find.widgetWithText(...)` peut trouver deux occurrences. Les tests visent alors
`.last` — la carte du dessus — avec un commentaire qui l'explique.

### État de fin de session V2

| Vérification | Résultat |
|--------------|----------|
| `flutter analyze` | ✅ aucun problème |
| `flutter test` | ✅ 245 tests verts |
| `flutter build apk --release` | ✅ `app-release.apk`, 72,4 Mo |
| Dépendances ajoutées | ✅ **aucune** — tout est bâti sur le SDK |
| Migrations | ✅ 1 → 2 → 3 → 4, par ajout uniquement, testées sur une base 1.0.0 |

Aucun blocage technique n'a nécessité de contournement pendant cette session.

---

## 2026-09-11 — Session V2.1

### ⚠️ Problème n°6 — un flux Drift ne surveille que les tables de sa requête

Les deux bugs remontés du terrain (potion de vie grisée, bilan du jour vide) avaient une
seule cause. `watchNight` était écrit ainsi :

```dart
_db.select(_db.nights).watchSingleOrNull().asyncMap((row) async => NightDetail(
      night: row.toEntity(),
      actions: await _actionsOf(nightId),   // ← requête séparée
    ));
```

Drift construit le flux à partir des tables que **la requête** lit — ici `nights` seule.
Les actions chargées dans l'`asyncMap` n'y participent pas : insérer dans `night_actions`
ne réveillait donc jamais le flux. L'écran gardait la liste d'actions telle qu'elle était
à son ouverture.

**Résolution** — une requête jointe, qui fait dépendre le flux des deux tables :

```dart
_db.select(_db.nights).join([
  leftOuterJoin(_db.nightActions,
      _db.nightActions.nightId.equalsExp(_db.nights.id)),
])
```

**Leçon retenue** : dans Drift, tout ce qui doit rafraîchir un écran doit être **dans** la
requête. Un `asyncMap`, un `Future` annexe ou un `await` dans un provider ne créent aucune
dépendance.

### ⚠️ Problème n°7 — `.future` d'un provider rend l'état déjà chargé

Après `resolveDay`, l'écran demandait `ref.read(gameSnapshotProvider(id).future)` pour
savoir si la partie était finie. Quand le provider détient déjà une valeur, ce futur se
complète **immédiatement avec cette valeur** — celle d'avant la transaction. Le vote qui
lynchait le dernier loup revenait donc à l'écran de partie au lieu d'ouvrir l'écran de
victoire.

**Résolution** — relire le plateau depuis le repository après l'écriture attendue.
Un provider observé sert à *afficher*, pas à *décider* juste après avoir écrit.

### ⚠️ Problème n°8 — les entrées/sorties réelles ne s'exécutent pas dans un test de widget

L'écran des instantanés lit de vrais fichiers via un `FutureProvider`. Testé avec
`testWidgets` + `pumpAndSettle`, le test **ne se terminait jamais** : le corps d'un test de
widget tourne dans une zone où les futurs de `dart:io` ne sont pas pompés, et le
`CircularProgressIndicator` de l'état « chargement » est une animation infinie que
`pumpAndSettle` attend indéfiniment.

**Résolution** — deux niveaux de test, chacun à sa place :

- `auto_backup_service_test.dart` (test unitaire classique) exerce les vrais fichiers :
  écriture, relecture, rotation, restauration, clé étrangère, fichier altéré ;
- `backups_screen_test.dart` injecte la liste via un override de `gameBackupsProvider` et
  ne touche jamais au disque.

Même piège pour `pumpAndSettle` après une navigation vers un écran qui affiche un
indicateur de progression : pomper à la main (`pump(Duration)`) ou ne pas naviguer.

### État de fin de session V2.1

| Vérification | Résultat |
|--------------|----------|
| `flutter analyze` | ✅ aucun problème |
| `flutter test` | ✅ 307 tests verts |
| `flutter build apk --release` | ✅ `app-release.apk` |
| Dépendances ajoutées | ✅ **aucune** (toujours 16 paquets, liste épinglée par le test hors-ligne) |
| Migrations | ✅ aucune nouvelle : la V2.1 ne touche pas au schéma |

---

## Session V2.2 — cinq remontées du terrain

### ⚠️ Problème n°9 — un bug de règle peut être un bug d'**ordre**, pas de code manquant

Le moteur de victoire connaissait déjà la condition du Joueur de Flûte, et cinq des six
tests écrits pour la reproduire passaient **du premier coup**. Un seul échouait : celui où
le Flûtiste avait charmé sa propre amoureuse, parce que la règle des Amoureux était
évaluée avant la sienne et rendait son verdict en premier.

**Leçon retenue** : dans un moteur à liste de règles ordonnée, écrire la règle ne suffit
pas — sa **place** est la moitié de la règle. Et écrire les tests avant de lire le code a
payé : ils ont montré du même coup ce qui manquait vraiment (la priorité, le partage de
la victoire avec l'amoureux) et ce qui était déjà juste, ce qu'une lecture du code aurait
confirmé trop vite.

### ⚠️ Problème n°10 — un filtre d'affichage peut rendre une action impossible à valider

Retirer les joueurs déjà charmés de la carte du Flûtiste a immédiatement cassé un test de
bout en bout : l'action exige deux cibles, et la dernière nuit utile n'en propose souvent
plus qu'une. La correction d'un bug d'ergonomie avait créé une impasse de règle.

**Leçon retenue** : quand on réduit l'ensemble des choix possibles, vérifier ce que
deviennent les contraintes de **validité** qui portaient sur cet ensemble. Ici, le drapeau
`secondaryTargetOptional` est porté par l'action du catalogue, pas par un `if` sur son
identifiant : Cupidon continue d'exiger ses deux amoureux sans le savoir.

### ⚠️ Problème n°11 — deux listes de choix identiques dans la même carte

Sur une carte à deux cibles, `find.widgetWithText(ChoiceChip, 'Chloé').last` visait la
**seconde** liste, jamais la première : les deux affichent les mêmes noms, et la pile
dessine en plus la carte suivante derrière la carte courante. Le test tapait donc deux
fois dans la même liste et le bouton « Valider » restait grisé, sans que rien ne le dise.

**Résolution** — une `ValueKey` sur chacune des deux listes (`primary-targets`,
`secondary-targets`), et un `find.descendant` dans le test. Un `.last` reste nécessaire
par-dessus, pour la carte du dessus de la pile.

### ⚠️ Problème n°12 — le plafond que le narrateur décrivait n'existait pas dans le code

L'utilisateur décrivait une « limite maximale » sur la saisie des voix. Recherche faite,
aucune constante, aucun `clamp`, aucune borne : la seule limite était le compteur `+`/`-`
lui-même, qui demandait quarante appuis pour quarante voix. Le symptôme était réel, la
cause supposée ne l'était pas.

**Leçon retenue** : vérifier la cause avant de « retirer » quelque chose qui n'existe pas.
Le correctif utile n'était pas de relever une borne mais de changer le mode de saisie —
et de documenter (D45) qu'il n'y a **volontairement** aucune borne haute.

### État de fin de session V2.2

| Vérification | Résultat |
|--------------|----------|
| `flutter analyze` | ✅ aucun problème |
| `flutter test` | ✅ 351 tests verts |
| `flutter build apk --release` | ✅ `app-release.apk` |
| Dépendances ajoutées | ✅ **aucune** (toujours 16 paquets) |
| Migrations | ✅ aucune : `isCharmed` existait depuis la v1 |
| Format d'export | ✅ inchangé, compatible avec les exports 2.0 et 2.1 |
