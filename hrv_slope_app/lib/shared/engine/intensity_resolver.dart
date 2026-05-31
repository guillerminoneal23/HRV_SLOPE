/// Intensity Percent Resolver — Pure Dart logic for determining exercise
/// intensity as a percentage of a reference maximum.
///
/// External priority chain:
/// 1. Direct percent_mas
/// 2. Direct percent_vvo2max
/// 3. Direct percent_map
/// 4. speed_kmh / athlete.MAS_kmh
/// 5. speed_kmh / athlete.vVO2max_kmh
/// 6. power_w / athlete.MAP_w
///
/// If no valid external intensity is available, internal load can be converted
/// to a 0-100 intensity percent for slope interpretation. Zero is treated as
/// non-informative for both external percent inputs and 0-10 internal scales.
library;

enum IntensitySourceForSlope {
  external('External'),
  internal('Internal'),
  unknown('Unknown');

  final String label;
  const IntensitySourceForSlope(this.label);
}

/// Explicit source-aware resolution used by HRV slope calculations.
class SlopeIntensityResolution {
  /// Resolved primary intensity percent, or null if unresolvable.
  final double? intensityPercent;

  /// Metric or method selected as primary.
  final String? metricName;

  /// Broad source of the primary intensity.
  final IntensitySourceForSlope source;

  /// True when internal load is used because valid external load is absent.
  final bool isFallback;

  /// Human-readable reason for the selected source or unresolved state.
  final String? reason;

  const SlopeIntensityResolution({
    required this.intensityPercent,
    required this.metricName,
    required this.source,
    required this.isFallback,
    this.reason,
  });
}

/// Result of intensity percent resolution.
class IntensityResolution extends SlopeIntensityResolution {
  /// Method used for resolution.
  final String method;

  /// Source variable names used.
  final List<String> sourceVariables;

  /// Warnings generated during resolution.
  final List<String> warnings;

  /// Whether the result is usable for nomogram classification.
  final bool canUseNomogram;

  const IntensityResolution({
    required super.intensityPercent,
    required this.method,
    required this.sourceVariables,
    required this.warnings,
    required this.canUseNomogram,
    required super.source,
    required super.metricName,
    required super.isFallback,
    super.reason,
  });

  @override
  String toString() =>
      'IntensityResolution(intensityPercent: $intensityPercent, '
      'method: $method, canUseNomogram: $canUseNomogram)';
}

/// Input variables for intensity resolution.
class IntensityInputs {
  final double? percentMas;
  final double? percentVvo2max;
  final double? percentMap;
  final double? speedKmh;
  final double? powerW;
  final double? rpe110;
  final double? sessionRpe110;
  final double? subjectiveIntensityPercent;
  final double? subjectiveIntensity110;
  final double? subjectiveFatigue110;
  final double? percentHrmax;
  final double? internalLoadPercent;

  const IntensityInputs({
    this.percentMas,
    this.percentVvo2max,
    this.percentMap,
    this.speedKmh,
    this.powerW,
    this.rpe110,
    this.sessionRpe110,
    this.subjectiveIntensityPercent,
    this.subjectiveIntensity110,
    this.subjectiveFatigue110,
    this.percentHrmax,
    this.internalLoadPercent,
  });
}

/// Athlete reference values for intensity calculation.
class AthleteReferenceValues {
  final double? masKmh;
  final double? vvo2maxKmh;
  final double? mapW;

  const AthleteReferenceValues({this.masKmh, this.vvo2maxKmh, this.mapW});
}

