# 📓 Changelog

Toutes les évolutions notables du projet, de la plus récente à la plus ancienne.
Format inspiré de [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/).

## [2.2.0] — 2026-09-11

Une vraie partie avec un Joueur de Flûte, et cinq remontées du terrain : sa
condition de victoire n'était pas prioritaire, ses cibles se répétaient, son
rituel de reconnaissance n'était rappelé nulle part, la Sorcière ne disait rien
au narrateur de ce qu'il voulait savoir, et compter quarante voix demandait
quarante appuis.

### Corrigé

- 🐞 **Le Joueur de Flûte pouvait perdre une partie qu'il venait de gagner.**
  Sa règle existait, mais elle était évaluée en quatrième : un Flûtiste ayant
  charmé sa propre amoureuse se faisait souffler la victoire par la règle des
  Amoureux, qui se déclenchait avant lui sur le même plateau. Sa condition est
  désormais la **première** testée — avant les Amoureux, avant le Village, avant
  les Loups — parce qu'elle ne doit rien à personne.
- 🎭 **Un Flûtiste amoureux gagne avec son amoureux vivant.** Deux règles
  officielles se croisaient ; les faire cohabiter coûte un nom de plus au
  palmarès et évite d'en sacrifier une (cf. D41).
- 📖 **Règle remise à l'endroit, et verrouillée par des tests : tuer le Joueur
  de Flûte n'a jamais fait partie des conditions de victoire du Village.** Le
  Village gagne en éliminant les Loups-Garous, Flûtiste vivant ou non. Un
  Flûtiste mort perd simplement sa façon de gagner (cf. D40).
- 🐞 **Les joueurs déjà charmés étaient reproposés nuit après nuit.** Le charme
  ne se retire jamais : les revoir dans la liste laissait croire que le sort
  s'était dissipé, et recharmer quelqu'un coûtait une nuit entière. Sa carte ne
  propose plus que les vivants non charmés, et dit pourquoi un nom manque.
- 🐞 **Le charme ne pouvait plus être validé quand il ne restait qu'un nom.**
  Conséquence du filtrage : la carte exigeait deux cibles, donc la dernière
  nuit utile était impossible à valider — et la victoire du Flûtiste,
  inatteignable. La règle dit « un ou deux joueurs » : la seconde cible est
  maintenant facultative (cf. D43).
- 🐞 **Compter plus d'une poignée de voix demandait autant d'appuis que de
  voix.** Le compteur de votes se saisit désormais au clavier autant qu'au
  `+`/`-`, sans aucun plafond : l'application compte ce que le narrateur lui
  dit, elle ne le contredit pas (cf. D45).

### Ajouté

- 🕵️ **Bandeau « Info narrateur »** sur les cartes de nuit. Le jeu cache des
  choses aux *joueurs*, jamais au narrateur : la carte de la Sorcière indique
  désormais si la victime des loups est **déjà protégée par le Salvateur**, donc
  si la potion de vie ferait double emploi. La Sorcière, elle, n'est toujours
  pas censée le savoir — le bandeau est visuellement à l'opposé du reste de la
  carte et porte la mention « à ne pas lire à voix haute ». Même mécanisme sur
  le **Grand Méchant Loup** (la meute a déjà désigné X) et sur l'**Infect Père
  des Loups** (quel repas l'infection remplace, et quand elle serait dépensée
  pour rien). **Aucun bouton n'est jamais grisé** à cause d'une de ces
  informations (cf. D44).
- 🎶 **Appel des charmés**, une carte par nuit, juste après celle du Flûtiste :
  la liste **cumulée** de tous les joueurs charmés — les anciens et ceux de la
  nuit — à réveiller ensemble pour qu'ils se reconnaissent, comme le prévoit la
  règle. Elle n'enregistre rien, exclut les morts, et n'existe pas s'il n'y a
  personne à réveiller (cf. D46).
- ⭐ La voix double du Capitaine s'affiche **à côté** du compteur (`+1⭐`) au
  lieu d'être fondue dedans : le champ contient les mains levées, et rien
  d'autre.

### Documenté

- Le cas du Flûtiste **infecté** par l'Infect Père des Loups : il change de
  `roleId`, donc de camp, et perd sa condition solo (cf. D42).
- Décisions **D40 à D46** dans `.claude/ARCHITECTURE.md`, avec le nouvel ordre
  des règles de victoire et les deux nouveaux mécanismes de carte.

### Inchangé

