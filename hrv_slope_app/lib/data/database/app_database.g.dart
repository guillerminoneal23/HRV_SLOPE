// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AthletesTable extends Athletes with TableInfo<$AthletesTable, Athlete> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AthletesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sportMeta = const VerificationMeta('sport');
  @override
  late final GeneratedColumn<String> sport = GeneratedColumn<String>(
    'sport',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _birthDateMeta = const VerificationMeta(
    'birthDate',
  );
  @override
  late final GeneratedColumn<String> birthDate = GeneratedColumn<String>(
    'birth_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _genderMeta = const VerificationMeta('gender');
  @override
  late final GeneratedColumn<String> gender = GeneratedColumn<String>(
    'gender',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _positionOrEventMeta = const VerificationMeta(
    'positionOrEvent',
  );
  @override
  late final GeneratedColumn<String> positionOrEvent = GeneratedColumn<String>(
    'position_or_event',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _masKmhMeta = const VerificationMeta('masKmh');
  @override
  late final GeneratedColumn<double> masKmh = GeneratedColumn<double>(
    'mas_kmh',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _vvo2maxKmhMeta = const VerificationMeta(
    'vvo2maxKmh',
  );
  @override
  late final GeneratedColumn<double> vvo2maxKmh = GeneratedColumn<double>(
    'vvo2max_kmh',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mapWMeta = const VerificationMeta('mapW');
  @override
  late final GeneratedColumn<double> mapW = GeneratedColumn<double>(
    'map_w',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fcMaxMeta = const VerificationMeta('fcMax');
  @override
  late final GeneratedColumn<double> fcMax = GeneratedColumn<double>(
    'fc_max',
    aliasedName,
    true,
    type: DriftSqlType.double,
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
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    sport,
    birthDate,
    gender,
    positionOrEvent,
    masKmh,
    vvo2maxKmh,
    mapW,
    fcMax,
    notes,
    isArchived,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'athletes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Athlete> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sport')) {
      context.handle(
        _sportMeta,
        sport.isAcceptableOrUnknown(data['sport']!, _sportMeta),
      );
    }
    if (data.containsKey('birth_date')) {
      context.handle(
        _birthDateMeta,
        birthDate.isAcceptableOrUnknown(data['birth_date']!, _birthDateMeta),
      );
    }
    if (data.containsKey('gender')) {
      context.handle(
        _genderMeta,
        gender.isAcceptableOrUnknown(data['gender']!, _genderMeta),
      );
    }
    if (data.containsKey('position_or_event')) {
      context.handle(
        _positionOrEventMeta,
        positionOrEvent.isAcceptableOrUnknown(
          data['position_or_event']!,
          _positionOrEventMeta,
        ),
      );
    }
    if (data.containsKey('mas_kmh')) {
      context.handle(
        _masKmhMeta,
        masKmh.isAcceptableOrUnknown(data['mas_kmh']!, _masKmhMeta),
      );
    }
    if (data.containsKey('vvo2max_kmh')) {
      context.handle(
        _vvo2maxKmhMeta,
        vvo2maxKmh.isAcceptableOrUnknown(data['vvo2max_kmh']!, _vvo2maxKmhMeta),
      );
    }
    if (data.containsKey('map_w')) {
      context.handle(
        _mapWMeta,
        mapW.isAcceptableOrUnknown(data['map_w']!, _mapWMeta),
      );
    }
    if (data.containsKey('fc_max')) {
      context.handle(
        _fcMaxMeta,
        fcMax.isAcceptableOrUnknown(data['fc_max']!, _fcMaxMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Athlete map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Athlete(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      sport: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sport'],
      ),
      birthDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}birth_date'],
      ),
      gender: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gender'],
      ),
      positionOrEvent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}position_or_event'],
      ),
      masKmh: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}mas_kmh'],
      ),
      vvo2maxKmh: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}vvo2max_kmh'],
      ),
      mapW: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}map_w'],
      ),
      fcMax: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fc_max'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AthletesTable createAlias(String alias) {
    return $AthletesTable(attachedDatabase, alias);
  }
}

