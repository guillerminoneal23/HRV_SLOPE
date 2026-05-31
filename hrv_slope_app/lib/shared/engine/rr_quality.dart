/// RR interval quality-control helpers for 5-minute RMSSD windows.
library;

/// Quality flag for a candidate RR interval window.
enum RrQualityFlag { valid, warning, invalid }

/// Pure quality report for RR interval data.
class RrQualityReport {
  final int rrCount;
  final double recordingDurationSec;
  final double? meanRrMs;
  final double? minRrMs;
  final double? maxRrMs;
  final int artifactCountEstimate;
  final double artifactPercentEstimate;
  final RrQualityFlag qualityFlag;
  final List<String> qualityNotes;

  const RrQualityReport({
    required this.rrCount,
    required this.recordingDurationSec,
    required this.meanRrMs,
    required this.minRrMs,
    required this.maxRrMs,
    required this.artifactCountEstimate,
    required this.artifactPercentEstimate,
    required this.qualityFlag,
    required this.qualityNotes,
  });
}

/// Assesses RR interval quality without correcting or mutating the input.
RrQualityReport assessRrQuality(List<double> rrIntervalsMs) {
  final notes = <String>[];

  if (rrIntervalsMs.isEmpty) {
    return const RrQualityReport(
      rrCount: 0,
      recordingDurationSec: 0,
      meanRrMs: null,
      minRrMs: null,
      maxRrMs: null,
      artifactCountEstimate: 0,
      artifactPercentEstimate: 0,
      qualityFlag: RrQualityFlag.invalid,
      qualityNotes: ['RR interval list is empty.'],
    );
  }

  final validIntervals = <double>[];
  int artifactCount = 0;

  for (final rr in rrIntervalsMs) {
    if (rr <= 300 || rr >= 2200) {
      artifactCount++;
    } else {
      validIntervals.add(rr);
    }
  }

  final rrCount = rrIntervalsMs.length;
  final artifactPercent = artifactCount / rrCount * 100.0;
  final recordingDurationSec =
      validIntervals.fold<double>(0, (sum, rr) => sum + rr) / 1000.0;

  double? mean;
  double? minValue;
  double? maxValue;
  if (validIntervals.isNotEmpty) {
    mean = validIntervals.reduce((a, b) => a + b) / validIntervals.length;
    minValue = validIntervals.reduce((a, b) => a < b ? a : b);
    maxValue = validIntervals.reduce((a, b) => a > b ? a : b);
  }

  var flag = RrQualityFlag.valid;

  if (rrCount < 2) {
    notes.add('Fewer than 2 RR intervals.');
    flag = RrQualityFlag.invalid;
  }

  if (recordingDurationSec < 300) {
    notes.add(
      'Effective recording duration is below 300 seconds '
      '(${recordingDurationSec.toStringAsFixed(1)} sec).',
    );
    flag = RrQualityFlag.invalid;
  }

  if (artifactCount > 0) {
    notes.add('$artifactCount RR intervals are outside 300-2200 ms.');
  }

  if (artifactPercent > 10) {
    notes.add(
      'Artifact estimate exceeds 10% '
      '(${artifactPercent.toStringAsFixed(1)}%).',
    );
    flag = RrQualityFlag.invalid;
  } else if (artifactPercent > 5 && flag != RrQualityFlag.invalid) {
    notes.add(
      'Artifact estimate exceeds 5% '
      '(${artifactPercent.toStringAsFixed(1)}%).',
    );
    flag = RrQualityFlag.warning;
  }

  if (notes.isEmpty) {
    notes.add('RR interval window passed Phase 1.5 quality checks.');
  }

  return RrQualityReport(
    rrCount: rrCount,
    recordingDurationSec: recordingDurationSec,
    meanRrMs: mean,
    minRrMs: minValue,
    maxRrMs: maxValue,
    artifactCountEstimate: artifactCount,
    artifactPercentEstimate: artifactPercent,
    qualityFlag: flag,
    qualityNotes: List.unmodifiable(notes),
  );
}
