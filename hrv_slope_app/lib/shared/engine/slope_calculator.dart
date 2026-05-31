/// Slope Calculator — Pure functions for RMSSD-Slope computation,
/// clamping, and Internal Training Load (ITL) index.
///
/// Reference: Naranjo Orellana et al. (2019).
/// Slope = (RMSSD_recovery − RMSSD_exercise) / t
library;

import 'dart:math';

import 'package:hrv_slope_app/core/constants/hrv_constants.dart';
import 'package:hrv_slope_app/core/errors/hrv_errors.dart';

/// A validated 5-minute recovery HRV window.
///
/// The slope denominator is the elapsed time from exercise end to the end of
/// this window, not the window duration.
class RecoveryWindow {
  final double startMin;
  final double endMin;

  const RecoveryWindow({required this.startMin, required this.endMin});

  double get durationMin => endMin - startMin;

  double get recoveryTimeForSlopeMin => endMin;

  void validate() {
    if (startMin < 0 || endMin < 0) {
      throw InvalidRecoveryTimeError(
        'Recovery window times must be non-negative, got '
        '$startMin-$endMin min.',
      );
    }

    if (endMin <= startMin) {
      throw InvalidRecoveryTimeError(
        'Recovery window end must be greater than start, got '
        '$startMin-$endMin min.',
      );
    }

    if (startMin < kMinRecoveryExclusionMin) {
      throw InvalidRecoveryTimeError(
        'Recovery window must start at or after '
        '$kMinRecoveryExclusionMin min, got $startMin min.',
      );
    }

    if ((durationMin - kRecoveryWindowDurationMin).abs() > 1e-9) {
      throw InvalidRecoveryTimeError(
        'Recovery window duration must be $kRecoveryWindowDurationMin min, '
        'got $durationMin min.',
      );
    }

    if (endMin > kMaxRecoveryWindowMin) {
      throw InvalidRecoveryTimeError(
        'Recovery window must end at or before $kMaxRecoveryWindowMin min, '
        'got $endMin min.',
      );
    }
  }
}

/// Result of slope computation, preserving metadata about the calculation.
class SlopeResult {
  /// The raw computed slope value (may be < 0.1 or even negative).
  final double rawSlope;

  /// The clamped slope used for graphical and nomogram interpretation.
  final double interpretedSlope;

  /// Whether the 4 ms default was used instead of a measured exercise RMSSD.
  final bool usedFallback;

  /// The actual RMSSD exercise value used (measured or fallback).
  final double rmssdExerciseUsed;

  /// Recovery window start in minutes after exercise, when known.
  final double? recoveryWindowStartMin;

  /// Recovery window end in minutes after exercise, when known.
  final double? recoveryWindowEndMin;

  /// Recovery window duration in minutes, when known.
  final double? recoveryWindowDurationMin;

  /// Time denominator used in the slope calculation.
  final double recoveryTimeForSlopeMin;

  const SlopeResult({
    required this.rawSlope,
    required this.interpretedSlope,
    required this.usedFallback,
    required this.rmssdExerciseUsed,
    required this.recoveryTimeForSlopeMin,
    this.recoveryWindowStartMin,
    this.recoveryWindowEndMin,
    this.recoveryWindowDurationMin,
  });

  @override
  String toString() =>
      'SlopeResult(rawSlope: $rawSlope, '
      'interpretedSlope: $interpretedSlope, '
      'usedFallback: $usedFallback, '
      'rmssdExerciseUsed: $rmssdExerciseUsed, '
      'recoveryTimeForSlopeMin: $recoveryTimeForSlopeMin)';
}

/// Computes the RMSSD recovery slope.
///
/// - [rmssdRecovery]: RMSSD from a 5-minute recovery window (ms). Must be ≥ 0.
/// - [rmssdExercise]: RMSSD from last 5 min of exercise (ms). Null → fallback to 4 ms.
/// - [recoveryTimeMin]: Time from end of exercise to end of recovery window.
///   Must be > 5.0 (first 5 minutes excluded per Javorka et al., 2002).
///
/// Throws [InvalidRecoveryTimeError] if recoveryTimeMin ≤ 5.0.
/// Throws [InvalidDataError] if rmssdRecovery < 0.
SlopeResult computeSlope(
  double rmssdRecovery,
  double? rmssdExercise,
  double recoveryTimeMin,
) {
  if (recoveryTimeMin <= kMinRecoveryExclusionMin) {
    throw InvalidRecoveryTimeError(
      'Recovery time must be > $kMinRecoveryExclusionMin min, '
      'got $recoveryTimeMin min. The first 5 minutes of recovery '
      'are excluded due to time-series instability.',
    );
  }

  if (rmssdRecovery < 0) {
    throw InvalidDataError(
      'RMSSD recovery must be ≥ 0, got $rmssdRecovery ms.',
    );
  }

  final bool usedFallback = rmssdExercise == null;
  final double exerciseValue = rmssdExercise ?? kDefaultRmssdExerciseMs;

  final double rawSlope = (rmssdRecovery - exerciseValue) / recoveryTimeMin;

  return SlopeResult(
    rawSlope: rawSlope,
    interpretedSlope: clampSlopeForInterpretation(rawSlope),
    usedFallback: usedFallback,
    rmssdExerciseUsed: exerciseValue,
    recoveryTimeForSlopeMin: recoveryTimeMin,
  );
}

/// Computes RMSSD-Slope from a validated 5-minute recovery window.
SlopeResult computeSlopeForRecoveryWindow({
  required double rmssdRecovery,
  required double? rmssdExercise,
  required RecoveryWindow recoveryWindow,
}) {
  recoveryWindow.validate();

  final result = computeSlope(
    rmssdRecovery,
    rmssdExercise,
    recoveryWindow.recoveryTimeForSlopeMin,
  );

  return SlopeResult(
    rawSlope: result.rawSlope,
    interpretedSlope: result.interpretedSlope,
    usedFallback: result.usedFallback,
    rmssdExerciseUsed: result.rmssdExerciseUsed,
    recoveryTimeForSlopeMin: recoveryWindow.recoveryTimeForSlopeMin,
    recoveryWindowStartMin: recoveryWindow.startMin,
    recoveryWindowEndMin: recoveryWindow.endMin,
    recoveryWindowDurationMin: recoveryWindow.durationMin,
  );
}

/// Clamps a raw slope to the minimum interpretable value (0.1).
///
/// From Paper 1: "0.1 is considered the minimum value of the slopes,
/// so that for any value less than 0.1, this value would be assigned."
///
/// The raw value should always be preserved separately.
double clampSlopeForInterpretation(double rawSlope) {
  return max(kMinSlopeForInterpretation, rawSlope);
}

/// Computes the Internal Training Load index from the interpreted slope.
///
/// ITL = 1 / slope_interpreted
///
/// - [slopeInterpreted] must be ≥ 0.1 (already clamped).
double computeItlIndex(double slopeInterpreted) {
  assert(
    slopeInterpreted >= kMinSlopeForInterpretation,
    'slopeInterpreted must be ≥ $kMinSlopeForInterpretation',
  );
  return 1.0 / slopeInterpreted;
}
