/// Nomogram Engine - Population, individual, and hybrid RMSSD-Slope models.
///
/// Reference: Naranjo Orellana et al. (2019).
library;

import 'dart:math';

import 'package:hrv_slope_app/core/constants/hrv_constants.dart';
import 'package:hrv_slope_app/core/errors/hrv_errors.dart';
import 'package:hrv_slope_app/shared/engine/slope_calculator.dart';

// ---------------------------------------------------------------------------
// Data types
// ---------------------------------------------------------------------------

/// Population nomogram presets supported by the app.
enum PopulationNomogramSource { paperOriginal2019, excelOperational }

/// Source type for a classification or expected-slope model.
enum NomogramModelSource {
  paperOriginal2019,
  excelOperational,
  individual,
  hybrid,
}

extension PopulationNomogramSourceName on PopulationNomogramSource {
  String get presetName {
    switch (this) {
      case PopulationNomogramSource.paperOriginal2019:
        return 'paper_original_2019';
      case PopulationNomogramSource.excelOperational:
        return 'excel_operational';
    }
  }

  NomogramModelSource get modelSource {
    switch (this) {
      case PopulationNomogramSource.paperOriginal2019:
        return NomogramModelSource.paperOriginal2019;
      case PopulationNomogramSource.excelOperational:
        return NomogramModelSource.excelOperational;
    }
  }
}

/// Internal-load interpretation against the expected lower/mean/upper bands.
enum InternalLoadClassification {
  veryHighInternalLoad,
  highOrModerateInternalLoad,
  expectedResponse,
  lowInternalLoadOrFastRecovery,
}

extension InternalLoadClassificationText on InternalLoadClassification {
  String get label {
    switch (this) {
      case InternalLoadClassification.veryHighInternalLoad:
        return 'Very high internal load';
      case InternalLoadClassification.highOrModerateInternalLoad:
        return 'High or moderate internal load';
      case InternalLoadClassification.expectedResponse:
        return 'Expected response';
      case InternalLoadClassification.lowInternalLoadOrFastRecovery:
        return 'Low internal load or fast recovery';
    }
  }

  String get meaning {
    switch (this) {
      case InternalLoadClassification.veryHighInternalLoad:
        return 'Lower than expected recovery for this intensity';
      case InternalLoadClassification.highOrModerateInternalLoad:
        return 'Slower than average recovery for this intensity';
      case InternalLoadClassification.expectedResponse:
        return 'Within expected range for this intensity';
      case InternalLoadClassification.lowInternalLoadOrFastRecovery:
        return 'Faster than expected recovery for this intensity';
    }
  }
}

/// Backward-compatible coarse labels used by Phase 1 tests and storage.
enum SlopeClassification { poor, good, veryGood }

extension SlopeClassificationLabel on SlopeClassification {
  String get label {
    switch (this) {
      case SlopeClassification.poor:
        return 'Poor recovery (high internal load)';
      case SlopeClassification.good:
        return 'Acceptable recovery';
      case SlopeClassification.veryGood:
        return 'Excellent recovery (low internal load)';
    }
  }

  String get shortLabel {
    switch (this) {
      case SlopeClassification.poor:
        return 'MALO';
      case SlopeClassification.good:
        return 'BUENO';
      case SlopeClassification.veryGood:
        return 'MUY BUENO';
    }
  }
}

/// Parameters for the exponential nomogram model:
/// slope = c + a * exp(b * intensity_percent)
class NomogramParams {
  final double a;
  final double b;
  final double c;

  const NomogramParams({required this.a, required this.b, required this.c});

  double evaluate(double intensityPercent) {
    return c + a * exp(b * intensityPercent);
  }

  @override
  String toString() => 'NomogramParams(a: $a, b: $b, c: $c)';
}

/// A single data point for nomogram fitting.
class NomogramPoint {
  final double intensityPercent;
  final double slope;

  const NomogramPoint({required this.intensityPercent, required this.slope});
}

/// Confidence level for an individual nomogram model.
enum IndividualNomogramConfidence { insufficient, initial, acceptable, robust }

