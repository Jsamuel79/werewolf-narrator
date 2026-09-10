# 📓 Changelog

Toutes les évolutions notables du projet, de la plus récente à la plus ancienne.
Format inspiré de [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/).

## [2.0.0] — 2026-09-10

La partie se termine enfin toute seule, et le tour de jeu est refondu : la nuit
se joue en cartes que le narrateur balaie, et la journée existe pour de bon.

### Corrigé

- 🐞 **Aucune fin de partie n'était détectée.** Une table sans le moindre
  Loup-Garou tournait indéfiniment sans jamais annoncer de vainqueur. Un moteur
  de règles ordonné évalue désormais la fin de partie après chaque résolution
  de nuit, chaque vote, et **toute** modification du statut d'un joueur :
  - victoire du **Village** dès l'élimination du dernier loup — le Loup-Garou
    Blanc compte, il chasse avec la meute ;
  - victoire des **Loups-Garous** dès que les survivants non-loups ne sont plus
    en supériorité numérique ;
  - victoire des **Amoureux** de camps différents, prioritaire sur les deux
    précédentes, dès qu'ils sont les deux derniers en vie ;
  - conditions individuelles des rôles solitaires : le **Joueur de Flûte** quand
    tous les survivants sont charmés, le **Loup-Garou Blanc** seul rescapé,
    l'**Ange** éliminé dès le premier tour ;
  - filets de sécurité : table entièrement décimée, dernier survivant isolé.
  Une partie sans aucun loup se termine dès la première vérification par une
  victoire du Village, et l'écran de création prévient avant même de commencer.

### Ajouté

#### Nuit en cartes
- L'écran de nuit est **entièrement refondu** : plus aucun formulaire. La
  séquence des cartes est calculée dans l'ordre de réveil du jeu de société,
  filtrée par les rôles encore vivants, les pouvoirs de première nuit et les
  pouvoirs déjà consommés.
- Une carte par rôle actif : choix simple, choix double (Cupidon, Joueur de
  Flûte), révélation (Voyante), cible + note (Renard, Corbeau), question fermée
  (Sœurs, Frères, Petite Fille, Voleur) et les trois boutons de la Sorcière.
- Balayage gauche pour passer sans rien enregistrer, droite pour revenir
  corriger ; boutons « Précédent » / « Passer » en alternative accessible.
- Contraintes de règles appliquées : la meute ne se dévore pas, la Voyante ne se
  regarde pas, la potion de vie ne ressuscite que la victime des loups, le
  Salvateur ne protège pas deux nuits de suite le même joueur.
- Carte finale de bilan, puis passage automatique au jour.

#### Phase de jour
- Réveil du village avec les morts de la nuit, chronomètre de débat configurable
  (2/3/5/10 min, ±30 s) avec vibration et son de fin, vote du village, tir du
  Chasseur, bilan.
- Le **vote** se saisit comme il se compte à table : un compteur par joueur. Le
  résultat s'affiche en direct, avec la voix double du Capitaine, l'égalité
  tranchée par le Bouc émissaire puis par le Capitaine, et l'Idiot du Village
  démasqué mais épargné une fois dans la partie.

#### Capitaine
- Élection **unique** : l'action disparaît tant qu'un Capitaine est vivant et
  réapparaît dès qu'il meurt.
- À sa mort, le narrateur choisit entre la **désignation d'un successeur** par le
  mourant et une **nouvelle élection** ; le bilan l'annonce explicitement.

#### Distribution et composition
- Bouton **« Distribution aléatoire »** sur l'écran de création et sur une partie
  pas encore commencée : nombre de loups conforme au livret, rôles uniques,
  seuils par rôle, plancher de Villageois simples. Redistribuable à volonté,
  et chaque assignation reste modifiable à la main.
- Écran **« Composition de la partie »** : les rôles autorisés se cochent avant
  la distribution. Villageois et Loup-Garou toujours en jeu. La composition est
  enregistrée par partie et proposée par défaut à la suivante.

#### Fin de partie
- Écran de victoire : camp vainqueur, justification, survivants, éliminés avec
  leur rôle révélé, accès à l'historique complet.
- **« Rejouer avec les mêmes joueurs »** : nouvelle partie pré-remplie avec les
  mêmes noms et la même composition, tous les statuts remis à zéro. La partie
  terminée reste consultable telle quelle.

### Modifié

- Un tour est désormais **deux moitiés distinctes** — la nuit s'applique au
  plateau avant que le jour commence — avec la phase de chaque action
  enregistrée. Les tours joués en 1.0.0 sont marqués comme complets.
- L'export chiffré transporte les nouveautés (camp vainqueur, composition,
  phase de jour). Un fichier exporté par la 1.0.0 s'importe toujours.
- La suggestion du nombre de loups suit maintenant la même table que le
  distributeur.

### Sécurité

- **Aucune dépendance ajoutée** : la pile de cartes balayables et le chronomètre
  sont écrits sur le SDK seul. Le test hors-ligne épingle désormais la liste des
  paquets embarqués et vérifie que ces deux widgets n'importent rien d'autre que
  Flutter.
- Les quatre migrations de schéma (2, 3, 4) n'ajoutent que des colonnes et une
  table : aucune partie existante n'est perdue, ce qu'un test vérifie sur une
  base reconstruite au format 1.0.0.

### Tests

- 245 tests verts : moteur de victoire, distributeur de rôles, composition,
  vote pondéré, séquences de cartes de nuit et de jour, migrations, export v2,
  écrans de nuit, de jour et de victoire, plus un test d'intégration qui joue
  une partie entière de la première nuit à la victoire finale.

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
