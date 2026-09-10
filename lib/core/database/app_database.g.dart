// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $GamesTable extends Games with TableInfo<$GamesTable, GameRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GamesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 120,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 24),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _winnerCampIdMeta = const VerificationMeta(
    'winnerCampId',
  );
  @override
  late final GeneratedColumn<String> winnerCampId = GeneratedColumn<String>(
    'winner_camp_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _winnerReasonMeta = const VerificationMeta(
    'winnerReason',
  );
  @override
  late final GeneratedColumn<String> winnerReason = GeneratedColumn<String>(
    'winner_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    createdAt,
    updatedAt,
    status,
    isArchived,
    notes,
    winnerCampId,
    winnerReason,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'games';
  @override
  VerificationContext validateIntegrity(
    Insertable<GameRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('winner_camp_id')) {
      context.handle(
        _winnerCampIdMeta,
        winnerCampId.isAcceptableOrUnknown(
          data['winner_camp_id']!,
          _winnerCampIdMeta,
        ),
      );
    }
    if (data.containsKey('winner_reason')) {
      context.handle(
        _winnerReasonMeta,
        winnerReason.isAcceptableOrUnknown(
          data['winner_reason']!,
          _winnerReasonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GameRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GameRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      winnerCampId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}winner_camp_id'],
      ),
      winnerReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}winner_reason'],
      ),
    );
  }

  @override
  $GamesTable createAlias(String alias) {
    return $GamesTable(attachedDatabase, alias);
  }
}

class GameRow extends DataClass implements Insertable<GameRow> {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// `setup` | `inProgress` | `finished` — see `GameStatus`.
  final String status;
  final bool isArchived;
  final String? notes;

  /// Camp that won, once [status] is `finished` — see `VictoryCamp`.
  /// Free-form text on purpose: a future solo role wins under its own role id
  /// without a migration.
  final String? winnerCampId;

  /// The sentence explaining that win, as the narrator read it out.
  final String? winnerReason;
  const GameRow({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    required this.isArchived,
    this.notes,
    this.winnerCampId,
    this.winnerReason,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['status'] = Variable<String>(status);
    map['is_archived'] = Variable<bool>(isArchived);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || winnerCampId != null) {
      map['winner_camp_id'] = Variable<String>(winnerCampId);
    }
    if (!nullToAbsent || winnerReason != null) {
      map['winner_reason'] = Variable<String>(winnerReason);
    }
    return map;
  }

  GamesCompanion toCompanion(bool nullToAbsent) {
    return GamesCompanion(
      id: Value(id),
      name: Value(name),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      status: Value(status),
      isArchived: Value(isArchived),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      winnerCampId: winnerCampId == null && nullToAbsent
          ? const Value.absent()
          : Value(winnerCampId),
      winnerReason: winnerReason == null && nullToAbsent
          ? const Value.absent()
          : Value(winnerReason),
    );
  }

  factory GameRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GameRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      status: serializer.fromJson<String>(json['status']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      notes: serializer.fromJson<String?>(json['notes']),
      winnerCampId: serializer.fromJson<String?>(json['winnerCampId']),
      winnerReason: serializer.fromJson<String?>(json['winnerReason']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'status': serializer.toJson<String>(status),
      'isArchived': serializer.toJson<bool>(isArchived),
      'notes': serializer.toJson<String?>(notes),
      'winnerCampId': serializer.toJson<String?>(winnerCampId),
      'winnerReason': serializer.toJson<String?>(winnerReason),
    };
  }

  GameRow copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? status,
    bool? isArchived,
    Value<String?> notes = const Value.absent(),
    Value<String?> winnerCampId = const Value.absent(),
    Value<String?> winnerReason = const Value.absent(),
  }) => GameRow(
    id: id ?? this.id,
    name: name ?? this.name,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    status: status ?? this.status,
    isArchived: isArchived ?? this.isArchived,
    notes: notes.present ? notes.value : this.notes,
    winnerCampId: winnerCampId.present ? winnerCampId.value : this.winnerCampId,
    winnerReason: winnerReason.present ? winnerReason.value : this.winnerReason,
  );
  GameRow copyWithCompanion(GamesCompanion data) {
    return GameRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      status: data.status.present ? data.status.value : this.status,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      notes: data.notes.present ? data.notes.value : this.notes,
      winnerCampId: data.winnerCampId.present
          ? data.winnerCampId.value
          : this.winnerCampId,
      winnerReason: data.winnerReason.present
          ? data.winnerReason.value
          : this.winnerReason,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GameRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('status: $status, ')
          ..write('isArchived: $isArchived, ')
          ..write('notes: $notes, ')
          ..write('winnerCampId: $winnerCampId, ')
          ..write('winnerReason: $winnerReason')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    createdAt,
    updatedAt,
    status,
    isArchived,
    notes,
    winnerCampId,
    winnerReason,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GameRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.status == this.status &&
          other.isArchived == this.isArchived &&
          other.notes == this.notes &&
          other.winnerCampId == this.winnerCampId &&
          other.winnerReason == this.winnerReason);
}

class GamesCompanion extends UpdateCompanion<GameRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> status;
  final Value<bool> isArchived;
  final Value<String?> notes;
  final Value<String?> winnerCampId;
  final Value<String?> winnerReason;
  final Value<int> rowid;
  const GamesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.status = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.notes = const Value.absent(),
    this.winnerCampId = const Value.absent(),
    this.winnerReason = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GamesCompanion.insert({
    required String id,
    required String name,
    required DateTime createdAt,
    required DateTime updatedAt,
    required String status,
    this.isArchived = const Value.absent(),
    this.notes = const Value.absent(),
    this.winnerCampId = const Value.absent(),
    this.winnerReason = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       status = Value(status);
  static Insertable<GameRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? status,
    Expression<bool>? isArchived,
    Expression<String>? notes,
    Expression<String>? winnerCampId,
    Expression<String>? winnerReason,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (status != null) 'status': status,
      if (isArchived != null) 'is_archived': isArchived,
      if (notes != null) 'notes': notes,
      if (winnerCampId != null) 'winner_camp_id': winnerCampId,
      if (winnerReason != null) 'winner_reason': winnerReason,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GamesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? status,
    Value<bool>? isArchived,
    Value<String?>? notes,
    Value<String?>? winnerCampId,
    Value<String?>? winnerReason,
    Value<int>? rowid,
  }) {
    return GamesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      isArchived: isArchived ?? this.isArchived,
      notes: notes ?? this.notes,
      winnerCampId: winnerCampId ?? this.winnerCampId,
      winnerReason: winnerReason ?? this.winnerReason,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (winnerCampId.present) {
      map['winner_camp_id'] = Variable<String>(winnerCampId.value);
    }
    if (winnerReason.present) {
      map['winner_reason'] = Variable<String>(winnerReason.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GamesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('status: $status, ')
          ..write('isArchived: $isArchived, ')
          ..write('notes: $notes, ')
          ..write('winnerCampId: $winnerCampId, ')
          ..write('winnerReason: $winnerReason, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlayersTable extends Players with TableInfo<$PlayersTable, PlayerRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlayersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gameIdMeta = const VerificationMeta('gameId');
  @override
  late final GeneratedColumn<String> gameId = GeneratedColumn<String>(
    'game_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES games (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 80,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleIdMeta = const VerificationMeta('roleId');
  @override
  late final GeneratedColumn<String> roleId = GeneratedColumn<String>(
    'role_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 40),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seatOrderMeta = const VerificationMeta(
    'seatOrder',
  );
  @override
  late final GeneratedColumn<int> seatOrder = GeneratedColumn<int>(
    'seat_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isAliveMeta = const VerificationMeta(
    'isAlive',
  );
  @override
  late final GeneratedColumn<bool> isAlive = GeneratedColumn<bool>(
    'is_alive',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_alive" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _isCaptainMeta = const VerificationMeta(
    'isCaptain',
  );
  @override
  late final GeneratedColumn<bool> isCaptain = GeneratedColumn<bool>(
    'is_captain',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_captain" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isCharmedMeta = const VerificationMeta(
    'isCharmed',
  );
  @override
  late final GeneratedColumn<bool> isCharmed = GeneratedColumn<bool>(
    'is_charmed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_charmed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _coupledWithPlayerIdMeta =
      const VerificationMeta('coupledWithPlayerId');
  @override
  late final GeneratedColumn<String> coupledWithPlayerId =
      GeneratedColumn<String>(
        'coupled_with_player_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _deathNightNumberMeta = const VerificationMeta(
    'deathNightNumber',
  );
  @override
  late final GeneratedColumn<int> deathNightNumber = GeneratedColumn<int>(
    'death_night_number',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deathCauseMeta = const VerificationMeta(
    'deathCause',
  );
  @override
  late final GeneratedColumn<String> deathCause = GeneratedColumn<String>(
    'death_cause',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    gameId,
    name,
    roleId,
    seatOrder,
    isAlive,
    isCaptain,
    isCharmed,
    coupledWithPlayerId,
    deathNightNumber,
    deathCause,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'players';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlayerRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('game_id')) {
      context.handle(
        _gameIdMeta,
        gameId.isAcceptableOrUnknown(data['game_id']!, _gameIdMeta),
      );
    } else if (isInserting) {
      context.missing(_gameIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('role_id')) {
      context.handle(
        _roleIdMeta,
        roleId.isAcceptableOrUnknown(data['role_id']!, _roleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_roleIdMeta);
    }
    if (data.containsKey('seat_order')) {
      context.handle(
        _seatOrderMeta,
        seatOrder.isAcceptableOrUnknown(data['seat_order']!, _seatOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_seatOrderMeta);
    }
    if (data.containsKey('is_alive')) {
      context.handle(
        _isAliveMeta,
        isAlive.isAcceptableOrUnknown(data['is_alive']!, _isAliveMeta),
      );
    }
    if (data.containsKey('is_captain')) {
      context.handle(
        _isCaptainMeta,
        isCaptain.isAcceptableOrUnknown(data['is_captain']!, _isCaptainMeta),
      );
    }
    if (data.containsKey('is_charmed')) {
      context.handle(
        _isCharmedMeta,
        isCharmed.isAcceptableOrUnknown(data['is_charmed']!, _isCharmedMeta),
      );
    }
    if (data.containsKey('coupled_with_player_id')) {
      context.handle(
        _coupledWithPlayerIdMeta,
        coupledWithPlayerId.isAcceptableOrUnknown(
          data['coupled_with_player_id']!,
          _coupledWithPlayerIdMeta,
        ),
      );
    }
    if (data.containsKey('death_night_number')) {
      context.handle(
        _deathNightNumberMeta,
        deathNightNumber.isAcceptableOrUnknown(
          data['death_night_number']!,
          _deathNightNumberMeta,
        ),
      );
    }
    if (data.containsKey('death_cause')) {
      context.handle(
        _deathCauseMeta,
        deathCause.isAcceptableOrUnknown(data['death_cause']!, _deathCauseMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlayerRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlayerRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      gameId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}game_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      roleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role_id'],
      )!,
      seatOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seat_order'],
      )!,
      isAlive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_alive'],
      )!,
      isCaptain: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_captain'],
      )!,
      isCharmed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_charmed'],
      )!,
      coupledWithPlayerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}coupled_with_player_id'],
      ),
      deathNightNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}death_night_number'],
      ),
      deathCause: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}death_cause'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $PlayersTable createAlias(String alias) {
    return $PlayersTable(attachedDatabase, alias);
  }
}

