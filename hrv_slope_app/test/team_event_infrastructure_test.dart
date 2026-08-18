import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrv_slope_app/core/constants/hrv_sources.dart';
import 'package:hrv_slope_app/data/database/app_database.dart';
import 'package:hrv_slope_app/data/services/multi_session_save_service.dart';
import 'package:hrv_slope_app/shared/engine/calculation_preview.dart';
import 'package:hrv_slope_app/shared/engine/group_report_builder.dart';
import 'package:hrv_slope_app/shared/engine/individual_nomogram_builder.dart';
import 'package:hrv_slope_app/shared/engine/individual_report_builder.dart';
import 'package:hrv_slope_app/shared/engine/intensity_resolver.dart';
import 'package:hrv_slope_app/shared/engine/longitudinal_builder.dart';
import 'package:hrv_slope_app/shared/engine/nomogram_engine.dart';

void main() {
  group('Schema v4 to v5 migration', () {
    test(
      'preserves existing individual data and leaves eventId null',
      () async {
        final tempDir = await Directory.systemTemp.createTemp('hrv_v4_to_v5_');
        addTearDown(() => tempDir.delete(recursive: true));
        final file = File('${tempDir.path}${Platform.pathSeparator}hrv.sqlite');

        final setupDb = AppDatabase.forTesting(
          NativeDatabase(
            file,
            setup: (rawDb) => rawDb.execute(_schemaV4FixtureSql),
            enableMigrations: false,
          ),
        );
        await setupDb.customSelect('SELECT 1').get();
        await setupDb.close();

        final db = AppDatabase.forTesting(NativeDatabase(file));
        addTearDown(db.close);

        final athletes = await db.athletesDao.getAllAthletes();
        expect(athletes.single.name, 'Legacy Runner');

        final sessions = await db.sessionsDao.getAllSessions();
        expect(sessions.single.taskName, 'Legacy tempo');
        expect(sessions.single.eventId, isNull);

        final measurements = await db.sessionsDao.getHrvMeasurements(
          sessions.single.id,
        );
        expect(measurements.single.rmssd, 22);

        final variables = await db.sessionsDao.getVariablesForSession(
          sessions.single.id,
        );
        expect(variables.map((v) => v.name), contains('percent_mas'));

        final newTables = await db
            .customSelect(
              "SELECT name FROM sqlite_master WHERE type = 'table' "
              "AND name IN ('teams', 'athlete_team_assignments', "
              "'session_events')",
            )
            .get();
        expect(newTables, hasLength(3));
      },
    );
  });

  group('Teams and athlete assignments', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'creates, edits and prevents normalized duplicate team names',
      () async {
        final teamId = await db.teamsDao.createTeam(
          name: ' First Team ',
          sport: 'Running',
        );
        await db.teamsDao.updateTeam(
          id: teamId,
          name: 'First Team Elite',
          sport: 'Trail',
          notes: 'Senior squad',
        );

        final updated = await db.teamsDao.getTeamById(teamId);
        expect(updated!.name, 'First Team Elite');
        expect(updated.normalizedName, 'first team elite');
        expect(updated.sport, 'Trail');
        expect(updated.notes, 'Senior squad');

        expect(
          () => db.teamsDao.createTeam(name: ' first   team   elite '),
          throwsA(isA<SqliteException>()),
        );
      },
    );

    test(
      'archives and restores a team without deleting athletes or sessions',
      () async {
        final athleteId = await _insertAthlete(db, name: 'Runner One');
        final sessionId = await _insertStoredSession(db, athleteId);
        final teamId = await db.teamsDao.createTeam(name: 'Squad A');
        await db.teamsDao.assignAthleteToTeam(
          athleteId: athleteId,
          teamId: teamId,
        );

        await db.teamsDao.archiveTeam(teamId);

        expect((await db.teamsDao.getTeamById(teamId))!.isArchived, isTrue);
        expect(await db.athletesDao.getAthleteById(athleteId), isNotNull);
        expect(await db.sessionsDao.getSessionById(sessionId), isNotNull);
        expect(await db.teamsDao.getAthletesForTeam(teamId), hasLength(1));
        expect(await db.teamsDao.getActiveTeams(), isEmpty);
        expect(await db.teamsDao.getArchivedTeams(), hasLength(1));

        await db.teamsDao.restoreTeam(teamId);
        expect((await db.teamsDao.getTeamById(teamId))!.isArchived, isFalse);
      },
    );

    test('assigns, removes and moves athletes by athleteId', () async {
      final duplicateNameA = await _insertAthlete(db, name: 'Alex Runner');
      final duplicateNameB = await _insertAthlete(db, name: 'Alex Runner');
      final teamA = await db.teamsDao.createTeam(name: 'Team A');
      final teamB = await db.teamsDao.createTeam(name: 'Team B');

      await db.teamsDao.assignAthleteToTeam(
        athleteId: duplicateNameA,
        teamId: teamA,
      );

      var teamAthletes = await db.teamsDao.getAthletesForTeam(teamA);
      expect(teamAthletes.map((a) => a.id), [duplicateNameA]);
      expect((await db.teamsDao.getAthletesWithoutTeam()).map((a) => a.id), [
        duplicateNameB,
      ]);

      await db.teamsDao.moveAthleteToTeam(
        athleteId: duplicateNameA,
        teamId: teamB,
      );

      expect(await db.teamsDao.getAthletesForTeam(teamA), isEmpty);
      teamAthletes = await db.teamsDao.getAthletesForTeam(teamB);
      expect(teamAthletes.single.id, duplicateNameA);

      await db.teamsDao.removeAthleteFromTeam(duplicateNameA);
      expect(await db.teamsDao.getAthletesForTeam(teamB), isEmpty);
      expect((await db.teamsDao.getAthletesWithoutTeam()).map((a) => a.id), [
        duplicateNameA,
        duplicateNameB,
      ]);
    });
  });

  group('Session events', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'creates events with and without a team and queries by id/team/date',
      () async {
        final teamId = await db.teamsDao.createTeam(name: 'Event Team');
        final eventWithTeam = await db.sessionEventsDao.createEvent(
          _eventCompanion(teamId: teamId, date: '2026-08-18T10:00:00'),
        );
        final eventWithoutTeam = await db.sessionEventsDao.createEvent(
          _eventCompanion(date: '2026-08-19T10:00:00'),
        );

        expect(
          (await db.sessionEventsDao.getEventById(eventWithTeam))!.teamId,
          teamId,
        );
        expect(
          (await db.sessionEventsDao.getEventById(eventWithoutTeam))!.teamId,
          isNull,
        );
        expect(
          (await db.sessionEventsDao.getEventsForTeam(teamId)).map((e) => e.id),
          [eventWithTeam],
        );
        expect(
          (await db.sessionEventsDao.getEventsInDateRange(
            dateFrom: '2026-08-19',
            dateTo: '2026-08-20',
          )).map((e) => e.id),
          [eventWithoutTeam],
        );
      },
    );
  });

  group('Multi-session transactional save', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('creates one event and three separate individual sessions', () async {
      final teamId = await db.teamsDao.createTeam(name: 'Squad Multi');
      final athleteIds = <int>[
        await _insertAthlete(db, name: 'Athlete A'),
        await _insertAthlete(db, name: 'Athlete B'),
        await _insertAthlete(db, name: 'Athlete C'),
      ];

      final result = await MultiSessionSaveService(db).saveEventWithSessions(
        event: _multiEvent(teamId: teamId),
        rows: [
          MultiSessionRowInput(
            athleteId: athleteIds[0],
            preview: _preview(
              athleteName: 'Athlete A',
              loadValue: 80,
              rmssdRecovery: 20,
              rmssdExercise: 4,
            ),
          ),
          MultiSessionRowInput(
            athleteId: athleteIds[1],
            preview: _preview(
              athleteName: 'Athlete B',
              loadValue: 82,
              rmssdRecovery: 24,
              rmssdExercise: null,
            ),
          ),
          MultiSessionRowInput(
            athleteId: athleteIds[2],
            preview: _preview(
              athleteName: 'Athlete C',
              loadValue: 78,
              rmssdRecovery: 18,
              rmssdExercise: 5,
            ),
          ),
        ],
      );

      final event = await db.sessionEventsDao.getEventById(result.eventId);
      expect(event, isNotNull);
      expect(event!.teamId, teamId);

      final sessions = await db.sessionEventsDao.getSessionsForEvent(
        result.eventId,
      );
      expect(sessions, hasLength(3));
      expect(sessions.map((s) => s.eventId).toSet(), {result.eventId});
      expect(sessions.map((s) => s.athleteId).toSet(), athleteIds.toSet());

      final fallbackSession = sessions.singleWhere(
        (s) => s.athleteId == athleteIds[1],
      );
      expect(fallbackSession.rmssdExercise, 4);
      expect(fallbackSession.rmssdExerciseIsDefault, isTrue);
      expect(fallbackSession.rmssdExerciseSource, 'fallback_4_ms');

      final measuredFour = sessions.singleWhere(
        (s) => s.athleteId == athleteIds[0],
      );
      expect(measuredFour.rmssdExercise, 4);
      expect(measuredFour.rmssdExerciseIsDefault, isFalse);
      expect(measuredFour.rmssdExerciseSource, 'measured');

      for (final session in sessions) {
        expect(
          await db.sessionsDao.getHrvMeasurements(session.id),
          hasLength(1),
        );
        final variables = await db.sessionsDao.getVariablesForSession(
          session.id,
        );
        expect(variables.map((v) => v.name), contains('percent_mas'));
        expect(variables.map((v) => v.name), contains('interpreted_slope'));
      }
    });

    test(
      'rolls back event, sessions and related rows when an insert fails',
      () async {
        final athleteA = await _insertAthlete(db, name: 'Atomic A');
        final athleteC = await _insertAthlete(db, name: 'Atomic C');

        expect(
          () => MultiSessionSaveService(db).saveEventWithSessions(
            event: _multiEvent(),
            rows: [
              MultiSessionRowInput(
                athleteId: athleteA,
                preview: _preview(athleteName: 'Atomic A', loadValue: 80),
              ),
              MultiSessionRowInput(
                athleteId: 999999,
                preview: _preview(
                  athleteName: 'Missing athlete',
                  loadValue: 81,
                ),
              ),
              MultiSessionRowInput(
                athleteId: athleteC,
                preview: _preview(athleteName: 'Atomic C', loadValue: 82),
              ),
            ],
          ),
          throwsA(isA<SqliteException>()),
        );

        expect(await db.sessionEventsDao.getEventsInDateRange(), isEmpty);
        expect(await db.sessionsDao.getAllSessions(), isEmpty);
        expect(await db.select(db.measurementsHrv).get(), isEmpty);
        expect(await db.select(db.intensityVariables).get(), isEmpty);
      },
    );
  });

  group('Existing individual/report flows remain readable', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'individual session has null eventId and feeds existing reports',
      () async {
        final athleteId = await _insertAthlete(db, name: 'Solo Runner');
        final sessionId = await _insertStoredSession(db, athleteId);
        final session = await db.sessionsDao.getSessionById(sessionId);
        expect(session!.eventId, isNull);

        final detail = await db.sessionsDao.getSessionDetail(sessionId);
        expect(detail, isNotNull);

        final individualReport = buildIndividualReport(
          detail: detail!,
          nomogramPreset: PopulationNomogramSource.excelOperational,
        );
        expect(individualReport.athleteName, 'Solo Runner');
        expect(individualReport.canShowNomogram, isTrue);

        final groupReport = buildGroupReport(
          details: [detail],
          nomogramPreset: PopulationNomogramSource.excelOperational,
        );
        expect(groupReport.rows, hasLength(1));

        final longitudinal = buildLongitudinalSeries(
          athlete: detail.athlete,
          details: [detail],
        );
        expect(longitudinal.points, hasLength(1));

        final nomogram = buildIndividualNomogramData(
          athlete: detail.athlete,
          details: [detail],
          populationPreset: PopulationNomogramSource.excelOperational,
        );
        expect(nomogram.validPoints, hasLength(1));
      },
    );
  });
}

