import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hrv_slope_app/data/database/app_database.dart';
import 'package:hrv_slope_app/data/database/daos/sessions_dao.dart';
import 'package:hrv_slope_app/shared/engine/individual_report_builder.dart';
import 'package:hrv_slope_app/shared/engine/nomogram_engine.dart';
import 'package:hrv_slope_app/shared/engine/nomogram_mode.dart';
import 'package:hrv_slope_app/shared/engine/nomogram_resolver.dart';

void main() {
  group('IndividualReportBuilder nomogram mode resolution', () {
    test('expected bands change when requested mode changes', () {
      final detail = _detail(
        session: _session(intensityPercent: 80, slopeInterpreted: 1.0),
      );
      final individualBands = _flatIndividualBands(mean: 2.0, sigma: 0.5);
      final readiness = _readyReadiness();

      final populationReport = buildIndividualReport(
        detail: detail,
        nomogramPreset: PopulationNomogramSource.excelOperational,
        requestedNomogramMode: NomogramMode.population,
        individualModelBands: individualBands,
        individualReadiness: readiness,
      );
      final individualReport = buildIndividualReport(
        detail: detail,
        nomogramPreset: PopulationNomogramSource.excelOperational,
        requestedNomogramMode: NomogramMode.individual,
        individualModelBands: individualBands,
        individualReadiness: readiness,
      );

      expect(
        populationReport.nomogramSummary!.activeMode,
        NomogramMode.population,
      );
      expect(
        individualReport.nomogramSummary!.activeMode,
        NomogramMode.individual,
      );
      expect(
        individualReport.nomogramSummary!.expectedMean,
        isNot(populationReport.nomogramSummary!.expectedMean),
      );
    });

    test('requested individual falls back to hybrid with partial model', () {
      final report = buildIndividualReport(
        detail: _detail(
          session: _session(intensityPercent: 80, slopeInterpreted: 1.0),
        ),
        nomogramPreset: PopulationNomogramSource.excelOperational,
        requestedNomogramMode: NomogramMode.individual,
        individualModelBands: _flatIndividualBands(mean: 2.0, sigma: 0.5),
        individualReadiness: evaluateIndividualReadiness(
          intensities: List.generate(9, (i) => 50.0 + i * 5.0),
          rSquared: 0.30,
          cvRmse: 0.80,
        ),
      );

      final summary = report.nomogramSummary!;
      expect(summary.requestedMode, NomogramMode.individual);
      expect(summary.activeMode, NomogramMode.hybrid);
      expect(summary.athleteWeightPercent, 70.0);
      expect(summary.populationWeightPercent, 30.0);
      expect(summary.readinessGaps, isNotEmpty);
    });

    test(
      'requested individual falls back to population without model data',
      () {
        final report = buildIndividualReport(
          detail: _detail(
            session: _session(intensityPercent: 80, slopeInterpreted: 1.0),
          ),
          nomogramPreset: PopulationNomogramSource.excelOperational,
          requestedNomogramMode: NomogramMode.individual,
        );

        final summary = report.nomogramSummary!;
        expect(summary.activeMode, NomogramMode.population);
        expect(summary.athleteWeightPercent, 0.0);
        expect(summary.populationWeightPercent, 100.0);
        expect(summary.readinessGaps, isNotEmpty);
      },
    );

    test('builds partial individual model bands from athlete history', () {
      final current = _detail(
        session: _session(
          id: 1,
          intensityPercent: 50,
          slopeInterpreted: _sourceSlope(50),
        ),
      );
      final history = [
        for (var i = 1; i < 9; i++)
          _detail(
            session: _session(
              id: i + 1,
              date: '2024-01-${(15 + i).toString().padLeft(2, '0')}',
              intensityPercent: 50.0 + i * 5.0,
              slopeInterpreted: _sourceSlope(50.0 + i * 5.0),
            ),
          ),
      ];

      final report = buildIndividualReport(
        detail: current,
        nomogramPreset: PopulationNomogramSource.excelOperational,
        requestedNomogramMode: NomogramMode.hybrid,
        athleteHistory: history,
      );

      expect(report.nomogramSummary!.activeMode, NomogramMode.hybrid);
      expect(report.nomogramSummary!.athleteWeightPercent, 70.0);
    });

    test('35% intensity remains calculable and exposes extrapolation', () {
      final report = buildIndividualReport(
        detail: _detail(
          session: _session(intensityPercent: 35, slopeInterpreted: 1.0),
        ),
        nomogramPreset: PopulationNomogramSource.excelOperational,
      );

      final summary = report.nomogramSummary!;
      expect(summary.isExtrapolated, true);
      expect(summary.expectedLower, greaterThanOrEqualTo(0.1));
      expect(summary.expectedMean, greaterThanOrEqualTo(summary.expectedLower));
      expect(summary.expectedUpper, greaterThanOrEqualTo(summary.expectedMean));
      expect(
        summary.warnings.any((warning) => warning.contains('extrapolated')),
        true,
      );
    });

    test('classification uses resolved bands instead of population bands', () {
      final populationClassification = classifySlopeWithPopulationNomogram(
        80,
        1.0,
        source: PopulationNomogramSource.excelOperational,
      );
      expect(
        populationClassification.classification,
        InternalLoadClassification.lowInternalLoadOrFastRecovery,
      );

      final report = buildIndividualReport(
        detail: _detail(
          session: _session(intensityPercent: 80, slopeInterpreted: 1.0),
        ),
        nomogramPreset: PopulationNomogramSource.excelOperational,
        requestedNomogramMode: NomogramMode.individual,
        individualModelBands: _flatIndividualBands(mean: 2.0, sigma: 0.5),
        individualReadiness: _readyReadiness(),
      );

      final summary = report.nomogramSummary!;
      expect(summary.activeMode, NomogramMode.individual);
      expect(summary.expectedLower, closeTo(1.5, 0.001));
      expect(
        summary.classification,
        InternalLoadClassification.veryHighInternalLoad,
      );
    });
  });
}

