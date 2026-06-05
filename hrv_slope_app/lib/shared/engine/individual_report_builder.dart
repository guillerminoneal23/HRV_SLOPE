/// Individual Report Data Model and Builder.
///
/// Assembles all session data into a report-ready structure for the
/// individual report screen and future export.
library;

import 'dart:convert';

import 'package:hrv_slope_app/data/database/app_database.dart';
import 'package:hrv_slope_app/data/database/daos/sessions_dao.dart';
import 'package:hrv_slope_app/shared/engine/intensity_resolver.dart';
import 'package:hrv_slope_app/shared/engine/nomogram_engine.dart';
import 'package:hrv_slope_app/shared/engine/nomogram_mode.dart';
import 'package:hrv_slope_app/shared/engine/nomogram_resolver.dart';

// ---------------------------------------------------------------------------
// Report data models
// ---------------------------------------------------------------------------

/// HRV summary for the report.
class HrvReportSummary {
  final String inputMode; // direct_rmssd | rr_intervals
  final double? rmssdRecovery;
  final String? rmssdRecoverySource;
  final double? rmssdExercise;
  final String? rmssdExerciseSource;
  final bool usedFallbackExercise;
  final double? recoveryWindowStartMin;
  final double? recoveryWindowEndMin;
  final double? tUsedForSlope;

  // RR preprocessing (only for rr_intervals mode)
  final double? rrRawRmssd;
  final double? rrCorrectedRmssd;
  final double? rrRmssdUsed;
  final bool rrCorrectionEnabled;
  final String? rrCorrectionMethod;
  final int? rrArtifactCount;
  final double? rrArtifactPercent;
  final String? rrQualityDecision;
  final List<String> rrQualityNotes;
  final double? rrRmssdDeltaPercent;

  const HrvReportSummary({
    required this.inputMode,
    this.rmssdRecovery,
    this.rmssdRecoverySource,
    this.rmssdExercise,
    this.rmssdExerciseSource,
    this.usedFallbackExercise = false,
    this.recoveryWindowStartMin,
    this.recoveryWindowEndMin,
    this.tUsedForSlope,
    this.rrRawRmssd,
    this.rrCorrectedRmssd,
    this.rrRmssdUsed,
    this.rrCorrectionEnabled = false,
    this.rrCorrectionMethod,
    this.rrArtifactCount,
    this.rrArtifactPercent,
    this.rrQualityDecision,
    this.rrQualityNotes = const [],
    this.rrRmssdDeltaPercent,
  });
}

/// Slope computation summary for the report.
class SlopeReportSummary {
  final double? rawSlope;
  final double? interpretedSlope;
  final double? itlIndex;
  final double? intensityPercent;
  final String? intensitySource;
  final String intensitySourceForSlope;
  final String? primaryIntensityMetric;

  const SlopeReportSummary({
    this.rawSlope,
    this.interpretedSlope,
    this.itlIndex,
    this.intensityPercent,
    this.intensitySource,
    this.intensitySourceForSlope = 'Unknown',
    this.primaryIntensityMetric,
  });
}

/// Nomogram summary for the report (null if intensity missing).
class NomogramReportSummary {
  final String presetName;
  final NomogramMode requestedMode;
  final NomogramMode activeMode;
  final double intensityPercent;
  final double observedSlope;
  final double expectedLower;
  final double expectedMean;
  final double expectedUpper;
  final double athleteWeightPercent;
  final double populationWeightPercent;
  final double residual;
  final double residualPercent;
  final InternalLoadClassification classification;
  final String classificationLabel;
  final String interpretationText;
  final bool isExtrapolated;
  final List<ReadinessGap> readinessGaps;
  final List<String> warnings;