Future<int> _insertAthlete(AppDatabase db, {required String name}) {
  final now = DateTime.now().toIso8601String();
  return db.athletesDao.insertAthlete(
    AthletesCompanion.insert(
      name: name,
      sport: const drift.Value('Running'),
      masKmh: const drift.Value(20),
      createdAt: now,
      updatedAt: now,
    ),
  );
}

Future<int> _insertStoredSession(AppDatabase db, int athleteId) async {
  final now = DateTime.now().toIso8601String();
  final sessionId = await db.sessionsDao.insertSession(
    SessionsCompanion.insert(
      athleteId: athleteId,
      date: '2026-08-18',
      taskName: const drift.Value('Tempo'),
      sport: const drift.Value('Running'),
      sessionType: const drift.Value('training'),
      intensityPercent: const drift.Value(80),
      intensitySource: const drift.Value('direct_percent_mas'),
      recoveryTimeMin: const drift.Value(10),
      recoveryWindowStartMin: const drift.Value(5),
      recoveryWindowEndMin: const drift.Value(10),
      rmssdExercise: const drift.Value(4),
      rmssdExerciseIsDefault: const drift.Value(false),
      rmssdRecovery: const drift.Value(20),
      slopeRaw: const drift.Value(1.6),
      slopeInterpreted: const drift.Value(1.6),
      itlIndex: const drift.Value(0.625),
      classification: const drift.Value('Expected response'),
      hrvInputMode: drift.Value(HrvInputMode.directRmssd.value),
      rmssdRecoverySource: const drift.Value('manual'),
      rmssdExerciseSource: const drift.Value('measured'),
      createdAt: now,
    ),
  );
  await db.sessionsDao.insertHrvMeasurement(
    MeasurementsHrvCompanion.insert(
      sessionId: sessionId,
      phase: 'recovery',
      windowStartMin: const drift.Value(5),
      windowEndMin: const drift.Value(10),
      rmssd: const drift.Value(20),
      createdAt: now,
    ),
  );
  await db.sessionsDao.insertVariables([
    IntensityVariablesCompanion.insert(
      sessionId: sessionId,
      category: 'external',
      name: 'percent_mas',
      unit: const drift.Value('%'),
      value: 80,
      source: const drift.Value('manual'),
      isPrimaryForNomogram: const drift.Value(true),
      createdAt: now,
    ),
    IntensityVariablesCompanion.insert(
      sessionId: sessionId,
      category: 'internal',
      name: 'rpe_1_10',
      value: 7,
      source: const drift.Value('manual'),
      createdAt: now,
    ),
  ]);
  return sessionId;
}

