import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:uuid/uuid.dart';
import 'package:werewolf_narrator/core/database/app_database.dart';
import 'package:werewolf_narrator/core/errors/app_exception.dart';
import 'package:werewolf_narrator/features/games/data/games_repository_impl.dart';
import 'package:werewolf_narrator/features/games/domain/game_entities.dart';
import 'package:werewolf_narrator/features/games/domain/games_repository.dart';
import 'package:werewolf_narrator/features/nights/data/nights_repository_impl.dart';
import 'package:werewolf_narrator/features/nights/domain/night_action_type.dart';
import 'package:werewolf_narrator/features/victory/data/victory_recorder.dart';
import 'package:werewolf_narrator/features/victory/domain/victory_entities.dart';

void main() {
  late AppDatabase db;
  late DriftGamesRepository games;
  late DriftNightsRepository nights;

  setUp(() {
    db = AppDatabase.memory();
    games = DriftGamesRepository(database: db, uuid: const Uuid());
    nights = DriftNightsRepository(database: db, uuid: const Uuid());
  });

  tearDown(() => db.close());

  Future<GameSnapshot> seed({
    List<PlayerDraft> players = const [
      PlayerDraft(name: 'Alice', roleId: 'villager'),
      PlayerDraft(name: 'Bob', roleId: 'villager'),
      PlayerDraft(name: 'Loup', roleId: 'werewolf'),
    ],
  }) async {
    final game = await games.createGame(name: 'Partie', players: players);
    return (await games.loadGame(game.id))!;
  }

  test('closing a night that kills the last wolf ends the game', () async {
    final snapshot = await seed();
    final wolf = snapshot.players.firstWhere((p) => p.name == 'Loup');
    final night = await nights.startNight(snapshot.game.id);
    await nights.addAction(
      nightId: night.id,
      typeId: NightActionTypes.villageVote.id,
      targetPlayerId: wolf.id,
    );

    await nights.resolveNight(night.id);

    final after = (await games.loadGame(snapshot.game.id))!;
    expect(after.game.status, GameStatus.finished);
    expect(after.game.winnerCampId, VictoryCamp.village.id);
    expect(after.game.winnerReason, contains('Village'));
  });

  test('marking a player dead by hand can end the game too', () async {
    final snapshot = await seed();
    final alice = snapshot.players.firstWhere((p) => p.name == 'Alice');

    await games.savePlayers([
      alice.copyWith(isAlive: false, deathCause: 'Marqué mort'),
    ]);

    final after = (await games.loadGame(snapshot.game.id))!;
    expect(after.game.status, GameStatus.finished);
    expect(after.game.winnerCampId, VictoryCamp.werewolves.id);
  });

  test('a finished game refuses to open another night', () async {
    final snapshot = await seed();
    final wolf = snapshot.players.firstWhere((p) => p.name == 'Loup');
    await games.savePlayers([wolf.copyWith(isAlive: false)]);

    expect(
      () => nights.startNight(snapshot.game.id),
      throwsA(isA<GameRuleException>()),
    );
  });

  test('resuming a finished game forgets the winner', () async {
    final snapshot = await seed();
    final wolf = snapshot.players.firstWhere((p) => p.name == 'Loup');
    await games.savePlayers([wolf.copyWith(isAlive: false)]);

    await games.setStatus(
      gameId: snapshot.game.id,
      status: GameStatus.inProgress,
    );

    final after = (await games.loadGame(snapshot.game.id))!;
    expect(after.game.status, GameStatus.inProgress);
    expect(after.game.winnerCampId, isNull);
    expect(after.game.winnerReason, isNull);
  });

  test('the recorder leaves a game the narrator already closed alone', () async {
    final snapshot = await seed();
    await games.setStatus(
      gameId: snapshot.game.id,
      status: GameStatus.finished,
    );

    final recorder = VictoryRecorder(database: db);
    expect(await recorder.refresh(snapshot.game.id), isNull);
  });

  test('a running game is left untouched', () async {
    final snapshot = await seed(
      players: const [
        PlayerDraft(name: 'Alice', roleId: 'villager'),
        PlayerDraft(name: 'Bob', roleId: 'villager'),
        PlayerDraft(name: 'Chloé', roleId: 'seer'),
        PlayerDraft(name: 'Loup', roleId: 'werewolf'),
      ],
    );

    final recorder = VictoryRecorder(database: db);
    expect(await recorder.refresh(snapshot.game.id), isNull);
    expect(
      (await games.loadGame(snapshot.game.id))!.game.status,
      GameStatus.inProgress,
    );
  });

  test('a v1 database keeps its games through the migration', () async {
    // Rebuild the v1 schema by hand — no winner columns — and drop a game in
    // it, the way a phone updating from 1.0.0 would have it.
    final directory = await Directory.systemTemp.createTemp('wn_migration');
    final file = File('${directory.path}/legacy.db');
    final legacy = sqlite3.open(file.path);
    legacy
      ..execute('''
        CREATE TABLE games (
          id TEXT NOT NULL PRIMARY KEY,
          name TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          status TEXT NOT NULL,
          is_archived INTEGER NOT NULL DEFAULT 0,
          notes TEXT
        )''')
      ..execute('''
        CREATE TABLE players (
          id TEXT NOT NULL PRIMARY KEY,
          game_id TEXT NOT NULL REFERENCES games (id) ON DELETE CASCADE,
          name TEXT NOT NULL,
          role_id TEXT NOT NULL,
          seat_order INTEGER NOT NULL,
          is_alive INTEGER NOT NULL DEFAULT 1,
          is_captain INTEGER NOT NULL DEFAULT 0,
          is_charmed INTEGER NOT NULL DEFAULT 0,
          coupled_with_player_id TEXT,
          death_night_number INTEGER,
          death_cause TEXT,
          notes TEXT
        )''')
      ..execute('''
        CREATE TABLE nights (
          id TEXT NOT NULL PRIMARY KEY,
          game_id TEXT NOT NULL REFERENCES games (id) ON DELETE CASCADE,
          night_number INTEGER NOT NULL,
          created_at INTEGER NOT NULL,
          resolved_at INTEGER,
          summary_json TEXT,
          UNIQUE (game_id, night_number)
        )''')
      ..execute('''
        CREATE TABLE night_actions (
          id TEXT NOT NULL PRIMARY KEY,
          night_id TEXT NOT NULL REFERENCES nights (id) ON DELETE CASCADE,
          game_id TEXT NOT NULL,
          type TEXT NOT NULL,
          actor_player_id TEXT,
          target_player_id TEXT,
          secondary_target_player_id TEXT,
          details_json TEXT,
          order_index INTEGER NOT NULL,
          created_at INTEGER NOT NULL
        )''')
      ..execute(
        "INSERT INTO games VALUES ('old', 'Vieille partie', 1, 1, "
        "'inProgress', 0, NULL)",
      )
      ..execute(
        "INSERT INTO nights VALUES ('n1', 'old', 1, 1, 2, NULL)",
      )
      ..execute(
        "INSERT INTO night_actions VALUES ('a1', 'n1', 'old', "
        "'werewolfVictim', NULL, 'p1', NULL, NULL, 0, 1)",
      )
      ..execute(
        "INSERT INTO players VALUES ('p1', 'old', 'Alice', 'villager', 0, "
        '1, 0, 0, NULL, NULL, NULL, NULL)',
      )
      ..execute('PRAGMA user_version = 1')
      ..close();

    final migrated = AppDatabase(NativeDatabase(file));
    final rows = await migrated.select(migrated.games).get();
    expect(rows, hasLength(1));
    expect(rows.single.name, 'Vieille partie');
    expect(rows.single.winnerCampId, isNull);
    expect(await migrated.select(migrated.players).get(), hasLength(1));

    // A round closed by the old build counts as complete, day included.
    final night = (await migrated.select(migrated.nights).get()).single;
    expect(night.resolvedAt, isNotNull);
    expect(
      night.dayResolvedAt,
      night.resolvedAt,
      reason: 'an old round covered the night and the vote that followed',
    );
    // And its actions default to the night phase.
    final action = (await migrated.select(migrated.nightActions).get()).single;
    expect(action.phase, 'night');
    await migrated.close();
    await directory.delete(recursive: true);
  });
}
