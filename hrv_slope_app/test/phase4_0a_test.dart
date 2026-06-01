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

    test('filter by sport', () {
      final series = _series([
        _detail(id: 1, sport: 'Running'),
        _detail(id: 2, sport: 'Cycling'),
      ], filter: const LongitudinalDashboardFilter(sports: {'Running'}));

      expect(series.points.map((p) => p.sport), ['Running']);
    });

    test('filter by session task/name', () {
      final series = _series([
        _detail(id: 1, taskName: 'HIIT'),
        _detail(id: 2, taskName: 'Tempo'),
      ], filter: const LongitudinalDashboardFilter(sessionTasks: {'HIIT'}));

      expect(series.points.single.taskName, 'HIIT');
    });

    test('filter by session type', () {
      final series = _series([
        _detail(id: 1, sessionType: 'training'),
        _detail(id: 2, sessionType: 'test'),
      ], filter: const LongitudinalDashboardFilter(sessionTypes: {'test'}));

      expect(series.points.single.sessionType, 'test');
    });

    test('filter by protocol name', () {
      final series = _series([
        _detail(id: 1, protocolName: '5-10'),
        _detail(id: 2, protocolName: '10-15'),
      ], filter: const LongitudinalDashboardFilter(protocolNames: {'10-15'}));

      expect(series.points.single.protocolName, '10-15');
    });

    test('filter by context/environment', () {
      final series = _series(
        [
          _detail(id: 1, contextEnvironment: 'Indoor'),
          _detail(id: 2, contextEnvironment: 'Outdoor'),
        ],
        filter: const LongitudinalDashboardFilter(
          contextEnvironmentTags: {'Outdoor'},
        ),
      );

      expect(series.points.single.contextEnvironment, 'Outdoor');
    });

    test('filter by context tag split with semicolon', () {
      final series = _series(
        [
          _detail(id: 1, contextEnvironment: 'heat; humidity; indoor'),
          _detail(id: 2, contextEnvironment: 'cold; outdoor'),
        ],
        filter: const LongitudinalDashboardFilter(
          contextEnvironmentTags: {'heat'},
        ),
      );

      expect(series.points.single.sessionId, 1);
    });

    test('filter by context tag split with pipe preserves spaced tag', () {
      final series = _series(
        [
          _detail(id: 1, contextEnvironment: 'sea level | high humidity'),
          _detail(id: 2, contextEnvironment: 'altitude | dry'),
        ],
        filter: const LongitudinalDashboardFilter(
          contextEnvironmentTags: {'high humidity'},
        ),
      );

      expect(series.points.single.sessionId, 1);
    });

    test('filter by complete context value still works', () {
      final series = _series(
        [
          _detail(id: 1, contextEnvironment: 'sea level | high humidity'),
          _detail(id: 2, contextEnvironment: 'altitude | dry'),
        ],
        filter: const LongitudinalDashboardFilter(
          contextEnvironmentTags: {'sea level | high humidity'},
        ),
      );

      expect(series.points.single.sessionId, 1);
    });

    test('dateTo includes ISO datetime on same calendar day', () {
      final series = _series([
        _detail(id: 1, date: '2026-05-27T10:00:00'),
        _detail(id: 2, date: '2026-05-28T10:00:00'),
      ], filter: const LongitudinalDashboardFilter(dateTo: '2026-05-27'));

      expect(series.points.single.sessionId, 1);
    });

    test('dateFrom and dateTo work with YYYY-MM-DD dates', () {
      final series = _series(
        [
          _detail(id: 1, date: '2026-05-26'),
          _detail(id: 2, date: '2026-05-27'),
          _detail(id: 3, date: '2026-05-28'),
        ],
        filter: const LongitudinalDashboardFilter(
          dateFrom: '2026-05-27',
          dateTo: '2026-05-27',
        ),
      );

      expect(series.points.single.sessionId, 2);
    });

    test('filter by intensity source', () {
      final series = _series(
        [
          _detail(id: 1, intensitySource: 'direct_percent_mas'),
          _detail(id: 2, intensitySource: 'internal_rpe_1_10'),
        ],
        filter: const LongitudinalDashboardFilter(
          intensitySourcesForSlope: {'Internal'},
        ),
      );

      expect(series.points.single.intensitySourceForSlope, 'Internal');
    });

    test('filter by RPE range', () {
      final series = _series([
        _detail(id: 1, rpe: 4),
        _detail(id: 2, rpe: 8),
      ], filter: const LongitudinalDashboardFilter(rpeMin: 7, rpeMax: 9));

      expect(series.points.single.rpe, 8);
    });

    test('extracts session_rpe_1_10 alias as longitudinal RPE', () {
      final series = _series([
        _detail(id: 1, rpe: 6, rpeVariableName: 'session_rpe_1_10'),
      ]);

      expect(series.points.single.rpe, 6);
    });

    test('filter by fatigue range', () {
      final series = _series(
        [_detail(id: 1, fatigue: 3), _detail(id: 2, fatigue: 7)],
        filter: const LongitudinalDashboardFilter(fatigueMin: 6, fatigueMax: 8),
      );

      expect(series.points.single.fatigue, 7);
    });

    test('filter by slope range', () {
      final series = _series([
        _detail(id: 1, slope: 0.4),
        _detail(id: 2, slope: 1.2),
      ], filter: const LongitudinalDashboardFilter(slopeMin: 1));

      expect(series.points.single.interpretedSlope, 1.2);
    });

    test('combined filter', () {
      final series = _series(
        [
          _detail(id: 1, sport: 'Running', rpe: 8, slope: 1.1),
          _detail(id: 2, sport: 'Running', rpe: 4, slope: 1.2),
          _detail(id: 3, sport: 'Cycling', rpe: 8, slope: 1.3),
        ],
        filter: const LongitudinalDashboardFilter(
          sports: {'Running'},
          rpeMin: 7,
          slopeMin: 1,
        ),
      );

      expect(series.points.single.sessionId, 1);
    });

    test('filter can return no results', () {
      final series = _series([
        _detail(id: 1, sport: 'Running'),
      ], filter: const LongitudinalDashboardFilter(sports: {'Swimming'}));

      expect(series.points, isEmpty);
      expect(series.excludedPoints, hasLength(1));
    });

    test('activeFilterCount and activeFilterLabels', () {
      const filter = LongitudinalDashboardFilter(
        sports: {'Running'},
        rpeMin: 7,
        comparableSessionsOnly: true,
      );

      expect(filter.activeFilterCount, 3);
      expect(filter.activeFilterLabels(), contains('Sport: Running'));
      expect(filter.activeFilterLabels(), contains('Comparable sessions only'));
    });

    test('comparable sessions mode uses latest included session', () {
      final series = _series(
        [
          _detail(id: 1, taskName: 'Tempo', intensity: 70, rpe: 6),
          _detail(id: 2, taskName: 'HIIT', intensity: 90, rpe: 9),
          _detail(id: 3, taskName: 'Tempo', intensity: 78, rpe: 7),
        ],
        filter: const LongitudinalDashboardFilter(comparableSessionsOnly: true),
      );

      expect(series.points.map((p) => p.sessionId), [1, 3]);
      expect(series.comparableIncludedCount, 2);
      expect(series.comparableTotalCount, 3);
    });

    test('data completeness counts filtered sessions', () {
      final series = _series([
        _detail(id: 1, intensitySource: 'direct_percent_mas', fatigue: 4),
        _detail(id: 2, intensitySource: 'internal_rpe_1_10', slope: null),
      ]);

      expect(series.completeness.includedSessions, 2);
      expect(series.completeness.totalSessions, 2);
      expect(series.completeness.withExternalIntensity, 1);
      expect(series.completeness.withInternalFallback, 1);
      expect(series.completeness.withRpe, 2);
      expect(series.completeness.withFatigue, 1);
      expect(series.completeness.missingKeyData, 1);
    });

    test('tooltip data model includes session metadata', () {
      final series = _series([
        _detail(
          id: 1,
          taskName: 'Tempo',
          protocolName: '5-10',
          contextEnvironment: 'Indoor',
          fatigue: 5,
          notes: 'Good session',
        ),
      ]);
      final point = series.points.single;

      expect(point.protocolName, '5-10');
      expect(point.contextEnvironment, 'Indoor');
      expect(point.notes, contains('Good session'));
    });

    test('dashboard without filters shows all sessions', () {
      final series = _series([_detail(id: 1), _detail(id: 2)]);

      expect(series.points, hasLength(2));
      expect(series.filter.isEmpty, isTrue);
    });

    test('filter option values are alphabetically sorted', () {
      final series = _series([
        _detail(id: 1, sport: 'Cycling'),
        _detail(id: 2, sport: 'Running'),
        _detail(id: 3, sport: 'Athletics'),
      ]);

      expect(series.filterOptions.sports.toList(), [
        'Athletics',
        'Cycling',
        'Running',
      ]);
    });
  });

  group('Longitudinal chart scaling', () {
    test('negative residual values produce a negative y-axis minimum', () {
      final scale = resolveLongitudinalYAxisScale([-0.7, -0.2, 0.3]);

      expect(scale.minY, lessThan(-0.7));
      expect(scale.maxY, greaterThan(0.3));
    });

    test('positive values can keep zero as y-axis minimum', () {
      final scale = resolveLongitudinalYAxisScale([0.4, 1.2]);

      expect(scale.minY, 0);
      expect(scale.maxY, greaterThan(1.2));
    });

    test('primary intensity overlay stays 0-100 when max is <= 100', () {
      final max = resolvePrimaryIntensityOverlayMax([80, 100]);

      expect(max, 100);
      expect(resolvePrimaryIntensityOverlayInterval(max), 25);
    });

    test('primary intensity overlay expands above 100 with clean ticks', () {
      final max = resolvePrimaryIntensityOverlayMax([80, 110, 120]);

      expect(max, 125);
      expect(resolvePrimaryIntensityOverlayInterval(max), 25);
    });
  });

  group('Longitudinal filter UI labels', () {
    test('maps direct_percent_mas to %MAS', () {
      expect(longitudinalIntensityMetricLabel('direct_percent_mas'), '%MAS');
    });

    test('maps rpe_1_10 to RPE 1-10', () {
      expect(longitudinalIntensityMetricLabel('rpe_1_10'), 'RPE 1-10');
    });

    test('maps session_rpe_1_10 to Session RPE 1-10', () {
      expect(
        longitudinalIntensityMetricLabel('session_rpe_1_10'),
        'Session RPE 1-10',
      );
    });

    test('humanizes unknown metric names without raw snake_case', () {
      final label = longitudinalIntensityMetricLabel('unknown_metric_name');

      expect(label, 'Unknown Metric Name');
      expect(label, isNot(contains('_')));
    });

    test('maps intensity source labels', () {
      expect(longitudinalIntensitySourceLabel('External'), 'External load');
      expect(longitudinalIntensitySourceLabel('Internal'), 'Internal load');
      expect(longitudinalIntensitySourceLabel('Unknown'), 'Unknown');
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
      await _dragUntilVisible(tester, find.text('Slope Trend'));
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
      expect(find.textContaining('Line: session trend'), findsOneWidget);
    });

    testWidgets('empty state when no complete sessions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AthleteLongitudinalScreen(database: db, athleteId: athleteId),
        ),
      );
      await tester.pumpAndSettle();

      await _dragUntilVisible(
        tester,
        find.textContaining('Not enough complete sessions'),
      );
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
      await _dragUntilVisible(tester, find.text('Open report'));

      expect(find.text('Open report'), findsOneWidget);
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

LongitudinalSeries _series(
  List<SessionDetail> details, {
  LongitudinalDashboardFilter filter = const LongitudinalDashboardFilter(),
}) {
  return buildLongitudinalSeries(
    athlete: _athlete(),
    details: details,
    filter: filter,
  );
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
  String? taskName,
  String sport = 'Running',
  String sessionType = 'training',
  String? protocolName,
  String? contextEnvironment,
  double? intensity = 80,
  String? intensitySource,
  double? slope = 0.5,
  double? rpe = 7,
  String rpeVariableName = 'rpe_1_10',
  double? fatigue,
  double? srpe,
  double? trimp,
  String? notes,
  String externalName = 'speed_kmh',
}) {
  final sessionDate = date ?? '2026-05-${id.toString().padLeft(2, '0')}';
  return SessionDetail(
    athlete: _athlete(),
    session: Session(
      id: id,
      athleteId: 1,
      date: sessionDate,
      taskName: taskName ?? 'Session $id',
      sport: sport,
      sessionType: sessionType,
      protocolName: protocolName,
      contextEnvironment: contextEnvironment,
      isDraft: false,
      intensityPercent: intensity,
      intensitySource: intensity == null
          ? null
          : (intensitySource ?? 'direct_percent_mas'),
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
      notes: notes,
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
          name: rpeVariableName,
          value: rpe,
        ),
      if (fatigue != null)
        _variable(
          id: id * 10 + 4,
          sessionId: id,
          category: 'internal',
          name: 'subjective_fatigue_1_10',
          value: fatigue,
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

Future<void> _dragUntilVisible(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 8; i++) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.drag(find.byType(ListView), const Offset(0, -360));
    await tester.pumpAndSettle();
  }
}
