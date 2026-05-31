/// RR/NN preprocessing for auditable RR-derived RMSSD workflows.
///
/// This module operates on beat-to-beat RR intervals, not raw ECG/PPG signals.
/// It implements interval preprocessing and optional linear correction to
/// produce NN intervals for RMSSD.
library;

import 'dart:math';

import 'package:hrv_slope_app/core/errors/hrv_errors.dart';
import 'package:hrv_slope_app/shared/engine/rmssd_calculator.dart';

enum RrPreprocessingMode {
  none,
  rangeOnly,
  rangeAndEctopic,
  localMedianThreshold,
}

enum RrCorrectionMethod {
  none,
  rangeOutlierLinearInterpolation,
  malikLinearInterpolation,
  kamathLinearInterpolation,
  karlssonLinearInterpolation,
  acarLinearInterpolation,
  localMedianLinearInterpolation,
}

enum RrArtifactType {
  tooShort,
  tooLong,
  suddenChange,
  malikEctopic,
  kamathEctopic,
  karlssonEctopic,
  acarEctopic,
  localMedianOutlier,
}

enum RrQualityDecision { valid, warning, invalid }

enum LocalMedianThresholdPreset {
  veryLow(450),
  low(350),
  medium(250),
  strong(150),
  veryStrong(50);

  final double thresholdMs;
  const LocalMedianThresholdPreset(this.thresholdMs);
}

class RrArtifactEvent {
  final int index;
  final double originalValueMs;
  final double? previousValueMs;
  final double? nextValueMs;
  final RrArtifactType artifactType;
  final String reason;
  final double? proposedReplacementMs;

  const RrArtifactEvent({
    required this.index,
    required this.originalValueMs,
    required this.previousValueMs,
    required this.nextValueMs,
    required this.artifactType,
    required this.reason,
    this.proposedReplacementMs,
  });

  RrArtifactEvent withReplacement(double? replacement) {
    return RrArtifactEvent(
      index: index,
      originalValueMs: originalValueMs,
      previousValueMs: previousValueMs,
      nextValueMs: nextValueMs,
      artifactType: artifactType,
      reason: reason,
      proposedReplacementMs: replacement,
    );
  }
}

class RrPreprocessingOptions {
  final double lowRriMs;
  final double highRriMs;
  final RrPreprocessingMode mode;
  final RrCorrectionMethod ectopicMethod;
  final String interpolationMethod;
  final int localMedianWindow;
  final double localMedianThresholdMs;
  final double artifactWarningPercent;
  final double artifactInvalidPercent;
  final bool preserveRawRmssd;
  final bool correctionEnabled;

  const RrPreprocessingOptions({
    this.lowRriMs = 300,
    this.highRriMs = 2200,
    this.mode = RrPreprocessingMode.rangeAndEctopic,
    this.ectopicMethod = RrCorrectionMethod.karlssonLinearInterpolation,
    this.interpolationMethod = 'linear',
    this.localMedianWindow = 5,
    this.localMedianThresholdMs = 250,
    this.artifactWarningPercent = 5.0,
    this.artifactInvalidPercent = 10.0,
    this.preserveRawRmssd = true,
    this.correctionEnabled = false,
  });

  RrCorrectionMethod get correctionMethod {
    if (!correctionEnabled) return RrCorrectionMethod.none;
    return switch (mode) {
      RrPreprocessingMode.none => RrCorrectionMethod.none,
      RrPreprocessingMode.rangeOnly =>
        RrCorrectionMethod.rangeOutlierLinearInterpolation,
      RrPreprocessingMode.rangeAndEctopic => ectopicMethod,
      RrPreprocessingMode.localMedianThreshold =>
        RrCorrectionMethod.localMedianLinearInterpolation,
    };
  }

