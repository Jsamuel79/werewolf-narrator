# 🐺 Werewolf Narrator

Application Flutter **100 % hors ligne** qui **guide** le narrateur d'une partie de
**Loup-Garou** tour après tour : elle appelle les rôles dans l'ordre, enregistre ce que
chacun fait, calcule les conséquences, mène le vote du village et annonce le vainqueur.

La nuit se joue en **cartes que l'on balaie** — une carte par rôle, dans l'ordre du
livret — et la journée enchaîne réveil, élection du Capitaine, chronomètre de débat et
vote.

Toutes les données restent sur le téléphone, dans une base **SQLite chiffrée en
AES-256 (SQLCipher)**.

---

## ✨ Ce que fait l'application

| | |
|---|---|
| 🏠 **Accueil** | Parties en cours et parties archivées, en un coup d'œil |
| 🎲 **Création** | Nommez la partie, installez les joueurs, distribuez les rôles |
| ✅ **Composition** | Choisissez les rôles autorisés dans cette partie ; la sélection est mémorisée pour la suivante |
| 🎰 **Distribution aléatoire** | Un bouton, et toute la table est servie : bon nombre de loups, rôles uniques, seuils par rôle. Redistribuable, et modifiable à la main |
| 🃏 **26 rôles** | Villageois, Voyante, Sorcière, Chasseur, Cupidon, Salvateur, Petite Fille, Voleur, Ancien, Renard, Corbeau, Loup-Garou Blanc, Joueur de Flûte, Ange… |
| 🌙 **Nuit en cartes** | Une carte plein écran par rôle vivant, dans l'ordre de réveil officiel. Balayez pour passer, revenez en arrière pour corriger |
| ☀️ **Phase de jour** | Réveil, élection du Capitaine, chronomètre de débat, vote du village, tir du Chasseur |
| ⭐ **Capitaine** | Élu une seule fois, sa voix compte double et tranche les égalités ; à sa mort, successeur désigné ou nouvelle élection |
| 💡 **Rappels** | Les pouvoirs passifs (Ancien, Chevalier, Idiot du Village, Bouc émissaire…) s'affichent sur la carte qui les pose |
| 💾 **Instantanés** | Sauvegarde chiffrée automatique après chaque tour, restaurable en un geste, sans mot de passe ni réseau |
| ⚖️ **Résolution automatique** | Protections, potions, cumul d'attaques, **cascade de chagrin** entre amoureux, infections |
| 🏆 **Fin de partie** | Détection automatique du vainqueur (Village, Loups, Amoureux mixtes, rôles solitaires) et écran de victoire, puis « rejouer avec les mêmes joueurs » |
| 📜 **Historique** | Chronologie complète : chaque tour, chaque action horodatée, chaque bilan |
| 🔐 **Export chiffré** | JSON protégé par mot de passe (AES-256-GCM), partageable |
| 📥 **Import** | Rechargez un export sur n'importe quel appareil |
| 🗄️ **Archivage** | Rangez les parties terminées sans les perdre |

---

## 🚀 Démarrage rapide

### Prérequis

