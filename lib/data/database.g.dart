// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $SavedRunsTable extends SavedRuns
    with TableInfo<$SavedRunsTable, SavedRun> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavedRunsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _slotMeta = const VerificationMeta('slot');
  @override
  late final GeneratedColumn<String> slot = GeneratedColumn<String>(
    'slot',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seedMeta = const VerificationMeta('seed');
  @override
  late final GeneratedColumn<String> seed = GeneratedColumn<String>(
    'seed',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addsMeta = const VerificationMeta('adds');
  @override
  late final GeneratedColumn<int> adds = GeneratedColumn<int>(
    'adds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hintsMeta = const VerificationMeta('hints');
  @override
  late final GeneratedColumn<int> hints = GeneratedColumn<int>(
    'hints',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetMeta = const VerificationMeta('target');
  @override
  late final GeneratedColumn<int> target = GeneratedColumn<int>(
    'target',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actionsMeta = const VerificationMeta(
    'actions',
  );
  @override
  late final GeneratedColumn<String> actions = GeneratedColumn<String>(
    'actions',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hintsUsedMeta = const VerificationMeta(
    'hintsUsed',
  );
  @override
  late final GeneratedColumn<int> hintsUsed = GeneratedColumn<int>(
    'hints_used',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hintAMeta = const VerificationMeta('hintA');
  @override
  late final GeneratedColumn<int> hintA = GeneratedColumn<int>(
    'hint_a',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hintBMeta = const VerificationMeta('hintB');
  @override
  late final GeneratedColumn<int> hintB = GeneratedColumn<int>(
    'hint_b',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hintAReleasedMeta = const VerificationMeta(
    'hintAReleased',
  );
  @override
  late final GeneratedColumn<bool> hintAReleased = GeneratedColumn<bool>(
    'hint_a_released',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("hint_a_released" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _hintBReleasedMeta = const VerificationMeta(
    'hintBReleased',
  );
  @override
  late final GeneratedColumn<bool> hintBReleased = GeneratedColumn<bool>(
    'hint_b_released',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("hint_b_released" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _scoreCacheMeta = const VerificationMeta(
    'scoreCache',
  );
  @override
  late final GeneratedColumn<int> scoreCache = GeneratedColumn<int>(
    'score_cache',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
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
  @override
  List<GeneratedColumn> get $columns => [
    slot,
    seed,
    adds,
    hints,
    target,
    actions,
    hintsUsed,
    hintA,
    hintB,
    hintAReleased,
    hintBReleased,
    scoreCache,
    startedAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'saved_runs';
  @override
  VerificationContext validateIntegrity(
    Insertable<SavedRun> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('slot')) {
      context.handle(
        _slotMeta,
        slot.isAcceptableOrUnknown(data['slot']!, _slotMeta),
      );
    } else if (isInserting) {
      context.missing(_slotMeta);
    }
    if (data.containsKey('seed')) {
      context.handle(
        _seedMeta,
        seed.isAcceptableOrUnknown(data['seed']!, _seedMeta),
      );
    } else if (isInserting) {
      context.missing(_seedMeta);
    }
    if (data.containsKey('adds')) {
      context.handle(
        _addsMeta,
        adds.isAcceptableOrUnknown(data['adds']!, _addsMeta),
      );
    }
    if (data.containsKey('hints')) {
      context.handle(
        _hintsMeta,
        hints.isAcceptableOrUnknown(data['hints']!, _hintsMeta),
      );
    }
    if (data.containsKey('target')) {
      context.handle(
        _targetMeta,
        target.isAcceptableOrUnknown(data['target']!, _targetMeta),
      );
    }
    if (data.containsKey('actions')) {
      context.handle(
        _actionsMeta,
        actions.isAcceptableOrUnknown(data['actions']!, _actionsMeta),
      );
    } else if (isInserting) {
      context.missing(_actionsMeta);
    }
    if (data.containsKey('hints_used')) {
      context.handle(
        _hintsUsedMeta,
        hintsUsed.isAcceptableOrUnknown(data['hints_used']!, _hintsUsedMeta),
      );
    } else if (isInserting) {
      context.missing(_hintsUsedMeta);
    }
    if (data.containsKey('hint_a')) {
      context.handle(
        _hintAMeta,
        hintA.isAcceptableOrUnknown(data['hint_a']!, _hintAMeta),
      );
    }
    if (data.containsKey('hint_b')) {
      context.handle(
        _hintBMeta,
        hintB.isAcceptableOrUnknown(data['hint_b']!, _hintBMeta),
      );
    }
    if (data.containsKey('hint_a_released')) {
      context.handle(
        _hintAReleasedMeta,
        hintAReleased.isAcceptableOrUnknown(
          data['hint_a_released']!,
          _hintAReleasedMeta,
        ),
      );
    }
    if (data.containsKey('hint_b_released')) {
      context.handle(
        _hintBReleasedMeta,
        hintBReleased.isAcceptableOrUnknown(
          data['hint_b_released']!,
          _hintBReleasedMeta,
        ),
      );
    }
    if (data.containsKey('score_cache')) {
      context.handle(
        _scoreCacheMeta,
        scoreCache.isAcceptableOrUnknown(data['score_cache']!, _scoreCacheMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreCacheMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {slot};
  @override
  SavedRun map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavedRun(
      slot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slot'],
      )!,
      seed: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}seed'],
      )!,
      adds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}adds'],
      ),
      hints: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hints'],
      ),
      target: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target'],
      ),
      actions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actions'],
      )!,
      hintsUsed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hints_used'],
      )!,
      hintA: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hint_a'],
      ),
      hintB: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hint_b'],
      ),
      hintAReleased: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}hint_a_released'],
      )!,
      hintBReleased: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}hint_b_released'],
      )!,
      scoreCache: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}score_cache'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SavedRunsTable createAlias(String alias) {
    return $SavedRunsTable(attachedDatabase, alias);
  }
}

class SavedRun extends DataClass implements Insertable<SavedRun> {
  final String slot;
  final String seed;
  final int? adds;
  final int? hints;
  final int? target;
  final String actions;
  final int hintsUsed;
  final int? hintA;
  final int? hintB;
  final bool hintAReleased;
  final bool hintBReleased;
  final int scoreCache;
  final DateTime startedAt;
  final DateTime updatedAt;
  const SavedRun({
    required this.slot,
    required this.seed,
    this.adds,
    this.hints,
    this.target,
    required this.actions,
    required this.hintsUsed,
    this.hintA,
    this.hintB,
    required this.hintAReleased,
    required this.hintBReleased,
    required this.scoreCache,
    required this.startedAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['slot'] = Variable<String>(slot);
    map['seed'] = Variable<String>(seed);
    if (!nullToAbsent || adds != null) {
      map['adds'] = Variable<int>(adds);
    }
    if (!nullToAbsent || hints != null) {
      map['hints'] = Variable<int>(hints);
    }
    if (!nullToAbsent || target != null) {
      map['target'] = Variable<int>(target);
    }
    map['actions'] = Variable<String>(actions);
    map['hints_used'] = Variable<int>(hintsUsed);
    if (!nullToAbsent || hintA != null) {
      map['hint_a'] = Variable<int>(hintA);
    }
    if (!nullToAbsent || hintB != null) {
      map['hint_b'] = Variable<int>(hintB);
    }
    map['hint_a_released'] = Variable<bool>(hintAReleased);
    map['hint_b_released'] = Variable<bool>(hintBReleased);
    map['score_cache'] = Variable<int>(scoreCache);
    map['started_at'] = Variable<DateTime>(startedAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SavedRunsCompanion toCompanion(bool nullToAbsent) {
    return SavedRunsCompanion(
      slot: Value(slot),
      seed: Value(seed),
      adds: adds == null && nullToAbsent ? const Value.absent() : Value(adds),
      hints: hints == null && nullToAbsent
          ? const Value.absent()
          : Value(hints),
      target: target == null && nullToAbsent
          ? const Value.absent()
          : Value(target),
      actions: Value(actions),
      hintsUsed: Value(hintsUsed),
      hintA: hintA == null && nullToAbsent
          ? const Value.absent()
          : Value(hintA),
      hintB: hintB == null && nullToAbsent
          ? const Value.absent()
          : Value(hintB),
      hintAReleased: Value(hintAReleased),
      hintBReleased: Value(hintBReleased),
      scoreCache: Value(scoreCache),
      startedAt: Value(startedAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SavedRun.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavedRun(
      slot: serializer.fromJson<String>(json['slot']),
      seed: serializer.fromJson<String>(json['seed']),
      adds: serializer.fromJson<int?>(json['adds']),
      hints: serializer.fromJson<int?>(json['hints']),
      target: serializer.fromJson<int?>(json['target']),
      actions: serializer.fromJson<String>(json['actions']),
      hintsUsed: serializer.fromJson<int>(json['hintsUsed']),
      hintA: serializer.fromJson<int?>(json['hintA']),
      hintB: serializer.fromJson<int?>(json['hintB']),
      hintAReleased: serializer.fromJson<bool>(json['hintAReleased']),
      hintBReleased: serializer.fromJson<bool>(json['hintBReleased']),
      scoreCache: serializer.fromJson<int>(json['scoreCache']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'slot': serializer.toJson<String>(slot),
      'seed': serializer.toJson<String>(seed),
      'adds': serializer.toJson<int?>(adds),
      'hints': serializer.toJson<int?>(hints),
      'target': serializer.toJson<int?>(target),
      'actions': serializer.toJson<String>(actions),
      'hintsUsed': serializer.toJson<int>(hintsUsed),
      'hintA': serializer.toJson<int?>(hintA),
      'hintB': serializer.toJson<int?>(hintB),
      'hintAReleased': serializer.toJson<bool>(hintAReleased),
      'hintBReleased': serializer.toJson<bool>(hintBReleased),
      'scoreCache': serializer.toJson<int>(scoreCache),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SavedRun copyWith({
    String? slot,
    String? seed,
    Value<int?> adds = const Value.absent(),
    Value<int?> hints = const Value.absent(),
    Value<int?> target = const Value.absent(),
    String? actions,
    int? hintsUsed,
    Value<int?> hintA = const Value.absent(),
    Value<int?> hintB = const Value.absent(),
    bool? hintAReleased,
    bool? hintBReleased,
    int? scoreCache,
    DateTime? startedAt,
    DateTime? updatedAt,
  }) => SavedRun(
    slot: slot ?? this.slot,
    seed: seed ?? this.seed,
    adds: adds.present ? adds.value : this.adds,
    hints: hints.present ? hints.value : this.hints,
    target: target.present ? target.value : this.target,
    actions: actions ?? this.actions,
    hintsUsed: hintsUsed ?? this.hintsUsed,
    hintA: hintA.present ? hintA.value : this.hintA,
    hintB: hintB.present ? hintB.value : this.hintB,
    hintAReleased: hintAReleased ?? this.hintAReleased,
    hintBReleased: hintBReleased ?? this.hintBReleased,
    scoreCache: scoreCache ?? this.scoreCache,
    startedAt: startedAt ?? this.startedAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SavedRun copyWithCompanion(SavedRunsCompanion data) {
    return SavedRun(
      slot: data.slot.present ? data.slot.value : this.slot,
      seed: data.seed.present ? data.seed.value : this.seed,
      adds: data.adds.present ? data.adds.value : this.adds,
      hints: data.hints.present ? data.hints.value : this.hints,
      target: data.target.present ? data.target.value : this.target,
      actions: data.actions.present ? data.actions.value : this.actions,
      hintsUsed: data.hintsUsed.present ? data.hintsUsed.value : this.hintsUsed,
      hintA: data.hintA.present ? data.hintA.value : this.hintA,
      hintB: data.hintB.present ? data.hintB.value : this.hintB,
      hintAReleased: data.hintAReleased.present
          ? data.hintAReleased.value
          : this.hintAReleased,
      hintBReleased: data.hintBReleased.present
          ? data.hintBReleased.value
          : this.hintBReleased,
      scoreCache: data.scoreCache.present
          ? data.scoreCache.value
          : this.scoreCache,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavedRun(')
          ..write('slot: $slot, ')
          ..write('seed: $seed, ')
          ..write('adds: $adds, ')
          ..write('hints: $hints, ')
          ..write('target: $target, ')
          ..write('actions: $actions, ')
          ..write('hintsUsed: $hintsUsed, ')
          ..write('hintA: $hintA, ')
          ..write('hintB: $hintB, ')
          ..write('hintAReleased: $hintAReleased, ')
          ..write('hintBReleased: $hintBReleased, ')
          ..write('scoreCache: $scoreCache, ')
          ..write('startedAt: $startedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    slot,
    seed,
    adds,
    hints,
    target,
    actions,
    hintsUsed,
    hintA,
    hintB,
    hintAReleased,
    hintBReleased,
    scoreCache,
    startedAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavedRun &&
          other.slot == this.slot &&
          other.seed == this.seed &&
          other.adds == this.adds &&
          other.hints == this.hints &&
          other.target == this.target &&
          other.actions == this.actions &&
          other.hintsUsed == this.hintsUsed &&
          other.hintA == this.hintA &&
          other.hintB == this.hintB &&
          other.hintAReleased == this.hintAReleased &&
          other.hintBReleased == this.hintBReleased &&
          other.scoreCache == this.scoreCache &&
          other.startedAt == this.startedAt &&
          other.updatedAt == this.updatedAt);
}

class SavedRunsCompanion extends UpdateCompanion<SavedRun> {
  final Value<String> slot;
  final Value<String> seed;
  final Value<int?> adds;
  final Value<int?> hints;
  final Value<int?> target;
  final Value<String> actions;
  final Value<int> hintsUsed;
  final Value<int?> hintA;
  final Value<int?> hintB;
  final Value<bool> hintAReleased;
  final Value<bool> hintBReleased;
  final Value<int> scoreCache;
  final Value<DateTime> startedAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SavedRunsCompanion({
    this.slot = const Value.absent(),
    this.seed = const Value.absent(),
    this.adds = const Value.absent(),
    this.hints = const Value.absent(),
    this.target = const Value.absent(),
    this.actions = const Value.absent(),
    this.hintsUsed = const Value.absent(),
    this.hintA = const Value.absent(),
    this.hintB = const Value.absent(),
    this.hintAReleased = const Value.absent(),
    this.hintBReleased = const Value.absent(),
    this.scoreCache = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SavedRunsCompanion.insert({
    required String slot,
    required String seed,
    this.adds = const Value.absent(),
    this.hints = const Value.absent(),
    this.target = const Value.absent(),
    required String actions,
    required int hintsUsed,
    this.hintA = const Value.absent(),
    this.hintB = const Value.absent(),
    this.hintAReleased = const Value.absent(),
    this.hintBReleased = const Value.absent(),
    required int scoreCache,
    required DateTime startedAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : slot = Value(slot),
       seed = Value(seed),
       actions = Value(actions),
       hintsUsed = Value(hintsUsed),
       scoreCache = Value(scoreCache),
       startedAt = Value(startedAt),
       updatedAt = Value(updatedAt);
  static Insertable<SavedRun> custom({
    Expression<String>? slot,
    Expression<String>? seed,
    Expression<int>? adds,
    Expression<int>? hints,
    Expression<int>? target,
    Expression<String>? actions,
    Expression<int>? hintsUsed,
    Expression<int>? hintA,
    Expression<int>? hintB,
    Expression<bool>? hintAReleased,
    Expression<bool>? hintBReleased,
    Expression<int>? scoreCache,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (slot != null) 'slot': slot,
      if (seed != null) 'seed': seed,
      if (adds != null) 'adds': adds,
      if (hints != null) 'hints': hints,
      if (target != null) 'target': target,
      if (actions != null) 'actions': actions,
      if (hintsUsed != null) 'hints_used': hintsUsed,
      if (hintA != null) 'hint_a': hintA,
      if (hintB != null) 'hint_b': hintB,
      if (hintAReleased != null) 'hint_a_released': hintAReleased,
      if (hintBReleased != null) 'hint_b_released': hintBReleased,
      if (scoreCache != null) 'score_cache': scoreCache,
      if (startedAt != null) 'started_at': startedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SavedRunsCompanion copyWith({
    Value<String>? slot,
    Value<String>? seed,
    Value<int?>? adds,
    Value<int?>? hints,
    Value<int?>? target,
    Value<String>? actions,
    Value<int>? hintsUsed,
    Value<int?>? hintA,
    Value<int?>? hintB,
    Value<bool>? hintAReleased,
    Value<bool>? hintBReleased,
    Value<int>? scoreCache,
    Value<DateTime>? startedAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SavedRunsCompanion(
      slot: slot ?? this.slot,
      seed: seed ?? this.seed,
      adds: adds ?? this.adds,
      hints: hints ?? this.hints,
      target: target ?? this.target,
      actions: actions ?? this.actions,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      hintA: hintA ?? this.hintA,
      hintB: hintB ?? this.hintB,
      hintAReleased: hintAReleased ?? this.hintAReleased,
      hintBReleased: hintBReleased ?? this.hintBReleased,
      scoreCache: scoreCache ?? this.scoreCache,
      startedAt: startedAt ?? this.startedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (slot.present) {
      map['slot'] = Variable<String>(slot.value);
    }
    if (seed.present) {
      map['seed'] = Variable<String>(seed.value);
    }
    if (adds.present) {
      map['adds'] = Variable<int>(adds.value);
    }
    if (hints.present) {
      map['hints'] = Variable<int>(hints.value);
    }
    if (target.present) {
      map['target'] = Variable<int>(target.value);
    }
    if (actions.present) {
      map['actions'] = Variable<String>(actions.value);
    }
    if (hintsUsed.present) {
      map['hints_used'] = Variable<int>(hintsUsed.value);
    }
    if (hintA.present) {
      map['hint_a'] = Variable<int>(hintA.value);
    }
    if (hintB.present) {
      map['hint_b'] = Variable<int>(hintB.value);
    }
    if (hintAReleased.present) {
      map['hint_a_released'] = Variable<bool>(hintAReleased.value);
    }
    if (hintBReleased.present) {
      map['hint_b_released'] = Variable<bool>(hintBReleased.value);
    }
    if (scoreCache.present) {
      map['score_cache'] = Variable<int>(scoreCache.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavedRunsCompanion(')
          ..write('slot: $slot, ')
          ..write('seed: $seed, ')
          ..write('adds: $adds, ')
          ..write('hints: $hints, ')
          ..write('target: $target, ')
          ..write('actions: $actions, ')
          ..write('hintsUsed: $hintsUsed, ')
          ..write('hintA: $hintA, ')
          ..write('hintB: $hintB, ')
          ..write('hintAReleased: $hintAReleased, ')
          ..write('hintBReleased: $hintBReleased, ')
          ..write('scoreCache: $scoreCache, ')
          ..write('startedAt: $startedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RunResultsTable extends RunResults
    with TableInfo<$RunResultsTable, RunResult> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RunResultsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _slotMeta = const VerificationMeta('slot');
  @override
  late final GeneratedColumn<String> slot = GeneratedColumn<String>(
    'slot',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seedMeta = const VerificationMeta('seed');
  @override
  late final GeneratedColumn<String> seed = GeneratedColumn<String>(
    'seed',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addsMeta = const VerificationMeta('adds');
  @override
  late final GeneratedColumn<int> adds = GeneratedColumn<int>(
    'adds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hintsMeta = const VerificationMeta('hints');
  @override
  late final GeneratedColumn<int> hints = GeneratedColumn<int>(
    'hints',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetMeta = const VerificationMeta('target');
  @override
  late final GeneratedColumn<int> target = GeneratedColumn<int>(
    'target',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<int> score = GeneratedColumn<int>(
    'score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clearedMeta = const VerificationMeta(
    'cleared',
  );
  @override
  late final GeneratedColumn<bool> cleared = GeneratedColumn<bool>(
    'cleared',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("cleared" IN (0, 1))',
    ),
  );
  static const VerificationMeta _targetBeatenMeta = const VerificationMeta(
    'targetBeaten',
  );
  @override
  late final GeneratedColumn<bool> targetBeaten = GeneratedColumn<bool>(
    'target_beaten',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("target_beaten" IN (0, 1))',
    ),
  );
  static const VerificationMeta _pairsMeta = const VerificationMeta('pairs');
  @override
  late final GeneratedColumn<int> pairs = GeneratedColumn<int>(
    'pairs',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rowsMeta = const VerificationMeta('rows');
  @override
  late final GeneratedColumn<int> rows = GeneratedColumn<int>(
    'rows',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addsUsedMeta = const VerificationMeta(
    'addsUsed',
  );
  @override
  late final GeneratedColumn<int> addsUsed = GeneratedColumn<int>(
    'adds_used',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hintsUsedMeta = const VerificationMeta(
    'hintsUsed',
  );
  @override
  late final GeneratedColumn<int> hintsUsed = GeneratedColumn<int>(
    'hints_used',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    slot,
    seed,
    adds,
    hints,
    target,
    score,
    cleared,
    targetBeaten,
    pairs,
    rows,
    addsUsed,
    hintsUsed,
    durationMs,
    startedAt,
    endedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'run_results';
  @override
  VerificationContext validateIntegrity(
    Insertable<RunResult> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('slot')) {
      context.handle(
        _slotMeta,
        slot.isAcceptableOrUnknown(data['slot']!, _slotMeta),
      );
    } else if (isInserting) {
      context.missing(_slotMeta);
    }
    if (data.containsKey('seed')) {
      context.handle(
        _seedMeta,
        seed.isAcceptableOrUnknown(data['seed']!, _seedMeta),
      );
    } else if (isInserting) {
      context.missing(_seedMeta);
    }
    if (data.containsKey('adds')) {
      context.handle(
        _addsMeta,
        adds.isAcceptableOrUnknown(data['adds']!, _addsMeta),
      );
    }
    if (data.containsKey('hints')) {
      context.handle(
        _hintsMeta,
        hints.isAcceptableOrUnknown(data['hints']!, _hintsMeta),
      );
    }
    if (data.containsKey('target')) {
      context.handle(
        _targetMeta,
        target.isAcceptableOrUnknown(data['target']!, _targetMeta),
      );
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreMeta);
    }
    if (data.containsKey('cleared')) {
      context.handle(
        _clearedMeta,
        cleared.isAcceptableOrUnknown(data['cleared']!, _clearedMeta),
      );
    } else if (isInserting) {
      context.missing(_clearedMeta);
    }
    if (data.containsKey('target_beaten')) {
      context.handle(
        _targetBeatenMeta,
        targetBeaten.isAcceptableOrUnknown(
          data['target_beaten']!,
          _targetBeatenMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetBeatenMeta);
    }
    if (data.containsKey('pairs')) {
      context.handle(
        _pairsMeta,
        pairs.isAcceptableOrUnknown(data['pairs']!, _pairsMeta),
      );
    } else if (isInserting) {
      context.missing(_pairsMeta);
    }
    if (data.containsKey('rows')) {
      context.handle(
        _rowsMeta,
        rows.isAcceptableOrUnknown(data['rows']!, _rowsMeta),
      );
    } else if (isInserting) {
      context.missing(_rowsMeta);
    }
    if (data.containsKey('adds_used')) {
      context.handle(
        _addsUsedMeta,
        addsUsed.isAcceptableOrUnknown(data['adds_used']!, _addsUsedMeta),
      );
    } else if (isInserting) {
      context.missing(_addsUsedMeta);
    }
    if (data.containsKey('hints_used')) {
      context.handle(
        _hintsUsedMeta,
        hintsUsed.isAcceptableOrUnknown(data['hints_used']!, _hintsUsedMeta),
      );
    } else if (isInserting) {
      context.missing(_hintsUsedMeta);
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    } else if (isInserting) {
      context.missing(_durationMsMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_endedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RunResult map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RunResult(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      slot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slot'],
      )!,
      seed: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}seed'],
      )!,
      adds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}adds'],
      ),
      hints: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hints'],
      ),
      target: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target'],
      ),
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}score'],
      )!,
      cleared: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}cleared'],
      )!,
      targetBeaten: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}target_beaten'],
      )!,
      pairs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pairs'],
      )!,
      rows: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rows'],
      )!,
      addsUsed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}adds_used'],
      )!,
      hintsUsed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hints_used'],
      )!,
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      )!,
    );
  }

  @override
  $RunResultsTable createAlias(String alias) {
    return $RunResultsTable(attachedDatabase, alias);
  }
}

class RunResult extends DataClass implements Insertable<RunResult> {
  final int id;
  final String slot;
  final String seed;
  final int? adds;
  final int? hints;
  final int? target;
  final int score;
  final bool cleared;
  final bool targetBeaten;
  final int pairs;
  final int rows;
  final int addsUsed;
  final int hintsUsed;
  final int durationMs;
  final DateTime startedAt;
  final DateTime endedAt;
  const RunResult({
    required this.id,
    required this.slot,
    required this.seed,
    this.adds,
    this.hints,
    this.target,
    required this.score,
    required this.cleared,
    required this.targetBeaten,
    required this.pairs,
    required this.rows,
    required this.addsUsed,
    required this.hintsUsed,
    required this.durationMs,
    required this.startedAt,
    required this.endedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['slot'] = Variable<String>(slot);
    map['seed'] = Variable<String>(seed);
    if (!nullToAbsent || adds != null) {
      map['adds'] = Variable<int>(adds);
    }
    if (!nullToAbsent || hints != null) {
      map['hints'] = Variable<int>(hints);
    }
    if (!nullToAbsent || target != null) {
      map['target'] = Variable<int>(target);
    }
    map['score'] = Variable<int>(score);
    map['cleared'] = Variable<bool>(cleared);
    map['target_beaten'] = Variable<bool>(targetBeaten);
    map['pairs'] = Variable<int>(pairs);
    map['rows'] = Variable<int>(rows);
    map['adds_used'] = Variable<int>(addsUsed);
    map['hints_used'] = Variable<int>(hintsUsed);
    map['duration_ms'] = Variable<int>(durationMs);
    map['started_at'] = Variable<DateTime>(startedAt);
    map['ended_at'] = Variable<DateTime>(endedAt);
    return map;
  }

  RunResultsCompanion toCompanion(bool nullToAbsent) {
    return RunResultsCompanion(
      id: Value(id),
      slot: Value(slot),
      seed: Value(seed),
      adds: adds == null && nullToAbsent ? const Value.absent() : Value(adds),
      hints: hints == null && nullToAbsent
          ? const Value.absent()
          : Value(hints),
      target: target == null && nullToAbsent
          ? const Value.absent()
          : Value(target),
      score: Value(score),
      cleared: Value(cleared),
      targetBeaten: Value(targetBeaten),
      pairs: Value(pairs),
      rows: Value(rows),
      addsUsed: Value(addsUsed),
      hintsUsed: Value(hintsUsed),
      durationMs: Value(durationMs),
      startedAt: Value(startedAt),
      endedAt: Value(endedAt),
    );
  }

  factory RunResult.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RunResult(
      id: serializer.fromJson<int>(json['id']),
      slot: serializer.fromJson<String>(json['slot']),
      seed: serializer.fromJson<String>(json['seed']),
      adds: serializer.fromJson<int?>(json['adds']),
      hints: serializer.fromJson<int?>(json['hints']),
      target: serializer.fromJson<int?>(json['target']),
      score: serializer.fromJson<int>(json['score']),
      cleared: serializer.fromJson<bool>(json['cleared']),
      targetBeaten: serializer.fromJson<bool>(json['targetBeaten']),
      pairs: serializer.fromJson<int>(json['pairs']),
      rows: serializer.fromJson<int>(json['rows']),
      addsUsed: serializer.fromJson<int>(json['addsUsed']),
      hintsUsed: serializer.fromJson<int>(json['hintsUsed']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime>(json['endedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'slot': serializer.toJson<String>(slot),
      'seed': serializer.toJson<String>(seed),
      'adds': serializer.toJson<int?>(adds),
      'hints': serializer.toJson<int?>(hints),
      'target': serializer.toJson<int?>(target),
      'score': serializer.toJson<int>(score),
      'cleared': serializer.toJson<bool>(cleared),
      'targetBeaten': serializer.toJson<bool>(targetBeaten),
      'pairs': serializer.toJson<int>(pairs),
      'rows': serializer.toJson<int>(rows),
      'addsUsed': serializer.toJson<int>(addsUsed),
      'hintsUsed': serializer.toJson<int>(hintsUsed),
      'durationMs': serializer.toJson<int>(durationMs),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime>(endedAt),
    };
  }

  RunResult copyWith({
    int? id,
    String? slot,
    String? seed,
    Value<int?> adds = const Value.absent(),
    Value<int?> hints = const Value.absent(),
    Value<int?> target = const Value.absent(),
    int? score,
    bool? cleared,
    bool? targetBeaten,
    int? pairs,
    int? rows,
    int? addsUsed,
    int? hintsUsed,
    int? durationMs,
    DateTime? startedAt,
    DateTime? endedAt,
  }) => RunResult(
    id: id ?? this.id,
    slot: slot ?? this.slot,
    seed: seed ?? this.seed,
    adds: adds.present ? adds.value : this.adds,
    hints: hints.present ? hints.value : this.hints,
    target: target.present ? target.value : this.target,
    score: score ?? this.score,
    cleared: cleared ?? this.cleared,
    targetBeaten: targetBeaten ?? this.targetBeaten,
    pairs: pairs ?? this.pairs,
    rows: rows ?? this.rows,
    addsUsed: addsUsed ?? this.addsUsed,
    hintsUsed: hintsUsed ?? this.hintsUsed,
    durationMs: durationMs ?? this.durationMs,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt ?? this.endedAt,
  );
  RunResult copyWithCompanion(RunResultsCompanion data) {
    return RunResult(
      id: data.id.present ? data.id.value : this.id,
      slot: data.slot.present ? data.slot.value : this.slot,
      seed: data.seed.present ? data.seed.value : this.seed,
      adds: data.adds.present ? data.adds.value : this.adds,
      hints: data.hints.present ? data.hints.value : this.hints,
      target: data.target.present ? data.target.value : this.target,
      score: data.score.present ? data.score.value : this.score,
      cleared: data.cleared.present ? data.cleared.value : this.cleared,
      targetBeaten: data.targetBeaten.present
          ? data.targetBeaten.value
          : this.targetBeaten,
      pairs: data.pairs.present ? data.pairs.value : this.pairs,
      rows: data.rows.present ? data.rows.value : this.rows,
      addsUsed: data.addsUsed.present ? data.addsUsed.value : this.addsUsed,
      hintsUsed: data.hintsUsed.present ? data.hintsUsed.value : this.hintsUsed,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RunResult(')
          ..write('id: $id, ')
          ..write('slot: $slot, ')
          ..write('seed: $seed, ')
          ..write('adds: $adds, ')
          ..write('hints: $hints, ')
          ..write('target: $target, ')
          ..write('score: $score, ')
          ..write('cleared: $cleared, ')
          ..write('targetBeaten: $targetBeaten, ')
          ..write('pairs: $pairs, ')
          ..write('rows: $rows, ')
          ..write('addsUsed: $addsUsed, ')
          ..write('hintsUsed: $hintsUsed, ')
          ..write('durationMs: $durationMs, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    slot,
    seed,
    adds,
    hints,
    target,
    score,
    cleared,
    targetBeaten,
    pairs,
    rows,
    addsUsed,
    hintsUsed,
    durationMs,
    startedAt,
    endedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RunResult &&
          other.id == this.id &&
          other.slot == this.slot &&
          other.seed == this.seed &&
          other.adds == this.adds &&
          other.hints == this.hints &&
          other.target == this.target &&
          other.score == this.score &&
          other.cleared == this.cleared &&
          other.targetBeaten == this.targetBeaten &&
          other.pairs == this.pairs &&
          other.rows == this.rows &&
          other.addsUsed == this.addsUsed &&
          other.hintsUsed == this.hintsUsed &&
          other.durationMs == this.durationMs &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt);
}

class RunResultsCompanion extends UpdateCompanion<RunResult> {
  final Value<int> id;
  final Value<String> slot;
  final Value<String> seed;
  final Value<int?> adds;
  final Value<int?> hints;
  final Value<int?> target;
  final Value<int> score;
  final Value<bool> cleared;
  final Value<bool> targetBeaten;
  final Value<int> pairs;
  final Value<int> rows;
  final Value<int> addsUsed;
  final Value<int> hintsUsed;
  final Value<int> durationMs;
  final Value<DateTime> startedAt;
  final Value<DateTime> endedAt;
  const RunResultsCompanion({
    this.id = const Value.absent(),
    this.slot = const Value.absent(),
    this.seed = const Value.absent(),
    this.adds = const Value.absent(),
    this.hints = const Value.absent(),
    this.target = const Value.absent(),
    this.score = const Value.absent(),
    this.cleared = const Value.absent(),
    this.targetBeaten = const Value.absent(),
    this.pairs = const Value.absent(),
    this.rows = const Value.absent(),
    this.addsUsed = const Value.absent(),
    this.hintsUsed = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
  });
  RunResultsCompanion.insert({
    this.id = const Value.absent(),
    required String slot,
    required String seed,
    this.adds = const Value.absent(),
    this.hints = const Value.absent(),
    this.target = const Value.absent(),
    required int score,
    required bool cleared,
    required bool targetBeaten,
    required int pairs,
    required int rows,
    required int addsUsed,
    required int hintsUsed,
    required int durationMs,
    required DateTime startedAt,
    required DateTime endedAt,
  }) : slot = Value(slot),
       seed = Value(seed),
       score = Value(score),
       cleared = Value(cleared),
       targetBeaten = Value(targetBeaten),
       pairs = Value(pairs),
       rows = Value(rows),
       addsUsed = Value(addsUsed),
       hintsUsed = Value(hintsUsed),
       durationMs = Value(durationMs),
       startedAt = Value(startedAt),
       endedAt = Value(endedAt);
  static Insertable<RunResult> custom({
    Expression<int>? id,
    Expression<String>? slot,
    Expression<String>? seed,
    Expression<int>? adds,
    Expression<int>? hints,
    Expression<int>? target,
    Expression<int>? score,
    Expression<bool>? cleared,
    Expression<bool>? targetBeaten,
    Expression<int>? pairs,
    Expression<int>? rows,
    Expression<int>? addsUsed,
    Expression<int>? hintsUsed,
    Expression<int>? durationMs,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (slot != null) 'slot': slot,
      if (seed != null) 'seed': seed,
      if (adds != null) 'adds': adds,
      if (hints != null) 'hints': hints,
      if (target != null) 'target': target,
      if (score != null) 'score': score,
      if (cleared != null) 'cleared': cleared,
      if (targetBeaten != null) 'target_beaten': targetBeaten,
      if (pairs != null) 'pairs': pairs,
      if (rows != null) 'rows': rows,
      if (addsUsed != null) 'adds_used': addsUsed,
      if (hintsUsed != null) 'hints_used': hintsUsed,
      if (durationMs != null) 'duration_ms': durationMs,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
    });
  }

  RunResultsCompanion copyWith({
    Value<int>? id,
    Value<String>? slot,
    Value<String>? seed,
    Value<int?>? adds,
    Value<int?>? hints,
    Value<int?>? target,
    Value<int>? score,
    Value<bool>? cleared,
    Value<bool>? targetBeaten,
    Value<int>? pairs,
    Value<int>? rows,
    Value<int>? addsUsed,
    Value<int>? hintsUsed,
    Value<int>? durationMs,
    Value<DateTime>? startedAt,
    Value<DateTime>? endedAt,
  }) {
    return RunResultsCompanion(
      id: id ?? this.id,
      slot: slot ?? this.slot,
      seed: seed ?? this.seed,
      adds: adds ?? this.adds,
      hints: hints ?? this.hints,
      target: target ?? this.target,
      score: score ?? this.score,
      cleared: cleared ?? this.cleared,
      targetBeaten: targetBeaten ?? this.targetBeaten,
      pairs: pairs ?? this.pairs,
      rows: rows ?? this.rows,
      addsUsed: addsUsed ?? this.addsUsed,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      durationMs: durationMs ?? this.durationMs,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (slot.present) {
      map['slot'] = Variable<String>(slot.value);
    }
    if (seed.present) {
      map['seed'] = Variable<String>(seed.value);
    }
    if (adds.present) {
      map['adds'] = Variable<int>(adds.value);
    }
    if (hints.present) {
      map['hints'] = Variable<int>(hints.value);
    }
    if (target.present) {
      map['target'] = Variable<int>(target.value);
    }
    if (score.present) {
      map['score'] = Variable<int>(score.value);
    }
    if (cleared.present) {
      map['cleared'] = Variable<bool>(cleared.value);
    }
    if (targetBeaten.present) {
      map['target_beaten'] = Variable<bool>(targetBeaten.value);
    }
    if (pairs.present) {
      map['pairs'] = Variable<int>(pairs.value);
    }
    if (rows.present) {
      map['rows'] = Variable<int>(rows.value);
    }
    if (addsUsed.present) {
      map['adds_used'] = Variable<int>(addsUsed.value);
    }
    if (hintsUsed.present) {
      map['hints_used'] = Variable<int>(hintsUsed.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RunResultsCompanion(')
          ..write('id: $id, ')
          ..write('slot: $slot, ')
          ..write('seed: $seed, ')
          ..write('adds: $adds, ')
          ..write('hints: $hints, ')
          ..write('target: $target, ')
          ..write('score: $score, ')
          ..write('cleared: $cleared, ')
          ..write('targetBeaten: $targetBeaten, ')
          ..write('pairs: $pairs, ')
          ..write('rows: $rows, ')
          ..write('addsUsed: $addsUsed, ')
          ..write('hintsUsed: $hintsUsed, ')
          ..write('durationMs: $durationMs, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SavedRunsTable savedRuns = $SavedRunsTable(this);
  late final $RunResultsTable runResults = $RunResultsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [savedRuns, runResults];
}

typedef $$SavedRunsTableCreateCompanionBuilder =
    SavedRunsCompanion Function({
      required String slot,
      required String seed,
      Value<int?> adds,
      Value<int?> hints,
      Value<int?> target,
      required String actions,
      required int hintsUsed,
      Value<int?> hintA,
      Value<int?> hintB,
      Value<bool> hintAReleased,
      Value<bool> hintBReleased,
      required int scoreCache,
      required DateTime startedAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$SavedRunsTableUpdateCompanionBuilder =
    SavedRunsCompanion Function({
      Value<String> slot,
      Value<String> seed,
      Value<int?> adds,
      Value<int?> hints,
      Value<int?> target,
      Value<String> actions,
      Value<int> hintsUsed,
      Value<int?> hintA,
      Value<int?> hintB,
      Value<bool> hintAReleased,
      Value<bool> hintBReleased,
      Value<int> scoreCache,
      Value<DateTime> startedAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$SavedRunsTableFilterComposer
    extends Composer<_$AppDatabase, $SavedRunsTable> {
  $$SavedRunsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get slot => $composableBuilder(
    column: $table.slot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get seed => $composableBuilder(
    column: $table.seed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get adds => $composableBuilder(
    column: $table.adds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hints => $composableBuilder(
    column: $table.hints,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get target => $composableBuilder(
    column: $table.target,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actions => $composableBuilder(
    column: $table.actions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hintsUsed => $composableBuilder(
    column: $table.hintsUsed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hintA => $composableBuilder(
    column: $table.hintA,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hintB => $composableBuilder(
    column: $table.hintB,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hintAReleased => $composableBuilder(
    column: $table.hintAReleased,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hintBReleased => $composableBuilder(
    column: $table.hintBReleased,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get scoreCache => $composableBuilder(
    column: $table.scoreCache,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SavedRunsTableOrderingComposer
    extends Composer<_$AppDatabase, $SavedRunsTable> {
  $$SavedRunsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get slot => $composableBuilder(
    column: $table.slot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get seed => $composableBuilder(
    column: $table.seed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get adds => $composableBuilder(
    column: $table.adds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hints => $composableBuilder(
    column: $table.hints,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get target => $composableBuilder(
    column: $table.target,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actions => $composableBuilder(
    column: $table.actions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hintsUsed => $composableBuilder(
    column: $table.hintsUsed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hintA => $composableBuilder(
    column: $table.hintA,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hintB => $composableBuilder(
    column: $table.hintB,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hintAReleased => $composableBuilder(
    column: $table.hintAReleased,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hintBReleased => $composableBuilder(
    column: $table.hintBReleased,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get scoreCache => $composableBuilder(
    column: $table.scoreCache,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SavedRunsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SavedRunsTable> {
  $$SavedRunsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get slot =>
      $composableBuilder(column: $table.slot, builder: (column) => column);

  GeneratedColumn<String> get seed =>
      $composableBuilder(column: $table.seed, builder: (column) => column);

  GeneratedColumn<int> get adds =>
      $composableBuilder(column: $table.adds, builder: (column) => column);

  GeneratedColumn<int> get hints =>
      $composableBuilder(column: $table.hints, builder: (column) => column);

  GeneratedColumn<int> get target =>
      $composableBuilder(column: $table.target, builder: (column) => column);

  GeneratedColumn<String> get actions =>
      $composableBuilder(column: $table.actions, builder: (column) => column);

  GeneratedColumn<int> get hintsUsed =>
      $composableBuilder(column: $table.hintsUsed, builder: (column) => column);

  GeneratedColumn<int> get hintA =>
      $composableBuilder(column: $table.hintA, builder: (column) => column);

  GeneratedColumn<int> get hintB =>
      $composableBuilder(column: $table.hintB, builder: (column) => column);

  GeneratedColumn<bool> get hintAReleased => $composableBuilder(
    column: $table.hintAReleased,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hintBReleased => $composableBuilder(
    column: $table.hintBReleased,
    builder: (column) => column,
  );

  GeneratedColumn<int> get scoreCache => $composableBuilder(
    column: $table.scoreCache,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SavedRunsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SavedRunsTable,
          SavedRun,
          $$SavedRunsTableFilterComposer,
          $$SavedRunsTableOrderingComposer,
          $$SavedRunsTableAnnotationComposer,
          $$SavedRunsTableCreateCompanionBuilder,
          $$SavedRunsTableUpdateCompanionBuilder,
          (SavedRun, BaseReferences<_$AppDatabase, $SavedRunsTable, SavedRun>),
          SavedRun,
          PrefetchHooks Function()
        > {
  $$SavedRunsTableTableManager(_$AppDatabase db, $SavedRunsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SavedRunsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SavedRunsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SavedRunsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> slot = const Value.absent(),
                Value<String> seed = const Value.absent(),
                Value<int?> adds = const Value.absent(),
                Value<int?> hints = const Value.absent(),
                Value<int?> target = const Value.absent(),
                Value<String> actions = const Value.absent(),
                Value<int> hintsUsed = const Value.absent(),
                Value<int?> hintA = const Value.absent(),
                Value<int?> hintB = const Value.absent(),
                Value<bool> hintAReleased = const Value.absent(),
                Value<bool> hintBReleased = const Value.absent(),
                Value<int> scoreCache = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SavedRunsCompanion(
                slot: slot,
                seed: seed,
                adds: adds,
                hints: hints,
                target: target,
                actions: actions,
                hintsUsed: hintsUsed,
                hintA: hintA,
                hintB: hintB,
                hintAReleased: hintAReleased,
                hintBReleased: hintBReleased,
                scoreCache: scoreCache,
                startedAt: startedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String slot,
                required String seed,
                Value<int?> adds = const Value.absent(),
                Value<int?> hints = const Value.absent(),
                Value<int?> target = const Value.absent(),
                required String actions,
                required int hintsUsed,
                Value<int?> hintA = const Value.absent(),
                Value<int?> hintB = const Value.absent(),
                Value<bool> hintAReleased = const Value.absent(),
                Value<bool> hintBReleased = const Value.absent(),
                required int scoreCache,
                required DateTime startedAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => SavedRunsCompanion.insert(
                slot: slot,
                seed: seed,
                adds: adds,
                hints: hints,
                target: target,
                actions: actions,
                hintsUsed: hintsUsed,
                hintA: hintA,
                hintB: hintB,
                hintAReleased: hintAReleased,
                hintBReleased: hintBReleased,
                scoreCache: scoreCache,
                startedAt: startedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SavedRunsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SavedRunsTable,
      SavedRun,
      $$SavedRunsTableFilterComposer,
      $$SavedRunsTableOrderingComposer,
      $$SavedRunsTableAnnotationComposer,
      $$SavedRunsTableCreateCompanionBuilder,
      $$SavedRunsTableUpdateCompanionBuilder,
      (SavedRun, BaseReferences<_$AppDatabase, $SavedRunsTable, SavedRun>),
      SavedRun,
      PrefetchHooks Function()
    >;
typedef $$RunResultsTableCreateCompanionBuilder =
    RunResultsCompanion Function({
      Value<int> id,
      required String slot,
      required String seed,
      Value<int?> adds,
      Value<int?> hints,
      Value<int?> target,
      required int score,
      required bool cleared,
      required bool targetBeaten,
      required int pairs,
      required int rows,
      required int addsUsed,
      required int hintsUsed,
      required int durationMs,
      required DateTime startedAt,
      required DateTime endedAt,
    });
typedef $$RunResultsTableUpdateCompanionBuilder =
    RunResultsCompanion Function({
      Value<int> id,
      Value<String> slot,
      Value<String> seed,
      Value<int?> adds,
      Value<int?> hints,
      Value<int?> target,
      Value<int> score,
      Value<bool> cleared,
      Value<bool> targetBeaten,
      Value<int> pairs,
      Value<int> rows,
      Value<int> addsUsed,
      Value<int> hintsUsed,
      Value<int> durationMs,
      Value<DateTime> startedAt,
      Value<DateTime> endedAt,
    });

class $$RunResultsTableFilterComposer
    extends Composer<_$AppDatabase, $RunResultsTable> {
  $$RunResultsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get slot => $composableBuilder(
    column: $table.slot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get seed => $composableBuilder(
    column: $table.seed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get adds => $composableBuilder(
    column: $table.adds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hints => $composableBuilder(
    column: $table.hints,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get target => $composableBuilder(
    column: $table.target,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get cleared => $composableBuilder(
    column: $table.cleared,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get targetBeaten => $composableBuilder(
    column: $table.targetBeaten,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pairs => $composableBuilder(
    column: $table.pairs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rows => $composableBuilder(
    column: $table.rows,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get addsUsed => $composableBuilder(
    column: $table.addsUsed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hintsUsed => $composableBuilder(
    column: $table.hintsUsed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RunResultsTableOrderingComposer
    extends Composer<_$AppDatabase, $RunResultsTable> {
  $$RunResultsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get slot => $composableBuilder(
    column: $table.slot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get seed => $composableBuilder(
    column: $table.seed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get adds => $composableBuilder(
    column: $table.adds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hints => $composableBuilder(
    column: $table.hints,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get target => $composableBuilder(
    column: $table.target,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get cleared => $composableBuilder(
    column: $table.cleared,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get targetBeaten => $composableBuilder(
    column: $table.targetBeaten,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pairs => $composableBuilder(
    column: $table.pairs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rows => $composableBuilder(
    column: $table.rows,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get addsUsed => $composableBuilder(
    column: $table.addsUsed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hintsUsed => $composableBuilder(
    column: $table.hintsUsed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RunResultsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RunResultsTable> {
  $$RunResultsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get slot =>
      $composableBuilder(column: $table.slot, builder: (column) => column);

  GeneratedColumn<String> get seed =>
      $composableBuilder(column: $table.seed, builder: (column) => column);

  GeneratedColumn<int> get adds =>
      $composableBuilder(column: $table.adds, builder: (column) => column);

  GeneratedColumn<int> get hints =>
      $composableBuilder(column: $table.hints, builder: (column) => column);

  GeneratedColumn<int> get target =>
      $composableBuilder(column: $table.target, builder: (column) => column);

  GeneratedColumn<int> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<bool> get cleared =>
      $composableBuilder(column: $table.cleared, builder: (column) => column);

  GeneratedColumn<bool> get targetBeaten => $composableBuilder(
    column: $table.targetBeaten,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pairs =>
      $composableBuilder(column: $table.pairs, builder: (column) => column);

  GeneratedColumn<int> get rows =>
      $composableBuilder(column: $table.rows, builder: (column) => column);

  GeneratedColumn<int> get addsUsed =>
      $composableBuilder(column: $table.addsUsed, builder: (column) => column);

  GeneratedColumn<int> get hintsUsed =>
      $composableBuilder(column: $table.hintsUsed, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);
}

class $$RunResultsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RunResultsTable,
          RunResult,
          $$RunResultsTableFilterComposer,
          $$RunResultsTableOrderingComposer,
          $$RunResultsTableAnnotationComposer,
          $$RunResultsTableCreateCompanionBuilder,
          $$RunResultsTableUpdateCompanionBuilder,
          (
            RunResult,
            BaseReferences<_$AppDatabase, $RunResultsTable, RunResult>,
          ),
          RunResult,
          PrefetchHooks Function()
        > {
  $$RunResultsTableTableManager(_$AppDatabase db, $RunResultsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RunResultsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RunResultsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RunResultsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> slot = const Value.absent(),
                Value<String> seed = const Value.absent(),
                Value<int?> adds = const Value.absent(),
                Value<int?> hints = const Value.absent(),
                Value<int?> target = const Value.absent(),
                Value<int> score = const Value.absent(),
                Value<bool> cleared = const Value.absent(),
                Value<bool> targetBeaten = const Value.absent(),
                Value<int> pairs = const Value.absent(),
                Value<int> rows = const Value.absent(),
                Value<int> addsUsed = const Value.absent(),
                Value<int> hintsUsed = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime> endedAt = const Value.absent(),
              }) => RunResultsCompanion(
                id: id,
                slot: slot,
                seed: seed,
                adds: adds,
                hints: hints,
                target: target,
                score: score,
                cleared: cleared,
                targetBeaten: targetBeaten,
                pairs: pairs,
                rows: rows,
                addsUsed: addsUsed,
                hintsUsed: hintsUsed,
                durationMs: durationMs,
                startedAt: startedAt,
                endedAt: endedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String slot,
                required String seed,
                Value<int?> adds = const Value.absent(),
                Value<int?> hints = const Value.absent(),
                Value<int?> target = const Value.absent(),
                required int score,
                required bool cleared,
                required bool targetBeaten,
                required int pairs,
                required int rows,
                required int addsUsed,
                required int hintsUsed,
                required int durationMs,
                required DateTime startedAt,
                required DateTime endedAt,
              }) => RunResultsCompanion.insert(
                id: id,
                slot: slot,
                seed: seed,
                adds: adds,
                hints: hints,
                target: target,
                score: score,
                cleared: cleared,
                targetBeaten: targetBeaten,
                pairs: pairs,
                rows: rows,
                addsUsed: addsUsed,
                hintsUsed: hintsUsed,
                durationMs: durationMs,
                startedAt: startedAt,
                endedAt: endedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RunResultsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RunResultsTable,
      RunResult,
      $$RunResultsTableFilterComposer,
      $$RunResultsTableOrderingComposer,
      $$RunResultsTableAnnotationComposer,
      $$RunResultsTableCreateCompanionBuilder,
      $$RunResultsTableUpdateCompanionBuilder,
      (RunResult, BaseReferences<_$AppDatabase, $RunResultsTable, RunResult>),
      RunResult,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SavedRunsTableTableManager get savedRuns =>
      $$SavedRunsTableTableManager(_db, _db.savedRuns);
  $$RunResultsTableTableManager get runResults =>
      $$RunResultsTableTableManager(_db, _db.runResults);
}