  RrPreprocessingOptions copyWith({
    double? lowRriMs,
    double? highRriMs,
    RrPreprocessingMode? mode,
    RrCorrectionMethod? ectopicMethod,
    String? interpolationMethod,
    int? localMedianWindow,
    double? localMedianThresholdMs,
    double? artifactWarningPercent,
    double? artifactInvalidPercent,
    bool? preserveRawRmssd,
    bool? correctionEnabled,
  }) {
    return RrPreprocessingOptions(
      lowRriMs: lowRriMs ?? this.lowRriMs,
      highRriMs: highRriMs ?? this.highRriMs,
      mode: mode ?? this.mode,
      ectopicMethod: ectopicMethod ?? this.ectopicMethod,
      interpolationMethod: interpolationMethod ?? this.interpolationMethod,
      localMedianWindow: localMedianWindow ?? this.localMedianWindow,
      localMedianThresholdMs:
          localMedianThresholdMs ?? this.localMedianThresholdMs,
      artifactWarningPercent:
          artifactWarningPercent ?? this.artifactWarningPercent,
      artifactInvalidPercent:
          artifactInvalidPercent ?? this.artifactInvalidPercent,
      preserveRawRmssd: preserveRawRmssd ?? this.preserveRawRmssd,
      correctionEnabled: correctionEnabled ?? this.correctionEnabled,
    );
  }
}

class RrPreprocessingResult {
  final List<double> rawRrIntervals;
  final List<double> cleanedNnIntervals;
  final RrPreprocessingMode preprocessingMode;
  final double rawRmssd;
  final double? correctedRmssd;
  final double rmssdUsed;
  final bool correctionApplied;
  final RrCorrectionMethod correctionMethod;
  final List<RrArtifactEvent> artifactEvents;
  final int artifactCount;
  final double artifactPercent;
  final double durationRawSec;
  final double durationCleanedSec;
  final RrQualityDecision qualityDecision;
  final List<String> qualityNotes;
  final List<String> warnings;
  final double? rmssdDelta;
  final double? rmssdDeltaPercent;

  const RrPreprocessingResult({
    required this.rawRrIntervals,
    required this.cleanedNnIntervals,
    required this.preprocessingMode,
    required this.rawRmssd,
    required this.correctedRmssd,
    required this.rmssdUsed,
    required this.correctionApplied,
    required this.correctionMethod,
    required this.artifactEvents,
    required this.artifactCount,
    required this.artifactPercent,
    required this.durationRawSec,
    required this.durationCleanedSec,
    required this.qualityDecision,
    required this.qualityNotes,
    required this.warnings,
    required this.rmssdDelta,
    required this.rmssdDeltaPercent,
  });
}

class RrInterpolationResult {
  final List<double> intervals;
  final Map<int, double> replacementsByIndex;

  const RrInterpolationResult({
    required this.intervals,
    required this.replacementsByIndex,
  });
}

double computeRawRmssdFromRr(List<double> rrIntervals) {
  if (rrIntervals.isEmpty) {
    throw InsufficientDataError('RR interval list is empty.');
  }
  if (rrIntervals.length < 2) {
    throw InsufficientDataError(
      'Need at least 2 RR intervals, got ${rrIntervals.length}.',
    );
  }
  for (var i = 0; i < rrIntervals.length; i++) {
    if (rrIntervals[i] <= 0) {
      throw InvalidDataError(
        'RR interval at index $i is ${rrIntervals[i]} ms (must be > 0).',
      );
    }
  }
  return computeRmssd(rrIntervals);
}