  const NomogramReportSummary({
    required this.presetName,
    this.requestedMode = NomogramMode.population,
    this.activeMode = NomogramMode.population,
    required this.intensityPercent,
    required this.observedSlope,
    required this.expectedLower,
    required this.expectedMean,
    required this.expectedUpper,
    this.athleteWeightPercent = 0.0,
    this.populationWeightPercent = 100.0,
    required this.residual,
    required this.residualPercent,
    required this.classification,
    required this.classificationLabel,
    required this.interpretationText,
    this.isExtrapolated = false,
    this.readinessGaps = const [],
    required this.warnings,
  });
}

/// Full individual report data model.
class IndividualReportData {
  // Header
  final String athleteName;
  final String? sport;
  final String sessionDate;
  final String? taskName;
  final String? sessionType;
  final String? protocolName;
  final String? contextEnvironment;
  final bool isDraft;

  // Variables
  final List<IntensityVariable> externalVariables;
  final List<IntensityVariable> internalVariables;
  final List<IntensityVariable> derivedVariables;

  // Summaries
  final HrvReportSummary hrvSummary;
  final SlopeReportSummary slopeSummary;
  final NomogramReportSummary? nomogramSummary;

  // Warnings & flags
  final List<String> warnings;
  final bool canShowNomogram;
  final String? classification;

  const IndividualReportData({
    required this.athleteName,
    this.sport,
    required this.sessionDate,
    this.taskName,
    this.sessionType,
    this.protocolName,
    this.contextEnvironment,
    this.isDraft = false,
    required this.externalVariables,
    required this.internalVariables,
    required this.derivedVariables,
    required this.hrvSummary,
    required this.slopeSummary,
    this.nomogramSummary,
    required this.warnings,
    required this.canShowNomogram,
    this.classification,
  });
}

// ---------------------------------------------------------------------------
// Interpretation text mapping
// ---------------------------------------------------------------------------

/// Returns neutral recovery-response interpretation text.
String interpretationTextFor(InternalLoadClassification c) {
  switch (c) {
    case InternalLoadClassification.veryHighInternalLoad:
      return 'The post-effort response was lower than expected for this intensity. '
          'Review recent load, context, and recovery conditions.';
    case InternalLoadClassification.highOrModerateInternalLoad:
      return 'The post-effort response was below the expected mean for this intensity. '
          'Review context, accumulated fatigue, and recent load.';
    case InternalLoadClassification.expectedResponse:
      return 'The post-effort response is within the expected recovery-response band for this '
          'intensity.';
    case InternalLoadClassification.lowInternalLoadOrFastRecovery:
      return 'The post-effort response was favorable compared with the expected upper band for this '
          'intensity.';
  }
}

// ---------------------------------------------------------------------------
// Builder
// ---------------------------------------------------------------------------

