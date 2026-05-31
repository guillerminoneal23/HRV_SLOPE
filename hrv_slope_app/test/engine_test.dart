// Comprehensive tests for the HRV Slope calculation engine.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hrv_slope_app/core/constants/hrv_constants.dart';
import 'package:hrv_slope_app/core/errors/hrv_errors.dart';
import 'package:hrv_slope_app/shared/engine/nomogram_engine.dart';
import 'package:hrv_slope_app/shared/engine/rmssd_calculator.dart';
import 'package:hrv_slope_app/shared/engine/rr_quality.dart';
import 'package:hrv_slope_app/shared/engine/slope_calculator.dart';
import 'package:hrv_slope_app/shared/engine/statistics.dart';

void main() {
  group('computeRmssd', () {
    test('computes RMSSD correctly with known RR intervals', () {
      final rr = [800.0, 810.0, 790.0, 815.0, 800.0];
      final rmssd = computeRmssd(rr);
      expect(rmssd, closeTo(18.371, 0.001));
    });

    test('computes RMSSD with constant intervals', () {
      final rr = [800.0, 800.0, 800.0, 800.0];
      final rmssd = computeRmssd(rr);
      expect(rmssd, equals(0.0));
    });

    test('computes RMSSD with two intervals', () {
      final rr = [800.0, 850.0];
      final rmssd = computeRmssd(rr);
      expect(rmssd, equals(50.0));
    });

    test('computes RMSSD matching typical exercise values', () {
      final rng = Random(42);
      final rr = List.generate(60, (_) => 500.0 + (rng.nextDouble() - 0.5) * 8);
      final rmssd = computeRmssd(rr);
      expect(rmssd, greaterThan(0));
      expect(rmssd, lessThan(10));
    });

    test('throws InsufficientDataError with fewer than 2 intervals', () {
      expect(
        () => computeRmssd([800.0]),
        throwsA(isA<InsufficientDataError>()),
      );
      expect(() => computeRmssd([]), throwsA(isA<InsufficientDataError>()));
    });

    test('throws InvalidDataError with non-positive RR interval', () {
      expect(
        () => computeRmssd([800.0, 0.0, 810.0]),
        throwsA(isA<InvalidDataError>()),
      );
      expect(
        () => computeRmssd([800.0, -100.0, 810.0]),
        throwsA(isA<InvalidDataError>()),
      );
    });

    test('validated RMSSD rejects invalid RR quality', () {
      expect(
        () => computeRmssdForValidatedWindow([800.0, 810.0, 790.0]),
        throwsA(isA<InvalidDataError>()),
      );
    });
  });

  group('RecoveryWindow and computeSlopeForRecoveryWindow', () {
    test('slope window 5-10 uses t = 10', () {
      final result = computeSlopeForRecoveryWindow(
        rmssdRecovery: 19.0,
        rmssdExercise: 4.0,
        recoveryWindow: const RecoveryWindow(startMin: 5, endMin: 10),
      );

      expect(result.recoveryWindowDurationMin, equals(5));
      expect(result.recoveryTimeForSlopeMin, equals(10));
      expect(result.rawSlope, closeTo(1.5, 0.001));
    });

    test('slope window 10-15 uses t = 15', () {
      final result = computeSlopeForRecoveryWindow(
        rmssdRecovery: 19.0,
        rmssdExercise: 4.0,
        recoveryWindow: const RecoveryWindow(startMin: 10, endMin: 15),
      );

      expect(result.recoveryWindowDurationMin, equals(5));
      expect(result.recoveryTimeForSlopeMin, equals(15));
      expect(result.rawSlope, closeTo(1.0, 0.001));
    });

    test('slope window 25-30 uses t = 30', () {
      final result = computeSlopeForRecoveryWindow(
        rmssdRecovery: 19.0,
        rmssdExercise: 4.0,
        recoveryWindow: const RecoveryWindow(startMin: 25, endMin: 30),
      );

      expect(result.recoveryWindowDurationMin, equals(5));
      expect(result.recoveryTimeForSlopeMin, equals(30));
      expect(result.rawSlope, closeTo(0.5, 0.001));
    });

    test('window 0-5 is invalid', () {
      expect(
        () => computeSlopeForRecoveryWindow(
          rmssdRecovery: 10,
          rmssdExercise: 4,
          recoveryWindow: const RecoveryWindow(startMin: 0, endMin: 5),
        ),
        throwsA(isA<InvalidRecoveryTimeError>()),
      );
    });

    test('window 5-9 is invalid because duration is not 5', () {
      expect(
        () => computeSlopeForRecoveryWindow(
          rmssdRecovery: 10,
          rmssdExercise: 4,
          recoveryWindow: const RecoveryWindow(startMin: 5, endMin: 9),
        ),
        throwsA(isA<InvalidRecoveryTimeError>()),
      );
    });

    test('window 28-33 is invalid because it ends after 30', () {
      expect(
        () => computeSlopeForRecoveryWindow(
          rmssdRecovery: 10,
          rmssdExercise: 4,
          recoveryWindow: const RecoveryWindow(startMin: 28, endMin: 33),
        ),
        throwsA(isA<InvalidRecoveryTimeError>()),
      );
    });

    test('negative start or end times are invalid', () {
      expect(
        () => const RecoveryWindow(startMin: -1, endMin: 5).validate(),
        throwsA(isA<InvalidRecoveryTimeError>()),
      );
      expect(
        () => const RecoveryWindow(startMin: 5, endMin: -10).validate(),
        throwsA(isA<InvalidRecoveryTimeError>()),
      );
    });

    test('end must be greater than start', () {
      expect(
        () => const RecoveryWindow(startMin: 10, endMin: 10).validate(),
        throwsA(isA<InvalidRecoveryTimeError>()),
      );
    });

    test('fallback RMSSD exercise sets a flag', () {
      final result = computeSlopeForRecoveryWindow(
        rmssdRecovery: 10.07,
        rmssdExercise: null,
        recoveryWindow: const RecoveryWindow(startMin: 10, endMin: 15),
      );

      expect(result.usedFallback, isTrue);
      expect(result.rmssdExerciseUsed, equals(kDefaultRmssdExerciseMs));
      expect(result.rawSlope, closeTo(0.4047, 0.001));
    });

    test('measured RMSSD exercise does not set fallback flag', () {
      final result = computeSlopeForRecoveryWindow(
        rmssdRecovery: 19.56,
        rmssdExercise: 3.92,
        recoveryWindow: const RecoveryWindow(startMin: 5, endMin: 10),
      );

      expect(result.usedFallback, isFalse);
      expect(result.rmssdExerciseUsed, equals(3.92));
      expect(result.rawSlope, closeTo(1.564, 0.001));
    });

    test('raw slope and interpreted slope are both preserved', () {
      final result = computeSlopeForRecoveryWindow(
        rmssdRecovery: 4.5,
        rmssdExercise: 4.0,
        recoveryWindow: const RecoveryWindow(startMin: 5, endMin: 10),
      );

      expect(result.rawSlope, closeTo(0.05, 0.001));
      expect(result.interpretedSlope, equals(0.1));
    });
  });

  group('computeSlope legacy API', () {
    test('computes slope with measured RMSSD exercise', () {
      final result = computeSlope(19.56, 3.92, 10.0);
      expect(result.rawSlope, closeTo(1.564, 0.001));
      expect(result.interpretedSlope, closeTo(1.564, 0.001));
      expect(result.usedFallback, isFalse);
      expect(result.rmssdExerciseUsed, equals(3.92));
    });

    test('throws InvalidRecoveryTimeError when time <= 5', () {
      expect(
        () => computeSlope(20.0, 4.0, 5.0),
        throwsA(isA<InvalidRecoveryTimeError>()),
      );
      expect(
        () => computeSlope(20.0, 4.0, 0.0),
        throwsA(isA<InvalidRecoveryTimeError>()),
      );
    });

    test('throws InvalidDataError when recovery RMSSD < 0', () {
      expect(
        () => computeSlope(-1.0, 4.0, 10.0),
        throwsA(isA<InvalidDataError>()),
      );
    });
  });

  group('clampSlopeForInterpretation', () {
    test('preserves values above 0.1', () {
      expect(clampSlopeForInterpretation(1.51), equals(1.51));
      expect(clampSlopeForInterpretation(0.29), equals(0.29));
      expect(clampSlopeForInterpretation(0.10), equals(0.10));
    });

    test('clamps values below 0.1 to 0.1', () {
      expect(clampSlopeForInterpretation(0.05), equals(0.1));
      expect(clampSlopeForInterpretation(0.0), equals(0.1));
      expect(clampSlopeForInterpretation(-0.5), equals(0.1));
    });
  });

  group('computeItlIndex', () {
    test('ITL = 1/slope for typical values', () {
      expect(computeItlIndex(2.49), closeTo(0.4016, 0.001));
      expect(computeItlIndex(1.51), closeTo(0.6623, 0.001));
      expect(computeItlIndex(0.34), closeTo(2.9412, 0.001));
      expect(computeItlIndex(0.10), closeTo(10.0, 0.001));
    });
  });

  group('population nomogram stability', () {
    const intensities = <double>[
      40,
      50,
      60,
      64,
      70,
      75,
      80,
      83,
      90,
      100,
      110,
      120,
      130,
    ];

    test('excel operational bands are ordered, monotonic, and sane', () {
      var previous = evaluatePopulationNomogramBands(intensities.first);

      for (final intensity in intensities) {
        final bands = evaluatePopulationNomogramBands(intensity);
        expect(bands.expectedUpper, greaterThanOrEqualTo(bands.expectedMean));
        expect(bands.expectedMean, greaterThanOrEqualTo(bands.expectedLower));
        expect(bands.expectedLower, greaterThanOrEqualTo(0.1));

        expect(bands.expectedUpper, lessThan(20));
        expect(bands.expectedMean, lessThan(20));
        expect(bands.expectedLower, lessThan(20));

        if (intensity != intensities.first) {
          expect(
            bands.expectedUpper,
            lessThanOrEqualTo(previous.expectedUpper),
          );
          expect(bands.expectedMean, lessThanOrEqualTo(previous.expectedMean));
          expect(
            bands.expectedLower,
            lessThanOrEqualTo(previous.expectedLower),
          );
        }
        previous = bands;
      }
    });

    test(
      'paper original preset remains available and exact at source points',
      () {
        final bands = evaluatePopulationNomogramBands(
          64.39,
          source: PopulationNomogramSource.paperOriginal2019,
        );

        expect(bands.presetName, equals('paper_original_2019'));
        expect(bands.expectedLower, closeTo(0.45, 0.001));
        expect(bands.expectedMean, closeTo(1.51, 0.001));
        expect(bands.expectedUpper, closeTo(2.57, 0.001));
      },
    );

    test('values outside validated source range emit warnings', () {
      final low = evaluatePopulationNomogramBands(40);
      final high = evaluatePopulationNomogramBands(130);

      expect(low.warnings, isNotEmpty);
      expect(high.warnings, isNotEmpty);
    });

    test('default population preset is explicit and excel operational', () {
      expect(
        kDefaultPopulationNomogramSource,
        equals(PopulationNomogramSource.excelOperational),
      );
      expect(kDefaultPopulationNomogramPresetName, equals('excel_operational'));
    });
  });

  group('population nomogram classification', () {
    test('observed below lower -> very high internal load', () {
      final result = classifySlopeWithPopulationNomogram(60, 0.50);
      expect(
        result.classification,
        equals(InternalLoadClassification.veryHighInternalLoad),
      );
    });

    test(
      'observed between lower and mean -> high or moderate internal load',
      () {
        final result = classifySlopeWithPopulationNomogram(80, 0.20);
        expect(
          result.classification,
          equals(InternalLoadClassification.highOrModerateInternalLoad),
        );
      },
    );

    test('observed between mean and upper -> expected response', () {
      final result = classifySlopeWithPopulationNomogram(80, 0.50);
      expect(
        result.classification,
        equals(InternalLoadClassification.expectedResponse),
      );
    });

    test('observed above upper -> low internal load or fast recovery', () {
      final result = classifySlopeWithPopulationNomogram(80, 1.0);
      expect(
        result.classification,
        equals(InternalLoadClassification.lowInternalLoadOrFastRecovery),
      );
    });

    test('residual and residual percent are correct', () {
      final result = classifySlopeWithPopulationNomogram(80, 0.51);
      expect(result.expectedMean, closeTo(0.34, 0.001));
      expect(result.residual, closeTo(0.17, 0.001));
      expect(result.residualPercent, closeTo(50, 0.01));
    });

    test('classification result includes model source and expected bands', () {
      final result = classifySlopeWithPopulationNomogram(60, 1.51);
      expect(result.modelSource, equals(NomogramModelSource.excelOperational));
      expect(result.presetName, equals('excel_operational'));
      expect(result.intensityPercent, equals(60));
      expect(result.observedSlope, equals(1.51));
      expect(result.expectedLower, closeTo(0.64, 0.001));
      expect(result.expectedMean, closeTo(1.51, 0.001));
      expect(result.expectedUpper, closeTo(2.49, 0.001));
    });

    test(
      'classification uses interpreted slope when raw slope is below 0.1',
      () {
        final result = classifySlopeWithPopulationNomogram(100, 0.02);
        expect(result.observedSlope, equals(0.1));
        expect(
          result.classification,
          equals(InternalLoadClassification.highOrModerateInternalLoad),
        );
      },
    );

    test('classification emits warning outside source range', () {
      final result = classifySlopeWithPopulationNomogram(130, 0.2);
      expect(result.warnings, isNotEmpty);
    });

    test('legacy coarse classifier maps band result', () {
      expect(
        classifySlopeByPopulationNomogram(80, 0.2),
        equals(SlopeClassification.poor),
      );
      expect(
        classifySlopeByPopulationNomogram(80, 0.5),
        equals(SlopeClassification.good),
      );
      expect(
        classifySlopeByPopulationNomogram(80, 1.0),
        equals(SlopeClassification.veryGood),
      );
    });
  });

  group('fitIndividualNomogram', () {
    test('fits exponential to synthetic data', () {
      final points = [
        const NomogramPoint(intensityPercent: 55, slope: 3.0),
        const NomogramPoint(intensityPercent: 60, slope: 2.5),
        const NomogramPoint(intensityPercent: 65, slope: 1.8),
        const NomogramPoint(intensityPercent: 70, slope: 1.2),
        const NomogramPoint(intensityPercent: 80, slope: 0.5),
        const NomogramPoint(intensityPercent: 85, slope: 0.35),
        const NomogramPoint(intensityPercent: 90, slope: 0.25),
        const NomogramPoint(intensityPercent: 95, slope: 0.15),
        const NomogramPoint(intensityPercent: 100, slope: 0.12),
      ];

      final model = fitIndividualNomogram(points);

      expect(model.params.a, greaterThan(0));
      expect(model.params.b, lessThan(0));
      expect(model.params.c, greaterThanOrEqualTo(kMinSlopeForInterpretation));
      expect(model.rSquared, greaterThan(0.5));
      expect(model.nPoints, equals(9));
      expect(model.nIntensityRanges, equals(3));
      expect(
        model.confidenceLevel,
        equals(IndividualNomogramConfidence.acceptable),
      );
    });

    test('produces decreasing slope with increasing intensity', () {
      final points = [
        const NomogramPoint(intensityPercent: 60, slope: 1.51),
        const NomogramPoint(intensityPercent: 80, slope: 0.34),
        const NomogramPoint(intensityPercent: 100, slope: 0.24),
      ];

      final model = fitIndividualNomogram(points);
      final s60 = expectedSlopeAtIntensity(model.params, 60);
      final s80 = expectedSlopeAtIntensity(model.params, 80);
      final s100 = expectedSlopeAtIntensity(model.params, 100);

      expect(s60, greaterThan(s80));
      expect(s80, greaterThanOrEqualTo(s100));
    });

    test('throws with fewer than 3 points', () {
      expect(
        () => fitIndividualNomogram([
          const NomogramPoint(intensityPercent: 60, slope: 1.5),
          const NomogramPoint(intensityPercent: 80, slope: 0.3),
        ]),
        throwsA(isA<NomogramFitError>()),
      );
    });

    test('throws with fewer than 2 intensity zones', () {
      expect(
        () => fitIndividualNomogram([
          const NomogramPoint(intensityPercent: 60, slope: 1.5),
          const NomogramPoint(intensityPercent: 62, slope: 1.3),
          const NomogramPoint(intensityPercent: 65, slope: 1.1),
        ]),
        throwsA(isA<NomogramFitError>()),
      );
    });
  });

  group('individual nomogram confidence', () {
    test('5 sessions -> insufficient', () {
      expect(
        evaluateIndividualNomogramConfidence(_points([60, 65, 75, 80, 95])),
        equals(IndividualNomogramConfidence.insufficient),
      );
    });

    test('6 sessions with only one intensity zone -> insufficient', () {
      expect(
        evaluateIndividualNomogramConfidence(_points([60, 61, 62, 63, 64, 65])),
        equals(IndividualNomogramConfidence.insufficient),
      );
    });

    test('6-8 sessions with 2 zones -> initial', () {
      expect(
        evaluateIndividualNomogramConfidence(_points([60, 62, 65, 75, 80, 85])),
        equals(IndividualNomogramConfidence.initial),
      );
    });

    test('9-11 sessions with low, medium, high -> acceptable', () {
      expect(
        evaluateIndividualNomogramConfidence(
          _points([60, 62, 65, 75, 80, 85, 92, 95, 100]),
        ),
        equals(IndividualNomogramConfidence.acceptable),
      );
    });

    test('12+ sessions with low, medium, high -> robust', () {
      expect(
        evaluateIndividualNomogramConfidence(
          _points([60, 62, 65, 68, 75, 80, 85, 88, 92, 95, 100, 105]),
        ),
        equals(IndividualNomogramConfidence.robust),
      );
    });
  });

  group('expected slope, residuals, and hybrid nomogram', () {
    test('expectedSlopeAtIntensity never returns below 0.1', () {
      final sVeryHigh = expectedSlopeAtIntensity(populationCurveMean, 200);
      expect(sVeryHigh, greaterThanOrEqualTo(0.1));
    });

    test('computeResidual handles positive, negative, and zero residuals', () {
      expect(computeResidual(2.0, 1.5), equals(0.5));
      expect(computeResidual(0.2, 0.5), equals(-0.3));
      expect(computeResidual(1.0, 1.0), equals(0.0));
    });

    test('hybrid weights match confidence levels', () {
      expect(
        individualWeightForConfidence(
          IndividualNomogramConfidence.insufficient,
        ),
        equals(0.0),
      );
      expect(
        individualWeightForConfidence(IndividualNomogramConfidence.initial),
        equals(0.3),
      );
      expect(
        individualWeightForConfidence(IndividualNomogramConfidence.acceptable),
        equals(0.7),
      );
      expect(
        individualWeightForConfidence(IndividualNomogramConfidence.robust),
        equals(1.0),
      );
    });

    test('computeHybridExpectedSlope blends by confidence', () {
      expect(
        computeHybridExpectedSlope(
          populationExpected: 1.5,
          individualExpected: 2.0,
          confidence: IndividualNomogramConfidence.insufficient,
        ),
        equals(1.5),
      );
      expect(
        computeHybridExpectedSlope(
          populationExpected: 1.0,
          individualExpected: 2.0,
          confidence: IndividualNomogramConfidence.initial,
        ),
        closeTo(1.3, 0.001),
      );
      expect(
        computeHybridExpectedSlope(
          populationExpected: 1.0,
          individualExpected: 2.0,
          confidence: IndividualNomogramConfidence.acceptable,
        ),
        closeTo(1.7, 0.001),
      );
      expect(
        computeHybridExpectedSlope(
          populationExpected: 1.0,
          individualExpected: 2.0,
          confidence: IndividualNomogramConfidence.robust,
        ),
        equals(2.0),
      );
    });

    test('individual model is not used alone unless confidence is robust', () {
      final initial = buildHybridNomogramResult(
        populationExpected: 1.0,
        individualExpected: 2.0,
        confidence: IndividualNomogramConfidence.initial,
      );
      final robust = buildHybridNomogramResult(
        populationExpected: 1.0,
        individualExpected: 2.0,
        confidence: IndividualNomogramConfidence.robust,
      );

      expect(initial.modelSource, equals(NomogramModelSource.hybrid));
      expect(initial.expectedSlope, closeTo(1.3, 0.001));
      expect(robust.modelSource, equals(NomogramModelSource.individual));
      expect(robust.expectedSlope, equals(2.0));
    });

    test(
      'hybrid result includes population and individual expected slopes',
      () {
        final result = buildHybridNomogramResult(
          populationExpected: 0.34,
          individualExpected: 0.50,
          confidence: IndividualNomogramConfidence.acceptable,
        );

        expect(result.populationExpectedSlope, equals(0.34));
        expect(result.individualExpectedSlope, equals(0.50));
        expect(result.individualWeight, equals(0.7));
        expect(result.populationWeight, closeTo(0.3, 0.001));
      },
    );
  });

  group('assessRrQuality', () {
    test('valid 5-minute RR sequence -> valid', () {
      final report = assessRrQuality(List.filled(300, 1000.0));
      expect(report.qualityFlag, equals(RrQualityFlag.valid));
      expect(report.rrCount, equals(300));
      expect(report.recordingDurationSec, equals(300));
      expect(report.artifactCountEstimate, equals(0));
    });

    test('empty RR sequence -> invalid', () {
      final report = assessRrQuality([]);
      expect(report.qualityFlag, equals(RrQualityFlag.invalid));
    });

    test('one RR interval -> invalid', () {
      final report = assessRrQuality([1000.0]);
      expect(report.qualityFlag, equals(RrQualityFlag.invalid));
    });

    test('duration below 300 sec -> invalid', () {
      final report = assessRrQuality(List.filled(299, 1000.0));
      expect(report.qualityFlag, equals(RrQualityFlag.invalid));
    });

    test('RR below 300 ms counted as artifact', () {
      final rr = List<double>.filled(300, 1000)..[0] = 299;
      final report = assessRrQuality(rr);
      expect(report.artifactCountEstimate, equals(1));
    });

    test('RR above 2200 ms counted as artifact', () {
      final rr = List<double>.filled(300, 1000)..[0] = 2201;
      final report = assessRrQuality(rr);
      expect(report.artifactCountEstimate, equals(1));
    });

    test('artifact percent > 5% -> warning', () {
      final rr = List<double>.filled(320, 1000);
      for (var i = 0; i < 20; i++) {
        rr[i] = 299;
      }
      final report = assessRrQuality(rr);
      expect(report.artifactPercentEstimate, greaterThan(5));
      expect(report.qualityFlag, equals(RrQualityFlag.warning));
    });

    test('artifact percent > 10% -> invalid', () {
      final rr = List<double>.filled(340, 1000);
      for (var i = 0; i < 40; i++) {
        rr[i] = 299;
      }
      final report = assessRrQuality(rr);
      expect(report.artifactPercentEstimate, greaterThan(10));
      expect(report.qualityFlag, equals(RrQualityFlag.invalid));
    });

    test(
      'validated RMSSD accepts warning quality but rejects invalid quality',
      () {
        final warningRr = List<double>.filled(320, 1000);
        for (var i = 0; i < 20; i++) {
          warningRr[i] = 299;
        }
        final invalidRr = List<double>.filled(299, 1000);

        expect(computeRmssdForValidatedWindow(warningRr), isA<double>());
        expect(
          () => computeRmssdForValidatedWindow(invalidRr),
          throwsA(isA<InvalidDataError>()),
        );
      },
    );
  });

  group('rollingAverage', () {
    test('computes rolling average with full window', () {
      final values = [
        1.0,
        2.0,
        3.0,
        4.0,
        5.0,
        6.0,
        7.0,
      ].map<double?>((v) => v).toList();
      final result = rollingAverage(values, 3);

      expect(result[0], closeTo(1.0, 0.001));
      expect(result[1], closeTo(1.5, 0.001));
      expect(result[2], closeTo(2.0, 0.001));
      expect(result[3], closeTo(3.0, 0.001));
      expect(result[6], closeTo(6.0, 0.001));
    });

    test('handles null values in list', () {
      final values = <double?>[1.0, null, 3.0, null, 5.0];
      final result = rollingAverage(values, 3);

      expect(result[0], closeTo(1.0, 0.001));
      expect(result[1], closeTo(1.0, 0.001));
      expect(result[2], closeTo(2.0, 0.001));
    });

    test('returns empty for empty input', () {
      expect(rollingAverage([], 7), isEmpty);
    });
  });

  group('detectFatigueFlags', () {
    test('detects consecutive negative residuals', () {
      final sessions = List.generate(5, (i) {
        return SessionSummary(
          date: DateTime(2024, 1, i + 1),
          slopeInterpreted: 0.3,
          intensityPercent: 70,
          expectedSlope: 1.0,
        );
      });

      final flags = detectFatigueFlags(sessions);
      expect(flags.any((f) => f.severity == FatigueSeverity.alert), isTrue);
    });

    test('no flags when recovery is normal', () {
      final sessions = List.generate(5, (i) {
        return SessionSummary(
          date: DateTime(2024, 1, i + 1),
          slopeInterpreted: 1.5,
          intensityPercent: 60,
          expectedSlope: 1.5,
        );
      });

      final flags = detectFatigueFlags(sessions);
      final alerts = flags
          .where((f) => f.severity == FatigueSeverity.alert)
          .toList();
      expect(alerts, isEmpty);
    });

    test('returns empty for too few sessions', () {
      expect(detectFatigueFlags([]), isEmpty);
      expect(
        detectFatigueFlags([
          SessionSummary(
            date: DateTime(2024, 1, 1),
            slopeInterpreted: 0.2,
            intensityPercent: 80,
          ),
        ]),
        isEmpty,
      );
    });
  });
}

List<NomogramPoint> _points(List<double> intensities) {
  return [
    for (final intensity in intensities)
      NomogramPoint(
        intensityPercent: intensity,
        slope: max(0.1, 4.0 * exp(-0.03 * intensity)),
      ),
  ];
}
