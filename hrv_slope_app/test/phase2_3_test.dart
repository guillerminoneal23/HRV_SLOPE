import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrv_slope_app/core/constants/hrv_sources.dart';
import 'package:hrv_slope_app/data/database/app_database.dart';
import 'package:hrv_slope_app/data/services/session_edit_service.dart';
import 'package:hrv_slope_app/shared/engine/rr_preprocessing.dart';

void main() {
  group('Session detail/edit/delete', () {
    late AppDatabase db;
    late int athleteId;
    late int sessionId;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      athleteId = await _insertAthlete(db);
      sessionId = await _insertCompleteSession(db, athleteId);
    });

    tearDown(() async {
      await db.close();
    });

    test('session detail loads existing session', () async {
      final detail = await db.sessionsDao.getSessionDetail(sessionId);
      expect(detail, isNotNull);
      expect(detail!.athlete.name, 'Runner One');
      expect(detail.session.taskName, 'Tempo');
      expect(detail.variablesByCategory('external'), isNotEmpty);
      expect(detail.hrvMeasurements, isNotEmpty);
    });

    test('edit session metadata', () async {
      await _edit(db, sessionId, taskName: 'Edited tempo', sport: 'Cycling');

      final detail = await db.sessionsDao.getSessionDetail(sessionId);
      expect(detail!.session.taskName, 'Edited tempo');
      expect(detail.session.sport, 'Cycling');
      expect(detail.session.protocolName, 'Standard 5-10');
      expect(detail.session.contextEnvironment, 'Indoor');
    });

    test('edit external variable and recompute intensity_percent', () async {
      await _edit(db, sessionId, external: {'speed_kmh': 16.0});

      final session = await db.sessionsDao.getSessionById(sessionId);
      expect(session!.intensityPercent, closeTo(80.0, 0.001));
      expect(session.intensitySource, 'speed_kmh_div_mas');
      final derived = await db.sessionsDao.getVariablesByCategory(
        sessionId,
        'derived',
      );
      expect(
        derived.firstWhere((v) => v.name == 'intensity_percent').value,
        closeTo(80.0, 0.001),
      );
    });

    test('edit internal variable persists', () async {
      await _edit(db, sessionId, internal: {'rpe_1_10': 8});

      final internal = await db.sessionsDao.getVariablesByCategory(
        sessionId,
        'internal',
      );
      expect(internal.single.name, 'rpe_1_10');
      expect(internal.single.value, 8);
    });

    test('edit direct RMSSD recovery and recompute slope', () async {
      await _edit(db, sessionId, rmssdRecovery: 24);

      final session = await db.sessionsDao.getSessionById(sessionId);
      expect(session!.rmssdRecovery, 24);
      expect(session.slopeRaw, closeTo(2.0, 0.001));
      expect(session.slopeInterpreted, closeTo(2.0, 0.001));
      expect(session.itlIndex, closeTo(0.5, 0.001));
    });

    test('edit recovery window 5-10 uses t=10', () async {
      await _edit(db, sessionId, windowStart: 5, windowEnd: 10);

      final session = await db.sessionsDao.getSessionById(sessionId);
      expect(session!.recoveryTimeMin, 10);
      expect(session.slopeRaw, closeTo(1.6, 0.001));
    });

    test('edit recovery window 0-5 is rejected', () async {
      expect(
        () => _edit(db, sessionId, windowStart: 0, windowEnd: 5),
        throwsA(isA<Error>()),
      );
    });

    test('no classification when intensity_percent missing', () async {
      await _edit(db, sessionId, external: {});

      final session = await db.sessionsDao.getSessionById(sessionId);
      expect(session!.intensityPercent, isNull);
      expect(session.classification, isNull);
    });

    test('delete session removes related intensity_variables', () async {
      await db.sessionsDao.deleteSessionCascade(sessionId);

      final variables = await db.sessionsDao.getVariablesForSession(sessionId);
      expect(variables, isEmpty);
    });

    test('delete session removes related HRV measurements', () async {
      await db.sessionsDao.deleteSessionCascade(sessionId);

      final measurements = await db.sessionsDao.getHrvMeasurements(sessionId);
      expect(measurements, isEmpty);
    });

    test(
      'delete session removes related notes and does not delete athlete',
      () async {
        await db
            .into(db.exclusionsOrNotes)
            .insert(
              ExclusionsOrNotesCompanion.insert(
                sessionId: drift.Value(sessionId),
                athleteId: drift.Value(athleteId),
                type: 'note',
                reason: 'Travel day',
                createdAt: DateTime.now().toIso8601String(),
              ),
            );

        await db.sessionsDao.deleteSessionCascade(sessionId);

        expect(await db.sessionsDao.getSessionById(sessionId), isNull);
        expect(await db.athletesDao.getAthleteById(athleteId), isNotNull);
        final notes = await db.select(db.exclusionsOrNotes).get();
        expect(notes, isEmpty);
      },
    );

    test('draft session does not show slope/classification', () async {
      final draftId = await db.sessionsDao.insertSession(
        SessionsCompanion.insert(
          athleteId: athleteId,
          date: '2026-05-26',
          taskName: const drift.Value('Draft session'),
          isDraft: const drift.Value(true),
          createdAt: DateTime.now().toIso8601String(),
        ),
      );

      final draft = await db.sessionsDao.getSessionById(draftId);
      expect(draft!.isDraft, isTrue);
      expect(draft.slopeInterpreted, isNull);
      expect(draft.classification, isNull);
    });
  });

  group('Phase 2.3 scientific guards', () {
    test('UI/import/edit flows still have no legacy computeSlope() usage', () {
      final files = [
        File('lib/ui/screens/import/import_screen.dart'),
        File('lib/ui/screens/session/session_wizard_screen.dart'),
        File('lib/ui/screens/session/session_edit_screen.dart'),
        File('lib/data/services/session_edit_service.dart'),
      ];

      for (final file in files) {
        expect(file.readAsStringSync().contains('computeSlope('), isFalse);
      }
    });

    test('RR correction default remains OFF', () {
      const options = RrPreprocessingOptions();
      expect(options.correctionEnabled, isFalse);
    });

    test('raw RMSSD remains preserved in RR workflows', () {
      final rr = List<double>.filled(300, 1000);
      rr[120] = 500;
      final result = preprocessRrIntervals(
        rr,
        const RrPreprocessingOptions(correctionEnabled: true),
      );

      expect(result.rawRmssd, isNotNull);
      expect(result.correctedRmssd, isNotNull);
      expect(result.rmssdUsed, result.correctedRmssd);
      expect(result.rawRmssd, isNot(equals(result.rmssdUsed)));
    });
  });
}