/// Builds an [IndividualReportData] from a [SessionDetail] and a nomogram
/// preset. Pure function (no DB access).
IndividualReportData buildIndividualReport({
  required SessionDetail detail,
  required PopulationNomogramSource nomogramPreset,
  NomogramMode requestedNomogramMode = NomogramMode.population,
  List<SessionDetail> athleteHistory = const [],
  IndividualModelBands? individualModelBands,
  IndividualReadiness? individualReadiness,
}) {
  final session = detail.session;
  final athlete = detail.athlete;
  final external = detail.variablesByCategory('external');
  final internal = detail.variablesByCategory('internal');
  final derived = detail.variablesByCategory('derived');

  // Warnings
  final warnings = <String>[];
  if (session.isDraft) warnings.add('Session is a draft — results incomplete.');
  if (session.intensityPercent == null) {
    warnings.add(
      'Intensity percent is missing. Recovery interpretation unavailable.',
    );
  }
  if (external.isEmpty) warnings.add('No external load variables recorded.');
  if (internal.isEmpty) {
    warnings.add('No internal intensity variables recorded.');
  }
  if (session.rmssdExerciseIsDefault) {
    warnings.add(
      'RMSSD exercise was not provided. The validated 4 ms fallback was used.',
    );
  }
  if (session.rrQualityDecision == 'warning') {
    warnings.add('RR quality: warning-level artifacts detected.');
  }
  if (session.rrCorrectionEnabled) {
    warnings.add(
      'RR correction was enabled (${session.rrCorrectionMethod ?? "unknown"}).',
    );
  }
  if (session.rmssdRecovery == null) {
    warnings.add('RMSSD recovery is missing. Slope cannot be computed.');
  }

  // Quality notes
  List<String> qualityNotes;
  try {
    final decoded = jsonDecode(session.rrQualityNotesJson ?? '');
    qualityNotes = decoded is List
        ? decoded.map((e) => e.toString()).toList()
        : [];
  } catch (_) {
    qualityNotes = [];
  }

  // HRV summary
  final hrv = HrvReportSummary(
    inputMode: session.hrvInputMode ?? 'direct_rmssd',
    rmssdRecovery: session.rmssdRecovery,
    rmssdRecoverySource: session.rmssdRecoverySource,
    rmssdExercise: session.rmssdExercise,
    rmssdExerciseSource: session.rmssdExerciseSource,
    usedFallbackExercise: session.rmssdExerciseIsDefault,
    recoveryWindowStartMin: session.recoveryWindowStartMin,
    recoveryWindowEndMin: session.recoveryWindowEndMin,
    tUsedForSlope: session.recoveryTimeMin,
    rrRawRmssd: session.rrRawRmssd,
    rrCorrectedRmssd: session.rrCorrectedRmssd,
    rrRmssdUsed: session.rrRmssdUsed,
    rrCorrectionEnabled: session.rrCorrectionEnabled,
    rrCorrectionMethod: session.rrCorrectionMethod,
    rrArtifactCount: session.rrArtifactCount,
    rrArtifactPercent: session.rrArtifactPercent,
    rrQualityDecision: session.rrQualityDecision,
    rrQualityNotes: qualityNotes,
    rrRmssdDeltaPercent: session.rrRmssdDeltaPercent,
  );

  // Slope summary
  final slope = SlopeReportSummary(
    rawSlope: session.slopeRaw,
    interpretedSlope: session.slopeInterpreted,
    itlIndex: session.itlIndex,
    intensityPercent: session.intensityPercent,
    intensitySource: session.intensitySource,
    intensitySourceForSlope: intensitySourceForSlopeLabel(
      session.intensitySource,
    ),
    primaryIntensityMetric: primaryIntensityMetricFromMethod(
      session.intensitySource,
    ),
  );

  // Nomogram classification
  NomogramReportSummary? nomogramSummary;
  final canShowNomogram =
      session.intensityPercent != null &&
      session.slopeInterpreted != null &&
      !session.isDraft;

  if (canShowNomogram) {
    final individualModel = _resolveIndividualModelForReport(
      currentDetail: detail,
      athleteHistory: athleteHistory,
      providedBands: individualModelBands,
      providedReadiness: individualReadiness,
      shouldResolve: requestedNomogramMode != NomogramMode.population,
    );
    warnings.addAll(individualModel.warnings);

    final resolvedBands = resolveNomogramBands(
      intensityPercent: session.intensityPercent!,
      requestedMode: requestedNomogramMode,
      populationPreset: nomogramPreset,
      individualBands: individualModel.bands,
      readiness: individualModel.readiness,
    );

    final result = classifySlopeAgainstBands(
      modelSource: resolvedBands.source,
      presetName: nomogramPreset.presetName,
      intensityPercent: session.intensityPercent!,
      observedSlope: session.slopeInterpreted!,
      expectedLower: resolvedBands.lower,
      expectedMean: resolvedBands.mean,
      expectedUpper: resolvedBands.upper,
      warnings: resolvedBands.warnings,
    );

    if (result.warnings.isNotEmpty) {
      warnings.addAll(result.warnings);
    }

    final readinessGaps =
        requestedNomogramMode == NomogramMode.individual &&
            resolvedBands.activeMode != NomogramMode.individual
        ? individualModel.readiness?.gaps ?? const <ReadinessGap>[]
        : const <ReadinessGap>[];

    nomogramSummary = NomogramReportSummary(
      presetName: nomogramPreset.presetName,
      requestedMode: requestedNomogramMode,
      activeMode: resolvedBands.activeMode,
      intensityPercent: result.intensityPercent,
      observedSlope: result.observedSlope,
      expectedLower: result.expectedLower,
      expectedMean: result.expectedMean,
      expectedUpper: result.expectedUpper,
      athleteWeightPercent: resolvedBands.athleteWeightPercent,
      populationWeightPercent: resolvedBands.populationWeightPercent,
      residual: result.residual,
      residualPercent: result.residualPercent,
      classification: result.classification,
      classificationLabel: result.classification.label,
      interpretationText: interpretationTextFor(result.classification),
      isExtrapolated: resolvedBands.isExtrapolated,
      readinessGaps: List.unmodifiable(readinessGaps),
      warnings: result.warnings,
    );
  }

  return IndividualReportData(
    athleteName: athlete.name,
    sport: session.sport ?? athlete.sport,
    sessionDate: session.date,
    taskName: session.taskName,
    sessionType: session.sessionType,
    protocolName: session.protocolName,
    contextEnvironment: session.contextEnvironment,
    isDraft: session.isDraft,
    externalVariables: external,
    internalVariables: internal,
    derivedVariables: derived,
    hrvSummary: hrv,
    slopeSummary: slope,
    nomogramSummary: nomogramSummary,
    warnings: warnings,
    canShowNomogram: canShowNomogram,
    classification: session.classification,
  );
}

