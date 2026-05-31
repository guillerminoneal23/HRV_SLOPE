/// Calculation Preview — Pure Dart model for presenting all computation
/// results before saving a session.
///
/// This is the central data structure that the calculation preview screen
/// displays, ensuring scientific transparency of every step.
library;

import 'package:hrv_slope_app/shared/engine/intensity_resolver.dart';
import 'package:hrv_slope_app/shared/engine/nomogram_engine.dart';
import 'package:hrv_slope_app/shared/engine/rr_preprocessing.dart';
import 'package:hrv_slope_app/shared/engine/slope_calculator.dart';
import 'package:hrv_slope_app/shared/engine/rr_quality.dart';
import 'package:hrv_slope_app/core/constants/hrv_constants.dart';
import 'package:hrv_slope_app/core/constants/hrv_sources.dart';

/// Source of an RMSSD value.
enum RmssdSource { measured, fallback4Ms, computedFromRr }

/// A tagged variable entry for display.
class TaggedVariable {
  final String category;
  final String name;
  final String? unit;
  final double value;
  final String? source;
  final bool isPrimaryForNomogram;
  final String? notes;

  const TaggedVariable({
    required this.category,
    required this.name,
    this.unit,
    required this.value,
    this.source,
    this.isPrimaryForNomogram = false,
    this.notes,
  });
}

/// Full calculation preview model.
class CalculationPreview {
  // Session context
  final String athleteName;
  final String sessionDate;
  final String? sessionName;
  final String? sport;

  // Variables
  final List<TaggedVariable> externalVariables;
  final List<TaggedVariable> internalVariables;

  // Intensity resolution
  final IntensityResolution? intensityResolution;
  final double? intensityPercent;

  // RMSSD data
  final double? rmssdExercise;
  final RmssdSource rmssdExerciseSource;
  final double rmssdRecovery;
  final RmssdSource rmssdRecoverySource;
  final HrvInputMode hrvInputMode;
  final RrPreprocessingMode? rrPreprocessingMode;
  final bool correctionEnabled;
  final RrCorrectionMethod? correctionMethod;
  final double? rawRmssd;
  final double? correctedRmssd;
  final double rmssdUsedForSlope;
  final int? artifactCount;
  final double? artifactPercent;
  final RrQualityDecision? qualityDecision;
  final List<String> qualityNotes;
  final String? hrvSource;

  // Recovery window
  final double recoveryWindowStartMin;
  final double recoveryWindowEndMin;
  final double recoveryWindowDurationMin;
  final double tUsedForSlope;

  // Slope results
  final double rawSlope;
  final double interpretedSlope;
  final double itlIndex;

  // Nomogram classification (null if intensity missing)
  final String populationNomogramPreset;
  final double? expectedLower;
  final double? expectedMean;
  final double? expectedUpper;
  final String? classification;
  final double? residual;
  final double? residualPercent;

  // Quality reports
  final RrQualityReport? exerciseRrQuality;
  final RrQualityReport? recoveryRrQuality;
  final RrPreprocessingResult? exerciseRrPreprocessing;
  final RrPreprocessingResult? recoveryRrPreprocessing;

  // Warnings
  final List<String> warnings;

  // Metadata
  final bool usedFallbackExercise;
  final bool canClassify;

  const CalculationPreview({
    required this.athleteName,
    required this.sessionDate,
    this.sessionName,
    this.sport,
    required this.externalVariables,
    required this.internalVariables,
    this.intensityResolution,
    this.intensityPercent,
    this.rmssdExercise,
    required this.rmssdExerciseSource,
    required this.rmssdRecovery,
    required this.rmssdRecoverySource,
    this.hrvInputMode = HrvInputMode.directRmssd,
    this.rrPreprocessingMode,
    this.correctionEnabled = false,
    this.correctionMethod,
    this.rawRmssd,
    this.correctedRmssd,
    required this.rmssdUsedForSlope,
    this.artifactCount,
    this.artifactPercent,
    this.qualityDecision,
    this.qualityNotes = const [],
    this.hrvSource,
    required this.recoveryWindowStartMin,
    required this.recoveryWindowEndMin,
    required this.recoveryWindowDurationMin,
    required this.tUsedForSlope,
    required this.rawSlope,
    required this.interpretedSlope,
    required this.itlIndex,
    required this.populationNomogramPreset,
    this.expectedLower,
    this.expectedMean,
    this.expectedUpper,
    this.classification,
    this.residual,
    this.residualPercent,
    this.exerciseRrQuality,
    this.recoveryRrQuality,
    this.exerciseRrPreprocessing,
    this.recoveryRrPreprocessing,
    required this.warnings,
    required this.usedFallbackExercise,
    required this.canClassify,
  });
}

