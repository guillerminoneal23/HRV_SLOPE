/// Nomogram band resolver — single entry point for all consumers.
///
/// Resolves which model (population, hybrid, individual) to use and returns
/// unified lower/mean/upper bands at any intensity. In hybrid mode, the three
/// visible bands ARE the blend — no extra overlay curves.
library;

import 'dart:math';

import 'package:hrv_slope_app/core/constants/hrv_constants.dart';
import 'package:hrv_slope_app/shared/engine/nomogram_engine.dart';
import 'package:hrv_slope_app/shared/engine/nomogram_mode.dart';

// ---------------------------------------------------------------------------
// Resolved bands model
// ---------------------------------------------------------------------------

/// The resolved nomogram bands at a specific intensity, after mode resolution.
///
/// These are the three curves that should be painted on the chart.
/// In hybrid mode, [lower], [mean], and [upper] already reflect the blend.
class ResolvedNomogramBands {
  /// The mode that was actually applied (may differ from requested).
  final NomogramMode activeMode;

  /// The intensity at which bands were evaluated.
  final double intensityPercent;

  /// Lower band value (slope).
  final double lower;

  /// Mean band value (slope).
  final double mean;

  /// Upper band value (slope).
  final double upper;

  /// Athlete model contribution as 0–100%.
  final double athleteWeightPercent;

  /// Population/study model contribution as 0–100%.
  final double populationWeightPercent;

  /// Source description for audit trail.
  final NomogramModelSource source;

  /// Whether this point was extrapolated below the source intensity range.
  final bool isExtrapolated;

  /// Warnings generated during resolution.
  final List<String> warnings;

  const ResolvedNomogramBands({
    required this.activeMode,
    required this.intensityPercent,
    required this.lower,
    required this.mean,
    required this.upper,
    required this.athleteWeightPercent,
    required this.populationWeightPercent,
    required this.source,
    this.isExtrapolated = false,
    required this.warnings,
  });
}

/// Individual model band data (mean curve + prediction interval via ±1σ).
class IndividualModelBands {
  /// Fitted exponential model parameters.
  final NomogramParams params;

  /// Standard deviation of fit residuals.
  final double residualStdDev;

  /// R² of the fitted model, when available from the source fit.
  final double? rSquared;

  /// Leave-one-out cross-validation RMSE, when enough source points allow it.
  final double? cvRmse;

  /// Number of source points used to produce these bands.
  final int? sourcePointCount;

  const IndividualModelBands({
    required this.params,
    required this.residualStdDev,
    this.rSquared,
    this.cvRmse,
    this.sourcePointCount,
  });

  /// Expected slope (mean) at a given intensity.
  double mean(double intensityPercent) =>
      max(kMinSlopeForInterpretation, params.evaluate(intensityPercent));

  /// Lower band (mean - 1σ), floored at 0.1.
  double lower(double intensityPercent) =>
      max(kMinSlopeForInterpretation, mean(intensityPercent) - residualStdDev);

  /// Upper band (mean + 1σ).
  double upper(double intensityPercent) =>
      mean(intensityPercent) + residualStdDev;
}

// ---------------------------------------------------------------------------
// Residual standard deviation computation
// ---------------------------------------------------------------------------

/// Computes the standard deviation of fit residuals for a set of points
/// against a fitted model.
double computeResidualStdDev(
  List<NomogramPoint> points,
  NomogramParams params,
) {
  if (points.length < 2) return 0.0;

  double sumSq = 0.0;
  for (final p in points) {
    final predicted = max(
      kMinSlopeForInterpretation,
      params.evaluate(p.intensityPercent),
    );
    final residual = p.slope - predicted;
    sumSq += residual * residual;
  }
  // Use n-1 (Bessel's correction) for sample std dev
  return sqrt(sumSq / (points.length - 1));
}

/// Converts a fitted individual nomogram and its source points into bands.
///
/// The mean curve comes from [fittedModel]. The lower/upper bands use ±1
/// residual standard deviation from [sourcePoints]. LOO-CV RMSE is computed
/// when enough source points are available and retained for readiness/audit
/// consumers.
IndividualModelBands buildIndividualModelBands({
  required NomogramModel fittedModel,
  required List<NomogramPoint> sourcePoints,
}) {
  return IndividualModelBands(
    params: fittedModel.params,
    residualStdDev: computeResidualStdDev(sourcePoints, fittedModel.params),
    rSquared: fittedModel.rSquared,
    cvRmse: computeLooCvRmse(sourcePoints),
    sourcePointCount: sourcePoints.length,
  );
}

// ---------------------------------------------------------------------------
// Leave-one-out cross-validation RMSE
// ---------------------------------------------------------------------------

