/// Nomogram mode selection and individual readiness evaluation.
///
/// This module defines the three nomogram interpretation modes
/// (population, hybrid, individual) and the readiness gate that
/// determines whether an athlete has sufficient data for individual
/// model use.
library;

// ---------------------------------------------------------------------------
// Nomogram mode enum
// ---------------------------------------------------------------------------

/// User-selectable nomogram interpretation mode.
///
/// - [population]: Always use population reference (the study model).
/// - [hybrid]: Blend population + individual based on data confidence.
///   The three visible bands (lower, mean, upper) shift — no extra curves.
/// - [individual]: Individual-only. Requires readiness gate to pass.
enum NomogramMode {
  population,
  hybrid,
  individual,
}

extension NomogramModeText on NomogramMode {
  String get key {
    switch (this) {
      case NomogramMode.population:
        return 'population';
      case NomogramMode.hybrid:
        return 'hybrid';
      case NomogramMode.individual:
        return 'individual';
    }
  }

  String get label {
    switch (this) {
      case NomogramMode.population:
        return 'Study model (population)';
      case NomogramMode.hybrid:
        return 'Hybrid (athlete + study)';
      case NomogramMode.individual:
        return 'Individual model';
    }
  }

  String get shortLabel {
    switch (this) {
      case NomogramMode.population:
        return 'Population';
      case NomogramMode.hybrid:
        return 'Hybrid';
      case NomogramMode.individual:
        return 'Individual';
    }
  }
}

/// Parses a [NomogramMode] from a stored string key.
NomogramMode parseNomogramMode(String? value) {
  switch (value?.trim()) {
    case 'hybrid':
      return NomogramMode.hybrid;
    case 'individual':
      return NomogramMode.individual;
    case 'population':
    default:
      return NomogramMode.population;
  }
}

// ---------------------------------------------------------------------------
// Individual readiness
// ---------------------------------------------------------------------------

/// Minimum number of valid sessions required for individual model.
const int kReadinessMinSessions = 12;

/// Minimum number of distinct intensity bins (10-pp wide) with ≥3
/// measurements each.
const int kReadinessMinBins = 4;

/// Minimum measurements per bin for that bin to count.
const int kReadinessMinMeasurementsPerBin = 3;

/// Minimum intensity coverage in percentage points (e.g. 50%–80% = 30 pp).
const double kReadinessMinCoveragePp = 30.0;

/// Minimum R² of the exponential fit for the model to be considered valid.
const double kReadinessMinRSquared = 0.60;

/// Maximum leave-one-out cross-validation RMSE for stability.
const double kReadinessMaxCvRmse = 0.50;

/// Width of each intensity bin in percentage points.
const double kReadinessBinWidthPp = 10.0;

/// A single readiness criterion that is not yet met.
class ReadinessGap {
  final String criterion;
  final String currentValue;
  final String requiredValue;

  const ReadinessGap({
    required this.criterion,
    required this.currentValue,
    required this.requiredValue,
  });

  @override
  String toString() =>
      '$criterion: $currentValue (required: $requiredValue)';
}

/// Result of evaluating whether an athlete has sufficient data for
/// individual nomogram use.
///
/// Pure value object — computed on-the-fly, never persisted.
class IndividualReadiness {
  /// Whether all criteria are met and the individual model can be used.
  final bool isReady;

  /// Number of valid sessions available.
  final int validSessions;

  /// Required session count.
  final int requiredSessions;

  /// Number of intensity bins with ≥ [kReadinessMinMeasurementsPerBin]
  /// measurements.
  final int qualifiedBins;

  /// Required bin count.
  final int requiredBins;

  /// Intensity range coverage in percentage points.
  final double coveragePp;

  /// Required coverage in percentage points.
  final double requiredCoveragePp;

  /// R² of the fitted model (null if not enough data to fit).
  final double? rSquared;

  /// Required minimum R².
  final double requiredRSquared;

  /// Leave-one-out cross-validation RMSE (null if not computed).
  final double? cvRmse;

  /// Required maximum CV-RMSE.
  final double requiredMaxCvRmse;

  /// List of criteria not yet met.
  final List<ReadinessGap> gaps;

  const IndividualReadiness({
    required this.isReady,
    required this.validSessions,
    required this.requiredSessions,
    required this.qualifiedBins,
    required this.requiredBins,
    required this.coveragePp,
    required this.requiredCoveragePp,
    this.rSquared,
    required this.requiredRSquared,
    this.cvRmse,
    required this.requiredMaxCvRmse,
    required this.gaps,
  });

  /// Whether we have enough data to attempt fitting (even if not fully ready).
  bool get canAttemptFit =>
      validSessions >= 3 && qualifiedBins >= 2;

