// Phase 3.0 tests — Individual Report + Population Nomogram MVP.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrv_slope_app/data/database/app_database.dart';
import 'package:hrv_slope_app/data/database/daos/sessions_dao.dart';
import 'package:hrv_slope_app/shared/engine/individual_report_builder.dart';
import 'package:hrv_slope_app/shared/engine/nomogram_engine.dart';
import 'package:hrv_slope_app/ui/widgets/nomogram_chart.dart';

// ── Test Helpers ──────────────────────────────────────────────────────────

/// Creates a fake Session with overridable fields.
Session _session({
  int id = 1,
  int athleteId = 1,
  String date = '2024-01-15',
  String? taskName = 'Test session',
  String? sport = 'Running',
  String? sessionType = 'training',
  String? protocolName,
  String? contextEnvironment,
  bool isDraft = false,
  double? intensityPercent = 80.0,
  String? intensitySource = 'percent_mas',
  double? recoveryTimeMin = 10.0,
  double? recoveryWindowStartMin = 5.0,
  double? recoveryWindowEndMin = 10.0,
  double? rmssdExercise = 4.0,
  bool rmssdExerciseIsDefault = true,
  double? rmssdRecovery = 25.0,
  double? slopeRaw = 2.1,
  double? slopeInterpreted = 2.1,
  double? itlIndex,
  String? classification = 'veryGood',
  String? hrvInputMode = 'direct_rmssd',
  String? rmssdRecoverySource = 'manual',
  String? rmssdExerciseSource = 'fallback_4_ms',
  String? rrQualityFlag,
  double? rrArtifactPercent,
  String? rrPreprocessingMode,
  bool rrCorrectionEnabled = false,
  String? rrCorrectionMethod,
  double? rrRawRmssd,
  double? rrCorrectedRmssd,
  double? rrRmssdUsed,
  int? rrArtifactCount,
  String? rrQualityDecision,
  String? rrQualityNotesJson,
  double? rrRmssdDeltaPercent,
  int? importBatchId,
  String? notes,
  String createdAt = '2024-01-15T10:00:00',
}) {
  return Session(
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
    itlIndex:
        itlIndex ?? (slopeInterpreted != null ? 1.0 / slopeInterpreted : null),
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
  );
}

Athlete _athlete({
  int id = 1,
  String name = 'Test Athlete',
  String? sport = 'Running',
}) {
  return Athlete(
    id: id,
    name: name,
    sport: sport,
    birthDate: null,
    gender: null,
    positionOrEvent: null,
    masKmh: 18.0,
    vvo2maxKmh: null,
    mapW: null,
    fcMax: null,
    notes: null,
    isArchived: false,
    createdAt: '2024-01-01T00:00:00',
    updatedAt: '2024-01-01T00:00:00',
  );
}