SessionEventsCompanion _eventCompanion({int? teamId, required String date}) {
  final now = DateTime.now().toIso8601String();
  return SessionEventsCompanion.insert(
    teamId: drift.Value(teamId),
    date: date,
    taskName: const drift.Value('RSA'),
    sport: const drift.Value('Running'),
    sessionType: const drift.Value('training'),
    protocolName: const drift.Value('5-10'),
    contextEnvironment: const drift.Value('Indoor'),
    recoveryWindowStartMin: 5,
    recoveryWindowEndMin: 10,
    loadType: 'external',
    loadMetricName: 'percent_mas',
    loadUnit: const drift.Value('%'),
    createdAt: now,
    updatedAt: now,
  );
}

MultiSessionEventInput _multiEvent({int? teamId}) {
  return MultiSessionEventInput(
    teamId: teamId,
    date: '2026-08-18',
    taskName: 'Repeated sprint',
    sport: 'Running',
    sessionType: 'training',
    protocolName: '5-10',
    contextEnvironment: 'Indoor',
    recoveryWindowStartMin: 5,
    recoveryWindowEndMin: 10,
    loadType: 'external',
    loadMetricName: 'percent_mas',
    loadUnit: '%',
  );
}

CalculationPreview _preview({
  required String athleteName,
  double loadValue = 80,
  double rmssdRecovery = 20,
  double? rmssdExercise = 4,
}) {
  final variable = TaggedVariable(
    category: 'external',
    name: 'percent_mas',
    unit: '%',
    value: loadValue,
    source: 'manual',
  );
  final intensity = IntensityResolution(
    intensityPercent: loadValue,
    method: 'direct_percent_mas',
    sourceVariables: const ['percent_mas'],
    warnings: const [],
    canUseNomogram: true,
    source: IntensitySourceForSlope.external,
    metricName: 'direct_percent_mas',
    isFallback: false,
  );

  return buildCalculationPreview(
    athleteName: athleteName,
    sessionDate: '2026-08-18',
    sessionName: 'Repeated sprint',
    sport: 'Running',
    externalVariables: [variable],
    internalVariables: const [
      TaggedVariable(
        category: 'internal',
        name: 'rpe_1_10',
        value: 7,
        source: 'manual',
      ),
    ],
    intensityResolution: intensity,
    rmssdExercise: rmssdExercise,
    rmssdExerciseSource: rmssdExercise == null
        ? RmssdSource.fallback4Ms
        : RmssdSource.measured,
    rmssdRecovery: rmssdRecovery,
    rmssdRecoverySource: RmssdSource.measured,
    hrvInputMode: HrvInputMode.directRmssd,
    recoveryWindowStartMin: 5,
    recoveryWindowEndMin: 10,
    populationPreset: PopulationNomogramSource.excelOperational,
  );
}

