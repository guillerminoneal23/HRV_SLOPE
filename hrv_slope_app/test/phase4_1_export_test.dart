// Phase 4.1 tests — Export MVP: CSV first.
import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrv_slope_app/data/database/app_database.dart'
    hide NomogramModel;
import 'package:hrv_slope_app/data/export/csv_export_service.dart';
import 'package:hrv_slope_app/shared/engine/group_report_builder.dart';
import 'package:hrv_slope_app/shared/engine/individual_nomogram_builder.dart';
import 'package:hrv_slope_app/shared/engine/individual_report_builder.dart';
import 'package:hrv_slope_app/shared/engine/longitudinal_builder.dart';
import 'package:hrv_slope_app/shared/engine/nomogram_engine.dart';
import 'package:hrv_slope_app/ui/screens/longitudinal/athlete_longitudinal_screen.dart';
import 'package:hrv_slope_app/ui/screens/nomogram/individual_nomogram_screen.dart';
import 'package:hrv_slope_app/ui/screens/reports/group_report_screen.dart';
import 'package:hrv_slope_app/ui/screens/reports/individual_report_screen.dart';
import 'package:hrv_slope_app/ui/screens/reports/population_nomogram_screen.dart';

void main() {
  group('CSV core', () {
    test('escapes commas', () {
      expect(csvField('Runner, A'), '"Runner, A"');
    });

    test('escapes quotes', () {
      expect(csvField('Runner "A"'), '"Runner ""A"""');
    });

    test('escapes newlines', () {
      expect(csvField('line 1\nline 2'), '"line 1\nline 2"');
    });

    test('keeps null values blank', () {
      expect(
        buildCsv(
          ['a', 'b'],
          [
            [1, null],
          ],
        ),
        'a,b\n1,\n',
      );
    });

    test('formats numeric values without noisy precision', () {
      expect(csvField(1.230000), '1.23');
      expect(csvField(4.0), '4');
    });

    test('keeps UTF-8 and quotes semicolon fields', () {
      expect(csvField('VALORACIÓN VO₂max; test'), '"VALORACIÓN VO₂max; test"');
    });
  });

  group('Individual report export', () {
    test('contains identity, HRV, slope, fallback, bands, and warnings', () {
      final export = exportIndividualReportCsv(
        _individualReport(),
        athleteId: 7,
        sessionId: 11,
      );

      expect(export.content, contains('athlete_id'));
      expect(export.content, contains('RMSSD Test'));
      expect(export.content, contains('slope_raw'));
      expect(export.content, contains('slope_interpreted'));
      expect(export.content, contains('rmssd_exercise_is_default'));
      expect(export.content, contains('intensity_source_for_slope'));
      expect(export.content, contains('primary_intensity_metric'));
      expect(export.content, contains('External'));
      expect(export.content, contains('speed_kmh_div_mas'));
      expect(export.content, contains('expected_lower'));
      expect(export.content, contains('Check context'));
    });

    test('uses slope_Orellana_19 preset name in new CSV output', () {
      final export = exportIndividualReportCsv(
        _individualReport(presetName: 'slope_Orellana_19'),
      );

      expect(export.content, contains('slope_Orellana_19'));
      expect(export.content, isNot(contains('paper_original_2019')));
    });
  });

  group('Group report export', () {
    test('exports ranked rows and incomplete rows', () {
      final export = exportGroupReportRowsCsv(_groupReport());

      expect(export.content, contains('rank,athlete_id'));
      expect(export.content, contains('Runner B'));
      expect(export.content, contains('Missing slope'));
    });

    test('exports summary stats and classification counts', () {
      final export = exportGroupReportSummaryCsv(_groupReport());

      expect(export.content, contains('n_sessions'));
      expect(export.content, contains('n_high_or_moderate_internal_load'));
      expect(export.content, contains('0.45'));
    });
  });

  group('Longitudinal export', () {
    test(
      'exports sorted sessions, load variables, residuals, and rolling data',
      () {
        final export = exportLongitudinalCsv(_longitudinalSeries());

        expect(export.content, contains('slope_rolling_7'));
        expect(export.content, contains('rpe'));
        expect(export.content, contains('srpe'));
        expect(export.content, contains('trimp'));
        expect(export.content, contains('player_load'));
        expect(export.content, contains('intensity_source_for_slope'));
        expect(export.content, contains('External'));
        expect(export.content, contains('2026-05-01'));
      },
    );

    test('exports fatigue flags as a separate dataset', () {
      final export = exportLongitudinalFatigueFlagsCsv(_longitudinalSeries());

      expect(export.content, contains('three_negative_residuals'));
      expect(export.content, contains('3 consecutive residuals below -0.5'));
    });

    test(
      'exports filtered rows, filter summary, and intensity source fields',
      () {
        const point = LongitudinalPoint(
          sessionId: 1,
          date: '2026-05-01',
          taskName: 'Tempo',
          sport: 'Running',
          sessionType: 'training',
          protocolName: '5-10',
          contextEnvironment: 'Indoor',
          intensityPercent: 80,
          intensitySourceForSlope: 'External',
          primaryIntensityMetric: 'direct_percent_mas',
          primaryIntensityValue: 80,
          rawSlope: 0.5,
          interpretedSlope: 0.5,
          itlIndex: 2,
          rpe: 7,
          fatigue: 4,
          notes: 'Filtered note',
          nomogramReference: LongitudinalNomogramReferencePoint(
            sessionId: 1,
            date: '2026-05-01',
            primaryIntensityValue: 80,
            primaryIntensityMetric: 'direct_percent_mas',
            intensitySourceForSlope: 'External',
            observedSlope: 0.5,
            observedItl: 2,
            referenceSlope: 0.4,
            lowerSlopeThreshold: 0.2,
            upperSlopeThreshold: 0.8,
            referenceItl: 2.5,
            lowerItlThreshold: 1.25,
            upperItlThreshold: 5,
            zone: LongitudinalRecoveryZone.normal,
            source: 'slope_Orellana_19',
          ),
        );
        const series = LongitudinalSeries(
          athleteId: 1,
          athleteName: 'Runner',
          points: [point],
          allPoints: [
            point,
            LongitudinalPoint(
              sessionId: 2,
              date: '2026-05-02',
              taskName: 'Bike',
              sport: 'Cycling',
              sessionType: 'training',
              rawSlope: 0.4,
              interpretedSlope: 0.4,
            ),
          ],
          excludedPoints: [
            LongitudinalPoint(
              sessionId: 2,
              date: '2026-05-02',
              taskName: 'Bike',
              sport: 'Cycling',
              sessionType: 'training',
              rawSlope: 0.4,
              interpretedSlope: 0.4,
            ),
          ],
          filter: LongitudinalDashboardFilter(sports: {'Running'}),
          activeFilterLabels: ['Sport: Running'],
          slopeRolling7: [0.5],
          slopeRolling14: [0.5],
          slopeRolling28: [0.5],
          itlRolling7: [2],
          itlRolling14: [2],
          itlRolling28: [2],
          fatigueFlags: [],
          summary: LongitudinalSummary(
            nSessions: 1,
            nComplete: 1,
            latestSlope: 0.5,
            latestItl: 2,
            meanSlope: 0.5,
            minSlope: 0.5,
            maxSlope: 0.5,
            meanItl: 2,
            trendDirection: LongitudinalTrendDirection.insufficientData,
          ),
        );

        final export = exportLongitudinalCsv(series);

        expect(export.content, contains('filter_summary'));
        expect(export.content, contains('Sport: Running'));
        expect(export.content, contains('intensity_source_for_slope'));
        expect(export.content, contains('primary_intensity_value'));
        expect(export.content, contains('primary_intensity_metric'));
        expect(export.content, contains('nomogram_reference_source'));
        expect(export.content, contains('slope_orellana_19_reference_slope'));
        expect(export.content, contains('recovery_zone'));
        expect(export.content, contains('rpe_slope_response_index'));
        expect(export.content, contains('rpe_slope_quadrant'));
        expect(export.content, contains('rpe_high_threshold'));
        expect(export.content, contains('rpe_slope_quadrant_label'));
        expect(export.content, contains('slope_Orellana_19'));
        expect(export.content, contains('normal'));
        expect(export.content, contains('high_rpe_favorable_slope_response'));
        expect(
          export.content,
          contains('High RPE + adequate/favorable slope response'),
        );
        expect(export.content, contains('External'));
        expect(export.content, contains('direct_percent_mas'));
        expect(export.content, contains('Filtered note'));
        expect(export.content, isNot(contains('Cycling')));
      },
    );

    test('exports filter summary metadata when filtered set is empty', () {
      const series = LongitudinalSeries(
        athleteId: 1,
        athleteName: 'Runner',
        points: [],
        allPoints: [
          LongitudinalPoint(
            sessionId: 1,
            date: '2026-05-01',
            taskName: 'Tempo',
            sport: 'Running',
          ),
        ],
        excludedPoints: [
          LongitudinalPoint(
            sessionId: 1,
            date: '2026-05-01',
            taskName: 'Tempo',
            sport: 'Running',
          ),
        ],
        filter: LongitudinalDashboardFilter(sports: {'Swimming'}),
        activeFilterLabels: ['Sport: Swimming'],
        slopeRolling7: [],
        slopeRolling14: [],
        slopeRolling28: [],
        itlRolling7: [],
        itlRolling14: [],
        itlRolling28: [],
        fatigueFlags: [],
        summary: LongitudinalSummary(
          nSessions: 0,
          nComplete: 0,
          trendDirection: LongitudinalTrendDirection.insufficientData,
        ),
      );

      final export = exportLongitudinalCsv(series);

      expect(export.rowCount, 1);
      expect(export.content, contains('filter_summary'));
      expect(export.content, contains('nomogram_reference_source'));
      expect(export.content, contains('rpe_slope_response_index'));
      expect(export.content, contains('Sport: Swimming'));
      expect(export.content, contains('Runner'));
    });
  });

  group('Individual nomogram export', () {
    test('exports valid points and excluded sessions', () {
      final data = _individualNomogramData();
      final points = exportIndividualNomogramValidPointsCsv(data);
      final excluded = exportIndividualNomogramExcludedCsv(data);

      expect(points.content, contains('residual_population'));
      expect(points.content, contains('residual_hybrid'));
      expect(excluded.content, contains('missing_intensity'));
    });

    test('exports confidence, model summary, and curve points', () {
      final data = _individualNomogramData();
      final summary = exportIndividualNomogramSummaryCsv(data);
      final curves = exportIndividualNomogramCurvePointsCsv(data);

      expect(summary.content, contains('recommended_mode'));
      expect(summary.content, contains('hybrid'));
      expect(curves.content, contains('individual'));
      expect(curves.content, contains('hybrid'));
      expect(curves.content, isNot(contains('population_mean')));
      expect(curves.content, isNot(contains('population_lower')));
      expect(curves.content, isNot(contains('population_upper')));
    });
  });

  group('Population nomogram export', () {
    test('exports excel_operational preset bands', () {
      final export = exportPopulationNomogramCsv(
        PopulationNomogramSource.excelOperational,
        startIntensity: 60,
        endIntensity: 60,
      );

      expect(export.content, contains('excel_operational'));
      expect(export.content, contains('expected_lower'));
      expect(export.content, contains('expected_mean'));
      expect(export.content, contains('expected_upper'));
    });

    test('exports slope_Orellana_19 preset bands', () {
      final export = exportPopulationNomogramCsv(
        PopulationNomogramSource.slopeOrellana19,
        startIntensity: 40,
        endIntensity: 40,
      );

      expect(export.content, contains('slope_Orellana_19'));
      expect(export.content, isNot(contains('paper_original_2019')));
      expect(export.content, contains('outside the'));
    });
  });

  group('Export UI integration', () {
    late AppDatabase db;
    late int athleteId;
    late int sessionId;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      final seed = await _seedSession(db);
      athleteId = seed.$1;
      sessionId = seed.$2;
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('individual report shows Export CSV button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: IndividualReportScreen(database: db, sessionId: sessionId),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Export CSV'), findsOneWidget);
    });

    testWidgets('group report shows Export CSV button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: GroupReportScreen(database: db)),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Export CSV'), findsOneWidget);
    });

    testWidgets('longitudinal dashboard shows Export CSV button', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AthleteLongitudinalScreen(database: db, athleteId: athleteId),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Export CSV'), findsOneWidget);
    });

    testWidgets('individual nomogram shows Export CSV button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: IndividualNomogramScreen(database: db, athleteId: athleteId),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Export CSV'), findsOneWidget);
    });

    testWidgets('population nomogram shows Export CSV button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: PopulationNomogramScreen(database: db)),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Export CSV'), findsOneWidget);
    });
  });

  group('Regression guards', () {
    test('no legacy computeSlope usage in export/report flows', () {
      final files = [
        'lib/data/export/csv_export_service.dart',
        'lib/ui/screens/reports/individual_report_screen.dart',
        'lib/ui/screens/reports/group_report_screen.dart',
        'lib/ui/screens/reports/population_nomogram_screen.dart',
        'lib/ui/screens/longitudinal/athlete_longitudinal_screen.dart',
        'lib/ui/screens/nomogram/individual_nomogram_screen.dart',
      ];

      for (final file in files) {
        final text = File(file).readAsStringSync();
        expect(text, isNot(contains('computeSlope(')));
      }
    });

    test('direct RMSSD and RR correction defaults remain documented', () {
      final readme = File('README.md').readAsStringSync();

      expect(readme, contains('Direct RMSSD input is the default workflow'));
      expect(readme, contains('RR correction is off by default'));
    });

    test('real RR fixtures remain mandatory', () {
      final fixture = Directory('test/fixtures/rr_samples');

      expect(fixture.existsSync(), isTrue);
      expect(
        File('test/fixtures/rr_samples/2026-05-25_05-27-02.txt').existsSync(),
        isTrue,
      );
    });
  });
}

