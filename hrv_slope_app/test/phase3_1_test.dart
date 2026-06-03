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

    test('filters by date athlete sport task type protocol and context', () {
      final report = buildGroupReport(
        details: [
          _detail(
            id: 1,
            athleteId: 1,
            athleteName: 'Runner A',
            sport: 'Running',
            date: '2026-05-01',
            taskName: 'RSA',
            sessionType: 'HIIT',
            protocolName: '5-10',
            contextEnvironment: 'Indoor; high humidity',
          ),
          _detail(
            id: 2,
            athleteId: 2,
            athleteName: 'Runner B',
            sport: 'Cycling',
            date: '2026-05-03',
            taskName: 'Tempo',
            sessionType: 'Training',
            protocolName: '10-15',
            contextEnvironment: 'Outdoor | heat',
          ),
        ],
        nomogramPreset: PopulationNomogramSource.excelOperational,
        filter: const GroupReportFilter(
          dateFrom: '2026-05-01',
          dateTo: '2026-05-02',
          athleteNames: {'Runner A'},
          sports: {'Running'},
          sessionTasks: {'RSA'},
          sessionTypes: {'HIIT'},
          protocolNames: {'5-10'},
          contextEnvironmentTags: {'high humidity'},
        ),
      );

      expect(report.rows.map((row) => row.athleteName), ['Runner A']);
      expect(report.activeFilterLabels, contains('Athlete: Runner A'));
      expect(report.filterOptions.contextEnvironmentTags, contains('Indoor'));
      expect(
        report.filterOptions.contextEnvironmentTags,
        contains('high humidity'),
      );
    });

    test(
      'advanced filters include intensity RPE fatigue slope ITL response notes',
      () {
        final report = buildGroupReport(
          details: [
            _detail(
              id: 1,
              athleteId: 1,
              athleteName: 'Runner A',
              intensity: 80,
              slope: 1.0,
              rpe: 6,
              fatigue: 3,
              notes: 'slept well',
            ),
            _detail(
              id: 2,
              athleteId: 2,
              athleteName: 'Runner B',
              intensity: 60,
              slope: 0.1,
              rpe: 9,
              fatigue: 8,
              notes: 'travel day',
            ),
          ],
          nomogramPreset: PopulationNomogramSource.excelOperational,
          filter: const GroupReportFilter(
            intensitySourcesForSlope: {'External'},
            intensityMetricNames: {'direct_percent_mas'},
            primaryIntensityMin: 70,
            primaryIntensityMax: 90,
            rpeMin: 5,
            rpeMax: 7,
            fatigueMin: 1,
            fatigueMax: 4,
            slopeMin: 0.8,
            slopeMax: 1.2,
            itlMin: 0.8,
            itlMax: 1.2,
            recoveryResponses: {'Favorable'},
            notesTextSearch: 'slept',
          ),
        );

        expect(report.rows.map((row) => row.athleteName), ['Runner A']);
        expect(report.rows.single.rpe, 6);
        expect(report.rows.single.fatigue, 3);
        expect(report.activeFilterLabels, contains('Response: Favorable'));
      },
    );
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

      await tester.scrollUntilVisible(
        find.text('Sessions: 2'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Sessions: 2'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Runner A'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
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

      await tester.scrollUntilVisible(
        find.textContaining('No sessions match'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('No sessions match'), findsOneWidget);
    });

    testWidgets('shows lower-than-expected recovery response label', (
      tester,
    ) async {
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

      await tester.scrollUntilVisible(
        find.text('Lower-than-expected recovery response'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.text('Lower-than-expected recovery response'),
        findsOneWidget,
      );
    });

    testWidgets('date picker opens and invalid date range is controlled', (
      tester,
    ) async {
      await _seedSession(db, athleteName: 'Runner A', slope: 0.5);

      await tester.pumpWidget(
        MaterialApp(home: GroupReportScreen(database: db)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Pick date').first);
      await tester.pumpAndSettle();
      expect(find.byType(CalendarDatePicker), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'From date'),
        '2026-05-30',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'To date'),
        '2026-05-01',
      );
      await tester.tap(find.text('Apply filters').first);
      await tester.pumpAndSettle();

      expect(
        find.text('From date must be on or before To date.'),
        findsOneWidget,
      );
    });

    testWidgets('categorical filters are compact multiselect dropdowns', (
      tester,
    ) async {
      await _seedSession(
        db,
        athleteName: 'Runner A',
        sport: 'Running',
        taskName: 'RSA',
        sessionType: 'HIIT',
        slope: 0.4,
      );
      await _seedSession(
        db,
        athleteName: 'Runner B',
        sport: 'Cycling',
        taskName: 'Tempo',
        sessionType: 'Training',
        slope: 0.8,
      );

      await tester.pumpWidget(
        MaterialApp(home: GroupReportScreen(database: db)),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(_filterSummaryKey('Athlete')), findsOneWidget);
      expect(_filterSummary(tester, 'Athlete'), 'Any');
      expect(_filterSummary(tester, 'Session task/name'), 'Any');
      expect(find.widgetWithText(CheckboxListTile, 'RSA'), findsNothing);

      await tester.tap(find.text('Session task/name'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(CheckboxListTile, 'RSA'), findsOneWidget);
      expect(find.widgetWithText(CheckboxListTile, 'Tempo'), findsOneWidget);

      await _tapVisible(tester, find.widgetWithText(CheckboxListTile, 'RSA'));
      expect(_filterSummary(tester, 'Session task/name'), 'RSA');

      await _tapVisible(tester, find.widgetWithText(CheckboxListTile, 'RSA'));
      expect(_filterSummary(tester, 'Session task/name'), 'Any');

      await _tapVisible(tester, find.widgetWithText(CheckboxListTile, 'RSA'));
      expect(_filterSummary(tester, 'Session task/name'), 'RSA');

      await _tapVisible(tester, find.widgetWithText(CheckboxListTile, 'Tempo'));
      expect(_filterSummary(tester, 'Session task/name'), '2 selected');
    });

    testWidgets('applies and clears athlete sport task filters', (
      tester,
    ) async {
      await _seedSession(
        db,
        athleteName: 'Runner A',
        sport: 'Running',
        taskName: 'RSA',
        sessionType: 'HIIT',
        slope: 0.4,
      );
      await _seedSession(
        db,
        athleteName: 'Runner B',
        sport: 'Cycling',
        taskName: 'Tempo',
        sessionType: 'Training',
        slope: 0.8,
      );

      await tester.pumpWidget(
        MaterialApp(home: GroupReportScreen(database: db)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Athlete'));
      await tester.pumpAndSettle();
      await _tapVisible(
        tester,
        find.widgetWithText(CheckboxListTile, 'Runner A'),
      );
      expect(_filterSummary(tester, 'Athlete'), 'Runner A');

      await _tapVisible(tester, find.text('Sport'));
      await _tapVisible(
        tester,
        find.widgetWithText(CheckboxListTile, 'Running'),
      );
      await tester.pumpAndSettle();
      expect(_filterSummary(tester, 'Sport'), 'Running');

      await _tapVisible(tester, find.text('Apply filters').first);

      await tester.scrollUntilVisible(
        find.text('Sessions: 1'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Sessions: 1'), findsOneWidget);
      expect(find.text('Runner A'), findsWidgets);
      expect(find.text('Athlete: Runner A'), findsOneWidget);

      await _tapVisible(tester, find.text('Clear filters').first);
      await tester.ensureVisible(find.byKey(_filterSummaryKey('Athlete')));
      await tester.pumpAndSettle();
      expect(_filterSummary(tester, 'Athlete'), 'Any');
      expect(_filterSummary(tester, 'Sport'), 'Any');
      await tester.scrollUntilVisible(
        find.text('Runner B'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Runner B'), findsOneWidget);
    });

    testWidgets('advanced filters remain collapsed and usable', (tester) async {
      await _seedSession(db, athleteName: 'Runner A', slope: 0.5);

      await tester.pumpWidget(
        MaterialApp(home: GroupReportScreen(database: db)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Advanced filters'), findsOneWidget);
      expect(find.text('Intensity source for slope'), findsNothing);

      await _tapVisible(tester, find.text('Advanced filters'));

      expect(find.text('Intensity source for slope'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'External'), findsOneWidget);
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

    testWidgets('supports slope_Orellana_19 preset', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NomogramChart(
              preset: PopulationNomogramSource.slopeOrellana19,
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
  String sport = 'Running',
  String date = '2026-05-26',
  String taskName = 'Tempo',
  String sessionType = 'training',
  String? protocolName,
  String? contextEnvironment,
  double? intensity = 80,
  double? slope = 0.5,
  double rpe = 7,
  double? fatigue,
  String? notes,
  bool isDraft = false,
}) {
  return SessionDetail(
    athlete: Athlete(
      id: athleteId,
      name: athleteName,
      sport: sport,
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
      date: date,
      taskName: taskName,
      sport: sport,
      sessionType: sessionType,
      protocolName: protocolName,
      contextEnvironment: contextEnvironment,
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
      notes: notes,
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
        value: rpe,
      ),
      if (fatigue != null)
        _variable(
          id: id * 10 + 2,
          sessionId: id,
          category: 'internal',
          name: 'subjective_fatigue_1_10',
          value: fatigue,
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

Key _filterSummaryKey(String label) {
  return Key('group-report-filter-$label-summary');
}

String? _filterSummary(WidgetTester tester, String label) {
  final widget = tester.widget<Text>(find.byKey(_filterSummaryKey(label)));
  return widget.data;
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<int> _seedSession(
  AppDatabase db, {
  required String athleteName,
  String sport = 'Running',
  String taskName = 'Tempo',
  String sessionType = 'training',
  double intensity = 80,
  double slope = 0.5,
}) async {
  final now = DateTime.now().toIso8601String();
  final athleteId = await db.athletesDao.insertAthlete(
    AthletesCompanion.insert(
      name: athleteName,
      sport: drift.Value(sport),
      masKmh: const drift.Value(20),
      createdAt: now,
      updatedAt: now,
    ),
  );
  final sessionId = await db.sessionsDao.insertSession(
    SessionsCompanion.insert(
      athleteId: athleteId,
      date: '2026-05-26',
      taskName: drift.Value(taskName),
      sport: drift.Value(sport),
      sessionType: drift.Value(sessionType),
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
