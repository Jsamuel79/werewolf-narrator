import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';
import 'package:werewolf_narrator/core/database/app_database.dart';
import 'package:werewolf_narrator/features/games/data/games_repository_impl.dart';
import 'package:werewolf_narrator/features/games/domain/game_entities.dart';
import 'package:werewolf_narrator/features/games/domain/games_repository.dart';
import 'package:werewolf_narrator/features/nights/data/nights_repository_impl.dart';
import 'package:werewolf_narrator/features/nights/domain/night_action_type.dart';
import 'package:werewolf_narrator/features/victory/domain/victory_entities.dart';

/// A whole game played through the repositories, the way the screens drive
/// them: night → day → vote → consequences → next night → victory.
void main() {
  late AppDatabase db;
  late DriftGamesRepository games;
  late DriftNightsRepository nights;
  late String gameId;

  setUp(() async {
    db = AppDatabase.memory();
    games = DriftGamesRepository(database: db, uuid: const Uuid());
    nights = DriftNightsRepository(database: db, uuid: const Uuid());
    final game = await games.createGame(
      name: 'Soirée complète',
      players: const [
        PlayerDraft(name: 'Alice', roleId: 'seer'),
        PlayerDraft(name: 'Bob', roleId: 'hunter'),
        PlayerDraft(name: 'Chloé', roleId: 'villager'),
        PlayerDraft(name: 'David', roleId: 'villager'),
        PlayerDraft(name: 'Loup', roleId: 'werewolf'),
      ],
      allowedRoleIds: const {'seer', 'hunter', 'villager', 'werewolf'},
    );
    gameId = game.id;
  });

  tearDown(() => db.close());

  Future<GameSnapshot> board() async => (await games.loadGame(gameId))!;

  Future<String> idOf(String name) async =>
      (await board()).players.firstWhere((p) => p.name == name).id;

  test('a full game runs from the first night to the victory screen', () async {
    // ── Night 1: the pack eats David, the seer looks at the wolf ───────────
    final round1 = await nights.startNight(gameId);
    expect(round1.nightNumber, 1);

    await nights.addAction(
      nightId: round1.id,
      typeId: NightActionTypes.seerVision.id,
      actorPlayerId: await idOf('Alice'),
      targetPlayerId: await idOf('Loup'),
      details: const {'text': 'Loup-Garou'},
    );
    await nights.addAction(
      nightId: round1.id,
      typeId: NightActionTypes.werewolfVictim.id,
      targetPlayerId: await idOf('David'),
    );
    final nightOutcome = await nights.resolveNight(round1.id);

    expect(nightOutcome.deaths.single.playerId, await idOf('David'));
    expect((await board()).alivePlayers, hasLength(4));
    expect(
      (await board()).game.status,
      GameStatus.inProgress,
      reason: 'two wolves-worth of villagers are still standing',
    );

    // ── Day 1: elect Chloé captain, then the village lynches Alice ─────────
    await nights.addAction(
      nightId: round1.id,
      typeId: NightActionTypes.captainElection.id,
      phase: ActionPhase.day,
      targetPlayerId: await idOf('Chloé'),
    );
    await nights.addAction(
      nightId: round1.id,
      typeId: NightActionTypes.villageVote.id,
      phase: ActionPhase.day,
      targetPlayerId: await idOf('Alice'),
      details: const {'text': 'Alice 3, Loup 1 · Capitaine → Alice'},
    );
    await nights.resolveDay(round1.id);

    var snapshot = await board();
    expect(snapshot.players.firstWhere((p) => p.name == 'Alice').isAlive, isFalse);
    expect(snapshot.aliveCaptain?.name, 'Chloé');
    expect(snapshot.alivePlayers, hasLength(3));
    expect(snapshot.game.status, GameStatus.inProgress);

    // ── Night 2: the pack eats the captain ─────────────────────────────────
    final round2 = await nights.startNight(gameId);
    expect(round2.nightNumber, 2, reason: 'the first round is complete');

    await nights.addAction(
      nightId: round2.id,
      typeId: NightActionTypes.werewolfVictim.id,
      targetPlayerId: await idOf('Chloé'),
    );
    final night2 = await nights.resolveNight(round2.id);

    expect(night2.captainDiedId, await idOf('Chloé'));
    snapshot = await board();
    expect(snapshot.aliveCaptain, isNull, reason: 'the badge died with her');
    // Bob (hunter) and the wolf are left: the wolves have caught up.
    expect(snapshot.alivePlayers.map((p) => p.name), ['Bob', 'Loup']);
    expect(
      snapshot.game.status,
      GameStatus.finished,
      reason: 'one wolf against one villager ends the game',
    );
    expect(snapshot.game.winnerCampId, VictoryCamp.werewolves.id);
    expect(snapshot.game.winnerReason, contains('Loups-Garous'));
  });

  test('the hunter takes the last wolf with him and the village wins',
      () async {
    final round1 = await nights.startNight(gameId);
    await nights.addAction(
      nightId: round1.id,
      typeId: NightActionTypes.werewolfVictim.id,
      targetPlayerId: await idOf('Bob'),
    );
    await nights.resolveNight(round1.id);

    expect((await board()).players.firstWhere((p) => p.name == 'Bob').isAlive,
        isFalse);
    expect((await board()).game.status, GameStatus.inProgress);

    // The hunter fires as he falls, and hits the wolf.
    await nights.addAction(
      nightId: round1.id,
      typeId: NightActionTypes.hunterShot.id,
      phase: ActionPhase.day,
      actorPlayerId: await idOf('Bob'),
      targetPlayerId: await idOf('Loup'),
    );
    await nights.resolveDay(round1.id);

    final snapshot = await board();
    expect(snapshot.players.firstWhere((p) => p.name == 'Loup').isAlive, isFalse);
    expect(snapshot.game.status, GameStatus.finished);
    expect(snapshot.game.winnerCampId, VictoryCamp.village.id);

    // And a finished game refuses to open another round.
    await expectLater(nights.startNight(gameId), throwsA(isA<Exception>()));
  });

  test('the lovers of two camps win over everybody else', () async {
    final round1 = await nights.startNight(gameId);
    await nights.addAction(
      nightId: round1.id,
      typeId: NightActionTypes.cupidCouple.id,
      targetPlayerId: await idOf('Loup'),
      secondaryTargetPlayerId: await idOf('Chloé'),
    );
    await nights.addAction(
      nightId: round1.id,
      typeId: NightActionTypes.werewolfVictim.id,
      targetPlayerId: await idOf('Alice'),
    );
    await nights.resolveNight(round1.id);
    await nights.addAction(
      nightId: round1.id,
      typeId: NightActionTypes.villageVote.id,
      phase: ActionPhase.day,
      targetPlayerId: await idOf('Bob'),
    );
    await nights.resolveDay(round1.id);

    // Alice, Bob gone. David, Chloé and the wolf remain.
    var snapshot = await board();
    expect(snapshot.alivePlayers, hasLength(3));
    expect(snapshot.game.status, GameStatus.inProgress);

    // The pack eats David: only the mixed couple is left.
    final round2 = await nights.startNight(gameId);
    await nights.addAction(
      nightId: round2.id,
      typeId: NightActionTypes.werewolfVictim.id,
      targetPlayerId: await idOf('David'),
    );
    await nights.resolveNight(round2.id);

    snapshot = await board();
    expect(snapshot.game.status, GameStatus.finished);
    expect(snapshot.game.winnerCampId, VictoryCamp.lovers.id);
    expect(snapshot.alivePlayers.map((p) => p.name), ['Chloé', 'Loup']);
  });
}