Session _session({
  int id = 1,
  int athleteId = 1,
  String date = '2024-01-15',
  String? taskName = 'Test session',
  String? sport = 'Running',
  String? sessionType = 'training',
  bool isDraft = false,
  double? intensityPercent = 80.0,
  String? intensitySource = 'percent_mas',
  double? recoveryTimeMin = 10.0,
  double? recoveryWindowStartMin = 5.0,
  double? recoveryWindowEndMin = 10.0,
  double? rmssdExercise = 4.0,
  bool rmssdExerciseIsDefault = false,
  double? rmssdRecovery = 25.0,
  double? slopeRaw,
  double? slopeInterpreted = 1.0,
  String? classification = 'expected_response',
}) {
  final slope = slopeInterpreted;
  return Session(
    id: id,
    athleteId: athleteId,
    date: date,
    taskName: taskName,
    sport: sport,
    sessionType: sessionType,
    protocolName: null,
    contextEnvironment: null,
    isDraft: isDraft,
    intensityPercent: intensityPercent,
    intensitySource: intensitySource,
    recoveryTimeMin: recoveryTimeMin,
    recoveryWindowStartMin: recoveryWindowStartMin,
    recoveryWindowEndMin: recoveryWindowEndMin,
    rmssdExercise: rmssdExercise,
    rmssdExerciseIsDefault: rmssdExerciseIsDefault,
    rmssdRecovery: rmssdRecovery,
    slopeRaw: slopeRaw ?? slope,
    slopeInterpreted: slope,
    itlIndex: slope != null ? 1.0 / slope : null,
    classification: classification,
    hrvInputMode: 'direct_rmssd',
    rmssdRecoverySource: 'manual',
    rmssdExerciseSource: 'fallback_4_ms',
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
    createdAt: '2024-01-15T10:00:00',
  );
}

Athlete _athlete() {
  return const Athlete(
    id: 1,
    name: 'Test Athlete',
    sport: 'Running',
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

SessionDetail _detail({required Session session}) {
  return SessionDetail(
    athlete: _athlete(),
    session: session,
    variables: const [],
    hrvMeasurements: const [],
    notes: const [],
  );
}

IndividualModelBands _flatIndividualBands({
  required double mean,
  required double sigma,
}) {
  return IndividualModelBands(
    params: NomogramParams(a: 0, b: -0.01, c: mean),
    residualStdDev: sigma,
    rSquared: 0.90,
    cvRmse: 0.10,
    sourcePointCount: 12,
  );
}

IndividualReadiness _readyReadiness() {
  return evaluateIndividualReadiness(
    intensities: const [
      40.0,
      42.0,
      44.0,
      50.0,
      52.0,
      54.0,
      60.0,
      62.0,
      64.0,
      80.0,
      82.0,
      84.0,
    ],
    rSquared: 0.85,
    cvRmse: 0.20,
  );
}

double _sourceSlope(double intensityPercent) {
  return max(0.1, 12.0 * exp(-0.045 * intensityPercent) + 0.15);
}