/// Resolves the primary intensity percent for HRV slope interpretation.
///
/// Valid external load is preferred. Internal load is used only when no valid
/// external intensity can be resolved.
IntensityResolution resolvePrimaryIntensityForSlope({
  required IntensityInputs inputs,
  required AthleteReferenceValues athlete,
}) {
  final warnings = <String>[];

  // Priority 1: Direct percent_mas
  if (_isPresent(inputs.percentMas)) {
    if (!_isPositiveFinite(inputs.percentMas)) {
      warnings.add('percent_mas must be positive, got ${inputs.percentMas}.');
    } else {
      return _external(inputs.percentMas!, 'direct_percent_mas', const [
        'percent_mas',
      ], warnings: warnings);
    }
  }

  // Priority 2: Direct percent_vvo2max
  if (_isPresent(inputs.percentVvo2max)) {
    if (!_isPositiveFinite(inputs.percentVvo2max)) {
      warnings.add(
        'percent_vvo2max must be positive, got ${inputs.percentVvo2max}.',
      );
    } else {
      return _external(inputs.percentVvo2max!, 'direct_percent_vvo2max', const [
        'percent_vvo2max',
      ], warnings: warnings);
    }
  }

  // Priority 3: Direct percent_map
  if (_isPresent(inputs.percentMap)) {
    if (!_isPositiveFinite(inputs.percentMap)) {
      warnings.add('percent_map must be positive, got ${inputs.percentMap}.');
    } else {
      return _external(inputs.percentMap!, 'direct_percent_map', const [
        'percent_map',
      ], warnings: warnings);
    }
  }

  // Priority 4: speed_kmh / athlete.MAS_kmh
  if (_isPresent(inputs.speedKmh) && _isPresent(athlete.masKmh)) {
    if (!_isPositiveFinite(inputs.speedKmh)) {
      warnings.add('speed_kmh must be positive, got ${inputs.speedKmh}.');
    } else if (!_isPositiveFinite(athlete.masKmh)) {
      warnings.add('athlete MAS_kmh must be positive, got ${athlete.masKmh}.');
    } else {
      final percent = inputs.speedKmh! / athlete.masKmh! * 100;
      return _external(percent, 'speed_kmh_div_mas', const [
        'speed_kmh',
        'athlete.MAS_kmh',
      ], warnings: warnings);
    }
  }

  // Priority 5: speed_kmh / athlete.vVO2max_kmh
  if (_isPresent(inputs.speedKmh) && _isPresent(athlete.vvo2maxKmh)) {
    if (!_isPositiveFinite(inputs.speedKmh)) {
      warnings.add('speed_kmh must be positive, got ${inputs.speedKmh}.');
    } else if (!_isPositiveFinite(athlete.vvo2maxKmh)) {
      warnings.add(
        'athlete vVO2max_kmh must be positive, got ${athlete.vvo2maxKmh}.',
      );
    } else {
      final percent = inputs.speedKmh! / athlete.vvo2maxKmh! * 100;
      return _external(percent, 'speed_kmh_div_vvo2max', const [
        'speed_kmh',
        'athlete.vVO2max_kmh',
      ], warnings: warnings);
    }
  }

  // Priority 6: power_w / athlete.MAP_w
  if (_isPresent(inputs.powerW) && _isPresent(athlete.mapW)) {
    if (!_isPositiveFinite(inputs.powerW)) {
      warnings.add('power_w must be positive, got ${inputs.powerW}.');
    } else if (!_isPositiveFinite(athlete.mapW)) {
      warnings.add('athlete MAP_w must be positive, got ${athlete.mapW}.');
    } else {
      final percent = inputs.powerW! / athlete.mapW! * 100;
      return _external(percent, 'power_w_div_map', const [
        'power_w',
        'athlete.MAP_w',
      ], warnings: warnings);
    }
  }

  // Internal fallback priority 1: session RPE / RPE on a 0-10 scale.
  final rpe = _firstValidScale10([
    (name: 'session_rpe_1_10', value: inputs.sessionRpe110),
    (name: 'rpe_1_10', value: inputs.rpe110),
  ], warnings);
  if (rpe != null) {
    return _internal(
      rpe.value * 10,
      'internal_${rpe.name}',
      [rpe.name],
      warnings,
      'No valid external intensity was available; using RPE on a 0-10 scale.',
    );
  }

  // Internal fallback priority 2: subjective intensity.
  if (_isPresent(inputs.subjectiveIntensityPercent)) {
    if (_isPositiveFinite(inputs.subjectiveIntensityPercent)) {
      return _internal(
        inputs.subjectiveIntensityPercent!,
        'internal_subjective_intensity_percent',
        const ['subjective_intensity_percent'],
        warnings,
        'No valid external intensity was available; using subjective intensity percent.',
      );
    }
    warnings.add(
      'subjective_intensity_percent must be positive, got '
      '${inputs.subjectiveIntensityPercent}.',
    );
  }
  final subjective = _firstValidScale10([
    (name: 'subjective_intensity_1_10', value: inputs.subjectiveIntensity110),
  ], warnings);
  if (subjective != null) {
    return _internal(
      subjective.value * 10,
      'internal_${subjective.name}',
      [subjective.name],
      warnings,
      'No valid external intensity was available; using subjective intensity on a 0-10 scale.',
    );
  }

  // Internal fallback priority 3: subjective fatigue on a 0-10 scale.
  final fatigue = _firstValidScale10([
    (name: 'subjective_fatigue_1_10', value: inputs.subjectiveFatigue110),
  ], warnings);
  if (fatigue != null) {
    return _internal(
      fatigue.value * 10,
      'internal_${fatigue.name}',
      [fatigue.name],
      warnings,
      'No valid external intensity was available; using subjective fatigue on a 0-10 scale.',
    );
  }

  // Internal fallback priority 4: already-normalized internal percentages.
  for (final percentMetric in [
    (name: 'internal_load_percent', value: inputs.internalLoadPercent),
    (name: 'percent_hrmax', value: inputs.percentHrmax),
  ]) {
    if (!_isPresent(percentMetric.value)) continue;
    if (_isPositiveFinite(percentMetric.value)) {
      return _internal(
        percentMetric.value!,
        'internal_${percentMetric.name}',
        [percentMetric.name],
        warnings,
        'No valid external intensity was available; using normalized internal load.',
      );
    }
    warnings.add(
      '${percentMetric.name} must be positive, got ${percentMetric.value}.',
    );
  }

  // Nothing resolved
  warnings.add(
    'Primary intensity is required for intensity-based interpretation. '
    'Provide external intensity or internal intensity such as RPE or '
    'subjective fatigue.',
  );
  return IntensityResolution(
    intensityPercent: null,
    method: 'unresolved',
    sourceVariables: const [],
    warnings: warnings,
    canUseNomogram: false,
    source: IntensitySourceForSlope.unknown,
    metricName: null,
    isFallback: false,
    reason: 'No valid external or internal intensity was available.',
  );
}