IndividualReportData _individualReport({
  String presetName = 'excel_operational',
}) {
  const classification = InternalLoadClassification.expectedResponse;
  return IndividualReportData(
    athleteName: 'VALORACIÓN Runner',
    sport: 'Running',
    sessionDate: '2026-05-27T10:00:00',
    taskName: 'RMSSD Test',
    sessionType: 'training',
    protocolName: '5-10',
    contextEnvironment: 'Indoor',
    externalVariables: [_variable('external', 'speed_kmh', 16, unit: 'km/h')],
    internalVariables: [_variable('internal', 'rpe_1_10', 7)],
    derivedVariables: const [],
    hrvSummary: const HrvReportSummary(
      inputMode: 'rr_intervals',
      rmssdRecovery: 24,
      rmssdRecoverySource: 'computed_from_rr_corrected',
      rmssdExercise: 4,
      rmssdExerciseSource: 'fallback_4_ms',
      usedFallbackExercise: true,
      recoveryWindowStartMin: 5,
      recoveryWindowEndMin: 10,
      tUsedForSlope: 10,
      rrRawRmssd: 23,
      rrCorrectedRmssd: 24,
      rrRmssdUsed: 24,
      rrCorrectionEnabled: true,
      rrCorrectionMethod: 'karlssonLinearInterpolation',
      rrArtifactCount: 1,
      rrArtifactPercent: 0.4,
      rrQualityDecision: 'valid',
      rrRmssdDeltaPercent: 4.3,
    ),
    slopeSummary: const SlopeReportSummary(
      rawSlope: 2,
      interpretedSlope: 2,
      itlIndex: 0.5,
      intensityPercent: 80,
      intensitySource: 'speed_kmh_div_mas',
      intensitySourceForSlope: 'External',
      primaryIntensityMetric: 'speed_kmh_div_mas',
    ),
    nomogramSummary: NomogramReportSummary(
      presetName: presetName,
      intensityPercent: 80,
      observedSlope: 2,
      expectedLower: 0.1,
      expectedMean: 0.34,
      expectedUpper: 0.72,
      residual: 1.66,
      residualPercent: 488.235,
      classification: classification,
      classificationLabel: 'Expected response',
      interpretationText: 'Within expected range for this intensity.',
      warnings: ['Check context'],
    ),
    warnings: const ['Check context'],
    canShowNomogram: true,
    classification: 'expected_response',
  );
}