/// Compatibility constants for older Phase 1 call sites.
abstract final class NomogramConfidence {
  static const insufficient = IndividualNomogramConfidence.insufficient;
  static const initial = IndividualNomogramConfidence.initial;
  static const acceptable = IndividualNomogramConfidence.acceptable;
  static const robust = IndividualNomogramConfidence.robust;
}

extension IndividualNomogramConfidenceLabel on IndividualNomogramConfidence {
  String get label {
    switch (this) {
      case IndividualNomogramConfidence.insufficient:
        return 'Insufficient data';
      case IndividualNomogramConfidence.initial:
        return 'Initial (limited reliability)';
      case IndividualNomogramConfidence.acceptable:
        return 'Acceptable';
      case IndividualNomogramConfidence.robust:
        return 'Robust';
    }
  }
}

/// Result of individual nomogram fitting.
class NomogramModel {
  final NomogramParams params;
  final double rSquared;
  final int nPoints;
  final int nIntensityRanges;
  final IndividualNomogramConfidence confidenceLevel;

  const NomogramModel({
    required this.params,
    required this.rSquared,
    required this.nPoints,
    required this.nIntensityRanges,
    required this.confidenceLevel,
  });
}

/// A population reference point with lower/mean/upper expected slope.
class NomogramBandPoint {
  final double intensityPercent;
  final double lower;
  final double mean;
  final double upper;

  const NomogramBandPoint({
    required this.intensityPercent,
    required this.lower,
    required this.mean,
    required this.upper,
  });
}

/// Evaluated population bands at one intensity.
class NomogramBandEvaluation {
  final NomogramModelSource modelSource;
  final String presetName;
  final double intensityPercent;
  final double expectedLower;
  final double expectedMean;
  final double expectedUpper;
  final List<String> warnings;

  const NomogramBandEvaluation({
    required this.modelSource,
    required this.presetName,
    required this.intensityPercent,
    required this.expectedLower,
    required this.expectedMean,
    required this.expectedUpper,
    required this.warnings,
  });
}

/// Full classification result against a nomogram model.
class NomogramClassificationResult {
  final NomogramModelSource modelSource;
  final String? presetName;
  final double intensityPercent;
  final double observedSlope;
  final double expectedLower;
  final double expectedMean;
  final double expectedUpper;
  final double residual;
  final double residualPercent;
  final InternalLoadClassification classification;
  final List<String> warnings;

  const NomogramClassificationResult({
    required this.modelSource,
    required this.presetName,
    required this.intensityPercent,
    required this.observedSlope,
    required this.expectedLower,
    required this.expectedMean,
    required this.expectedUpper,
    required this.residual,
    required this.residualPercent,
    required this.classification,
    required this.warnings,
  });
}

/// Hybrid population/individual model result.
class HybridNomogramResult {
  final NomogramModelSource modelSource;
  final double populationExpectedSlope;
  final double? individualExpectedSlope;
  final double expectedSlope;
  final IndividualNomogramConfidence confidence;
  final double individualWeight;
  final double populationWeight;
  final List<String> warnings;

  const HybridNomogramResult({
    required this.modelSource,
    required this.populationExpectedSlope,
    required this.individualExpectedSlope,
    required this.expectedSlope,
    required this.confidence,
    required this.individualWeight,
    required this.populationWeight,
    required this.warnings,
  });
}

// ---------------------------------------------------------------------------
// Population nomogram presets
// ---------------------------------------------------------------------------

const PopulationNomogramSource kDefaultPopulationNomogramSource =
    PopulationNomogramSource.excelOperational;

const List<NomogramBandPoint> _paperOriginal2019Points = [
  NomogramBandPoint(
    intensityPercent: 64.39,
    lower: 0.45,
    mean: 1.51,
    upper: 2.57,
  ),
  NomogramBandPoint(
    intensityPercent: 83.11,
    lower: 0.10,
    mean: 0.29,
    upper: 0.57,
  ),
  NomogramBandPoint(
    intensityPercent: 100.00,
    lower: 0.10,
    mean: 0.28,
    upper: 0.53,
  ),
];

