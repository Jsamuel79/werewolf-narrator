import 'package:drift/drift.dart';

/// A game session run by a single narrator.
@DataClassName('GameRow')
class Games extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 120)();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  /// `setup` | `inProgress` | `finished` — see `GameStatus`.
  TextColumn get status => text().withLength(max: 24)();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().nullable()();

  /// Camp that won, once [status] is `finished` — see `VictoryCamp`.
  /// Free-form text on purpose: a future solo role wins under its own role id
  /// without a migration.
  TextColumn get winnerCampId => text().nullable()();

  /// The sentence explaining that win, as the narrator read it out.
  TextColumn get winnerReason => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// A player seated at the table, with the role the narrator dealt them.
@DataClassName('PlayerRow')
class Players extends Table {
  TextColumn get id => text()();
  TextColumn get gameId =>
      text().references(Games, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text().withLength(min: 1, max: 80)();

  /// Key into the role catalogue (`werewolf`, `seer`, ...), free-form on
  /// purpose so adding a role never requires a schema migration.
  TextColumn get roleId => text().withLength(max: 40)();
  IntColumn get seatOrder => integer()();
  BoolColumn get isAlive => boolean().withDefault(const Constant(true))();

  /// Captain is an elected status that stacks with any role, not a role.
  BoolColumn get isCaptain => boolean().withDefault(const Constant(false))();
  BoolColumn get isCharmed => boolean().withDefault(const Constant(false))();

  /// The other lover. Symmetric: both rows point at each other.
  /// Not declared as a foreign key so the two rows can be written in any order.
  TextColumn get coupledWithPlayerId => text().nullable()();
  IntColumn get deathNightNumber => integer().nullable()();
  TextColumn get deathCause => text().nullable()();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// One full round of play: the night phase plus the village vote that follows.
@DataClassName('NightRow')
class Nights extends Table {
  TextColumn get id => text()();
  TextColumn get gameId =>
      text().references(Games, #id, onDelete: KeyAction.cascade)();
  IntColumn get nightNumber => integer()();
  DateTimeColumn get createdAt => dateTime()();

  /// Non-null once the narrator closed the night; actions are then frozen.
  DateTimeColumn get resolvedAt => dateTime().nullable()();

  /// Serialised `NightOutcome`, stored so past nights render without replaying
  /// the resolver against a player state that has since moved on.
  TextColumn get summaryJson => text().nullable()();

  /// Non-null once the day phase (debate, election, vote) is over too.
  DateTimeColumn get dayResolvedAt => dateTime().nullable()();

  /// Serialised `NightOutcome` of the day phase.
  TextColumn get daySummaryJson => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {gameId, nightNumber},
  ];
}

/// A single thing that happened during a round, as entered by the narrator.
@DataClassName('NightActionRow')
class NightActions extends Table {
  TextColumn get id => text()();
  TextColumn get nightId =>
      text().references(Nights, #id, onDelete: KeyAction.cascade)();

  /// Denormalised so the full history of a game is one indexed query.
  TextColumn get gameId => text()();

  /// Key into the action catalogue — see `NightActionType`.
  TextColumn get type => text().withLength(max: 40)();

  /// `night` or `day` — which half of the round recorded this action, so both
  /// halves can be resolved separately. Some actions (the hunter's shot) can
  /// happen in either, hence a column rather than a lookup in the catalogue.
  TextColumn get phase =>
      text().withLength(max: 8).withDefault(const Constant('night'))();
  TextColumn get actorPlayerId => text().nullable()();
  TextColumn get targetPlayerId => text().nullable()();
  TextColumn get secondaryTargetPlayerId => text().nullable()();

  /// Free-form payload, e.g. the role the seer discovered.
  TextColumn get detailsJson => text().nullable()();
  IntColumn get orderIndex => integer()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// One role the narrator allowed for a given game.
///
/// A row per allowed role rather than a JSON blob on `games`: the selection is
/// a set of foreign keys to the role catalogue, and SQLite is better at sets
/// than at parsing text. Absence of any row means « no explicit composition »,
/// which the app reads as the whole catalogue.
@DataClassName('GameRoleSelectionRow')
class GameRoleSelections extends Table {
  TextColumn get gameId =>
      text().references(Games, #id, onDelete: KeyAction.cascade)();

  /// Key into the role catalogue — free-form, like `Players.roleId`.
  TextColumn get roleId => text().withLength(max: 40)();

  @override
  Set<Column<Object>> get primaryKey => {gameId, roleId};
}