GroupReportData _groupReport() {
  const rows = [
    GroupReportRow(
      athleteId: 2,
      athleteName: 'Runner B',
      sessionId: 20,
      sessionDate: '2026-05-02',
      taskName: 'Tempo',
      intensityPercent: 80,
      intensitySourceForSlope: 'External',
      primaryIntensityMetric: 'direct_percent_mas',
      rmssdExercise: 4,
      rmssdRecovery: 8,
      rawSlope: 0.4,
      interpretedSlope: 0.4,
      itlIndex: 2.5,
      classification: 'expected_response',
      residual: 0.06,
      residualPercent: 17.647,
      externalVariables: [],
      internalVariables: [],
      warnings: [],
      isCompleteForNomogram: true,
    ),
    GroupReportRow(
      athleteId: 1,
      athleteName: 'Runner A',
      sessionId: 10,
      sessionDate: '2026-05-01',
      taskName: 'Tempo',
      intensityPercent: null,
      rmssdExercise: null,
      rmssdRecovery: null,
      rawSlope: null,
      interpretedSlope: null,
      itlIndex: null,
      externalVariables: [],
      internalVariables: [],
      warnings: ['Missing slope'],
      isCompleteForNomogram: false,
    ),
  ];
  return const GroupReportData(
    title: 'Group Report',
    dateRange: 'All dates',
    presetName: 'excel_operational',
    rows: rows,
    summary: GroupReportSummary(
      nSessions: 2,
      nAthletes: 2,
      nComplete: 1,
      meanSlope: 0.45,
      medianSlope: 0.45,
      minSlope: 0.4,
      maxSlope: 0.5,
      meanItl: 2.5,
      nExpectedResponse: 1,
    ),
    warnings: ['Runner A: Missing slope'],
  );
}

