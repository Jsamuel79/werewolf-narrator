# 🐺 Werewolf Narrator

Application Flutter **offline-first** pour aider le narrateur de Loup-Garou à suivre les rôles, actions de nuit, couples, et historique des parties.

## ✨ Fonctionnalité

- ✅ **100% offline** — fonctionne sans Wi-Fi
- ✅ **Chiffrement SQLCipher** (AES-256) — données sécur localement
- ✅ **Gestion des parties** — crée, archive, exporte tes parties
- ✅ **Suivi des rôles** — note qui a quel rôle
- ✅ **Actions de nuit** — enregistre chaque action (tue, sauve, visite, couple, etc.)
- ✅ **Historique complet** — consulte toutes les nuits d'une partie
- ✅ **Export JSON chiffré** — sauvegarde et partage tes parties

## 🛠️ Stack technique

| Composant | Technologie |
|-----------|-------------|
| Framework | Flutter 3.x |
| Langage | Dart |
| Base de données | Drift (SQLite) |
| Chiffrement | SQLCipher (AES-256) |
| Gestion des clés | flutter_secure_storage (Keychain/Keystore) |
| State management | Riverpod (optionnel) |

## 📁 Architecture du projet

```
lib/
├── main.dart                 # Point d'entré, setup SQLCipher
├── database/
│   ├── database.dart         # Configuration Drift + SQLCipher
│   ├── schema.dart           # Sché·µ de la base (tables)
│   └── migrations.dart       # Migrations de schéma
├── models/                   # Modèle Dart (Player, Night, Action, Couple)
├── services/
│   ├── security_service.dart # Gestion des clés de chiffrement
│   └── export_service.dart   # Export JSON chiffré
├── screens/                  # Écrans de l'app
│   ├── home_screen.dart      # Liste des parties
│   ├── game_screen.dart      # Détail d'une partie
│   ├── night_screen.dart     # Saisie des actions de nuit
│   └── export_screen.dart    # Export/sauvegarde
└── widgets/                  # Composants réutilisables
```

## 🚀 Démarrage rapide

### Prérequis

- Flutter SDK 3.x installé ([guide d'installation](https://docs.flutter.dev/get-started/install))
- Un émulateur ou un appareil physique (Android/iOS)

### Installation

```bash
# Cloner le repo
git clone https://github.com/Jsamuel79/werewolf-narrator.git
cd werewolf-narrator

# Installer les dépendances
flutter pub get

# Lancer l'app (détecte l' appareil/émulateur)
flutter run
```

### Build APK (Android)

```bash
flutter build apk --release
```

L'APK sera génré·¢ dans `build/app/outputs/flutter-apk/app-release.apk`.

## 🔐 Sécurité

- **Base de données chiffré·¢** avec SQLCipher (AES-256)
- **Clé·µ stocké·¢** dans le Keychain (iOS) / EncryptedSharedPreferences (Android)
- **Aucune donnée envoyé** au réseau (100% local)
- **Export optionnel** en JSON chiffré (mot de passe)

## 📊 Schéma de la base de données

### Tables principales

#### `players`
- `id` (TEXT, UUID)
- `name` (TEXT)
- `role` (TEXT)
- `isAlive` (BOOLEAN)
- `isCoupledWith` (TEXT, nullable, référence player.id)
- `notes` (TEXT)

#### `nights`
- `id` (TEXT, UUID)
- `gameId` (TEXT, référence games.id)
- `nightNumber` (INTEGER)
- `createdAt` (DATETIME)

#### `actions`
- `id` (TEXT, UUID)
- `nightId` (TEXT, référence nights.id)
- `type` (TEXT: kill, save, visit, couple, reveal, etc.)
- `fromPlayerId` (TEXT, nullable, référence players.id)
- `toPlayerId` (TEXT, nullable, référence players.id)
- `details` (TEXT, JSON)

#### `games`
- `id` (TEXT, UUID)
- `name` (TEXT)
- `createdAt` (DATETIME)
- `isArchived` (BOOLEAN)

## 🧪 Développeur

### Ajouter une migration

```dart
// database/migrations.dart
@DriftDatabase(tables: [...])
class AppDatabase extends _$AppDatabase {
  @override
  int get schemaVersion => 2; // Incrémenter à chaque migration

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // Ajouter nouvelle colonne/table
        }
      },
    );
  }
}
```

### Ressources utiles

- [Drift documentation](https://drift.simonbinder.eu/)
- [SQLCipher dans Flutter](https://asoasis.tech/articles/2026-07-18-0854-flutter-sqlcipher-encrypted-database/)
- [Flutter secure storage](https://pub.dev/packages/flutter_secure_storage)

## 📝 Licence

MIT — utilise, modifie, distribue comme tu veux !

## 🤝 Contribution

Les PR sont les bienvenues ! Ouvre une issue pour discuter des features avant de coder.

---

**Développé par Jsamuel79**