/// Builds a full CalculationPreview from raw inputs.
///
/// Uses RecoveryWindow + computeSlopeForRecoveryWindow() +
/// classifySlopeWithPopulationNomogram() as mandated.
CalculationPreview buildCalculationPreview({
  required String athleteName,
  required String sessionDate,
  String? sessionName,
  String? sport,
  required List<TaggedVariable> externalVariables,
  required List<TaggedVariable> internalVariables,
  IntensityResolution? intensityResolution,
  double? rmssdExercise,
  RmssdSource rmssdExerciseSource = RmssdSource.measured,
  required double rmssdRecovery,
  RmssdSource rmssdRecoverySource = RmssdSource.measured,
  required double recoveryWindowStartMin,
  required double recoveryWindowEndMin,
  RrQualityReport? exerciseRrQuality,
  RrQualityReport? recoveryRrQuality,
  RrPreprocessingResult? exerciseRrPreprocessing,
  RrPreprocessingResult? recoveryRrPreprocessing,
  HrvInputMode hrvInputMode = HrvInputMode.directRmssd,
  PopulationNomogramSource populationPreset = kDefaultPopulationNomogramSource,
}) {
  final warnings = <String>[];
  warnings.addAll(recoveryRrPreprocessing?.warnings ?? const []);
  warnings.addAll(exerciseRrPreprocessing?.warnings ?? const []);

  // Resolve RMSSD exercise
  double? effectiveExercise = rmssdExercise;
  var effectiveSource = rmssdExerciseSource;
  bool usedFallback = false;

  if (effectiveExercise == null) {
    effectiveExercise = kDefaultRmssdExerciseMs;
    effectiveSource = RmssdSource.fallback4Ms;
    usedFallback = true;
    warnings.add(
      'RMSSD exercise not provided. Using fallback value of '
      '$kDefaultRmssdExerciseMs ms.',
    );
  }

  // Build recovery window and compute slope
  final window = RecoveryWindow(
    startMin: recoveryWindowStartMin,
    endMin: recoveryWindowEndMin,
  );
  window.validate();

  final slopeResult = computeSlopeForRecoveryWindow(
    rmssdRecovery: rmssdRecovery,
    rmssdExercise: effectiveExercise,
    recoveryWindow: window,
  );

  final itl = computeItlIndex(slopeResult.interpretedSlope);

  // Intensity resolution
  final intensityPercent = intensityResolution?.intensityPercent;
  final canClassify =
      intensityPercent != null && intensityResolution!.canUseNomogram;

  // Nomogram classification
  double? expectedLower;
  double? expectedMean;
  double? expectedUpper;
  String? classification;
  double? residual;
  double? residualPercent;

  if (canClassify) {
    final classResult = classifySlopeWithPopulationNomogram(
      intensityPercent,
      slopeResult.interpretedSlope,
      source: populationPreset,
    );
    expectedLower = classResult.expectedLower;
    expectedMean = classResult.expectedMean;
    expectedUpper = classResult.expectedUpper;
    classification = classResult.classification.label;
    residual = classResult.residual;
    residualPercent = classResult.residualPercent;
    warnings.addAll(classResult.warnings);
  } else {
    warnings.add('Intensity percent is required for nomogram classification.');
  }

  // Add intensity resolution warnings
  if (intensityResolution != null) {
    warnings.addAll(intensityResolution.warnings);
  }

  return CalculationPreview(
    athleteName: athleteName,
    sessionDate: sessionDate,
    sessionName: sessionName,
    sport: sport,
    externalVariables: externalVariables,
    internalVariables: internalVariables,
    intensityResolution: intensityResolution,
    intensityPercent: intensityPercent,
    rmssdExercise: effectiveExercise,
    rmssdExerciseSource: effectiveSource,
    rmssdRecovery: rmssdRecovery,
    rmssdRecoverySource: rmssdRecoverySource,
    hrvInputMode: hrvInputMode,
    rrPreprocessingMode: recoveryRrPreprocessing?.preprocessingMode,
    correctionEnabled: recoveryRrPreprocessing?.correctionApplied ?? false,
    correctionMethod: recoveryRrPreprocessing?.correctionMethod,
    rawRmssd: recoveryRrPreprocessing?.rawRmssd,
    correctedRmssd: recoveryRrPreprocessing?.correctedRmssd,
    rmssdUsedForSlope: rmssdRecovery,
    artifactCount: recoveryRrPreprocessing?.artifactCount,
    artifactPercent: recoveryRrPreprocessing?.artifactPercent,
    qualityDecision: recoveryRrPreprocessing?.qualityDecision,
    qualityNotes: recoveryRrPreprocessing?.qualityNotes ?? const [],
    hrvSource: recoveryRrPreprocessing == null
        ? null
        : recoveryRrPreprocessing.correctionApplied
        ? 'computed_from_rr_corrected'
        : 'computed_from_rr_raw',
    recoveryWindowStartMin: recoveryWindowStartMin,
    recoveryWindowEndMin: recoveryWindowEndMin,
    recoveryWindowDurationMin: window.durationMin,
    tUsedForSlope: slopeResult.recoveryTimeForSlopeMin,
    rawSlope: slopeResult.rawSlope,
    interpretedSlope: slopeResult.interpretedSlope,
    itlIndex: itl,
    populationNomogramPreset: populationPreset.presetName,
    expectedLower: expectedLower,
    expectedMean: expectedMean,
    expectedUpper: expectedUpper,
    classification: classification,
    residual: residual,
    residualPercent: residualPercent,
    exerciseRrQuality: exerciseRrQuality,
    recoveryRrQuality: recoveryRrQuality,
    exerciseRrPreprocessing: exerciseRrPreprocessing,
    recoveryRrPreprocessing: recoveryRrPreprocessing,
    warnings: warnings,
    usedFallbackExercise: usedFallback,
    canClassify: canClassify,
  );
}
