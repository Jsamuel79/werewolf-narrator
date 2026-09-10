import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/game_composition.dart';
import '../../domain/game_entities.dart';
import '../../domain/games_repository.dart';
import '../../domain/role.dart';
import '../../domain/role_dealer.dart';
import 'games_providers.dart';

class GameSetupState {
  const GameSetupState({
    this.name = '',
    this.players = const [],
    this.isSaving = false,
    this.allowedRoleIds = GameComposition.defaultRoleIds,
  });

  final String name;
  final List<PlayerDraft> players;
  final bool isSaving;

  /// Roles allowed in this game; the random deal only picks among them.
  final Set<String> allowedRoleIds;

  bool get canSubmit =>
      !isSaving && name.trim().isNotEmpty && players.length >= 3;

  int get werewolfCount =>
      players.where((p) => Roles.byId(p.roleId).team == RoleTeam.werewolves)
          .length;

  /// Usual table ratio: roughly one wolf per four players, at least one.
  int get suggestedWerewolfCount =>
      players.isEmpty ? 0 : RoleDealer.werewolfCountFor(players.length);

  GameSetupState copyWith({
    String? name,
    List<PlayerDraft>? players,
    bool? isSaving,
    Set<String>? allowedRoleIds,
  }) {
    return GameSetupState(
      name: name ?? this.name,
      players: players ?? this.players,
      isSaving: isSaving ?? this.isSaving,
      allowedRoleIds: allowedRoleIds ?? this.allowedRoleIds,
    );
  }
}

class GameSetupController extends Notifier<GameSetupState> {
  bool _disposed = false;

  /// Set once the screen handed over a starting point (a rematch), so the
  /// background load of the last composition does not overwrite it.
  bool _seeded = false;

  @override
  GameSetupState build() {
    ref.onDispose(() => _disposed = true);
    // The composition of the last game is the sensible default for the next
    // one; loaded in the background so the screen opens instantly.
    unawaited(_restoreLastComposition());
    return const GameSetupState();
  }

  Future<void> _restoreLastComposition() async {
    final last = await ref
        .read(gamesRepositoryProvider)
        .loadLastComposition();
    if (_disposed || _seeded) return;
    state = state.copyWith(allowedRoleIds: last);
  }

  void setName(String value) => state = state.copyWith(name: value);

  void setComposition(Set<String> roleIds) => state = state.copyWith(
    allowedRoleIds: GameComposition.normalize(roleIds),
  );

  /// Seeds the screen with the players of a game that just ended, so the same
  /// table can start over without retyping every name.
  void seed({
    String? name,
    List<String>? playerNames,
    Set<String>? allowedRoleIds,
  }) {
    _seeded = true;
    state = state.copyWith(
      name: name ?? state.name,
      players: playerNames == null
          ? state.players
          : [
              for (final playerName in playerNames)
                PlayerDraft(name: playerName, roleId: Roles.villager.id),
            ],
      allowedRoleIds: allowedRoleIds == null
          ? state.allowedRoleIds
          : GameComposition.normalize(allowedRoleIds),
    );
  }

  void addPlayer(String name, {String roleId = 'villager'}) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    state = state.copyWith(
      players: [...state.players, PlayerDraft(name: trimmed, roleId: roleId)],
    );
  }

  void removePlayerAt(int index) {
    final players = [...state.players]..removeAt(index);
    state = state.copyWith(players: players);
  }

  void renamePlayerAt(int index, String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final players = [...state.players];
    players[index] = players[index].copyWith(name: trimmed);
    state = state.copyWith(players: players);
  }

  /// Deals every seat at random. A second call redeals from scratch: the
  /// narrator can keep rolling until they like the table.
  void randomizeRoles({Random? random}) {
    if (state.players.isEmpty) return;
    final roleIds = RoleDealer.deal(
      playerCount: state.players.length,
      allowedRoleIds: state.allowedRoleIds,
      random: random,
    );
    state = state.copyWith(
      players: [
        for (var i = 0; i < state.players.length; i++)
          state.players[i].copyWith(roleId: roleIds[i]),
      ],
    );
  }

  void setRoleAt(int index, String roleId) {
    final players = [...state.players];
    players[index] = players[index].copyWith(roleId: roleId);
    state = state.copyWith(players: players);
  }

  /// [newIndex] is the final index of the moved player, as handed over by
  /// `ReorderableListView.onReorderItem`.
  void reorder(int oldIndex, int newIndex) {
    final players = [...state.players];
    players.insert(newIndex, players.removeAt(oldIndex));
    state = state.copyWith(players: players);
  }

  Future<Game> submit() async {
    state = state.copyWith(isSaving: true);
    try {
      return await ref
          .read(gamesRepositoryProvider)
          .createGame(
            name: state.name,
            players: state.players,
            allowedRoleIds: state.allowedRoleIds,
          );
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }
}

final NotifierProvider<GameSetupController, GameSetupState>
gameSetupControllerProvider =
    NotifierProvider<GameSetupController, GameSetupState>(
      GameSetupController.new,
      isAutoDispose: true,
    );