const List<NomogramBandPoint> _excelOperationalPoints = [
  NomogramBandPoint(intensityPercent: 60, lower: 0.64, mean: 1.51, upper: 2.49),
  NomogramBandPoint(intensityPercent: 80, lower: 0.10, mean: 0.34, upper: 0.72),
  NomogramBandPoint(
    intensityPercent: 100,
    lower: 0.10,
    mean: 0.24,
    upper: 0.48,
  ),
];

/// Legacy exponential constants retained for audit comparison only.
const NomogramParams populationCurveMean = NomogramParams(
  a: 2049.016856,
  b: -0.122979,
  c: 0.230654,
);

const NomogramParams populationCurveUpper = NomogramParams(
  a: 821.374424,
  b: -0.099905,
  c: 0.442353,
);

const NomogramParams populationCurveLower = NomogramParams(
  a: 999999.890580,
  b: -0.240530,
  c: 0.100000,
);

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/// Evaluates the selected population preset using monotonic log-linear
/// interpolation between source points and explicit extrapolation warnings.
NomogramBandEvaluation evaluatePopulationNomogramBands(
  double intensityPercent, {
  PopulationNomogramSource source = kDefaultPopulationNomogramSource,
}) {
  final points = _pointsForSource(source);
  final first = points.first;
  final last = points.last;
  final warnings = <String>[];

  if (intensityPercent < first.intensityPercent ||
      intensityPercent > last.intensityPercent) {
    warnings.add(
      'Intensity ${intensityPercent.toStringAsFixed(2)}% is outside the '
      '${first.intensityPercent.toStringAsFixed(2)}-'
      '${last.intensityPercent.toStringAsFixed(2)}% source range for '
      '${source.presetName}; bands are extrapolated.',
    );
  }

  final lower = _interpolateBand(points, intensityPercent, (p) => p.lower);
  final mean = _interpolateBand(points, intensityPercent, (p) => p.mean);
  final upper = _interpolateBand(points, intensityPercent, (p) => p.upper);

  return NomogramBandEvaluation(
    modelSource: source.modelSource,
    presetName: source.presetName,
    intensityPercent: intensityPercent,
    expectedLower: max(kMinSlopeForInterpretation, lower),
    expectedMean: max(kMinSlopeForInterpretation, mean),
    expectedUpper: max(kMinSlopeForInterpretation, upper),
    warnings: warnings,
  );
}

/// Classifies an observed slope against the selected population preset.
///
/// [observedSlope] is clamped to the paper's 0.1 minimum before comparison.
NomogramClassificationResult classifySlopeWithPopulationNomogram(
  double intensityPercent,
  double observedSlope, {
  PopulationNomogramSource source = kDefaultPopulationNomogramSource,
}) {
  final bands = evaluatePopulationNomogramBands(
    intensityPercent,
    source: source,
  );
  return classifySlopeAgainstBands(
    modelSource: bands.modelSource,
    presetName: bands.presetName,
    intensityPercent: intensityPercent,
    observedSlope: observedSlope,
    expectedLower: bands.expectedLower,
    expectedMean: bands.expectedMean,
    expectedUpper: bands.expectedUpper,
    warnings: bands.warnings,
  );
}

/// Classifies an observed slope against supplied lower/mean/upper bands.
NomogramClassificationResult classifySlopeAgainstBands({
  required NomogramModelSource modelSource,
  required String? presetName,
  required double intensityPercent,
  required double observedSlope,
  required double expectedLower,
  required double expectedMean,
  required double expectedUpper,
  List<String> warnings = const [],
}) {
  final interpretedSlope = clampSlopeForInterpretation(observedSlope);
  final residual = computeResidual(interpretedSlope, expectedMean);
  final residualPercent = expectedMean == 0
      ? 0.0
      : residual / expectedMean * 100.0;

  final classification = _classifyAgainstBands(
    interpretedSlope,
    expectedLower,
    expectedMean,
    expectedUpper,
  );

  return NomogramClassificationResult(
    modelSource: modelSource,
    presetName: presetName,
    intensityPercent: intensityPercent,
    observedSlope: interpretedSlope,
    expectedLower: expectedLower,
    expectedMean: expectedMean,
    expectedUpper: expectedUpper,
    residual: residual,
    residualPercent: residualPercent,
    classification: classification,
    warnings: List.unmodifiable(warnings),
  );
}

