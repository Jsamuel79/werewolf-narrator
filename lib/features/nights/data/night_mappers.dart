import '../../../core/database/app_database.dart';
import '../domain/night_entities.dart';

extension NightRowMapper on NightRow {
  Night toEntity() => Night(
    id: id,
    gameId: gameId,
    nightNumber: nightNumber,
    createdAt: createdAt,
    resolvedAt: resolvedAt,
    outcome: summaryJson == null
        ? null
        : NightOutcome.fromJson(
            NightAction.decodeDetails(summaryJson),
          ),
  );
}

extension NightActionRowMapper on NightActionRow {
  NightAction toEntity() => NightAction(
    id: id,
    nightId: nightId,
    gameId: gameId,
    typeId: type,
    actorPlayerId: actorPlayerId,
    targetPlayerId: targetPlayerId,
    secondaryTargetPlayerId: secondaryTargetPlayerId,
    details: NightAction.decodeDetails(detailsJson),
    orderIndex: orderIndex,
    createdAt: createdAt,
  );
}
