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

