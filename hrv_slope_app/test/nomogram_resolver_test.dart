/// Tests for nomogram_resolver.dart — band resolution, hybrid blending,
/// individual bands, residual std dev, and LOO-CV.
library;

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hrv_slope_app/shared/engine/nomogram_engine.dart';
import 'package:hrv_slope_app/shared/engine/nomogram_mode.dart';
import 'package:hrv_slope_app/shared/engine/nomogram_resolver.dart';

void main() {
  // ── Helper factories ──

  IndividualModelBands makeIndividualBands({
    double a = 100.0,
    double b = -0.05,
    double c = 0.1,
    double residualStdDev = 0.3,
  }) {
    return IndividualModelBands(
      params: NomogramParams(a: a, b: b, c: c),
      residualStdDev: residualStdDev,
    );
  }

  IndividualReadiness makeReadiness({
    required bool isReady,
    int validSessions = 15,
  }) {
    // Generate data with ≥4 qualified bins (3+ measurements each)
    // and ≥30pp coverage.
    final intensities = <double>[
      40.0, 42.0, 44.0, // bin 4
      50.0, 52.0, 54.0, // bin 5
      60.0, 62.0, 64.0, // bin 6
      80.0, 82.0, 84.0, // bin 8
      90.0, 92.0, 94.0, // bin 9
    ].take(validSessions).toList();
    return evaluateIndividualReadiness(
      intensities: intensities,
      rSquared: isReady ? 0.85 : 0.30,
      cvRmse: isReady ? 0.20 : 0.80,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  group('IndividualModelBands', () {
    test('mean evaluates exponential model', () {
      final bands = makeIndividualBands();
      final m = bands.mean(70.0);
      expect(m, greaterThan(0.1));
    });

    test('lower is mean minus σ, floored at 0.1', () {
      final bands = makeIndividualBands(residualStdDev: 0.3);
      final m = bands.mean(90.0);
      final l = bands.lower(90.0);
      expect(l, max(0.1, m - 0.3));
    });

    test('upper is mean plus σ', () {
      final bands = makeIndividualBands(residualStdDev: 0.3);
      final m = bands.mean(70.0);
      final u = bands.upper(70.0);
      expect(u, closeTo(m + 0.3, 0.001));
    });

    test('lower never goes below 0.1', () {
      final bands = makeIndividualBands(
        a: 0.01,
        b: -0.001,
        c: 0.1,
        residualStdDev: 5.0,
      );
      expect(bands.lower(95.0), 0.1);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('computeResidualStdDev', () {
    test('perfect fit returns 0', () {
      final params = NomogramParams(a: 10.0, b: -0.05, c: 0.1);
      final points = [
        NomogramPoint(intensityPercent: 60.0, slope: params.evaluate(60.0)),
        NomogramPoint(intensityPercent: 80.0, slope: params.evaluate(80.0)),
        NomogramPoint(intensityPercent: 100.0, slope: params.evaluate(100.0)),
      ];
      final std = computeResidualStdDev(points, params);
      expect(std, closeTo(0.0, 1e-9));
    });

    test('returns positive value for imperfect fit', () {
      final params = NomogramParams(a: 10.0, b: -0.05, c: 0.1);
      final points = [
        NomogramPoint(
          intensityPercent: 60.0,
          slope: params.evaluate(60.0) + 0.5,
        ),
        NomogramPoint(
          intensityPercent: 80.0,
          slope: params.evaluate(80.0) - 0.3,
        ),
        NomogramPoint(
          intensityPercent: 100.0,
          slope: params.evaluate(100.0) + 0.1,
        ),
      ];
      final std = computeResidualStdDev(points, params);
      expect(std, greaterThan(0.0));
    });

    test('single point returns 0', () {
      final params = NomogramParams(a: 10.0, b: -0.05, c: 0.1);
      final points = [NomogramPoint(intensityPercent: 70.0, slope: 1.5)];
      expect(computeResidualStdDev(points, params), 0.0);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('computeLooCvRmse', () {
    test('returns null with fewer than 4 points', () {
      final points = [
        NomogramPoint(intensityPercent: 60.0, slope: 1.5),
        NomogramPoint(intensityPercent: 80.0, slope: 0.5),
        NomogramPoint(intensityPercent: 100.0, slope: 0.2),
      ];
      expect(computeLooCvRmse(points), isNull);
    });

    test('returns finite positive value with enough points', () {
      final points = [
        NomogramPoint(intensityPercent: 55.0, slope: 2.0),
        NomogramPoint(intensityPercent: 60.0, slope: 1.5),
        NomogramPoint(intensityPercent: 70.0, slope: 0.8),
        NomogramPoint(intensityPercent: 80.0, slope: 0.4),
        NomogramPoint(intensityPercent: 90.0, slope: 0.2),
        NomogramPoint(intensityPercent: 100.0, slope: 0.15),
      ];
      final cv = computeLooCvRmse(points);
      expect(cv, isNotNull);
      expect(cv!, greaterThanOrEqualTo(0.0));
      expect(cv.isFinite, true);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('buildIndividualModelBands', () {
    test('copies fit params and derives residual standard deviation', () {
      final points = [
        NomogramPoint(intensityPercent: 55.0, slope: 2.0),
        NomogramPoint(intensityPercent: 60.0, slope: 1.5),
        NomogramPoint(intensityPercent: 70.0, slope: 0.8),
        NomogramPoint(intensityPercent: 80.0, slope: 0.4),
        NomogramPoint(intensityPercent: 90.0, slope: 0.2),
        NomogramPoint(intensityPercent: 100.0, slope: 0.15),
      ];
      final model = fitIndividualNomogram(points);

      final bands = buildIndividualModelBands(
        fittedModel: model,
        sourcePoints: points,
      );

      expect(bands.params, model.params);
      expect(
        bands.residualStdDev,
        closeTo(computeResidualStdDev(points, model.params), 1e-12),
      );
      expect(bands.rSquared, model.rSquared);
      expect(bands.sourcePointCount, points.length);
    });

    test('computes LOO-CV RMSE when source points allow it', () {
      final points = [
        NomogramPoint(intensityPercent: 55.0, slope: 2.0),
        NomogramPoint(intensityPercent: 60.0, slope: 1.5),
        NomogramPoint(intensityPercent: 70.0, slope: 0.8),
        NomogramPoint(intensityPercent: 80.0, slope: 0.4),
        NomogramPoint(intensityPercent: 90.0, slope: 0.2),
        NomogramPoint(intensityPercent: 100.0, slope: 0.15),
      ];
      final model = fitIndividualNomogram(points);

      final bands = buildIndividualModelBands(
        fittedModel: model,
        sourcePoints: points,
      );

      expect(bands.cvRmse, isNotNull);
      expect(bands.cvRmse, closeTo(computeLooCvRmse(points)!, 1e-12));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('resolveNomogramBands — population mode', () {
    test('always returns population bands regardless of individual data', () {
      final indBands = makeIndividualBands();
      final readiness = makeReadiness(isReady: true);

      final result = resolveNomogramBands(
        intensityPercent: 70.0,
        requestedMode: NomogramMode.population,
        populationPreset: PopulationNomogramSource.excelOperational,
        individualBands: indBands,
        readiness: readiness,
      );

      expect(result.activeMode, NomogramMode.population);
      expect(result.athleteWeightPercent, 0.0);
      expect(result.populationWeightPercent, 100.0);
    });

    test('population bands match direct evaluatePopulationNomogramBands', () {
      final result = resolveNomogramBands(
        intensityPercent: 80.0,
        requestedMode: NomogramMode.population,
        populationPreset: PopulationNomogramSource.excelOperational,
      );

      final direct = evaluatePopulationNomogramBands(
        80.0,
        source: PopulationNomogramSource.excelOperational,
      );

      expect(result.lower, direct.expectedLower);
      expect(result.mean, direct.expectedMean);
      expect(result.upper, direct.expectedUpper);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('resolveNomogramBands — hybrid mode', () {
    test('blends population and individual when data available', () {
      final indBands = makeIndividualBands();
      final readiness = evaluateIndividualReadiness(
        intensities: List.generate(7, (i) => 50.0 + i * 8.0),
      );
      expect(readiness.hybridWeight, 0.3);

      final result = resolveNomogramBands(
        intensityPercent: 70.0,
        requestedMode: NomogramMode.hybrid,
        populationPreset: PopulationNomogramSource.excelOperational,
        individualBands: indBands,
        readiness: readiness,
      );

      expect(result.activeMode, NomogramMode.hybrid);
      expect(result.athleteWeightPercent, 30.0);
      expect(result.populationWeightPercent, 70.0);
      expect(result.source, NomogramModelSource.hybrid);
    });

    test('falls back to population if no individual data', () {
      final result = resolveNomogramBands(
        intensityPercent: 70.0,
        requestedMode: NomogramMode.hybrid,
        populationPreset: PopulationNomogramSource.excelOperational,
      );

      expect(result.activeMode, NomogramMode.population);
      expect(result.warnings, isNotEmpty);
    });

    test('falls back to population if hybridWeight is 0', () {
      final readiness = evaluateIndividualReadiness(
        intensities: [60.0, 70.0], // only 2 sessions
      );
      expect(readiness.hybridWeight, 0.0);

      final result = resolveNomogramBands(
        intensityPercent: 70.0,
        requestedMode: NomogramMode.hybrid,
        populationPreset: PopulationNomogramSource.excelOperational,
        individualBands: makeIndividualBands(),
        readiness: readiness,
      );

      expect(result.activeMode, NomogramMode.population);
    });

    test('hybrid bands are between population and individual', () {
      final indBands = makeIndividualBands(
        a: 50.0,
        b: -0.04,
        c: 0.2,
        residualStdDev: 0.2,
      );
      final readiness = evaluateIndividualReadiness(
        intensities: List.generate(10, (i) => 50.0 + i * 5.0),
      );

      final result = resolveNomogramBands(
        intensityPercent: 70.0,
        requestedMode: NomogramMode.hybrid,
        populationPreset: PopulationNomogramSource.excelOperational,
        individualBands: indBands,
        readiness: readiness,
      );

      final popBands = evaluatePopulationNomogramBands(
        70.0,
        source: PopulationNomogramSource.excelOperational,
      );

      // Hybrid mean should be between pop and individual
      final indMean = indBands.mean(70.0);
      final popMean = popBands.expectedMean;
      final lower = min(indMean, popMean);
      final upper = max(indMean, popMean);

      // With tolerance for min-band-width adjustment
      expect(result.mean, greaterThanOrEqualTo(lower - 0.1));
      expect(result.mean, lessThanOrEqualTo(upper + 0.1));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('resolveNomogramBands — individual mode', () {
    test('uses individual bands when fully ready', () {
      final indBands = makeIndividualBands();
      final readiness = makeReadiness(isReady: true);

      final result = resolveNomogramBands(
        intensityPercent: 70.0,
        requestedMode: NomogramMode.individual,
        populationPreset: PopulationNomogramSource.excelOperational,
        individualBands: indBands,
        readiness: readiness,
      );

      expect(result.activeMode, NomogramMode.individual);
      expect(result.athleteWeightPercent, 100.0);
      expect(result.source, NomogramModelSource.individual);
    });

    test('falls back to hybrid when not ready but has some data', () {
      final indBands = makeIndividualBands();
      // 9 sessions: hybridWeight = 0.7
      final readiness = evaluateIndividualReadiness(
        intensities: List.generate(9, (i) => 50.0 + i * 5.0),
        rSquared: 0.30,
        cvRmse: 0.80,
      );
      expect(readiness.isReady, false);
      expect(readiness.hybridWeight, 0.7);

      final result = resolveNomogramBands(
        intensityPercent: 70.0,
        requestedMode: NomogramMode.individual,
        populationPreset: PopulationNomogramSource.excelOperational,
        individualBands: indBands,
        readiness: readiness,
      );

      expect(result.activeMode, NomogramMode.hybrid);
      expect(result.warnings.any((w) => w.contains('fallback')), true);
    });

    test('falls back to population when no hybrid possible', () {
      final readiness = evaluateIndividualReadiness(
        intensities: [60.0, 70.0], // too few
      );

      final result = resolveNomogramBands(
        intensityPercent: 70.0,
        requestedMode: NomogramMode.individual,
        populationPreset: PopulationNomogramSource.excelOperational,
        individualBands: makeIndividualBands(),
        readiness: readiness,
      );

      expect(result.activeMode, NomogramMode.population);
      expect(result.warnings.any((w) => w.contains('population')), true);
    });

    test('falls back to population when individual data is null', () {
      final result = resolveNomogramBands(
        intensityPercent: 70.0,
        requestedMode: NomogramMode.individual,
        populationPreset: PopulationNomogramSource.excelOperational,
      );

      expect(result.activeMode, NomogramMode.population);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('resolveNomogramBands — minimum band width enforcement', () {
    test('narrow individual bands are widened to 50% of population width', () {
      // Very small residualStdDev → very narrow individual bands
      final indBands = makeIndividualBands(
        a: 10.0,
        b: -0.03,
        c: 0.15,
        residualStdDev: 0.01,
      );
      final readiness = makeReadiness(isReady: true);

      final result = resolveNomogramBands(
        intensityPercent: 70.0,
        requestedMode: NomogramMode.individual,
        populationPreset: PopulationNomogramSource.excelOperational,
        individualBands: indBands,
        readiness: readiness,
      );

      final popBands = evaluatePopulationNomogramBands(
        70.0,
        source: PopulationNomogramSource.excelOperational,
      );
      final popWidth = popBands.expectedUpper - popBands.expectedLower;
      final resultWidth = result.upper - result.lower;

      expect(resultWidth, greaterThanOrEqualTo(popWidth * 0.5 - 0.01));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('resolveNomogramBands — extrapolation', () {
    test(
      'population band evaluation exposes structured extrapolation flag',
      () {
        final lowBands = evaluatePopulationNomogramBands(
          40.0,
          source: PopulationNomogramSource.excelOperational,
        );
        final inRangeBands = evaluatePopulationNomogramBands(
          80.0,
          source: PopulationNomogramSource.excelOperational,
        );

        expect(lowBands.isExtrapolated, true);
        expect(inRangeBands.isExtrapolated, false);
      },
    );

    test('extrapolated flag set for out-of-range intensity', () {
      final result = resolveNomogramBands(
        intensityPercent: 40.0, // below excel_operational 60% min
        requestedMode: NomogramMode.population,
        populationPreset: PopulationNomogramSource.excelOperational,
      );

      expect(result.isExtrapolated, true);
      expect(result.warnings.any((w) => w.contains('extrapolated')), true);
    });

    test('no extrapolation flag for in-range intensity', () {
      final result = resolveNomogramBands(
        intensityPercent: 70.0,
        requestedMode: NomogramMode.population,
        populationPreset: PopulationNomogramSource.excelOperational,
      );

      expect(result.isExtrapolated, false);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('resolveNomogramBandCurve', () {
    test('returns correct number of points', () {
      final curve = resolveNomogramBandCurve(
        startIntensity: 40.0,
        endIntensity: 100.0,
        steps: 30,
        requestedMode: NomogramMode.population,
        populationPreset: PopulationNomogramSource.excelOperational,
      );

      expect(curve.length, 31); // steps + 1
    });

    test('steps <= 0 returns a single point without division by zero', () {
      final zeroStepCurve = resolveNomogramBandCurve(
        startIntensity: 40.0,
        endIntensity: 100.0,
        steps: 0,
        requestedMode: NomogramMode.population,
        populationPreset: PopulationNomogramSource.excelOperational,
      );
      final negativeStepCurve = resolveNomogramBandCurve(
        startIntensity: 45.0,
        endIntensity: 100.0,
        steps: -3,
        requestedMode: NomogramMode.population,
        populationPreset: PopulationNomogramSource.excelOperational,
      );

      expect(zeroStepCurve, hasLength(1));
      expect(zeroStepCurve.single.intensityPercent, 40.0);
      expect(negativeStepCurve, hasLength(1));
      expect(negativeStepCurve.single.intensityPercent, 45.0);
    });

    test('all points have valid band values', () {
      final curve = resolveNomogramBandCurve(
        startIntensity: 50.0,
        endIntensity: 105.0,
        steps: 20,
        requestedMode: NomogramMode.population,
        populationPreset: PopulationNomogramSource.excelOperational,
      );

      for (final point in curve) {
        expect(point.lower, greaterThanOrEqualTo(0.1));
        expect(point.mean, greaterThanOrEqualTo(point.lower));
        expect(point.upper, greaterThanOrEqualTo(point.mean));
      }
    });

    test(
      'band values are monotonically decreasing with increasing intensity',
      () {
        final curve = resolveNomogramBandCurve(
          startIntensity: 60.0,
          endIntensity: 100.0,
          steps: 20,
          requestedMode: NomogramMode.population,
          populationPreset: PopulationNomogramSource.excelOperational,
        );

        for (int i = 1; i < curve.length; i++) {
          // Mean should be monotonically non-increasing
          expect(curve[i].mean, lessThanOrEqualTo(curve[i - 1].mean + 0.001));
        }
      },
    );
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('resolveNomogramBands — band ordering invariant', () {
    test('lower <= mean <= upper for population mode', () {
      for (final intensity in [40.0, 60.0, 70.0, 80.0, 90.0, 100.0, 110.0]) {
        final result = resolveNomogramBands(
          intensityPercent: intensity,
          requestedMode: NomogramMode.population,
          populationPreset: PopulationNomogramSource.excelOperational,
        );
        expect(
          result.lower,
          lessThanOrEqualTo(result.mean + 0.001),
          reason: 'lower <= mean at $intensity%',
        );
        expect(
          result.mean,
          lessThanOrEqualTo(result.upper + 0.001),
          reason: 'mean <= upper at $intensity%',
        );
      }
    });

    test('lower <= mean <= upper for hybrid mode', () {
      final indBands = makeIndividualBands();
      final readiness = evaluateIndividualReadiness(
        intensities: List.generate(9, (i) => 50.0 + i * 6.0),
      );

      for (final intensity in [50.0, 65.0, 80.0, 95.0]) {
        final result = resolveNomogramBands(
          intensityPercent: intensity,
          requestedMode: NomogramMode.hybrid,
          populationPreset: PopulationNomogramSource.excelOperational,
          individualBands: indBands,
          readiness: readiness,
        );
        expect(
          result.lower,
          lessThanOrEqualTo(result.mean + 0.001),
          reason: 'lower <= mean at $intensity%',
        );
        expect(
          result.mean,
          lessThanOrEqualTo(result.upper + 0.001),
          reason: 'mean <= upper at $intensity%',
        );
      }
    });
  });
}