- **Flutter 3.47** ou plus récent ([guide d'installation](https://docs.flutter.dev/get-started/install))
- Pour Android : un SDK Android avec la plateforme **android-36** et Java 17+
- Un appareil ou un émulateur Android / iOS

### Installation

```bash
git clone https://github.com/Jsamuel79/werewolf-narrator.git
cd werewolf-narrator

# Dépendances
flutter pub get

# Lancer l'application
flutter run
```

> ℹ️ Le code Drift généré (`lib/core/database/app_database.g.dart`) est versionné,
> le projet compile donc directement après un `flutter pub get`.
> Si vous **modifiez les tables** dans `lib/core/database/tables.dart`, régénérez-le :
>
> ```bash
> dart run build_runner build
> ```

### Tests et qualité

```bash
flutter analyze   # doit être vide
flutter test      # 307 tests
```

### Build APK

```bash
flutter build apk --release
```

L'APK est produit dans `build/app/outputs/flutter-apk/app-release.apk` (~72 Mo :
il contient les trois ABI et les binaires SQLCipher). Pour des APK plus légers,
d'environ 24 Mo chacun :

```bash
flutter build apk --release --split-per-abi
```

> ⚠️ Le build de release utilise pour l'instant la **clé de signature de debug**
> (configuration par défaut de `flutter create`). Pour publier sur le Play Store,
> créez un keystore et remplissez `signingConfigs.release` dans
> [`android/app/build.gradle.kts`](android/app/build.gradle.kts).

---

## 🛠️ Stack technique

| Composant | Technologie |
|-----------|-------------|
| Framework | Flutter 3.47.3 / Dart 3.13.3 |
| État & injection | Riverpod 3 |
| Base de données | Drift (SQLite typé) |
| Chiffrement de la base | SQLCipher AES-256, via `source: sqlcipher` de `package:sqlite3` |
| Stockage de la clé | `flutter_secure_storage` (Keystore / Keychain) |
| Export chiffré | `encrypt` (AES-GCM) + `pointycastle` (PBKDF2) |
| Partage / import | `share_plus`, `file_picker` |
| Cartes balayables & chronomètre | SDK Flutter seul (`GestureDetector`, `Transform`, `Timer`, `HapticFeedback`) |
| Tests | `flutter_test`, `mocktail`, base Drift en mémoire |

---

## 📁 Structure du projet

```
lib/
├── main.dart              # bootstrap : clé → base chiffrée → ProviderScope
├── app.dart               # MaterialApp, thème, locale française
├── core/                  # base de données, sécurité, thème, utilitaires
└── features/
    ├── games/             # parties, joueurs, rôles, composition, distribution
    ├── nights/            # nuit en cartes, actions, moteur de résolution
    ├── day/               # réveil, capitaine, débat, vote, juge bègue, servante
    ├── victory/           # règles de fin de partie et écran de victoire
    ├── history/           # chronologie d'une partie
    └── export/            # export / import chiffré
```

Chaque feature est découpée en `domain` (métier pur), `data` (accès aux
données) et `presentation` (écrans et contrôleurs). Le détail complet — schéma
de base, décisions d'architecture, flux de données — est dans
[`.claude/ARCHITECTURE.md`](.claude/ARCHITECTURE.md).

---

## 🔐 Sécurité

- **Base chiffrée** : SQLCipher AES-256. Le fichier `.db` est illisible en
  dehors de l'application — un test relit le fichier brut pour le vérifier.
- **Clé** : 32 octets tirés de `Random.secure()` au premier lancement, stockés
  uniquement dans le Keystore Android / le Keychain iOS. Jamais en dur dans le
  code, jamais versionnée.
- **Zéro réseau** : la permission `INTERNET` n'est **pas** déclarée dans le
  manifeste de release, et aucun paquet utilisé n'appelle le réseau. Un test
  automatisé épingle la liste des paquets embarqués : en ajouter un demande de
  mettre ce test à jour, et donc de justifier le paquet.
- **Export** : AES-256-GCM, clé dérivée du mot de passe par PBKDF2-HMAC-SHA256
  (150 000 itérations, sel et nonce aléatoires). Aucun export en clair n'est
  possible ; un mauvais mot de passe est rejeté au lieu de produire n'importe
  quoi.
- **Journaux** : aucune clé ni aucun mot de passe n'apparaît dans les messages
  d'erreur.

> ⚠️ Si la clé du Keystore est perdue (désinstallation de l'application,
> réinitialisation de l'appareil), les parties existantes deviennent
> **définitivement illisibles**. Exportez les parties auxquelles vous tenez.

---

## 📚 Documentation

| Fichier | Contenu |
|---------|---------|
| [`.claude/ARCHITECTURE.md`](.claude/ARCHITECTURE.md) | Architecture, schéma de base, décisions techniques, roadmap |
| [`CHANGELOG.md`](CHANGELOG.md) | Historique des versions |
| [`SETUP_LOG.md`](SETUP_LOG.md) | Journal d'installation et des problèmes résolus pendant le build |

---

## 📝 Licence

MIT — utilisez, modifiez, distribuez comme vous voulez.

---

**Développé par Jsamuel79**
