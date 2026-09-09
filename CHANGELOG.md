# 📓 Changelog

Toutes les évolutions notables du projet, de la plus récente à la plus ancienne.
Format inspiré de [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/).

## [1.0.0] — 2026-09-10

Première version complète du MVP : l'application est utilisable de bout en bout
pour narrer une partie de Loup-Garou hors ligne.

### Ajouté

#### Socle technique
- Projet Flutter 3.47.3 (Android + iOS), architecture feature-first en couches
  `data` / `domain` / `presentation`, injection de dépendances par Riverpod.
- Base de données **Drift/SQLite chiffrée par SQLCipher (AES-256)** : 4 tables
  (`games`, `players`, `nights`, `night_actions`) avec suppressions en cascade.
- Clé de chiffrement de 256 bits générée aléatoirement au premier lancement et
  conservée uniquement dans le Keystore Android / Keychain iOS.
- Thème sombre Material 3, pensé pour une table peu éclairée.

#### Parties et joueurs
- Écran d'accueil listant les parties en cours et les parties archivées.
- Création d'une partie : nom, ajout des joueurs, réorganisation des places,
  attribution d'un rôle à chacun depuis un catalogue de **26 rôles**.
- Suggestion du nombre de loups adapté à la taille de la table.
- Écran de partie : synthèse du plateau (vivants, camps, morts), couples en
  cours, et retouches manuelles par joueur (mort/vivant, rôle, capitaine,
  rupture de couple, retrait).
- Renommer, archiver, désarchiver et supprimer une partie.

#### Nuits
- Ouverture d'un tour, saisie horodatée des actions, fermeture du tour.
- Formulaire dynamique : seules les actions des rôles **encore en vie** sont
  proposées ; les actions de première nuit et les pouvoirs à usage unique
  disparaissent une fois consommés.
- **21 types d'actions** : dévoration, potions de la Sorcière, vision de la
  Voyante, protection du Salvateur, couple de Cupidon, charme du Joueur de
  Flûte, infection, vote du village, élection du Capitaine, tir du Chasseur…
- Moteur de résolution : protections, cumul d'attaques, **cascade de chagrin**
  entre amoureux, changements de rôle, élection du capitaine.
- Aperçu du bilan avant validation, puis application automatique au plateau
  (`isAlive`, cause et tour du décès, couples, charmes) en une transaction.

#### Historique
- Chronologie complète d'une partie : chaque tour, ses actions horodatées, son
  bilan, et l'état final de chaque joueur.

#### Export / import
- Export d'une partie en **JSON chiffré AES-256-GCM**, clé dérivée du mot de
  passe de l'utilisateur par PBKDF2-HMAC-SHA256 (150 000 itérations, sel et
  nonce aléatoires). L'en-tête est authentifié par le tag GCM.
- Partage du fichier via la feuille de partage du système.
- Import d'un export chiffré : la partie est restaurée sous de nouveaux
  identifiants, ce qui permet d'importer deux fois le même fichier sans écraser
  quoi que ce soit.

### Sécurité
- Aucune permission `INTERNET` dans le manifeste de release : l'application ne
  peut physiquement pas accéder au réseau. Vérifié par un test automatisé.
- Aucun mot de passe ni clé n'apparaît dans les journaux ou les messages
  d'erreur.
- La base n'est jamais écrite en clair sur le disque, ce qui est vérifié par un
  test qui relit le fichier brut.

### Tests
- 129 tests : unitaires (moteur de résolution, catalogues, chiffrement),
  d'intégration (repositories sur base en mémoire) et de widgets (accueil,
  création, nuit, historique, mot de passe).