class Athlete extends DataClass implements Insertable<Athlete> {
  final int id;
  final String name;
  final String? sport;
  final String? birthDate;
  final String? gender;
  final String? positionOrEvent;
  final double? masKmh;
  final double? vvo2maxKmh;
  final double? mapW;
  final double? fcMax;
  final String? notes;
  final bool isArchived;
  final String createdAt;
  final String updatedAt;
  const Athlete({
    required this.id,
    required this.name,
    this.sport,
    this.birthDate,
    this.gender,
    this.positionOrEvent,
    this.masKmh,
    this.vvo2maxKmh,
    this.mapW,
    this.fcMax,
    this.notes,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || sport != null) {
      map['sport'] = Variable<String>(sport);
    }
    if (!nullToAbsent || birthDate != null) {
      map['birth_date'] = Variable<String>(birthDate);
    }
    if (!nullToAbsent || gender != null) {
      map['gender'] = Variable<String>(gender);
    }
    if (!nullToAbsent || positionOrEvent != null) {
      map['position_or_event'] = Variable<String>(positionOrEvent);
    }
    if (!nullToAbsent || masKmh != null) {
      map['mas_kmh'] = Variable<double>(masKmh);
    }
    if (!nullToAbsent || vvo2maxKmh != null) {
      map['vvo2max_kmh'] = Variable<double>(vvo2maxKmh);
    }
    if (!nullToAbsent || mapW != null) {
      map['map_w'] = Variable<double>(mapW);
    }
    if (!nullToAbsent || fcMax != null) {
      map['fc_max'] = Variable<double>(fcMax);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['is_archived'] = Variable<bool>(isArchived);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  AthletesCompanion toCompanion(bool nullToAbsent) {
    return AthletesCompanion(
      id: Value(id),
      name: Value(name),
      sport: sport == null && nullToAbsent
          ? const Value.absent()
          : Value(sport),
      birthDate: birthDate == null && nullToAbsent
          ? const Value.absent()
          : Value(birthDate),
      gender: gender == null && nullToAbsent
          ? const Value.absent()
          : Value(gender),
      positionOrEvent: positionOrEvent == null && nullToAbsent
          ? const Value.absent()
          : Value(positionOrEvent),
      masKmh: masKmh == null && nullToAbsent
          ? const Value.absent()
          : Value(masKmh),
      vvo2maxKmh: vvo2maxKmh == null && nullToAbsent
          ? const Value.absent()
          : Value(vvo2maxKmh),
      mapW: mapW == null && nullToAbsent ? const Value.absent() : Value(mapW),
      fcMax: fcMax == null && nullToAbsent
          ? const Value.absent()
          : Value(fcMax),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      isArchived: Value(isArchived),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Athlete.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Athlete(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      sport: serializer.fromJson<String?>(json['sport']),
      birthDate: serializer.fromJson<String?>(json['birthDate']),
      gender: serializer.fromJson<String?>(json['gender']),
      positionOrEvent: serializer.fromJson<String?>(json['positionOrEvent']),
      masKmh: serializer.fromJson<double?>(json['masKmh']),
      vvo2maxKmh: serializer.fromJson<double?>(json['vvo2maxKmh']),
      mapW: serializer.fromJson<double?>(json['mapW']),
      fcMax: serializer.fromJson<double?>(json['fcMax']),
      notes: serializer.fromJson<String?>(json['notes']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'sport': serializer.toJson<String?>(sport),
      'birthDate': serializer.toJson<String?>(birthDate),
      'gender': serializer.toJson<String?>(gender),
      'positionOrEvent': serializer.toJson<String?>(positionOrEvent),
      'masKmh': serializer.toJson<double?>(masKmh),
      'vvo2maxKmh': serializer.toJson<double?>(vvo2maxKmh),
      'mapW': serializer.toJson<double?>(mapW),
      'fcMax': serializer.toJson<double?>(fcMax),
      'notes': serializer.toJson<String?>(notes),
      'isArchived': serializer.toJson<bool>(isArchived),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  Athlete copyWith({
    int? id,
    String? name,
    Value<String?> sport = const Value.absent(),
    Value<String?> birthDate = const Value.absent(),
    Value<String?> gender = const Value.absent(),
    Value<String?> positionOrEvent = const Value.absent(),
    Value<double?> masKmh = const Value.absent(),
    Value<double?> vvo2maxKmh = const Value.absent(),
    Value<double?> mapW = const Value.absent(),
    Value<double?> fcMax = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    bool? isArchived,
    String? createdAt,
    String? updatedAt,
  }) => Athlete(
    id: id ?? this.id,
    name: name ?? this.name,
    sport: sport.present ? sport.value : this.sport,
    birthDate: birthDate.present ? birthDate.value : this.birthDate,
    gender: gender.present ? gender.value : this.gender,
    positionOrEvent: positionOrEvent.present
        ? positionOrEvent.value
        : this.positionOrEvent,
    masKmh: masKmh.present ? masKmh.value : this.masKmh,
    vvo2maxKmh: vvo2maxKmh.present ? vvo2maxKmh.value : this.vvo2maxKmh,
    mapW: mapW.present ? mapW.value : this.mapW,
    fcMax: fcMax.present ? fcMax.value : this.fcMax,
    notes: notes.present ? notes.value : this.notes,
    isArchived: isArchived ?? this.isArchived,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Athlete copyWithCompanion(AthletesCompanion data) {
    return Athlete(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      sport: data.sport.present ? data.sport.value : this.sport,
      birthDate: data.birthDate.present ? data.birthDate.value : this.birthDate,
      gender: data.gender.present ? data.gender.value : this.gender,
      positionOrEvent: data.positionOrEvent.present
          ? data.positionOrEvent.value
          : this.positionOrEvent,
      masKmh: data.masKmh.present ? data.masKmh.value : this.masKmh,
      vvo2maxKmh: data.vvo2maxKmh.present
          ? data.vvo2maxKmh.value
          : this.vvo2maxKmh,
      mapW: data.mapW.present ? data.mapW.value : this.mapW,
      fcMax: data.fcMax.present ? data.fcMax.value : this.fcMax,
      notes: data.notes.present ? data.notes.value : this.notes,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Athlete(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sport: $sport, ')
          ..write('birthDate: $birthDate, ')
          ..write('gender: $gender, ')
          ..write('positionOrEvent: $positionOrEvent, ')
          ..write('masKmh: $masKmh, ')
          ..write('vvo2maxKmh: $vvo2maxKmh, ')
          ..write('mapW: $mapW, ')
          ..write('fcMax: $fcMax, ')
          ..write('notes: $notes, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    sport,
    birthDate,
    gender,
    positionOrEvent,
    masKmh,
    vvo2maxKmh,
    mapW,
    fcMax,
    notes,
    isArchived,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Athlete &&
          other.id == this.id &&
          other.name == this.name &&
          other.sport == this.sport &&
          other.birthDate == this.birthDate &&
          other.gender == this.gender &&
          other.positionOrEvent == this.positionOrEvent &&
          other.masKmh == this.masKmh &&
          other.vvo2maxKmh == this.vvo2maxKmh &&
          other.mapW == this.mapW &&
          other.fcMax == this.fcMax &&
          other.notes == this.notes &&
          other.isArchived == this.isArchived &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AthletesCompanion extends UpdateCompanion<Athlete> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> sport;
  final Value<String?> birthDate;
  final Value<String?> gender;
  final Value<String?> positionOrEvent;
  final Value<double?> masKmh;
  final Value<double?> vvo2maxKmh;
  final Value<double?> mapW;
  final Value<double?> fcMax;
  final Value<String?> notes;
  final Value<bool> isArchived;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  const AthletesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.sport = const Value.absent(),
    this.birthDate = const Value.absent(),
    this.gender = const Value.absent(),
    this.positionOrEvent = const Value.absent(),
    this.masKmh = const Value.absent(),
    this.vvo2maxKmh = const Value.absent(),
    this.mapW = const Value.absent(),
    this.fcMax = const Value.absent(),
    this.notes = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  AthletesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.sport = const Value.absent(),
    this.birthDate = const Value.absent(),
    this.gender = const Value.absent(),
    this.positionOrEvent = const Value.absent(),
    this.masKmh = const Value.absent(),
    this.vvo2maxKmh = const Value.absent(),
    this.mapW = const Value.absent(),
    this.fcMax = const Value.absent(),
    this.notes = const Value.absent(),
    this.isArchived = const Value.absent(),
    required String createdAt,
    required String updatedAt,
  }) : name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Athlete> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? sport,
    Expression<String>? birthDate,
    Expression<String>? gender,
    Expression<String>? positionOrEvent,
    Expression<double>? masKmh,
    Expression<double>? vvo2maxKmh,
    Expression<double>? mapW,
    Expression<double>? fcMax,
    Expression<String>? notes,
    Expression<bool>? isArchived,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (sport != null) 'sport': sport,
      if (birthDate != null) 'birth_date': birthDate,
      if (gender != null) 'gender': gender,
      if (positionOrEvent != null) 'position_or_event': positionOrEvent,
      if (masKmh != null) 'mas_kmh': masKmh,
      if (vvo2maxKmh != null) 'vvo2max_kmh': vvo2maxKmh,
      if (mapW != null) 'map_w': mapW,
      if (fcMax != null) 'fc_max': fcMax,
      if (notes != null) 'notes': notes,
      if (isArchived != null) 'is_archived': isArchived,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  AthletesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String?>? sport,
    Value<String?>? birthDate,
    Value<String?>? gender,
    Value<String?>? positionOrEvent,
    Value<double?>? masKmh,
    Value<double?>? vvo2maxKmh,
    Value<double?>? mapW,
    Value<double?>? fcMax,
    Value<String?>? notes,
    Value<bool>? isArchived,
    Value<String>? createdAt,
    Value<String>? updatedAt,
  }) {
    return AthletesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      sport: sport ?? this.sport,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      positionOrEvent: positionOrEvent ?? this.positionOrEvent,
      masKmh: masKmh ?? this.masKmh,
      vvo2maxKmh: vvo2maxKmh ?? this.vvo2maxKmh,
      mapW: mapW ?? this.mapW,
      fcMax: fcMax ?? this.fcMax,
      notes: notes ?? this.notes,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sport.present) {
      map['sport'] = Variable<String>(sport.value);
    }
    if (birthDate.present) {
      map['birth_date'] = Variable<String>(birthDate.value);
    }
    if (gender.present) {
      map['gender'] = Variable<String>(gender.value);
    }
    if (positionOrEvent.present) {
      map['position_or_event'] = Variable<String>(positionOrEvent.value);
    }
    if (masKmh.present) {
      map['mas_kmh'] = Variable<double>(masKmh.value);
    }
    if (vvo2maxKmh.present) {
      map['vvo2max_kmh'] = Variable<double>(vvo2maxKmh.value);
    }
    if (mapW.present) {
      map['map_w'] = Variable<double>(mapW.value);
    }
    if (fcMax.present) {
      map['fc_max'] = Variable<double>(fcMax.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AthletesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sport: $sport, ')
          ..write('birthDate: $birthDate, ')
          ..write('gender: $gender, ')
          ..write('positionOrEvent: $positionOrEvent, ')
          ..write('masKmh: $masKmh, ')
          ..write('vvo2maxKmh: $vvo2maxKmh, ')
          ..write('mapW: $mapW, ')
          ..write('fcMax: $fcMax, ')
          ..write('notes: $notes, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ImportBatchesTable extends ImportBatches
    with TableInfo<$ImportBatchesTable, ImportBatche> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ImportBatchesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _filenameMeta = const VerificationMeta(
    'filename',
  );
  @override
  late final GeneratedColumn<String> filename = GeneratedColumn<String>(
    'filename',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _importTypeMeta = const VerificationMeta(
    'importType',
  );
  @override
  late final GeneratedColumn<String> importType = GeneratedColumn<String>(
    'import_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rowCountMeta = const VerificationMeta(
    'rowCount',
  );
  @override
  late final GeneratedColumn<int> rowCount = GeneratedColumn<int>(
    'row_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _errorCountMeta = const VerificationMeta(
    'errorCount',
  );
  @override
  late final GeneratedColumn<int> errorCount = GeneratedColumn<int>(
    'error_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
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
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    filename,
    importType,
    rowCount,
    errorCount,
    notes,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'import_batches';
  @override
  VerificationContext validateIntegrity(
    Insertable<ImportBatche> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('filename')) {
      context.handle(
        _filenameMeta,
        filename.isAcceptableOrUnknown(data['filename']!, _filenameMeta),
      );
    }
    if (data.containsKey('import_type')) {
      context.handle(
        _importTypeMeta,
        importType.isAcceptableOrUnknown(data['import_type']!, _importTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_importTypeMeta);
    }
    if (data.containsKey('row_count')) {
      context.handle(
        _rowCountMeta,
        rowCount.isAcceptableOrUnknown(data['row_count']!, _rowCountMeta),
      );
    }
    if (data.containsKey('error_count')) {
      context.handle(
        _errorCountMeta,
        errorCount.isAcceptableOrUnknown(data['error_count']!, _errorCountMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
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
  ImportBatche map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ImportBatche(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      filename: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}filename'],
      ),
      importType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}import_type'],
      )!,
      rowCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}row_count'],
      ),
      errorCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}error_count'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ImportBatchesTable createAlias(String alias) {
    return $ImportBatchesTable(attachedDatabase, alias);
  }
}

class ImportBatche extends DataClass implements Insertable<ImportBatche> {
  final int id;
  final String? filename;
  final String importType;
  final int? rowCount;
  final int? errorCount;
  final String? notes;
  final String createdAt;
  const ImportBatche({
    required this.id,
    this.filename,
    required this.importType,
    this.rowCount,
    this.errorCount,
    this.notes,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || filename != null) {
      map['filename'] = Variable<String>(filename);
    }
    map['import_type'] = Variable<String>(importType);
    if (!nullToAbsent || rowCount != null) {
      map['row_count'] = Variable<int>(rowCount);
    }
    if (!nullToAbsent || errorCount != null) {
      map['error_count'] = Variable<int>(errorCount);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  ImportBatchesCompanion toCompanion(bool nullToAbsent) {
    return ImportBatchesCompanion(
      id: Value(id),
      filename: filename == null && nullToAbsent
          ? const Value.absent()
          : Value(filename),
      importType: Value(importType),
      rowCount: rowCount == null && nullToAbsent
          ? const Value.absent()
          : Value(rowCount),
      errorCount: errorCount == null && nullToAbsent
          ? const Value.absent()
          : Value(errorCount),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
    );
  }

  factory ImportBatche.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ImportBatche(
      id: serializer.fromJson<int>(json['id']),
      filename: serializer.fromJson<String?>(json['filename']),
      importType: serializer.fromJson<String>(json['importType']),
      rowCount: serializer.fromJson<int?>(json['rowCount']),
      errorCount: serializer.fromJson<int?>(json['errorCount']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'filename': serializer.toJson<String?>(filename),
      'importType': serializer.toJson<String>(importType),
      'rowCount': serializer.toJson<int?>(rowCount),
      'errorCount': serializer.toJson<int?>(errorCount),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  ImportBatche copyWith({
    int? id,
    Value<String?> filename = const Value.absent(),
    String? importType,
    Value<int?> rowCount = const Value.absent(),
    Value<int?> errorCount = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    String? createdAt,
  }) => ImportBatche(
    id: id ?? this.id,
    filename: filename.present ? filename.value : this.filename,
    importType: importType ?? this.importType,
    rowCount: rowCount.present ? rowCount.value : this.rowCount,
    errorCount: errorCount.present ? errorCount.value : this.errorCount,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
  );
  ImportBatche copyWithCompanion(ImportBatchesCompanion data) {
    return ImportBatche(
      id: data.id.present ? data.id.value : this.id,
      filename: data.filename.present ? data.filename.value : this.filename,
      importType: data.importType.present
          ? data.importType.value
          : this.importType,
      rowCount: data.rowCount.present ? data.rowCount.value : this.rowCount,
      errorCount: data.errorCount.present
          ? data.errorCount.value
          : this.errorCount,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ImportBatche(')
          ..write('id: $id, ')
          ..write('filename: $filename, ')
          ..write('importType: $importType, ')
          ..write('rowCount: $rowCount, ')
          ..write('errorCount: $errorCount, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    filename,
    importType,
    rowCount,
    errorCount,
    notes,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ImportBatche &&
          other.id == this.id &&
          other.filename == this.filename &&
          other.importType == this.importType &&
          other.rowCount == this.rowCount &&
          other.errorCount == this.errorCount &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt);
}

class ImportBatchesCompanion extends UpdateCompanion<ImportBatche> {
  final Value<int> id;
  final Value<String?> filename;
  final Value<String> importType;
  final Value<int?> rowCount;
  final Value<int?> errorCount;
  final Value<String?> notes;
  final Value<String> createdAt;
  const ImportBatchesCompanion({
    this.id = const Value.absent(),
    this.filename = const Value.absent(),
    this.importType = const Value.absent(),
    this.rowCount = const Value.absent(),
    this.errorCount = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ImportBatchesCompanion.insert({
    this.id = const Value.absent(),
    this.filename = const Value.absent(),
    required String importType,
    this.rowCount = const Value.absent(),
    this.errorCount = const Value.absent(),
    this.notes = const Value.absent(),
    required String createdAt,
  }) : importType = Value(importType),
       createdAt = Value(createdAt);
  static Insertable<ImportBatche> custom({
    Expression<int>? id,
    Expression<String>? filename,
    Expression<String>? importType,
    Expression<int>? rowCount,
    Expression<int>? errorCount,
    Expression<String>? notes,
    Expression<String>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (filename != null) 'filename': filename,
      if (importType != null) 'import_type': importType,
      if (rowCount != null) 'row_count': rowCount,
      if (errorCount != null) 'error_count': errorCount,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ImportBatchesCompanion copyWith({
    Value<int>? id,
    Value<String?>? filename,
    Value<String>? importType,
    Value<int?>? rowCount,
    Value<int?>? errorCount,
    Value<String?>? notes,
    Value<String>? createdAt,
  }) {
    return ImportBatchesCompanion(
      id: id ?? this.id,
      filename: filename ?? this.filename,
      importType: importType ?? this.importType,
      rowCount: rowCount ?? this.rowCount,
      errorCount: errorCount ?? this.errorCount,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (filename.present) {
      map['filename'] = Variable<String>(filename.value);
    }
    if (importType.present) {
      map['import_type'] = Variable<String>(importType.value);
    }
    if (rowCount.present) {
      map['row_count'] = Variable<int>(rowCount.value);
    }
    if (errorCount.present) {
      map['error_count'] = Variable<int>(errorCount.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ImportBatchesCompanion(')
          ..write('id: $id, ')
          ..write('filename: $filename, ')
          ..write('importType: $importType, ')
          ..write('rowCount: $rowCount, ')
          ..write('errorCount: $errorCount, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $SessionsTable extends Sessions with TableInfo<$SessionsTable, Session> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _athleteIdMeta = const VerificationMeta(
    'athleteId',
  );
  @override
  late final GeneratedColumn<int> athleteId = GeneratedColumn<int>(
    'athlete_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES athletes (id)',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taskNameMeta = const VerificationMeta(
    'taskName',
  );
  @override
  late final GeneratedColumn<String> taskName = GeneratedColumn<String>(
    'task_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sportMeta = const VerificationMeta('sport');
  @override
  late final GeneratedColumn<String> sport = GeneratedColumn<String>(
    'sport',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sessionTypeMeta = const VerificationMeta(
    'sessionType',
  );
  @override
  late final GeneratedColumn<String> sessionType = GeneratedColumn<String>(
    'session_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _protocolNameMeta = const VerificationMeta(
    'protocolName',
  );
  @override
  late final GeneratedColumn<String> protocolName = GeneratedColumn<String>(
    'protocol_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contextEnvironmentMeta =
      const VerificationMeta('contextEnvironment');
  @override
  late final GeneratedColumn<String> contextEnvironment =
      GeneratedColumn<String>(
        'context_environment',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _isDraftMeta = const VerificationMeta(
    'isDraft',
  );
  @override
  late final GeneratedColumn<bool> isDraft = GeneratedColumn<bool>(
    'is_draft',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_draft" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _intensityPercentMeta = const VerificationMeta(
    'intensityPercent',
  );
  @override
  late final GeneratedColumn<double> intensityPercent = GeneratedColumn<double>(
    'intensity_percent',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _intensitySourceMeta = const VerificationMeta(
    'intensitySource',
  );
  @override
  late final GeneratedColumn<String> intensitySource = GeneratedColumn<String>(
    'intensity_source',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recoveryTimeMinMeta = const VerificationMeta(
    'recoveryTimeMin',
  );
  @override
  late final GeneratedColumn<double> recoveryTimeMin = GeneratedColumn<double>(
    'recovery_time_min',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recoveryWindowStartMinMeta =
      const VerificationMeta('recoveryWindowStartMin');
  @override
  late final GeneratedColumn<double> recoveryWindowStartMin =
      GeneratedColumn<double>(
        'recovery_window_start_min',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _recoveryWindowEndMinMeta =
      const VerificationMeta('recoveryWindowEndMin');
  @override
  late final GeneratedColumn<double> recoveryWindowEndMin =
      GeneratedColumn<double>(
        'recovery_window_end_min',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _rmssdExerciseMeta = const VerificationMeta(
    'rmssdExercise',
  );
  @override
  late final GeneratedColumn<double> rmssdExercise = GeneratedColumn<double>(
    'rmssd_exercise',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rmssdExerciseIsDefaultMeta =
      const VerificationMeta('rmssdExerciseIsDefault');
  @override
  late final GeneratedColumn<bool> rmssdExerciseIsDefault =
      GeneratedColumn<bool>(
        'rmssd_exercise_is_default',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("rmssd_exercise_is_default" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _rmssdRecoveryMeta = const VerificationMeta(
    'rmssdRecovery',
  );
  @override
  late final GeneratedColumn<double> rmssdRecovery = GeneratedColumn<double>(
    'rmssd_recovery',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _slopeRawMeta = const VerificationMeta(
    'slopeRaw',
  );
  @override
  late final GeneratedColumn<double> slopeRaw = GeneratedColumn<double>(
    'slope_raw',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _slopeInterpretedMeta = const VerificationMeta(
    'slopeInterpreted',
  );
  @override
  late final GeneratedColumn<double> slopeInterpreted = GeneratedColumn<double>(
    'slope_interpreted',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _itlIndexMeta = const VerificationMeta(
    'itlIndex',
  );
  @override
  late final GeneratedColumn<double> itlIndex = GeneratedColumn<double>(
    'itl_index',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _classificationMeta = const VerificationMeta(
    'classification',
  );
  @override
  late final GeneratedColumn<String> classification = GeneratedColumn<String>(
    'classification',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hrvInputModeMeta = const VerificationMeta(
    'hrvInputMode',
  );
  @override
  late final GeneratedColumn<String> hrvInputMode = GeneratedColumn<String>(
    'hrv_input_mode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rmssdRecoverySourceMeta =
      const VerificationMeta('rmssdRecoverySource');
  @override
  late final GeneratedColumn<String> rmssdRecoverySource =
      GeneratedColumn<String>(
        'rmssd_recovery_source',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _rmssdExerciseSourceMeta =
      const VerificationMeta('rmssdExerciseSource');
  @override
  late final GeneratedColumn<String> rmssdExerciseSource =
      GeneratedColumn<String>(
        'rmssd_exercise_source',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _rrQualityFlagMeta = const VerificationMeta(
    'rrQualityFlag',
  );
  @override
  late final GeneratedColumn<String> rrQualityFlag = GeneratedColumn<String>(
    'rr_quality_flag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rrArtifactPercentMeta = const VerificationMeta(
    'rrArtifactPercent',
  );
  @override
  late final GeneratedColumn<double> rrArtifactPercent =
      GeneratedColumn<double>(
        'rr_artifact_percent',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _rrPreprocessingModeMeta =
      const VerificationMeta('rrPreprocessingMode');
  @override
  late final GeneratedColumn<String> rrPreprocessingMode =
      GeneratedColumn<String>(
        'rr_preprocessing_mode',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _rrCorrectionEnabledMeta =
      const VerificationMeta('rrCorrectionEnabled');
  @override
  late final GeneratedColumn<bool> rrCorrectionEnabled = GeneratedColumn<bool>(
    'rr_correction_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("rr_correction_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _rrCorrectionMethodMeta =
      const VerificationMeta('rrCorrectionMethod');
  @override
  late final GeneratedColumn<String> rrCorrectionMethod =
      GeneratedColumn<String>(
        'rr_correction_method',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _rrRawRmssdMeta = const VerificationMeta(
    'rrRawRmssd',
  );
  @override
  late final GeneratedColumn<double> rrRawRmssd = GeneratedColumn<double>(
    'rr_raw_rmssd',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rrCorrectedRmssdMeta = const VerificationMeta(
    'rrCorrectedRmssd',
  );
  @override
  late final GeneratedColumn<double> rrCorrectedRmssd = GeneratedColumn<double>(
    'rr_corrected_rmssd',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rrRmssdUsedMeta = const VerificationMeta(
    'rrRmssdUsed',
  );
  @override
  late final GeneratedColumn<double> rrRmssdUsed = GeneratedColumn<double>(
    'rr_rmssd_used',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rrArtifactCountMeta = const VerificationMeta(
    'rrArtifactCount',
  );
  @override
  late final GeneratedColumn<int> rrArtifactCount = GeneratedColumn<int>(
    'rr_artifact_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rrQualityDecisionMeta = const VerificationMeta(
    'rrQualityDecision',
  );
  @override
  late final GeneratedColumn<String> rrQualityDecision =
      GeneratedColumn<String>(
        'rr_quality_decision',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _rrQualityNotesJsonMeta =
      const VerificationMeta('rrQualityNotesJson');
  @override
  late final GeneratedColumn<String> rrQualityNotesJson =
      GeneratedColumn<String>(
        'rr_quality_notes_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _rrRmssdDeltaPercentMeta =
      const VerificationMeta('rrRmssdDeltaPercent');
  @override
  late final GeneratedColumn<double> rrRmssdDeltaPercent =
      GeneratedColumn<double>(
        'rr_rmssd_delta_percent',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _importBatchIdMeta = const VerificationMeta(
    'importBatchId',
  );
  @override
  late final GeneratedColumn<int> importBatchId = GeneratedColumn<int>(
    'import_batch_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES import_batches (id)',
    ),
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
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    athleteId,
    date,
    taskName,
    sport,
    sessionType,
    protocolName,
    contextEnvironment,
    isDraft,
    intensityPercent,
    intensitySource,
    recoveryTimeMin,
    recoveryWindowStartMin,
    recoveryWindowEndMin,
    rmssdExercise,
    rmssdExerciseIsDefault,
    rmssdRecovery,
    slopeRaw,
    slopeInterpreted,
    itlIndex,
    classification,
    hrvInputMode,
    rmssdRecoverySource,
    rmssdExerciseSource,
    rrQualityFlag,
    rrArtifactPercent,
    rrPreprocessingMode,
    rrCorrectionEnabled,
    rrCorrectionMethod,
    rrRawRmssd,
    rrCorrectedRmssd,
    rrRmssdUsed,
    rrArtifactCount,
    rrQualityDecision,
    rrQualityNotesJson,
    rrRmssdDeltaPercent,
    importBatchId,
    notes,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Session> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('athlete_id')) {
      context.handle(
        _athleteIdMeta,
        athleteId.isAcceptableOrUnknown(data['athlete_id']!, _athleteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_athleteIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('task_name')) {
      context.handle(
        _taskNameMeta,
        taskName.isAcceptableOrUnknown(data['task_name']!, _taskNameMeta),
      );
    }
    if (data.containsKey('sport')) {
      context.handle(
        _sportMeta,
        sport.isAcceptableOrUnknown(data['sport']!, _sportMeta),
      );
    }
    if (data.containsKey('session_type')) {
      context.handle(
        _sessionTypeMeta,
        sessionType.isAcceptableOrUnknown(
          data['session_type']!,
          _sessionTypeMeta,
        ),
      );
    }
    if (data.containsKey('protocol_name')) {
      context.handle(
        _protocolNameMeta,
        protocolName.isAcceptableOrUnknown(
          data['protocol_name']!,
          _protocolNameMeta,
        ),
      );
    }
    if (data.containsKey('context_environment')) {
      context.handle(
        _contextEnvironmentMeta,
        contextEnvironment.isAcceptableOrUnknown(
          data['context_environment']!,
          _contextEnvironmentMeta,
        ),
      );
    }
    if (data.containsKey('is_draft')) {
      context.handle(
        _isDraftMeta,
        isDraft.isAcceptableOrUnknown(data['is_draft']!, _isDraftMeta),
      );
    }
    if (data.containsKey('intensity_percent')) {
      context.handle(
        _intensityPercentMeta,
        intensityPercent.isAcceptableOrUnknown(
          data['intensity_percent']!,
          _intensityPercentMeta,
        ),
      );
    }
    if (data.containsKey('intensity_source')) {
      context.handle(
        _intensitySourceMeta,
        intensitySource.isAcceptableOrUnknown(
          data['intensity_source']!,
          _intensitySourceMeta,
        ),
      );
    }
    if (data.containsKey('recovery_time_min')) {
      context.handle(
        _recoveryTimeMinMeta,
        recoveryTimeMin.isAcceptableOrUnknown(
          data['recovery_time_min']!,
          _recoveryTimeMinMeta,
        ),
      );
    }
    if (data.containsKey('recovery_window_start_min')) {
      context.handle(
        _recoveryWindowStartMinMeta,
        recoveryWindowStartMin.isAcceptableOrUnknown(
          data['recovery_window_start_min']!,
          _recoveryWindowStartMinMeta,
        ),
      );
    }
    if (data.containsKey('recovery_window_end_min')) {
      context.handle(
        _recoveryWindowEndMinMeta,
        recoveryWindowEndMin.isAcceptableOrUnknown(
          data['recovery_window_end_min']!,
          _recoveryWindowEndMinMeta,
        ),
      );
    }
    if (data.containsKey('rmssd_exercise')) {
      context.handle(
        _rmssdExerciseMeta,
        rmssdExercise.isAcceptableOrUnknown(
          data['rmssd_exercise']!,
          _rmssdExerciseMeta,
        ),
      );
    }
    if (data.containsKey('rmssd_exercise_is_default')) {
      context.handle(
        _rmssdExerciseIsDefaultMeta,
        rmssdExerciseIsDefault.isAcceptableOrUnknown(
          data['rmssd_exercise_is_default']!,
          _rmssdExerciseIsDefaultMeta,
        ),
      );
    }
    if (data.containsKey('rmssd_recovery')) {
      context.handle(
        _rmssdRecoveryMeta,
        rmssdRecovery.isAcceptableOrUnknown(
          data['rmssd_recovery']!,
          _rmssdRecoveryMeta,
        ),
      );
    }
    if (data.containsKey('slope_raw')) {
      context.handle(
        _slopeRawMeta,
        slopeRaw.isAcceptableOrUnknown(data['slope_raw']!, _slopeRawMeta),
      );
    }
    if (data.containsKey('slope_interpreted')) {
      context.handle(
        _slopeInterpretedMeta,
        slopeInterpreted.isAcceptableOrUnknown(
          data['slope_interpreted']!,
          _slopeInterpretedMeta,
        ),
      );
    }
    if (data.containsKey('itl_index')) {
      context.handle(
        _itlIndexMeta,
        itlIndex.isAcceptableOrUnknown(data['itl_index']!, _itlIndexMeta),
      );
    }
    if (data.containsKey('classification')) {
      context.handle(
        _classificationMeta,
        classification.isAcceptableOrUnknown(
          data['classification']!,
          _classificationMeta,
        ),
      );
    }
    if (data.containsKey('hrv_input_mode')) {
      context.handle(
        _hrvInputModeMeta,
        hrvInputMode.isAcceptableOrUnknown(
          data['hrv_input_mode']!,
          _hrvInputModeMeta,
        ),
      );
    }
    if (data.containsKey('rmssd_recovery_source')) {
      context.handle(
        _rmssdRecoverySourceMeta,
        rmssdRecoverySource.isAcceptableOrUnknown(
          data['rmssd_recovery_source']!,
          _rmssdRecoverySourceMeta,
        ),
      );
    }
    if (data.containsKey('rmssd_exercise_source')) {
      context.handle(
        _rmssdExerciseSourceMeta,
        rmssdExerciseSource.isAcceptableOrUnknown(
          data['rmssd_exercise_source']!,
          _rmssdExerciseSourceMeta,
        ),
      );
    }
    if (data.containsKey('rr_quality_flag')) {
      context.handle(
        _rrQualityFlagMeta,
        rrQualityFlag.isAcceptableOrUnknown(
          data['rr_quality_flag']!,
          _rrQualityFlagMeta,
        ),
      );
    }
    if (data.containsKey('rr_artifact_percent')) {
      context.handle(
        _rrArtifactPercentMeta,
        rrArtifactPercent.isAcceptableOrUnknown(
          data['rr_artifact_percent']!,
          _rrArtifactPercentMeta,
        ),
      );
    }
    if (data.containsKey('rr_preprocessing_mode')) {
      context.handle(
        _rrPreprocessingModeMeta,
        rrPreprocessingMode.isAcceptableOrUnknown(
          data['rr_preprocessing_mode']!,
          _rrPreprocessingModeMeta,
        ),
      );
    }
    if (data.containsKey('rr_correction_enabled')) {
      context.handle(
        _rrCorrectionEnabledMeta,
        rrCorrectionEnabled.isAcceptableOrUnknown(
          data['rr_correction_enabled']!,
          _rrCorrectionEnabledMeta,
        ),
      );
    }
    if (data.containsKey('rr_correction_method')) {
      context.handle(
        _rrCorrectionMethodMeta,
        rrCorrectionMethod.isAcceptableOrUnknown(
          data['rr_correction_method']!,
          _rrCorrectionMethodMeta,
        ),
      );
    }
    if (data.containsKey('rr_raw_rmssd')) {
      context.handle(
        _rrRawRmssdMeta,
        rrRawRmssd.isAcceptableOrUnknown(
          data['rr_raw_rmssd']!,
          _rrRawRmssdMeta,
        ),
      );
    }
    if (data.containsKey('rr_corrected_rmssd')) {
      context.handle(
        _rrCorrectedRmssdMeta,
        rrCorrectedRmssd.isAcceptableOrUnknown(
          data['rr_corrected_rmssd']!,
          _rrCorrectedRmssdMeta,
        ),
      );
    }
    if (data.containsKey('rr_rmssd_used')) {
      context.handle(
        _rrRmssdUsedMeta,
        rrRmssdUsed.isAcceptableOrUnknown(
          data['rr_rmssd_used']!,
          _rrRmssdUsedMeta,
        ),
      );
    }
    if (data.containsKey('rr_artifact_count')) {
      context.handle(
        _rrArtifactCountMeta,
        rrArtifactCount.isAcceptableOrUnknown(
          data['rr_artifact_count']!,
          _rrArtifactCountMeta,
        ),
      );
    }
    if (data.containsKey('rr_quality_decision')) {
      context.handle(
        _rrQualityDecisionMeta,
        rrQualityDecision.isAcceptableOrUnknown(
          data['rr_quality_decision']!,
          _rrQualityDecisionMeta,
        ),
      );
    }
    if (data.containsKey('rr_quality_notes_json')) {
      context.handle(
        _rrQualityNotesJsonMeta,
        rrQualityNotesJson.isAcceptableOrUnknown(
          data['rr_quality_notes_json']!,
          _rrQualityNotesJsonMeta,
        ),
      );
    }
    if (data.containsKey('rr_rmssd_delta_percent')) {
      context.handle(
        _rrRmssdDeltaPercentMeta,
        rrRmssdDeltaPercent.isAcceptableOrUnknown(
          data['rr_rmssd_delta_percent']!,
          _rrRmssdDeltaPercentMeta,
        ),
      );
    }
    if (data.containsKey('import_batch_id')) {
      context.handle(
        _importBatchIdMeta,
        importBatchId.isAcceptableOrUnknown(
          data['import_batch_id']!,
          _importBatchIdMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
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
  Session map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Session(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      athleteId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}athlete_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      taskName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_name'],
      ),
      sport: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sport'],
      ),
      sessionType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_type'],
      ),
      protocolName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}protocol_name'],
      ),
      contextEnvironment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}context_environment'],
      ),
      isDraft: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_draft'],
      )!,
      intensityPercent: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}intensity_percent'],
      ),
      intensitySource: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}intensity_source'],
      ),
      recoveryTimeMin: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}recovery_time_min'],
      ),
      recoveryWindowStartMin: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}recovery_window_start_min'],
      ),
      recoveryWindowEndMin: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}recovery_window_end_min'],
      ),
      rmssdExercise: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rmssd_exercise'],
      ),
      rmssdExerciseIsDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}rmssd_exercise_is_default'],
      )!,
      rmssdRecovery: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rmssd_recovery'],
      ),
      slopeRaw: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}slope_raw'],
      ),
      slopeInterpreted: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}slope_interpreted'],
      ),
      itlIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}itl_index'],
      ),
      classification: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}classification'],
      ),
      hrvInputMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hrv_input_mode'],
      ),
      rmssdRecoverySource: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rmssd_recovery_source'],
      ),
      rmssdExerciseSource: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rmssd_exercise_source'],
      ),
      rrQualityFlag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rr_quality_flag'],
      ),
      rrArtifactPercent: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rr_artifact_percent'],
      ),
      rrPreprocessingMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rr_preprocessing_mode'],
      ),
      rrCorrectionEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}rr_correction_enabled'],
      )!,
      rrCorrectionMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rr_correction_method'],
      ),
      rrRawRmssd: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rr_raw_rmssd'],
      ),
      rrCorrectedRmssd: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rr_corrected_rmssd'],
      ),
      rrRmssdUsed: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rr_rmssd_used'],
      ),
      rrArtifactCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rr_artifact_count'],
      ),
      rrQualityDecision: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rr_quality_decision'],
      ),
      rrQualityNotesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rr_quality_notes_json'],
      ),
      rrRmssdDeltaPercent: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rr_rmssd_delta_percent'],
      ),
      importBatchId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}import_batch_id'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }
}

class Session extends DataClass implements Insertable<Session> {
  final int id;
  final int athleteId;
  final String date;
  final String? taskName;
  final String? sport;
  final String? sessionType;
  final String? protocolName;
  final String? contextEnvironment;
  final bool isDraft;
  final double? intensityPercent;
  final String? intensitySource;
  final double? recoveryTimeMin;
  final double? recoveryWindowStartMin;
  final double? recoveryWindowEndMin;
  final double? rmssdExercise;
  final bool rmssdExerciseIsDefault;
  final double? rmssdRecovery;
  final double? slopeRaw;
  final double? slopeInterpreted;
  final double? itlIndex;
  final String? classification;
  final String? hrvInputMode;
  final String? rmssdRecoverySource;
  final String? rmssdExerciseSource;
  final String? rrQualityFlag;
  final double? rrArtifactPercent;
  final String? rrPreprocessingMode;
  final bool rrCorrectionEnabled;
  final String? rrCorrectionMethod;
  final double? rrRawRmssd;
  final double? rrCorrectedRmssd;
  final double? rrRmssdUsed;
  final int? rrArtifactCount;
  final String? rrQualityDecision;
  final String? rrQualityNotesJson;
  final double? rrRmssdDeltaPercent;
  final int? importBatchId;
  final String? notes;
  final String createdAt;
  const Session({
    required this.id,
    required this.athleteId,
    required this.date,
    this.taskName,
    this.sport,
    this.sessionType,
    this.protocolName,
    this.contextEnvironment,
    required this.isDraft,
    this.intensityPercent,
    this.intensitySource,
    this.recoveryTimeMin,
    this.recoveryWindowStartMin,
    this.recoveryWindowEndMin,
    this.rmssdExercise,
    required this.rmssdExerciseIsDefault,
    this.rmssdRecovery,
    this.slopeRaw,
    this.slopeInterpreted,
    this.itlIndex,
    this.classification,
    this.hrvInputMode,
    this.rmssdRecoverySource,
    this.rmssdExerciseSource,
    this.rrQualityFlag,
    this.rrArtifactPercent,
    this.rrPreprocessingMode,
    required this.rrCorrectionEnabled,
    this.rrCorrectionMethod,
    this.rrRawRmssd,
    this.rrCorrectedRmssd,
    this.rrRmssdUsed,
    this.rrArtifactCount,
    this.rrQualityDecision,
    this.rrQualityNotesJson,
    this.rrRmssdDeltaPercent,
    this.importBatchId,
    this.notes,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['athlete_id'] = Variable<int>(athleteId);
    map['date'] = Variable<String>(date);
    if (!nullToAbsent || taskName != null) {
      map['task_name'] = Variable<String>(taskName);
    }
    if (!nullToAbsent || sport != null) {
      map['sport'] = Variable<String>(sport);
    }
    if (!nullToAbsent || sessionType != null) {
      map['session_type'] = Variable<String>(sessionType);
    }
    if (!nullToAbsent || protocolName != null) {
      map['protocol_name'] = Variable<String>(protocolName);
    }
    if (!nullToAbsent || contextEnvironment != null) {
      map['context_environment'] = Variable<String>(contextEnvironment);
    }
    map['is_draft'] = Variable<bool>(isDraft);
    if (!nullToAbsent || intensityPercent != null) {
      map['intensity_percent'] = Variable<double>(intensityPercent);
    }
    if (!nullToAbsent || intensitySource != null) {
      map['intensity_source'] = Variable<String>(intensitySource);
    }
    if (!nullToAbsent || recoveryTimeMin != null) {
      map['recovery_time_min'] = Variable<double>(recoveryTimeMin);
    }
    if (!nullToAbsent || recoveryWindowStartMin != null) {
      map['recovery_window_start_min'] = Variable<double>(
        recoveryWindowStartMin,
      );
    }
    if (!nullToAbsent || recoveryWindowEndMin != null) {
      map['recovery_window_end_min'] = Variable<double>(recoveryWindowEndMin);
    }
    if (!nullToAbsent || rmssdExercise != null) {
      map['rmssd_exercise'] = Variable<double>(rmssdExercise);
    }
    map['rmssd_exercise_is_default'] = Variable<bool>(rmssdExerciseIsDefault);
    if (!nullToAbsent || rmssdRecovery != null) {
      map['rmssd_recovery'] = Variable<double>(rmssdRecovery);
    }
    if (!nullToAbsent || slopeRaw != null) {
      map['slope_raw'] = Variable<double>(slopeRaw);
    }
    if (!nullToAbsent || slopeInterpreted != null) {
      map['slope_interpreted'] = Variable<double>(slopeInterpreted);
    }
    if (!nullToAbsent || itlIndex != null) {
      map['itl_index'] = Variable<double>(itlIndex);
    }
    if (!nullToAbsent || classification != null) {
      map['classification'] = Variable<String>(classification);
    }
    if (!nullToAbsent || hrvInputMode != null) {
      map['hrv_input_mode'] = Variable<String>(hrvInputMode);
    }
    if (!nullToAbsent || rmssdRecoverySource != null) {
      map['rmssd_recovery_source'] = Variable<String>(rmssdRecoverySource);
    }
    if (!nullToAbsent || rmssdExerciseSource != null) {
      map['rmssd_exercise_source'] = Variable<String>(rmssdExerciseSource);
    }
    if (!nullToAbsent || rrQualityFlag != null) {
      map['rr_quality_flag'] = Variable<String>(rrQualityFlag);
    }
    if (!nullToAbsent || rrArtifactPercent != null) {
      map['rr_artifact_percent'] = Variable<double>(rrArtifactPercent);
    }
    if (!nullToAbsent || rrPreprocessingMode != null) {
      map['rr_preprocessing_mode'] = Variable<String>(rrPreprocessingMode);
    }
    map['rr_correction_enabled'] = Variable<bool>(rrCorrectionEnabled);
    if (!nullToAbsent || rrCorrectionMethod != null) {
      map['rr_correction_method'] = Variable<String>(rrCorrectionMethod);
    }
    if (!nullToAbsent || rrRawRmssd != null) {
      map['rr_raw_rmssd'] = Variable<double>(rrRawRmssd);
    }
    if (!nullToAbsent || rrCorrectedRmssd != null) {
      map['rr_corrected_rmssd'] = Variable<double>(rrCorrectedRmssd);
    }
    if (!nullToAbsent || rrRmssdUsed != null) {
      map['rr_rmssd_used'] = Variable<double>(rrRmssdUsed);
    }
    if (!nullToAbsent || rrArtifactCount != null) {
      map['rr_artifact_count'] = Variable<int>(rrArtifactCount);
    }
    if (!nullToAbsent || rrQualityDecision != null) {
      map['rr_quality_decision'] = Variable<String>(rrQualityDecision);
    }
    if (!nullToAbsent || rrQualityNotesJson != null) {
      map['rr_quality_notes_json'] = Variable<String>(rrQualityNotesJson);
    }
    if (!nullToAbsent || rrRmssdDeltaPercent != null) {
      map['rr_rmssd_delta_percent'] = Variable<double>(rrRmssdDeltaPercent);
    }
    if (!nullToAbsent || importBatchId != null) {
      map['import_batch_id'] = Variable<int>(importBatchId);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      id: Value(id),
      athleteId: Value(athleteId),
      date: Value(date),
      taskName: taskName == null && nullToAbsent
          ? const Value.absent()
          : Value(taskName),
      sport: sport == null && nullToAbsent
          ? const Value.absent()
          : Value(sport),
      sessionType: sessionType == null && nullToAbsent
          ? const Value.absent()
          : Value(sessionType),
      protocolName: protocolName == null && nullToAbsent
          ? const Value.absent()
          : Value(protocolName),
      contextEnvironment: contextEnvironment == null && nullToAbsent
          ? const Value.absent()
          : Value(contextEnvironment),
      isDraft: Value(isDraft),
      intensityPercent: intensityPercent == null && nullToAbsent
          ? const Value.absent()
          : Value(intensityPercent),
      intensitySource: intensitySource == null && nullToAbsent
          ? const Value.absent()
          : Value(intensitySource),
      recoveryTimeMin: recoveryTimeMin == null && nullToAbsent
          ? const Value.absent()
          : Value(recoveryTimeMin),
      recoveryWindowStartMin: recoveryWindowStartMin == null && nullToAbsent
          ? const Value.absent()
          : Value(recoveryWindowStartMin),
      recoveryWindowEndMin: recoveryWindowEndMin == null && nullToAbsent
          ? const Value.absent()
          : Value(recoveryWindowEndMin),
      rmssdExercise: rmssdExercise == null && nullToAbsent
          ? const Value.absent()
          : Value(rmssdExercise),
      rmssdExerciseIsDefault: Value(rmssdExerciseIsDefault),
      rmssdRecovery: rmssdRecovery == null && nullToAbsent
          ? const Value.absent()
          : Value(rmssdRecovery),
      slopeRaw: slopeRaw == null && nullToAbsent
          ? const Value.absent()
          : Value(slopeRaw),
      slopeInterpreted: slopeInterpreted == null && nullToAbsent
          ? const Value.absent()
          : Value(slopeInterpreted),
      itlIndex: itlIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(itlIndex),
      classification: classification == null && nullToAbsent
          ? const Value.absent()
          : Value(classification),
      hrvInputMode: hrvInputMode == null && nullToAbsent
          ? const Value.absent()
          : Value(hrvInputMode),
      rmssdRecoverySource: rmssdRecoverySource == null && nullToAbsent
          ? const Value.absent()
          : Value(rmssdRecoverySource),
      rmssdExerciseSource: rmssdExerciseSource == null && nullToAbsent
          ? const Value.absent()
          : Value(rmssdExerciseSource),
      rrQualityFlag: rrQualityFlag == null && nullToAbsent
          ? const Value.absent()
          : Value(rrQualityFlag),
      rrArtifactPercent: rrArtifactPercent == null && nullToAbsent
          ? const Value.absent()
          : Value(rrArtifactPercent),
      rrPreprocessingMode: rrPreprocessingMode == null && nullToAbsent
          ? const Value.absent()
          : Value(rrPreprocessingMode),
      rrCorrectionEnabled: Value(rrCorrectionEnabled),
      rrCorrectionMethod: rrCorrectionMethod == null && nullToAbsent
          ? const Value.absent()
          : Value(rrCorrectionMethod),
      rrRawRmssd: rrRawRmssd == null && nullToAbsent
          ? const Value.absent()
          : Value(rrRawRmssd),
      rrCorrectedRmssd: rrCorrectedRmssd == null && nullToAbsent
          ? const Value.absent()
          : Value(rrCorrectedRmssd),
      rrRmssdUsed: rrRmssdUsed == null && nullToAbsent
          ? const Value.absent()
          : Value(rrRmssdUsed),
      rrArtifactCount: rrArtifactCount == null && nullToAbsent
          ? const Value.absent()
          : Value(rrArtifactCount),
      rrQualityDecision: rrQualityDecision == null && nullToAbsent
          ? const Value.absent()
          : Value(rrQualityDecision),
      rrQualityNotesJson: rrQualityNotesJson == null && nullToAbsent
          ? const Value.absent()
          : Value(rrQualityNotesJson),
      rrRmssdDeltaPercent: rrRmssdDeltaPercent == null && nullToAbsent
          ? const Value.absent()
          : Value(rrRmssdDeltaPercent),
      importBatchId: importBatchId == null && nullToAbsent
          ? const Value.absent()
          : Value(importBatchId),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
    );
  }

  factory Session.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Session(
      id: serializer.fromJson<int>(json['id']),
      athleteId: serializer.fromJson<int>(json['athleteId']),
      date: serializer.fromJson<String>(json['date']),
      taskName: serializer.fromJson<String?>(json['taskName']),
      sport: serializer.fromJson<String?>(json['sport']),
      sessionType: serializer.fromJson<String?>(json['sessionType']),
      protocolName: serializer.fromJson<String?>(json['protocolName']),
      contextEnvironment: serializer.fromJson<String?>(
        json['contextEnvironment'],
      ),
      isDraft: serializer.fromJson<bool>(json['isDraft']),
      intensityPercent: serializer.fromJson<double?>(json['intensityPercent']),
      intensitySource: serializer.fromJson<String?>(json['intensitySource']),
      recoveryTimeMin: serializer.fromJson<double?>(json['recoveryTimeMin']),
      recoveryWindowStartMin: serializer.fromJson<double?>(
        json['recoveryWindowStartMin'],
      ),
      recoveryWindowEndMin: serializer.fromJson<double?>(
        json['recoveryWindowEndMin'],
      ),
      rmssdExercise: serializer.fromJson<double?>(json['rmssdExercise']),
      rmssdExerciseIsDefault: serializer.fromJson<bool>(
        json['rmssdExerciseIsDefault'],
      ),
      rmssdRecovery: serializer.fromJson<double?>(json['rmssdRecovery']),
      slopeRaw: serializer.fromJson<double?>(json['slopeRaw']),
      slopeInterpreted: serializer.fromJson<double?>(json['slopeInterpreted']),
      itlIndex: serializer.fromJson<double?>(json['itlIndex']),
      classification: serializer.fromJson<String?>(json['classification']),
      hrvInputMode: serializer.fromJson<String?>(json['hrvInputMode']),
      rmssdRecoverySource: serializer.fromJson<String?>(
        json['rmssdRecoverySource'],
      ),
      rmssdExerciseSource: serializer.fromJson<String?>(
        json['rmssdExerciseSource'],
      ),
      rrQualityFlag: serializer.fromJson<String?>(json['rrQualityFlag']),
      rrArtifactPercent: serializer.fromJson<double?>(
        json['rrArtifactPercent'],
      ),
      rrPreprocessingMode: serializer.fromJson<String?>(
        json['rrPreprocessingMode'],
      ),
      rrCorrectionEnabled: serializer.fromJson<bool>(
        json['rrCorrectionEnabled'],
      ),
      rrCorrectionMethod: serializer.fromJson<String?>(
        json['rrCorrectionMethod'],
      ),
      rrRawRmssd: serializer.fromJson<double?>(json['rrRawRmssd']),
      rrCorrectedRmssd: serializer.fromJson<double?>(json['rrCorrectedRmssd']),
      rrRmssdUsed: serializer.fromJson<double?>(json['rrRmssdUsed']),
      rrArtifactCount: serializer.fromJson<int?>(json['rrArtifactCount']),
      rrQualityDecision: serializer.fromJson<String?>(
        json['rrQualityDecision'],
      ),
      rrQualityNotesJson: serializer.fromJson<String?>(
        json['rrQualityNotesJson'],
      ),
      rrRmssdDeltaPercent: serializer.fromJson<double?>(
        json['rrRmssdDeltaPercent'],
      ),
      importBatchId: serializer.fromJson<int?>(json['importBatchId']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'athleteId': serializer.toJson<int>(athleteId),
      'date': serializer.toJson<String>(date),
      'taskName': serializer.toJson<String?>(taskName),
      'sport': serializer.toJson<String?>(sport),
      'sessionType': serializer.toJson<String?>(sessionType),
      'protocolName': serializer.toJson<String?>(protocolName),
      'contextEnvironment': serializer.toJson<String?>(contextEnvironment),
      'isDraft': serializer.toJson<bool>(isDraft),
      'intensityPercent': serializer.toJson<double?>(intensityPercent),
      'intensitySource': serializer.toJson<String?>(intensitySource),
      'recoveryTimeMin': serializer.toJson<double?>(recoveryTimeMin),
      'recoveryWindowStartMin': serializer.toJson<double?>(
        recoveryWindowStartMin,
      ),
      'recoveryWindowEndMin': serializer.toJson<double?>(recoveryWindowEndMin),
      'rmssdExercise': serializer.toJson<double?>(rmssdExercise),
      'rmssdExerciseIsDefault': serializer.toJson<bool>(rmssdExerciseIsDefault),
      'rmssdRecovery': serializer.toJson<double?>(rmssdRecovery),
      'slopeRaw': serializer.toJson<double?>(slopeRaw),
      'slopeInterpreted': serializer.toJson<double?>(slopeInterpreted),
      'itlIndex': serializer.toJson<double?>(itlIndex),
      'classification': serializer.toJson<String?>(classification),
      'hrvInputMode': serializer.toJson<String?>(hrvInputMode),
      'rmssdRecoverySource': serializer.toJson<String?>(rmssdRecoverySource),
      'rmssdExerciseSource': serializer.toJson<String?>(rmssdExerciseSource),
      'rrQualityFlag': serializer.toJson<String?>(rrQualityFlag),
      'rrArtifactPercent': serializer.toJson<double?>(rrArtifactPercent),
      'rrPreprocessingMode': serializer.toJson<String?>(rrPreprocessingMode),
      'rrCorrectionEnabled': serializer.toJson<bool>(rrCorrectionEnabled),
      'rrCorrectionMethod': serializer.toJson<String?>(rrCorrectionMethod),
      'rrRawRmssd': serializer.toJson<double?>(rrRawRmssd),
      'rrCorrectedRmssd': serializer.toJson<double?>(rrCorrectedRmssd),
      'rrRmssdUsed': serializer.toJson<double?>(rrRmssdUsed),
      'rrArtifactCount': serializer.toJson<int?>(rrArtifactCount),
      'rrQualityDecision': serializer.toJson<String?>(rrQualityDecision),
      'rrQualityNotesJson': serializer.toJson<String?>(rrQualityNotesJson),
      'rrRmssdDeltaPercent': serializer.toJson<double?>(rrRmssdDeltaPercent),
      'importBatchId': serializer.toJson<int?>(importBatchId),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  Session copyWith({
    int? id,
    int? athleteId,
    String? date,
    Value<String?> taskName = const Value.absent(),
    Value<String?> sport = const Value.absent(),
    Value<String?> sessionType = const Value.absent(),
    Value<String?> protocolName = const Value.absent(),
    Value<String?> contextEnvironment = const Value.absent(),
    bool? isDraft,
    Value<double?> intensityPercent = const Value.absent(),
    Value<String?> intensitySource = const Value.absent(),
    Value<double?> recoveryTimeMin = const Value.absent(),
    Value<double?> recoveryWindowStartMin = const Value.absent(),
    Value<double?> recoveryWindowEndMin = const Value.absent(),
    Value<double?> rmssdExercise = const Value.absent(),
    bool? rmssdExerciseIsDefault,
    Value<double?> rmssdRecovery = const Value.absent(),
    Value<double?> slopeRaw = const Value.absent(),
    Value<double?> slopeInterpreted = const Value.absent(),
    Value<double?> itlIndex = const Value.absent(),
    Value<String?> classification = const Value.absent(),
    Value<String?> hrvInputMode = const Value.absent(),
    Value<String?> rmssdRecoverySource = const Value.absent(),
    Value<String?> rmssdExerciseSource = const Value.absent(),
    Value<String?> rrQualityFlag = const Value.absent(),
    Value<double?> rrArtifactPercent = const Value.absent(),
    Value<String?> rrPreprocessingMode = const Value.absent(),
    bool? rrCorrectionEnabled,
    Value<String?> rrCorrectionMethod = const Value.absent(),
    Value<double?> rrRawRmssd = const Value.absent(),
    Value<double?> rrCorrectedRmssd = const Value.absent(),
    Value<double?> rrRmssdUsed = const Value.absent(),
    Value<int?> rrArtifactCount = const Value.absent(),
    Value<String?> rrQualityDecision = const Value.absent(),
    Value<String?> rrQualityNotesJson = const Value.absent(),
    Value<double?> rrRmssdDeltaPercent = const Value.absent(),
    Value<int?> importBatchId = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    String? createdAt,
  }) => Session(
    id: id ?? this.id,
    athleteId: athleteId ?? this.athleteId,
    date: date ?? this.date,
    taskName: taskName.present ? taskName.value : this.taskName,
    sport: sport.present ? sport.value : this.sport,
    sessionType: sessionType.present ? sessionType.value : this.sessionType,
    protocolName: protocolName.present ? protocolName.value : this.protocolName,
    contextEnvironment: contextEnvironment.present
        ? contextEnvironment.value
        : this.contextEnvironment,
    isDraft: isDraft ?? this.isDraft,
    intensityPercent: intensityPercent.present
        ? intensityPercent.value
        : this.intensityPercent,
    intensitySource: intensitySource.present
        ? intensitySource.value
        : this.intensitySource,
    recoveryTimeMin: recoveryTimeMin.present
        ? recoveryTimeMin.value
        : this.recoveryTimeMin,
    recoveryWindowStartMin: recoveryWindowStartMin.present
        ? recoveryWindowStartMin.value
        : this.recoveryWindowStartMin,
    recoveryWindowEndMin: recoveryWindowEndMin.present
        ? recoveryWindowEndMin.value
        : this.recoveryWindowEndMin,
    rmssdExercise: rmssdExercise.present
        ? rmssdExercise.value
        : this.rmssdExercise,
    rmssdExerciseIsDefault:
        rmssdExerciseIsDefault ?? this.rmssdExerciseIsDefault,
    rmssdRecovery: rmssdRecovery.present
        ? rmssdRecovery.value
        : this.rmssdRecovery,
    slopeRaw: slopeRaw.present ? slopeRaw.value : this.slopeRaw,
    slopeInterpreted: slopeInterpreted.present
        ? slopeInterpreted.value
        : this.slopeInterpreted,
    itlIndex: itlIndex.present ? itlIndex.value : this.itlIndex,
    classification: classification.present
        ? classification.value
        : this.classification,
    hrvInputMode: hrvInputMode.present ? hrvInputMode.value : this.hrvInputMode,
    rmssdRecoverySource: rmssdRecoverySource.present
        ? rmssdRecoverySource.value
        : this.rmssdRecoverySource,
    rmssdExerciseSource: rmssdExerciseSource.present
        ? rmssdExerciseSource.value
        : this.rmssdExerciseSource,
    rrQualityFlag: rrQualityFlag.present
        ? rrQualityFlag.value
        : this.rrQualityFlag,
    rrArtifactPercent: rrArtifactPercent.present
        ? rrArtifactPercent.value
        : this.rrArtifactPercent,
    rrPreprocessingMode: rrPreprocessingMode.present
        ? rrPreprocessingMode.value
        : this.rrPreprocessingMode,
    rrCorrectionEnabled: rrCorrectionEnabled ?? this.rrCorrectionEnabled,
    rrCorrectionMethod: rrCorrectionMethod.present
        ? rrCorrectionMethod.value
        : this.rrCorrectionMethod,
    rrRawRmssd: rrRawRmssd.present ? rrRawRmssd.value : this.rrRawRmssd,
    rrCorrectedRmssd: rrCorrectedRmssd.present
        ? rrCorrectedRmssd.value
        : this.rrCorrectedRmssd,
    rrRmssdUsed: rrRmssdUsed.present ? rrRmssdUsed.value : this.rrRmssdUsed,
    rrArtifactCount: rrArtifactCount.present
        ? rrArtifactCount.value
        : this.rrArtifactCount,
    rrQualityDecision: rrQualityDecision.present
        ? rrQualityDecision.value
        : this.rrQualityDecision,
    rrQualityNotesJson: rrQualityNotesJson.present
        ? rrQualityNotesJson.value
        : this.rrQualityNotesJson,
    rrRmssdDeltaPercent: rrRmssdDeltaPercent.present
        ? rrRmssdDeltaPercent.value
        : this.rrRmssdDeltaPercent,
    importBatchId: importBatchId.present
        ? importBatchId.value
        : this.importBatchId,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
  );
  Session copyWithCompanion(SessionsCompanion data) {
    return Session(
      id: data.id.present ? data.id.value : this.id,
      athleteId: data.athleteId.present ? data.athleteId.value : this.athleteId,
      date: data.date.present ? data.date.value : this.date,
      taskName: data.taskName.present ? data.taskName.value : this.taskName,
      sport: data.sport.present ? data.sport.value : this.sport,
      sessionType: data.sessionType.present
          ? data.sessionType.value
          : this.sessionType,
      protocolName: data.protocolName.present
          ? data.protocolName.value
          : this.protocolName,
      contextEnvironment: data.contextEnvironment.present
          ? data.contextEnvironment.value
          : this.contextEnvironment,
      isDraft: data.isDraft.present ? data.isDraft.value : this.isDraft,
      intensityPercent: data.intensityPercent.present
          ? data.intensityPercent.value
          : this.intensityPercent,
      intensitySource: data.intensitySource.present
          ? data.intensitySource.value
          : this.intensitySource,
      recoveryTimeMin: data.recoveryTimeMin.present
          ? data.recoveryTimeMin.value
          : this.recoveryTimeMin,
      recoveryWindowStartMin: data.recoveryWindowStartMin.present
          ? data.recoveryWindowStartMin.value
          : this.recoveryWindowStartMin,
      recoveryWindowEndMin: data.recoveryWindowEndMin.present
          ? data.recoveryWindowEndMin.value
          : this.recoveryWindowEndMin,
      rmssdExercise: data.rmssdExercise.present
          ? data.rmssdExercise.value
          : this.rmssdExercise,
      rmssdExerciseIsDefault: data.rmssdExerciseIsDefault.present
          ? data.rmssdExerciseIsDefault.value
          : this.rmssdExerciseIsDefault,
      rmssdRecovery: data.rmssdRecovery.present
          ? data.rmssdRecovery.value
          : this.rmssdRecovery,
      slopeRaw: data.slopeRaw.present ? data.slopeRaw.value : this.slopeRaw,
      slopeInterpreted: data.slopeInterpreted.present
          ? data.slopeInterpreted.value
          : this.slopeInterpreted,
      itlIndex: data.itlIndex.present ? data.itlIndex.value : this.itlIndex,
      classification: data.classification.present
          ? data.classification.value
          : this.classification,
      hrvInputMode: data.hrvInputMode.present
          ? data.hrvInputMode.value
          : this.hrvInputMode,
      rmssdRecoverySource: data.rmssdRecoverySource.present
          ? data.rmssdRecoverySource.value
          : this.rmssdRecoverySource,
      rmssdExerciseSource: data.rmssdExerciseSource.present
          ? data.rmssdExerciseSource.value
          : this.rmssdExerciseSource,
      rrQualityFlag: data.rrQualityFlag.present
          ? data.rrQualityFlag.value
          : this.rrQualityFlag,
      rrArtifactPercent: data.rrArtifactPercent.present
          ? data.rrArtifactPercent.value
          : this.rrArtifactPercent,
      rrPreprocessingMode: data.rrPreprocessingMode.present
          ? data.rrPreprocessingMode.value
          : this.rrPreprocessingMode,
      rrCorrectionEnabled: data.rrCorrectionEnabled.present
          ? data.rrCorrectionEnabled.value
          : this.rrCorrectionEnabled,
      rrCorrectionMethod: data.rrCorrectionMethod.present
          ? data.rrCorrectionMethod.value
          : this.rrCorrectionMethod,
      rrRawRmssd: data.rrRawRmssd.present
          ? data.rrRawRmssd.value
          : this.rrRawRmssd,
      rrCorrectedRmssd: data.rrCorrectedRmssd.present
          ? data.rrCorrectedRmssd.value
          : this.rrCorrectedRmssd,
      rrRmssdUsed: data.rrRmssdUsed.present
          ? data.rrRmssdUsed.value
          : this.rrRmssdUsed,
      rrArtifactCount: data.rrArtifactCount.present
          ? data.rrArtifactCount.value
          : this.rrArtifactCount,
      rrQualityDecision: data.rrQualityDecision.present
          ? data.rrQualityDecision.value
          : this.rrQualityDecision,
      rrQualityNotesJson: data.rrQualityNotesJson.present
          ? data.rrQualityNotesJson.value
          : this.rrQualityNotesJson,
      rrRmssdDeltaPercent: data.rrRmssdDeltaPercent.present
          ? data.rrRmssdDeltaPercent.value
          : this.rrRmssdDeltaPercent,
      importBatchId: data.importBatchId.present
          ? data.importBatchId.value
          : this.importBatchId,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Session(')
          ..write('id: $id, ')
          ..write('athleteId: $athleteId, ')
          ..write('date: $date, ')
          ..write('taskName: $taskName, ')
          ..write('sport: $sport, ')
          ..write('sessionType: $sessionType, ')
          ..write('protocolName: $protocolName, ')
          ..write('contextEnvironment: $contextEnvironment, ')
          ..write('isDraft: $isDraft, ')
          ..write('intensityPercent: $intensityPercent, ')
          ..write('intensitySource: $intensitySource, ')
          ..write('recoveryTimeMin: $recoveryTimeMin, ')
          ..write('recoveryWindowStartMin: $recoveryWindowStartMin, ')
          ..write('recoveryWindowEndMin: $recoveryWindowEndMin, ')
          ..write('rmssdExercise: $rmssdExercise, ')
          ..write('rmssdExerciseIsDefault: $rmssdExerciseIsDefault, ')
          ..write('rmssdRecovery: $rmssdRecovery, ')
          ..write('slopeRaw: $slopeRaw, ')
          ..write('slopeInterpreted: $slopeInterpreted, ')
          ..write('itlIndex: $itlIndex, ')
          ..write('classification: $classification, ')
          ..write('hrvInputMode: $hrvInputMode, ')
          ..write('rmssdRecoverySource: $rmssdRecoverySource, ')
          ..write('rmssdExerciseSource: $rmssdExerciseSource, ')
          ..write('rrQualityFlag: $rrQualityFlag, ')
          ..write('rrArtifactPercent: $rrArtifactPercent, ')
          ..write('rrPreprocessingMode: $rrPreprocessingMode, ')
          ..write('rrCorrectionEnabled: $rrCorrectionEnabled, ')
          ..write('rrCorrectionMethod: $rrCorrectionMethod, ')
          ..write('rrRawRmssd: $rrRawRmssd, ')
          ..write('rrCorrectedRmssd: $rrCorrectedRmssd, ')
          ..write('rrRmssdUsed: $rrRmssdUsed, ')
          ..write('rrArtifactCount: $rrArtifactCount, ')
          ..write('rrQualityDecision: $rrQualityDecision, ')
          ..write('rrQualityNotesJson: $rrQualityNotesJson, ')
          ..write('rrRmssdDeltaPercent: $rrRmssdDeltaPercent, ')
          ..write('importBatchId: $importBatchId, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    athleteId,
    date,
    taskName,
    sport,
    sessionType,
    protocolName,
    contextEnvironment,
    isDraft,
    intensityPercent,
    intensitySource,
    recoveryTimeMin,
    recoveryWindowStartMin,
    recoveryWindowEndMin,
    rmssdExercise,
    rmssdExerciseIsDefault,
    rmssdRecovery,
    slopeRaw,
    slopeInterpreted,
    itlIndex,
    classification,
    hrvInputMode,
    rmssdRecoverySource,
    rmssdExerciseSource,
    rrQualityFlag,
    rrArtifactPercent,
    rrPreprocessingMode,
    rrCorrectionEnabled,
    rrCorrectionMethod,
    rrRawRmssd,
    rrCorrectedRmssd,
    rrRmssdUsed,
    rrArtifactCount,
    rrQualityDecision,
    rrQualityNotesJson,
    rrRmssdDeltaPercent,
    importBatchId,
    notes,
    createdAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Session &&
          other.id == this.id &&
          other.athleteId == this.athleteId &&
          other.date == this.date &&
          other.taskName == this.taskName &&
          other.sport == this.sport &&
          other.sessionType == this.sessionType &&
          other.protocolName == this.protocolName &&
          other.contextEnvironment == this.contextEnvironment &&
          other.isDraft == this.isDraft &&
          other.intensityPercent == this.intensityPercent &&
          other.intensitySource == this.intensitySource &&
          other.recoveryTimeMin == this.recoveryTimeMin &&
          other.recoveryWindowStartMin == this.recoveryWindowStartMin &&
          other.recoveryWindowEndMin == this.recoveryWindowEndMin &&
          other.rmssdExercise == this.rmssdExercise &&
          other.rmssdExerciseIsDefault == this.rmssdExerciseIsDefault &&
          other.rmssdRecovery == this.rmssdRecovery &&
          other.slopeRaw == this.slopeRaw &&
          other.slopeInterpreted == this.slopeInterpreted &&
          other.itlIndex == this.itlIndex &&
          other.classification == this.classification &&
          other.hrvInputMode == this.hrvInputMode &&
          other.rmssdRecoverySource == this.rmssdRecoverySource &&
          other.rmssdExerciseSource == this.rmssdExerciseSource &&
          other.rrQualityFlag == this.rrQualityFlag &&
          other.rrArtifactPercent == this.rrArtifactPercent &&
          other.rrPreprocessingMode == this.rrPreprocessingMode &&
          other.rrCorrectionEnabled == this.rrCorrectionEnabled &&
          other.rrCorrectionMethod == this.rrCorrectionMethod &&
          other.rrRawRmssd == this.rrRawRmssd &&
          other.rrCorrectedRmssd == this.rrCorrectedRmssd &&
          other.rrRmssdUsed == this.rrRmssdUsed &&
          other.rrArtifactCount == this.rrArtifactCount &&
          other.rrQualityDecision == this.rrQualityDecision &&
          other.rrQualityNotesJson == this.rrQualityNotesJson &&
          other.rrRmssdDeltaPercent == this.rrRmssdDeltaPercent &&
          other.importBatchId == this.importBatchId &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt);
}

class SessionsCompanion extends UpdateCompanion<Session> {
  final Value<int> id;
  final Value<int> athleteId;
  final Value<String> date;
  final Value<String?> taskName;
  final Value<String?> sport;
  final Value<String?> sessionType;
  final Value<String?> protocolName;
  final Value<String?> contextEnvironment;
  final Value<bool> isDraft;
  final Value<double?> intensityPercent;
  final Value<String?> intensitySource;
  final Value<double?> recoveryTimeMin;
  final Value<double?> recoveryWindowStartMin;
  final Value<double?> recoveryWindowEndMin;
  final Value<double?> rmssdExercise;
  final Value<bool> rmssdExerciseIsDefault;
  final Value<double?> rmssdRecovery;
  final Value<double?> slopeRaw;
  final Value<double?> slopeInterpreted;
  final Value<double?> itlIndex;
  final Value<String?> classification;
  final Value<String?> hrvInputMode;
  final Value<String?> rmssdRecoverySource;
  final Value<String?> rmssdExerciseSource;
  final Value<String?> rrQualityFlag;
  final Value<double?> rrArtifactPercent;
  final Value<String?> rrPreprocessingMode;
  final Value<bool> rrCorrectionEnabled;
  final Value<String?> rrCorrectionMethod;
  final Value<double?> rrRawRmssd;
  final Value<double?> rrCorrectedRmssd;
  final Value<double?> rrRmssdUsed;
  final Value<int?> rrArtifactCount;
  final Value<String?> rrQualityDecision;
  final Value<String?> rrQualityNotesJson;
  final Value<double?> rrRmssdDeltaPercent;
  final Value<int?> importBatchId;
  final Value<String?> notes;
  final Value<String> createdAt;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.athleteId = const Value.absent(),
    this.date = const Value.absent(),
    this.taskName = const Value.absent(),
    this.sport = const Value.absent(),
    this.sessionType = const Value.absent(),
    this.protocolName = const Value.absent(),
    this.contextEnvironment = const Value.absent(),
    this.isDraft = const Value.absent(),
    this.intensityPercent = const Value.absent(),
    this.intensitySource = const Value.absent(),
    this.recoveryTimeMin = const Value.absent(),
    this.recoveryWindowStartMin = const Value.absent(),
    this.recoveryWindowEndMin = const Value.absent(),
    this.rmssdExercise = const Value.absent(),
    this.rmssdExerciseIsDefault = const Value.absent(),
    this.rmssdRecovery = const Value.absent(),
    this.slopeRaw = const Value.absent(),
    this.slopeInterpreted = const Value.absent(),
    this.itlIndex = const Value.absent(),
    this.classification = const Value.absent(),
    this.hrvInputMode = const Value.absent(),
    this.rmssdRecoverySource = const Value.absent(),
    this.rmssdExerciseSource = const Value.absent(),
    this.rrQualityFlag = const Value.absent(),
    this.rrArtifactPercent = const Value.absent(),
    this.rrPreprocessingMode = const Value.absent(),
    this.rrCorrectionEnabled = const Value.absent(),
    this.rrCorrectionMethod = const Value.absent(),
    this.rrRawRmssd = const Value.absent(),
    this.rrCorrectedRmssd = const Value.absent(),
    this.rrRmssdUsed = const Value.absent(),
    this.rrArtifactCount = const Value.absent(),
    this.rrQualityDecision = const Value.absent(),
    this.rrQualityNotesJson = const Value.absent(),
    this.rrRmssdDeltaPercent = const Value.absent(),
    this.importBatchId = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SessionsCompanion.insert({
    this.id = const Value.absent(),
    required int athleteId,
    required String date,
    this.taskName = const Value.absent(),
    this.sport = const Value.absent(),
    this.sessionType = const Value.absent(),
    this.protocolName = const Value.absent(),
    this.contextEnvironment = const Value.absent(),
    this.isDraft = const Value.absent(),
    this.intensityPercent = const Value.absent(),
    this.intensitySource = const Value.absent(),
    this.recoveryTimeMin = const Value.absent(),
    this.recoveryWindowStartMin = const Value.absent(),
    this.recoveryWindowEndMin = const Value.absent(),
    this.rmssdExercise = const Value.absent(),
    this.rmssdExerciseIsDefault = const Value.absent(),
    this.rmssdRecovery = const Value.absent(),
    this.slopeRaw = const Value.absent(),
    this.slopeInterpreted = const Value.absent(),
    this.itlIndex = const Value.absent(),
    this.classification = const Value.absent(),
    this.hrvInputMode = const Value.absent(),
    this.rmssdRecoverySource = const Value.absent(),
    this.rmssdExerciseSource = const Value.absent(),
    this.rrQualityFlag = const Value.absent(),
    this.rrArtifactPercent = const Value.absent(),
    this.rrPreprocessingMode = const Value.absent(),
    this.rrCorrectionEnabled = const Value.absent(),
    this.rrCorrectionMethod = const Value.absent(),
    this.rrRawRmssd = const Value.absent(),
    this.rrCorrectedRmssd = const Value.absent(),
    this.rrRmssdUsed = const Value.absent(),
    this.rrArtifactCount = const Value.absent(),
    this.rrQualityDecision = const Value.absent(),
    this.rrQualityNotesJson = const Value.absent(),
    this.rrRmssdDeltaPercent = const Value.absent(),
    this.importBatchId = const Value.absent(),
    this.notes = const Value.absent(),
    required String createdAt,
  }) : athleteId = Value(athleteId),
       date = Value(date),
       createdAt = Value(createdAt);
  static Insertable<Session> custom({
    Expression<int>? id,
    Expression<int>? athleteId,
    Expression<String>? date,
    Expression<String>? taskName,
    Expression<String>? sport,
    Expression<String>? sessionType,
    Expression<String>? protocolName,
    Expression<String>? contextEnvironment,
    Expression<bool>? isDraft,
    Expression<double>? intensityPercent,
    Expression<String>? intensitySource,
    Expression<double>? recoveryTimeMin,
    Expression<double>? recoveryWindowStartMin,
    Expression<double>? recoveryWindowEndMin,
    Expression<double>? rmssdExercise,
    Expression<bool>? rmssdExerciseIsDefault,
    Expression<double>? rmssdRecovery,
    Expression<double>? slopeRaw,
    Expression<double>? slopeInterpreted,
    Expression<double>? itlIndex,
    Expression<String>? classification,
    Expression<String>? hrvInputMode,
    Expression<String>? rmssdRecoverySource,
    Expression<String>? rmssdExerciseSource,
    Expression<String>? rrQualityFlag,
    Expression<double>? rrArtifactPercent,
    Expression<String>? rrPreprocessingMode,
    Expression<bool>? rrCorrectionEnabled,
    Expression<String>? rrCorrectionMethod,
    Expression<double>? rrRawRmssd,
    Expression<double>? rrCorrectedRmssd,
    Expression<double>? rrRmssdUsed,
    Expression<int>? rrArtifactCount,
    Expression<String>? rrQualityDecision,
    Expression<String>? rrQualityNotesJson,
    Expression<double>? rrRmssdDeltaPercent,
    Expression<int>? importBatchId,
    Expression<String>? notes,
    Expression<String>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (athleteId != null) 'athlete_id': athleteId,
      if (date != null) 'date': date,
      if (taskName != null) 'task_name': taskName,
      if (sport != null) 'sport': sport,
      if (sessionType != null) 'session_type': sessionType,
      if (protocolName != null) 'protocol_name': protocolName,
      if (contextEnvironment != null) 'context_environment': contextEnvironment,
      if (isDraft != null) 'is_draft': isDraft,
      if (intensityPercent != null) 'intensity_percent': intensityPercent,
      if (intensitySource != null) 'intensity_source': intensitySource,
      if (recoveryTimeMin != null) 'recovery_time_min': recoveryTimeMin,
      if (recoveryWindowStartMin != null)
        'recovery_window_start_min': recoveryWindowStartMin,
      if (recoveryWindowEndMin != null)
        'recovery_window_end_min': recoveryWindowEndMin,
      if (rmssdExercise != null) 'rmssd_exercise': rmssdExercise,
      if (rmssdExerciseIsDefault != null)
        'rmssd_exercise_is_default': rmssdExerciseIsDefault,
      if (rmssdRecovery != null) 'rmssd_recovery': rmssdRecovery,
      if (slopeRaw != null) 'slope_raw': slopeRaw,
      if (slopeInterpreted != null) 'slope_interpreted': slopeInterpreted,
      if (itlIndex != null) 'itl_index': itlIndex,
      if (classification != null) 'classification': classification,
      if (hrvInputMode != null) 'hrv_input_mode': hrvInputMode,
      if (rmssdRecoverySource != null)
        'rmssd_recovery_source': rmssdRecoverySource,
      if (rmssdExerciseSource != null)
        'rmssd_exercise_source': rmssdExerciseSource,
      if (rrQualityFlag != null) 'rr_quality_flag': rrQualityFlag,
      if (rrArtifactPercent != null) 'rr_artifact_percent': rrArtifactPercent,
      if (rrPreprocessingMode != null)
        'rr_preprocessing_mode': rrPreprocessingMode,
      if (rrCorrectionEnabled != null)
        'rr_correction_enabled': rrCorrectionEnabled,
      if (rrCorrectionMethod != null)
        'rr_correction_method': rrCorrectionMethod,
      if (rrRawRmssd != null) 'rr_raw_rmssd': rrRawRmssd,
      if (rrCorrectedRmssd != null) 'rr_corrected_rmssd': rrCorrectedRmssd,
      if (rrRmssdUsed != null) 'rr_rmssd_used': rrRmssdUsed,
      if (rrArtifactCount != null) 'rr_artifact_count': rrArtifactCount,
      if (rrQualityDecision != null) 'rr_quality_decision': rrQualityDecision,
      if (rrQualityNotesJson != null)
        'rr_quality_notes_json': rrQualityNotesJson,
      if (rrRmssdDeltaPercent != null)
        'rr_rmssd_delta_percent': rrRmssdDeltaPercent,
      if (importBatchId != null) 'import_batch_id': importBatchId,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SessionsCompanion copyWith({
    Value<int>? id,
    Value<int>? athleteId,
    Value<String>? date,
    Value<String?>? taskName,
    Value<String?>? sport,
    Value<String?>? sessionType,
    Value<String?>? protocolName,
    Value<String?>? contextEnvironment,
    Value<bool>? isDraft,
    Value<double?>? intensityPercent,
    Value<String?>? intensitySource,
    Value<double?>? recoveryTimeMin,
    Value<double?>? recoveryWindowStartMin,
    Value<double?>? recoveryWindowEndMin,
    Value<double?>? rmssdExercise,
    Value<bool>? rmssdExerciseIsDefault,
    Value<double?>? rmssdRecovery,
    Value<double?>? slopeRaw,
    Value<double?>? slopeInterpreted,
    Value<double?>? itlIndex,
    Value<String?>? classification,
    Value<String?>? hrvInputMode,
    Value<String?>? rmssdRecoverySource,
    Value<String?>? rmssdExerciseSource,
    Value<String?>? rrQualityFlag,
    Value<double?>? rrArtifactPercent,
    Value<String?>? rrPreprocessingMode,
    Value<bool>? rrCorrectionEnabled,
    Value<String?>? rrCorrectionMethod,
    Value<double?>? rrRawRmssd,
    Value<double?>? rrCorrectedRmssd,
    Value<double?>? rrRmssdUsed,
    Value<int?>? rrArtifactCount,
    Value<String?>? rrQualityDecision,
    Value<String?>? rrQualityNotesJson,
    Value<double?>? rrRmssdDeltaPercent,
    Value<int?>? importBatchId,
    Value<String?>? notes,
    Value<String>? createdAt,
  }) {
    return SessionsCompanion(
      id: id ?? this.id,
      athleteId: athleteId ?? this.athleteId,
      date: date ?? this.date,
      taskName: taskName ?? this.taskName,
      sport: sport ?? this.sport,
      sessionType: sessionType ?? this.sessionType,
      protocolName: protocolName ?? this.protocolName,
      contextEnvironment: contextEnvironment ?? this.contextEnvironment,
      isDraft: isDraft ?? this.isDraft,
      intensityPercent: intensityPercent ?? this.intensityPercent,
      intensitySource: intensitySource ?? this.intensitySource,
      recoveryTimeMin: recoveryTimeMin ?? this.recoveryTimeMin,
      recoveryWindowStartMin:
          recoveryWindowStartMin ?? this.recoveryWindowStartMin,
      recoveryWindowEndMin: recoveryWindowEndMin ?? this.recoveryWindowEndMin,
      rmssdExercise: rmssdExercise ?? this.rmssdExercise,
      rmssdExerciseIsDefault:
          rmssdExerciseIsDefault ?? this.rmssdExerciseIsDefault,
      rmssdRecovery: rmssdRecovery ?? this.rmssdRecovery,
      slopeRaw: slopeRaw ?? this.slopeRaw,
      slopeInterpreted: slopeInterpreted ?? this.slopeInterpreted,
      itlIndex: itlIndex ?? this.itlIndex,
      classification: classification ?? this.classification,
      hrvInputMode: hrvInputMode ?? this.hrvInputMode,
      rmssdRecoverySource: rmssdRecoverySource ?? this.rmssdRecoverySource,
      rmssdExerciseSource: rmssdExerciseSource ?? this.rmssdExerciseSource,
      rrQualityFlag: rrQualityFlag ?? this.rrQualityFlag,
      rrArtifactPercent: rrArtifactPercent ?? this.rrArtifactPercent,
      rrPreprocessingMode: rrPreprocessingMode ?? this.rrPreprocessingMode,
      rrCorrectionEnabled: rrCorrectionEnabled ?? this.rrCorrectionEnabled,
      rrCorrectionMethod: rrCorrectionMethod ?? this.rrCorrectionMethod,
      rrRawRmssd: rrRawRmssd ?? this.rrRawRmssd,
      rrCorrectedRmssd: rrCorrectedRmssd ?? this.rrCorrectedRmssd,
      rrRmssdUsed: rrRmssdUsed ?? this.rrRmssdUsed,
      rrArtifactCount: rrArtifactCount ?? this.rrArtifactCount,
      rrQualityDecision: rrQualityDecision ?? this.rrQualityDecision,
      rrQualityNotesJson: rrQualityNotesJson ?? this.rrQualityNotesJson,
      rrRmssdDeltaPercent: rrRmssdDeltaPercent ?? this.rrRmssdDeltaPercent,
      importBatchId: importBatchId ?? this.importBatchId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (athleteId.present) {
      map['athlete_id'] = Variable<int>(athleteId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (taskName.present) {
      map['task_name'] = Variable<String>(taskName.value);
    }
    if (sport.present) {
      map['sport'] = Variable<String>(sport.value);
    }
    if (sessionType.present) {
      map['session_type'] = Variable<String>(sessionType.value);
    }
    if (protocolName.present) {
      map['protocol_name'] = Variable<String>(protocolName.value);
    }
    if (contextEnvironment.present) {
      map['context_environment'] = Variable<String>(contextEnvironment.value);
    }
    if (isDraft.present) {
      map['is_draft'] = Variable<bool>(isDraft.value);
    }
    if (intensityPercent.present) {
      map['intensity_percent'] = Variable<double>(intensityPercent.value);
    }
    if (intensitySource.present) {
      map['intensity_source'] = Variable<String>(intensitySource.value);
    }
    if (recoveryTimeMin.present) {
      map['recovery_time_min'] = Variable<double>(recoveryTimeMin.value);
    }
    if (recoveryWindowStartMin.present) {
      map['recovery_window_start_min'] = Variable<double>(
        recoveryWindowStartMin.value,
      );
    }
    if (recoveryWindowEndMin.present) {
      map['recovery_window_end_min'] = Variable<double>(
        recoveryWindowEndMin.value,
      );
    }
    if (rmssdExercise.present) {
      map['rmssd_exercise'] = Variable<double>(rmssdExercise.value);
    }
    if (rmssdExerciseIsDefault.present) {
      map['rmssd_exercise_is_default'] = Variable<bool>(
        rmssdExerciseIsDefault.value,
      );
    }
    if (rmssdRecovery.present) {
      map['rmssd_recovery'] = Variable<double>(rmssdRecovery.value);
    }
    if (slopeRaw.present) {
      map['slope_raw'] = Variable<double>(slopeRaw.value);
    }
    if (slopeInterpreted.present) {
      map['slope_interpreted'] = Variable<double>(slopeInterpreted.value);
    }
    if (itlIndex.present) {
      map['itl_index'] = Variable<double>(itlIndex.value);
    }
    if (classification.present) {
      map['classification'] = Variable<String>(classification.value);
    }
    if (hrvInputMode.present) {
      map['hrv_input_mode'] = Variable<String>(hrvInputMode.value);
    }
    if (rmssdRecoverySource.present) {
      map['rmssd_recovery_source'] = Variable<String>(
        rmssdRecoverySource.value,
      );
    }
    if (rmssdExerciseSource.present) {
      map['rmssd_exercise_source'] = Variable<String>(
        rmssdExerciseSource.value,
      );
    }
    if (rrQualityFlag.present) {
      map['rr_quality_flag'] = Variable<String>(rrQualityFlag.value);
    }
    if (rrArtifactPercent.present) {
      map['rr_artifact_percent'] = Variable<double>(rrArtifactPercent.value);
    }
    if (rrPreprocessingMode.present) {
      map['rr_preprocessing_mode'] = Variable<String>(
        rrPreprocessingMode.value,
      );
    }
    if (rrCorrectionEnabled.present) {
      map['rr_correction_enabled'] = Variable<bool>(rrCorrectionEnabled.value);
    }
    if (rrCorrectionMethod.present) {
      map['rr_correction_method'] = Variable<String>(rrCorrectionMethod.value);
    }
    if (rrRawRmssd.present) {
      map['rr_raw_rmssd'] = Variable<double>(rrRawRmssd.value);
    }
    if (rrCorrectedRmssd.present) {
      map['rr_corrected_rmssd'] = Variable<double>(rrCorrectedRmssd.value);
    }
    if (rrRmssdUsed.present) {
      map['rr_rmssd_used'] = Variable<double>(rrRmssdUsed.value);
    }
    if (rrArtifactCount.present) {
      map['rr_artifact_count'] = Variable<int>(rrArtifactCount.value);
    }
    if (rrQualityDecision.present) {
      map['rr_quality_decision'] = Variable<String>(rrQualityDecision.value);
    }
    if (rrQualityNotesJson.present) {
      map['rr_quality_notes_json'] = Variable<String>(rrQualityNotesJson.value);
    }
    if (rrRmssdDeltaPercent.present) {
      map['rr_rmssd_delta_percent'] = Variable<double>(
        rrRmssdDeltaPercent.value,
      );
    }
    if (importBatchId.present) {
      map['import_batch_id'] = Variable<int>(importBatchId.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsCompanion(')
          ..write('id: $id, ')
          ..write('athleteId: $athleteId, ')
          ..write('date: $date, ')
          ..write('taskName: $taskName, ')
          ..write('sport: $sport, ')
          ..write('sessionType: $sessionType, ')
          ..write('protocolName: $protocolName, ')
          ..write('contextEnvironment: $contextEnvironment, ')
          ..write('isDraft: $isDraft, ')
          ..write('intensityPercent: $intensityPercent, ')
          ..write('intensitySource: $intensitySource, ')
          ..write('recoveryTimeMin: $recoveryTimeMin, ')
          ..write('recoveryWindowStartMin: $recoveryWindowStartMin, ')
          ..write('recoveryWindowEndMin: $recoveryWindowEndMin, ')
          ..write('rmssdExercise: $rmssdExercise, ')
          ..write('rmssdExerciseIsDefault: $rmssdExerciseIsDefault, ')
          ..write('rmssdRecovery: $rmssdRecovery, ')
          ..write('slopeRaw: $slopeRaw, ')
          ..write('slopeInterpreted: $slopeInterpreted, ')
          ..write('itlIndex: $itlIndex, ')
          ..write('classification: $classification, ')
          ..write('hrvInputMode: $hrvInputMode, ')
          ..write('rmssdRecoverySource: $rmssdRecoverySource, ')
          ..write('rmssdExerciseSource: $rmssdExerciseSource, ')
          ..write('rrQualityFlag: $rrQualityFlag, ')
          ..write('rrArtifactPercent: $rrArtifactPercent, ')
          ..write('rrPreprocessingMode: $rrPreprocessingMode, ')
          ..write('rrCorrectionEnabled: $rrCorrectionEnabled, ')
          ..write('rrCorrectionMethod: $rrCorrectionMethod, ')
          ..write('rrRawRmssd: $rrRawRmssd, ')
          ..write('rrCorrectedRmssd: $rrCorrectedRmssd, ')
          ..write('rrRmssdUsed: $rrRmssdUsed, ')
          ..write('rrArtifactCount: $rrArtifactCount, ')
          ..write('rrQualityDecision: $rrQualityDecision, ')
          ..write('rrQualityNotesJson: $rrQualityNotesJson, ')
          ..write('rrRmssdDeltaPercent: $rrRmssdDeltaPercent, ')
          ..write('importBatchId: $importBatchId, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $MeasurementsHrvTable extends MeasurementsHrv
    with TableInfo<$MeasurementsHrvTable, MeasurementsHrvData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MeasurementsHrvTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<int> sessionId = GeneratedColumn<int>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sessions (id)',
    ),
  );
  static const VerificationMeta _phaseMeta = const VerificationMeta('phase');
  @override
  late final GeneratedColumn<String> phase = GeneratedColumn<String>(
    'phase',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _windowStartMinMeta = const VerificationMeta(
    'windowStartMin',
  );
  @override
  late final GeneratedColumn<double> windowStartMin = GeneratedColumn<double>(
    'window_start_min',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _windowEndMinMeta = const VerificationMeta(
    'windowEndMin',
  );
  @override
  late final GeneratedColumn<double> windowEndMin = GeneratedColumn<double>(
    'window_end_min',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rrIntervalsJsonMeta = const VerificationMeta(
    'rrIntervalsJson',
  );
  @override
  late final GeneratedColumn<String> rrIntervalsJson = GeneratedColumn<String>(
    'rr_intervals_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rmssdMeta = const VerificationMeta('rmssd');
  @override
  late final GeneratedColumn<double> rmssd = GeneratedColumn<double>(
    'rmssd',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _meanHrMeta = const VerificationMeta('meanHr');
  @override
  late final GeneratedColumn<double> meanHr = GeneratedColumn<double>(
    'mean_hr',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sdnnMeta = const VerificationMeta('sdnn');
  @override
  late final GeneratedColumn<double> sdnn = GeneratedColumn<double>(
    'sdnn',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    phase,
    windowStartMin,
    windowEndMin,
    rrIntervalsJson,
    rmssd,
    meanHr,
    sdnn,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'measurements_hrv';
  @override
  VerificationContext validateIntegrity(
    Insertable<MeasurementsHrvData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('phase')) {
      context.handle(
        _phaseMeta,
        phase.isAcceptableOrUnknown(data['phase']!, _phaseMeta),
      );
    } else if (isInserting) {
      context.missing(_phaseMeta);
    }
    if (data.containsKey('window_start_min')) {
      context.handle(
        _windowStartMinMeta,
        windowStartMin.isAcceptableOrUnknown(
          data['window_start_min']!,
          _windowStartMinMeta,
        ),
      );
    }
    if (data.containsKey('window_end_min')) {
      context.handle(
        _windowEndMinMeta,
        windowEndMin.isAcceptableOrUnknown(
          data['window_end_min']!,
          _windowEndMinMeta,
        ),
      );
    }
    if (data.containsKey('rr_intervals_json')) {
      context.handle(
        _rrIntervalsJsonMeta,
        rrIntervalsJson.isAcceptableOrUnknown(
          data['rr_intervals_json']!,
          _rrIntervalsJsonMeta,
        ),
      );
    }
    if (data.containsKey('rmssd')) {
      context.handle(
        _rmssdMeta,
        rmssd.isAcceptableOrUnknown(data['rmssd']!, _rmssdMeta),
      );
    }
    if (data.containsKey('mean_hr')) {
      context.handle(
        _meanHrMeta,
        meanHr.isAcceptableOrUnknown(data['mean_hr']!, _meanHrMeta),
      );
    }
    if (data.containsKey('sdnn')) {
      context.handle(
        _sdnnMeta,
        sdnn.isAcceptableOrUnknown(data['sdnn']!, _sdnnMeta),
      );
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
  MeasurementsHrvData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MeasurementsHrvData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}session_id'],
      )!,
      phase: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phase'],
      )!,
      windowStartMin: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}window_start_min'],
      ),
      windowEndMin: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}window_end_min'],
      ),
      rrIntervalsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rr_intervals_json'],
      ),
      rmssd: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rmssd'],
      ),
      meanHr: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}mean_hr'],
      ),
      sdnn: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sdnn'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $MeasurementsHrvTable createAlias(String alias) {
    return $MeasurementsHrvTable(attachedDatabase, alias);
  }
}

class MeasurementsHrvData extends DataClass
    implements Insertable<MeasurementsHrvData> {
  final int id;
  final int sessionId;
  final String phase;
  final double? windowStartMin;
  final double? windowEndMin;
  final String? rrIntervalsJson;
  final double? rmssd;
  final double? meanHr;
  final double? sdnn;
  final String createdAt;
  const MeasurementsHrvData({
    required this.id,
    required this.sessionId,
    required this.phase,
    this.windowStartMin,
    this.windowEndMin,
    this.rrIntervalsJson,
    this.rmssd,
    this.meanHr,
    this.sdnn,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['session_id'] = Variable<int>(sessionId);
    map['phase'] = Variable<String>(phase);
    if (!nullToAbsent || windowStartMin != null) {
      map['window_start_min'] = Variable<double>(windowStartMin);
    }
    if (!nullToAbsent || windowEndMin != null) {
      map['window_end_min'] = Variable<double>(windowEndMin);
    }
    if (!nullToAbsent || rrIntervalsJson != null) {
      map['rr_intervals_json'] = Variable<String>(rrIntervalsJson);
    }
    if (!nullToAbsent || rmssd != null) {
      map['rmssd'] = Variable<double>(rmssd);
    }
    if (!nullToAbsent || meanHr != null) {
      map['mean_hr'] = Variable<double>(meanHr);
    }
    if (!nullToAbsent || sdnn != null) {
      map['sdnn'] = Variable<double>(sdnn);
    }
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  MeasurementsHrvCompanion toCompanion(bool nullToAbsent) {
    return MeasurementsHrvCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      phase: Value(phase),
      windowStartMin: windowStartMin == null && nullToAbsent
          ? const Value.absent()
          : Value(windowStartMin),
      windowEndMin: windowEndMin == null && nullToAbsent
          ? const Value.absent()
          : Value(windowEndMin),
      rrIntervalsJson: rrIntervalsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(rrIntervalsJson),
      rmssd: rmssd == null && nullToAbsent
          ? const Value.absent()
          : Value(rmssd),
      meanHr: meanHr == null && nullToAbsent
          ? const Value.absent()
          : Value(meanHr),
      sdnn: sdnn == null && nullToAbsent ? const Value.absent() : Value(sdnn),
      createdAt: Value(createdAt),
    );
  }

  factory MeasurementsHrvData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MeasurementsHrvData(
      id: serializer.fromJson<int>(json['id']),
      sessionId: serializer.fromJson<int>(json['sessionId']),
      phase: serializer.fromJson<String>(json['phase']),
      windowStartMin: serializer.fromJson<double?>(json['windowStartMin']),
      windowEndMin: serializer.fromJson<double?>(json['windowEndMin']),
      rrIntervalsJson: serializer.fromJson<String?>(json['rrIntervalsJson']),
      rmssd: serializer.fromJson<double?>(json['rmssd']),
      meanHr: serializer.fromJson<double?>(json['meanHr']),
      sdnn: serializer.fromJson<double?>(json['sdnn']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionId': serializer.toJson<int>(sessionId),
      'phase': serializer.toJson<String>(phase),
      'windowStartMin': serializer.toJson<double?>(windowStartMin),
      'windowEndMin': serializer.toJson<double?>(windowEndMin),
      'rrIntervalsJson': serializer.toJson<String?>(rrIntervalsJson),
      'rmssd': serializer.toJson<double?>(rmssd),
      'meanHr': serializer.toJson<double?>(meanHr),
      'sdnn': serializer.toJson<double?>(sdnn),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  MeasurementsHrvData copyWith({
    int? id,
    int? sessionId,
    String? phase,
    Value<double?> windowStartMin = const Value.absent(),
    Value<double?> windowEndMin = const Value.absent(),
    Value<String?> rrIntervalsJson = const Value.absent(),
    Value<double?> rmssd = const Value.absent(),
    Value<double?> meanHr = const Value.absent(),
    Value<double?> sdnn = const Value.absent(),
    String? createdAt,
  }) => MeasurementsHrvData(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    phase: phase ?? this.phase,
    windowStartMin: windowStartMin.present
        ? windowStartMin.value
        : this.windowStartMin,
    windowEndMin: windowEndMin.present ? windowEndMin.value : this.windowEndMin,
    rrIntervalsJson: rrIntervalsJson.present
        ? rrIntervalsJson.value
        : this.rrIntervalsJson,
    rmssd: rmssd.present ? rmssd.value : this.rmssd,
    meanHr: meanHr.present ? meanHr.value : this.meanHr,
    sdnn: sdnn.present ? sdnn.value : this.sdnn,
    createdAt: createdAt ?? this.createdAt,
  );
  MeasurementsHrvData copyWithCompanion(MeasurementsHrvCompanion data) {
    return MeasurementsHrvData(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      phase: data.phase.present ? data.phase.value : this.phase,
      windowStartMin: data.windowStartMin.present
          ? data.windowStartMin.value
          : this.windowStartMin,
      windowEndMin: data.windowEndMin.present
          ? data.windowEndMin.value
          : this.windowEndMin,
      rrIntervalsJson: data.rrIntervalsJson.present
          ? data.rrIntervalsJson.value
          : this.rrIntervalsJson,
      rmssd: data.rmssd.present ? data.rmssd.value : this.rmssd,
      meanHr: data.meanHr.present ? data.meanHr.value : this.meanHr,
      sdnn: data.sdnn.present ? data.sdnn.value : this.sdnn,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MeasurementsHrvData(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('phase: $phase, ')
          ..write('windowStartMin: $windowStartMin, ')
          ..write('windowEndMin: $windowEndMin, ')
          ..write('rrIntervalsJson: $rrIntervalsJson, ')
          ..write('rmssd: $rmssd, ')
          ..write('meanHr: $meanHr, ')
          ..write('sdnn: $sdnn, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    phase,
    windowStartMin,
    windowEndMin,
    rrIntervalsJson,
    rmssd,
    meanHr,
    sdnn,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MeasurementsHrvData &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.phase == this.phase &&
          other.windowStartMin == this.windowStartMin &&
          other.windowEndMin == this.windowEndMin &&
          other.rrIntervalsJson == this.rrIntervalsJson &&
          other.rmssd == this.rmssd &&
          other.meanHr == this.meanHr &&
          other.sdnn == this.sdnn &&
          other.createdAt == this.createdAt);
}

class MeasurementsHrvCompanion extends UpdateCompanion<MeasurementsHrvData> {
  final Value<int> id;
  final Value<int> sessionId;
  final Value<String> phase;
  final Value<double?> windowStartMin;
  final Value<double?> windowEndMin;
  final Value<String?> rrIntervalsJson;
  final Value<double?> rmssd;
  final Value<double?> meanHr;
  final Value<double?> sdnn;
  final Value<String> createdAt;
  const MeasurementsHrvCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.phase = const Value.absent(),
    this.windowStartMin = const Value.absent(),
    this.windowEndMin = const Value.absent(),
    this.rrIntervalsJson = const Value.absent(),
    this.rmssd = const Value.absent(),
    this.meanHr = const Value.absent(),
    this.sdnn = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  MeasurementsHrvCompanion.insert({
    this.id = const Value.absent(),
    required int sessionId,
    required String phase,
    this.windowStartMin = const Value.absent(),
    this.windowEndMin = const Value.absent(),
    this.rrIntervalsJson = const Value.absent(),
    this.rmssd = const Value.absent(),
    this.meanHr = const Value.absent(),
    this.sdnn = const Value.absent(),
    required String createdAt,
  }) : sessionId = Value(sessionId),
       phase = Value(phase),
       createdAt = Value(createdAt);
  static Insertable<MeasurementsHrvData> custom({
    Expression<int>? id,
    Expression<int>? sessionId,
    Expression<String>? phase,
    Expression<double>? windowStartMin,
    Expression<double>? windowEndMin,
    Expression<String>? rrIntervalsJson,
    Expression<double>? rmssd,
    Expression<double>? meanHr,
    Expression<double>? sdnn,
    Expression<String>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (phase != null) 'phase': phase,
      if (windowStartMin != null) 'window_start_min': windowStartMin,
      if (windowEndMin != null) 'window_end_min': windowEndMin,
      if (rrIntervalsJson != null) 'rr_intervals_json': rrIntervalsJson,
      if (rmssd != null) 'rmssd': rmssd,
      if (meanHr != null) 'mean_hr': meanHr,
      if (sdnn != null) 'sdnn': sdnn,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  MeasurementsHrvCompanion copyWith({
    Value<int>? id,
    Value<int>? sessionId,
    Value<String>? phase,
    Value<double?>? windowStartMin,
    Value<double?>? windowEndMin,
    Value<String?>? rrIntervalsJson,
    Value<double?>? rmssd,
    Value<double?>? meanHr,
    Value<double?>? sdnn,
    Value<String>? createdAt,
  }) {
    return MeasurementsHrvCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      phase: phase ?? this.phase,
      windowStartMin: windowStartMin ?? this.windowStartMin,
      windowEndMin: windowEndMin ?? this.windowEndMin,
      rrIntervalsJson: rrIntervalsJson ?? this.rrIntervalsJson,
      rmssd: rmssd ?? this.rmssd,
      meanHr: meanHr ?? this.meanHr,
      sdnn: sdnn ?? this.sdnn,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    if (phase.present) {
      map['phase'] = Variable<String>(phase.value);
    }
    if (windowStartMin.present) {
      map['window_start_min'] = Variable<double>(windowStartMin.value);
    }
    if (windowEndMin.present) {
      map['window_end_min'] = Variable<double>(windowEndMin.value);
    }
    if (rrIntervalsJson.present) {
      map['rr_intervals_json'] = Variable<String>(rrIntervalsJson.value);
    }
    if (rmssd.present) {
      map['rmssd'] = Variable<double>(rmssd.value);
    }
    if (meanHr.present) {
      map['mean_hr'] = Variable<double>(meanHr.value);
    }
    if (sdnn.present) {
      map['sdnn'] = Variable<double>(sdnn.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MeasurementsHrvCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('phase: $phase, ')
          ..write('windowStartMin: $windowStartMin, ')
          ..write('windowEndMin: $windowEndMin, ')
          ..write('rrIntervalsJson: $rrIntervalsJson, ')
          ..write('rmssd: $rmssd, ')
          ..write('meanHr: $meanHr, ')
          ..write('sdnn: $sdnn, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $IntensityVariablesTable extends IntensityVariables
    with TableInfo<$IntensityVariablesTable, IntensityVariable> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IntensityVariablesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<int> sessionId = GeneratedColumn<int>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sessions (id)',
    ),
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
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
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isPrimaryForNomogramMeta =
      const VerificationMeta('isPrimaryForNomogram');
  @override
  late final GeneratedColumn<bool> isPrimaryForNomogram = GeneratedColumn<bool>(
    'is_primary_for_nomogram',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_primary_for_nomogram" IN (0, 1))',
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
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    category,
    name,
    unit,
    value,
    source,
    isPrimaryForNomogram,
    notes,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'intensity_variables';
  @override
  VerificationContext validateIntegrity(
    Insertable<IntensityVariable> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('is_primary_for_nomogram')) {
      context.handle(
        _isPrimaryForNomogramMeta,
        isPrimaryForNomogram.isAcceptableOrUnknown(
          data['is_primary_for_nomogram']!,
          _isPrimaryForNomogramMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
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
  IntensityVariable map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IntensityVariable(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}session_id'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      ),
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}value'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      ),
      isPrimaryForNomogram: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_primary_for_nomogram'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $IntensityVariablesTable createAlias(String alias) {
    return $IntensityVariablesTable(attachedDatabase, alias);
  }
}

class IntensityVariable extends DataClass
    implements Insertable<IntensityVariable> {
  final int id;
  final int sessionId;
  final String category;
  final String name;
  final String? unit;
  final double value;
  final String? source;
  final bool isPrimaryForNomogram;
  final String? notes;
  final String createdAt;
  const IntensityVariable({
    required this.id,
    required this.sessionId,
    required this.category,
    required this.name,
    this.unit,
    required this.value,
    this.source,
    required this.isPrimaryForNomogram,
    this.notes,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['session_id'] = Variable<int>(sessionId);
    map['category'] = Variable<String>(category);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    map['value'] = Variable<double>(value);
    if (!nullToAbsent || source != null) {
      map['source'] = Variable<String>(source);
    }
    map['is_primary_for_nomogram'] = Variable<bool>(isPrimaryForNomogram);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  IntensityVariablesCompanion toCompanion(bool nullToAbsent) {
    return IntensityVariablesCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      category: Value(category),
      name: Value(name),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      value: Value(value),
      source: source == null && nullToAbsent
          ? const Value.absent()
          : Value(source),
      isPrimaryForNomogram: Value(isPrimaryForNomogram),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
    );
  }

  factory IntensityVariable.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IntensityVariable(
      id: serializer.fromJson<int>(json['id']),
      sessionId: serializer.fromJson<int>(json['sessionId']),
      category: serializer.fromJson<String>(json['category']),
      name: serializer.fromJson<String>(json['name']),
      unit: serializer.fromJson<String?>(json['unit']),
      value: serializer.fromJson<double>(json['value']),
      source: serializer.fromJson<String?>(json['source']),
      isPrimaryForNomogram: serializer.fromJson<bool>(
        json['isPrimaryForNomogram'],
      ),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionId': serializer.toJson<int>(sessionId),
      'category': serializer.toJson<String>(category),
      'name': serializer.toJson<String>(name),
      'unit': serializer.toJson<String?>(unit),
      'value': serializer.toJson<double>(value),
      'source': serializer.toJson<String?>(source),
      'isPrimaryForNomogram': serializer.toJson<bool>(isPrimaryForNomogram),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  IntensityVariable copyWith({
    int? id,
    int? sessionId,
    String? category,
    String? name,
    Value<String?> unit = const Value.absent(),
    double? value,
    Value<String?> source = const Value.absent(),
    bool? isPrimaryForNomogram,
    Value<String?> notes = const Value.absent(),
    String? createdAt,
  }) => IntensityVariable(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    category: category ?? this.category,
    name: name ?? this.name,
    unit: unit.present ? unit.value : this.unit,
    value: value ?? this.value,
    source: source.present ? source.value : this.source,
    isPrimaryForNomogram: isPrimaryForNomogram ?? this.isPrimaryForNomogram,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
  );
  IntensityVariable copyWithCompanion(IntensityVariablesCompanion data) {
    return IntensityVariable(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      category: data.category.present ? data.category.value : this.category,
      name: data.name.present ? data.name.value : this.name,
      unit: data.unit.present ? data.unit.value : this.unit,
      value: data.value.present ? data.value.value : this.value,
      source: data.source.present ? data.source.value : this.source,
      isPrimaryForNomogram: data.isPrimaryForNomogram.present
          ? data.isPrimaryForNomogram.value
          : this.isPrimaryForNomogram,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IntensityVariable(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('category: $category, ')
          ..write('name: $name, ')
          ..write('unit: $unit, ')
          ..write('value: $value, ')
          ..write('source: $source, ')
          ..write('isPrimaryForNomogram: $isPrimaryForNomogram, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    category,
    name,
    unit,
    value,
    source,
    isPrimaryForNomogram,
    notes,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IntensityVariable &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.category == this.category &&
          other.name == this.name &&
          other.unit == this.unit &&
          other.value == this.value &&
          other.source == this.source &&
          other.isPrimaryForNomogram == this.isPrimaryForNomogram &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt);
}

class IntensityVariablesCompanion extends UpdateCompanion<IntensityVariable> {
  final Value<int> id;
  final Value<int> sessionId;
  final Value<String> category;
  final Value<String> name;
  final Value<String?> unit;
  final Value<double> value;
  final Value<String?> source;
  final Value<bool> isPrimaryForNomogram;
  final Value<String?> notes;
  final Value<String> createdAt;
  const IntensityVariablesCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.category = const Value.absent(),
    this.name = const Value.absent(),
    this.unit = const Value.absent(),
    this.value = const Value.absent(),
    this.source = const Value.absent(),
    this.isPrimaryForNomogram = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  IntensityVariablesCompanion.insert({
    this.id = const Value.absent(),
    required int sessionId,
    required String category,
    required String name,
    this.unit = const Value.absent(),
    required double value,
    this.source = const Value.absent(),
    this.isPrimaryForNomogram = const Value.absent(),
    this.notes = const Value.absent(),
    required String createdAt,
  }) : sessionId = Value(sessionId),
       category = Value(category),
       name = Value(name),
       value = Value(value),
       createdAt = Value(createdAt);
  static Insertable<IntensityVariable> custom({
    Expression<int>? id,
    Expression<int>? sessionId,
    Expression<String>? category,
    Expression<String>? name,
    Expression<String>? unit,
    Expression<double>? value,
    Expression<String>? source,
    Expression<bool>? isPrimaryForNomogram,
    Expression<String>? notes,
    Expression<String>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (category != null) 'category': category,
      if (name != null) 'name': name,
      if (unit != null) 'unit': unit,
      if (value != null) 'value': value,
      if (source != null) 'source': source,
      if (isPrimaryForNomogram != null)
        'is_primary_for_nomogram': isPrimaryForNomogram,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  IntensityVariablesCompanion copyWith({
    Value<int>? id,
    Value<int>? sessionId,
    Value<String>? category,
    Value<String>? name,
    Value<String?>? unit,
    Value<double>? value,
    Value<String?>? source,
    Value<bool>? isPrimaryForNomogram,
    Value<String?>? notes,
    Value<String>? createdAt,
  }) {
    return IntensityVariablesCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      category: category ?? this.category,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      value: value ?? this.value,
      source: source ?? this.source,
      isPrimaryForNomogram: isPrimaryForNomogram ?? this.isPrimaryForNomogram,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (isPrimaryForNomogram.present) {
      map['is_primary_for_nomogram'] = Variable<bool>(
        isPrimaryForNomogram.value,
      );
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IntensityVariablesCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('category: $category, ')
          ..write('name: $name, ')
          ..write('unit: $unit, ')
          ..write('value: $value, ')
          ..write('source: $source, ')
          ..write('isPrimaryForNomogram: $isPrimaryForNomogram, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $NomogramModelsTable extends NomogramModels
    with TableInfo<$NomogramModelsTable, NomogramModel> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NomogramModelsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _athleteIdMeta = const VerificationMeta(
    'athleteId',
  );
  @override
  late final GeneratedColumn<int> athleteId = GeneratedColumn<int>(
    'athlete_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'UNIQUE REFERENCES athletes (id)',
    ),
  );
  static const VerificationMeta _paramAMeta = const VerificationMeta('paramA');
  @override
  late final GeneratedColumn<double> paramA = GeneratedColumn<double>(
    'param_a',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paramBMeta = const VerificationMeta('paramB');
  @override
  late final GeneratedColumn<double> paramB = GeneratedColumn<double>(
    'param_b',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paramCMeta = const VerificationMeta('paramC');
  @override
  late final GeneratedColumn<double> paramC = GeneratedColumn<double>(
    'param_c',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rSquaredMeta = const VerificationMeta(
    'rSquared',
  );
  @override
  late final GeneratedColumn<double> rSquared = GeneratedColumn<double>(
    'r_squared',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nPointsMeta = const VerificationMeta(
    'nPoints',
  );
  @override
  late final GeneratedColumn<int> nPoints = GeneratedColumn<int>(
    'n_points',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nIntensityRangesMeta = const VerificationMeta(
    'nIntensityRanges',
  );
  @override
  late final GeneratedColumn<int> nIntensityRanges = GeneratedColumn<int>(
    'n_intensity_ranges',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _confidenceLevelMeta = const VerificationMeta(
    'confidenceLevel',
  );
  @override
  late final GeneratedColumn<String> confidenceLevel = GeneratedColumn<String>(
    'confidence_level',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastUpdatedMeta = const VerificationMeta(
    'lastUpdated',
  );
  @override
  late final GeneratedColumn<String> lastUpdated = GeneratedColumn<String>(
    'last_updated',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    athleteId,
    paramA,
    paramB,
    paramC,
    rSquared,
    nPoints,
    nIntensityRanges,
    confidenceLevel,
    lastUpdated,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'nomogram_models';
  @override
  VerificationContext validateIntegrity(
    Insertable<NomogramModel> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('athlete_id')) {
      context.handle(
        _athleteIdMeta,
        athleteId.isAcceptableOrUnknown(data['athlete_id']!, _athleteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_athleteIdMeta);
    }
    if (data.containsKey('param_a')) {
      context.handle(
        _paramAMeta,
        paramA.isAcceptableOrUnknown(data['param_a']!, _paramAMeta),
      );
    } else if (isInserting) {
      context.missing(_paramAMeta);
    }
    if (data.containsKey('param_b')) {
      context.handle(
        _paramBMeta,
        paramB.isAcceptableOrUnknown(data['param_b']!, _paramBMeta),
      );
    } else if (isInserting) {
      context.missing(_paramBMeta);
    }
    if (data.containsKey('param_c')) {
      context.handle(
        _paramCMeta,
        paramC.isAcceptableOrUnknown(data['param_c']!, _paramCMeta),
      );
    } else if (isInserting) {
      context.missing(_paramCMeta);
    }
    if (data.containsKey('r_squared')) {
      context.handle(
        _rSquaredMeta,
        rSquared.isAcceptableOrUnknown(data['r_squared']!, _rSquaredMeta),
      );
    }
    if (data.containsKey('n_points')) {
      context.handle(
        _nPointsMeta,
        nPoints.isAcceptableOrUnknown(data['n_points']!, _nPointsMeta),
      );
    } else if (isInserting) {
      context.missing(_nPointsMeta);
    }
    if (data.containsKey('n_intensity_ranges')) {
      context.handle(
        _nIntensityRangesMeta,
        nIntensityRanges.isAcceptableOrUnknown(
          data['n_intensity_ranges']!,
          _nIntensityRangesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nIntensityRangesMeta);
    }
    if (data.containsKey('confidence_level')) {
      context.handle(
        _confidenceLevelMeta,
        confidenceLevel.isAcceptableOrUnknown(
          data['confidence_level']!,
          _confidenceLevelMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_confidenceLevelMeta);
    }
    if (data.containsKey('last_updated')) {
      context.handle(
        _lastUpdatedMeta,
        lastUpdated.isAcceptableOrUnknown(
          data['last_updated']!,
          _lastUpdatedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastUpdatedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NomogramModel map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NomogramModel(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      athleteId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}athlete_id'],
      )!,
      paramA: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}param_a'],
      )!,
      paramB: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}param_b'],
      )!,
      paramC: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}param_c'],
      )!,
      rSquared: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}r_squared'],
      ),
      nPoints: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}n_points'],
      )!,
      nIntensityRanges: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}n_intensity_ranges'],
      )!,
      confidenceLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}confidence_level'],
      )!,
      lastUpdated: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_updated'],
      )!,
    );
  }

  @override
  $NomogramModelsTable createAlias(String alias) {
    return $NomogramModelsTable(attachedDatabase, alias);
  }
}

class NomogramModel extends DataClass implements Insertable<NomogramModel> {
  final int id;
  final int athleteId;
  final double paramA;
  final double paramB;
  final double paramC;
  final double? rSquared;
  final int nPoints;
  final int nIntensityRanges;
  final String confidenceLevel;
  final String lastUpdated;
  const NomogramModel({
    required this.id,
    required this.athleteId,
    required this.paramA,
    required this.paramB,
    required this.paramC,
    this.rSquared,
    required this.nPoints,
    required this.nIntensityRanges,
    required this.confidenceLevel,
    required this.lastUpdated,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['athlete_id'] = Variable<int>(athleteId);
    map['param_a'] = Variable<double>(paramA);
    map['param_b'] = Variable<double>(paramB);
    map['param_c'] = Variable<double>(paramC);
    if (!nullToAbsent || rSquared != null) {
      map['r_squared'] = Variable<double>(rSquared);
    }
    map['n_points'] = Variable<int>(nPoints);
    map['n_intensity_ranges'] = Variable<int>(nIntensityRanges);
    map['confidence_level'] = Variable<String>(confidenceLevel);
    map['last_updated'] = Variable<String>(lastUpdated);
    return map;
  }

  NomogramModelsCompanion toCompanion(bool nullToAbsent) {
    return NomogramModelsCompanion(
      id: Value(id),
      athleteId: Value(athleteId),
      paramA: Value(paramA),
      paramB: Value(paramB),
      paramC: Value(paramC),
      rSquared: rSquared == null && nullToAbsent
          ? const Value.absent()
          : Value(rSquared),
      nPoints: Value(nPoints),
      nIntensityRanges: Value(nIntensityRanges),
      confidenceLevel: Value(confidenceLevel),
      lastUpdated: Value(lastUpdated),
    );
  }

  factory NomogramModel.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NomogramModel(
      id: serializer.fromJson<int>(json['id']),
      athleteId: serializer.fromJson<int>(json['athleteId']),
      paramA: serializer.fromJson<double>(json['paramA']),
      paramB: serializer.fromJson<double>(json['paramB']),
      paramC: serializer.fromJson<double>(json['paramC']),
      rSquared: serializer.fromJson<double?>(json['rSquared']),
      nPoints: serializer.fromJson<int>(json['nPoints']),
      nIntensityRanges: serializer.fromJson<int>(json['nIntensityRanges']),
      confidenceLevel: serializer.fromJson<String>(json['confidenceLevel']),
      lastUpdated: serializer.fromJson<String>(json['lastUpdated']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'athleteId': serializer.toJson<int>(athleteId),
      'paramA': serializer.toJson<double>(paramA),
      'paramB': serializer.toJson<double>(paramB),
      'paramC': serializer.toJson<double>(paramC),
      'rSquared': serializer.toJson<double?>(rSquared),
      'nPoints': serializer.toJson<int>(nPoints),
      'nIntensityRanges': serializer.toJson<int>(nIntensityRanges),
      'confidenceLevel': serializer.toJson<String>(confidenceLevel),
      'lastUpdated': serializer.toJson<String>(lastUpdated),
    };
  }

  NomogramModel copyWith({
    int? id,
    int? athleteId,
    double? paramA,
    double? paramB,
    double? paramC,
    Value<double?> rSquared = const Value.absent(),
    int? nPoints,
    int? nIntensityRanges,
    String? confidenceLevel,
    String? lastUpdated,
  }) => NomogramModel(
    id: id ?? this.id,
    athleteId: athleteId ?? this.athleteId,
    paramA: paramA ?? this.paramA,
    paramB: paramB ?? this.paramB,
    paramC: paramC ?? this.paramC,
    rSquared: rSquared.present ? rSquared.value : this.rSquared,
    nPoints: nPoints ?? this.nPoints,
    nIntensityRanges: nIntensityRanges ?? this.nIntensityRanges,
    confidenceLevel: confidenceLevel ?? this.confidenceLevel,
    lastUpdated: lastUpdated ?? this.lastUpdated,
  );
  NomogramModel copyWithCompanion(NomogramModelsCompanion data) {
    return NomogramModel(
      id: data.id.present ? data.id.value : this.id,
      athleteId: data.athleteId.present ? data.athleteId.value : this.athleteId,
      paramA: data.paramA.present ? data.paramA.value : this.paramA,
      paramB: data.paramB.present ? data.paramB.value : this.paramB,
      paramC: data.paramC.present ? data.paramC.value : this.paramC,
      rSquared: data.rSquared.present ? data.rSquared.value : this.rSquared,
      nPoints: data.nPoints.present ? data.nPoints.value : this.nPoints,
      nIntensityRanges: data.nIntensityRanges.present
          ? data.nIntensityRanges.value
          : this.nIntensityRanges,
      confidenceLevel: data.confidenceLevel.present
          ? data.confidenceLevel.value
          : this.confidenceLevel,
      lastUpdated: data.lastUpdated.present
          ? data.lastUpdated.value
          : this.lastUpdated,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NomogramModel(')
          ..write('id: $id, ')
          ..write('athleteId: $athleteId, ')
          ..write('paramA: $paramA, ')
          ..write('paramB: $paramB, ')
          ..write('paramC: $paramC, ')
          ..write('rSquared: $rSquared, ')
          ..write('nPoints: $nPoints, ')
          ..write('nIntensityRanges: $nIntensityRanges, ')
          ..write('confidenceLevel: $confidenceLevel, ')
          ..write('lastUpdated: $lastUpdated')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    athleteId,
    paramA,
    paramB,
    paramC,
    rSquared,
    nPoints,
    nIntensityRanges,
    confidenceLevel,
    lastUpdated,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NomogramModel &&
          other.id == this.id &&
          other.athleteId == this.athleteId &&
          other.paramA == this.paramA &&
          other.paramB == this.paramB &&
          other.paramC == this.paramC &&
          other.rSquared == this.rSquared &&
          other.nPoints == this.nPoints &&
          other.nIntensityRanges == this.nIntensityRanges &&
          other.confidenceLevel == this.confidenceLevel &&
          other.lastUpdated == this.lastUpdated);
}

class NomogramModelsCompanion extends UpdateCompanion<NomogramModel> {
  final Value<int> id;
  final Value<int> athleteId;
  final Value<double> paramA;
  final Value<double> paramB;
  final Value<double> paramC;
  final Value<double?> rSquared;
  final Value<int> nPoints;
  final Value<int> nIntensityRanges;
  final Value<String> confidenceLevel;
  final Value<String> lastUpdated;
  const NomogramModelsCompanion({
    this.id = const Value.absent(),
    this.athleteId = const Value.absent(),
    this.paramA = const Value.absent(),
    this.paramB = const Value.absent(),
    this.paramC = const Value.absent(),
    this.rSquared = const Value.absent(),
    this.nPoints = const Value.absent(),
    this.nIntensityRanges = const Value.absent(),
    this.confidenceLevel = const Value.absent(),
    this.lastUpdated = const Value.absent(),
  });
  NomogramModelsCompanion.insert({
    this.id = const Value.absent(),
    required int athleteId,
    required double paramA,
    required double paramB,
    required double paramC,
    this.rSquared = const Value.absent(),
    required int nPoints,
    required int nIntensityRanges,
    required String confidenceLevel,
    required String lastUpdated,
  }) : athleteId = Value(athleteId),
       paramA = Value(paramA),
       paramB = Value(paramB),
       paramC = Value(paramC),
       nPoints = Value(nPoints),
       nIntensityRanges = Value(nIntensityRanges),
       confidenceLevel = Value(confidenceLevel),
       lastUpdated = Value(lastUpdated);
  static Insertable<NomogramModel> custom({
    Expression<int>? id,
    Expression<int>? athleteId,
    Expression<double>? paramA,
    Expression<double>? paramB,
    Expression<double>? paramC,
    Expression<double>? rSquared,
    Expression<int>? nPoints,
    Expression<int>? nIntensityRanges,
    Expression<String>? confidenceLevel,
    Expression<String>? lastUpdated,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (athleteId != null) 'athlete_id': athleteId,
      if (paramA != null) 'param_a': paramA,
      if (paramB != null) 'param_b': paramB,
      if (paramC != null) 'param_c': paramC,
      if (rSquared != null) 'r_squared': rSquared,
      if (nPoints != null) 'n_points': nPoints,
      if (nIntensityRanges != null) 'n_intensity_ranges': nIntensityRanges,
      if (confidenceLevel != null) 'confidence_level': confidenceLevel,
      if (lastUpdated != null) 'last_updated': lastUpdated,
    });
  }

  NomogramModelsCompanion copyWith({
    Value<int>? id,
    Value<int>? athleteId,
    Value<double>? paramA,
    Value<double>? paramB,
    Value<double>? paramC,
    Value<double?>? rSquared,
    Value<int>? nPoints,
    Value<int>? nIntensityRanges,
    Value<String>? confidenceLevel,
    Value<String>? lastUpdated,
  }) {
    return NomogramModelsCompanion(
      id: id ?? this.id,
      athleteId: athleteId ?? this.athleteId,
      paramA: paramA ?? this.paramA,
      paramB: paramB ?? this.paramB,
      paramC: paramC ?? this.paramC,
      rSquared: rSquared ?? this.rSquared,
      nPoints: nPoints ?? this.nPoints,
      nIntensityRanges: nIntensityRanges ?? this.nIntensityRanges,
      confidenceLevel: confidenceLevel ?? this.confidenceLevel,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (athleteId.present) {
      map['athlete_id'] = Variable<int>(athleteId.value);
    }
    if (paramA.present) {
      map['param_a'] = Variable<double>(paramA.value);
    }
    if (paramB.present) {
      map['param_b'] = Variable<double>(paramB.value);
    }
    if (paramC.present) {
      map['param_c'] = Variable<double>(paramC.value);
    }
    if (rSquared.present) {
      map['r_squared'] = Variable<double>(rSquared.value);
    }
    if (nPoints.present) {
      map['n_points'] = Variable<int>(nPoints.value);
    }
    if (nIntensityRanges.present) {
      map['n_intensity_ranges'] = Variable<int>(nIntensityRanges.value);
    }
    if (confidenceLevel.present) {
      map['confidence_level'] = Variable<String>(confidenceLevel.value);
    }
    if (lastUpdated.present) {
      map['last_updated'] = Variable<String>(lastUpdated.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NomogramModelsCompanion(')
          ..write('id: $id, ')
          ..write('athleteId: $athleteId, ')
          ..write('paramA: $paramA, ')
          ..write('paramB: $paramB, ')
          ..write('paramC: $paramC, ')
          ..write('rSquared: $rSquared, ')
          ..write('nPoints: $nPoints, ')
          ..write('nIntensityRanges: $nIntensityRanges, ')
          ..write('confidenceLevel: $confidenceLevel, ')
          ..write('lastUpdated: $lastUpdated')
          ..write(')'))
        .toString();
  }
}

class $ExclusionsOrNotesTable extends ExclusionsOrNotes
    with TableInfo<$ExclusionsOrNotesTable, ExclusionsOrNote> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExclusionsOrNotesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<int> sessionId = GeneratedColumn<int>(
    'session_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sessions (id)',
    ),
  );
  static const VerificationMeta _athleteIdMeta = const VerificationMeta(
    'athleteId',
  );
  @override
  late final GeneratedColumn<int> athleteId = GeneratedColumn<int>(
    'athlete_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES athletes (id)',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    athleteId,
    type,
    reason,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exclusions_or_notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExclusionsOrNote> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    }
    if (data.containsKey('athlete_id')) {
      context.handle(
        _athleteIdMeta,
        athleteId.isAcceptableOrUnknown(data['athlete_id']!, _athleteIdMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonMeta);
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
  ExclusionsOrNote map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExclusionsOrNote(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}session_id'],
      ),
      athleteId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}athlete_id'],
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ExclusionsOrNotesTable createAlias(String alias) {
    return $ExclusionsOrNotesTable(attachedDatabase, alias);
  }
}

class ExclusionsOrNote extends DataClass
    implements Insertable<ExclusionsOrNote> {
  final int id;
  final int? sessionId;
  final int? athleteId;
  final String type;
  final String reason;
  final String createdAt;
  const ExclusionsOrNote({
    required this.id,
    this.sessionId,
    this.athleteId,
    required this.type,
    required this.reason,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || sessionId != null) {
      map['session_id'] = Variable<int>(sessionId);
    }
    if (!nullToAbsent || athleteId != null) {
      map['athlete_id'] = Variable<int>(athleteId);
    }
    map['type'] = Variable<String>(type);
    map['reason'] = Variable<String>(reason);
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  ExclusionsOrNotesCompanion toCompanion(bool nullToAbsent) {
    return ExclusionsOrNotesCompanion(
      id: Value(id),
      sessionId: sessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(sessionId),
      athleteId: athleteId == null && nullToAbsent
          ? const Value.absent()
          : Value(athleteId),
      type: Value(type),
      reason: Value(reason),
      createdAt: Value(createdAt),
    );
  }

  factory ExclusionsOrNote.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExclusionsOrNote(
      id: serializer.fromJson<int>(json['id']),
      sessionId: serializer.fromJson<int?>(json['sessionId']),
      athleteId: serializer.fromJson<int?>(json['athleteId']),
      type: serializer.fromJson<String>(json['type']),
      reason: serializer.fromJson<String>(json['reason']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionId': serializer.toJson<int?>(sessionId),
      'athleteId': serializer.toJson<int?>(athleteId),
      'type': serializer.toJson<String>(type),
      'reason': serializer.toJson<String>(reason),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  ExclusionsOrNote copyWith({
    int? id,
    Value<int?> sessionId = const Value.absent(),
    Value<int?> athleteId = const Value.absent(),
    String? type,
    String? reason,
    String? createdAt,
  }) => ExclusionsOrNote(
    id: id ?? this.id,
    sessionId: sessionId.present ? sessionId.value : this.sessionId,
    athleteId: athleteId.present ? athleteId.value : this.athleteId,
    type: type ?? this.type,
    reason: reason ?? this.reason,
    createdAt: createdAt ?? this.createdAt,
  );
  ExclusionsOrNote copyWithCompanion(ExclusionsOrNotesCompanion data) {
    return ExclusionsOrNote(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      athleteId: data.athleteId.present ? data.athleteId.value : this.athleteId,
      type: data.type.present ? data.type.value : this.type,
      reason: data.reason.present ? data.reason.value : this.reason,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExclusionsOrNote(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('athleteId: $athleteId, ')
          ..write('type: $type, ')
          ..write('reason: $reason, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, sessionId, athleteId, type, reason, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExclusionsOrNote &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.athleteId == this.athleteId &&
          other.type == this.type &&
          other.reason == this.reason &&
          other.createdAt == this.createdAt);
}

class ExclusionsOrNotesCompanion extends UpdateCompanion<ExclusionsOrNote> {
  final Value<int> id;
  final Value<int?> sessionId;
  final Value<int?> athleteId;
  final Value<String> type;
  final Value<String> reason;
  final Value<String> createdAt;
  const ExclusionsOrNotesCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.athleteId = const Value.absent(),
    this.type = const Value.absent(),
    this.reason = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ExclusionsOrNotesCompanion.insert({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.athleteId = const Value.absent(),
    required String type,
    required String reason,
    required String createdAt,
  }) : type = Value(type),
       reason = Value(reason),
       createdAt = Value(createdAt);
  static Insertable<ExclusionsOrNote> custom({
    Expression<int>? id,
    Expression<int>? sessionId,
    Expression<int>? athleteId,
    Expression<String>? type,
    Expression<String>? reason,
    Expression<String>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (athleteId != null) 'athlete_id': athleteId,
      if (type != null) 'type': type,
      if (reason != null) 'reason': reason,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ExclusionsOrNotesCompanion copyWith({
    Value<int>? id,
    Value<int?>? sessionId,
    Value<int?>? athleteId,
    Value<String>? type,
    Value<String>? reason,
    Value<String>? createdAt,
  }) {
    return ExclusionsOrNotesCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      athleteId: athleteId ?? this.athleteId,
      type: type ?? this.type,
      reason: reason ?? this.reason,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    if (athleteId.present) {
      map['athlete_id'] = Variable<int>(athleteId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExclusionsOrNotesCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('athleteId: $athleteId, ')
          ..write('type: $type, ')
          ..write('reason: $reason, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
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
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String key;
  final String value;
  final String updatedAt;
  const AppSetting({
    required this.key,
    required this.value,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  AppSetting copyWith({String? key, String? value, String? updatedAt}) =>
      AppSetting(
        key: key ?? this.key,
        value: value ?? this.value,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    required String updatedAt,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value),
       updatedAt = Value(updatedAt);
  static Insertable<AppSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<String>? updatedAt,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AthletesTable athletes = $AthletesTable(this);
  late final $ImportBatchesTable importBatches = $ImportBatchesTable(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $MeasurementsHrvTable measurementsHrv = $MeasurementsHrvTable(
    this,
  );
  late final $IntensityVariablesTable intensityVariables =
      $IntensityVariablesTable(this);
  late final $NomogramModelsTable nomogramModels = $NomogramModelsTable(this);
  late final $ExclusionsOrNotesTable exclusionsOrNotes =
      $ExclusionsOrNotesTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final AthletesDao athletesDao = AthletesDao(this as AppDatabase);
  late final SessionsDao sessionsDao = SessionsDao(this as AppDatabase);
  late final SettingsDao settingsDao = SettingsDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    athletes,
    importBatches,
    sessions,
    measurementsHrv,
    intensityVariables,
    nomogramModels,
    exclusionsOrNotes,
    appSettings,
  ];
}

typedef $$AthletesTableCreateCompanionBuilder =
    AthletesCompanion Function({
      Value<int> id,
      required String name,
      Value<String?> sport,
      Value<String?> birthDate,
      Value<String?> gender,
      Value<String?> positionOrEvent,
      Value<double?> masKmh,
      Value<double?> vvo2maxKmh,
      Value<double?> mapW,
      Value<double?> fcMax,
      Value<String?> notes,
      Value<bool> isArchived,
      required String createdAt,
      required String updatedAt,
    });
typedef $$AthletesTableUpdateCompanionBuilder =
    AthletesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String?> sport,
      Value<String?> birthDate,
      Value<String?> gender,
      Value<String?> positionOrEvent,
      Value<double?> masKmh,
      Value<double?> vvo2maxKmh,
      Value<double?> mapW,
      Value<double?> fcMax,
      Value<String?> notes,
      Value<bool> isArchived,
      Value<String> createdAt,
      Value<String> updatedAt,
    });

final class $$AthletesTableReferences
    extends BaseReferences<_$AppDatabase, $AthletesTable, Athlete> {
  $$AthletesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SessionsTable, List<Session>> _sessionsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.sessions,
    aliasName: $_aliasNameGenerator(db.athletes.id, db.sessions.athleteId),
  );

  $$SessionsTableProcessedTableManager get sessionsRefs {
    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.athleteId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_sessionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$NomogramModelsTable, List<NomogramModel>>
  _nomogramModelsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.nomogramModels,
    aliasName: $_aliasNameGenerator(
      db.athletes.id,
      db.nomogramModels.athleteId,
    ),
  );

  $$NomogramModelsTableProcessedTableManager get nomogramModelsRefs {
    final manager = $$NomogramModelsTableTableManager(
      $_db,
      $_db.nomogramModels,
    ).filter((f) => f.athleteId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_nomogramModelsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ExclusionsOrNotesTable, List<ExclusionsOrNote>>
  _exclusionsOrNotesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.exclusionsOrNotes,
        aliasName: $_aliasNameGenerator(
          db.athletes.id,
          db.exclusionsOrNotes.athleteId,
        ),
      );

  $$ExclusionsOrNotesTableProcessedTableManager get exclusionsOrNotesRefs {
    final manager = $$ExclusionsOrNotesTableTableManager(
      $_db,
      $_db.exclusionsOrNotes,
    ).filter((f) => f.athleteId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _exclusionsOrNotesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AthletesTableFilterComposer
    extends Composer<_$AppDatabase, $AthletesTable> {
  $$AthletesTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sport => $composableBuilder(
    column: $table.sport,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get birthDate => $composableBuilder(
    column: $table.birthDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gender => $composableBuilder(
    column: $table.gender,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get positionOrEvent => $composableBuilder(
    column: $table.positionOrEvent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get masKmh => $composableBuilder(
    column: $table.masKmh,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get vvo2maxKmh => $composableBuilder(
    column: $table.vvo2maxKmh,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get mapW => $composableBuilder(
    column: $table.mapW,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fcMax => $composableBuilder(
    column: $table.fcMax,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> sessionsRefs(
    Expression<bool> Function($$SessionsTableFilterComposer f) f,
  ) {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.athleteId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableFilterComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> nomogramModelsRefs(
    Expression<bool> Function($$NomogramModelsTableFilterComposer f) f,
  ) {
    final $$NomogramModelsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.nomogramModels,
      getReferencedColumn: (t) => t.athleteId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NomogramModelsTableFilterComposer(
            $db: $db,
            $table: $db.nomogramModels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> exclusionsOrNotesRefs(
    Expression<bool> Function($$ExclusionsOrNotesTableFilterComposer f) f,
  ) {
    final $$ExclusionsOrNotesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.exclusionsOrNotes,
      getReferencedColumn: (t) => t.athleteId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExclusionsOrNotesTableFilterComposer(
            $db: $db,
            $table: $db.exclusionsOrNotes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AthletesTableOrderingComposer
    extends Composer<_$AppDatabase, $AthletesTable> {
  $$AthletesTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sport => $composableBuilder(
    column: $table.sport,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get birthDate => $composableBuilder(
    column: $table.birthDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gender => $composableBuilder(
    column: $table.gender,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get positionOrEvent => $composableBuilder(
    column: $table.positionOrEvent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get masKmh => $composableBuilder(
    column: $table.masKmh,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get vvo2maxKmh => $composableBuilder(
    column: $table.vvo2maxKmh,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get mapW => $composableBuilder(
    column: $table.mapW,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fcMax => $composableBuilder(
    column: $table.fcMax,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AthletesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AthletesTable> {
  $$AthletesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get sport =>
      $composableBuilder(column: $table.sport, builder: (column) => column);

  GeneratedColumn<String> get birthDate =>
      $composableBuilder(column: $table.birthDate, builder: (column) => column);

  GeneratedColumn<String> get gender =>
      $composableBuilder(column: $table.gender, builder: (column) => column);

  GeneratedColumn<String> get positionOrEvent => $composableBuilder(
    column: $table.positionOrEvent,
    builder: (column) => column,
  );

  GeneratedColumn<double> get masKmh =>
      $composableBuilder(column: $table.masKmh, builder: (column) => column);

  GeneratedColumn<double> get vvo2maxKmh => $composableBuilder(
    column: $table.vvo2maxKmh,
    builder: (column) => column,
  );

  GeneratedColumn<double> get mapW =>
      $composableBuilder(column: $table.mapW, builder: (column) => column);

  GeneratedColumn<double> get fcMax =>
      $composableBuilder(column: $table.fcMax, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> sessionsRefs<T extends Object>(
    Expression<T> Function($$SessionsTableAnnotationComposer a) f,
  ) {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.athleteId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> nomogramModelsRefs<T extends Object>(
    Expression<T> Function($$NomogramModelsTableAnnotationComposer a) f,
  ) {
    final $$NomogramModelsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.nomogramModels,
      getReferencedColumn: (t) => t.athleteId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NomogramModelsTableAnnotationComposer(
            $db: $db,
            $table: $db.nomogramModels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> exclusionsOrNotesRefs<T extends Object>(
    Expression<T> Function($$ExclusionsOrNotesTableAnnotationComposer a) f,
  ) {
    final $$ExclusionsOrNotesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.exclusionsOrNotes,
          getReferencedColumn: (t) => t.athleteId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ExclusionsOrNotesTableAnnotationComposer(
                $db: $db,
                $table: $db.exclusionsOrNotes,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$AthletesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AthletesTable,
          Athlete,
          $$AthletesTableFilterComposer,
          $$AthletesTableOrderingComposer,
          $$AthletesTableAnnotationComposer,
          $$AthletesTableCreateCompanionBuilder,
          $$AthletesTableUpdateCompanionBuilder,
          (Athlete, $$AthletesTableReferences),
          Athlete,
          PrefetchHooks Function({
            bool sessionsRefs,
            bool nomogramModelsRefs,
            bool exclusionsOrNotesRefs,
          })
        > {
  $$AthletesTableTableManager(_$AppDatabase db, $AthletesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AthletesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AthletesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AthletesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> sport = const Value.absent(),
                Value<String?> birthDate = const Value.absent(),
                Value<String?> gender = const Value.absent(),
                Value<String?> positionOrEvent = const Value.absent(),
                Value<double?> masKmh = const Value.absent(),
                Value<double?> vvo2maxKmh = const Value.absent(),
                Value<double?> mapW = const Value.absent(),
                Value<double?> fcMax = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
              }) => AthletesCompanion(
                id: id,
                name: name,
                sport: sport,
                birthDate: birthDate,
                gender: gender,
                positionOrEvent: positionOrEvent,
                masKmh: masKmh,
                vvo2maxKmh: vvo2maxKmh,
                mapW: mapW,
                fcMax: fcMax,
                notes: notes,
                isArchived: isArchived,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String?> sport = const Value.absent(),
                Value<String?> birthDate = const Value.absent(),
                Value<String?> gender = const Value.absent(),
                Value<String?> positionOrEvent = const Value.absent(),
                Value<double?> masKmh = const Value.absent(),
                Value<double?> vvo2maxKmh = const Value.absent(),
                Value<double?> mapW = const Value.absent(),
                Value<double?> fcMax = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                required String createdAt,
                required String updatedAt,
              }) => AthletesCompanion.insert(
                id: id,
                name: name,
                sport: sport,
                birthDate: birthDate,
                gender: gender,
                positionOrEvent: positionOrEvent,
                masKmh: masKmh,
                vvo2maxKmh: vvo2maxKmh,
                mapW: mapW,
                fcMax: fcMax,
                notes: notes,
                isArchived: isArchived,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AthletesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                sessionsRefs = false,
                nomogramModelsRefs = false,
                exclusionsOrNotesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (sessionsRefs) db.sessions,
                    if (nomogramModelsRefs) db.nomogramModels,
                    if (exclusionsOrNotesRefs) db.exclusionsOrNotes,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (sessionsRefs)
                        await $_getPrefetchedData<
                          Athlete,
                          $AthletesTable,
                          Session
                        >(
                          currentTable: table,
                          referencedTable: $$AthletesTableReferences
                              ._sessionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AthletesTableReferences(
                                db,
                                table,
                                p0,
                              ).sessionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.athleteId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (nomogramModelsRefs)
                        await $_getPrefetchedData<
                          Athlete,
                          $AthletesTable,
                          NomogramModel
                        >(
                          currentTable: table,
                          referencedTable: $$AthletesTableReferences
                              ._nomogramModelsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AthletesTableReferences(
                                db,
                                table,
                                p0,
                              ).nomogramModelsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.athleteId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (exclusionsOrNotesRefs)
                        await $_getPrefetchedData<
                          Athlete,
                          $AthletesTable,
                          ExclusionsOrNote
                        >(
                          currentTable: table,
                          referencedTable: $$AthletesTableReferences
                              ._exclusionsOrNotesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AthletesTableReferences(
                                db,
                                table,
                                p0,
                              ).exclusionsOrNotesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.athleteId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$AthletesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AthletesTable,
      Athlete,
      $$AthletesTableFilterComposer,
      $$AthletesTableOrderingComposer,
      $$AthletesTableAnnotationComposer,
      $$AthletesTableCreateCompanionBuilder,
      $$AthletesTableUpdateCompanionBuilder,
      (Athlete, $$AthletesTableReferences),
      Athlete,
      PrefetchHooks Function({
        bool sessionsRefs,
        bool nomogramModelsRefs,
        bool exclusionsOrNotesRefs,
      })
    >;
typedef $$ImportBatchesTableCreateCompanionBuilder =
    ImportBatchesCompanion Function({
      Value<int> id,
      Value<String?> filename,
      required String importType,
      Value<int?> rowCount,
      Value<int?> errorCount,
      Value<String?> notes,
      required String createdAt,
    });
typedef $$ImportBatchesTableUpdateCompanionBuilder =
    ImportBatchesCompanion Function({
      Value<int> id,
      Value<String?> filename,
      Value<String> importType,
      Value<int?> rowCount,
      Value<int?> errorCount,
      Value<String?> notes,
      Value<String> createdAt,
    });

final class $$ImportBatchesTableReferences
    extends BaseReferences<_$AppDatabase, $ImportBatchesTable, ImportBatche> {
  $$ImportBatchesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$SessionsTable, List<Session>> _sessionsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.sessions,
    aliasName: $_aliasNameGenerator(
      db.importBatches.id,
      db.sessions.importBatchId,
    ),
  );

  $$SessionsTableProcessedTableManager get sessionsRefs {
    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.importBatchId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_sessionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ImportBatchesTableFilterComposer
    extends Composer<_$AppDatabase, $ImportBatchesTable> {
  $$ImportBatchesTableFilterComposer({
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

  ColumnFilters<String> get filename => $composableBuilder(
    column: $table.filename,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get importType => $composableBuilder(
    column: $table.importType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rowCount => $composableBuilder(
    column: $table.rowCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get errorCount => $composableBuilder(
    column: $table.errorCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> sessionsRefs(
    Expression<bool> Function($$SessionsTableFilterComposer f) f,
  ) {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.importBatchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableFilterComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ImportBatchesTableOrderingComposer
    extends Composer<_$AppDatabase, $ImportBatchesTable> {
  $$ImportBatchesTableOrderingComposer({
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

  ColumnOrderings<String> get filename => $composableBuilder(
    column: $table.filename,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get importType => $composableBuilder(
    column: $table.importType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rowCount => $composableBuilder(
    column: $table.rowCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get errorCount => $composableBuilder(
    column: $table.errorCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ImportBatchesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ImportBatchesTable> {
  $$ImportBatchesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get filename =>
      $composableBuilder(column: $table.filename, builder: (column) => column);

  GeneratedColumn<String> get importType => $composableBuilder(
    column: $table.importType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rowCount =>
      $composableBuilder(column: $table.rowCount, builder: (column) => column);

  GeneratedColumn<int> get errorCount => $composableBuilder(
    column: $table.errorCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> sessionsRefs<T extends Object>(
    Expression<T> Function($$SessionsTableAnnotationComposer a) f,
  ) {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.importBatchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ImportBatchesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ImportBatchesTable,
          ImportBatche,
          $$ImportBatchesTableFilterComposer,
          $$ImportBatchesTableOrderingComposer,
          $$ImportBatchesTableAnnotationComposer,
          $$ImportBatchesTableCreateCompanionBuilder,
          $$ImportBatchesTableUpdateCompanionBuilder,
          (ImportBatche, $$ImportBatchesTableReferences),
          ImportBatche,
          PrefetchHooks Function({bool sessionsRefs})
        > {
  $$ImportBatchesTableTableManager(_$AppDatabase db, $ImportBatchesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ImportBatchesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ImportBatchesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ImportBatchesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> filename = const Value.absent(),
                Value<String> importType = const Value.absent(),
                Value<int?> rowCount = const Value.absent(),
                Value<int?> errorCount = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
              }) => ImportBatchesCompanion(
                id: id,
                filename: filename,
                importType: importType,
                rowCount: rowCount,
                errorCount: errorCount,
                notes: notes,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> filename = const Value.absent(),
                required String importType,
                Value<int?> rowCount = const Value.absent(),
                Value<int?> errorCount = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                required String createdAt,
              }) => ImportBatchesCompanion.insert(
                id: id,
                filename: filename,
                importType: importType,
                rowCount: rowCount,
                errorCount: errorCount,
                notes: notes,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ImportBatchesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (sessionsRefs) db.sessions],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (sessionsRefs)
                    await $_getPrefetchedData<
                      ImportBatche,
                      $ImportBatchesTable,
                      Session
                    >(
                      currentTable: table,
                      referencedTable: $$ImportBatchesTableReferences
                          ._sessionsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ImportBatchesTableReferences(
                            db,
                            table,
                            p0,
                          ).sessionsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.importBatchId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ImportBatchesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ImportBatchesTable,
      ImportBatche,
      $$ImportBatchesTableFilterComposer,
      $$ImportBatchesTableOrderingComposer,
      $$ImportBatchesTableAnnotationComposer,
      $$ImportBatchesTableCreateCompanionBuilder,
      $$ImportBatchesTableUpdateCompanionBuilder,
      (ImportBatche, $$ImportBatchesTableReferences),
      ImportBatche,
      PrefetchHooks Function({bool sessionsRefs})
    >;
typedef $$SessionsTableCreateCompanionBuilder =
    SessionsCompanion Function({
      Value<int> id,
      required int athleteId,
      required String date,
      Value<String?> taskName,
      Value<String?> sport,
      Value<String?> sessionType,
      Value<String?> protocolName,
      Value<String?> contextEnvironment,
      Value<bool> isDraft,
      Value<double?> intensityPercent,
      Value<String?> intensitySource,
      Value<double?> recoveryTimeMin,
      Value<double?> recoveryWindowStartMin,
      Value<double?> recoveryWindowEndMin,
      Value<double?> rmssdExercise,
      Value<bool> rmssdExerciseIsDefault,
      Value<double?> rmssdRecovery,
      Value<double?> slopeRaw,
      Value<double?> slopeInterpreted,
      Value<double?> itlIndex,
      Value<String?> classification,
      Value<String?> hrvInputMode,
      Value<String?> rmssdRecoverySource,
      Value<String?> rmssdExerciseSource,
      Value<String?> rrQualityFlag,
      Value<double?> rrArtifactPercent,
      Value<String?> rrPreprocessingMode,
      Value<bool> rrCorrectionEnabled,
      Value<String?> rrCorrectionMethod,
      Value<double?> rrRawRmssd,
      Value<double?> rrCorrectedRmssd,
      Value<double?> rrRmssdUsed,
      Value<int?> rrArtifactCount,
      Value<String?> rrQualityDecision,
      Value<String?> rrQualityNotesJson,
      Value<double?> rrRmssdDeltaPercent,
      Value<int?> importBatchId,
      Value<String?> notes,
      required String createdAt,
    });
typedef $$SessionsTableUpdateCompanionBuilder =
    SessionsCompanion Function({
      Value<int> id,
      Value<int> athleteId,
      Value<String> date,
      Value<String?> taskName,
      Value<String?> sport,
      Value<String?> sessionType,
      Value<String?> protocolName,
      Value<String?> contextEnvironment,
      Value<bool> isDraft,
      Value<double?> intensityPercent,
      Value<String?> intensitySource,
      Value<double?> recoveryTimeMin,
      Value<double?> recoveryWindowStartMin,
      Value<double?> recoveryWindowEndMin,
      Value<double?> rmssdExercise,
      Value<bool> rmssdExerciseIsDefault,
      Value<double?> rmssdRecovery,
      Value<double?> slopeRaw,
      Value<double?> slopeInterpreted,
      Value<double?> itlIndex,
      Value<String?> classification,
      Value<String?> hrvInputMode,
      Value<String?> rmssdRecoverySource,
      Value<String?> rmssdExerciseSource,
      Value<String?> rrQualityFlag,
      Value<double?> rrArtifactPercent,
      Value<String?> rrPreprocessingMode,
      Value<bool> rrCorrectionEnabled,
      Value<String?> rrCorrectionMethod,
      Value<double?> rrRawRmssd,
      Value<double?> rrCorrectedRmssd,
      Value<double?> rrRmssdUsed,
      Value<int?> rrArtifactCount,
      Value<String?> rrQualityDecision,
      Value<String?> rrQualityNotesJson,
      Value<double?> rrRmssdDeltaPercent,
      Value<int?> importBatchId,
      Value<String?> notes,
      Value<String> createdAt,
    });

final class $$SessionsTableReferences
    extends BaseReferences<_$AppDatabase, $SessionsTable, Session> {
  $$SessionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AthletesTable _athleteIdTable(_$AppDatabase db) => db.athletes
      .createAlias($_aliasNameGenerator(db.sessions.athleteId, db.athletes.id));

  $$AthletesTableProcessedTableManager get athleteId {
    final $_column = $_itemColumn<int>('athlete_id')!;

    final manager = $$AthletesTableTableManager(
      $_db,
      $_db.athletes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_athleteIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ImportBatchesTable _importBatchIdTable(_$AppDatabase db) =>
      db.importBatches.createAlias(
        $_aliasNameGenerator(db.sessions.importBatchId, db.importBatches.id),
      );

  $$ImportBatchesTableProcessedTableManager? get importBatchId {
    final $_column = $_itemColumn<int>('import_batch_id');
    if ($_column == null) return null;
    final manager = $$ImportBatchesTableTableManager(
      $_db,
      $_db.importBatches,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_importBatchIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$MeasurementsHrvTable, List<MeasurementsHrvData>>
  _measurementsHrvRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.measurementsHrv,
    aliasName: $_aliasNameGenerator(
      db.sessions.id,
      db.measurementsHrv.sessionId,
    ),
  );

  $$MeasurementsHrvTableProcessedTableManager get measurementsHrvRefs {
    final manager = $$MeasurementsHrvTableTableManager(
      $_db,
      $_db.measurementsHrv,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _measurementsHrvRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$IntensityVariablesTable, List<IntensityVariable>>
  _intensityVariablesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.intensityVariables,
        aliasName: $_aliasNameGenerator(
          db.sessions.id,
          db.intensityVariables.sessionId,
        ),
      );

  $$IntensityVariablesTableProcessedTableManager get intensityVariablesRefs {
    final manager = $$IntensityVariablesTableTableManager(
      $_db,
      $_db.intensityVariables,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _intensityVariablesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ExclusionsOrNotesTable, List<ExclusionsOrNote>>
  _exclusionsOrNotesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.exclusionsOrNotes,
        aliasName: $_aliasNameGenerator(
          db.sessions.id,
          db.exclusionsOrNotes.sessionId,
        ),
      );

  $$ExclusionsOrNotesTableProcessedTableManager get exclusionsOrNotesRefs {
    final manager = $$ExclusionsOrNotesTableTableManager(
      $_db,
      $_db.exclusionsOrNotes,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _exclusionsOrNotesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SessionsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer({
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

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taskName => $composableBuilder(
    column: $table.taskName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sport => $composableBuilder(
    column: $table.sport,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionType => $composableBuilder(
    column: $table.sessionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get protocolName => $composableBuilder(
    column: $table.protocolName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contextEnvironment => $composableBuilder(
    column: $table.contextEnvironment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDraft => $composableBuilder(
    column: $table.isDraft,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get intensityPercent => $composableBuilder(
    column: $table.intensityPercent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get intensitySource => $composableBuilder(
    column: $table.intensitySource,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get recoveryTimeMin => $composableBuilder(
    column: $table.recoveryTimeMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get recoveryWindowStartMin => $composableBuilder(
    column: $table.recoveryWindowStartMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get recoveryWindowEndMin => $composableBuilder(
    column: $table.recoveryWindowEndMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rmssdExercise => $composableBuilder(
    column: $table.rmssdExercise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get rmssdExerciseIsDefault => $composableBuilder(
    column: $table.rmssdExerciseIsDefault,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rmssdRecovery => $composableBuilder(
    column: $table.rmssdRecovery,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get slopeRaw => $composableBuilder(
    column: $table.slopeRaw,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get slopeInterpreted => $composableBuilder(
    column: $table.slopeInterpreted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get itlIndex => $composableBuilder(
    column: $table.itlIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get classification => $composableBuilder(
    column: $table.classification,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hrvInputMode => $composableBuilder(
    column: $table.hrvInputMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rmssdRecoverySource => $composableBuilder(
    column: $table.rmssdRecoverySource,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rmssdExerciseSource => $composableBuilder(
    column: $table.rmssdExerciseSource,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rrQualityFlag => $composableBuilder(
    column: $table.rrQualityFlag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rrArtifactPercent => $composableBuilder(
    column: $table.rrArtifactPercent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rrPreprocessingMode => $composableBuilder(
    column: $table.rrPreprocessingMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get rrCorrectionEnabled => $composableBuilder(
    column: $table.rrCorrectionEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rrCorrectionMethod => $composableBuilder(
    column: $table.rrCorrectionMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rrRawRmssd => $composableBuilder(
    column: $table.rrRawRmssd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rrCorrectedRmssd => $composableBuilder(
    column: $table.rrCorrectedRmssd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rrRmssdUsed => $composableBuilder(
    column: $table.rrRmssdUsed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rrArtifactCount => $composableBuilder(
    column: $table.rrArtifactCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rrQualityDecision => $composableBuilder(
    column: $table.rrQualityDecision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rrQualityNotesJson => $composableBuilder(
    column: $table.rrQualityNotesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rrRmssdDeltaPercent => $composableBuilder(
    column: $table.rrRmssdDeltaPercent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$AthletesTableFilterComposer get athleteId {
    final $$AthletesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.athleteId,
      referencedTable: $db.athletes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AthletesTableFilterComposer(
            $db: $db,
            $table: $db.athletes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ImportBatchesTableFilterComposer get importBatchId {
    final $$ImportBatchesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.importBatchId,
      referencedTable: $db.importBatches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImportBatchesTableFilterComposer(
            $db: $db,
            $table: $db.importBatches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> measurementsHrvRefs(
    Expression<bool> Function($$MeasurementsHrvTableFilterComposer f) f,
  ) {
    final $$MeasurementsHrvTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.measurementsHrv,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MeasurementsHrvTableFilterComposer(
            $db: $db,
            $table: $db.measurementsHrv,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> intensityVariablesRefs(
    Expression<bool> Function($$IntensityVariablesTableFilterComposer f) f,
  ) {
    final $$IntensityVariablesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.intensityVariables,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IntensityVariablesTableFilterComposer(
            $db: $db,
            $table: $db.intensityVariables,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> exclusionsOrNotesRefs(
    Expression<bool> Function($$ExclusionsOrNotesTableFilterComposer f) f,
  ) {
    final $$ExclusionsOrNotesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.exclusionsOrNotes,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExclusionsOrNotesTableFilterComposer(
            $db: $db,
            $table: $db.exclusionsOrNotes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer({
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

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taskName => $composableBuilder(
    column: $table.taskName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sport => $composableBuilder(
    column: $table.sport,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionType => $composableBuilder(
    column: $table.sessionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get protocolName => $composableBuilder(
    column: $table.protocolName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contextEnvironment => $composableBuilder(
    column: $table.contextEnvironment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDraft => $composableBuilder(
    column: $table.isDraft,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get intensityPercent => $composableBuilder(
    column: $table.intensityPercent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get intensitySource => $composableBuilder(
    column: $table.intensitySource,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get recoveryTimeMin => $composableBuilder(
    column: $table.recoveryTimeMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get recoveryWindowStartMin => $composableBuilder(
    column: $table.recoveryWindowStartMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get recoveryWindowEndMin => $composableBuilder(
    column: $table.recoveryWindowEndMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rmssdExercise => $composableBuilder(
    column: $table.rmssdExercise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get rmssdExerciseIsDefault => $composableBuilder(
    column: $table.rmssdExerciseIsDefault,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rmssdRecovery => $composableBuilder(
    column: $table.rmssdRecovery,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get slopeRaw => $composableBuilder(
    column: $table.slopeRaw,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get slopeInterpreted => $composableBuilder(
    column: $table.slopeInterpreted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get itlIndex => $composableBuilder(
    column: $table.itlIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get classification => $composableBuilder(
    column: $table.classification,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hrvInputMode => $composableBuilder(
    column: $table.hrvInputMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rmssdRecoverySource => $composableBuilder(
    column: $table.rmssdRecoverySource,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rmssdExerciseSource => $composableBuilder(
    column: $table.rmssdExerciseSource,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rrQualityFlag => $composableBuilder(
    column: $table.rrQualityFlag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rrArtifactPercent => $composableBuilder(
    column: $table.rrArtifactPercent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rrPreprocessingMode => $composableBuilder(
    column: $table.rrPreprocessingMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get rrCorrectionEnabled => $composableBuilder(
    column: $table.rrCorrectionEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rrCorrectionMethod => $composableBuilder(
    column: $table.rrCorrectionMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rrRawRmssd => $composableBuilder(
    column: $table.rrRawRmssd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rrCorrectedRmssd => $composableBuilder(
    column: $table.rrCorrectedRmssd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rrRmssdUsed => $composableBuilder(
    column: $table.rrRmssdUsed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rrArtifactCount => $composableBuilder(
    column: $table.rrArtifactCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rrQualityDecision => $composableBuilder(
    column: $table.rrQualityDecision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rrQualityNotesJson => $composableBuilder(
    column: $table.rrQualityNotesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rrRmssdDeltaPercent => $composableBuilder(
    column: $table.rrRmssdDeltaPercent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$AthletesTableOrderingComposer get athleteId {
    final $$AthletesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.athleteId,
      referencedTable: $db.athletes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AthletesTableOrderingComposer(
            $db: $db,
            $table: $db.athletes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ImportBatchesTableOrderingComposer get importBatchId {
    final $$ImportBatchesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.importBatchId,
      referencedTable: $db.importBatches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImportBatchesTableOrderingComposer(
            $db: $db,
            $table: $db.importBatches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get taskName =>
      $composableBuilder(column: $table.taskName, builder: (column) => column);

  GeneratedColumn<String> get sport =>
      $composableBuilder(column: $table.sport, builder: (column) => column);

  GeneratedColumn<String> get sessionType => $composableBuilder(
    column: $table.sessionType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get protocolName => $composableBuilder(
    column: $table.protocolName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contextEnvironment => $composableBuilder(
    column: $table.contextEnvironment,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDraft =>
      $composableBuilder(column: $table.isDraft, builder: (column) => column);

  GeneratedColumn<double> get intensityPercent => $composableBuilder(
    column: $table.intensityPercent,
    builder: (column) => column,
  );

  GeneratedColumn<String> get intensitySource => $composableBuilder(
    column: $table.intensitySource,
    builder: (column) => column,
  );

  GeneratedColumn<double> get recoveryTimeMin => $composableBuilder(
    column: $table.recoveryTimeMin,
    builder: (column) => column,
  );

  GeneratedColumn<double> get recoveryWindowStartMin => $composableBuilder(
    column: $table.recoveryWindowStartMin,
    builder: (column) => column,
  );

  GeneratedColumn<double> get recoveryWindowEndMin => $composableBuilder(
    column: $table.recoveryWindowEndMin,
    builder: (column) => column,
  );

  GeneratedColumn<double> get rmssdExercise => $composableBuilder(
    column: $table.rmssdExercise,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get rmssdExerciseIsDefault => $composableBuilder(
    column: $table.rmssdExerciseIsDefault,
    builder: (column) => column,
  );

  GeneratedColumn<double> get rmssdRecovery => $composableBuilder(
    column: $table.rmssdRecovery,
    builder: (column) => column,
  );

  GeneratedColumn<double> get slopeRaw =>
      $composableBuilder(column: $table.slopeRaw, builder: (column) => column);

  GeneratedColumn<double> get slopeInterpreted => $composableBuilder(
    column: $table.slopeInterpreted,
    builder: (column) => column,
  );

  GeneratedColumn<double> get itlIndex =>
      $composableBuilder(column: $table.itlIndex, builder: (column) => column);

  GeneratedColumn<String> get classification => $composableBuilder(
    column: $table.classification,
    builder: (column) => column,
  );

  GeneratedColumn<String> get hrvInputMode => $composableBuilder(
    column: $table.hrvInputMode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rmssdRecoverySource => $composableBuilder(
    column: $table.rmssdRecoverySource,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rmssdExerciseSource => $composableBuilder(
    column: $table.rmssdExerciseSource,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rrQualityFlag => $composableBuilder(
    column: $table.rrQualityFlag,
    builder: (column) => column,
  );

  GeneratedColumn<double> get rrArtifactPercent => $composableBuilder(
    column: $table.rrArtifactPercent,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rrPreprocessingMode => $composableBuilder(
    column: $table.rrPreprocessingMode,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get rrCorrectionEnabled => $composableBuilder(
    column: $table.rrCorrectionEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rrCorrectionMethod => $composableBuilder(
    column: $table.rrCorrectionMethod,
    builder: (column) => column,
  );

  GeneratedColumn<double> get rrRawRmssd => $composableBuilder(
    column: $table.rrRawRmssd,
    builder: (column) => column,
  );

  GeneratedColumn<double> get rrCorrectedRmssd => $composableBuilder(
    column: $table.rrCorrectedRmssd,
    builder: (column) => column,
  );

  GeneratedColumn<double> get rrRmssdUsed => $composableBuilder(
    column: $table.rrRmssdUsed,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rrArtifactCount => $composableBuilder(
    column: $table.rrArtifactCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rrQualityDecision => $composableBuilder(
    column: $table.rrQualityDecision,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rrQualityNotesJson => $composableBuilder(
    column: $table.rrQualityNotesJson,
    builder: (column) => column,
  );

  GeneratedColumn<double> get rrRmssdDeltaPercent => $composableBuilder(
    column: $table.rrRmssdDeltaPercent,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$AthletesTableAnnotationComposer get athleteId {
    final $$AthletesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.athleteId,
      referencedTable: $db.athletes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AthletesTableAnnotationComposer(
            $db: $db,
            $table: $db.athletes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ImportBatchesTableAnnotationComposer get importBatchId {
    final $$ImportBatchesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.importBatchId,
      referencedTable: $db.importBatches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImportBatchesTableAnnotationComposer(
            $db: $db,
            $table: $db.importBatches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> measurementsHrvRefs<T extends Object>(
    Expression<T> Function($$MeasurementsHrvTableAnnotationComposer a) f,
  ) {
    final $$MeasurementsHrvTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.measurementsHrv,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MeasurementsHrvTableAnnotationComposer(
            $db: $db,
            $table: $db.measurementsHrv,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> intensityVariablesRefs<T extends Object>(
    Expression<T> Function($$IntensityVariablesTableAnnotationComposer a) f,
  ) {
    final $$IntensityVariablesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.intensityVariables,
          getReferencedColumn: (t) => t.sessionId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$IntensityVariablesTableAnnotationComposer(
                $db: $db,
                $table: $db.intensityVariables,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> exclusionsOrNotesRefs<T extends Object>(
    Expression<T> Function($$ExclusionsOrNotesTableAnnotationComposer a) f,
  ) {
    final $$ExclusionsOrNotesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.exclusionsOrNotes,
          getReferencedColumn: (t) => t.sessionId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ExclusionsOrNotesTableAnnotationComposer(
                $db: $db,
                $table: $db.exclusionsOrNotes,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$SessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionsTable,
          Session,
          $$SessionsTableFilterComposer,
          $$SessionsTableOrderingComposer,
          $$SessionsTableAnnotationComposer,
          $$SessionsTableCreateCompanionBuilder,
          $$SessionsTableUpdateCompanionBuilder,
          (Session, $$SessionsTableReferences),
          Session,
          PrefetchHooks Function({
            bool athleteId,
            bool importBatchId,
            bool measurementsHrvRefs,
            bool intensityVariablesRefs,
            bool exclusionsOrNotesRefs,
          })
        > {
  $$SessionsTableTableManager(_$AppDatabase db, $SessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> athleteId = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String?> taskName = const Value.absent(),
                Value<String?> sport = const Value.absent(),
                Value<String?> sessionType = const Value.absent(),
                Value<String?> protocolName = const Value.absent(),
                Value<String?> contextEnvironment = const Value.absent(),
                Value<bool> isDraft = const Value.absent(),
                Value<double?> intensityPercent = const Value.absent(),
                Value<String?> intensitySource = const Value.absent(),
                Value<double?> recoveryTimeMin = const Value.absent(),
                Value<double?> recoveryWindowStartMin = const Value.absent(),
                Value<double?> recoveryWindowEndMin = const Value.absent(),
                Value<double?> rmssdExercise = const Value.absent(),
                Value<bool> rmssdExerciseIsDefault = const Value.absent(),
                Value<double?> rmssdRecovery = const Value.absent(),
                Value<double?> slopeRaw = const Value.absent(),
                Value<double?> slopeInterpreted = const Value.absent(),
                Value<double?> itlIndex = const Value.absent(),
                Value<String?> classification = const Value.absent(),
                Value<String?> hrvInputMode = const Value.absent(),
                Value<String?> rmssdRecoverySource = const Value.absent(),
                Value<String?> rmssdExerciseSource = const Value.absent(),
                Value<String?> rrQualityFlag = const Value.absent(),
                Value<double?> rrArtifactPercent = const Value.absent(),
                Value<String?> rrPreprocessingMode = const Value.absent(),
                Value<bool> rrCorrectionEnabled = const Value.absent(),
                Value<String?> rrCorrectionMethod = const Value.absent(),
                Value<double?> rrRawRmssd = const Value.absent(),
                Value<double?> rrCorrectedRmssd = const Value.absent(),
                Value<double?> rrRmssdUsed = const Value.absent(),
                Value<int?> rrArtifactCount = const Value.absent(),
                Value<String?> rrQualityDecision = const Value.absent(),
                Value<String?> rrQualityNotesJson = const Value.absent(),
                Value<double?> rrRmssdDeltaPercent = const Value.absent(),
                Value<int?> importBatchId = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
              }) => SessionsCompanion(
                id: id,
                athleteId: athleteId,
                date: date,
                taskName: taskName,
                sport: sport,
                sessionType: sessionType,
                protocolName: protocolName,
                contextEnvironment: contextEnvironment,
                isDraft: isDraft,
                intensityPercent: intensityPercent,
                intensitySource: intensitySource,
                recoveryTimeMin: recoveryTimeMin,
                recoveryWindowStartMin: recoveryWindowStartMin,
                recoveryWindowEndMin: recoveryWindowEndMin,
                rmssdExercise: rmssdExercise,
                rmssdExerciseIsDefault: rmssdExerciseIsDefault,
                rmssdRecovery: rmssdRecovery,
                slopeRaw: slopeRaw,
                slopeInterpreted: slopeInterpreted,
                itlIndex: itlIndex,
                classification: classification,
                hrvInputMode: hrvInputMode,
                rmssdRecoverySource: rmssdRecoverySource,
                rmssdExerciseSource: rmssdExerciseSource,
                rrQualityFlag: rrQualityFlag,
                rrArtifactPercent: rrArtifactPercent,
                rrPreprocessingMode: rrPreprocessingMode,
                rrCorrectionEnabled: rrCorrectionEnabled,
                rrCorrectionMethod: rrCorrectionMethod,
                rrRawRmssd: rrRawRmssd,
                rrCorrectedRmssd: rrCorrectedRmssd,
                rrRmssdUsed: rrRmssdUsed,
                rrArtifactCount: rrArtifactCount,
                rrQualityDecision: rrQualityDecision,
                rrQualityNotesJson: rrQualityNotesJson,
                rrRmssdDeltaPercent: rrRmssdDeltaPercent,
                importBatchId: importBatchId,
                notes: notes,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int athleteId,
                required String date,
                Value<String?> taskName = const Value.absent(),
                Value<String?> sport = const Value.absent(),
                Value<String?> sessionType = const Value.absent(),
                Value<String?> protocolName = const Value.absent(),
                Value<String?> contextEnvironment = const Value.absent(),
                Value<bool> isDraft = const Value.absent(),
                Value<double?> intensityPercent = const Value.absent(),
                Value<String?> intensitySource = const Value.absent(),
                Value<double?> recoveryTimeMin = const Value.absent(),
                Value<double?> recoveryWindowStartMin = const Value.absent(),
                Value<double?> recoveryWindowEndMin = const Value.absent(),
                Value<double?> rmssdExercise = const Value.absent(),
                Value<bool> rmssdExerciseIsDefault = const Value.absent(),
                Value<double?> rmssdRecovery = const Value.absent(),
                Value<double?> slopeRaw = const Value.absent(),
                Value<double?> slopeInterpreted = const Value.absent(),
                Value<double?> itlIndex = const Value.absent(),
                Value<String?> classification = const Value.absent(),
                Value<String?> hrvInputMode = const Value.absent(),
                Value<String?> rmssdRecoverySource = const Value.absent(),
                Value<String?> rmssdExerciseSource = const Value.absent(),
                Value<String?> rrQualityFlag = const Value.absent(),
                Value<double?> rrArtifactPercent = const Value.absent(),
                Value<String?> rrPreprocessingMode = const Value.absent(),
                Value<bool> rrCorrectionEnabled = const Value.absent(),
                Value<String?> rrCorrectionMethod = const Value.absent(),
                Value<double?> rrRawRmssd = const Value.absent(),
                Value<double?> rrCorrectedRmssd = const Value.absent(),
                Value<double?> rrRmssdUsed = const Value.absent(),
                Value<int?> rrArtifactCount = const Value.absent(),
                Value<String?> rrQualityDecision = const Value.absent(),
                Value<String?> rrQualityNotesJson = const Value.absent(),
                Value<double?> rrRmssdDeltaPercent = const Value.absent(),
                Value<int?> importBatchId = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                required String createdAt,
              }) => SessionsCompanion.insert(
                id: id,
                athleteId: athleteId,
                date: date,
                taskName: taskName,
                sport: sport,
                sessionType: sessionType,
                protocolName: protocolName,
                contextEnvironment: contextEnvironment,
                isDraft: isDraft,
                intensityPercent: intensityPercent,
                intensitySource: intensitySource,
                recoveryTimeMin: recoveryTimeMin,
                recoveryWindowStartMin: recoveryWindowStartMin,
                recoveryWindowEndMin: recoveryWindowEndMin,
                rmssdExercise: rmssdExercise,
                rmssdExerciseIsDefault: rmssdExerciseIsDefault,
                rmssdRecovery: rmssdRecovery,
                slopeRaw: slopeRaw,
                slopeInterpreted: slopeInterpreted,
                itlIndex: itlIndex,
                classification: classification,
                hrvInputMode: hrvInputMode,
                rmssdRecoverySource: rmssdRecoverySource,
                rmssdExerciseSource: rmssdExerciseSource,
                rrQualityFlag: rrQualityFlag,
                rrArtifactPercent: rrArtifactPercent,
                rrPreprocessingMode: rrPreprocessingMode,
                rrCorrectionEnabled: rrCorrectionEnabled,
                rrCorrectionMethod: rrCorrectionMethod,
                rrRawRmssd: rrRawRmssd,
                rrCorrectedRmssd: rrCorrectedRmssd,
                rrRmssdUsed: rrRmssdUsed,
                rrArtifactCount: rrArtifactCount,
                rrQualityDecision: rrQualityDecision,
                rrQualityNotesJson: rrQualityNotesJson,
                rrRmssdDeltaPercent: rrRmssdDeltaPercent,
                importBatchId: importBatchId,
                notes: notes,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                athleteId = false,
                importBatchId = false,
                measurementsHrvRefs = false,
                intensityVariablesRefs = false,
                exclusionsOrNotesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (measurementsHrvRefs) db.measurementsHrv,
                    if (intensityVariablesRefs) db.intensityVariables,
                    if (exclusionsOrNotesRefs) db.exclusionsOrNotes,
                  ],
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
                        if (athleteId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.athleteId,
                                    referencedTable: $$SessionsTableReferences
                                        ._athleteIdTable(db),
                                    referencedColumn: $$SessionsTableReferences
                                        ._athleteIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (importBatchId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.importBatchId,
                                    referencedTable: $$SessionsTableReferences
                                        ._importBatchIdTable(db),
                                    referencedColumn: $$SessionsTableReferences
                                        ._importBatchIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (measurementsHrvRefs)
                        await $_getPrefetchedData<
                          Session,
                          $SessionsTable,
                          MeasurementsHrvData
                        >(
                          currentTable: table,
                          referencedTable: $$SessionsTableReferences
                              ._measurementsHrvRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).measurementsHrvRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sessionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (intensityVariablesRefs)
                        await $_getPrefetchedData<
                          Session,
                          $SessionsTable,
                          IntensityVariable
                        >(
                          currentTable: table,
                          referencedTable: $$SessionsTableReferences
                              ._intensityVariablesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).intensityVariablesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sessionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (exclusionsOrNotesRefs)
                        await $_getPrefetchedData<
                          Session,
                          $SessionsTable,
                          ExclusionsOrNote
                        >(
                          currentTable: table,
                          referencedTable: $$SessionsTableReferences
                              ._exclusionsOrNotesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).exclusionsOrNotesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sessionId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$SessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionsTable,
      Session,
      $$SessionsTableFilterComposer,
      $$SessionsTableOrderingComposer,
      $$SessionsTableAnnotationComposer,
      $$SessionsTableCreateCompanionBuilder,
      $$SessionsTableUpdateCompanionBuilder,
      (Session, $$SessionsTableReferences),
      Session,
      PrefetchHooks Function({
        bool athleteId,
        bool importBatchId,
        bool measurementsHrvRefs,
        bool intensityVariablesRefs,
        bool exclusionsOrNotesRefs,
      })
    >;
typedef $$MeasurementsHrvTableCreateCompanionBuilder =
    MeasurementsHrvCompanion Function({
      Value<int> id,
      required int sessionId,
      required String phase,
      Value<double?> windowStartMin,
      Value<double?> windowEndMin,
      Value<String?> rrIntervalsJson,
      Value<double?> rmssd,
      Value<double?> meanHr,
      Value<double?> sdnn,
      required String createdAt,
    });
typedef $$MeasurementsHrvTableUpdateCompanionBuilder =
    MeasurementsHrvCompanion Function({
      Value<int> id,
      Value<int> sessionId,
      Value<String> phase,
      Value<double?> windowStartMin,
      Value<double?> windowEndMin,
      Value<String?> rrIntervalsJson,
      Value<double?> rmssd,
      Value<double?> meanHr,
      Value<double?> sdnn,
      Value<String> createdAt,
    });

final class $$MeasurementsHrvTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $MeasurementsHrvTable,
          MeasurementsHrvData
        > {
  $$MeasurementsHrvTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.sessions.createAlias(
        $_aliasNameGenerator(db.measurementsHrv.sessionId, db.sessions.id),
      );

  $$SessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<int>('session_id')!;

    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MeasurementsHrvTableFilterComposer
    extends Composer<_$AppDatabase, $MeasurementsHrvTable> {
  $$MeasurementsHrvTableFilterComposer({
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

  ColumnFilters<String> get phase => $composableBuilder(
    column: $table.phase,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get windowStartMin => $composableBuilder(
    column: $table.windowStartMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get windowEndMin => $composableBuilder(
    column: $table.windowEndMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rrIntervalsJson => $composableBuilder(
    column: $table.rrIntervalsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rmssd => $composableBuilder(
    column: $table.rmssd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get meanHr => $composableBuilder(
    column: $table.meanHr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sdnn => $composableBuilder(
    column: $table.sdnn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$SessionsTableFilterComposer get sessionId {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableFilterComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MeasurementsHrvTableOrderingComposer
    extends Composer<_$AppDatabase, $MeasurementsHrvTable> {
  $$MeasurementsHrvTableOrderingComposer({
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

  ColumnOrderings<String> get phase => $composableBuilder(
    column: $table.phase,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get windowStartMin => $composableBuilder(
    column: $table.windowStartMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get windowEndMin => $composableBuilder(
    column: $table.windowEndMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rrIntervalsJson => $composableBuilder(
    column: $table.rrIntervalsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rmssd => $composableBuilder(
    column: $table.rmssd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get meanHr => $composableBuilder(
    column: $table.meanHr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sdnn => $composableBuilder(
    column: $table.sdnn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$SessionsTableOrderingComposer get sessionId {
    final $$SessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableOrderingComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MeasurementsHrvTableAnnotationComposer
    extends Composer<_$AppDatabase, $MeasurementsHrvTable> {
  $$MeasurementsHrvTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get phase =>
      $composableBuilder(column: $table.phase, builder: (column) => column);

  GeneratedColumn<double> get windowStartMin => $composableBuilder(
    column: $table.windowStartMin,
    builder: (column) => column,
  );

  GeneratedColumn<double> get windowEndMin => $composableBuilder(
    column: $table.windowEndMin,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rrIntervalsJson => $composableBuilder(
    column: $table.rrIntervalsJson,
    builder: (column) => column,
  );

  GeneratedColumn<double> get rmssd =>
      $composableBuilder(column: $table.rmssd, builder: (column) => column);

  GeneratedColumn<double> get meanHr =>
      $composableBuilder(column: $table.meanHr, builder: (column) => column);

  GeneratedColumn<double> get sdnn =>
      $composableBuilder(column: $table.sdnn, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$SessionsTableAnnotationComposer get sessionId {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MeasurementsHrvTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MeasurementsHrvTable,
          MeasurementsHrvData,
          $$MeasurementsHrvTableFilterComposer,
          $$MeasurementsHrvTableOrderingComposer,
          $$MeasurementsHrvTableAnnotationComposer,
          $$MeasurementsHrvTableCreateCompanionBuilder,
          $$MeasurementsHrvTableUpdateCompanionBuilder,
          (MeasurementsHrvData, $$MeasurementsHrvTableReferences),
          MeasurementsHrvData,
          PrefetchHooks Function({bool sessionId})
        > {
  $$MeasurementsHrvTableTableManager(
    _$AppDatabase db,
    $MeasurementsHrvTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MeasurementsHrvTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MeasurementsHrvTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MeasurementsHrvTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> sessionId = const Value.absent(),
                Value<String> phase = const Value.absent(),
                Value<double?> windowStartMin = const Value.absent(),
                Value<double?> windowEndMin = const Value.absent(),
                Value<String?> rrIntervalsJson = const Value.absent(),
                Value<double?> rmssd = const Value.absent(),
                Value<double?> meanHr = const Value.absent(),
                Value<double?> sdnn = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
              }) => MeasurementsHrvCompanion(
                id: id,
                sessionId: sessionId,
                phase: phase,
                windowStartMin: windowStartMin,
                windowEndMin: windowEndMin,
                rrIntervalsJson: rrIntervalsJson,
                rmssd: rmssd,
                meanHr: meanHr,
                sdnn: sdnn,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int sessionId,
                required String phase,
                Value<double?> windowStartMin = const Value.absent(),
                Value<double?> windowEndMin = const Value.absent(),
                Value<String?> rrIntervalsJson = const Value.absent(),
                Value<double?> rmssd = const Value.absent(),
                Value<double?> meanHr = const Value.absent(),
                Value<double?> sdnn = const Value.absent(),
                required String createdAt,
              }) => MeasurementsHrvCompanion.insert(
                id: id,
                sessionId: sessionId,
                phase: phase,
                windowStartMin: windowStartMin,
                windowEndMin: windowEndMin,
                rrIntervalsJson: rrIntervalsJson,
                rmssd: rmssd,
                meanHr: meanHr,
                sdnn: sdnn,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MeasurementsHrvTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
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
                    if (sessionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sessionId,
                                referencedTable:
                                    $$MeasurementsHrvTableReferences
                                        ._sessionIdTable(db),
                                referencedColumn:
                                    $$MeasurementsHrvTableReferences
                                        ._sessionIdTable(db)
                                        .id,
                              )
                              as T;
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

typedef $$MeasurementsHrvTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MeasurementsHrvTable,
      MeasurementsHrvData,
      $$MeasurementsHrvTableFilterComposer,
      $$MeasurementsHrvTableOrderingComposer,
      $$MeasurementsHrvTableAnnotationComposer,
      $$MeasurementsHrvTableCreateCompanionBuilder,
      $$MeasurementsHrvTableUpdateCompanionBuilder,
      (MeasurementsHrvData, $$MeasurementsHrvTableReferences),
      MeasurementsHrvData,
      PrefetchHooks Function({bool sessionId})
    >;
typedef $$IntensityVariablesTableCreateCompanionBuilder =
    IntensityVariablesCompanion Function({
      Value<int> id,
      required int sessionId,
      required String category,
      required String name,
      Value<String?> unit,
      required double value,
      Value<String?> source,
      Value<bool> isPrimaryForNomogram,
      Value<String?> notes,
      required String createdAt,
    });
typedef $$IntensityVariablesTableUpdateCompanionBuilder =
    IntensityVariablesCompanion Function({
      Value<int> id,
      Value<int> sessionId,
      Value<String> category,
      Value<String> name,
      Value<String?> unit,
      Value<double> value,
      Value<String?> source,
      Value<bool> isPrimaryForNomogram,
      Value<String?> notes,
      Value<String> createdAt,
    });

final class $$IntensityVariablesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $IntensityVariablesTable,
          IntensityVariable
        > {
  $$IntensityVariablesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.sessions.createAlias(
        $_aliasNameGenerator(db.intensityVariables.sessionId, db.sessions.id),
      );

  $$SessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<int>('session_id')!;

    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$IntensityVariablesTableFilterComposer
    extends Composer<_$AppDatabase, $IntensityVariablesTable> {
  $$IntensityVariablesTableFilterComposer({
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

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPrimaryForNomogram => $composableBuilder(
    column: $table.isPrimaryForNomogram,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$SessionsTableFilterComposer get sessionId {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableFilterComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IntensityVariablesTableOrderingComposer
    extends Composer<_$AppDatabase, $IntensityVariablesTable> {
  $$IntensityVariablesTableOrderingComposer({
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

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPrimaryForNomogram => $composableBuilder(
    column: $table.isPrimaryForNomogram,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$SessionsTableOrderingComposer get sessionId {
    final $$SessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableOrderingComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IntensityVariablesTableAnnotationComposer
    extends Composer<_$AppDatabase, $IntensityVariablesTable> {
  $$IntensityVariablesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<double> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<bool> get isPrimaryForNomogram => $composableBuilder(
    column: $table.isPrimaryForNomogram,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$SessionsTableAnnotationComposer get sessionId {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IntensityVariablesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IntensityVariablesTable,
          IntensityVariable,
          $$IntensityVariablesTableFilterComposer,
          $$IntensityVariablesTableOrderingComposer,
          $$IntensityVariablesTableAnnotationComposer,
          $$IntensityVariablesTableCreateCompanionBuilder,
          $$IntensityVariablesTableUpdateCompanionBuilder,
          (IntensityVariable, $$IntensityVariablesTableReferences),
          IntensityVariable,
          PrefetchHooks Function({bool sessionId})
        > {
  $$IntensityVariablesTableTableManager(
    _$AppDatabase db,
    $IntensityVariablesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IntensityVariablesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IntensityVariablesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IntensityVariablesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> sessionId = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<double> value = const Value.absent(),
                Value<String?> source = const Value.absent(),
                Value<bool> isPrimaryForNomogram = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
              }) => IntensityVariablesCompanion(
                id: id,
                sessionId: sessionId,
                category: category,
                name: name,
                unit: unit,
                value: value,
                source: source,
                isPrimaryForNomogram: isPrimaryForNomogram,
                notes: notes,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int sessionId,
                required String category,
                required String name,
                Value<String?> unit = const Value.absent(),
                required double value,
                Value<String?> source = const Value.absent(),
                Value<bool> isPrimaryForNomogram = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                required String createdAt,
              }) => IntensityVariablesCompanion.insert(
                id: id,
                sessionId: sessionId,
                category: category,
                name: name,
                unit: unit,
                value: value,
                source: source,
                isPrimaryForNomogram: isPrimaryForNomogram,
                notes: notes,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$IntensityVariablesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
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
                    if (sessionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sessionId,
                                referencedTable:
                                    $$IntensityVariablesTableReferences
                                        ._sessionIdTable(db),
                                referencedColumn:
                                    $$IntensityVariablesTableReferences
                                        ._sessionIdTable(db)
                                        .id,
                              )
                              as T;
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

typedef $$IntensityVariablesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IntensityVariablesTable,
      IntensityVariable,
      $$IntensityVariablesTableFilterComposer,
      $$IntensityVariablesTableOrderingComposer,
      $$IntensityVariablesTableAnnotationComposer,
      $$IntensityVariablesTableCreateCompanionBuilder,
      $$IntensityVariablesTableUpdateCompanionBuilder,
      (IntensityVariable, $$IntensityVariablesTableReferences),
      IntensityVariable,
      PrefetchHooks Function({bool sessionId})
    >;
typedef $$NomogramModelsTableCreateCompanionBuilder =
    NomogramModelsCompanion Function({
      Value<int> id,
      required int athleteId,
      required double paramA,
      required double paramB,
      required double paramC,
      Value<double?> rSquared,
      required int nPoints,
      required int nIntensityRanges,
      required String confidenceLevel,
      required String lastUpdated,
    });
typedef $$NomogramModelsTableUpdateCompanionBuilder =
    NomogramModelsCompanion Function({
      Value<int> id,
      Value<int> athleteId,
      Value<double> paramA,
      Value<double> paramB,
      Value<double> paramC,
      Value<double?> rSquared,
      Value<int> nPoints,
      Value<int> nIntensityRanges,
      Value<String> confidenceLevel,
      Value<String> lastUpdated,
    });

final class $$NomogramModelsTableReferences
    extends BaseReferences<_$AppDatabase, $NomogramModelsTable, NomogramModel> {
  $$NomogramModelsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AthletesTable _athleteIdTable(_$AppDatabase db) =>
      db.athletes.createAlias(
        $_aliasNameGenerator(db.nomogramModels.athleteId, db.athletes.id),
      );

  $$AthletesTableProcessedTableManager get athleteId {
    final $_column = $_itemColumn<int>('athlete_id')!;

    final manager = $$AthletesTableTableManager(
      $_db,
      $_db.athletes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_athleteIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$NomogramModelsTableFilterComposer
    extends Composer<_$AppDatabase, $NomogramModelsTable> {
  $$NomogramModelsTableFilterComposer({
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

  ColumnFilters<double> get paramA => $composableBuilder(
    column: $table.paramA,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get paramB => $composableBuilder(
    column: $table.paramB,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get paramC => $composableBuilder(
    column: $table.paramC,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rSquared => $composableBuilder(
    column: $table.rSquared,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nPoints => $composableBuilder(
    column: $table.nPoints,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nIntensityRanges => $composableBuilder(
    column: $table.nIntensityRanges,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get confidenceLevel => $composableBuilder(
    column: $table.confidenceLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastUpdated => $composableBuilder(
    column: $table.lastUpdated,
    builder: (column) => ColumnFilters(column),
  );

  $$AthletesTableFilterComposer get athleteId {
    final $$AthletesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.athleteId,
      referencedTable: $db.athletes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AthletesTableFilterComposer(
            $db: $db,
            $table: $db.athletes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NomogramModelsTableOrderingComposer
    extends Composer<_$AppDatabase, $NomogramModelsTable> {
  $$NomogramModelsTableOrderingComposer({
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

  ColumnOrderings<double> get paramA => $composableBuilder(
    column: $table.paramA,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get paramB => $composableBuilder(
    column: $table.paramB,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get paramC => $composableBuilder(
    column: $table.paramC,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rSquared => $composableBuilder(
    column: $table.rSquared,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nPoints => $composableBuilder(
    column: $table.nPoints,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nIntensityRanges => $composableBuilder(
    column: $table.nIntensityRanges,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get confidenceLevel => $composableBuilder(
    column: $table.confidenceLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastUpdated => $composableBuilder(
    column: $table.lastUpdated,
    builder: (column) => ColumnOrderings(column),
  );

  $$AthletesTableOrderingComposer get athleteId {
    final $$AthletesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.athleteId,
      referencedTable: $db.athletes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AthletesTableOrderingComposer(
            $db: $db,
            $table: $db.athletes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NomogramModelsTableAnnotationComposer
    extends Composer<_$AppDatabase, $NomogramModelsTable> {
  $$NomogramModelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get paramA =>
      $composableBuilder(column: $table.paramA, builder: (column) => column);

  GeneratedColumn<double> get paramB =>
      $composableBuilder(column: $table.paramB, builder: (column) => column);

  GeneratedColumn<double> get paramC =>
      $composableBuilder(column: $table.paramC, builder: (column) => column);

  GeneratedColumn<double> get rSquared =>
      $composableBuilder(column: $table.rSquared, builder: (column) => column);

  GeneratedColumn<int> get nPoints =>
      $composableBuilder(column: $table.nPoints, builder: (column) => column);

  GeneratedColumn<int> get nIntensityRanges => $composableBuilder(
    column: $table.nIntensityRanges,
    builder: (column) => column,
  );

  GeneratedColumn<String> get confidenceLevel => $composableBuilder(
    column: $table.confidenceLevel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastUpdated => $composableBuilder(
    column: $table.lastUpdated,
    builder: (column) => column,
  );

  $$AthletesTableAnnotationComposer get athleteId {
    final $$AthletesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.athleteId,
      referencedTable: $db.athletes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AthletesTableAnnotationComposer(
            $db: $db,
            $table: $db.athletes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NomogramModelsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NomogramModelsTable,
          NomogramModel,
          $$NomogramModelsTableFilterComposer,
          $$NomogramModelsTableOrderingComposer,
          $$NomogramModelsTableAnnotationComposer,
          $$NomogramModelsTableCreateCompanionBuilder,
          $$NomogramModelsTableUpdateCompanionBuilder,
          (NomogramModel, $$NomogramModelsTableReferences),
          NomogramModel,
          PrefetchHooks Function({bool athleteId})
        > {
  $$NomogramModelsTableTableManager(
    _$AppDatabase db,
    $NomogramModelsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NomogramModelsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NomogramModelsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NomogramModelsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> athleteId = const Value.absent(),
                Value<double> paramA = const Value.absent(),
                Value<double> paramB = const Value.absent(),
                Value<double> paramC = const Value.absent(),
                Value<double?> rSquared = const Value.absent(),
                Value<int> nPoints = const Value.absent(),
                Value<int> nIntensityRanges = const Value.absent(),
                Value<String> confidenceLevel = const Value.absent(),
                Value<String> lastUpdated = const Value.absent(),
              }) => NomogramModelsCompanion(
                id: id,
                athleteId: athleteId,
                paramA: paramA,
                paramB: paramB,
                paramC: paramC,
                rSquared: rSquared,
                nPoints: nPoints,
                nIntensityRanges: nIntensityRanges,
                confidenceLevel: confidenceLevel,
                lastUpdated: lastUpdated,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int athleteId,
                required double paramA,
                required double paramB,
                required double paramC,
                Value<double?> rSquared = const Value.absent(),
                required int nPoints,
                required int nIntensityRanges,
                required String confidenceLevel,
                required String lastUpdated,
              }) => NomogramModelsCompanion.insert(
                id: id,
                athleteId: athleteId,
                paramA: paramA,
                paramB: paramB,
                paramC: paramC,
                rSquared: rSquared,
                nPoints: nPoints,
                nIntensityRanges: nIntensityRanges,
                confidenceLevel: confidenceLevel,
                lastUpdated: lastUpdated,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$NomogramModelsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({athleteId = false}) {
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
                    if (athleteId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.athleteId,
                                referencedTable: $$NomogramModelsTableReferences
                                    ._athleteIdTable(db),
                                referencedColumn:
                                    $$NomogramModelsTableReferences
                                        ._athleteIdTable(db)
                                        .id,
                              )
                              as T;
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

typedef $$NomogramModelsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NomogramModelsTable,
      NomogramModel,
      $$NomogramModelsTableFilterComposer,
      $$NomogramModelsTableOrderingComposer,
      $$NomogramModelsTableAnnotationComposer,
      $$NomogramModelsTableCreateCompanionBuilder,
      $$NomogramModelsTableUpdateCompanionBuilder,
      (NomogramModel, $$NomogramModelsTableReferences),
      NomogramModel,
      PrefetchHooks Function({bool athleteId})
    >;
typedef $$ExclusionsOrNotesTableCreateCompanionBuilder =
    ExclusionsOrNotesCompanion Function({
      Value<int> id,
      Value<int?> sessionId,
      Value<int?> athleteId,
      required String type,
      required String reason,
      required String createdAt,
    });
typedef $$ExclusionsOrNotesTableUpdateCompanionBuilder =
    ExclusionsOrNotesCompanion Function({
      Value<int> id,
      Value<int?> sessionId,
      Value<int?> athleteId,
      Value<String> type,
      Value<String> reason,
      Value<String> createdAt,
    });

final class $$ExclusionsOrNotesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ExclusionsOrNotesTable,
          ExclusionsOrNote
        > {
  $$ExclusionsOrNotesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.sessions.createAlias(
        $_aliasNameGenerator(db.exclusionsOrNotes.sessionId, db.sessions.id),
      );

  $$SessionsTableProcessedTableManager? get sessionId {
    final $_column = $_itemColumn<int>('session_id');
    if ($_column == null) return null;
    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AthletesTable _athleteIdTable(_$AppDatabase db) =>
      db.athletes.createAlias(
        $_aliasNameGenerator(db.exclusionsOrNotes.athleteId, db.athletes.id),
      );

  $$AthletesTableProcessedTableManager? get athleteId {
    final $_column = $_itemColumn<int>('athlete_id');
    if ($_column == null) return null;
    final manager = $$AthletesTableTableManager(
      $_db,
      $_db.athletes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_athleteIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ExclusionsOrNotesTableFilterComposer
    extends Composer<_$AppDatabase, $ExclusionsOrNotesTable> {
  $$ExclusionsOrNotesTableFilterComposer({
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

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$SessionsTableFilterComposer get sessionId {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableFilterComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AthletesTableFilterComposer get athleteId {
    final $$AthletesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.athleteId,
      referencedTable: $db.athletes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AthletesTableFilterComposer(
            $db: $db,
            $table: $db.athletes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExclusionsOrNotesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExclusionsOrNotesTable> {
  $$ExclusionsOrNotesTableOrderingComposer({
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

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$SessionsTableOrderingComposer get sessionId {
    final $$SessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableOrderingComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AthletesTableOrderingComposer get athleteId {
    final $$AthletesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.athleteId,
      referencedTable: $db.athletes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AthletesTableOrderingComposer(
            $db: $db,
            $table: $db.athletes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExclusionsOrNotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExclusionsOrNotesTable> {
  $$ExclusionsOrNotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$SessionsTableAnnotationComposer get sessionId {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AthletesTableAnnotationComposer get athleteId {
    final $$AthletesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.athleteId,
      referencedTable: $db.athletes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AthletesTableAnnotationComposer(
            $db: $db,
            $table: $db.athletes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExclusionsOrNotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExclusionsOrNotesTable,
          ExclusionsOrNote,
          $$ExclusionsOrNotesTableFilterComposer,
          $$ExclusionsOrNotesTableOrderingComposer,
          $$ExclusionsOrNotesTableAnnotationComposer,
          $$ExclusionsOrNotesTableCreateCompanionBuilder,
          $$ExclusionsOrNotesTableUpdateCompanionBuilder,
          (ExclusionsOrNote, $$ExclusionsOrNotesTableReferences),
          ExclusionsOrNote,
          PrefetchHooks Function({bool sessionId, bool athleteId})
        > {
  $$ExclusionsOrNotesTableTableManager(
    _$AppDatabase db,
    $ExclusionsOrNotesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExclusionsOrNotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExclusionsOrNotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExclusionsOrNotesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> sessionId = const Value.absent(),
                Value<int?> athleteId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
              }) => ExclusionsOrNotesCompanion(
                id: id,
                sessionId: sessionId,
                athleteId: athleteId,
                type: type,
                reason: reason,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> sessionId = const Value.absent(),
                Value<int?> athleteId = const Value.absent(),
                required String type,
                required String reason,
                required String createdAt,
              }) => ExclusionsOrNotesCompanion.insert(
                id: id,
                sessionId: sessionId,
                athleteId: athleteId,
                type: type,
                reason: reason,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ExclusionsOrNotesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false, athleteId = false}) {
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
                    if (sessionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sessionId,
                                referencedTable:
                                    $$ExclusionsOrNotesTableReferences
                                        ._sessionIdTable(db),
                                referencedColumn:
                                    $$ExclusionsOrNotesTableReferences
                                        ._sessionIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (athleteId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.athleteId,
                                referencedTable:
                                    $$ExclusionsOrNotesTableReferences
                                        ._athleteIdTable(db),
                                referencedColumn:
                                    $$ExclusionsOrNotesTableReferences
                                        ._athleteIdTable(db)
                                        .id,
                              )
                              as T;
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

typedef $$ExclusionsOrNotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExclusionsOrNotesTable,
      ExclusionsOrNote,
      $$ExclusionsOrNotesTableFilterComposer,
      $$ExclusionsOrNotesTableOrderingComposer,
      $$ExclusionsOrNotesTableAnnotationComposer,
      $$ExclusionsOrNotesTableCreateCompanionBuilder,
      $$ExclusionsOrNotesTableUpdateCompanionBuilder,
      (ExclusionsOrNote, $$ExclusionsOrNotesTableReferences),
      ExclusionsOrNote,
      PrefetchHooks Function({bool sessionId, bool athleteId})
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String key,
      required String value,
      required String updatedAt,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<String> updatedAt,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                required String updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                key: key,
                value: value,
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

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AthletesTableTableManager get athletes =>
      $$AthletesTableTableManager(_db, _db.athletes);
  $$ImportBatchesTableTableManager get importBatches =>
      $$ImportBatchesTableTableManager(_db, _db.importBatches);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$MeasurementsHrvTableTableManager get measurementsHrv =>
      $$MeasurementsHrvTableTableManager(_db, _db.measurementsHrv);
  $$IntensityVariablesTableTableManager get intensityVariables =>
      $$IntensityVariablesTableTableManager(_db, _db.intensityVariables);
  $$NomogramModelsTableTableManager get nomogramModels =>
      $$NomogramModelsTableTableManager(_db, _db.nomogramModels);
  $$ExclusionsOrNotesTableTableManager get exclusionsOrNotes =>
      $$ExclusionsOrNotesTableTableManager(_db, _db.exclusionsOrNotes);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
}
