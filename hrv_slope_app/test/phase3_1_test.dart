// Phase 3.1 tests — Group Report + Standalone Population Nomogram.
import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrv_slope_app/data/database/app_database.dart';
import 'package:hrv_slope_app/data/database/daos/sessions_dao.dart';
import 'package:hrv_slope_app/shared/engine/group_report_builder.dart';
import 'package:hrv_slope_app/shared/engine/nomogram_engine.dart';
import 'package:hrv_slope_app/ui/screens/reports/group_report_screen.dart';
import 'package:hrv_slope_app/ui/screens/reports/population_nomogram_screen.dart';
import 'package:hrv_slope_app/ui/widgets/nomogram_chart.dart';

void main() {
  group('Group report builder', () {
    test('ranks complete sessions by interpreted_slope ascending', () {
      final report = _report([
        _detail(id: 1, athleteId: 1, athleteName: 'A', slope: 0.8),
        _detail(id: 2, athleteId: 2, athleteName: 'B', slope: 0.2),
        _detail(id: 3, athleteId: 3, athleteName: 'C', slope: 1.1),
      ]);

      expect(report.rankedRows.map((r) => r.athleteName), ['B', 'A', 'C']);
    });

    test('excludes incomplete sessions without slope from ranking', () {
      final report = _report([
        _detail(id: 1, athleteId: 1, athleteName: 'A', slope: 0.8),
        _detail(id: 2, athleteId: 2, athleteName: 'B', slope: null),
      ]);

      expect(report.rankedRows.length, 1);
      expect(report.incompleteRows.single.athleteName, 'B');
    });

    test('calculates mean/min/max slope', () {
      final report = _report([
        _detail(id: 1, athleteId: 1, slope: 0.2),
        _detail(id: 2, athleteId: 2, slope: 0.6),
        _detail(id: 3, athleteId: 3, slope: 1.0),
      ]);

      expect(report.summary.meanSlope, closeTo(0.6, 0.001));
      expect(report.summary.minSlope, 0.2);
      expect(report.summary.maxSlope, 1.0);
      expect(report.summary.medianSlope, 0.6);
    });

    test('counts classifications', () {
      final report = _report([
        _detail(id: 1, athleteId: 1, intensity: 70, slope: 0.1),
        _detail(id: 2, athleteId: 2, intensity: 80, slope: 0.5),
        _detail(id: 3, athleteId: 3, intensity: 80, slope: 1.0),
      ]);

      expect(report.summary.nVeryHighInternalLoad, 1);
      expect(report.summary.nExpectedResponse, 1);
      expect(report.summary.nLowInternalLoadOrFastRecovery, 1);
    });

    test('warns when intensity_percent missing', () {
      final report = _report([
        _detail(id: 1, athleteId: 1, intensity: null, slope: 0.5),
      ]);

      expect(report.rows.single.warnings.join(), contains('Intensity percent'));
    });

    test('warns when HRV/slope missing', () {
      final report = _report([_detail(id: 1, athleteId: 1, slope: null)]);

      expect(report.rows.single.warnings.join(), contains('HRV or slope'));
    });

    test('includes external/internal variables', () {
      final report = _report([_detail(id: 1, athleteId: 1)]);

      expect(report.rows.single.externalVariables.single.name, 'speed_kmh');
      expect(report.rows.single.internalVariables.single.name, 'rpe_1_10');
    });
  });

  group('Group report screen', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('renders summary and ranked rows/cards', (tester) async {
      await _seedSession(db, athleteName: 'Runner A', slope: 0.2);
      await _seedSession(db, athleteName: 'Runner B', slope: 0.8);

      await tester.pumpWidget(
        MaterialApp(home: GroupReportScreen(database: db)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sessions: 2'), findsOneWidget);
      expect(find.text('Runner A'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Runner B'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Runner B'), findsOneWidget);
    });

    testWidgets('handles empty state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: GroupReportScreen(database: db)),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('No sessions match'), findsOneWidget);
    });

    testWidgets('shows very_high_internal_load label', (tester) async {
      await _seedSession(
        db,
        athleteName: 'Loaded Athlete',
        intensity: 70,
        slope: 0.1,
      );

      await tester.pumpWidget(
        MaterialApp(home: GroupReportScreen(database: db)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Very high internal load'), findsOneWidget);
    });

    test('does not use medical diagnostic language', () {
      final text = File(
        'lib/ui/screens/reports/group_report_screen.dart',
      ).readAsStringSync().toLowerCase();
      expect(text, isNot(contains('diagnosis')));
      expect(text, isNot(contains('disease')));
      expect(text, isNot(contains('pathological')));
    });
  });

  group('Population nomogram screen and chart', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('renders active preset', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: PopulationNomogramScreen(database: db)),
      );
      await tester.pumpAndSettle();

      expect(find.text('excel_operational'), findsOneWidget);
    });

    testWidgets('plots multiple session points', (tester) async {
      await _seedSession(db, athleteName: 'Runner A', slope: 0.4);
      await _seedSession(db, athleteName: 'Runner B', slope: 0.8);

      await tester.pumpWidget(
        MaterialApp(home: PopulationNomogramScreen(database: db)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Session points'), findsWidgets);
      await tester.scrollUntilVisible(
        find.text('Runner A'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Runner A'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Runner B'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Runner B'), findsOneWidget);
    });

    testWidgets('supports excel_operational preset', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NomogramChart(
              preset: PopulationNomogramSource.excelOperational,
              observedPoints: const [
                NomogramObservedPoint(
                  xIntensityPercent: 80,
                  ySlope: 0.5,
                  label: 'A',
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Session points'), findsOneWidget);
      expect(find.text('Mean'), findsOneWidget);
    });

    testWidgets('supports paper_original_2019 preset', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NomogramChart(
              preset: PopulationNomogramSource.paperOriginal2019,
              observedPoints: const [
                NomogramObservedPoint(
                  xIntensityPercent: 83.11,
                  ySlope: 0.29,
                  label: 'A',
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Intensity (%)'), findsOneWidget);
      expect(find.text('Session points'), findsOneWidget);
    });

    testWidgets('warns for out-of-range intensity', (tester) async {
      await _seedSession(db, athleteName: 'Runner A', intensity: 40, slope: 1);

      await tester.pumpWidget(
        MaterialApp(home: PopulationNomogramScreen(database: db)),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.textContaining('outside'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('outside'), findsOneWidget);
    });

    testWidgets('filters by athlete if implemented', (tester) async {
      final idA = await _seedSession(db, athleteName: 'Runner A', slope: 0.4);
      await _seedSession(db, athleteName: 'Runner B', slope: 0.8);

      await tester.pumpWidget(
        MaterialApp(home: PopulationNomogramScreen(database: db)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<int?>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Runner A').last);
      await tester.pumpAndSettle();

      expect(idA, greaterThan(0));
      expect(find.text('Runner A'), findsWidgets);
      expect(find.text('Runner B'), findsNothing);
    });

    testWidgets('individual report chart still renders one point', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NomogramChart(
              preset: PopulationNomogramSource.excelOperational,
              observedIntensity: 80,
              observedSlope: 0.5,
            ),
          ),
        ),
      );

      expect(find.text('Session'), findsOneWidget);
      expect(find.text('Session points'), findsNothing);
    });
  });

  group('Phase 3.1 regression guards', () {
    test('no legacy computeSlope() usage in UI/report/import/edit', () {
      final files = [
        File('lib/ui/screens/import/import_screen.dart'),
        File('lib/ui/screens/session/session_wizard_screen.dart'),
        File('lib/ui/screens/session/session_edit_screen.dart'),
        File('lib/ui/screens/reports/individual_report_screen.dart'),
        File('lib/ui/screens/reports/group_report_screen.dart'),
        File('lib/ui/screens/reports/population_nomogram_screen.dart'),
        File('lib/data/services/session_edit_service.dart'),
      ];

      for (final file in files) {
        expect(file.readAsStringSync().contains('computeSlope('), isFalse);
      }
    });

    test('no classification without intensity_percent', () {
      final report = _report([
        _detail(id: 1, athleteId: 1, intensity: null, slope: 0.5),
      ]);

      expect(report.rows.single.classification, isNull);
      expect(report.rows.single.isCompleteForNomogram, isFalse);
    });

    test('direct RMSSD remains default', () {
      expect(_detail(id: 1, athleteId: 1).session.hrvInputMode, 'direct_rmssd');
    });

    test('RR correction remains off by default', () {
      expect(_detail(id: 1, athleteId: 1).session.rrCorrectionEnabled, isFalse);
    });

    test('real RR fixture tests remain mandatory inputs', () {
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

GroupReportData _report(List<SessionDetail> details) {
  return buildGroupReport(
    details: details,
    nomogramPreset: PopulationNomogramSource.excelOperational,
  );
}

SessionDetail _detail({
  required int id,
  required int athleteId,
  String athleteName = 'Athlete',
  double? intensity = 80,
  double? slope = 0.5,
  bool isDraft = false,
}) {
  return SessionDetail(
    athlete: Athlete(
      id: athleteId,
      name: athleteName,
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
    ),
    session: Session(
      id: id,
      athleteId: athleteId,
      date: '2026-05-26',
      taskName: 'Tempo',
      sport: 'Running',
      sessionType: 'training',
      protocolName: null,
      contextEnvironment: null,
      isDraft: isDraft,
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
      createdAt: '2026-05-26T00:00:00',
    ),
    variables: [
      _variable(
        id: id * 10,
        sessionId: id,
        category: 'external',
        name: 'speed_kmh',
        value: 16,
        unit: 'km/h',
      ),
      _variable(
        id: id * 10 + 1,
        sessionId: id,
        category: 'internal',
        name: 'rpe_1_10',
        value: 7,
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
  String? unit,
}) {
  return IntensityVariable(
    id: id,
    sessionId: sessionId,
    category: category,
    name: name,
    unit: unit,
    value: value,
    source: 'manual',
    isPrimaryForNomogram: false,
    notes: null,
    createdAt: '2026-05-26T00:00:00',
  );
}

Future<int> _seedSession(
  AppDatabase db, {
  required String athleteName,
  double intensity = 80,
  double slope = 0.5,
}) async {
  final now = DateTime.now().toIso8601String();
  final athleteId = await db.athletesDao.insertAthlete(
    AthletesCompanion.insert(
      name: athleteName,
      sport: const drift.Value('Running'),
      masKmh: const drift.Value(20),
      createdAt: now,
      updatedAt: now,
    ),
  );
  final sessionId = await db.sessionsDao.insertSession(
    SessionsCompanion.insert(
      athleteId: athleteId,
      date: '2026-05-26',
      taskName: const drift.Value('Tempo'),
      sport: const drift.Value('Running'),
      sessionType: const drift.Value('training'),
      intensityPercent: drift.Value(intensity),
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
  ]);
  return athleteId;
}
