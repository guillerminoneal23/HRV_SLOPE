// Phase 4.0A tests — Athlete Longitudinal Dashboard MVP.
import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrv_slope_app/data/database/app_database.dart';
import 'package:hrv_slope_app/data/database/daos/sessions_dao.dart';
import 'package:hrv_slope_app/shared/engine/longitudinal_builder.dart';
import 'package:hrv_slope_app/shared/engine/statistics.dart';
import 'package:hrv_slope_app/ui/screens/athletes/athlete_detail_screen.dart';
import 'package:hrv_slope_app/ui/screens/longitudinal/athlete_longitudinal_screen.dart';
import 'package:hrv_slope_app/ui/widgets/longitudinal_chart.dart';

void main() {
  group('Longitudinal builder', () {
    test('points sorted by date ascending', () {
      final series = _series([
        _detail(id: 1, date: '2026-05-03'),
        _detail(id: 2, date: '2026-05-01'),
        _detail(id: 3, date: '2026-05-02'),
      ]);

      expect(series.points.map((p) => p.date), [
        '2026-05-01',
        '2026-05-02',
        '2026-05-03',
      ]);
    });

    test('summary counts complete sessions', () {
      final series = _series([
        _detail(id: 1, slope: 0.5),
        _detail(id: 2, slope: null),
      ]);

      expect(series.summary.nSessions, 2);
      expect(series.summary.nComplete, 1);
    });

    test('latest slope ITL and classification', () {
      final series = _series([
        _detail(id: 1, slope: 0.5),
        _detail(id: 2, slope: 1.0),
      ]);

      expect(series.summary.latestSlope, 1.0);
      expect(series.summary.latestItl, 1.0);
      expect(series.summary.latestClassification, isNotNull);
    });

    test('mean min max slope', () {
      final series = _series([
        _detail(id: 1, slope: 0.5),
        _detail(id: 2, slope: 1.0),
        _detail(id: 3, slope: 1.5),
      ]);

      expect(series.summary.meanSlope, closeTo(1.0, 0.001));
      expect(series.summary.minSlope, 0.5);
      expect(series.summary.maxSlope, 1.5);
    });

    test('trendDirection insufficient with too few points', () {
      final series = _series([_detail(id: 1), _detail(id: 2)]);

      expect(
        series.summary.trendDirection,
        LongitudinalTrendDirection.insufficientData,
      );
    });

    test('trendDirection improving when slope rises', () {
      final series = _series([
        _detail(id: 1, slope: 0.5),
        _detail(id: 2, slope: 0.6),
        _detail(id: 3, slope: 0.7),
        _detail(id: 4, slope: 1.0),
        _detail(id: 5, slope: 1.1),
        _detail(id: 6, slope: 1.2),
      ]);

      expect(
        series.summary.trendDirection,
        LongitudinalTrendDirection.improving,
      );
    });

    test('trendDirection worsening when slope falls', () {
      final series = _series([
        _detail(id: 1, slope: 1.2),
        _detail(id: 2, slope: 1.1),
        _detail(id: 3, slope: 1.0),
        _detail(id: 4, slope: 0.7),
        _detail(id: 5, slope: 0.6),
        _detail(id: 6, slope: 0.5),
      ]);

      expect(
        series.summary.trendDirection,
        LongitudinalTrendDirection.worsening,
      );
    });

    test('extracts RPE sRPE TRIMP from internal variables', () {
      final series = _series([_detail(id: 1, rpe: 7, srpe: 420, trimp: 80)]);

      expect(series.points.single.rpe, 7);
      expect(series.points.single.srpe, 420);
      expect(series.points.single.trimp, 80);
    });

    test('extracts primary external load', () {
      final series = _series([_detail(id: 1, externalName: 'player_load')]);

      expect(series.points.single.primaryExternalLoadName, 'player_load');
      expect(series.points.single.primaryExternalLoadValue, 100);
    });

    test('residual values included', () {
      final series = _series([_detail(id: 1, intensity: 80, slope: 0.5)]);

      expect(series.points.single.residual, isNotNull);
      expect(series.points.single.residualPercent, isNotNull);
    });

    test('missing values generate warnings', () {
      final series = _series([_detail(id: 1, intensity: null, slope: null)]);

      expect(series.points.single.warnings, isNotEmpty);
    });
  });

  group('Rolling and fatigue flags', () {
    test('rolling average calculation works', () {
      final result = rollingAverage([1, 2, 3, 4], 3);

      expect(result, [1, 1.5, 2, 3]);
    });

    test('3 negative residuals below threshold triggers flag', () {
      final series = _series([
        _detail(id: 1, intensity: 60, slope: 0.5),
        _detail(id: 2, intensity: 60, slope: 0.5),
        _detail(id: 3, intensity: 60, slope: 0.5),
      ]);

      expect(
        series.fatigueFlags.any(
          (f) => f.ruleName == 'three_negative_residuals',
        ),
        isTrue,
      );
    });

    test('slope 7 vs 28 drop triggers flag', () {
      final details = <SessionDetail>[
        for (var i = 0; i < 21; i++) _detail(id: i + 1, slope: 1.0),
        for (var i = 21; i < 28; i++) _detail(id: i + 1, slope: 0.4),
      ];
      final series = _series(details);

      expect(
        series.fatigueFlags.any((f) => f.ruleName == 'slope_7_vs_28_drop'),
        isTrue,
      );
    });

    test('ITL 7 vs 28 increase triggers flag', () {
      final details = <SessionDetail>[
        for (var i = 0; i < 21; i++) _detail(id: i + 1, slope: 2.0),
        for (var i = 21; i < 28; i++) _detail(id: i + 1, slope: 0.67),
      ];
      final series = _series(details);

      expect(
        series.fatigueFlags.any((f) => f.ruleName == 'itl_7_vs_28_increase'),
        isTrue,
      );
    });

    test('no false flag with insufficient data', () {
      final series = _series([_detail(id: 1), _detail(id: 2)]);

      expect(series.fatigueFlags, isEmpty);
    });
  });

  group('Longitudinal UI', () {
    late AppDatabase db;
    late int athleteId;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      athleteId = await _seedAthlete(db);
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('athlete detail exposes Longitudinal button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AthleteDetailScreen(database: db, athleteId: athleteId),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Longitudinal'), findsOneWidget);
    });

    testWidgets('longitudinal screen renders header and summary cards', (
      tester,
    ) async {
      await _seedSession(db, athleteId, slope: 0.5);
      await _seedSession(db, athleteId, slope: 1.0, day: 2);

      await tester.pumpWidget(
        MaterialApp(
          home: AthleteLongitudinalScreen(database: db, athleteId: athleteId),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Runner One'), findsOneWidget);
      expect(find.textContaining('Latest slope'), findsOneWidget);
      expect(find.text('Slope Trend'), findsOneWidget);
    });

    testWidgets('slope chart renders with complete data', (tester) async {
      await _seedSession(db, athleteId, slope: 0.5);
      await _seedSession(db, athleteId, slope: 1.0, day: 2);

      await tester.pumpWidget(
        MaterialApp(
          home: LongitudinalChart(
            title: 'Slope Trend',
            valueLabel: 'Slope',
            points: const [
              LongitudinalChartPoint(label: '1', value: 0.5),
              LongitudinalChartPoint(label: '2', value: 1.0),
            ],
          ),
        ),
      );

      expect(find.text('Slope Trend'), findsOneWidget);
      expect(
        find.text('Line: session trend · Dots: available values'),
        findsOneWidget,
      );
    });

    testWidgets('empty state when no complete sessions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AthleteLongitudinalScreen(database: db, athleteId: athleteId),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Not enough complete sessions'),
        findsOneWidget,
      );
    });

    testWidgets('session list includes Open Report action', (tester) async {
      await _seedSession(db, athleteId, slope: 0.5);

      await tester.pumpWidget(
        MaterialApp(
          home: AthleteLongitudinalScreen(database: db, athleteId: athleteId),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Open Report'),
        400,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('Open Report'), findsOneWidget);
    });

    test('no medical diagnostic language', () {
      final text = File(
        'lib/ui/screens/longitudinal/athlete_longitudinal_screen.dart',
      ).readAsStringSync().toLowerCase();

      expect(text, isNot(contains('diagnosis')));
      expect(text, isNot(contains('disease')));
      expect(text, isNot(contains('pathological')));
    });
  });

  group('Phase 4.0A regression guards', () {
    test(
      'no legacy computeSlope() usage in UI/report/import/edit/longitudinal',
      () {
        final files = [
          File('lib/ui/screens/import/import_screen.dart'),
          File('lib/ui/screens/session/session_wizard_screen.dart'),
          File('lib/ui/screens/session/session_edit_screen.dart'),
          File('lib/ui/screens/reports/individual_report_screen.dart'),
          File('lib/ui/screens/reports/group_report_screen.dart'),
          File('lib/ui/screens/reports/population_nomogram_screen.dart'),
          File('lib/ui/screens/longitudinal/athlete_longitudinal_screen.dart'),
          File('lib/data/services/session_edit_service.dart'),
        ];

        for (final file in files) {
          expect(file.readAsStringSync().contains('computeSlope('), isFalse);
        }
      },
    );

    test('direct RMSSD remains default', () {
      expect(_detail(id: 1).session.hrvInputMode, 'direct_rmssd');
    });

    test('RR correction remains off by default', () {
      expect(_detail(id: 1).session.rrCorrectionEnabled, isFalse);
    });

    test('real RR fixtures remain mandatory', () {
      for (final name in [
        '2026-05-25_05-27-02.txt',
        '2026-05-22_05-39-13.txt',
        '2026-05-21_05-42-46.txt',
      ]) {
        expect(File('test/fixtures/rr_samples/$name').existsSync(), isTrue);
      }
    });
  });
}

