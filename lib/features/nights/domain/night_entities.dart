import 'dart:convert';

import 'night_action_type.dart';

/// One thing the narrator recorded during a round.
class NightAction {
  const NightAction({
    required this.id,
    required this.nightId,
    required this.gameId,
    required this.typeId,
    required this.orderIndex,
    required this.createdAt,
    this.actorPlayerId,
    this.targetPlayerId,
    this.secondaryTargetPlayerId,
    this.details = const {},
  });

  final String id;
  final String nightId;
  final String gameId;
  final String typeId;
  final String? actorPlayerId;
  final String? targetPlayerId;
  final String? secondaryTargetPlayerId;
  final Map<String, dynamic> details;
  final int orderIndex;
  final DateTime createdAt;

  NightActionType get type => NightActionTypes.byId(typeId);

  String? get detail => details['text'] as String?;

  String? get detailsJson => details.isEmpty ? null : jsonEncode(details);

  static Map<String, dynamic> decodeDetails(String? raw) {
    if (raw == null || raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : const {};
    } on FormatException {
      return const {};
    }
  }
}

/// A player killed during a round, with the wording shown in the history.
class PlayerDeath {
  const PlayerDeath({required this.playerId, required this.cause});

  final String playerId;
  final String cause;

  Map<String, dynamic> toJson() => {'playerId': playerId, 'cause': cause};

  static PlayerDeath fromJson(Map<String, dynamic> json) => PlayerDeath(
    playerId: json['playerId'] as String,
    cause: json['cause'] as String? ?? 'Mort',
  );
}

class RoleChange {
  const RoleChange({required this.playerId, required this.newRoleId});

  final String playerId;
  final String newRoleId;

  Map<String, dynamic> toJson() => {
    'playerId': playerId,
    'newRoleId': newRoleId,
  };

  static RoleChange fromJson(Map<String, dynamic> json) => RoleChange(
    playerId: json['playerId'] as String,
    newRoleId: json['newRoleId'] as String,
  );
}

/// Everything that follows from the actions of one round.
///
/// Produced by `NightResolver`, persisted on the night row so a past round can
/// be displayed without replaying it against a board that has moved on.
class NightOutcome {
  const NightOutcome({
    required this.nightNumber,
    this.deaths = const [],
    this.savedPlayerIds = const [],
    this.newCouple,
    this.charmedPlayerIds = const [],
    this.roleChanges = const [],
    this.newCaptainId,
    this.captainDiedId,
    this.notes = const [],
  });

  final int nightNumber;
  final List<PlayerDeath> deaths;
  final List<String> savedPlayerIds;
  final (String, String)? newCouple;
  final List<String> charmedPlayerIds;
  final List<RoleChange> roleChanges;
  final String? newCaptainId;

  /// The captain lost this round, if any: the village owes itself either a new
  /// election or the successor the dying captain named.
  final String? captainDiedId;

  /// Narrator-facing lines that do not change the board (visions, spying, ...).
  final List<String> notes;

  bool get isQuiet =>
      deaths.isEmpty &&
      savedPlayerIds.isEmpty &&
      newCouple == null &&
      charmedPlayerIds.isEmpty &&
      roleChanges.isEmpty &&
      newCaptainId == null &&
      captainDiedId == null;

  Map<String, dynamic> toJson() => {
    'nightNumber': nightNumber,
    'deaths': deaths.map((d) => d.toJson()).toList(),
    'savedPlayerIds': savedPlayerIds,
    if (newCouple != null) 'newCouple': [newCouple!.$1, newCouple!.$2],
    'charmedPlayerIds': charmedPlayerIds,
    'roleChanges': roleChanges.map((c) => c.toJson()).toList(),
    if (newCaptainId != null) 'newCaptainId': newCaptainId,
    if (captainDiedId != null) 'captainDiedId': captainDiedId,
    'notes': notes,
  };

  static NightOutcome fromJson(Map<String, dynamic> json) {
    final couple = json['newCouple'] as List<dynamic>?;
    return NightOutcome(
      nightNumber: json['nightNumber'] as int? ?? 0,
      deaths: (json['deaths'] as List<dynamic>? ?? [])
          .map((e) => PlayerDeath.fromJson(e as Map<String, dynamic>))
          .toList(),
      savedPlayerIds: (json['savedPlayerIds'] as List<dynamic>? ?? [])
          .cast<String>(),
      newCouple: couple != null && couple.length == 2
          ? (couple[0] as String, couple[1] as String)
          : null,
      charmedPlayerIds: (json['charmedPlayerIds'] as List<dynamic>? ?? [])
          .cast<String>(),
      roleChanges: (json['roleChanges'] as List<dynamic>? ?? [])
          .map((e) => RoleChange.fromJson(e as Map<String, dynamic>))
          .toList(),
      newCaptainId: json['newCaptainId'] as String?,
      captainDiedId: json['captainDiedId'] as String?,
      notes: (json['notes'] as List<dynamic>? ?? []).cast<String>(),
    );
  }
}

/// One round of play: the night phase and the village vote that follows it.
class Night {
  const Night({
    required this.id,
    required this.gameId,
    required this.nightNumber,
    required this.createdAt,
    this.resolvedAt,
    this.outcome,
  });

  final String id;
  final String gameId;
  final int nightNumber;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final NightOutcome? outcome;

  bool get isResolved => resolvedAt != null;
}

/// A night together with the actions recorded in it.
class NightDetail {
  const NightDetail({required this.night, required this.actions});

  final Night night;
  final List<NightAction> actions;
}