const _schemaV4FixtureSql = '''
PRAGMA foreign_keys = OFF;
CREATE TABLE athletes (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  sport TEXT NULL,
  birth_date TEXT NULL,
  gender TEXT NULL,
  position_or_event TEXT NULL,
  mas_kmh REAL NULL,
  vvo2max_kmh REAL NULL,
  map_w REAL NULL,
  fc_max REAL NULL,
  notes TEXT NULL,
  is_archived INTEGER NOT NULL DEFAULT 0 CHECK (is_archived IN (0, 1)),
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
CREATE TABLE import_batches (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  filename TEXT NULL,
  import_type TEXT NOT NULL,
  row_count INTEGER NULL,
  error_count INTEGER NULL,
  notes TEXT NULL,
  created_at TEXT NOT NULL
);
CREATE TABLE sessions (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  athlete_id INTEGER NOT NULL REFERENCES athletes(id),
  date TEXT NOT NULL,
  task_name TEXT NULL,
  sport TEXT NULL,
  session_type TEXT NULL,
  protocol_name TEXT NULL,
  context_environment TEXT NULL,
  is_draft INTEGER NOT NULL DEFAULT 0 CHECK (is_draft IN (0, 1)),
  intensity_percent REAL NULL,
  intensity_source TEXT NULL,
  recovery_time_min REAL NULL,
  recovery_window_start_min REAL NULL,
  recovery_window_end_min REAL NULL,
  rmssd_exercise REAL NULL,
  rmssd_exercise_is_default INTEGER NOT NULL DEFAULT 0
    CHECK (rmssd_exercise_is_default IN (0, 1)),
  rmssd_recovery REAL NULL,
  slope_raw REAL NULL,
  slope_interpreted REAL NULL,
  itl_index REAL NULL,
  classification TEXT NULL,
  hrv_input_mode TEXT NULL,
  rmssd_recovery_source TEXT NULL,
  rmssd_exercise_source TEXT NULL,
  rr_quality_flag TEXT NULL,
  rr_artifact_percent REAL NULL,
  rr_preprocessing_mode TEXT NULL,
  rr_correction_enabled INTEGER NOT NULL DEFAULT 0
    CHECK (rr_correction_enabled IN (0, 1)),
  rr_correction_method TEXT NULL,
  rr_raw_rmssd REAL NULL,
  rr_corrected_rmssd REAL NULL,
  rr_rmssd_used REAL NULL,
  rr_artifact_count INTEGER NULL,
  rr_quality_decision TEXT NULL,
  rr_quality_notes_json TEXT NULL,
  rr_rmssd_delta_percent REAL NULL,
  import_batch_id INTEGER NULL REFERENCES import_batches(id),
  notes TEXT NULL,
  created_at TEXT NOT NULL
);
CREATE TABLE measurements_hrv (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  session_id INTEGER NOT NULL REFERENCES sessions(id),
  phase TEXT NOT NULL,
  window_start_min REAL NULL,
  window_end_min REAL NULL,
  rr_intervals_json TEXT NULL,
  rmssd REAL NULL,
  mean_hr REAL NULL,
  sdnn REAL NULL,
  created_at TEXT NOT NULL
);
CREATE TABLE intensity_variables (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  session_id INTEGER NOT NULL REFERENCES sessions(id),
  category TEXT NOT NULL,
  name TEXT NOT NULL,
  unit TEXT NULL,
  value REAL NOT NULL,
  source TEXT NULL,
  is_primary_for_nomogram INTEGER NOT NULL DEFAULT 0
    CHECK (is_primary_for_nomogram IN (0, 1)),
  notes TEXT NULL,
  created_at TEXT NOT NULL
);
CREATE TABLE nomogram_models (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  athlete_id INTEGER NOT NULL UNIQUE REFERENCES athletes(id),
  param_a REAL NOT NULL,
  param_b REAL NOT NULL,
  param_c REAL NOT NULL,
  r_squared REAL NULL,
  n_points INTEGER NOT NULL,
  n_intensity_ranges INTEGER NOT NULL,
  confidence_level TEXT NOT NULL,
  last_updated TEXT NOT NULL
);
CREATE TABLE exclusions_or_notes (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  session_id INTEGER NULL REFERENCES sessions(id),
  athlete_id INTEGER NULL REFERENCES athletes(id),
  type TEXT NOT NULL,
  reason TEXT NOT NULL,
  created_at TEXT NOT NULL
);
CREATE TABLE app_settings (
  key TEXT NOT NULL PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
INSERT INTO athletes (
  id, name, sport, mas_kmh, is_archived, created_at, updated_at
) VALUES (
  1, 'Legacy Runner', 'Running', 20.0, 0,
  '2026-08-01T00:00:00', '2026-08-01T00:00:00'
);
INSERT INTO sessions (
  id, athlete_id, date, task_name, sport, session_type, is_draft,
  intensity_percent, intensity_source, recovery_time_min,
  recovery_window_start_min, recovery_window_end_min, rmssd_exercise,
  rmssd_exercise_is_default, rmssd_recovery, slope_raw, slope_interpreted,
  itl_index, classification, hrv_input_mode, rmssd_recovery_source,
  rmssd_exercise_source, rr_correction_enabled, created_at
) VALUES (
  1, 1, '2026-08-01', 'Legacy tempo', 'Running', 'training', 0,
  80.0, 'direct_percent_mas', 10.0, 5.0, 10.0, 4.0, 0, 22.0,
  1.8, 1.8, 0.555, 'Expected response', 'direct_rmssd', 'manual',
  'measured', 0, '2026-08-01T00:00:00'
);
INSERT INTO measurements_hrv (
  id, session_id, phase, window_start_min, window_end_min, rmssd, created_at
) VALUES (
  1, 1, 'recovery', 5.0, 10.0, 22.0, '2026-08-01T00:00:00'
);
INSERT INTO intensity_variables (
  id, session_id, category, name, unit, value, source,
  is_primary_for_nomogram, created_at
) VALUES (
  1, 1, 'external', 'percent_mas', '%', 80.0, 'manual', 1,
  '2026-08-01T00:00:00'
);
PRAGMA user_version = 4;
''';