RrPreprocessingResult preprocessRrIntervals(
  List<double> rrIntervals,
  RrPreprocessingOptions options,
) {
  if (rrIntervals.isEmpty) {
    return _invalidEmptyResult(options);
  }

  if (rrIntervals.length < 2) {
    return _invalidShortResult(rrIntervals, options);
  }

  final raw = List<double>.unmodifiable(rrIntervals);
  final rawRmssd = computeRawRmssdFromRr(raw);
  final durationRawSec = _durationSec(raw);
  var events = <RrArtifactEvent>[];

  if (options.mode != RrPreprocessingMode.none) {
    events.addAll(
      detectRangeOutliers(raw, options.lowRriMs, options.highRriMs),
    );
  }

  final rangeIndexes = events.map((e) => e.index).toSet();
  final stageAfterRange = interpolateMarkedIntervalsLinear(raw, rangeIndexes);

  if (options.mode == RrPreprocessingMode.rangeAndEctopic) {
    events = _mergeEvents(
      events,
      _detectEctopics(stageAfterRange.intervals, options, rangeIndexes),
    );
  } else if (options.mode == RrPreprocessingMode.localMedianThreshold) {
    events = _mergeEvents(
      events,
      detectLocalMedianOutliers(
        stageAfterRange.intervals,
        windowSize: options.localMedianWindow,
        thresholdMs: options.localMedianThresholdMs,
        excludedIndexes: rangeIndexes,
      ),
    );
  }

  final artifactIndexes = events.map((e) => e.index).toSet();
  final replacementPreview = interpolateMarkedIntervalsLinear(
    raw,
    artifactIndexes,
  );
  events = [
    for (final event in events)
      event.withReplacement(
        replacementPreview.replacementsByIndex[event.index],
      ),
  ]..sort((a, b) => a.index.compareTo(b.index));

  final artifactCount = artifactIndexes.length;
  final artifactPercent = artifactCount / raw.length * 100.0;

  List<double> cleanedNn = raw;
  double? correctedRmssd;
  double rmssdUsed = rawRmssd;
  var correctionApplied = false;

  if (options.correctionEnabled && artifactIndexes.isNotEmpty) {
    cleanedNn = replacementPreview.intervals;
    correctedRmssd = computeRmssd(cleanedNn);
    rmssdUsed = correctedRmssd;
    correctionApplied = true;
  } else if (options.correctionEnabled && artifactIndexes.isEmpty) {
    cleanedNn = raw;
    correctedRmssd = rawRmssd;
    rmssdUsed = rawRmssd;
    correctionApplied = true;
  }

  final rmssdDelta = correctedRmssd == null ? null : correctedRmssd - rawRmssd;
  final rmssdDeltaPercent = correctedRmssd == null || rawRmssd == 0
      ? null
      : rmssdDelta! / rawRmssd * 100.0;

  final notes = <String>[];
  final warnings = <String>[];
  var decision = RrQualityDecision.valid;

  if (durationRawSec < 300) {
    notes.add(
      'Total raw duration is below 300 seconds '
      '(${durationRawSec.toStringAsFixed(1)} sec).',
    );
    decision = RrQualityDecision.invalid;
  }

  if (artifactCount > 0) {
    notes.add(
      '$artifactCount artifacts detected '
      '(${artifactPercent.toStringAsFixed(2)}%).',
    );
  }

  if (artifactPercent > options.artifactInvalidPercent) {
    warnings.add(
      'Artifact percent exceeds invalid threshold '
      '(${artifactPercent.toStringAsFixed(1)}% > '
      '${options.artifactInvalidPercent.toStringAsFixed(1)}%).',
    );
    decision = RrQualityDecision.invalid;
  } else if (artifactPercent > options.artifactWarningPercent &&
      decision != RrQualityDecision.invalid) {
    warnings.add(
      'Artifact percent exceeds warning threshold '
      '(${artifactPercent.toStringAsFixed(1)}% > '
      '${options.artifactWarningPercent.toStringAsFixed(1)}%).',
    );
    decision = RrQualityDecision.warning;
  }

  if (!options.correctionEnabled &&
      artifactCount > 0 &&
      decision != RrQualityDecision.invalid) {
    warnings.add('Artifacts detected while correction is off; raw RMSSD used.');
    decision = RrQualityDecision.warning;
  }

  if (rmssdDeltaPercent != null &&
      rmssdDeltaPercent.abs() > 10 &&
      decision != RrQualityDecision.invalid) {
    warnings.add(
      'Correction changed RMSSD by '
      '${rmssdDeltaPercent.toStringAsFixed(1)}%.',
    );
    decision = RrQualityDecision.warning;
  }

  if (notes.isEmpty) {
    notes.add('RR preprocessing checks passed.');
  }

  return RrPreprocessingResult(
    rawRrIntervals: raw,
    cleanedNnIntervals: List<double>.unmodifiable(cleanedNn),
    preprocessingMode: options.mode,
    rawRmssd: rawRmssd,
    correctedRmssd: correctedRmssd,
    rmssdUsed: rmssdUsed,
    correctionApplied: correctionApplied,
    correctionMethod: options.correctionMethod,
    artifactEvents: List.unmodifiable(events),
    artifactCount: artifactCount,
    artifactPercent: artifactPercent,
    durationRawSec: durationRawSec,
    durationCleanedSec: _durationSec(cleanedNn),
    qualityDecision: decision,
    qualityNotes: List.unmodifiable(notes),
    warnings: List.unmodifiable(warnings),
    rmssdDelta: rmssdDelta,
    rmssdDeltaPercent: rmssdDeltaPercent,
  );
}