/// Computes leave-one-out cross-validation RMSE for the exponential model.
///
/// For each point, re-fits the model on all other points and measures
/// the prediction error. Returns null if points.length < 4 (need ≥3 to fit).
double? computeLooCvRmse(List<NomogramPoint> points) {
  if (points.length < 4) return null;

  double sumSqError = 0.0;
  int validFolds = 0;

  for (int i = 0; i < points.length; i++) {
    final trainPoints = [...points.sublist(0, i), ...points.sublist(i + 1)];

    try {
      final model = fitIndividualNomogram(trainPoints);
      final predicted = max(
        kMinSlopeForInterpretation,
        model.params.evaluate(points[i].intensityPercent),
      );
      final error = points[i].slope - predicted;
      sumSqError += error * error;
      validFolds++;
    } catch (_) {
      // If a fold fails to fit, skip it
      continue;
    }
  }

  if (validFolds == 0) return null;
  return sqrt(sumSqError / validFolds);
}

// ---------------------------------------------------------------------------
// Band resolution logic
// ---------------------------------------------------------------------------

/// Resolves nomogram bands at a single intensity point.
///
/// This is the single entry point that all builders and widgets should use.
/// It applies the correct model based on the requested mode, readiness,
/// and the fallback chain: individual → hybrid → population.
///
/// Parameters:
/// - [intensityPercent]: the intensity to evaluate.
/// - [requestedMode]: the user's preferred mode.
/// - [populationPreset]: which population dataset to use.
/// - [individualBands]: the athlete's fitted model (null if unavailable).
/// - [readiness]: the athlete's data readiness (null if not evaluated).
/// - [populationBandWidth]: used to enforce minimum individual band width.
ResolvedNomogramBands resolveNomogramBands({
  required double intensityPercent,
  required NomogramMode requestedMode,
  required PopulationNomogramSource populationPreset,
  IndividualModelBands? individualBands,
  IndividualReadiness? readiness,
}) {
  final warnings = <String>[];

  // Get population bands (always needed as baseline or fallback)
  final popBands = evaluatePopulationNomogramBands(
    intensityPercent,
    source: populationPreset,
  );
  warnings.addAll(popBands.warnings);
  final isExtrapolated = popBands.isExtrapolated;

  // Population band width for minimum individual band enforcement
  final popBandWidth = popBands.expectedUpper - popBands.expectedLower;

  // --- Mode resolution with fallback chain ---

  // POPULATION mode: always use population, regardless of data
  if (requestedMode == NomogramMode.population) {
    return ResolvedNomogramBands(
      activeMode: NomogramMode.population,
      intensityPercent: intensityPercent,
      lower: popBands.expectedLower,
      mean: popBands.expectedMean,
      upper: popBands.expectedUpper,
      athleteWeightPercent: 0.0,
      populationWeightPercent: 100.0,
      source: popBands.modelSource,
      isExtrapolated: isExtrapolated,
      warnings: List.unmodifiable(warnings),
    );
  }

  // For hybrid or individual, we need individual data
  if (individualBands == null || readiness == null) {
    warnings.add(
      'Individual model not available. Falling back to population reference.',
    );
    return ResolvedNomogramBands(
      activeMode: NomogramMode.population,
      intensityPercent: intensityPercent,
      lower: popBands.expectedLower,
      mean: popBands.expectedMean,
      upper: popBands.expectedUpper,
      athleteWeightPercent: 0.0,
      populationWeightPercent: 100.0,
      source: popBands.modelSource,
      isExtrapolated: isExtrapolated,
      warnings: List.unmodifiable(warnings),
    );
  }

  // INDIVIDUAL mode requested
  if (requestedMode == NomogramMode.individual) {
    if (readiness.isReady) {
      // Full individual mode
      final indBands = _applyMinBandWidth(
        individualBands,
        intensityPercent,
        popBandWidth,
      );
      return ResolvedNomogramBands(
        activeMode: NomogramMode.individual,
        intensityPercent: intensityPercent,
        lower: indBands.lower,
        mean: indBands.mean,
        upper: indBands.upper,
        athleteWeightPercent: 100.0,
        populationWeightPercent: 0.0,
        source: NomogramModelSource.individual,
        isExtrapolated: isExtrapolated,
        warnings: List.unmodifiable(warnings),
      );
    }
    // Fallback: individual not ready → try hybrid, then population
    if (readiness.hybridWeight > 0) {
      warnings.add(
        'Individual model not ready. Using hybrid mode as fallback.',
      );
      return _buildHybridBands(
        intensityPercent: intensityPercent,
        popBands: popBands,
        individualBands: individualBands,
        readiness: readiness,
        popBandWidth: popBandWidth,
        isExtrapolated: isExtrapolated,
        warnings: warnings,
      );
    }
    warnings.add(
      'Individual model not ready and insufficient data for hybrid. '
      'Falling back to population reference.',
    );
    return ResolvedNomogramBands(
      activeMode: NomogramMode.population,
      intensityPercent: intensityPercent,
      lower: popBands.expectedLower,
      mean: popBands.expectedMean,
      upper: popBands.expectedUpper,
      athleteWeightPercent: 0.0,
      populationWeightPercent: 100.0,
      source: popBands.modelSource,
      isExtrapolated: isExtrapolated,
      warnings: List.unmodifiable(warnings),
    );
  }

  // HYBRID mode requested
  if (readiness.hybridWeight > 0) {
    return _buildHybridBands(
      intensityPercent: intensityPercent,
      popBands: popBands,
      individualBands: individualBands,
      readiness: readiness,
      popBandWidth: popBandWidth,
      isExtrapolated: isExtrapolated,
      warnings: warnings,
    );
  }

  // Not enough data for any blending
  warnings.add(
    'Insufficient data for hybrid blending. Using population reference.',
  );
  return ResolvedNomogramBands(
    activeMode: NomogramMode.population,
    intensityPercent: intensityPercent,
    lower: popBands.expectedLower,
    mean: popBands.expectedMean,
    upper: popBands.expectedUpper,
    athleteWeightPercent: 0.0,
    populationWeightPercent: 100.0,
    source: popBands.modelSource,
    isExtrapolated: isExtrapolated,
    warnings: List.unmodifiable(warnings),
  );
}