LongitudinalSeries _series(List<SessionDetail> details) {
  return buildLongitudinalSeries(athlete: _athlete(), details: details);
}

Athlete _athlete() {
  return const Athlete(
    id: 1,
    name: 'Runner One',
    sport: 'Running',
    birthDate: null,
    gender: null,
    positionOrEvent: null,
    masKmh: 20,
    vvo2maxKmh: null,
    mapW: null,
    fcMax: null,
    notes: null,
    isArchived: false,
    createdAt: '2026-05-26T00:00:00',
    updatedAt: '2026-05-26T00:00:00',
  );
}

SessionDetail _detail({
  required int id,
  String? date,
  double? intensity = 80,
  double? slope = 0.5,
  double? rpe = 7,
  double? srpe,
  double? trimp,
  String externalName = 'speed_kmh',
}) {
  final sessionDate = date ?? '2026-05-${id.toString().padLeft(2, '0')}';
  return SessionDetail(
    athlete: _athlete(),
    session: Session(
      id: id,
      athleteId: 1,
      date: sessionDate,
      taskName: 'Session $id',
      sport: 'Running',
      sessionType: 'training',
      protocolName: null,
      contextEnvironment: null,
      isDraft: false,
      intensityPercent: intensity,
      intensitySource: intensity == null ? null : 'direct_percent_mas',
      recoveryTimeMin: slope == null ? null : 10,
      recoveryWindowStartMin: slope == null ? null : 5,
      recoveryWindowEndMin: slope == null ? null : 10,
      rmssdExercise: slope == null ? null : 4,
      rmssdExerciseIsDefault: false,
      rmssdRecovery: slope == null ? null : 24,
      slopeRaw: slope,
      slopeInterpreted: slope,
      itlIndex: slope == null ? null : 1 / slope,
      classification: null,
      hrvInputMode: 'direct_rmssd',
      rmssdRecoverySource: 'manual',
      rmssdExerciseSource: 'measured',
      rrQualityFlag: null,
      rrArtifactPercent: null,
      rrPreprocessingMode: null,
      rrCorrectionEnabled: false,
      rrCorrectionMethod: null,
      rrRawRmssd: null,
      rrCorrectedRmssd: null,
      rrRmssdUsed: null,
      rrArtifactCount: null,
      rrQualityDecision: null,
      rrQualityNotesJson: null,
      rrRmssdDeltaPercent: null,
      importBatchId: null,
      notes: null,
      createdAt: '${sessionDate}T00:00:00',
    ),
    variables: [
      _variable(
        id: id * 10,
        sessionId: id,
        category: 'external',
        name: externalName,
        value: 100,
      ),
      if (rpe != null)
        _variable(
          id: id * 10 + 1,
          sessionId: id,
          category: 'internal',
          name: 'rpe_1_10',
          value: rpe,
        ),
      if (srpe != null)
        _variable(
          id: id * 10 + 2,
          sessionId: id,
          category: 'internal',
          name: 'srpe',
          value: srpe,
        ),
      if (trimp != null)
        _variable(
          id: id * 10 + 3,
          sessionId: id,
          category: 'internal',
          name: 'trimp',
          value: trimp,
        ),
    ],
    hrvMeasurements: const [],
    notes: const [],
  );
}

