import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hrv_slope_app/data/database/app_database.dart';
import 'package:hrv_slope_app/data/database/daos/sessions_dao.dart';
import 'package:hrv_slope_app/shared/engine/longitudinal_builder.dart';
import 'package:hrv_slope_app/shared/engine/nomogram_engine.dart';
import 'package:hrv_slope_app/shared/engine/nomogram_mode.dart';
import 'package:hrv_slope_app/shared/engine/nomogram_resolver.dart';

void main() {
  group('LongitudinalBuilder nomogram mode resolution', () {
    test('default behavior uses population study mode', () {
      final series = _series([
        _detail(session: _session(intensityPercent: 80, slopeInterpreted: 0.5)),
      ]);
      final reference = series.points.single.nomogramReference;
      final populationBands = evaluatePopulationNomogramBands(
        80,
        source: PopulationNomogramSource.slopeOrellana19,
      );

      expect(reference.requestedMode, NomogramMode.population);
      expect(reference.activeMode, NomogramMode.population);
      expect(reference.source, 'slope_Orellana_19');
      expect(reference.athleteWeightPercent, 0.0);
      expect(reference.populationWeightPercent, 100.0);
      expect(
        reference.referenceSlope,
        closeTo(populationBands.expectedMean, 1e-9),
      );
      expect(
        series.nomogramReferenceSeries.requestedMode,
        NomogramMode.population,
      );
      expect(
        series.nomogramReferenceSeries.activeMode,
        NomogramMode.population,
      );
    });

    test('hybrid mode resolves one blended band set', () {
      final series = _series(
        [
          _detail(
            session: _session(intensityPercent: 80, slopeInterpreted: 1.0),
          ),
        ],
        requestedNomogramMode: NomogramMode.hybrid,
        individualModelBands: _flatIndividualBands(mean: 2.0, sigma: 0.5),
        individualReadiness: _partialReadiness(),
      );
      final reference = series.points.single.nomogramReference;
      final populationBands = evaluatePopulationNomogramBands(
        80,
        source: PopulationNomogramSource.excelOperational,
      );

      expect(reference.requestedMode, NomogramMode.hybrid);
      expect(reference.activeMode, NomogramMode.hybrid);
      expect(reference.source, NomogramMode.hybrid.key);
      expect(reference.athleteWeightPercent, 70.0);
      expect(reference.populationWeightPercent, 30.0);
      expect(reference.referenceSlope, isNot(populationBands.expectedMean));
      expect(series.nomogramReferenceSeries.points, hasLength(1));
      expect(series.nomogramReferenceSeries.activeMode, NomogramMode.hybrid);
    });

    test('hybrid mode can build individual bands from athlete history', () {
      final details = [
        for (var i = 0; i < 9; i++)
          _detail(
            session: _session(
              id: i + 1,
              date: '2024-01-${(10 + i).toString().padLeft(2, '0')}',
              intensityPercent: 50.0 + i * 5.0,
              slopeInterpreted: _sourceSlope(50.0 + i * 5.0),
            ),
          ),
      ];

      final series = _series(
        details,
        requestedNomogramMode: NomogramMode.hybrid,
      );

      expect(
        series.points.last.nomogramReference.activeMode,
        NomogramMode.hybrid,
      );
      expect(series.points.last.nomogramReference.athleteWeightPercent, 70.0);
    });

    test('requested individual falls back to hybrid with partial data', () {
      final series = _series(
        [
          _detail(
            session: _session(intensityPercent: 80, slopeInterpreted: 1.0),
          ),
        ],
        requestedNomogramMode: NomogramMode.individual,
        individualModelBands: _flatIndividualBands(mean: 2.0, sigma: 0.5),
        individualReadiness: _partialReadiness(),
      );
      final reference = series.points.single.nomogramReference;

      expect(reference.requestedMode, NomogramMode.individual);
      expect(reference.activeMode, NomogramMode.hybrid);
      expect(reference.readinessGaps, isNotEmpty);
      expect(series.nomogramReferenceSeries.activeMode, NomogramMode.hybrid);
      expect(series.nomogramReferenceSeries.readinessGaps, isNotEmpty);
    });

    test(
      'requested individual falls back to population with no model data',
      () {
        final series = _series([
          _detail(
            session: _session(intensityPercent: 80, slopeInterpreted: 1.0),
          ),
        ], requestedNomogramMode: NomogramMode.individual);
        final reference = series.points.single.nomogramReference;

        expect(reference.activeMode, NomogramMode.population);
        expect(reference.athleteWeightPercent, 0.0);
        expect(reference.populationWeightPercent, 100.0);
        expect(reference.readinessGaps, isNotEmpty);
      },
    );

    test('classification uses resolved bands instead of population bands', () {
      final populationClassification = classifySlopeWithPopulationNomogram(
        80,
        1.0,
        source: PopulationNomogramSource.slopeOrellana19,
      );
      expect(
        populationClassification.classification,
        InternalLoadClassification.lowInternalLoadOrFastRecovery,
      );

      final series = _series(
        [
          _detail(
            session: _session(intensityPercent: 80, slopeInterpreted: 1.0),
          ),
        ],
        requestedNomogramMode: NomogramMode.individual,
        individualModelBands: _flatIndividualBands(mean: 2.0, sigma: 0.5),
        individualReadiness: _readyReadiness(),
      );
      final point = series.points.single;

      expect(point.nomogramReference.activeMode, NomogramMode.individual);
      expect(point.nomogramReference.lowerSlopeThreshold, closeTo(1.5, 0.001));
      expect(point.nomogramReference.zone, LongitudinalRecoveryZone.low);
      expect(point.classification, 'very_high_internal_load');
      expect(point.residual, closeTo(-1.0, 0.001));
    });

    test(
      '35 percent intensity remains calculable with extrapolation metadata',
      () {
        final series = _series([
          _detail(
            session: _session(intensityPercent: 35, slopeInterpreted: 1.0),
          ),
        ]);
        final reference = series.points.single.nomogramReference;

        expect(reference.isAvailable, true);
        expect(reference.referenceSlope, isNotNull);
        expect(reference.lowerSlopeThreshold, isNotNull);
        expect(reference.upperSlopeThreshold, isNotNull);
        expect(reference.isExtrapolated, true);
        expect(
          reference.warnings.any((warning) => warning.contains('extrapolated')),
          true,
        );
        expect(series.nomogramReferenceSeries.hasExtrapolatedPoints, true);
      },
    );
  });
}

LongitudinalSeries _series(
  List<SessionDetail> details, {
  NomogramMode requestedNomogramMode = NomogramMode.population,
  IndividualModelBands? individualModelBands,
  IndividualReadiness? individualReadiness,
}) {
  return buildLongitudinalSeries(
    athlete: _athlete(),
    details: details,
    requestedNomogramMode: requestedNomogramMode,
    individualModelBands: individualModelBands,
    individualReadiness: individualReadiness,
  );
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

IndividualReadiness _partialReadiness() {
  return evaluateIndividualReadiness(
    intensities: List.generate(9, (i) => 50.0 + i * 5.0),
    rSquared: 0.30,
    cvRmse: 0.80,
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