class _ReportIndividualModel {
  final IndividualModelBands? bands;
  final IndividualReadiness? readiness;
  final List<String> warnings;

  const _ReportIndividualModel({
    required this.bands,
    required this.readiness,
    required this.warnings,
  });
}

_ReportIndividualModel _resolveIndividualModelForReport({
  required SessionDetail currentDetail,
  required List<SessionDetail> athleteHistory,
  required IndividualModelBands? providedBands,
  required IndividualReadiness? providedReadiness,
  required bool shouldResolve,
}) {
  if (!shouldResolve) {
    return const _ReportIndividualModel(
      bands: null,
      readiness: null,
      warnings: [],
    );
  }

  final sourcePoints = _individualSourcePoints(
    currentDetail: currentDetail,
    athleteHistory: athleteHistory,
  );
  final warnings = <String>[];
  var bands = providedBands;
  var readiness = providedReadiness;

  if (bands == null && sourcePoints.length >= 3) {
    try {
      final fittedModel = fitIndividualNomogram(sourcePoints);
      bands = buildIndividualModelBands(
        fittedModel: fittedModel,
        sourcePoints: sourcePoints,
      );
    } catch (error) {
      warnings.add('Individual model unavailable for report: $error');
    }
  }

  readiness ??= evaluateIndividualReadiness(
    intensities: sourcePoints.map((point) => point.intensityPercent).toList(),
    rSquared: bands?.rSquared,
    cvRmse: bands?.cvRmse,
  );

  return _ReportIndividualModel(
    bands: bands,
    readiness: readiness,
    warnings: List.unmodifiable(warnings),
  );
}

List<NomogramPoint> _individualSourcePoints({
  required SessionDetail currentDetail,
  required List<SessionDetail> athleteHistory,
}) {
  final athleteId = currentDetail.athlete.id;
  final bySessionId = <int, SessionDetail>{
    currentDetail.session.id: currentDetail,
    for (final detail in athleteHistory)
      if (detail.athlete.id == athleteId) detail.session.id: detail,
  };
  final points = <NomogramPoint>[];

  for (final detail in bySessionId.values) {
    final session = detail.session;
    final intensity = session.intensityPercent;
    final slope = session.slopeInterpreted;
    if (session.isDraft ||
        intensity == null ||
        slope == null ||
        !intensity.isFinite ||
        !slope.isFinite ||
        intensity <= 0 ||
        slope <= 0) {
      continue;
    }
    points.add(NomogramPoint(intensityPercent: intensity, slope: slope));
  }

  return List.unmodifiable(points);
}