IntensityVariable _variable({
  required int id,
  required int sessionId,
  required String category,
  required String name,
  required double value,
}) {
  return IntensityVariable(
    id: id,
    sessionId: sessionId,
    category: category,
    name: name,
    unit: null,
    value: value,
    source: 'manual',
    isPrimaryForNomogram: category == 'external',
    notes: null,
    createdAt: '2026-05-26T00:00:00',
  );
}

Future<int> _seedAthlete(AppDatabase db) {
  final now = DateTime.now().toIso8601String();
  return db.athletesDao.insertAthlete(
    AthletesCompanion.insert(
      name: 'Runner One',
      sport: const drift.Value('Running'),
      masKmh: const drift.Value(20),
      createdAt: now,
      updatedAt: now,
    ),
  );
}

Future<int> _seedSession(
  AppDatabase db,
  int athleteId, {
  double slope = 0.5,
  int day = 1,
}) async {
  final now = DateTime.now().toIso8601String();
  final date = '2026-05-${day.toString().padLeft(2, '0')}';
  final sessionId = await db.sessionsDao.insertSession(
    SessionsCompanion.insert(
      athleteId: athleteId,
      date: date,
      taskName: drift.Value('Session $day'),
      sport: const drift.Value('Running'),
      sessionType: const drift.Value('training'),
      intensityPercent: const drift.Value(80),
      intensitySource: const drift.Value('direct_percent_mas'),
      recoveryTimeMin: const drift.Value(10),
      recoveryWindowStartMin: const drift.Value(5),
      recoveryWindowEndMin: const drift.Value(10),
      rmssdExercise: const drift.Value(4),
      rmssdRecovery: const drift.Value(24),
      slopeRaw: drift.Value(slope),
      slopeInterpreted: drift.Value(slope),
      itlIndex: drift.Value(1 / slope),
      hrvInputMode: const drift.Value('direct_rmssd'),
      rmssdRecoverySource: const drift.Value('manual'),
      rmssdExerciseSource: const drift.Value('measured'),
      createdAt: now,
    ),
  );
  await db.sessionsDao.insertVariables([
    IntensityVariablesCompanion.insert(
      sessionId: sessionId,
      category: 'external',
      name: 'speed_kmh',
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
  ]);
  return sessionId;
}
