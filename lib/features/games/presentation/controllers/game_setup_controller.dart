import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/game_entities.dart';
import '../../domain/games_repository.dart';
import '../../domain/role.dart';
import 'games_providers.dart';

class GameSetupState {
  const GameSetupState({
    this.name = '',
    this.players = const [],
    this.isSaving = false,
  });

  final String name;
  final List<PlayerDraft> players;
  final bool isSaving;

  bool get canSubmit =>
      !isSaving && name.trim().isNotEmpty && players.length >= 3;

  int get werewolfCount =>
      players.where((p) => Roles.byId(p.roleId).team == RoleTeam.werewolves)
          .length;

  /// Usual table ratio: roughly one wolf per four players, at least one.
  int get suggestedWerewolfCount =>
      players.isEmpty ? 0 : (players.length / 4).round().clamp(1, 99);

  GameSetupState copyWith({
    String? name,
    List<PlayerDraft>? players,
    bool? isSaving,
  }) {
    return GameSetupState(
      name: name ?? this.name,
      players: players ?? this.players,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

class GameSetupController extends Notifier<GameSetupState> {
  @override
  GameSetupState build() => const GameSetupState();

  void setName(String value) => state = state.copyWith(name: value);

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
          .createGame(name: state.name, players: state.players);
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