  /// Discrete hybrid weight based on data quantity (v1 discrete steps).
  ///
  /// Weight represents the individual model's contribution.
  /// 0.0 = pure population, 1.0 = pure individual.
  double get hybridWeight {
    if (validSessions < 6) return 0.0;
    if (validSessions < 9) return 0.3;
    if (validSessions < 12) return 0.7;
    if (!isReady) return 0.7;
    return 1.0;
  }

  /// Population weight (complement of hybridWeight).
  double get populationWeight => 1.0 - hybridWeight;

  /// Human-readable hybrid weight label, e.g. "70% athlete / 30% study".
  String get hybridLabel {
    final aw = (hybridWeight * 100).round();
    final pw = (populationWeight * 100).round();
    return '$aw% athlete / $pw% study';
  }
}

// ---------------------------------------------------------------------------
// Readiness evaluator — pure function
// ---------------------------------------------------------------------------

/// Assigns each intensity to a 10-pp bin: 30–40, 40–50, …, 100–110.
int _binIndex(double intensityPercent) =>
    (intensityPercent / kReadinessBinWidthPp).floor();

/// Evaluates whether an athlete's data meets the criteria for individual
/// nomogram use.
///
/// [intensities] is the list of intensity percentages from valid sessions.
/// [rSquared] and [cvRmse] come from the fitted model (null if unavailable).
IndividualReadiness evaluateIndividualReadiness({
  required List<double> intensities,
  double? rSquared,
  double? cvRmse,
}) {
  final gaps = <ReadinessGap>[];
  final n = intensities.length;

  // 1. Session count
  final sessionOk = n >= kReadinessMinSessions;
  if (!sessionOk) {
    gaps.add(ReadinessGap(
      criterion: 'Valid sessions',
      currentValue: '$n',
      requiredValue: '>= $kReadinessMinSessions',
    ));
  }

  // 2. Bin distribution
  final binCounts = <int, int>{};
  for (final intensity in intensities) {
    final bin = _binIndex(intensity);
    binCounts[bin] = (binCounts[bin] ?? 0) + 1;
  }
  final qualifiedBins = binCounts.values
      .where((count) => count >= kReadinessMinMeasurementsPerBin)
      .length;
  final binsOk = qualifiedBins >= kReadinessMinBins;
  if (!binsOk) {
    gaps.add(ReadinessGap(
      criterion: 'Intensity bins with ≥$kReadinessMinMeasurementsPerBin measurements',
      currentValue: '$qualifiedBins bins',
      requiredValue: '>= $kReadinessMinBins bins',
    ));
  }

  // 3. Coverage
  final coverage = intensities.isEmpty
      ? 0.0
      : intensities.reduce((a, b) => a > b ? a : b) -
        intensities.reduce((a, b) => a < b ? a : b);
  final coverageOk = coverage >= kReadinessMinCoveragePp;
  if (!coverageOk) {
    gaps.add(ReadinessGap(
      criterion: 'Intensity coverage',
      currentValue: '${coverage.toStringAsFixed(1)} pp',
      requiredValue: '>= ${kReadinessMinCoveragePp.toStringAsFixed(0)} pp',
    ));
  }

  // 4. R² (only checked if model was fitted)
  final rSquaredOk = rSquared != null && rSquared >= kReadinessMinRSquared;
  if (rSquared != null && !rSquaredOk) {
    gaps.add(ReadinessGap(
      criterion: 'Model R²',
      currentValue: rSquared.toStringAsFixed(3),
      requiredValue: '>= ${kReadinessMinRSquared.toStringAsFixed(2)}',
    ));
  } else if (rSquared == null && n >= kReadinessMinSessions) {
    gaps.add(ReadinessGap(
      criterion: 'Model R²',
      currentValue: 'not available',
      requiredValue: '>= ${kReadinessMinRSquared.toStringAsFixed(2)}',
    ));
  }

  // 5. CV-RMSE stability (only checked if computed)
  final cvOk = cvRmse != null && cvRmse <= kReadinessMaxCvRmse;
  if (cvRmse != null && !cvOk) {
    gaps.add(ReadinessGap(
      criterion: 'Cross-validation RMSE',
      currentValue: cvRmse.toStringAsFixed(3),
      requiredValue: '<= ${kReadinessMaxCvRmse.toStringAsFixed(2)}',
    ));
  }

  // Overall readiness requires all 5 criteria
  final isReady = sessionOk &&
      binsOk &&
      coverageOk &&
      rSquaredOk &&
      cvOk;

  return IndividualReadiness(
    isReady: isReady,
    validSessions: n,
    requiredSessions: kReadinessMinSessions,
    qualifiedBins: qualifiedBins,
    requiredBins: kReadinessMinBins,
    coveragePp: coverage,
    requiredCoveragePp: kReadinessMinCoveragePp,
    rSquared: rSquared,
    requiredRSquared: kReadinessMinRSquared,
    cvRmse: cvRmse,
    requiredMaxCvRmse: kReadinessMaxCvRmse,
    gaps: List.unmodifiable(gaps),
  );
}