LongitudinalSeries _longitudinalSeries() {
  const points = [
    LongitudinalPoint(
      sessionId: 1,
      date: '2026-05-01',
      taskName: 'Tempo',
      sessionType: 'training',
      intensityPercent: 80,
      intensitySourceForSlope: 'External',
      primaryIntensityMetric: 'direct_percent_mas',
      rawSlope: 0.5,
      interpretedSlope: 0.5,
      itlIndex: 2,
      residual: -0.6,
      residualPercent: -54,
      classification: 'high_or_moderate_internal_load',
      nomogramReference: LongitudinalNomogramReferencePoint(
        sessionId: 1,
        date: '2026-05-01',
        primaryIntensityValue: 80,
        primaryIntensityMetric: 'direct_percent_mas',
        intensitySourceForSlope: 'External',
        observedSlope: 0.5,
        observedItl: 2,
        referenceSlope: 0.4,
        lowerSlopeThreshold: 0.2,
        upperSlopeThreshold: 0.8,
        referenceItl: 2.5,
        lowerItlThreshold: 1.25,
        upperItlThreshold: 5,
        zone: LongitudinalRecoveryZone.normal,
        source: 'slope_Orellana_19',
      ),
      rpe: 7,
      srpe: 420,
      trimp: 80,
      primaryExternalLoadName: 'player_load',
      primaryExternalLoadValue: 100,
      warnings: ['Context note'],
    ),
    LongitudinalPoint(
      sessionId: 2,
      date: '2026-05-02',
      taskName: 'Intervals',
      sessionType: 'training',
      intensityPercent: 90,
      rawSlope: 0.4,
      interpretedSlope: 0.4,
      itlIndex: 2.5,
      residual: -0.7,
      residualPercent: -60,
    ),
  ];
  return const LongitudinalSeries(
    athleteId: 1,
    athleteName: 'Runner',
    points: points,
    slopeRolling7: [0.5, 0.45],
    slopeRolling14: [0.5, 0.45],
    slopeRolling28: [0.5, 0.45],
    itlRolling7: [2, 2.25],
    itlRolling14: [2, 2.25],
    itlRolling28: [2, 2.25],
    fatigueFlags: [
      LongitudinalFatigueFlag(
        ruleName: 'three_negative_residuals',
        message: 'Review training context.',
        startDate: '2026-05-01',
        endDate: '2026-05-03',
      ),
    ],
    summary: LongitudinalSummary(
      nSessions: 2,
      nComplete: 2,
      latestSlope: 0.4,
      latestItl: 2.5,
      meanSlope: 0.45,
      minSlope: 0.4,
      maxSlope: 0.5,
      meanItl: 2.25,
      trendDirection: LongitudinalTrendDirection.insufficientData,
    ),
  );
}