/// Backward-compatible coarse classifier.
SlopeClassification classifySlopeByPopulationNomogram(
  double intensityPercent,
  double slope,
) {
  final result = classifySlopeWithPopulationNomogram(intensityPercent, slope);
  switch (result.classification) {
    case InternalLoadClassification.veryHighInternalLoad:
    case InternalLoadClassification.highOrModerateInternalLoad:
      return SlopeClassification.poor;
    case InternalLoadClassification.expectedResponse:
      return SlopeClassification.good;
    case InternalLoadClassification.lowInternalLoadOrFastRecovery:
      return SlopeClassification.veryGood;
  }
}

/// Fits an individual nomogram model to observed (intensity, slope) points.
///
/// Model: slope = c + a * exp(b * intensity_percent)
/// Constraints: c >= 0.1, b < 0, a > 0.
NomogramModel fitIndividualNomogram(List<NomogramPoint> points) {
  if (points.length < 3) {
    throw NomogramFitError(
      'Need at least 3 data points for fitting, got ${points.length}.',
    );
  }

  final intensityRanges = _countIntensityZones(points);

  if (intensityRanges < 2) {
    throw NomogramFitError(
      'Need at least 2 distinct intensity zones, got $intensityRanges.',
    );
  }

  final maxSlope = points.map((p) => p.slope).reduce((a, b) => a > b ? a : b);
  final minSlope = points.map((p) => p.slope).reduce((a, b) => a < b ? a : b);

  final initialGuesses = [
    (maxSlope - kMinSlopeForInterpretation, -0.05, kMinSlopeForInterpretation),
    (maxSlope * 10, -0.10, minSlope),
    (100.0, -0.08, kMinSlopeForInterpretation),
    (1000.0, -0.12, 0.2),
    (maxSlope * 50, -0.15, kMinSlopeForInterpretation),
  ];

  double bestA = 1.0, bestB = -0.05, bestC = kMinSlopeForInterpretation;
  double bestCost = double.infinity;

  for (final (initA, initB, initC) in initialGuesses) {
    double a = initA > 0.01 ? initA : 1.0;
    double b = initB;
    double c = initC >= kMinSlopeForInterpretation
        ? initC
        : kMinSlopeForInterpretation;

    double learningRate = 0.0001;
    double prevCost = _cost(points, a, b, c);

    const int maxIterations = 5000;
    const double convergenceThreshold = 1e-10;

    for (int iter = 0; iter < maxIterations; iter++) {
      double dA = 0, dB = 0, dC = 0;

      for (final p in points) {
        final predicted = c + a * exp(b * p.intensityPercent);
        final residual = predicted - p.slope;
        final expTerm = exp(b * p.intensityPercent);

        dA += 2 * residual * expTerm;
        dB += 2 * residual * a * p.intensityPercent * expTerm;
        dC += 2 * residual;
      }

      dA /= points.length;
      dB /= points.length;
      dC /= points.length;

      final gradNorm = sqrt(dA * dA + dB * dB + dC * dC);
      if (gradNorm > 1e6) {
        final scale = 1e6 / gradNorm;
        dA *= scale;
        dB *= scale;
        dC *= scale;
      }

      final constrainedA = max(0.01, a - learningRate * dA);
      final constrainedB = min(-0.001, b - learningRate * dB);
      final constrainedC = max(
        kMinSlopeForInterpretation,
        c - learningRate * dC,
      );

      final newCost = _cost(points, constrainedA, constrainedB, constrainedC);

      if (newCost < prevCost) {
        a = constrainedA;
        b = constrainedB;
        c = constrainedC;

        final relChange = (prevCost - newCost) / prevCost;
        prevCost = newCost;

        if (relChange.abs() < convergenceThreshold) break;

        learningRate *= 1.05;
      } else {
        learningRate *= 0.5;
        if (learningRate < 1e-12) break;
      }
    }

    if (prevCost < bestCost) {
      bestA = a;
      bestB = b;
      bestC = c;
      bestCost = prevCost;
    }
  }

  final rSquared = _computeRSquared(points, bestA, bestB, bestC);
  final confidence = evaluateIndividualNomogramConfidence(points);

  return NomogramModel(
    params: NomogramParams(a: bestA, b: bestB, c: bestC),
    rSquared: rSquared,
    nPoints: points.length,
    nIntensityRanges: intensityRanges,
    confidenceLevel: confidence,
  );
}