- **Aucune migration** : le schéma ne bouge pas (la colonne `isCharmed` existait
  depuis la v1, et elle n'a jamais été remise à zéro entre deux nuits).
- **Aucune dépendance ajoutée** — toujours 16 paquets, liste épinglée par le
  test hors-ligne. Le format d'export est inchangé et reste lisible par les
  versions précédentes.
- 351 tests verts, `flutter analyze` sans reproche.

## [2.1.0] — 2026-09-11

Deux bugs de synchronisation remontés du terrain, et la fin de la roadmap : les
deux derniers rôles sans interface, les rappels de pouvoirs passifs, et une
sauvegarde chiffrée qui se fait toute seule.

### Corrigé

- 🐞 **La potion de vie de la Sorcière paraissait inutilisable.** Après que la
  meute avait désigné sa victime, la carte suivante affichait « Personne à
  sauver » — alors que le bilan de fin de nuit, lui, annonçait bien la mort.
- 🐞 **Le bilan du jour s'ouvrait vide.** Juste après la validation d'un vote
  qui éliminait un joueur, la carte suivante annonçait « personne n'est mort »,
  et ne se corrigeait qu'au rechargement suivant.

  Même cause pour les deux : `watchNight` interrogeait la table `nights` et
  chargeait les actions à côté. Un flux Drift ne se réveille que pour les tables
  que sa requête lit — celui-ci n'entendait donc jamais parler d'une action
  ajoutée, et **toutes les cartes après la première lisaient une liste
  périmée**. La donnée n'était jamais perdue, ce qui explique que le bilan final,
  rendu après la mise à jour de la ligne `nights`, ait toujours été juste. La
  requête joint désormais les deux tables : enregistrer, modifier ou retirer une
  action rafraîchit l'écran immédiatement.
- 🐞 **Un vote qui terminait la partie ne montrait pas l'écran de victoire.**
  Même famille : l'écran demandait au provider qui l'observait si la partie était
  finie, et recevait l'état d'avant la transaction. Le plateau est maintenant
  relu en base après l'écriture.
- 🐞 **Les cartes de jour se partageaient leur état** faute de clé : le joueur
  choisi pour l'élection du Capitaine se retrouvait présélectionné sur la carte
  du Chasseur.

### Ajouté

#### Les deux derniers rôles du catalogue
- **Juge bègue** : une fois dans la partie, il peut réclamer un **second vote**
  immédiatement après le premier, dans la même journée. Les deux éliminations
  comptent, et c'est le second vote qui a le dernier mot sur le Chasseur et sur
  la Servante.
- **Servante dévouée** : juste avant que la carte de l'éliminé ne soit
  retournée, elle peut se dévoiler et la reprendre. Elle perd alors tous ses
  statuts — amoureux, écharpe de Capitaine, charme — et son partenaire est
  libéré du couple.

#### Rappels des pouvoirs passifs
- Les règles que l'application ne peut pas appliquer seule s'affichent sur la
  carte qui les pose : l'**Ancien** et le **Chevalier** sur la carte des loups,
  l'**ours** et la **Servante** au réveil, l'**Idiot du Village**, le **Bouc
  émissaire** et la malédiction de l'**Ancien** sur la carte de vote.
- Les règles que le moteur applique vraiment le disent (« l'application s'en
  charge »), pour qu'elles ne soient pas appliquées deux fois.

#### Sauvegarde automatique chiffrée
- Après **chaque moitié de tour**, l'application écrit un instantané chiffré de
  la partie dans son répertoire privé, scellé avec la **clé de la base** : aucun
  mot de passe à saisir, aucun réseau, rien de lisible hors de l'appareil.
- Un fichier par partie, réécrit à chaque tour, via un fichier temporaire
  renommé pour qu'un crash en cours d'écriture ne détruise pas le précédent.
- Écran **« Instantanés de secours »** depuis l'accueil : liste, restauration
  (qui crée une **copie** — la partie en cours n'est jamais écrasée) et
  suppression.
- Une sauvegarde qui échoue n'annule jamais le tour joué.

#### Chronomètre
- Nouveau mode **« Tour de parole »** : chaque joueur dispose du même temps
  (20/30/45/60 s), le nom du joueur courant est affiché, et un bouton passe au
  suivant en faisant le tour de la table. Le mode « Débat libre » reste
  inchangé.

### Sécurité
- Toujours **aucune dépendance ajoutée** : l'instantané réutilise l'AES-256-GCM
  déjà embarqué, avec la clé du Keystore au lieu d'un mot de passe. Les deux
  types d'enveloppe se refusent mutuellement, avec un message qui indique la
  bonne porte.
- Le tag GCM couvre l'en-tête : un instantané modifié est rejeté, un instantané
  venu d'une autre installation est ignoré sans casser la liste.

### Tests
- 307 tests verts. Les deux bugs ont d'abord été reproduits par des tests qui
  échouaient sur le code livré — flux Drift, carte de la Sorcière, aller-retour
  dans la pile de cartes, bilan du jour, cascade des amoureux, Chasseur
  lynché — avant d'être corrigés.

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