List<RrArtifactEvent> detectRangeOutliers(
  List<double> rrIntervals,
  double lowRriMs,
  double highRriMs,
) {
  final events = <RrArtifactEvent>[];
  for (var i = 0; i < rrIntervals.length; i++) {
    final rr = rrIntervals[i];
    if (rr <= lowRriMs) {
      events.add(
        _event(
          rrIntervals,
          i,
          RrArtifactType.tooShort,
          'RR <= ${lowRriMs.toStringAsFixed(0)} ms.',
        ),
      );
    } else if (rr >= highRriMs) {
      events.add(
        _event(
          rrIntervals,
          i,
          RrArtifactType.tooLong,
          'RR >= ${highRriMs.toStringAsFixed(0)} ms.',
        ),
      );
    }
  }
  return events;
}

List<RrArtifactEvent> detectMalikEctopics(
  List<double> rrIntervals, {
  Set<int> excludedIndexes = const {},
}) {
  final events = <RrArtifactEvent>[];
  for (var i = 0; i < rrIntervals.length - 1; i++) {
    final nextIndex = i + 1;
    if (excludedIndexes.contains(nextIndex)) continue;
    final current = rrIntervals[i];
    final next = rrIntervals[nextIndex];
    if ((current - next).abs() > 0.2 * current) {
      events.add(
        _event(
          rrIntervals,
          nextIndex,
          RrArtifactType.malikEctopic,
          'Consecutive RR change exceeds 20% of previous interval.',
        ),
      );
    }
  }
  return events;
}

List<RrArtifactEvent> detectKamathEctopics(
  List<double> rrIntervals, {
  Set<int> excludedIndexes = const {},
}) {
  final events = <RrArtifactEvent>[];
  for (var i = 0; i < rrIntervals.length - 1; i++) {
    final nextIndex = i + 1;
    if (excludedIndexes.contains(nextIndex)) continue;
    final current = rrIntervals[i];
    final next = rrIntervals[nextIndex];
    final increase = next - current;
    final decrease = current - next;
    final allowed = increase >= 0
        ? increase <= 0.325 * current
        : decrease <= 0.245 * current;
    if (!allowed) {
      events.add(
        _event(
          rrIntervals,
          nextIndex,
          RrArtifactType.kamathEctopic,
          'RR change exceeds Kamath allowed increase/decrease thresholds.',
        ),
      );
    }
  }
  return events;
}

List<RrArtifactEvent> detectKarlssonEctopics(
  List<double> rrIntervals, {
  Set<int> excludedIndexes = const {},
}) {
  final events = <RrArtifactEvent>[];
  for (var i = 1; i < rrIntervals.length - 1; i++) {
    if (excludedIndexes.contains(i)) continue;
    final meanPrevNext = (rrIntervals[i - 1] + rrIntervals[i + 1]) / 2.0;
    if ((rrIntervals[i] - meanPrevNext).abs() > 0.2 * meanPrevNext) {
      events.add(
        _event(
          rrIntervals,
          i,
          RrArtifactType.karlssonEctopic,
          'RR differs by more than 20% from mean of adjacent intervals.',
        ),
      );
    }
  }
  return events;
}