/// Evaluates individual nomogram confidence without requiring model fitting.
IndividualNomogramConfidence evaluateIndividualNomogramConfidence(
  List<NomogramPoint> points,
) {
  final nPoints = points.length;
  final zoneCounts = _intensityZoneCounts(points);
  final representedZones = zoneCounts.values.where((count) => count > 0).length;
  final hasAllZones = zoneCounts.values.every((count) => count > 0);
  final hasExtremeDistributionProblem =
      hasAllZones && zoneCounts.values.any((count) => count < 2);

  if (nPoints < 6 || representedZones < 2) {
    return IndividualNomogramConfidence.insufficient;
  }

  if (nPoints <= 8 && representedZones >= 2) {
    return IndividualNomogramConfidence.initial;
  }

  if (nPoints <= 11 && hasAllZones) {
    return IndividualNomogramConfidence.acceptable;
  }

  if (nPoints >= 12 && hasAllZones && !hasExtremeDistributionProblem) {
    return IndividualNomogramConfidence.robust;
  }

  return IndividualNomogramConfidence.insufficient;
}

/// Returns the expected slope at a given intensity using a fitted model.
double expectedSlopeAtIntensity(NomogramParams model, double intensityPercent) {
  final expected = model.evaluate(intensityPercent);
  return max(kMinSlopeForInterpretation, expected);
}

/// Computes the residual between observed and expected slope.
double computeResidual(double observedSlope, double expectedSlope) {
  return observedSlope - expectedSlope;
}

/// Returns the hybrid weight for an individual confidence level.
double individualWeightForConfidence(IndividualNomogramConfidence confidence) {
  return switch (confidence) {
    IndividualNomogramConfidence.insufficient => 0.0,
    IndividualNomogramConfidence.initial => 0.3,
    IndividualNomogramConfidence.acceptable => 0.7,
    IndividualNomogramConfidence.robust => 1.0,
  };
}

/// Blends population and individual expected slopes based on confidence.
double computeHybridExpectedSlope({
  required double populationExpected,
  required double individualExpected,
  required IndividualNomogramConfidence confidence,
}) {
  final weight = individualWeightForConfidence(confidence);
  return weight * individualExpected + (1.0 - weight) * populationExpected;
}

/// Builds a hybrid expected-slope result with explicit source and weights.
HybridNomogramResult buildHybridNomogramResult({
  required double populationExpected,
  required double? individualExpected,
  required IndividualNomogramConfidence confidence,
}) {
  final warnings = <String>[];

  if (individualExpected == null ||
      confidence == IndividualNomogramConfidence.insufficient) {
    if (individualExpected == null) {
      warnings.add('Individual expected slope is unavailable.');
    }
    return HybridNomogramResult(
      modelSource: NomogramModelSource.excelOperational,
      populationExpectedSlope: populationExpected,
      individualExpectedSlope: individualExpected,
      expectedSlope: populationExpected,
      confidence: confidence,
      individualWeight: 0.0,
      populationWeight: 1.0,
      warnings: warnings,
    );
  }

  final individualWeight = individualWeightForConfidence(confidence);
  final populationWeight = 1.0 - individualWeight;
  final expected =
      individualWeight * individualExpected +
      populationWeight * populationExpected;

  return HybridNomogramResult(
    modelSource: confidence == IndividualNomogramConfidence.robust
        ? NomogramModelSource.individual
        : NomogramModelSource.hybrid,
    populationExpectedSlope: populationExpected,
    individualExpectedSlope: individualExpected,
    expectedSlope: expected,
    confidence: confidence,
    individualWeight: individualWeight,
    populationWeight: populationWeight,
    warnings: warnings,
  );
}

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

