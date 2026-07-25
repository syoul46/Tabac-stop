// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $CigarettesTable extends Cigarettes
    with TableInfo<$CigarettesTable, Cigarette> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CigarettesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occurredAtUtcMeta = const VerificationMeta(
    'occurredAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAtUtc =
      GeneratedColumn<DateTime>(
        'occurred_at_utc',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _tzOffsetMinMeta = const VerificationMeta(
    'tzOffsetMin',
  );
  @override
  late final GeneratedColumn<int> tzOffsetMin = GeneratedColumn<int>(
    'tz_offset_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contextAMeta = const VerificationMeta(
    'contextA',
  );
  @override
  late final GeneratedColumn<int> contextA = GeneratedColumn<int>(
    'context_a',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contextBMeta = const VerificationMeta(
    'contextB',
  );
  @override
  late final GeneratedColumn<int> contextB = GeneratedColumn<int>(
    'context_b',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contextCMeta = const VerificationMeta(
    'contextC',
  );
  @override
  late final GeneratedColumn<int> contextC = GeneratedColumn<int>(
    'context_c',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _wasBossMeta = const VerificationMeta(
    'wasBoss',
  );
  @override
  late final GeneratedColumn<bool> wasBoss = GeneratedColumn<bool>(
    'was_boss',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("was_boss" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _duringDelayMeta = const VerificationMeta(
    'duringDelay',
  );
  @override
  late final GeneratedColumn<bool> duringDelay = GeneratedColumn<bool>(
    'during_delay',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("during_delay" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    occurredAtUtc,
    tzOffsetMin,
    contextA,
    contextB,
    contextC,
    wasBoss,
    duringDelay,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cigarettes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Cigarette> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('occurred_at_utc')) {
      context.handle(
        _occurredAtUtcMeta,
        occurredAtUtc.isAcceptableOrUnknown(
          data['occurred_at_utc']!,
          _occurredAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_occurredAtUtcMeta);
    }
    if (data.containsKey('tz_offset_min')) {
      context.handle(
        _tzOffsetMinMeta,
        tzOffsetMin.isAcceptableOrUnknown(
          data['tz_offset_min']!,
          _tzOffsetMinMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_tzOffsetMinMeta);
    }
    if (data.containsKey('context_a')) {
      context.handle(
        _contextAMeta,
        contextA.isAcceptableOrUnknown(data['context_a']!, _contextAMeta),
      );
    }
    if (data.containsKey('context_b')) {
      context.handle(
        _contextBMeta,
        contextB.isAcceptableOrUnknown(data['context_b']!, _contextBMeta),
      );
    }
    if (data.containsKey('context_c')) {
      context.handle(
        _contextCMeta,
        contextC.isAcceptableOrUnknown(data['context_c']!, _contextCMeta),
      );
    }
    if (data.containsKey('was_boss')) {
      context.handle(
        _wasBossMeta,
        wasBoss.isAcceptableOrUnknown(data['was_boss']!, _wasBossMeta),
      );
    }
    if (data.containsKey('during_delay')) {
      context.handle(
        _duringDelayMeta,
        duringDelay.isAcceptableOrUnknown(
          data['during_delay']!,
          _duringDelayMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Cigarette map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Cigarette(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      occurredAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at_utc'],
      )!,
      tzOffsetMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tz_offset_min'],
      )!,
      contextA: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}context_a'],
      ),
      contextB: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}context_b'],
      ),
      contextC: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}context_c'],
      ),
      wasBoss: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}was_boss'],
      )!,
      duringDelay: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}during_delay'],
      )!,
    );
  }

  @override
  $CigarettesTable createAlias(String alias) {
    return $CigarettesTable(attachedDatabase, alias);
  }
}

class Cigarette extends DataClass implements Insertable<Cigarette> {
  final String id;

  /// Toujours en **UTC** (source de vérité temporelle).
  final DateTime occurredAtUtc;

  /// Décalage local en minutes au moment du tap → reconstitue l'heure murale
  /// locale, sur laquelle on clusterise les Boss.
  final int tzOffsetMin;

