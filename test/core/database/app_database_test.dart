import 'package:flutter_test/flutter_test.dart';
import 'package:werewolf_narrator/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.memory());
  tearDown(() => db.close());

  GamesCompanion game(String id) => GamesCompanion.insert(
        id: id,
        name: 'Partie $id',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        status: 'setup',
      );

  test('schema version is 2', () {
    expect(db.schemaVersion, 2);
  });

  test('deleting a game cascades to players, nights and actions', () async {
    await db.into(db.games).insert(game('g1'));
    await db.into(db.players).insert(
          PlayersCompanion.insert(
            id: 'p1',
            gameId: 'g1',
            name: 'Alice',
            roleId: 'seer',
            seatOrder: 0,
          ),
        );
    await db.into(db.nights).insert(
          NightsCompanion.insert(
            id: 'n1',
            gameId: 'g1',
            nightNumber: 1,
            createdAt: DateTime(2026, 1, 1),
          ),
        );
    await db.into(db.nightActions).insert(
          NightActionsCompanion.insert(
            id: 'a1',
            nightId: 'n1',
            gameId: 'g1',
            type: 'werewolfVictim',
            orderIndex: 0,
            createdAt: DateTime(2026, 1, 1),
          ),
        );

    await (db.delete(db.games)..where((g) => g.id.equals('g1'))).go();

    expect(await db.select(db.players).get(), isEmpty);
    expect(await db.select(db.nights).get(), isEmpty);
    expect(await db.select(db.nightActions).get(), isEmpty);
  });

  test('a night number is unique within a game', () async {
    await db.into(db.games).insert(game('g1'));
    await db.into(db.games).insert(game('g2'));

    NightsCompanion night(String id, String gameId) => NightsCompanion.insert(
          id: id,
          gameId: gameId,
          nightNumber: 1,
          createdAt: DateTime(2026, 1, 1),
        );

    await db.into(db.nights).insert(night('n1', 'g1'));
    // Same number in another game is fine.
    await db.into(db.nights).insert(night('n2', 'g2'));

    await expectLater(
      db.into(db.nights).insert(night('n3', 'g1')),
      throwsA(anything),
    );
  });

  test('players default to alive, uncoupled and without a captain badge',
      () async {
    await db.into(db.games).insert(game('g1'));
    await db.into(db.players).insert(
          PlayersCompanion.insert(
            id: 'p1',
            gameId: 'g1',
            name: 'Bob',
            roleId: 'villager',
            seatOrder: 0,
          ),
        );

    final player = await db.select(db.players).getSingle();

    expect(player.isAlive, isTrue);
    expect(player.isCaptain, isFalse);
    expect(player.isCharmed, isFalse);
    expect(player.coupledWithPlayerId, isNull);
    expect(player.deathNightNumber, isNull);
  });
}