Future<int> _insertAthlete(AppDatabase db) {
  return db.athletesDao.insertAthlete(
    AthletesCompanion.insert(
      name: 'Runner One',
      sport: const drift.Value('Running'),
      masKmh: const drift.Value(20),
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    ),
  );
}

Future<int> _insertCompleteSession(AppDatabase db, int athleteId) async {
  final now = DateTime.now().toIso8601String();
  final sessionId = await db.sessionsDao.insertSession(
    SessionsCompanion.insert(
      athleteId: athleteId,
      date: '2026-05-25',
      taskName: const drift.Value('Tempo'),
      sport: const drift.Value('Running'),
      sessionType: const drift.Value('training'),
      intensityPercent: const drift.Value(75),
      intensitySource: const drift.Value('direct_percent_mas'),
      recoveryTimeMin: const drift.Value(10),
      recoveryWindowStartMin: const drift.Value(5),
      recoveryWindowEndMin: const drift.Value(10),
      rmssdExercise: const drift.Value(4),
      rmssdRecovery: const drift.Value(20),
      slopeRaw: const drift.Value(1.6),
      slopeInterpreted: const drift.Value(1.6),
      itlIndex: const drift.Value(0.625),
      classification: const drift.Value('expected_response'),
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
      value: 75,
      source: const drift.Value('manual'),
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

Future<void> _edit(
  AppDatabase db,
  int sessionId, {
  String taskName = 'Tempo',
  String sport = 'Running',
  Map<String, double> external = const {'percent_mas': 75},
  Map<String, double> internal = const {'rpe_1_10': 7},
  double rmssdRecovery = 20,
  double? rmssdExercise = 4,
  double windowStart = 5,
  double windowEnd = 10,
}) async {
  await SessionEditService(db).updateDirectRmssdSession(
    SessionEditInput(
      sessionId: sessionId,
      date: '2026-05-25',
      taskName: taskName,
      sport: sport,
      sessionType: 'training',
      protocolName: 'Standard 5-10',
      contextEnvironment: 'Indoor',
      notes: 'Edited',
      externalVariables: external,
      internalVariables: internal,
      rmssdRecovery: rmssdRecovery,
      rmssdExercise: rmssdExercise,
      recoveryWindowStartMin: windowStart,
      recoveryWindowEndMin: windowEnd,
    ),
  );
}