  /// Contexte optionnel (index de `CigContext`). `contextB/C` réservés pour
  /// d'éventuelles familles futures.
  final int? contextA;
  final int? contextB;
  final int? contextC;

  /// Cette cigarette ciblait-elle le Boss du jour.
  final bool wasBoss;

  /// Fumée pendant un délai actif = « je fume quand même ».
  final bool duringDelay;
  const Cigarette({
    required this.id,
    required this.occurredAtUtc,
    required this.tzOffsetMin,
    this.contextA,
    this.contextB,
    this.contextC,
    required this.wasBoss,
    required this.duringDelay,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['occurred_at_utc'] = Variable<DateTime>(occurredAtUtc);
    map['tz_offset_min'] = Variable<int>(tzOffsetMin);
    if (!nullToAbsent || contextA != null) {
      map['context_a'] = Variable<int>(contextA);
    }
    if (!nullToAbsent || contextB != null) {
      map['context_b'] = Variable<int>(contextB);
    }
    if (!nullToAbsent || contextC != null) {
      map['context_c'] = Variable<int>(contextC);
    }
    map['was_boss'] = Variable<bool>(wasBoss);
    map['during_delay'] = Variable<bool>(duringDelay);
    return map;
  }

  CigarettesCompanion toCompanion(bool nullToAbsent) {
    return CigarettesCompanion(
      id: Value(id),
      occurredAtUtc: Value(occurredAtUtc),
      tzOffsetMin: Value(tzOffsetMin),
      contextA: contextA == null && nullToAbsent
          ? const Value.absent()
          : Value(contextA),
      contextB: contextB == null && nullToAbsent
          ? const Value.absent()
          : Value(contextB),
      contextC: contextC == null && nullToAbsent
          ? const Value.absent()
          : Value(contextC),
      wasBoss: Value(wasBoss),
      duringDelay: Value(duringDelay),
    );
  }

  factory Cigarette.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Cigarette(
      id: serializer.fromJson<String>(json['id']),
      occurredAtUtc: serializer.fromJson<DateTime>(json['occurredAtUtc']),
      tzOffsetMin: serializer.fromJson<int>(json['tzOffsetMin']),
      contextA: serializer.fromJson<int?>(json['contextA']),
      contextB: serializer.fromJson<int?>(json['contextB']),
      contextC: serializer.fromJson<int?>(json['contextC']),
      wasBoss: serializer.fromJson<bool>(json['wasBoss']),
      duringDelay: serializer.fromJson<bool>(json['duringDelay']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'occurredAtUtc': serializer.toJson<DateTime>(occurredAtUtc),
      'tzOffsetMin': serializer.toJson<int>(tzOffsetMin),
      'contextA': serializer.toJson<int?>(contextA),
      'contextB': serializer.toJson<int?>(contextB),
      'contextC': serializer.toJson<int?>(contextC),
      'wasBoss': serializer.toJson<bool>(wasBoss),
      'duringDelay': serializer.toJson<bool>(duringDelay),
    };
  }

  Cigarette copyWith({
    String? id,
    DateTime? occurredAtUtc,
    int? tzOffsetMin,
    Value<int?> contextA = const Value.absent(),
    Value<int?> contextB = const Value.absent(),
    Value<int?> contextC = const Value.absent(),
    bool? wasBoss,
    bool? duringDelay,
  }) => Cigarette(
    id: id ?? this.id,
    occurredAtUtc: occurredAtUtc ?? this.occurredAtUtc,
    tzOffsetMin: tzOffsetMin ?? this.tzOffsetMin,
    contextA: contextA.present ? contextA.value : this.contextA,
    contextB: contextB.present ? contextB.value : this.contextB,
    contextC: contextC.present ? contextC.value : this.contextC,
    wasBoss: wasBoss ?? this.wasBoss,
    duringDelay: duringDelay ?? this.duringDelay,
  );
  Cigarette copyWithCompanion(CigarettesCompanion data) {
    return Cigarette(
      id: data.id.present ? data.id.value : this.id,
      occurredAtUtc: data.occurredAtUtc.present
          ? data.occurredAtUtc.value
          : this.occurredAtUtc,
      tzOffsetMin: data.tzOffsetMin.present
          ? data.tzOffsetMin.value
          : this.tzOffsetMin,
      contextA: data.contextA.present ? data.contextA.value : this.contextA,
      contextB: data.contextB.present ? data.contextB.value : this.contextB,
      contextC: data.contextC.present ? data.contextC.value : this.contextC,
      wasBoss: data.wasBoss.present ? data.wasBoss.value : this.wasBoss,
      duringDelay: data.duringDelay.present
          ? data.duringDelay.value
          : this.duringDelay,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Cigarette(')
          ..write('id: $id, ')
          ..write('occurredAtUtc: $occurredAtUtc, ')
          ..write('tzOffsetMin: $tzOffsetMin, ')
          ..write('contextA: $contextA, ')
          ..write('contextB: $contextB, ')
          ..write('contextC: $contextC, ')
          ..write('wasBoss: $wasBoss, ')
          ..write('duringDelay: $duringDelay')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    occurredAtUtc,
    tzOffsetMin,
    contextA,
    contextB,
    contextC,
    wasBoss,
    duringDelay,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Cigarette &&
          other.id == this.id &&
          other.occurredAtUtc == this.occurredAtUtc &&
          other.tzOffsetMin == this.tzOffsetMin &&
          other.contextA == this.contextA &&
          other.contextB == this.contextB &&
          other.contextC == this.contextC &&
          other.wasBoss == this.wasBoss &&
          other.duringDelay == this.duringDelay);
}

class CigarettesCompanion extends UpdateCompanion<Cigarette> {
  final Value<String> id;
  final Value<DateTime> occurredAtUtc;
  final Value<int> tzOffsetMin;
  final Value<int?> contextA;
  final Value<int?> contextB;
  final Value<int?> contextC;
  final Value<bool> wasBoss;
  final Value<bool> duringDelay;
  final Value<int> rowid;
  const CigarettesCompanion({
    this.id = const Value.absent(),
    this.occurredAtUtc = const Value.absent(),
    this.tzOffsetMin = const Value.absent(),
    this.contextA = const Value.absent(),
    this.contextB = const Value.absent(),
    this.contextC = const Value.absent(),
    this.wasBoss = const Value.absent(),
    this.duringDelay = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CigarettesCompanion.insert({
    required String id,
    required DateTime occurredAtUtc,
    required int tzOffsetMin,
    this.contextA = const Value.absent(),
    this.contextB = const Value.absent(),
    this.contextC = const Value.absent(),
    this.wasBoss = const Value.absent(),
    this.duringDelay = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       occurredAtUtc = Value(occurredAtUtc),
       tzOffsetMin = Value(tzOffsetMin);
  static Insertable<Cigarette> custom({
    Expression<String>? id,
    Expression<DateTime>? occurredAtUtc,
    Expression<int>? tzOffsetMin,
    Expression<int>? contextA,
    Expression<int>? contextB,
    Expression<int>? contextC,
    Expression<bool>? wasBoss,
    Expression<bool>? duringDelay,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (occurredAtUtc != null) 'occurred_at_utc': occurredAtUtc,
      if (tzOffsetMin != null) 'tz_offset_min': tzOffsetMin,
      if (contextA != null) 'context_a': contextA,
      if (contextB != null) 'context_b': contextB,
      if (contextC != null) 'context_c': contextC,
      if (wasBoss != null) 'was_boss': wasBoss,
      if (duringDelay != null) 'during_delay': duringDelay,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CigarettesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? occurredAtUtc,
    Value<int>? tzOffsetMin,
    Value<int?>? contextA,
    Value<int?>? contextB,
    Value<int?>? contextC,
    Value<bool>? wasBoss,
    Value<bool>? duringDelay,
    Value<int>? rowid,
  }) {
    return CigarettesCompanion(
      id: id ?? this.id,
      occurredAtUtc: occurredAtUtc ?? this.occurredAtUtc,
      tzOffsetMin: tzOffsetMin ?? this.tzOffsetMin,
      contextA: contextA ?? this.contextA,
      contextB: contextB ?? this.contextB,
      contextC: contextC ?? this.contextC,
      wasBoss: wasBoss ?? this.wasBoss,
      duringDelay: duringDelay ?? this.duringDelay,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (occurredAtUtc.present) {
      map['occurred_at_utc'] = Variable<DateTime>(occurredAtUtc.value);
    }
    if (tzOffsetMin.present) {
      map['tz_offset_min'] = Variable<int>(tzOffsetMin.value);
    }
    if (contextA.present) {
      map['context_a'] = Variable<int>(contextA.value);
    }
    if (contextB.present) {
      map['context_b'] = Variable<int>(contextB.value);
    }
    if (contextC.present) {
      map['context_c'] = Variable<int>(contextC.value);
    }
    if (wasBoss.present) {
      map['was_boss'] = Variable<bool>(wasBoss.value);
    }
    if (duringDelay.present) {
      map['during_delay'] = Variable<bool>(duringDelay.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CigarettesCompanion(')
          ..write('id: $id, ')
          ..write('occurredAtUtc: $occurredAtUtc, ')
          ..write('tzOffsetMin: $tzOffsetMin, ')
          ..write('contextA: $contextA, ')
          ..write('contextB: $contextB, ')
          ..write('contextC: $contextC, ')
          ..write('wasBoss: $wasBoss, ')
          ..write('duringDelay: $duringDelay, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $JourneyEventsTable extends JourneyEvents
    with TableInfo<$JourneyEventsTable, JourneyEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JourneyEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occurredAtUtcMeta = const VerificationMeta(
    'occurredAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAtUtc =
      GeneratedColumn<DateTime>(
        'occurred_at_utc',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, occurredAtUtc, kind, payload];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'journey_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<JourneyEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('occurred_at_utc')) {
      context.handle(
        _occurredAtUtcMeta,
        occurredAtUtc.isAcceptableOrUnknown(
          data['occurred_at_utc']!,
          _occurredAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_occurredAtUtcMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  JourneyEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JourneyEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      occurredAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at_utc'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      ),
    );
  }

  @override
  $JourneyEventsTable createAlias(String alias) {
    return $JourneyEventsTable(attachedDatabase, alias);
  }
}

class JourneyEvent extends DataClass implements Insertable<JourneyEvent> {
  final String id;
  final DateTime occurredAtUtc;

  /// `JourneyEventKind.name`.
  final String kind;

  /// Données spécifiques à l'événement, en JSON (id du boss, mode cible…).
  final String? payload;
  const JourneyEvent({
    required this.id,
    required this.occurredAtUtc,
    required this.kind,
    this.payload,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['occurred_at_utc'] = Variable<DateTime>(occurredAtUtc);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || payload != null) {
      map['payload'] = Variable<String>(payload);
    }
    return map;
  }

  JourneyEventsCompanion toCompanion(bool nullToAbsent) {
    return JourneyEventsCompanion(
      id: Value(id),
      occurredAtUtc: Value(occurredAtUtc),
      kind: Value(kind),
      payload: payload == null && nullToAbsent
          ? const Value.absent()
          : Value(payload),
    );
  }

  factory JourneyEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JourneyEvent(
      id: serializer.fromJson<String>(json['id']),
      occurredAtUtc: serializer.fromJson<DateTime>(json['occurredAtUtc']),
      kind: serializer.fromJson<String>(json['kind']),
      payload: serializer.fromJson<String?>(json['payload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'occurredAtUtc': serializer.toJson<DateTime>(occurredAtUtc),
      'kind': serializer.toJson<String>(kind),
      'payload': serializer.toJson<String?>(payload),
    };
  }

  JourneyEvent copyWith({
    String? id,
    DateTime? occurredAtUtc,
    String? kind,
    Value<String?> payload = const Value.absent(),
  }) => JourneyEvent(
    id: id ?? this.id,
    occurredAtUtc: occurredAtUtc ?? this.occurredAtUtc,
    kind: kind ?? this.kind,
    payload: payload.present ? payload.value : this.payload,
  );
  JourneyEvent copyWithCompanion(JourneyEventsCompanion data) {
    return JourneyEvent(
      id: data.id.present ? data.id.value : this.id,
      occurredAtUtc: data.occurredAtUtc.present
          ? data.occurredAtUtc.value
          : this.occurredAtUtc,
      kind: data.kind.present ? data.kind.value : this.kind,
      payload: data.payload.present ? data.payload.value : this.payload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JourneyEvent(')
          ..write('id: $id, ')
          ..write('occurredAtUtc: $occurredAtUtc, ')
          ..write('kind: $kind, ')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, occurredAtUtc, kind, payload);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JourneyEvent &&
          other.id == this.id &&
          other.occurredAtUtc == this.occurredAtUtc &&
          other.kind == this.kind &&
          other.payload == this.payload);
}

class JourneyEventsCompanion extends UpdateCompanion<JourneyEvent> {
  final Value<String> id;
  final Value<DateTime> occurredAtUtc;
  final Value<String> kind;
  final Value<String?> payload;
  final Value<int> rowid;
  const JourneyEventsCompanion({
    this.id = const Value.absent(),
    this.occurredAtUtc = const Value.absent(),
    this.kind = const Value.absent(),
    this.payload = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  JourneyEventsCompanion.insert({
    required String id,
    required DateTime occurredAtUtc,
    required String kind,
    this.payload = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       occurredAtUtc = Value(occurredAtUtc),
       kind = Value(kind);
  static Insertable<JourneyEvent> custom({
    Expression<String>? id,
    Expression<DateTime>? occurredAtUtc,
    Expression<String>? kind,
    Expression<String>? payload,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (occurredAtUtc != null) 'occurred_at_utc': occurredAtUtc,
      if (kind != null) 'kind': kind,
      if (payload != null) 'payload': payload,
      if (rowid != null) 'rowid': rowid,
    });
  }

  JourneyEventsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? occurredAtUtc,
    Value<String>? kind,
    Value<String?>? payload,
    Value<int>? rowid,
  }) {
    return JourneyEventsCompanion(
      id: id ?? this.id,
      occurredAtUtc: occurredAtUtc ?? this.occurredAtUtc,
      kind: kind ?? this.kind,
      payload: payload ?? this.payload,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (occurredAtUtc.present) {
      map['occurred_at_utc'] = Variable<DateTime>(occurredAtUtc.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JourneyEventsCompanion(')
          ..write('id: $id, ')
          ..write('occurredAtUtc: $occurredAtUtc, ')
          ..write('kind: $kind, ')
          ..write('payload: $payload, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$CairnDatabase extends GeneratedDatabase {
  _$CairnDatabase(QueryExecutor e) : super(e);
  $CairnDatabaseManager get managers => $CairnDatabaseManager(this);
  late final $CigarettesTable cigarettes = $CigarettesTable(this);
  late final $JourneyEventsTable journeyEvents = $JourneyEventsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cigarettes,
    journeyEvents,
  ];
}

typedef $$CigarettesTableCreateCompanionBuilder =
    CigarettesCompanion Function({
      required String id,
      required DateTime occurredAtUtc,
      required int tzOffsetMin,
      Value<int?> contextA,
      Value<int?> contextB,
      Value<int?> contextC,
      Value<bool> wasBoss,
      Value<bool> duringDelay,
      Value<int> rowid,
    });
typedef $$CigarettesTableUpdateCompanionBuilder =
    CigarettesCompanion Function({
      Value<String> id,
      Value<DateTime> occurredAtUtc,
      Value<int> tzOffsetMin,
      Value<int?> contextA,
      Value<int?> contextB,
      Value<int?> contextC,
      Value<bool> wasBoss,
      Value<bool> duringDelay,
      Value<int> rowid,
    });

class $$CigarettesTableFilterComposer
    extends Composer<_$CairnDatabase, $CigarettesTable> {
  $$CigarettesTableFilterComposer({
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

  ColumnFilters<DateTime> get occurredAtUtc => $composableBuilder(
    column: $table.occurredAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tzOffsetMin => $composableBuilder(
    column: $table.tzOffsetMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get contextA => $composableBuilder(
    column: $table.contextA,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get contextB => $composableBuilder(
    column: $table.contextB,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get contextC => $composableBuilder(
    column: $table.contextC,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get wasBoss => $composableBuilder(
    column: $table.wasBoss,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get duringDelay => $composableBuilder(
    column: $table.duringDelay,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CigarettesTableOrderingComposer
    extends Composer<_$CairnDatabase, $CigarettesTable> {
  $$CigarettesTableOrderingComposer({
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

  ColumnOrderings<DateTime> get occurredAtUtc => $composableBuilder(
    column: $table.occurredAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tzOffsetMin => $composableBuilder(
    column: $table.tzOffsetMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get contextA => $composableBuilder(
    column: $table.contextA,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get contextB => $composableBuilder(
    column: $table.contextB,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get contextC => $composableBuilder(
    column: $table.contextC,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get wasBoss => $composableBuilder(
    column: $table.wasBoss,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get duringDelay => $composableBuilder(
    column: $table.duringDelay,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CigarettesTableAnnotationComposer
    extends Composer<_$CairnDatabase, $CigarettesTable> {
  $$CigarettesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get occurredAtUtc => $composableBuilder(
    column: $table.occurredAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tzOffsetMin => $composableBuilder(
    column: $table.tzOffsetMin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get contextA =>
      $composableBuilder(column: $table.contextA, builder: (column) => column);

  GeneratedColumn<int> get contextB =>
      $composableBuilder(column: $table.contextB, builder: (column) => column);

  GeneratedColumn<int> get contextC =>
      $composableBuilder(column: $table.contextC, builder: (column) => column);

  GeneratedColumn<bool> get wasBoss =>
      $composableBuilder(column: $table.wasBoss, builder: (column) => column);

  GeneratedColumn<bool> get duringDelay => $composableBuilder(
    column: $table.duringDelay,
    builder: (column) => column,
  );
}

class $$CigarettesTableTableManager
    extends
        RootTableManager<
          _$CairnDatabase,
          $CigarettesTable,
          Cigarette,
          $$CigarettesTableFilterComposer,
          $$CigarettesTableOrderingComposer,
          $$CigarettesTableAnnotationComposer,
          $$CigarettesTableCreateCompanionBuilder,
          $$CigarettesTableUpdateCompanionBuilder,
          (
            Cigarette,
            BaseReferences<_$CairnDatabase, $CigarettesTable, Cigarette>,
          ),
          Cigarette,
          PrefetchHooks Function()
        > {
  $$CigarettesTableTableManager(_$CairnDatabase db, $CigarettesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CigarettesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CigarettesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CigarettesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> occurredAtUtc = const Value.absent(),
                Value<int> tzOffsetMin = const Value.absent(),
                Value<int?> contextA = const Value.absent(),
                Value<int?> contextB = const Value.absent(),
                Value<int?> contextC = const Value.absent(),
                Value<bool> wasBoss = const Value.absent(),
                Value<bool> duringDelay = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CigarettesCompanion(
                id: id,
                occurredAtUtc: occurredAtUtc,
                tzOffsetMin: tzOffsetMin,
                contextA: contextA,
                contextB: contextB,
                contextC: contextC,
                wasBoss: wasBoss,
                duringDelay: duringDelay,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime occurredAtUtc,
                required int tzOffsetMin,
                Value<int?> contextA = const Value.absent(),
                Value<int?> contextB = const Value.absent(),
                Value<int?> contextC = const Value.absent(),
                Value<bool> wasBoss = const Value.absent(),
                Value<bool> duringDelay = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CigarettesCompanion.insert(
                id: id,
                occurredAtUtc: occurredAtUtc,
                tzOffsetMin: tzOffsetMin,
                contextA: contextA,
                contextB: contextB,
                contextC: contextC,
                wasBoss: wasBoss,
                duringDelay: duringDelay,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CigarettesTableProcessedTableManager =
    ProcessedTableManager<
      _$CairnDatabase,
      $CigarettesTable,
      Cigarette,
      $$CigarettesTableFilterComposer,
      $$CigarettesTableOrderingComposer,
      $$CigarettesTableAnnotationComposer,
      $$CigarettesTableCreateCompanionBuilder,
      $$CigarettesTableUpdateCompanionBuilder,
      (Cigarette, BaseReferences<_$CairnDatabase, $CigarettesTable, Cigarette>),
      Cigarette,
      PrefetchHooks Function()
    >;
typedef $$JourneyEventsTableCreateCompanionBuilder =
    JourneyEventsCompanion Function({
      required String id,
      required DateTime occurredAtUtc,
      required String kind,
      Value<String?> payload,
      Value<int> rowid,
    });
typedef $$JourneyEventsTableUpdateCompanionBuilder =
    JourneyEventsCompanion Function({
      Value<String> id,
      Value<DateTime> occurredAtUtc,
      Value<String> kind,
      Value<String?> payload,
      Value<int> rowid,
    });

class $$JourneyEventsTableFilterComposer
    extends Composer<_$CairnDatabase, $JourneyEventsTable> {
  $$JourneyEventsTableFilterComposer({
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

  ColumnFilters<DateTime> get occurredAtUtc => $composableBuilder(
    column: $table.occurredAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );
}

class $$JourneyEventsTableOrderingComposer
    extends Composer<_$CairnDatabase, $JourneyEventsTable> {
  $$JourneyEventsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get occurredAtUtc => $composableBuilder(
    column: $table.occurredAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$JourneyEventsTableAnnotationComposer
    extends Composer<_$CairnDatabase, $JourneyEventsTable> {
  $$JourneyEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get occurredAtUtc => $composableBuilder(
    column: $table.occurredAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);
}

class $$JourneyEventsTableTableManager
    extends
        RootTableManager<
          _$CairnDatabase,
          $JourneyEventsTable,
          JourneyEvent,
          $$JourneyEventsTableFilterComposer,
          $$JourneyEventsTableOrderingComposer,
          $$JourneyEventsTableAnnotationComposer,
          $$JourneyEventsTableCreateCompanionBuilder,
          $$JourneyEventsTableUpdateCompanionBuilder,
          (
            JourneyEvent,
            BaseReferences<_$CairnDatabase, $JourneyEventsTable, JourneyEvent>,
          ),
          JourneyEvent,
          PrefetchHooks Function()
        > {
  $$JourneyEventsTableTableManager(
    _$CairnDatabase db,
    $JourneyEventsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JourneyEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JourneyEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JourneyEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> occurredAtUtc = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String?> payload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JourneyEventsCompanion(
                id: id,
                occurredAtUtc: occurredAtUtc,
                kind: kind,
                payload: payload,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime occurredAtUtc,
                required String kind,
                Value<String?> payload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JourneyEventsCompanion.insert(
                id: id,
                occurredAtUtc: occurredAtUtc,
                kind: kind,
                payload: payload,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$JourneyEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$CairnDatabase,
      $JourneyEventsTable,
      JourneyEvent,
      $$JourneyEventsTableFilterComposer,
      $$JourneyEventsTableOrderingComposer,
      $$JourneyEventsTableAnnotationComposer,
      $$JourneyEventsTableCreateCompanionBuilder,
      $$JourneyEventsTableUpdateCompanionBuilder,
      (
        JourneyEvent,
        BaseReferences<_$CairnDatabase, $JourneyEventsTable, JourneyEvent>,
      ),
      JourneyEvent,
      PrefetchHooks Function()
    >;

class $CairnDatabaseManager {
  final _$CairnDatabase _db;
  $CairnDatabaseManager(this._db);
  $$CigarettesTableTableManager get cigarettes =>
      $$CigarettesTableTableManager(_db, _db.cigarettes);
  $$JourneyEventsTableTableManager get journeyEvents =>
      $$JourneyEventsTableTableManager(_db, _db.journeyEvents);
}