List<RrArtifactEvent> detectAcarEctopics(
  List<double> rrIntervals, {
  Set<int> excludedIndexes = const {},
}) {
  final events = <RrArtifactEvent>[];
  final accepted = <double>[];
  for (var i = 0; i < rrIntervals.length; i++) {
    final rr = rrIntervals[i];
    if (i >= 9 && accepted.length >= 9 && !excludedIndexes.contains(i)) {
      final previous9 = accepted.sublist(accepted.length - 9);
      final meanPrevious9 =
          previous9.reduce((a, b) => a + b) / previous9.length;
      if ((rr - meanPrevious9).abs() > 0.2 * meanPrevious9) {
        events.add(
          _event(
            rrIntervals,
            i,
            RrArtifactType.acarEctopic,
            'RR differs by more than 20% from mean of previous 9 intervals.',
          ),
        );
        accepted.add(meanPrevious9);
        continue;
      }
    }
    accepted.add(rr);
  }
  return events;
}

List<RrArtifactEvent> detectLocalMedianOutliers(
  List<double> rrIntervals, {
  int windowSize = 5,
  double thresholdMs = 250,
  Set<int> excludedIndexes = const {},
}) {
  final events = <RrArtifactEvent>[];
  final radius = max(1, windowSize ~/ 2);

  for (var i = 0; i < rrIntervals.length; i++) {
    if (excludedIndexes.contains(i)) continue;
    final start = max(0, i - radius);
    final end = min(rrIntervals.length - 1, i + radius);
    final local = <double>[];
    for (var j = start; j <= end; j++) {
      if (j != i && !excludedIndexes.contains(j)) {
        local.add(rrIntervals[j]);
      }
    }
    if (local.isEmpty) continue;
    final median = _median(local);
    final diff = (rrIntervals[i] - median).abs();
    if (diff > thresholdMs) {
      events.add(
        _event(
          rrIntervals,
          i,
          RrArtifactType.localMedianOutlier,
          'RR differs from local median by '
          '${diff.toStringAsFixed(1)} ms, above '
          '${thresholdMs.toStringAsFixed(0)} ms threshold.',
        ),
      );
    }
  }

  return events;
}

RrInterpolationResult interpolateMarkedIntervalsLinear(
  List<double> rrIntervals,
  Set<int> invalidIndexes,
) {
  if (rrIntervals.isEmpty || invalidIndexes.isEmpty) {
    return RrInterpolationResult(
      intervals: List<double>.from(rrIntervals),
      replacementsByIndex: const {},
    );
  }

  final output = List<double>.from(rrIntervals);
  final replacements = <int, double>{};
  final validIndexes = <int>[
    for (var i = 0; i < rrIntervals.length; i++)
      if (!invalidIndexes.contains(i)) i,
  ];

  if (validIndexes.isEmpty) {
    return RrInterpolationResult(
      intervals: output,
      replacementsByIndex: const {},
    );
  }

  for (final index in invalidIndexes.toList()..sort()) {
    if (index < 0 || index >= rrIntervals.length) continue;

    final previousValid = validIndexes.lastWhere(
      (i) => i < index,
      orElse: () => -1,
    );
    final nextValid = validIndexes.firstWhere(
      (i) => i > index,
      orElse: () => -1,
    );

    double replacement;
    if (previousValid == -1 && nextValid == -1) {
      replacement = rrIntervals[index];
    } else if (previousValid == -1) {
      replacement = rrIntervals[nextValid];
    } else if (nextValid == -1) {
      replacement = rrIntervals[previousValid];
    } else {
      final span = nextValid - previousValid;
      final fraction = (index - previousValid) / span;
      replacement =
          rrIntervals[previousValid] +
          fraction * (rrIntervals[nextValid] - rrIntervals[previousValid]);
    }

    output[index] = replacement;
    replacements[index] = replacement;
  }

  return RrInterpolationResult(
    intervals: output,
    replacementsByIndex: Map.unmodifiable(replacements),
  );
}