/// Backward-compatible API for resolving intensity percent.
IntensityResolution resolveIntensityPercent({
  required IntensityInputs inputs,
  required AthleteReferenceValues athlete,
}) {
  return resolvePrimaryIntensityForSlope(inputs: inputs, athlete: athlete);
}

IntensityResolution _external(
  double percent,
  String method,
  List<String> sourceVariables, {
  required List<String> warnings,
}) {
  return IntensityResolution(
    intensityPercent: percent,
    method: method,
    sourceVariables: sourceVariables,
    warnings: warnings,
    canUseNomogram: true,
    source: IntensitySourceForSlope.external,
    metricName: method,
    isFallback: false,
    reason: 'Using valid external intensity.',
  );
}

IntensityResolution _internal(
  double percent,
  String method,
  List<String> sourceVariables,
  List<String> warnings,
  String reason,
) {
  return IntensityResolution(
    intensityPercent: percent,
    method: method,
    sourceVariables: sourceVariables,
    warnings: warnings,
    canUseNomogram: true,
    source: IntensitySourceForSlope.internal,
    metricName: method,
    isFallback: true,
    reason: reason,
  );
}

({String name, double value})? _firstValidScale10(
  List<({String name, double? value})> metrics,
  List<String> warnings,
) {
  for (final metric in metrics) {
    if (!_isPresent(metric.value)) continue;
    if (_isPositiveFinite(metric.value) && metric.value! <= 10) {
      return (name: metric.name, value: metric.value!);
    }
    warnings.add('${metric.name} must be > 0 and <= 10, got ${metric.value}.');
  }
  return null;
}

bool _isPresent(double? value) => value != null;

bool _isPositiveFinite(double? value) {
  return value != null && value.isFinite && value > 0;
}

IntensitySourceForSlope intensitySourceForSlopeFromMethod(String? method) {
  final normalized = method?.trim().toLowerCase();
  if (normalized == null || normalized.isEmpty || normalized == 'unresolved') {
    return IntensitySourceForSlope.unknown;
  }
  if (normalized.startsWith('internal_')) {
    return IntensitySourceForSlope.internal;
  }
  return IntensitySourceForSlope.external;
}

String intensitySourceForSlopeLabel(String? method) {
  return intensitySourceForSlopeFromMethod(method).label;
}

String? primaryIntensityMetricFromMethod(String? method) {
  final normalized = method?.trim();
  if (normalized == null ||
      normalized.isEmpty ||
      normalized.toLowerCase() == 'unresolved') {
    return null;
  }
  return normalized.startsWith('internal_')
      ? normalized.replaceFirst('internal_', '')
      : normalized;
}
