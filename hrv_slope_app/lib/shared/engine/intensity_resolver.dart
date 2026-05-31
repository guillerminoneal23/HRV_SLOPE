/// Intensity Percent Resolver — Pure Dart logic for determining exercise
/// intensity as a percentage of a reference maximum.
///
/// Priority chain:
/// 1. Direct percent_mas
/// 2. Direct percent_vvo2max
/// 3. Direct percent_map
/// 4. speed_kmh / athlete.MAS_kmh
/// 5. speed_kmh / athlete.vVO2max_kmh
/// 6. power_w / athlete.MAP_w
library;

/// Result of intensity percent resolution.
class IntensityResolution {
  /// Resolved intensity percent, or null if unresolvable.
  final double? intensityPercent;

  /// Method used for resolution.
  final String method;

  /// Source variable names used.
  final List<String> sourceVariables;

  /// Warnings generated during resolution.
  final List<String> warnings;

  /// Whether the result is usable for nomogram classification.
  final bool canUseNomogram;

  const IntensityResolution({
    required this.intensityPercent,
    required this.method,
    required this.sourceVariables,
    required this.warnings,
    required this.canUseNomogram,
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

  const IntensityInputs({
    this.percentMas,
    this.percentVvo2max,
    this.percentMap,
    this.speedKmh,
    this.powerW,
  });
}

/// Athlete reference values for intensity calculation.
class AthleteReferenceValues {
  final double? masKmh;
  final double? vvo2maxKmh;
  final double? mapW;

  const AthleteReferenceValues({this.masKmh, this.vvo2maxKmh, this.mapW});
}

/// Resolves intensity percent from available inputs and athlete reference values.
///
/// Returns an [IntensityResolution] with the resolved value and metadata.
/// If intensity cannot be resolved, [IntensityResolution.intensityPercent] is null
/// and [canUseNomogram] is false.
IntensityResolution resolveIntensityPercent({
  required IntensityInputs inputs,
  required AthleteReferenceValues athlete,
}) {
  final warnings = <String>[];

  // Priority 1: Direct percent_mas
  if (inputs.percentMas != null) {
    if (inputs.percentMas! <= 0) {
      warnings.add('percent_mas must be positive, got ${inputs.percentMas}.');
      return IntensityResolution(
        intensityPercent: null,
        method: 'percent_mas_invalid',
        sourceVariables: const ['percent_mas'],
        warnings: warnings,
        canUseNomogram: false,
      );
    }
    return IntensityResolution(
      intensityPercent: inputs.percentMas!,
      method: 'direct_percent_mas',
      sourceVariables: const ['percent_mas'],
      warnings: warnings,
      canUseNomogram: true,
    );
  }

  // Priority 2: Direct percent_vvo2max
  if (inputs.percentVvo2max != null) {
    if (inputs.percentVvo2max! <= 0) {
      warnings.add(
        'percent_vvo2max must be positive, got ${inputs.percentVvo2max}.',
      );
      return IntensityResolution(
        intensityPercent: null,
        method: 'percent_vvo2max_invalid',
        sourceVariables: const ['percent_vvo2max'],
        warnings: warnings,
        canUseNomogram: false,
      );
    }
    return IntensityResolution(
      intensityPercent: inputs.percentVvo2max!,
      method: 'direct_percent_vvo2max',
      sourceVariables: const ['percent_vvo2max'],
      warnings: warnings,
      canUseNomogram: true,
    );
  }

  // Priority 3: Direct percent_map
  if (inputs.percentMap != null) {
    if (inputs.percentMap! <= 0) {
      warnings.add('percent_map must be positive, got ${inputs.percentMap}.');
      return IntensityResolution(
        intensityPercent: null,
        method: 'percent_map_invalid',
        sourceVariables: const ['percent_map'],
        warnings: warnings,
        canUseNomogram: false,
      );
    }
    return IntensityResolution(
      intensityPercent: inputs.percentMap!,
      method: 'direct_percent_map',
      sourceVariables: const ['percent_map'],
      warnings: warnings,
      canUseNomogram: true,
    );
  }

  // Priority 4: speed_kmh / athlete.MAS_kmh
  if (inputs.speedKmh != null && athlete.masKmh != null) {
    if (inputs.speedKmh! <= 0) {
      warnings.add('speed_kmh must be positive, got ${inputs.speedKmh}.');
    } else if (athlete.masKmh! <= 0) {
      warnings.add('athlete MAS_kmh must be positive, got ${athlete.masKmh}.');
    } else {
      final percent = inputs.speedKmh! / athlete.masKmh! * 100;
      return IntensityResolution(
        intensityPercent: percent,
        method: 'speed_kmh_div_mas',
        sourceVariables: const ['speed_kmh', 'athlete.MAS_kmh'],
        warnings: warnings,
        canUseNomogram: true,
      );
    }
  }

  // Priority 5: speed_kmh / athlete.vVO2max_kmh
  if (inputs.speedKmh != null && athlete.vvo2maxKmh != null) {
    if (inputs.speedKmh! <= 0) {
      warnings.add('speed_kmh must be positive, got ${inputs.speedKmh}.');
    } else if (athlete.vvo2maxKmh! <= 0) {
      warnings.add(
        'athlete vVO2max_kmh must be positive, got ${athlete.vvo2maxKmh}.',
      );
    } else {
      final percent = inputs.speedKmh! / athlete.vvo2maxKmh! * 100;
      return IntensityResolution(
        intensityPercent: percent,
        method: 'speed_kmh_div_vvo2max',
        sourceVariables: const ['speed_kmh', 'athlete.vVO2max_kmh'],
        warnings: warnings,
        canUseNomogram: true,
      );
    }
  }

  // Priority 6: power_w / athlete.MAP_w
  if (inputs.powerW != null && athlete.mapW != null) {
    if (inputs.powerW! <= 0) {
      warnings.add('power_w must be positive, got ${inputs.powerW}.');
    } else if (athlete.mapW! <= 0) {
      warnings.add('athlete MAP_w must be positive, got ${athlete.mapW}.');
    } else {
      final percent = inputs.powerW! / athlete.mapW! * 100;
      return IntensityResolution(
        intensityPercent: percent,
        method: 'power_w_div_map',
        sourceVariables: const ['power_w', 'athlete.MAP_w'],
        warnings: warnings,
        canUseNomogram: true,
      );
    }
  }

  // Nothing resolved
  warnings.add(
    'Intensity percent is required for nomogram interpretation. '
    'Provide percent_mas, percent_vvo2max, percent_map, '
    'speed + MAS/vVO2max, or power + MAP.',
  );
  return IntensityResolution(
    intensityPercent: null,
    method: 'unresolved',
    sourceVariables: const [],
    warnings: warnings,
    canUseNomogram: false,
  );
}