List<RrArtifactEvent> _detectEctopics(
  List<double> rrIntervals,
  RrPreprocessingOptions options,
  Set<int> excludedIndexes,
) {
  return switch (options.ectopicMethod) {
    RrCorrectionMethod.malikLinearInterpolation => detectMalikEctopics(
      rrIntervals,
      excludedIndexes: excludedIndexes,
    ),
    RrCorrectionMethod.kamathLinearInterpolation => detectKamathEctopics(
      rrIntervals,
      excludedIndexes: excludedIndexes,
    ),
    RrCorrectionMethod.acarLinearInterpolation => detectAcarEctopics(
      rrIntervals,
      excludedIndexes: excludedIndexes,
    ),
    RrCorrectionMethod.karlssonLinearInterpolation => detectKarlssonEctopics(
      rrIntervals,
      excludedIndexes: excludedIndexes,
    ),
    _ => detectKarlssonEctopics(rrIntervals, excludedIndexes: excludedIndexes),
  };
}

List<RrArtifactEvent> _mergeEvents(
  List<RrArtifactEvent> existing,
  List<RrArtifactEvent> incoming,
) {
  final byIndex = <int, RrArtifactEvent>{
    for (final event in existing) event.index: event,
  };
  for (final event in incoming) {
    byIndex.putIfAbsent(event.index, () => event);
  }
  return byIndex.values.toList()..sort((a, b) => a.index.compareTo(b.index));
}

RrArtifactEvent _event(
  List<double> rrIntervals,
  int index,
  RrArtifactType type,
  String reason,
) {
  return RrArtifactEvent(
    index: index,
    originalValueMs: rrIntervals[index],
    previousValueMs: index > 0 ? rrIntervals[index - 1] : null,
    nextValueMs: index < rrIntervals.length - 1 ? rrIntervals[index + 1] : null,
    artifactType: type,
    reason: reason,
  );
}

double _durationSec(List<double> intervals) {
  return intervals.fold<double>(0, (sum, rr) => sum + rr) / 1000.0;
}

double _median(List<double> values) {
  final sorted = List<double>.from(values)..sort();
  final mid = sorted.length ~/ 2;
  if (sorted.length.isOdd) return sorted[mid];
  return (sorted[mid - 1] + sorted[mid]) / 2.0;
}

RrPreprocessingResult _invalidEmptyResult(RrPreprocessingOptions options) {
  return RrPreprocessingResult(
    rawRrIntervals: const [],
    cleanedNnIntervals: const [],
    preprocessingMode: options.mode,
    rawRmssd: 0,
    correctedRmssd: null,
    rmssdUsed: 0,
    correctionApplied: false,
    correctionMethod: options.correctionMethod,
    artifactEvents: const [],
    artifactCount: 0,
    artifactPercent: 0,
    durationRawSec: 0,
    durationCleanedSec: 0,
    qualityDecision: RrQualityDecision.invalid,
    qualityNotes: const ['RR interval list is empty.'],
    warnings: const [],
    rmssdDelta: null,
    rmssdDeltaPercent: null,
  );
}

RrPreprocessingResult _invalidShortResult(
  List<double> rrIntervals,
  RrPreprocessingOptions options,
) {
  final duration = _durationSec(rrIntervals);
  return RrPreprocessingResult(
    rawRrIntervals: List.unmodifiable(rrIntervals),
    cleanedNnIntervals: List.unmodifiable(rrIntervals),
    preprocessingMode: options.mode,
    rawRmssd: 0,
    correctedRmssd: null,
    rmssdUsed: 0,
    correctionApplied: false,
    correctionMethod: options.correctionMethod,
    artifactEvents: const [],
    artifactCount: 0,
    artifactPercent: 0,
    durationRawSec: duration,
    durationCleanedSec: duration,
    qualityDecision: RrQualityDecision.invalid,
    qualityNotes: const ['Fewer than 2 RR intervals.'],
    warnings: const [],
    rmssdDelta: null,
    rmssdDeltaPercent: null,
  );
}