List<NomogramBandPoint> _pointsForSource(PopulationNomogramSource source) {
  switch (source) {
    case PopulationNomogramSource.paperOriginal2019:
      return _paperOriginal2019Points;
    case PopulationNomogramSource.excelOperational:
      return _excelOperationalPoints;
  }
}

double _interpolateBand(
  List<NomogramBandPoint> points,
  double intensityPercent,
  double Function(NomogramBandPoint point) read,
) {
  final segment = _segmentForIntensity(points, intensityPercent);
  final p0 = segment.$1;
  final p1 = segment.$2;
  final y0 = max(kMinSlopeForInterpretation, read(p0));
  final y1 = max(kMinSlopeForInterpretation, read(p1));

  if ((p1.intensityPercent - p0.intensityPercent).abs() < 1e-9) {
    return y0;
  }

  final t =
      (intensityPercent - p0.intensityPercent) /
      (p1.intensityPercent - p0.intensityPercent);
  final logY = log(y0) + t * (log(y1) - log(y0));
  return exp(logY);
}

(NomogramBandPoint, NomogramBandPoint) _segmentForIntensity(
  List<NomogramBandPoint> points,
  double intensityPercent,
) {
  if (intensityPercent <= points.first.intensityPercent) {
    return (points[0], points[1]);
  }

  if (intensityPercent >= points.last.intensityPercent) {
    return (points[points.length - 2], points.last);
  }

  for (int i = 0; i < points.length - 1; i++) {
    if (intensityPercent >= points[i].intensityPercent &&
        intensityPercent <= points[i + 1].intensityPercent) {
      return (points[i], points[i + 1]);
    }
  }

  return (points[points.length - 2], points.last);
}

InternalLoadClassification _classifyAgainstBands(
  double observedSlope,
  double expectedLower,
  double expectedMean,
  double expectedUpper,
) {
  const epsilon = 1e-9;
  if (observedSlope < expectedLower - epsilon) {
    return InternalLoadClassification.veryHighInternalLoad;
  }
  if (observedSlope < expectedMean - epsilon) {
    return InternalLoadClassification.highOrModerateInternalLoad;
  }
  if (observedSlope <= expectedUpper + epsilon) {
    return InternalLoadClassification.expectedResponse;
  }
  return InternalLoadClassification.lowInternalLoadOrFastRecovery;
}

double _cost(List<NomogramPoint> points, double a, double b, double c) {
  double total = 0;
  for (final p in points) {
    final predicted = c + a * exp(b * p.intensityPercent);
    final diff = predicted - p.slope;
    total += diff * diff;
  }
  return total / points.length;
}

double _computeRSquared(
  List<NomogramPoint> points,
  double a,
  double b,
  double c,
) {
  final meanSlope =
      points.map((p) => p.slope).reduce((x, y) => x + y) / points.length;

  double ssRes = 0, ssTot = 0;
  for (final p in points) {
    final predicted = c + a * exp(b * p.intensityPercent);
    ssRes += (p.slope - predicted) * (p.slope - predicted);
    ssTot += (p.slope - meanSlope) * (p.slope - meanSlope);
  }

  if (ssTot == 0) return 1.0;
  return 1.0 - (ssRes / ssTot);
}

int _countIntensityZones(List<NomogramPoint> points) {
  return _intensityZoneCounts(points).values.where((count) => count > 0).length;
}

Map<String, int> _intensityZoneCounts(List<NomogramPoint> points) {
  final counts = {'low': 0, 'medium': 0, 'high': 0};

  for (final p in points) {
    if (p.intensityPercent < 70) {
      counts['low'] = counts['low']! + 1;
    } else if (p.intensityPercent <= 90) {
      counts['medium'] = counts['medium']! + 1;
    } else {
      counts['high'] = counts['high']! + 1;
    }
  }

  return counts;
}
