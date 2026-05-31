/// Individual Report Data Model and Builder.
///
/// Assembles all session data into a report-ready structure for the
/// individual report screen and future export.
library;

import 'dart:convert';

import 'package:hrv_slope_app/data/database/app_database.dart';
import 'package:hrv_slope_app/data/database/daos/sessions_dao.dart';
import 'package:hrv_slope_app/shared/engine/nomogram_engine.dart';

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

  const SlopeReportSummary({
    this.rawSlope,
    this.interpretedSlope,
    this.itlIndex,
    this.intensityPercent,
    this.intensitySource,
  });
}

/// Nomogram summary for the report (null if intensity missing).
class NomogramReportSummary {
  final String presetName;
  final double intensityPercent;
  final double observedSlope;
  final double expectedLower;
  final double expectedMean;
  final double expectedUpper;
  final double residual;
  final double residualPercent;
  final InternalLoadClassification classification;
  final String classificationLabel;
  final String interpretationText;
  final List<String> warnings;

  const NomogramReportSummary({
    required this.presetName,
    required this.intensityPercent,
    required this.observedSlope,
    required this.expectedLower,
    required this.expectedMean,
    required this.expectedUpper,
    required this.residual,
    required this.residualPercent,
    required this.classification,
    required this.classificationLabel,
    required this.interpretationText,
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

/// Returns neutral, training-load-focused interpretation text.
String interpretationTextFor(InternalLoadClassification c) {
  switch (c) {
    case InternalLoadClassification.veryHighInternalLoad:
      return 'Recovery was slower than expected for this intensity. '
          'Internal load appears high relative to the external load.';
    case InternalLoadClassification.highOrModerateInternalLoad:
      return 'Recovery was below the expected mean for this intensity. '
          'Monitor context, accumulated fatigue, and recent load.';
    case InternalLoadClassification.expectedResponse:
      return 'Recovery is within the expected population band for this '
          'intensity.';
    case InternalLoadClassification.lowInternalLoadOrFastRecovery:
      return 'Recovery was faster than the expected upper band for this '
          'intensity. Internal load appears low relative to the external '
          'load.';
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
      'Intensity percent is missing. Nomogram classification unavailable.',
    );
  }
  if (external.isEmpty) warnings.add('No external load variables recorded.');
  if (internal.isEmpty) warnings.add('No internal load variables recorded.');
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
  );

  // Nomogram classification
  NomogramReportSummary? nomogramSummary;
  final canShowNomogram =
      session.intensityPercent != null &&
      session.slopeInterpreted != null &&
      !session.isDraft;

  if (canShowNomogram) {
    final result = classifySlopeWithPopulationNomogram(
      session.intensityPercent!,
      session.slopeInterpreted!,
      source: nomogramPreset,
    );
    // Add extrapolation warnings
    if (result.warnings.isNotEmpty) {
      warnings.addAll(result.warnings);
    }
    nomogramSummary = NomogramReportSummary(
      presetName: nomogramPreset.presetName,
      intensityPercent: result.intensityPercent,
      observedSlope: result.observedSlope,
      expectedLower: result.expectedLower,
      expectedMean: result.expectedMean,
      expectedUpper: result.expectedUpper,
      residual: result.residual,
      residualPercent: result.residualPercent,
      classification: result.classification,
      classificationLabel: result.classification.label,
      interpretationText: interpretationTextFor(result.classification),
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