IndividualNomogramData _individualNomogramData() {
  const model = NomogramModel(
    params: NomogramParams(a: 2, b: -0.02, c: 0.1),
    rSquared: 0.88,
    nPoints: 6,
    nIntensityRanges: 2,
    confidenceLevel: IndividualNomogramConfidence.initial,
  );
  return const IndividualNomogramData(
    athleteId: 1,
    athleteName: 'Runner',
    validPoints: [
      IndividualNomogramPoint(
        sessionId: 1,
        date: '2026-05-01',
        taskName: 'Tempo',
        intensityPercent: 80,
        interpretedSlope: 0.5,
        classification: 'expected_response',
        residualPopulation: 0.16,
        residualIndividual: 0.08,
        residualHybrid: 0.12,
      ),
    ],
    excludedSessions: [
      ExcludedNomogramSession(
        sessionId: 2,
        date: '2026-05-02',
        taskName: 'Draft',
        reason: ExcludedNomogramReason.missingIntensity,
      ),
    ],
    confidenceLevel: IndividualNomogramConfidence.initial,
    intensityZonesPresent: {'low', 'medium'},
    fittedModel: model,
    populationPreset: PopulationNomogramSource.excelOperational,
    hybridWeightIndividual: 0.3,
    hybridWeightPopulation: 0.7,
    populationCurvePoints: [
      IndividualNomogramCurvePoint(intensityPercent: 80, slope: 0.34),
    ],
    individualCurvePoints: [
      IndividualNomogramCurvePoint(intensityPercent: 80, slope: 0.42),
    ],
    hybridCurvePoints: [
      IndividualNomogramCurvePoint(intensityPercent: 80, slope: 0.36),
    ],
    warnings: ['More data recommended'],
    summary: IndividualNomogramSummary(
      totalSessions: 2,
      validPointCount: 1,
      excludedCount: 1,
      lowZoneCount: 1,
      mediumZoneCount: 1,
      highZoneCount: 0,
      confidenceLabel: 'Initial',
      recommendedMode: IndividualNomogramRecommendedMode.hybrid,
      explanationText: 'Hybrid mode.',
    ),
  );
}