class PlayerRow extends DataClass implements Insertable<PlayerRow> {
  final String id;
  final String gameId;
  final String name;

  /// Key into the role catalogue (`werewolf`, `seer`, ...), free-form on
  /// purpose so adding a role never requires a schema migration.
  final String roleId;
  final int seatOrder;
  final bool isAlive;

  /// Captain is an elected status that stacks with any role, not a role.
  final bool isCaptain;
  final bool isCharmed;

  /// The other lover. Symmetric: both rows point at each other.
  /// Not declared as a foreign key so the two rows can be written in any order.
  final String? coupledWithPlayerId;
  final int? deathNightNumber;
  final String? deathCause;
  final String? notes;
  const PlayerRow({
    required this.id,
    required this.gameId,
    required this.name,
    required this.roleId,
    required this.seatOrder,
    required this.isAlive,
    required this.isCaptain,
    required this.isCharmed,
    this.coupledWithPlayerId,
    this.deathNightNumber,
    this.deathCause,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['game_id'] = Variable<String>(gameId);
    map['name'] = Variable<String>(name);
    map['role_id'] = Variable<String>(roleId);
    map['seat_order'] = Variable<int>(seatOrder);
    map['is_alive'] = Variable<bool>(isAlive);
    map['is_captain'] = Variable<bool>(isCaptain);
    map['is_charmed'] = Variable<bool>(isCharmed);
    if (!nullToAbsent || coupledWithPlayerId != null) {
      map['coupled_with_player_id'] = Variable<String>(coupledWithPlayerId);
    }
    if (!nullToAbsent || deathNightNumber != null) {
      map['death_night_number'] = Variable<int>(deathNightNumber);
    }
    if (!nullToAbsent || deathCause != null) {
      map['death_cause'] = Variable<String>(deathCause);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  PlayersCompanion toCompanion(bool nullToAbsent) {
    return PlayersCompanion(
      id: Value(id),
      gameId: Value(gameId),
      name: Value(name),
      roleId: Value(roleId),
      seatOrder: Value(seatOrder),
      isAlive: Value(isAlive),
      isCaptain: Value(isCaptain),
      isCharmed: Value(isCharmed),
      coupledWithPlayerId: coupledWithPlayerId == null && nullToAbsent
          ? const Value.absent()
          : Value(coupledWithPlayerId),
      deathNightNumber: deathNightNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(deathNightNumber),
      deathCause: deathCause == null && nullToAbsent
          ? const Value.absent()
          : Value(deathCause),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory PlayerRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlayerRow(
      id: serializer.fromJson<String>(json['id']),
      gameId: serializer.fromJson<String>(json['gameId']),
      name: serializer.fromJson<String>(json['name']),
      roleId: serializer.fromJson<String>(json['roleId']),
      seatOrder: serializer.fromJson<int>(json['seatOrder']),
      isAlive: serializer.fromJson<bool>(json['isAlive']),
      isCaptain: serializer.fromJson<bool>(json['isCaptain']),
      isCharmed: serializer.fromJson<bool>(json['isCharmed']),
      coupledWithPlayerId: serializer.fromJson<String?>(
        json['coupledWithPlayerId'],
      ),
      deathNightNumber: serializer.fromJson<int?>(json['deathNightNumber']),
      deathCause: serializer.fromJson<String?>(json['deathCause']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'gameId': serializer.toJson<String>(gameId),
      'name': serializer.toJson<String>(name),
      'roleId': serializer.toJson<String>(roleId),
      'seatOrder': serializer.toJson<int>(seatOrder),
      'isAlive': serializer.toJson<bool>(isAlive),
      'isCaptain': serializer.toJson<bool>(isCaptain),
      'isCharmed': serializer.toJson<bool>(isCharmed),
      'coupledWithPlayerId': serializer.toJson<String?>(coupledWithPlayerId),
      'deathNightNumber': serializer.toJson<int?>(deathNightNumber),
      'deathCause': serializer.toJson<String?>(deathCause),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  PlayerRow copyWith({
    String? id,
    String? gameId,
    String? name,
    String? roleId,
    int? seatOrder,
    bool? isAlive,
    bool? isCaptain,
    bool? isCharmed,
    Value<String?> coupledWithPlayerId = const Value.absent(),
    Value<int?> deathNightNumber = const Value.absent(),
    Value<String?> deathCause = const Value.absent(),
    Value<String?> notes = const Value.absent(),
  }) => PlayerRow(
    id: id ?? this.id,
    gameId: gameId ?? this.gameId,
    name: name ?? this.name,
    roleId: roleId ?? this.roleId,
    seatOrder: seatOrder ?? this.seatOrder,
    isAlive: isAlive ?? this.isAlive,
    isCaptain: isCaptain ?? this.isCaptain,
    isCharmed: isCharmed ?? this.isCharmed,
    coupledWithPlayerId: coupledWithPlayerId.present
        ? coupledWithPlayerId.value
        : this.coupledWithPlayerId,
    deathNightNumber: deathNightNumber.present
        ? deathNightNumber.value
        : this.deathNightNumber,
    deathCause: deathCause.present ? deathCause.value : this.deathCause,
    notes: notes.present ? notes.value : this.notes,
  );
  PlayerRow copyWithCompanion(PlayersCompanion data) {
    return PlayerRow(
      id: data.id.present ? data.id.value : this.id,
      gameId: data.gameId.present ? data.gameId.value : this.gameId,
      name: data.name.present ? data.name.value : this.name,
      roleId: data.roleId.present ? data.roleId.value : this.roleId,
      seatOrder: data.seatOrder.present ? data.seatOrder.value : this.seatOrder,
      isAlive: data.isAlive.present ? data.isAlive.value : this.isAlive,
      isCaptain: data.isCaptain.present ? data.isCaptain.value : this.isCaptain,
      isCharmed: data.isCharmed.present ? data.isCharmed.value : this.isCharmed,
      coupledWithPlayerId: data.coupledWithPlayerId.present
          ? data.coupledWithPlayerId.value
          : this.coupledWithPlayerId,
      deathNightNumber: data.deathNightNumber.present
          ? data.deathNightNumber.value
          : this.deathNightNumber,
      deathCause: data.deathCause.present
          ? data.deathCause.value
          : this.deathCause,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlayerRow(')
          ..write('id: $id, ')
          ..write('gameId: $gameId, ')
          ..write('name: $name, ')
          ..write('roleId: $roleId, ')
          ..write('seatOrder: $seatOrder, ')
          ..write('isAlive: $isAlive, ')
          ..write('isCaptain: $isCaptain, ')
          ..write('isCharmed: $isCharmed, ')
          ..write('coupledWithPlayerId: $coupledWithPlayerId, ')
          ..write('deathNightNumber: $deathNightNumber, ')
          ..write('deathCause: $deathCause, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    gameId,
    name,
    roleId,
    seatOrder,
    isAlive,
    isCaptain,
    isCharmed,
    coupledWithPlayerId,
    deathNightNumber,
    deathCause,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlayerRow &&
          other.id == this.id &&
          other.gameId == this.gameId &&
          other.name == this.name &&
          other.roleId == this.roleId &&
          other.seatOrder == this.seatOrder &&
          other.isAlive == this.isAlive &&
          other.isCaptain == this.isCaptain &&
          other.isCharmed == this.isCharmed &&
          other.coupledWithPlayerId == this.coupledWithPlayerId &&
          other.deathNightNumber == this.deathNightNumber &&
          other.deathCause == this.deathCause &&
          other.notes == this.notes);
}

class PlayersCompanion extends UpdateCompanion<PlayerRow> {
  final Value<String> id;
  final Value<String> gameId;
  final Value<String> name;
  final Value<String> roleId;
  final Value<int> seatOrder;
  final Value<bool> isAlive;
  final Value<bool> isCaptain;
  final Value<bool> isCharmed;
  final Value<String?> coupledWithPlayerId;
  final Value<int?> deathNightNumber;
  final Value<String?> deathCause;
  final Value<String?> notes;
  final Value<int> rowid;
  const PlayersCompanion({
    this.id = const Value.absent(),
    this.gameId = const Value.absent(),
    this.name = const Value.absent(),
    this.roleId = const Value.absent(),
    this.seatOrder = const Value.absent(),
    this.isAlive = const Value.absent(),
    this.isCaptain = const Value.absent(),
    this.isCharmed = const Value.absent(),
    this.coupledWithPlayerId = const Value.absent(),
    this.deathNightNumber = const Value.absent(),
    this.deathCause = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlayersCompanion.insert({
    required String id,
    required String gameId,
    required String name,
    required String roleId,
    required int seatOrder,
    this.isAlive = const Value.absent(),
    this.isCaptain = const Value.absent(),
    this.isCharmed = const Value.absent(),
    this.coupledWithPlayerId = const Value.absent(),
    this.deathNightNumber = const Value.absent(),
    this.deathCause = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       gameId = Value(gameId),
       name = Value(name),
       roleId = Value(roleId),
       seatOrder = Value(seatOrder);
  static Insertable<PlayerRow> custom({
    Expression<String>? id,
    Expression<String>? gameId,
    Expression<String>? name,
    Expression<String>? roleId,
    Expression<int>? seatOrder,
    Expression<bool>? isAlive,
    Expression<bool>? isCaptain,
    Expression<bool>? isCharmed,
    Expression<String>? coupledWithPlayerId,
    Expression<int>? deathNightNumber,
    Expression<String>? deathCause,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (gameId != null) 'game_id': gameId,
      if (name != null) 'name': name,
      if (roleId != null) 'role_id': roleId,
      if (seatOrder != null) 'seat_order': seatOrder,
      if (isAlive != null) 'is_alive': isAlive,
      if (isCaptain != null) 'is_captain': isCaptain,
      if (isCharmed != null) 'is_charmed': isCharmed,
      if (coupledWithPlayerId != null)
        'coupled_with_player_id': coupledWithPlayerId,
      if (deathNightNumber != null) 'death_night_number': deathNightNumber,
      if (deathCause != null) 'death_cause': deathCause,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlayersCompanion copyWith({
    Value<String>? id,
    Value<String>? gameId,
    Value<String>? name,
    Value<String>? roleId,
    Value<int>? seatOrder,
    Value<bool>? isAlive,
    Value<bool>? isCaptain,
    Value<bool>? isCharmed,
    Value<String?>? coupledWithPlayerId,
    Value<int?>? deathNightNumber,
    Value<String?>? deathCause,
    Value<String?>? notes,
    Value<int>? rowid,
  }) {
    return PlayersCompanion(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      name: name ?? this.name,
      roleId: roleId ?? this.roleId,
      seatOrder: seatOrder ?? this.seatOrder,
      isAlive: isAlive ?? this.isAlive,
      isCaptain: isCaptain ?? this.isCaptain,
      isCharmed: isCharmed ?? this.isCharmed,
      coupledWithPlayerId: coupledWithPlayerId ?? this.coupledWithPlayerId,
      deathNightNumber: deathNightNumber ?? this.deathNightNumber,
      deathCause: deathCause ?? this.deathCause,
      notes: notes ?? this.notes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (gameId.present) {
      map['game_id'] = Variable<String>(gameId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (roleId.present) {
      map['role_id'] = Variable<String>(roleId.value);
    }
    if (seatOrder.present) {
      map['seat_order'] = Variable<int>(seatOrder.value);
    }
    if (isAlive.present) {
      map['is_alive'] = Variable<bool>(isAlive.value);
    }
    if (isCaptain.present) {
      map['is_captain'] = Variable<bool>(isCaptain.value);
    }
    if (isCharmed.present) {
      map['is_charmed'] = Variable<bool>(isCharmed.value);
    }
    if (coupledWithPlayerId.present) {
      map['coupled_with_player_id'] = Variable<String>(
        coupledWithPlayerId.value,
      );
    }
    if (deathNightNumber.present) {
      map['death_night_number'] = Variable<int>(deathNightNumber.value);
    }
    if (deathCause.present) {
      map['death_cause'] = Variable<String>(deathCause.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlayersCompanion(')
          ..write('id: $id, ')
          ..write('gameId: $gameId, ')
          ..write('name: $name, ')
          ..write('roleId: $roleId, ')
          ..write('seatOrder: $seatOrder, ')
          ..write('isAlive: $isAlive, ')
          ..write('isCaptain: $isCaptain, ')
          ..write('isCharmed: $isCharmed, ')
          ..write('coupledWithPlayerId: $coupledWithPlayerId, ')
          ..write('deathNightNumber: $deathNightNumber, ')
          ..write('deathCause: $deathCause, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NightsTable extends Nights with TableInfo<$NightsTable, NightRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NightsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gameIdMeta = const VerificationMeta('gameId');
  @override
  late final GeneratedColumn<String> gameId = GeneratedColumn<String>(
    'game_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES games (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nightNumberMeta = const VerificationMeta(
    'nightNumber',
  );
  @override
  late final GeneratedColumn<int> nightNumber = GeneratedColumn<int>(
    'night_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _resolvedAtMeta = const VerificationMeta(
    'resolvedAt',
  );
  @override
  late final GeneratedColumn<DateTime> resolvedAt = GeneratedColumn<DateTime>(
    'resolved_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _summaryJsonMeta = const VerificationMeta(
    'summaryJson',
  );
  @override
  late final GeneratedColumn<String> summaryJson = GeneratedColumn<String>(
    'summary_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    gameId,
    nightNumber,
    createdAt,
    resolvedAt,
    summaryJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'nights';
  @override
  VerificationContext validateIntegrity(
    Insertable<NightRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('game_id')) {
      context.handle(
        _gameIdMeta,
        gameId.isAcceptableOrUnknown(data['game_id']!, _gameIdMeta),
      );
    } else if (isInserting) {
      context.missing(_gameIdMeta);
    }
    if (data.containsKey('night_number')) {
      context.handle(
        _nightNumberMeta,
        nightNumber.isAcceptableOrUnknown(
          data['night_number']!,
          _nightNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nightNumberMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('resolved_at')) {
      context.handle(
        _resolvedAtMeta,
        resolvedAt.isAcceptableOrUnknown(data['resolved_at']!, _resolvedAtMeta),
      );
    }
    if (data.containsKey('summary_json')) {
      context.handle(
        _summaryJsonMeta,
        summaryJson.isAcceptableOrUnknown(
          data['summary_json']!,
          _summaryJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {gameId, nightNumber},
  ];
  @override
  NightRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NightRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      gameId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}game_id'],
      )!,
      nightNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}night_number'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      resolvedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}resolved_at'],
      ),
      summaryJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary_json'],
      ),
    );
  }

  @override
  $NightsTable createAlias(String alias) {
    return $NightsTable(attachedDatabase, alias);
  }
}

class NightRow extends DataClass implements Insertable<NightRow> {
  final String id;
  final String gameId;
  final int nightNumber;
  final DateTime createdAt;

  /// Non-null once the narrator closed the night; actions are then frozen.
  final DateTime? resolvedAt;

  /// Serialised `NightOutcome`, stored so past nights render without replaying
  /// the resolver against a player state that has since moved on.
  final String? summaryJson;
  const NightRow({
    required this.id,
    required this.gameId,
    required this.nightNumber,
    required this.createdAt,
    this.resolvedAt,
    this.summaryJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['game_id'] = Variable<String>(gameId);
    map['night_number'] = Variable<int>(nightNumber);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || resolvedAt != null) {
      map['resolved_at'] = Variable<DateTime>(resolvedAt);
    }
    if (!nullToAbsent || summaryJson != null) {
      map['summary_json'] = Variable<String>(summaryJson);
    }
    return map;
  }

  NightsCompanion toCompanion(bool nullToAbsent) {
    return NightsCompanion(
      id: Value(id),
      gameId: Value(gameId),
      nightNumber: Value(nightNumber),
      createdAt: Value(createdAt),
      resolvedAt: resolvedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(resolvedAt),
      summaryJson: summaryJson == null && nullToAbsent
          ? const Value.absent()
          : Value(summaryJson),
    );
  }

  factory NightRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NightRow(
      id: serializer.fromJson<String>(json['id']),
      gameId: serializer.fromJson<String>(json['gameId']),
      nightNumber: serializer.fromJson<int>(json['nightNumber']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      resolvedAt: serializer.fromJson<DateTime?>(json['resolvedAt']),
      summaryJson: serializer.fromJson<String?>(json['summaryJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'gameId': serializer.toJson<String>(gameId),
      'nightNumber': serializer.toJson<int>(nightNumber),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'resolvedAt': serializer.toJson<DateTime?>(resolvedAt),
      'summaryJson': serializer.toJson<String?>(summaryJson),
    };
  }

  NightRow copyWith({
    String? id,
    String? gameId,
    int? nightNumber,
    DateTime? createdAt,
    Value<DateTime?> resolvedAt = const Value.absent(),
    Value<String?> summaryJson = const Value.absent(),
  }) => NightRow(
    id: id ?? this.id,
    gameId: gameId ?? this.gameId,
    nightNumber: nightNumber ?? this.nightNumber,
    createdAt: createdAt ?? this.createdAt,
    resolvedAt: resolvedAt.present ? resolvedAt.value : this.resolvedAt,
    summaryJson: summaryJson.present ? summaryJson.value : this.summaryJson,
  );
  NightRow copyWithCompanion(NightsCompanion data) {
    return NightRow(
      id: data.id.present ? data.id.value : this.id,
      gameId: data.gameId.present ? data.gameId.value : this.gameId,
      nightNumber: data.nightNumber.present
          ? data.nightNumber.value
          : this.nightNumber,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      resolvedAt: data.resolvedAt.present
          ? data.resolvedAt.value
          : this.resolvedAt,
      summaryJson: data.summaryJson.present
          ? data.summaryJson.value
          : this.summaryJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NightRow(')
          ..write('id: $id, ')
          ..write('gameId: $gameId, ')
          ..write('nightNumber: $nightNumber, ')
          ..write('createdAt: $createdAt, ')
          ..write('resolvedAt: $resolvedAt, ')
          ..write('summaryJson: $summaryJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, gameId, nightNumber, createdAt, resolvedAt, summaryJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NightRow &&
          other.id == this.id &&
          other.gameId == this.gameId &&
          other.nightNumber == this.nightNumber &&
          other.createdAt == this.createdAt &&
          other.resolvedAt == this.resolvedAt &&
          other.summaryJson == this.summaryJson);
}

class NightsCompanion extends UpdateCompanion<NightRow> {
  final Value<String> id;
  final Value<String> gameId;
  final Value<int> nightNumber;
  final Value<DateTime> createdAt;
  final Value<DateTime?> resolvedAt;
  final Value<String?> summaryJson;
  final Value<int> rowid;
  const NightsCompanion({
    this.id = const Value.absent(),
    this.gameId = const Value.absent(),
    this.nightNumber = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.resolvedAt = const Value.absent(),
    this.summaryJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NightsCompanion.insert({
    required String id,
    required String gameId,
    required int nightNumber,
    required DateTime createdAt,
    this.resolvedAt = const Value.absent(),
    this.summaryJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       gameId = Value(gameId),
       nightNumber = Value(nightNumber),
       createdAt = Value(createdAt);
  static Insertable<NightRow> custom({
    Expression<String>? id,
    Expression<String>? gameId,
    Expression<int>? nightNumber,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? resolvedAt,
    Expression<String>? summaryJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (gameId != null) 'game_id': gameId,
      if (nightNumber != null) 'night_number': nightNumber,
      if (createdAt != null) 'created_at': createdAt,
      if (resolvedAt != null) 'resolved_at': resolvedAt,
      if (summaryJson != null) 'summary_json': summaryJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NightsCompanion copyWith({
    Value<String>? id,
    Value<String>? gameId,
    Value<int>? nightNumber,
    Value<DateTime>? createdAt,
    Value<DateTime?>? resolvedAt,
    Value<String?>? summaryJson,
    Value<int>? rowid,
  }) {
    return NightsCompanion(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      nightNumber: nightNumber ?? this.nightNumber,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      summaryJson: summaryJson ?? this.summaryJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (gameId.present) {
      map['game_id'] = Variable<String>(gameId.value);
    }
    if (nightNumber.present) {
      map['night_number'] = Variable<int>(nightNumber.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (resolvedAt.present) {
      map['resolved_at'] = Variable<DateTime>(resolvedAt.value);
    }
    if (summaryJson.present) {
      map['summary_json'] = Variable<String>(summaryJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NightsCompanion(')
          ..write('id: $id, ')
          ..write('gameId: $gameId, ')
          ..write('nightNumber: $nightNumber, ')
          ..write('createdAt: $createdAt, ')
          ..write('resolvedAt: $resolvedAt, ')
          ..write('summaryJson: $summaryJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NightActionsTable extends NightActions
    with TableInfo<$NightActionsTable, NightActionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NightActionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nightIdMeta = const VerificationMeta(
    'nightId',
  );
  @override
  late final GeneratedColumn<String> nightId = GeneratedColumn<String>(
    'night_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES nights (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _gameIdMeta = const VerificationMeta('gameId');
  @override
  late final GeneratedColumn<String> gameId = GeneratedColumn<String>(
    'game_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 40),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actorPlayerIdMeta = const VerificationMeta(
    'actorPlayerId',
  );
  @override
  late final GeneratedColumn<String> actorPlayerId = GeneratedColumn<String>(
    'actor_player_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetPlayerIdMeta = const VerificationMeta(
    'targetPlayerId',
  );
  @override
  late final GeneratedColumn<String> targetPlayerId = GeneratedColumn<String>(
    'target_player_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _secondaryTargetPlayerIdMeta =
      const VerificationMeta('secondaryTargetPlayerId');
  @override
  late final GeneratedColumn<String> secondaryTargetPlayerId =
      GeneratedColumn<String>(
        'secondary_target_player_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _detailsJsonMeta = const VerificationMeta(
    'detailsJson',
  );
  @override
  late final GeneratedColumn<String> detailsJson = GeneratedColumn<String>(
    'details_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _orderIndexMeta = const VerificationMeta(
    'orderIndex',
  );
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
    'order_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    nightId,
    gameId,
    type,
    actorPlayerId,
    targetPlayerId,
    secondaryTargetPlayerId,
    detailsJson,
    orderIndex,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'night_actions';
  @override
  VerificationContext validateIntegrity(
    Insertable<NightActionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('night_id')) {
      context.handle(
        _nightIdMeta,
        nightId.isAcceptableOrUnknown(data['night_id']!, _nightIdMeta),
      );
    } else if (isInserting) {
      context.missing(_nightIdMeta);
    }
    if (data.containsKey('game_id')) {
      context.handle(
        _gameIdMeta,
        gameId.isAcceptableOrUnknown(data['game_id']!, _gameIdMeta),
      );
    } else if (isInserting) {
      context.missing(_gameIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('actor_player_id')) {
      context.handle(
        _actorPlayerIdMeta,
        actorPlayerId.isAcceptableOrUnknown(
          data['actor_player_id']!,
          _actorPlayerIdMeta,
        ),
      );
    }
    if (data.containsKey('target_player_id')) {
      context.handle(
        _targetPlayerIdMeta,
        targetPlayerId.isAcceptableOrUnknown(
          data['target_player_id']!,
          _targetPlayerIdMeta,
        ),
      );
    }
    if (data.containsKey('secondary_target_player_id')) {
      context.handle(
        _secondaryTargetPlayerIdMeta,
        secondaryTargetPlayerId.isAcceptableOrUnknown(
          data['secondary_target_player_id']!,
          _secondaryTargetPlayerIdMeta,
        ),
      );
    }
    if (data.containsKey('details_json')) {
      context.handle(
        _detailsJsonMeta,
        detailsJson.isAcceptableOrUnknown(
          data['details_json']!,
          _detailsJsonMeta,
        ),
      );
    }
    if (data.containsKey('order_index')) {
      context.handle(
        _orderIndexMeta,
        orderIndex.isAcceptableOrUnknown(data['order_index']!, _orderIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_orderIndexMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NightActionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NightActionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      nightId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}night_id'],
      )!,
      gameId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}game_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      actorPlayerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actor_player_id'],
      ),
      targetPlayerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_player_id'],
      ),
      secondaryTargetPlayerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}secondary_target_player_id'],
      ),
      detailsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}details_json'],
      ),
      orderIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_index'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $NightActionsTable createAlias(String alias) {
    return $NightActionsTable(attachedDatabase, alias);
  }
}

class NightActionRow extends DataClass implements Insertable<NightActionRow> {
  final String id;
  final String nightId;

  /// Denormalised so the full history of a game is one indexed query.
  final String gameId;

  /// Key into the action catalogue — see `NightActionType`.
  final String type;
  final String? actorPlayerId;
  final String? targetPlayerId;
  final String? secondaryTargetPlayerId;

  /// Free-form payload, e.g. the role the seer discovered.
  final String? detailsJson;
  final int orderIndex;
  final DateTime createdAt;
  const NightActionRow({
    required this.id,
    required this.nightId,
    required this.gameId,
    required this.type,
    this.actorPlayerId,
    this.targetPlayerId,
    this.secondaryTargetPlayerId,
    this.detailsJson,
    required this.orderIndex,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['night_id'] = Variable<String>(nightId);
    map['game_id'] = Variable<String>(gameId);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || actorPlayerId != null) {
      map['actor_player_id'] = Variable<String>(actorPlayerId);
    }
    if (!nullToAbsent || targetPlayerId != null) {
      map['target_player_id'] = Variable<String>(targetPlayerId);
    }
    if (!nullToAbsent || secondaryTargetPlayerId != null) {
      map['secondary_target_player_id'] = Variable<String>(
        secondaryTargetPlayerId,
      );
    }
    if (!nullToAbsent || detailsJson != null) {
      map['details_json'] = Variable<String>(detailsJson);
    }
    map['order_index'] = Variable<int>(orderIndex);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  NightActionsCompanion toCompanion(bool nullToAbsent) {
    return NightActionsCompanion(
      id: Value(id),
      nightId: Value(nightId),
      gameId: Value(gameId),
      type: Value(type),
      actorPlayerId: actorPlayerId == null && nullToAbsent
          ? const Value.absent()
          : Value(actorPlayerId),
      targetPlayerId: targetPlayerId == null && nullToAbsent
          ? const Value.absent()
          : Value(targetPlayerId),
      secondaryTargetPlayerId: secondaryTargetPlayerId == null && nullToAbsent
          ? const Value.absent()
          : Value(secondaryTargetPlayerId),
      detailsJson: detailsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(detailsJson),
      orderIndex: Value(orderIndex),
      createdAt: Value(createdAt),
    );
  }

  factory NightActionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NightActionRow(
      id: serializer.fromJson<String>(json['id']),
      nightId: serializer.fromJson<String>(json['nightId']),
      gameId: serializer.fromJson<String>(json['gameId']),
      type: serializer.fromJson<String>(json['type']),
      actorPlayerId: serializer.fromJson<String?>(json['actorPlayerId']),
      targetPlayerId: serializer.fromJson<String?>(json['targetPlayerId']),
      secondaryTargetPlayerId: serializer.fromJson<String?>(
        json['secondaryTargetPlayerId'],
      ),
      detailsJson: serializer.fromJson<String?>(json['detailsJson']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'nightId': serializer.toJson<String>(nightId),
      'gameId': serializer.toJson<String>(gameId),
      'type': serializer.toJson<String>(type),
      'actorPlayerId': serializer.toJson<String?>(actorPlayerId),
      'targetPlayerId': serializer.toJson<String?>(targetPlayerId),
      'secondaryTargetPlayerId': serializer.toJson<String?>(
        secondaryTargetPlayerId,
      ),
      'detailsJson': serializer.toJson<String?>(detailsJson),
      'orderIndex': serializer.toJson<int>(orderIndex),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  NightActionRow copyWith({
    String? id,
    String? nightId,
    String? gameId,
    String? type,
    Value<String?> actorPlayerId = const Value.absent(),
    Value<String?> targetPlayerId = const Value.absent(),
    Value<String?> secondaryTargetPlayerId = const Value.absent(),
    Value<String?> detailsJson = const Value.absent(),
    int? orderIndex,
    DateTime? createdAt,
  }) => NightActionRow(
    id: id ?? this.id,
    nightId: nightId ?? this.nightId,
    gameId: gameId ?? this.gameId,
    type: type ?? this.type,
    actorPlayerId: actorPlayerId.present
        ? actorPlayerId.value
        : this.actorPlayerId,
    targetPlayerId: targetPlayerId.present
        ? targetPlayerId.value
        : this.targetPlayerId,
    secondaryTargetPlayerId: secondaryTargetPlayerId.present
        ? secondaryTargetPlayerId.value
        : this.secondaryTargetPlayerId,
    detailsJson: detailsJson.present ? detailsJson.value : this.detailsJson,
    orderIndex: orderIndex ?? this.orderIndex,
    createdAt: createdAt ?? this.createdAt,
  );
  NightActionRow copyWithCompanion(NightActionsCompanion data) {
    return NightActionRow(
      id: data.id.present ? data.id.value : this.id,
      nightId: data.nightId.present ? data.nightId.value : this.nightId,
      gameId: data.gameId.present ? data.gameId.value : this.gameId,
      type: data.type.present ? data.type.value : this.type,
      actorPlayerId: data.actorPlayerId.present
          ? data.actorPlayerId.value
          : this.actorPlayerId,
      targetPlayerId: data.targetPlayerId.present
          ? data.targetPlayerId.value
          : this.targetPlayerId,
      secondaryTargetPlayerId: data.secondaryTargetPlayerId.present
          ? data.secondaryTargetPlayerId.value
          : this.secondaryTargetPlayerId,
      detailsJson: data.detailsJson.present
          ? data.detailsJson.value
          : this.detailsJson,
      orderIndex: data.orderIndex.present
          ? data.orderIndex.value
          : this.orderIndex,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NightActionRow(')
          ..write('id: $id, ')
          ..write('nightId: $nightId, ')
          ..write('gameId: $gameId, ')
          ..write('type: $type, ')
          ..write('actorPlayerId: $actorPlayerId, ')
          ..write('targetPlayerId: $targetPlayerId, ')
          ..write('secondaryTargetPlayerId: $secondaryTargetPlayerId, ')
          ..write('detailsJson: $detailsJson, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    nightId,
    gameId,
    type,
    actorPlayerId,
    targetPlayerId,
    secondaryTargetPlayerId,
    detailsJson,
    orderIndex,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NightActionRow &&
          other.id == this.id &&
          other.nightId == this.nightId &&
          other.gameId == this.gameId &&
          other.type == this.type &&
          other.actorPlayerId == this.actorPlayerId &&
          other.targetPlayerId == this.targetPlayerId &&
          other.secondaryTargetPlayerId == this.secondaryTargetPlayerId &&
          other.detailsJson == this.detailsJson &&
          other.orderIndex == this.orderIndex &&
          other.createdAt == this.createdAt);
}

class NightActionsCompanion extends UpdateCompanion<NightActionRow> {
  final Value<String> id;
  final Value<String> nightId;
  final Value<String> gameId;
  final Value<String> type;
  final Value<String?> actorPlayerId;
  final Value<String?> targetPlayerId;
  final Value<String?> secondaryTargetPlayerId;
  final Value<String?> detailsJson;
  final Value<int> orderIndex;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const NightActionsCompanion({
    this.id = const Value.absent(),
    this.nightId = const Value.absent(),
    this.gameId = const Value.absent(),
    this.type = const Value.absent(),
    this.actorPlayerId = const Value.absent(),
    this.targetPlayerId = const Value.absent(),
    this.secondaryTargetPlayerId = const Value.absent(),
    this.detailsJson = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NightActionsCompanion.insert({
    required String id,
    required String nightId,
    required String gameId,
    required String type,
    this.actorPlayerId = const Value.absent(),
    this.targetPlayerId = const Value.absent(),
    this.secondaryTargetPlayerId = const Value.absent(),
    this.detailsJson = const Value.absent(),
    required int orderIndex,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       nightId = Value(nightId),
       gameId = Value(gameId),
       type = Value(type),
       orderIndex = Value(orderIndex),
       createdAt = Value(createdAt);
  static Insertable<NightActionRow> custom({
    Expression<String>? id,
    Expression<String>? nightId,
    Expression<String>? gameId,
    Expression<String>? type,
    Expression<String>? actorPlayerId,
    Expression<String>? targetPlayerId,
    Expression<String>? secondaryTargetPlayerId,
    Expression<String>? detailsJson,
    Expression<int>? orderIndex,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nightId != null) 'night_id': nightId,
      if (gameId != null) 'game_id': gameId,
      if (type != null) 'type': type,
      if (actorPlayerId != null) 'actor_player_id': actorPlayerId,
      if (targetPlayerId != null) 'target_player_id': targetPlayerId,
      if (secondaryTargetPlayerId != null)
        'secondary_target_player_id': secondaryTargetPlayerId,
      if (detailsJson != null) 'details_json': detailsJson,
      if (orderIndex != null) 'order_index': orderIndex,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NightActionsCompanion copyWith({
    Value<String>? id,
    Value<String>? nightId,
    Value<String>? gameId,
    Value<String>? type,
    Value<String?>? actorPlayerId,
    Value<String?>? targetPlayerId,
    Value<String?>? secondaryTargetPlayerId,
    Value<String?>? detailsJson,
    Value<int>? orderIndex,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return NightActionsCompanion(
      id: id ?? this.id,
      nightId: nightId ?? this.nightId,
      gameId: gameId ?? this.gameId,
      type: type ?? this.type,
      actorPlayerId: actorPlayerId ?? this.actorPlayerId,
      targetPlayerId: targetPlayerId ?? this.targetPlayerId,
      secondaryTargetPlayerId:
          secondaryTargetPlayerId ?? this.secondaryTargetPlayerId,
      detailsJson: detailsJson ?? this.detailsJson,
      orderIndex: orderIndex ?? this.orderIndex,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (nightId.present) {
      map['night_id'] = Variable<String>(nightId.value);
    }
    if (gameId.present) {
      map['game_id'] = Variable<String>(gameId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (actorPlayerId.present) {
      map['actor_player_id'] = Variable<String>(actorPlayerId.value);
    }
    if (targetPlayerId.present) {
      map['target_player_id'] = Variable<String>(targetPlayerId.value);
    }
    if (secondaryTargetPlayerId.present) {
      map['secondary_target_player_id'] = Variable<String>(
        secondaryTargetPlayerId.value,
      );
    }
    if (detailsJson.present) {
      map['details_json'] = Variable<String>(detailsJson.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NightActionsCompanion(')
          ..write('id: $id, ')
          ..write('nightId: $nightId, ')
          ..write('gameId: $gameId, ')
          ..write('type: $type, ')
          ..write('actorPlayerId: $actorPlayerId, ')
          ..write('targetPlayerId: $targetPlayerId, ')
          ..write('secondaryTargetPlayerId: $secondaryTargetPlayerId, ')
          ..write('detailsJson: $detailsJson, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $GamesTable games = $GamesTable(this);
  late final $PlayersTable players = $PlayersTable(this);
  late final $NightsTable nights = $NightsTable(this);
  late final $NightActionsTable nightActions = $NightActionsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    games,
    players,
    nights,
    nightActions,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'games',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('players', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'games',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('nights', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'nights',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('night_actions', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$GamesTableCreateCompanionBuilder = GamesCompanion Function({
  required String id,
  required String name,
  required DateTime createdAt,
  required DateTime updatedAt,
  required String status,
  Value<bool> isArchived,
  Value<String?> notes,
  Value<String?> winnerCampId,
  Value<String?> winnerReason,
  Value<int> rowid,
});
typedef $$GamesTableUpdateCompanionBuilder = GamesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<String> status,
  Value<bool> isArchived,
  Value<String?> notes,
  Value<String?> winnerCampId,
  Value<String?> winnerReason,
  Value<int> rowid,
});

final class $$GamesTableReferences
    extends BaseReferences<_$AppDatabase, $GamesTable, GameRow> {
  $$GamesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PlayersTable, List<PlayerRow>> _playersRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.players,
    aliasName: 'games__id__players__game_id',
  );

  $$PlayersTableProcessedTableManager get playersRefs {
    final manager = $$PlayersTableTableManager(
      $_db,
      $_db.players,
    ).filter((f) => f.gameId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_playersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$NightsTable, List<NightRow>> _nightsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.nights,
    aliasName: 'games__id__nights__game_id',
  );

  $$NightsTableProcessedTableManager get nightsRefs {
    final manager = $$NightsTableTableManager(
      $_db,
      $_db.nights,
    ).filter((f) => f.gameId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_nightsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$GamesTableFilterComposer extends Composer<_$AppDatabase, $GamesTable> {
  $$GamesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get winnerCampId => $composableBuilder(
    column: $table.winnerCampId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get winnerReason => $composableBuilder(
    column: $table.winnerReason,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> playersRefs(
    Expression<bool> Function($$PlayersTableFilterComposer f) f,
  ) {
    final $$PlayersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.gameId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableFilterComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> nightsRefs(
    Expression<bool> Function($$NightsTableFilterComposer f) f,
  ) {
    final $$NightsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.nights,
      getReferencedColumn: (t) => t.gameId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NightsTableFilterComposer(
            $db: $db,
            $table: $db.nights,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$GamesTableOrderingComposer
    extends Composer<_$AppDatabase, $GamesTable> {
  $$GamesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get winnerCampId => $composableBuilder(
    column: $table.winnerCampId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get winnerReason => $composableBuilder(
    column: $table.winnerReason,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GamesTableAnnotationComposer
    extends Composer<_$AppDatabase, $GamesTable> {
  $$GamesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get winnerCampId => $composableBuilder(
    column: $table.winnerCampId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get winnerReason => $composableBuilder(
    column: $table.winnerReason,
    builder: (column) => column,
  );

  Expression<T> playersRefs<T extends Object>(
    Expression<T> Function($$PlayersTableAnnotationComposer a) f,
  ) {
    final $$PlayersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.gameId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableAnnotationComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> nightsRefs<T extends Object>(
    Expression<T> Function($$NightsTableAnnotationComposer a) f,
  ) {
    final $$NightsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.nights,
      getReferencedColumn: (t) => t.gameId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NightsTableAnnotationComposer(
            $db: $db,
            $table: $db.nights,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$GamesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GamesTable,
          GameRow,
          $$GamesTableFilterComposer,
          $$GamesTableOrderingComposer,
          $$GamesTableAnnotationComposer,
          $$GamesTableCreateCompanionBuilder,
          $$GamesTableUpdateCompanionBuilder,
          (GameRow, $$GamesTableReferences),
          GameRow,
          PrefetchHooks Function({bool playersRefs, bool nightsRefs})
        > {
  $$GamesTableTableManager(_$AppDatabase db, $GamesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GamesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GamesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GamesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> winnerCampId = const Value.absent(),
                Value<String?> winnerReason = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GamesCompanion(
                id: id,
                name: name,
                createdAt: createdAt,
                updatedAt: updatedAt,
                status: status,
                isArchived: isArchived,
                notes: notes,
                winnerCampId: winnerCampId,
                winnerReason: winnerReason,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required DateTime createdAt,
                required DateTime updatedAt,
                required String status,
                Value<bool> isArchived = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> winnerCampId = const Value.absent(),
                Value<String?> winnerReason = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GamesCompanion.insert(
                id: id,
                name: name,
                createdAt: createdAt,
                updatedAt: updatedAt,
                status: status,
                isArchived: isArchived,
                notes: notes,
                winnerCampId: winnerCampId,
                winnerReason: winnerReason,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$GamesTable, GameRow>(table),
                  $$GamesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({playersRefs = false, nightsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (playersRefs) db.players,
                if (nightsRefs) db.nights,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (playersRefs)
                    await $_getPrefetchedData<GameRow, $GamesTable, PlayerRow>(
                      currentTable: table,
                      referencedTable: $$GamesTableReferences._playersRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$GamesTableReferences(db, table, p0).playersRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.gameId == item.id),
                      typedResults: items,
                    ),
                  if (nightsRefs)
                    await $_getPrefetchedData<GameRow, $GamesTable, NightRow>(
                      currentTable: table,
                      referencedTable: $$GamesTableReferences._nightsRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$GamesTableReferences(db, table, p0).nightsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.gameId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$GamesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GamesTable,
      GameRow,
      $$GamesTableFilterComposer,
      $$GamesTableOrderingComposer,
      $$GamesTableAnnotationComposer,
      $$GamesTableCreateCompanionBuilder,
      $$GamesTableUpdateCompanionBuilder,
      (GameRow, $$GamesTableReferences),
      GameRow,
      PrefetchHooks Function({bool playersRefs, bool nightsRefs})
    >;
typedef $$PlayersTableCreateCompanionBuilder = PlayersCompanion Function({
  required String id,
  required String gameId,
  required String name,
  required String roleId,
  required int seatOrder,
  Value<bool> isAlive,
  Value<bool> isCaptain,
  Value<bool> isCharmed,
  Value<String?> coupledWithPlayerId,
  Value<int?> deathNightNumber,
  Value<String?> deathCause,
  Value<String?> notes,
  Value<int> rowid,
});
typedef $$PlayersTableUpdateCompanionBuilder = PlayersCompanion Function({
  Value<String> id,
  Value<String> gameId,
  Value<String> name,
  Value<String> roleId,
  Value<int> seatOrder,
  Value<bool> isAlive,
  Value<bool> isCaptain,
  Value<bool> isCharmed,
  Value<String?> coupledWithPlayerId,
  Value<int?> deathNightNumber,
  Value<String?> deathCause,
  Value<String?> notes,
  Value<int> rowid,
});

final class $$PlayersTableReferences
    extends BaseReferences<_$AppDatabase, $PlayersTable, PlayerRow> {
  $$PlayersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $GamesTable _gameIdTable(_$AppDatabase db) =>
      db.games.createAlias('players__game_id__games__id');

  $$GamesTableProcessedTableManager get gameId {
    final $_column = $_itemColumn<String>('game_id')!;

    final manager = $$GamesTableTableManager(
      $_db,
      $_db.games,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_gameIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PlayersTableFilterComposer
    extends Composer<_$AppDatabase, $PlayersTable> {
  $$PlayersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get roleId => $composableBuilder(
    column: $table.roleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seatOrder => $composableBuilder(
    column: $table.seatOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAlive => $composableBuilder(
    column: $table.isAlive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCaptain => $composableBuilder(
    column: $table.isCaptain,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCharmed => $composableBuilder(
    column: $table.isCharmed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coupledWithPlayerId => $composableBuilder(
    column: $table.coupledWithPlayerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deathNightNumber => $composableBuilder(
    column: $table.deathNightNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deathCause => $composableBuilder(
    column: $table.deathCause,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  $$GamesTableFilterComposer get gameId {
    final $$GamesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableFilterComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlayersTableOrderingComposer
    extends Composer<_$AppDatabase, $PlayersTable> {
  $$PlayersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get roleId => $composableBuilder(
    column: $table.roleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seatOrder => $composableBuilder(
    column: $table.seatOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAlive => $composableBuilder(
    column: $table.isAlive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCaptain => $composableBuilder(
    column: $table.isCaptain,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCharmed => $composableBuilder(
    column: $table.isCharmed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coupledWithPlayerId => $composableBuilder(
    column: $table.coupledWithPlayerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deathNightNumber => $composableBuilder(
    column: $table.deathNightNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deathCause => $composableBuilder(
    column: $table.deathCause,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  $$GamesTableOrderingComposer get gameId {
    final $$GamesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableOrderingComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlayersTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlayersTable> {
  $$PlayersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get roleId =>
      $composableBuilder(column: $table.roleId, builder: (column) => column);

  GeneratedColumn<int> get seatOrder =>
      $composableBuilder(column: $table.seatOrder, builder: (column) => column);

  GeneratedColumn<bool> get isAlive =>
      $composableBuilder(column: $table.isAlive, builder: (column) => column);

  GeneratedColumn<bool> get isCaptain =>
      $composableBuilder(column: $table.isCaptain, builder: (column) => column);

  GeneratedColumn<bool> get isCharmed =>
      $composableBuilder(column: $table.isCharmed, builder: (column) => column);

  GeneratedColumn<String> get coupledWithPlayerId => $composableBuilder(
    column: $table.coupledWithPlayerId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get deathNightNumber => $composableBuilder(
    column: $table.deathNightNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deathCause => $composableBuilder(
    column: $table.deathCause,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  $$GamesTableAnnotationComposer get gameId {
    final $$GamesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableAnnotationComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlayersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlayersTable,
          PlayerRow,
          $$PlayersTableFilterComposer,
          $$PlayersTableOrderingComposer,
          $$PlayersTableAnnotationComposer,
          $$PlayersTableCreateCompanionBuilder,
          $$PlayersTableUpdateCompanionBuilder,
          (PlayerRow, $$PlayersTableReferences),
          PlayerRow,
          PrefetchHooks Function({bool gameId})
        > {
  $$PlayersTableTableManager(_$AppDatabase db, $PlayersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlayersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlayersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlayersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> gameId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> roleId = const Value.absent(),
                Value<int> seatOrder = const Value.absent(),
                Value<bool> isAlive = const Value.absent(),
                Value<bool> isCaptain = const Value.absent(),
                Value<bool> isCharmed = const Value.absent(),
                Value<String?> coupledWithPlayerId = const Value.absent(),
                Value<int?> deathNightNumber = const Value.absent(),
                Value<String?> deathCause = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlayersCompanion(
                id: id,
                gameId: gameId,
                name: name,
                roleId: roleId,
                seatOrder: seatOrder,
                isAlive: isAlive,
                isCaptain: isCaptain,
                isCharmed: isCharmed,
                coupledWithPlayerId: coupledWithPlayerId,
                deathNightNumber: deathNightNumber,
                deathCause: deathCause,
                notes: notes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String gameId,
                required String name,
                required String roleId,
                required int seatOrder,
                Value<bool> isAlive = const Value.absent(),
                Value<bool> isCaptain = const Value.absent(),
                Value<bool> isCharmed = const Value.absent(),
                Value<String?> coupledWithPlayerId = const Value.absent(),
                Value<int?> deathNightNumber = const Value.absent(),
                Value<String?> deathCause = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlayersCompanion.insert(
                id: id,
                gameId: gameId,
                name: name,
                roleId: roleId,
                seatOrder: seatOrder,
                isAlive: isAlive,
                isCaptain: isCaptain,
                isCharmed: isCharmed,
                coupledWithPlayerId: coupledWithPlayerId,
                deathNightNumber: deathNightNumber,
                deathCause: deathCause,
                notes: notes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlayersTable, PlayerRow>(table),
                  $$PlayersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({gameId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (gameId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.gameId,
                        referencedTable: $$PlayersTableReferences._gameIdTable(
                          db,
                        ),
                        referencedColumn: $$PlayersTableReferences
                            ._gameIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PlayersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlayersTable,
      PlayerRow,
      $$PlayersTableFilterComposer,
      $$PlayersTableOrderingComposer,
      $$PlayersTableAnnotationComposer,
      $$PlayersTableCreateCompanionBuilder,
      $$PlayersTableUpdateCompanionBuilder,
      (PlayerRow, $$PlayersTableReferences),
      PlayerRow,
      PrefetchHooks Function({bool gameId})
    >;
typedef $$NightsTableCreateCompanionBuilder = NightsCompanion Function({
  required String id,
  required String gameId,
  required int nightNumber,
  required DateTime createdAt,
  Value<DateTime?> resolvedAt,
  Value<String?> summaryJson,
  Value<int> rowid,
});
typedef $$NightsTableUpdateCompanionBuilder = NightsCompanion Function({
  Value<String> id,
  Value<String> gameId,
  Value<int> nightNumber,
  Value<DateTime> createdAt,
  Value<DateTime?> resolvedAt,
  Value<String?> summaryJson,
  Value<int> rowid,
});

final class $$NightsTableReferences
    extends BaseReferences<_$AppDatabase, $NightsTable, NightRow> {
  $$NightsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $GamesTable _gameIdTable(_$AppDatabase db) =>
      db.games.createAlias('nights__game_id__games__id');

  $$GamesTableProcessedTableManager get gameId {
    final $_column = $_itemColumn<String>('game_id')!;

    final manager = $$GamesTableTableManager(
      $_db,
      $_db.games,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_gameIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$NightActionsTable, List<NightActionRow>>
  _nightActionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.nightActions,
    aliasName: 'nights__id__night_actions__night_id',
  );

  $$NightActionsTableProcessedTableManager get nightActionsRefs {
    final manager = $$NightActionsTableTableManager(
      $_db,
      $_db.nightActions,
    ).filter((f) => f.nightId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_nightActionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$NightsTableFilterComposer
    extends Composer<_$AppDatabase, $NightsTable> {
  $$NightsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nightNumber => $composableBuilder(
    column: $table.nightNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summaryJson => $composableBuilder(
    column: $table.summaryJson,
    builder: (column) => ColumnFilters(column),
  );

  $$GamesTableFilterComposer get gameId {
    final $$GamesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableFilterComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> nightActionsRefs(
    Expression<bool> Function($$NightActionsTableFilterComposer f) f,
  ) {
    final $$NightActionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.nightActions,
      getReferencedColumn: (t) => t.nightId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NightActionsTableFilterComposer(
            $db: $db,
            $table: $db.nightActions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$NightsTableOrderingComposer
    extends Composer<_$AppDatabase, $NightsTable> {
  $$NightsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nightNumber => $composableBuilder(
    column: $table.nightNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summaryJson => $composableBuilder(
    column: $table.summaryJson,
    builder: (column) => ColumnOrderings(column),
  );

  $$GamesTableOrderingComposer get gameId {
    final $$GamesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableOrderingComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NightsTableAnnotationComposer
    extends Composer<_$AppDatabase, $NightsTable> {
  $$NightsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get nightNumber => $composableBuilder(
    column: $table.nightNumber,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get summaryJson => $composableBuilder(
    column: $table.summaryJson,
    builder: (column) => column,
  );

  $$GamesTableAnnotationComposer get gameId {
    final $$GamesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableAnnotationComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> nightActionsRefs<T extends Object>(
    Expression<T> Function($$NightActionsTableAnnotationComposer a) f,
  ) {
    final $$NightActionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.nightActions,
      getReferencedColumn: (t) => t.nightId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NightActionsTableAnnotationComposer(
            $db: $db,
            $table: $db.nightActions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$NightsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NightsTable,
          NightRow,
          $$NightsTableFilterComposer,
          $$NightsTableOrderingComposer,
          $$NightsTableAnnotationComposer,
          $$NightsTableCreateCompanionBuilder,
          $$NightsTableUpdateCompanionBuilder,
          (NightRow, $$NightsTableReferences),
          NightRow,
          PrefetchHooks Function({bool gameId, bool nightActionsRefs})
        > {
  $$NightsTableTableManager(_$AppDatabase db, $NightsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NightsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NightsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NightsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> gameId = const Value.absent(),
                Value<int> nightNumber = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> resolvedAt = const Value.absent(),
                Value<String?> summaryJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NightsCompanion(
                id: id,
                gameId: gameId,
                nightNumber: nightNumber,
                createdAt: createdAt,
                resolvedAt: resolvedAt,
                summaryJson: summaryJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String gameId,
                required int nightNumber,
                required DateTime createdAt,
                Value<DateTime?> resolvedAt = const Value.absent(),
                Value<String?> summaryJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NightsCompanion.insert(
                id: id,
                gameId: gameId,
                nightNumber: nightNumber,
                createdAt: createdAt,
                resolvedAt: resolvedAt,
                summaryJson: summaryJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$NightsTable, NightRow>(table),
                  $$NightsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({gameId = false, nightActionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (nightActionsRefs) db.nightActions],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (gameId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.gameId,
                        referencedTable: $$NightsTableReferences._gameIdTable(
                          db,
                        ),
                        referencedColumn: $$NightsTableReferences
                            ._gameIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (nightActionsRefs)
                    await $_getPrefetchedData<
                      NightRow,
                      $NightsTable,
                      NightActionRow
                    >(
                      currentTable: table,
                      referencedTable: $$NightsTableReferences
                          ._nightActionsRefsTable(db),
                      managerFromTypedResult: (p0) => $$NightsTableReferences(
                        db,
                        table,
                        p0,
                      ).nightActionsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.nightId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$NightsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NightsTable,
      NightRow,
      $$NightsTableFilterComposer,
      $$NightsTableOrderingComposer,
      $$NightsTableAnnotationComposer,
      $$NightsTableCreateCompanionBuilder,
      $$NightsTableUpdateCompanionBuilder,
      (NightRow, $$NightsTableReferences),
      NightRow,
      PrefetchHooks Function({bool gameId, bool nightActionsRefs})
    >;
typedef $$NightActionsTableCreateCompanionBuilder =
    NightActionsCompanion Function({
      required String id,
      required String nightId,
      required String gameId,
      required String type,
      Value<String?> actorPlayerId,
      Value<String?> targetPlayerId,
      Value<String?> secondaryTargetPlayerId,
      Value<String?> detailsJson,
      required int orderIndex,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$NightActionsTableUpdateCompanionBuilder =
    NightActionsCompanion Function({
      Value<String> id,
      Value<String> nightId,
      Value<String> gameId,
      Value<String> type,
      Value<String?> actorPlayerId,
      Value<String?> targetPlayerId,
      Value<String?> secondaryTargetPlayerId,
      Value<String?> detailsJson,
      Value<int> orderIndex,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$NightActionsTableReferences
    extends BaseReferences<_$AppDatabase, $NightActionsTable, NightActionRow> {
  $$NightActionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $NightsTable _nightIdTable(_$AppDatabase db) =>
      db.nights.createAlias('night_actions__night_id__nights__id');

  $$NightsTableProcessedTableManager get nightId {
    final $_column = $_itemColumn<String>('night_id')!;

    final manager = $$NightsTableTableManager(
      $_db,
      $_db.nights,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_nightIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$NightActionsTableFilterComposer
    extends Composer<_$AppDatabase, $NightActionsTable> {
  $$NightActionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gameId => $composableBuilder(
    column: $table.gameId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actorPlayerId => $composableBuilder(
    column: $table.actorPlayerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetPlayerId => $composableBuilder(
    column: $table.targetPlayerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get secondaryTargetPlayerId => $composableBuilder(
    column: $table.secondaryTargetPlayerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get detailsJson => $composableBuilder(
    column: $table.detailsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$NightsTableFilterComposer get nightId {
    final $$NightsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.nightId,
      referencedTable: $db.nights,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NightsTableFilterComposer(
            $db: $db,
            $table: $db.nights,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NightActionsTableOrderingComposer
    extends Composer<_$AppDatabase, $NightActionsTable> {
  $$NightActionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gameId => $composableBuilder(
    column: $table.gameId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actorPlayerId => $composableBuilder(
    column: $table.actorPlayerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetPlayerId => $composableBuilder(
    column: $table.targetPlayerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get secondaryTargetPlayerId => $composableBuilder(
    column: $table.secondaryTargetPlayerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get detailsJson => $composableBuilder(
    column: $table.detailsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$NightsTableOrderingComposer get nightId {
    final $$NightsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.nightId,
      referencedTable: $db.nights,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NightsTableOrderingComposer(
            $db: $db,
            $table: $db.nights,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NightActionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $NightActionsTable> {
  $$NightActionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get gameId =>
      $composableBuilder(column: $table.gameId, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get actorPlayerId => $composableBuilder(
    column: $table.actorPlayerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get targetPlayerId => $composableBuilder(
    column: $table.targetPlayerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get secondaryTargetPlayerId => $composableBuilder(
    column: $table.secondaryTargetPlayerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get detailsJson => $composableBuilder(
    column: $table.detailsJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$NightsTableAnnotationComposer get nightId {
    final $$NightsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.nightId,
      referencedTable: $db.nights,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NightsTableAnnotationComposer(
            $db: $db,
            $table: $db.nights,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NightActionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NightActionsTable,
          NightActionRow,
          $$NightActionsTableFilterComposer,
          $$NightActionsTableOrderingComposer,
          $$NightActionsTableAnnotationComposer,
          $$NightActionsTableCreateCompanionBuilder,
          $$NightActionsTableUpdateCompanionBuilder,
          (NightActionRow, $$NightActionsTableReferences),
          NightActionRow,
          PrefetchHooks Function({bool nightId})
        > {
  $$NightActionsTableTableManager(_$AppDatabase db, $NightActionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NightActionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NightActionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NightActionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> nightId = const Value.absent(),
                Value<String> gameId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> actorPlayerId = const Value.absent(),
                Value<String?> targetPlayerId = const Value.absent(),
                Value<String?> secondaryTargetPlayerId = const Value.absent(),
                Value<String?> detailsJson = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NightActionsCompanion(
                id: id,
                nightId: nightId,
                gameId: gameId,
                type: type,
                actorPlayerId: actorPlayerId,
                targetPlayerId: targetPlayerId,
                secondaryTargetPlayerId: secondaryTargetPlayerId,
                detailsJson: detailsJson,
                orderIndex: orderIndex,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String nightId,
                required String gameId,
                required String type,
                Value<String?> actorPlayerId = const Value.absent(),
                Value<String?> targetPlayerId = const Value.absent(),
                Value<String?> secondaryTargetPlayerId = const Value.absent(),
                Value<String?> detailsJson = const Value.absent(),
                required int orderIndex,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => NightActionsCompanion.insert(
                id: id,
                nightId: nightId,
                gameId: gameId,
                type: type,
                actorPlayerId: actorPlayerId,
                targetPlayerId: targetPlayerId,
                secondaryTargetPlayerId: secondaryTargetPlayerId,
                detailsJson: detailsJson,
                orderIndex: orderIndex,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$NightActionsTable, NightActionRow>(table),
                  $$NightActionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({nightId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (nightId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.nightId,
                        referencedTable: $$NightActionsTableReferences
                            ._nightIdTable(db),
                        referencedColumn: $$NightActionsTableReferences
                            ._nightIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$NightActionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NightActionsTable,
      NightActionRow,
      $$NightActionsTableFilterComposer,
      $$NightActionsTableOrderingComposer,
      $$NightActionsTableAnnotationComposer,
      $$NightActionsTableCreateCompanionBuilder,
      $$NightActionsTableUpdateCompanionBuilder,
      (NightActionRow, $$NightActionsTableReferences),
      NightActionRow,
      PrefetchHooks Function({bool nightId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$GamesTableTableManager get games =>
      $$GamesTableTableManager(_db, _db.games);
  $$PlayersTableTableManager get players =>
      $$PlayersTableTableManager(_db, _db.players);
  $$NightsTableTableManager get nights =>
      $$NightsTableTableManager(_db, _db.nights);
  $$NightActionsTableTableManager get nightActions =>
      $$NightActionsTableTableManager(_db, _db.nightActions);
}