SessionDetail _detail({
  Session? session,
  Athlete? athlete,
  List<IntensityVariable>? variables,
}) {
  return SessionDetail(
    athlete: athlete ?? _athlete(),
    session: session ?? _session(),
    variables: variables ?? [],
    hrvMeasurements: [],
    notes: [],
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────

void main() {
  // ── Report builder ────────────────────────────────────────────────────

  group('Report builder', () {
    test('complete session builds report data', () {
      final report = buildIndividualReport(
        detail: _detail(),
        nomogramPreset: PopulationNomogramSource.excelOperational,
      );
      expect(report.athleteName, 'Test Athlete');
      expect(report.sessionDate, '2024-01-15');
      expect(report.taskName, 'Test session');
      expect(report.sport, 'Running');
      expect(report.isDraft, isFalse);
      expect(report.hrvSummary.rmssdRecovery, 25.0);
      expect(report.slopeSummary.rawSlope, 2.1);
      expect(report.slopeSummary.interpretedSlope, 2.1);
      expect(report.canShowNomogram, isTrue);
      expect(report.nomogramSummary, isNotNull);
    });

    test('missing intensity_percent disables nomogram summary', () {
      final report = buildIndividualReport(
        detail: _detail(session: _session(intensityPercent: null)),
        nomogramPreset: PopulationNomogramSource.excelOperational,
      );
      expect(report.canShowNomogram, isFalse);
      expect(report.nomogramSummary, isNull);
      expect(
        report.warnings.any((w) => w.contains('Intensity percent')),
        isTrue,
      );
    });

    test('missing external variable produces warning', () {
      final report = buildIndividualReport(
        detail: _detail(variables: []),
        nomogramPreset: PopulationNomogramSource.excelOperational,
      );
      expect(report.warnings.any((w) => w.contains('external')), isTrue);
    });

    test('missing internal variable produces warning', () {
      final report = buildIndividualReport(
        detail: _detail(variables: []),
        nomogramPreset: PopulationNomogramSource.excelOperational,
      );
      expect(report.warnings.any((w) => w.contains('internal')), isTrue);
    });

    test('fallback RMSSD exercise produces warning', () {
      final report = buildIndividualReport(
        detail: _detail(session: _session(rmssdExerciseIsDefault: true)),
        nomogramPreset: PopulationNomogramSource.excelOperational,
      );
      expect(report.warnings.any((w) => w.contains('fallback')), isTrue);
    });

    test('RR mode includes preprocessing summary', () {
      final report = buildIndividualReport(
        detail: _detail(
          session: _session(
            hrvInputMode: 'rr_intervals',
            rrRawRmssd: 28.5,
            rrCorrectedRmssd: 27.1,
            rrRmssdUsed: 27.1,
            rrCorrectionEnabled: true,
            rrCorrectionMethod: 'rangeAndEctopic',
            rrArtifactCount: 3,
            rrArtifactPercent: 1.2,
            rrQualityDecision: 'valid',
            rrRmssdDeltaPercent: -4.9,
          ),
        ),
        nomogramPreset: PopulationNomogramSource.excelOperational,
      );
      final h = report.hrvSummary;
      expect(h.inputMode, 'rr_intervals');
      expect(h.rrRawRmssd, 28.5);
      expect(h.rrCorrectedRmssd, 27.1);
      expect(h.rrCorrectionEnabled, isTrue);
      expect(h.rrArtifactCount, 3);
      expect(h.rrQualityDecision, 'valid');
    });

    test('RR correction enabled produces warning', () {
      final report = buildIndividualReport(
        detail: _detail(
          session: _session(
            rrCorrectionEnabled: true,
            rrCorrectionMethod: 'rangeAndEctopic',
          ),
        ),
        nomogramPreset: PopulationNomogramSource.excelOperational,
      );
      expect(report.warnings.any((w) => w.contains('correction')), isTrue);
    });

    test('RR quality warning produces warning', () {
      final report = buildIndividualReport(
        detail: _detail(session: _session(rrQualityDecision: 'warning')),
        nomogramPreset: PopulationNomogramSource.excelOperational,
      );
      expect(report.warnings.any((w) => w.contains('warning')), isTrue);
    });

    test('classification text maps correctly', () {
      expect(
        interpretationTextFor(InternalLoadClassification.veryHighInternalLoad),
        contains('lower than expected'),
      );
      expect(
        interpretationTextFor(
          InternalLoadClassification.highOrModerateInternalLoad,
        ),
        contains('below the expected mean'),
      );
      expect(
        interpretationTextFor(InternalLoadClassification.expectedResponse),
        contains('within the expected'),
      );
      expect(
        interpretationTextFor(
          InternalLoadClassification.lowInternalLoadOrFastRecovery,
        ),
        contains('favorable'),
      );
    });

    test('residual and residual_percent shown when available', () {
      final report = buildIndividualReport(
        detail: _detail(),
        nomogramPreset: PopulationNomogramSource.excelOperational,
      );
      final n = report.nomogramSummary!;
      // Residual = observed - expected_mean; will be non-null
      expect(n.residual, isNotNaN);
      expect(n.residualPercent, isNotNaN);
    });

    test('report uses active population preset', () {
      final reportExcel = buildIndividualReport(
        detail: _detail(),
        nomogramPreset: PopulationNomogramSource.excelOperational,
      );
      expect(reportExcel.nomogramSummary!.presetName, 'excel_operational');

      final reportPaper = buildIndividualReport(
        detail: _detail(),
        nomogramPreset: PopulationNomogramSource.slopeOrellana19,
      );
      expect(reportPaper.nomogramSummary!.presetName, 'slope_Orellana_19');
    });

    test('draft session shows draft warning and disables nomogram', () {
      final report = buildIndividualReport(
        detail: _detail(
          session: _session(isDraft: true, slopeInterpreted: null),
        ),
        nomogramPreset: PopulationNomogramSource.excelOperational,
      );
      expect(report.isDraft, isTrue);
      expect(report.canShowNomogram, isFalse);
      expect(report.warnings.any((w) => w.contains('draft')), isTrue);
    });

    test('missing RMSSD recovery produces warning', () {
      final report = buildIndividualReport(
        detail: _detail(session: _session(rmssdRecovery: null)),
        nomogramPreset: PopulationNomogramSource.excelOperational,
      );
      expect(report.warnings.any((w) => w.contains('RMSSD recovery')), isTrue);
    });

    test('out-of-range intensity produces extrapolation warning', () {
      final report = buildIndividualReport(
        detail: _detail(session: _session(intensityPercent: 50.0)),
        nomogramPreset: PopulationNomogramSource.excelOperational,
      );
      expect(report.warnings.any((w) => w.contains('extrapolated')), isTrue);
    });
  });

  // ── Nomogram chart ────────────────────────────────────────────────────

  group('Nomogram chart', () {
    testWidgets('chart renders for excel_operational preset', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NomogramChart(
              preset: PopulationNomogramSource.excelOperational,
            ),
          ),
        ),
      );
      expect(find.text('Intensity (%)'), findsOneWidget);
      expect(find.text('RMSSD-Slope'), findsOneWidget);
      expect(find.text('Lower band'), findsOneWidget);
      expect(find.text('Mean'), findsOneWidget);
      expect(find.text('Upper band'), findsOneWidget);
    });

    testWidgets('chart renders for slope_Orellana_19 preset', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NomogramChart(
              preset: PopulationNomogramSource.slopeOrellana19,
            ),
          ),
        ),
      );
      expect(find.text('Intensity (%)'), findsOneWidget);
      expect(find.text('RMSSD-Slope'), findsOneWidget);
    });

    testWidgets('session point included when intensity and slope exist', (
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
      // Session legend item should appear
      expect(find.text('Session'), findsOneWidget);
    });

    testWidgets('missing intensity shows no session point', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NomogramChart(
              preset: PopulationNomogramSource.excelOperational,
            ),
          ),
        ),
      );
      // Session legend item should not appear
      expect(find.text('Session'), findsNothing);
    });
  });

  // ── Nomogram engine (chart-supporting) ────────────────────────────────

  group('Nomogram engine for chart', () {
    test('evaluatePopulationNomogramBands at 80% excel_operational', () {
      final bands = evaluatePopulationNomogramBands(
        80.0,
        source: PopulationNomogramSource.excelOperational,
      );
      expect(bands.expectedLower, greaterThan(0));
      expect(bands.expectedMean, greaterThan(bands.expectedLower));
      expect(bands.expectedUpper, greaterThan(bands.expectedMean));
      expect(bands.warnings, isEmpty);
    });

    test('evaluatePopulationNomogramBands at 80% slope_Orellana_19', () {
      final bands = evaluatePopulationNomogramBands(
        80.0,
        source: PopulationNomogramSource.slopeOrellana19,
      );
      expect(bands.expectedLower, greaterThan(0));
      expect(bands.expectedMean, greaterThan(bands.expectedLower));
      expect(bands.expectedUpper, greaterThan(bands.expectedMean));
    });

    test('out-of-range intensity produces extrapolation warning', () {
      final bands = evaluatePopulationNomogramBands(
        50.0,
        source: PopulationNomogramSource.excelOperational,
      );
      expect(bands.warnings, isNotEmpty);
      expect(bands.warnings.first, contains('extrapolated'));
    });

    test('classify at 80% with slope 2.1 = favorable response', () {
      final result = classifySlopeWithPopulationNomogram(
        80.0,
        2.1,
        source: PopulationNomogramSource.excelOperational,
      );
      expect(
        result.classification,
        InternalLoadClassification.lowInternalLoadOrFastRecovery,
      );
    });

    test('classify at 80% with slope 0.05 → clamped to 0.1', () {
      final result = classifySlopeWithPopulationNomogram(
        80.0,
        0.05,
        source: PopulationNomogramSource.excelOperational,
      );
      // 0.05 is clamped to 0.1 (minimum). At 80%, lower ≈ 0.10,
      // so clamped slope ≈ lower band → highOrModerate
      expect(
        result.classification,
        anyOf(
          InternalLoadClassification.veryHighInternalLoad,
          InternalLoadClassification.highOrModerateInternalLoad,
        ),
      );
      // Confirm clamping occurred
      expect(result.observedSlope, 0.1);
    });
  });

  // ── Interpretation text ───────────────────────────────────────────────

  group('Interpretation text', () {
    test('does not contain medical terms', () {
      for (final c in InternalLoadClassification.values) {
        final text = interpretationTextFor(c);
        expect(text.toLowerCase(), isNot(contains('diagnosis')));
        expect(text.toLowerCase(), isNot(contains('disease')));
        expect(text.toLowerCase(), isNot(contains('pathological')));
        expect(text.toLowerCase(), isNot(contains('safe')));
        expect(text.toLowerCase(), isNot(contains('unsafe')));
      }
    });

    test('uses recovery-response language', () {
      for (final c in InternalLoadClassification.values) {
        final text = interpretationTextFor(c);
        // Each interpretation should reference recovery/post-effort response.
        expect(
          text.contains('Recovery') ||
              text.contains('recovery') ||
              text.contains('post-effort response'),
          isTrue,
          reason: 'Text for $c should use recovery-response language: $text',
        );
        expect(text.toLowerCase(), isNot(contains('internal load')));
      }
    });
  });

  // ── Regression guards ─────────────────────────────────────────────────

  group('Regression guards', () {
    test('direct RMSSD remains default in HRV summary', () {
      final report = buildIndividualReport(
        detail: _detail(session: _session()),
        nomogramPreset: PopulationNomogramSource.excelOperational,
      );
      expect(report.hrvSummary.inputMode, 'direct_rmssd');
    });

    test('RR correction remains off by default', () {
      final report = buildIndividualReport(
        detail: _detail(session: _session()),
        nomogramPreset: PopulationNomogramSource.excelOperational,
      );
      expect(report.hrvSummary.rrCorrectionEnabled, isFalse);
    });

    test('no nomogram classification if intensity_percent missing', () {
      final report = buildIndividualReport(
        detail: _detail(session: _session(intensityPercent: null)),
        nomogramPreset: PopulationNomogramSource.excelOperational,
      );
      expect(report.nomogramSummary, isNull);
    });

    test('slope denominator is recovery_window_end_min', () {
      final report = buildIndividualReport(
        detail: _detail(
          session: _session(recoveryWindowEndMin: 10.0, recoveryTimeMin: 10.0),
        ),
        nomogramPreset: PopulationNomogramSource.excelOperational,
      );
      expect(report.hrvSummary.tUsedForSlope, 10.0);
    });

    test('raw and interpreted slope both present in report', () {
      final report = buildIndividualReport(
        detail: _detail(
          session: _session(slopeRaw: 2.1, slopeInterpreted: 2.1),
        ),
        nomogramPreset: PopulationNomogramSource.excelOperational,
      );
      expect(report.slopeSummary.rawSlope, 2.1);
      expect(report.slopeSummary.interpretedSlope, 2.1);
    });
  });
}