IntensityVariable _variable(
  String category,
  String name,
  double value, {
  String? unit,
}) {
  return IntensityVariable(
    id: 1,
    sessionId: 1,
    category: category,
    name: name,
    unit: unit,
    value: value,
    source: 'manual',
    isPrimaryForNomogram: category == 'external',
    createdAt: '2026-05-27T00:00:00',
  );
}

Future<(int, int)> _seedSession(AppDatabase db) async {
  final now = DateTime.now().toIso8601String();
  final athleteId = await db.athletesDao.insertAthlete(
    AthletesCompanion.insert(
      name: 'Export Runner',
      sport: const drift.Value('Running'),
      masKmh: const drift.Value(20),
      createdAt: now,
      updatedAt: now,
    ),
  );
  final sessionId = await db.sessionsDao.insertSession(
    SessionsCompanion.insert(
      athleteId: athleteId,
      date: '2026-05-27T10:00:00',
      taskName: const drift.Value('Tempo'),
      sport: const drift.Value('Running'),
      sessionType: const drift.Value('training'),
      intensityPercent: const drift.Value(80),
      intensitySource: const drift.Value('direct_percent_mas'),
      recoveryTimeMin: const drift.Value(10),
      recoveryWindowStartMin: const drift.Value(5),
      recoveryWindowEndMin: const drift.Value(10),
      rmssdExercise: const drift.Value(4),
      rmssdRecovery: const drift.Value(8),
      slopeRaw: const drift.Value(0.4),
      slopeInterpreted: const drift.Value(0.4),
      itlIndex: const drift.Value(2.5),
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
  return (athleteId, sessionId);
}
