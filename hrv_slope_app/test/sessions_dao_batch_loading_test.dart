import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrv_slope_app/data/database/app_database.dart';

void main() {
  group('SessionsDao detail aggregate loading', () {
    late _SelectCounter counter;
    late AppDatabase db;

    setUp(() {
      counter = _SelectCounter();
      final executor = drift.ApplyInterceptor(
        NativeDatabase.memory(),
      ).interceptWith(counter);
      db = AppDatabase.forTesting(executor);
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'getAllSessionDetails preserves data and date-desc ordering',
      () async {
        final alphaId = await _insertAthlete(db, name: 'Alpha');
        final bravoId = await _insertAthlete(db, name: 'Bravo');
        final alphaDateOnly = await _insertCompleteSession(
          db,
          athleteId: alphaId,
          date: '2026-08-20',
          taskName: 'Date only',
          slope: 0.2,
          withSecondHrvMeasurement: true,
          withNotes: true,
        );
        final alphaMorning = await _insertCompleteSession(
          db,
          athleteId: alphaId,
          date: '2026-08-20T10:00:00',
          taskName: 'Morning',
          slope: 0.3,
        );
        final alphaAfternoon = await _insertCompleteSession(
          db,
          athleteId: alphaId,
          date: '2026-08-20T17:00:00',
          taskName: 'Afternoon',
          slope: 0.4,
        );
        final bravoLater = await _insertCompleteSession(
          db,
          athleteId: bravoId,
          date: '2026-08-21',
          taskName: 'Later',
          slope: 0.5,
        );

        final details = await db.sessionsDao.getAllSessionDetails();

        expect(details.map((detail) => detail.session.id), [
          bravoLater,
          alphaAfternoon,
          alphaMorning,
          alphaDateOnly,
        ]);
        expect(details.map((detail) => detail.athlete.name), [
          'Bravo',
          'Alpha',
          'Alpha',
          'Alpha',
        ]);

        final dateOnlyDetail = details.singleWhere(
          (detail) => detail.session.id == alphaDateOnly,
        );
        expect(dateOnlyDetail.session.date, '2026-08-20');
        expect(dateOnlyDetail.session.taskName, 'Date only');
        expect(dateOnlyDetail.session.slopeInterpreted, 0.2);
        expect(dateOnlyDetail.variables.map((variable) => variable.category), [
          'derived',
          'external',
          'internal',
        ]);
        expect(dateOnlyDetail.variables.map((variable) => variable.name), [
          'itl_index',
          'speed_kmh',
          'rpe_1_10',
        ]);
        expect(dateOnlyDetail.hrvMeasurements, hasLength(2));
        expect(
          dateOnlyDetail.hrvMeasurements.map(
            (measurement) => measurement.phase,
          ),
          ['recovery', 'exercise'],
        );
        expect(dateOnlyDetail.notes.map((note) => note.reason), [
          'Travel day',
          'Late meal',
        ]);
      },
    );

    test(
      'getSessionDetailsForAthlete preserves athlete aggregate chronological order',
      () async {
        final alphaId = await _insertAthlete(db, name: 'Alpha');
        await _insertAthlete(db, name: 'Bravo');
        final dateOnly = await _insertCompleteSession(
          db,
          athleteId: alphaId,
          date: '2026-08-20',
          taskName: 'Date only',
          slope: 0.2,
          withNotes: true,
        );
        final morning = await _insertCompleteSession(
          db,
          athleteId: alphaId,
          date: '2026-08-20T10:00:00',
          taskName: 'Morning',
          slope: 0.3,
        );
        final afternoon = await _insertCompleteSession(
          db,
          athleteId: alphaId,
          date: '2026-08-20T17:00:00',
          taskName: 'Afternoon',
          slope: 0.4,
        );

        final details = await db.sessionsDao.getSessionDetailsForAthlete(
          alphaId,
        );

        expect(details.map((detail) => detail.session.id), [
          dateOnly,
          morning,
          afternoon,
        ]);
        expect(details.every((detail) => detail.athlete.id == alphaId), isTrue);
        expect(details.map((detail) => detail.session.date), [
          '2026-08-20',
          '2026-08-20T10:00:00',
          '2026-08-20T17:00:00',
        ]);
        expect(details.first.notes.single.reason, 'Travel day');
        expect(
          details.first.variablesByCategory('external').single.name,
          'speed_kmh',
        );
        expect(details.first.hrvMeasurements.single.phase, 'recovery');
      },
    );

    test('detail aggregate methods handle empty input', () async {
      final athleteId = await _insertAthlete(db, name: 'No Sessions');

      expect(await db.sessionsDao.getAllSessionDetails(), isEmpty);
      expect(
        await db.sessionsDao.getSessionDetailsForAthlete(athleteId),
        isEmpty,
      );
    });

    test(
      'getAllSessionDetails uses a constant number of SELECT queries',
      () async {
        final athleteIds = [
          await _insertAthlete(db, name: 'Alpha'),
          await _insertAthlete(db, name: 'Bravo'),
          await _insertAthlete(db, name: 'Charlie'),
        ];
        for (var i = 0; i < 12; i++) {
          await _insertCompleteSession(
            db,
            athleteId: athleteIds[i % athleteIds.length],
            date: '2026-09-${(i + 1).toString().padLeft(2, '0')}',
            taskName: 'Session $i',
            slope: 0.2 + i / 100,
          );
        }

        counter.reset();
        final details = await db.sessionsDao.getAllSessionDetails();

        expect(details, hasLength(12));
        expect(counter.selectCount, 5);
      },
    );

    test(
      'getSessionDetailsForAthlete uses a constant number of SELECT queries',
      () async {
        final athleteId = await _insertAthlete(db, name: 'Alpha');
        for (var i = 0; i < 12; i++) {
          await _insertCompleteSession(
            db,
            athleteId: athleteId,
            date: '2026-09-${(i + 1).toString().padLeft(2, '0')}',
            taskName: 'Session $i',
            slope: 0.2 + i / 100,
          );
        }

        counter.reset();
        final details = await db.sessionsDao.getSessionDetailsForAthlete(
          athleteId,
        );

        expect(details, hasLength(12));
        expect(counter.selectCount, 5);
      },
    );

    test('detail aggregate public methods do not call getSessionDetail', () {
      final source = File(
        'lib/data/database/daos/sessions_dao.dart',
      ).readAsStringSync();

      expect(
        _methodBody(source, 'getAllSessionDetails'),
        isNot(contains('getSessionDetail(')),
      );
      expect(
        _methodBody(source, 'getSessionDetailsForAthlete'),
        isNot(contains('getSessionDetail(')),
      );
    });

    test(
      'loads 80 sessions for one athlete without missing related data',
      () async {
        final athleteId = await _insertAthlete(db, name: 'Alpha');
        for (var i = 0; i < 80; i++) {
          await _insertCompleteSession(
            db,
            athleteId: athleteId,
            date:
                '2026-${(10 + i ~/ 28).toString().padLeft(2, '0')}-'
                '${(i % 28 + 1).toString().padLeft(2, '0')}T10:00:00',
            taskName: 'Athlete session $i',
            slope: 0.2 + i / 1000,
          );
        }

        final details = await db.sessionsDao.getSessionDetailsForAthlete(
          athleteId,
        );

        expect(details, hasLength(80));
        expect(details.first.session.date, '2026-10-01T10:00:00');
        expect(details.last.session.date, '2026-12-24T10:00:00');
        expect(
          details.every((detail) => detail.athlete.id == athleteId),
          isTrue,
        );
        expect(details.every((detail) => detail.variables.length == 3), isTrue);
        expect(
          details.every((detail) => detail.hrvMeasurements.length == 1),
          isTrue,
        );
        expect(details.every((detail) => detail.notes.length == 1), isTrue);
      },
    );

    test(
      'loads 200 total sessions across athletes without dropping aggregates',
      () async {
        final athleteIds = [
          await _insertAthlete(db, name: 'Alpha'),
          await _insertAthlete(db, name: 'Bravo'),
          await _insertAthlete(db, name: 'Charlie'),
          await _insertAthlete(db, name: 'Delta'),
        ];
        for (var i = 0; i < 200; i++) {
          await _insertCompleteSession(
            db,
            athleteId: athleteIds[i % athleteIds.length],
            date:
                '2027-${(i ~/ 28 + 1).toString().padLeft(2, '0')}-'
                '${(i % 28 + 1).toString().padLeft(2, '0')}T'
                '${(i % 24).toString().padLeft(2, '0')}:00:00',
            taskName: 'Team pool $i',
            slope: 0.3 + i / 1000,
          );
        }

        final details = await db.sessionsDao.getAllSessionDetails();

        expect(details, hasLength(200));
        expect(details.first.session.date, startsWith('2027-08-'));
        expect(details.last.session.date, startsWith('2027-01-'));
        expect(
          details.map((detail) => detail.athlete.id).toSet(),
          athleteIds.toSet(),
        );
        expect(details.every((detail) => detail.variables.length == 3), isTrue);
        expect(
          details.every((detail) => detail.hrvMeasurements.length == 1),
          isTrue,
        );
        expect(details.every((detail) => detail.notes.length == 1), isTrue);
      },
    );
  });
}

class _SelectCounter extends drift.QueryInterceptor {
  int selectCount = 0;

  void reset() {
    selectCount = 0;
  }

  @override
  Future<List<Map<String, Object?>>> runSelect(
    drift.QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    selectCount++;
    return super.runSelect(executor, statement, args);
  }
}

Future<int> _insertAthlete(AppDatabase db, {required String name}) {
  const now = '2026-08-20T09:00:00';
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

Future<int> _insertCompleteSession(
  AppDatabase db, {
  required int athleteId,
  required String date,
  required String taskName,
  required double slope,
  bool withSecondHrvMeasurement = false,
  bool withNotes = true,
}) async {
  const now = '2026-08-20T09:00:00';
  final sessionId = await db.sessionsDao.insertSession(
    SessionsCompanion.insert(
      athleteId: athleteId,
      date: date,
      taskName: drift.Value(taskName),
      sport: const drift.Value('Running'),
      sessionType: const drift.Value('training'),
      protocolName: const drift.Value('5-10'),
      contextEnvironment: const drift.Value('Indoor'),
      intensityPercent: const drift.Value(80),
      intensitySource: const drift.Value('direct_percent_mas'),
      recoveryTimeMin: const drift.Value(10),
      recoveryWindowStartMin: const drift.Value(5),
      recoveryWindowEndMin: const drift.Value(10),
      rmssdExercise: const drift.Value(4),
      rmssdExerciseIsDefault: const drift.Value(false),
      rmssdRecovery: const drift.Value(20),
      slopeRaw: drift.Value(slope),
      slopeInterpreted: drift.Value(slope),
      itlIndex: drift.Value(1 / slope),
      classification: const drift.Value('expected_response'),
      hrvInputMode: const drift.Value('direct_rmssd'),
      rmssdRecoverySource: const drift.Value('manual'),
      rmssdExerciseSource: const drift.Value('measured'),
      notes: const drift.Value('Session note'),
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
  if (withSecondHrvMeasurement) {
    await db.sessionsDao.insertHrvMeasurement(
      MeasurementsHrvCompanion.insert(
        sessionId: sessionId,
        phase: 'exercise',
        windowStartMin: const drift.Value(0),
        windowEndMin: const drift.Value(0),
        rmssd: const drift.Value(4),
        createdAt: now,
      ),
    );
  }

  await db.sessionsDao.insertVariables([
    IntensityVariablesCompanion.insert(
      sessionId: sessionId,
      category: 'external',
      name: 'speed_kmh',
      unit: const drift.Value('km/h'),
      value: 16,
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
    IntensityVariablesCompanion.insert(
      sessionId: sessionId,
      category: 'derived',
      name: 'itl_index',
      value: 1 / slope,
      source: const drift.Value('calculated'),
      createdAt: now,
    ),
  ]);

  if (withNotes) {
    await db
        .into(db.exclusionsOrNotes)
        .insert(
          ExclusionsOrNotesCompanion.insert(
            sessionId: drift.Value(sessionId),
            athleteId: drift.Value(athleteId),
            type: 'note',
            reason: 'Travel day',
            createdAt: now,
          ),
        );
  }
  if (withSecondHrvMeasurement && withNotes) {
    await db
        .into(db.exclusionsOrNotes)
        .insert(
          ExclusionsOrNotesCompanion.insert(
            sessionId: drift.Value(sessionId),
            athleteId: drift.Value(athleteId),
            type: 'flag',
            reason: 'Late meal',
            createdAt: now,
          ),
        );
  }

  return sessionId;
}

String _methodBody(String source, String methodName) {
  final signatureIndex = source.indexOf(
    'Future<List<SessionDetail>> $methodName',
  );
  if (signatureIndex == -1) return '';
  final bodyStart = source.indexOf('{', signatureIndex);
  var depth = 0;
  for (var i = bodyStart; i < source.length; i++) {
    final char = source[i];
    if (char == '{') depth++;
    if (char == '}') {
      depth--;
      if (depth == 0) return source.substring(bodyStart, i + 1);
    }
  }
  return source.substring(bodyStart);
}