/// Resolves bands at multiple intensities for chart curve sampling.
///
/// Returns a list of resolved bands from [startIntensity] to [endIntensity]
/// with [steps] evenly spaced points.
List<ResolvedNomogramBands> resolveNomogramBandCurve({
  required double startIntensity,
  required double endIntensity,
  required int steps,
  required NomogramMode requestedMode,
  required PopulationNomogramSource populationPreset,
  IndividualModelBands? individualBands,
  IndividualReadiness? readiness,
}) {
  if (steps <= 0) {
    return [
      resolveNomogramBands(
        intensityPercent: startIntensity,
        requestedMode: requestedMode,
        populationPreset: populationPreset,
        individualBands: individualBands,
        readiness: readiness,
      ),
    ];
  }

  final dx = (endIntensity - startIntensity) / steps;
  return [
    for (var i = 0; i <= steps; i++)
      resolveNomogramBands(
        intensityPercent: startIntensity + i * dx,
        requestedMode: requestedMode,
        populationPreset: populationPreset,
        individualBands: individualBands,
        readiness: readiness,
      ),
  ];
}

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

ResolvedNomogramBands _buildHybridBands({
  required double intensityPercent,
  required NomogramBandEvaluation popBands,
  required IndividualModelBands individualBands,
  required IndividualReadiness readiness,
  required double popBandWidth,
  required bool isExtrapolated,
  required List<String> warnings,
}) {
  final w = readiness.hybridWeight;
  final pw = 1.0 - w;

  final indBands = _applyMinBandWidth(
    individualBands,
    intensityPercent,
    popBandWidth,
  );

  final blendedLower = w * indBands.lower + pw * popBands.expectedLower;
  final blendedMean = w * indBands.mean + pw * popBands.expectedMean;
  final blendedUpper = w * indBands.upper + pw * popBands.expectedUpper;

  return ResolvedNomogramBands(
    activeMode: NomogramMode.hybrid,
    intensityPercent: intensityPercent,
    lower: max(kMinSlopeForInterpretation, blendedLower),
    mean: max(kMinSlopeForInterpretation, blendedMean),
    upper: max(kMinSlopeForInterpretation, blendedUpper),
    athleteWeightPercent: (w * 100).roundToDouble(),
    populationWeightPercent: (pw * 100).roundToDouble(),
    source: NomogramModelSource.hybrid,
    isExtrapolated: isExtrapolated,
    warnings: List.unmodifiable(warnings),
  );
}

/// Evaluates individual bands with minimum width enforcement.
///
/// If individual band width (upper - lower) is less than 50% of population
/// band width, widens the individual bands symmetrically.
({double lower, double mean, double upper}) _applyMinBandWidth(
  IndividualModelBands individualBands,
  double intensityPercent,
  double populationBandWidth,
) {
  final indMean = individualBands.mean(intensityPercent);
  var indLower = individualBands.lower(intensityPercent);
  var indUpper = individualBands.upper(intensityPercent);

  final indWidth = indUpper - indLower;
  final minWidth = populationBandWidth * 0.5;

  if (indWidth < minWidth && minWidth > 0) {
    final expand = (minWidth - indWidth) / 2.0;
    indLower = max(kMinSlopeForInterpretation, indLower - expand);
    indUpper = indUpper + expand;
  }

  return (lower: indLower, mean: indMean, upper: indUpper);
}
