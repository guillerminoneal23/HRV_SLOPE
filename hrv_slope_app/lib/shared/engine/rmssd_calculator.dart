/// RMSSD Calculator — Pure function for computing Root Mean Square of
/// Successive Differences from RR intervals.
///
/// Reference: Task Force of the European Society of Cardiology (1996).
/// RMSSD is the most used variable in sport due to the lower coefficient
/// of variation compared with other indices (Halson, 2014).
library;

import 'dart:math';

import 'package:hrv_slope_app/core/errors/hrv_errors.dart';
import 'package:hrv_slope_app/shared/engine/rr_quality.dart';

/// Computes RMSSD from a list of RR intervals in milliseconds.
///
/// RMSSD = sqrt( mean( (RR[i+1] - RR[i])² ) )
///
/// - [rrIntervalsMs] must contain at least 2 values, all > 0.
/// - Returns RMSSD in milliseconds.
///
/// Throws [InsufficientDataError] if fewer than 2 intervals.
/// Throws [InvalidDataError] if any interval is ≤ 0.
double computeRmssd(List<double> rrIntervalsMs) {
  if (rrIntervalsMs.length < 2) {
    throw InsufficientDataError(
      'Need at least 2 RR intervals, got ${rrIntervalsMs.length}.',
    );
  }

  for (int i = 0; i < rrIntervalsMs.length; i++) {
    if (rrIntervalsMs[i] <= 0) {
      throw InvalidDataError(
        'RR interval at index $i is ${rrIntervalsMs[i]} ms (must be > 0).',
      );
    }
  }

  double sumSquaredDiffs = 0.0;
  final int n = rrIntervalsMs.length - 1;

  for (int i = 0; i < n; i++) {
    final double diff = rrIntervalsMs[i + 1] - rrIntervalsMs[i];
    sumSquaredDiffs += diff * diff;
  }

  final double meanSquaredDiffs = sumSquaredDiffs / n;
  return sqrt(meanSquaredDiffs);
}

/// Computes RMSSD only after the RR window passes Phase 1.5 quality control.
///
/// This is the intended entry point for 5-minute exercise/recovery HRV windows.
double computeRmssdForValidatedWindow(List<double> rrIntervalsMs) {
  final quality = assessRrQuality(rrIntervalsMs);
  if (quality.qualityFlag == RrQualityFlag.invalid) {
    throw InvalidDataError(
      'RR interval window is invalid: ${quality.qualityNotes.join(' ')}',
    );
  }

  return computeRmssd(rrIntervalsMs);
}
