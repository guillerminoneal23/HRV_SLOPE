/// Individual nomogram data builder.
///
/// Builds athlete-specific nomogram fitting data from already-loaded session
/// aggregates. The builder is pure and does not read or write the database.
library;

import 'package:hrv_slope_app/data/database/app_database.dart'
    hide NomogramModel;
import 'package:hrv_slope_app/data/database/daos/sessions_dao.dart';
import 'package:hrv_slope_app/shared/engine/nomogram_engine.dart';

enum IndividualNomogramRecommendedMode { populationOnly, hybrid, individual }

extension IndividualNomogramRecommendedModeText
    on IndividualNomogramRecommendedMode {
  String get key {
    switch (this) {
      case IndividualNomogramRecommendedMode.populationOnly:
        return 'population_only';
      case IndividualNomogramRecommendedMode.hybrid:
        return 'hybrid';
      case IndividualNomogramRecommendedMode.individual:
        return 'individual';
    }
  }

  String get label {
    switch (this) {
      case IndividualNomogramRecommendedMode.populationOnly:
        return 'Population only';
      case IndividualNomogramRecommendedMode.hybrid:
        return 'Hybrid';
      case IndividualNomogramRecommendedMode.individual:
        return 'Individual';
    }
  }
}

enum ExcludedNomogramReason {
  missingIntensity,
  missingSlope,
  draftSession,
  invalidValue,
}

extension ExcludedNomogramReasonText on ExcludedNomogramReason {
  String get key {
    switch (this) {
      case ExcludedNomogramReason.missingIntensity:
        return 'missing_intensity';
      case ExcludedNomogramReason.missingSlope:
        return 'missing_slope';
      case ExcludedNomogramReason.draftSession:
        return 'draft_session';
      case ExcludedNomogramReason.invalidValue:
        return 'invalid_value';
    }
  }

  String get label {
    switch (this) {
      case ExcludedNomogramReason.missingIntensity:
        return 'Missing intensity';
      case ExcludedNomogramReason.missingSlope:
        return 'Missing interpreted slope';
      case ExcludedNomogramReason.draftSession:
        return 'Draft session';
      case ExcludedNomogramReason.invalidValue:
        return 'Invalid value';
    }
  }
}

class IndividualNomogramCurvePoint {
  final double intensityPercent;
  final double slope;

  const IndividualNomogramCurvePoint({
    required this.intensityPercent,
    required this.slope,
  });
}

class IndividualNomogramPoint {
  final int sessionId;
  final String date;
  final String? taskName;
  final double intensityPercent;
  final double interpretedSlope;
  final String? classification;
  final double? residualPopulation;
  final double? residualIndividual;
  final double? residualHybrid;

  const IndividualNomogramPoint({
    required this.sessionId,
    required this.date,
    this.taskName,
    required this.intensityPercent,
    required this.interpretedSlope,
    this.classification,
    this.residualPopulation,
    this.residualIndividual,
    this.residualHybrid,
  });
}

class ExcludedNomogramSession {
  final int sessionId;
  final String date;
  final String? taskName;
  final ExcludedNomogramReason reason;

  const ExcludedNomogramSession({
    required this.sessionId,
    required this.date,
    this.taskName,
    required this.reason,
  });
}

class IndividualNomogramSummary {
  final int totalSessions;
  final int validPointCount;
  final int excludedCount;
  final int lowZoneCount;
  final int mediumZoneCount;
  final int highZoneCount;
  final String confidenceLabel;
  final IndividualNomogramRecommendedMode recommendedMode;
  final String explanationText;

  const IndividualNomogramSummary({
    required this.totalSessions,
    required this.validPointCount,
    required this.excludedCount,
    required this.lowZoneCount,
    required this.mediumZoneCount,
    required this.highZoneCount,
    required this.confidenceLabel,
    required this.recommendedMode,
    required this.explanationText,
  });
}

class IndividualNomogramData {
  final int athleteId;
  final String athleteName;
  final List<IndividualNomogramPoint> validPoints;
  final List<ExcludedNomogramSession> excludedSessions;
  final IndividualNomogramConfidence confidenceLevel;
  final Set<String> intensityZonesPresent;
  final NomogramModel? fittedModel;
  final PopulationNomogramSource populationPreset;
  final double hybridWeightIndividual;
  final double hybridWeightPopulation;
  final List<IndividualNomogramCurvePoint> populationCurvePoints;
  final List<IndividualNomogramCurvePoint> individualCurvePoints;
  final List<IndividualNomogramCurvePoint> hybridCurvePoints;
  final List<String> warnings;
  final IndividualNomogramSummary summary;

  const IndividualNomogramData({
    required this.athleteId,
    required this.athleteName,
    required this.validPoints,
    required this.excludedSessions,
    required this.confidenceLevel,
    required this.intensityZonesPresent,
    required this.fittedModel,
    required this.populationPreset,
    required this.hybridWeightIndividual,
    required this.hybridWeightPopulation,
    required this.populationCurvePoints,
    required this.individualCurvePoints,
    required this.hybridCurvePoints,
    required this.warnings,
    required this.summary,
  });

  IndividualNomogramRecommendedMode get recommendedMode =>
      summary.recommendedMode;
}

IndividualNomogramData buildIndividualNomogramData({
  required Athlete athlete,
  required List<SessionDetail> details,
  PopulationNomogramSource populationPreset = kDefaultPopulationNomogramSource,
}) {
  final sorted = [...details]
    ..sort((a, b) => a.session.date.compareTo(b.session.date));
  final excluded = <ExcludedNomogramSession>[];
  final fitPoints = <NomogramPoint>[];
  final validSessions = <Session>[];

  for (final detail in sorted) {
    final session = detail.session;
    final reason = _exclusionReason(session);
    if (reason != null) {
      excluded.add(
        ExcludedNomogramSession(
          sessionId: session.id,
          date: session.date,
          taskName: session.taskName,
          reason: reason,
        ),
      );
      continue;
    }

    validSessions.add(session);
    fitPoints.add(
      NomogramPoint(
        intensityPercent: session.intensityPercent!,
        slope: session.slopeInterpreted!,
      ),
    );
  }

  final zoneCounts = _zoneCounts(fitPoints);
  final zonesPresent = <String>{
    if (zoneCounts.low > 0) 'low',
    if (zoneCounts.medium > 0) 'medium',
    if (zoneCounts.high > 0) 'high',
  };
  final confidence = _confidenceFor(fitPoints.length, zonesPresent.length);
  final individualWeight = individualWeightForConfidence(confidence);
  final populationWeight = 1.0 - individualWeight;
  final recommendedMode = _modeFor(confidence);

  NomogramModel? fittedModel;
  final warnings = <String>[];
  if (confidence != IndividualNomogramConfidence.insufficient) {
    try {
      fittedModel = fitIndividualNomogram(fitPoints);
    } catch (error) {
      warnings.add('Individual fit unavailable: $error');
    }
  }

  if (confidence == IndividualNomogramConfidence.insufficient) {
    warnings.add(
      'Population nomogram remains primary until at least 6 valid sessions '
      'and 2 intensity zones are available.',
    );
  }
  for (final zone in ['low', 'medium', 'high']) {
    if (!zonesPresent.contains(zone)) {
      warnings.add('Missing $zone intensity zone for athlete-specific fit.');
    }
  }
  if (excluded.isNotEmpty) {
    warnings.add('${excluded.length} session(s) excluded from fitting.');
  }

  final validPoints = <IndividualNomogramPoint>[];
  for (final session in validSessions) {
    final populationBands = evaluatePopulationNomogramBands(
      session.intensityPercent!,
      source: populationPreset,
    );
    final populationExpected = populationBands.expectedMean;
    final individualExpected = fittedModel == null
        ? null
        : expectedSlopeAtIntensity(
            fittedModel.params,
            session.intensityPercent!,
          );
    final hybridExpected = individualExpected == null
        ? null
        : computeHybridExpectedSlope(
            populationExpected: populationExpected,
            individualExpected: individualExpected,
            confidence: confidence,
          );
    final classification = classifySlopeWithPopulationNomogram(
      session.intensityPercent!,
      session.slopeInterpreted!,
      source: populationPreset,
    );

    validPoints.add(
      IndividualNomogramPoint(
        sessionId: session.id,
        date: session.date,
        taskName: session.taskName,
        intensityPercent: session.intensityPercent!,
        interpretedSlope: session.slopeInterpreted!,
        classification: _classificationKey(classification.classification),
        residualPopulation: computeResidual(
          session.slopeInterpreted!,
          populationExpected,
        ),
        residualIndividual: individualExpected == null
            ? null
            : computeResidual(session.slopeInterpreted!, individualExpected),
        residualHybrid: hybridExpected == null
            ? null
            : computeResidual(session.slopeInterpreted!, hybridExpected),
      ),
    );
  }

  final populationCurve = _sampleCurve(
    populationPreset,
    (intensity) => evaluatePopulationNomogramBands(
      intensity,
      source: populationPreset,
    ).expectedMean,
  );
  final individualCurve = fittedModel == null
      ? <IndividualNomogramCurvePoint>[]
      : _sampleCurve(
          populationPreset,
          (intensity) =>
              expectedSlopeAtIntensity(fittedModel!.params, intensity),
        );
  final hybridCurve =
      fittedModel == null ||
          recommendedMode != IndividualNomogramRecommendedMode.hybrid
      ? <IndividualNomogramCurvePoint>[]
      : _sampleCurve(populationPreset, (intensity) {
          final populationExpected = evaluatePopulationNomogramBands(
            intensity,
            source: populationPreset,
          ).expectedMean;
          final individualExpected = expectedSlopeAtIntensity(
            fittedModel!.params,
            intensity,
          );
          return computeHybridExpectedSlope(
            populationExpected: populationExpected,
            individualExpected: individualExpected,
            confidence: confidence,
          );
        });

  final explanation = _explanationFor(confidence);
  return IndividualNomogramData(
    athleteId: athlete.id,
    athleteName: athlete.name,
    validPoints: List.unmodifiable(validPoints),
    excludedSessions: List.unmodifiable(excluded),
    confidenceLevel: confidence,
    intensityZonesPresent: Set.unmodifiable(zonesPresent),
    fittedModel: fittedModel,
    populationPreset: populationPreset,
    hybridWeightIndividual: individualWeight,
    hybridWeightPopulation: populationWeight,
    populationCurvePoints: List.unmodifiable(populationCurve),
    individualCurvePoints: List.unmodifiable(individualCurve),
    hybridCurvePoints: List.unmodifiable(hybridCurve),
    warnings: List.unmodifiable(warnings),
    summary: IndividualNomogramSummary(
      totalSessions: sorted.length,
      validPointCount: validPoints.length,
      excludedCount: excluded.length,
      lowZoneCount: zoneCounts.low,
      mediumZoneCount: zoneCounts.medium,
      highZoneCount: zoneCounts.high,
      confidenceLabel: confidence.label,
      recommendedMode: recommendedMode,
      explanationText: explanation,
    ),
  );
}

ExcludedNomogramReason? _exclusionReason(Session session) {
  if (session.isDraft) return ExcludedNomogramReason.draftSession;
  if (session.intensityPercent == null) {
    return ExcludedNomogramReason.missingIntensity;
  }
  if (session.slopeInterpreted == null) {
    return ExcludedNomogramReason.missingSlope;
  }
  if (session.intensityPercent!.isNaN ||
      session.slopeInterpreted!.isNaN ||
      session.intensityPercent! <= 0 ||
      session.slopeInterpreted! <= 0) {
    return ExcludedNomogramReason.invalidValue;
  }
  return null;
}

IndividualNomogramConfidence _confidenceFor(int nPoints, int zonesPresent) {
  final hasTwoZones = zonesPresent >= 2;
  final hasThreeZones = zonesPresent == 3;
  if (nPoints < 6 || !hasTwoZones) {
    return IndividualNomogramConfidence.insufficient;
  }
  if (nPoints <= 8 && hasTwoZones) {
    return IndividualNomogramConfidence.initial;
  }
  if (nPoints <= 11 && hasThreeZones) {
    return IndividualNomogramConfidence.acceptable;
  }
  if (nPoints >= 12 && hasThreeZones) {
    return IndividualNomogramConfidence.robust;
  }
  return IndividualNomogramConfidence.insufficient;
}

IndividualNomogramRecommendedMode _modeFor(
  IndividualNomogramConfidence confidence,
) {
  switch (confidence) {
    case IndividualNomogramConfidence.insufficient:
      return IndividualNomogramRecommendedMode.populationOnly;
    case IndividualNomogramConfidence.initial:
    case IndividualNomogramConfidence.acceptable:
      return IndividualNomogramRecommendedMode.hybrid;
    case IndividualNomogramConfidence.robust:
      return IndividualNomogramRecommendedMode.individual;
  }
}

String _explanationFor(IndividualNomogramConfidence confidence) {
  switch (confidence) {
    case IndividualNomogramConfidence.insufficient:
      return 'Use the population nomogram as the primary reference while more '
          'valid sessions and intensity spread accumulate.';
    case IndividualNomogramConfidence.initial:
      return 'Use a hybrid reference with stronger population weighting while '
          'the athlete-specific model is still developing.';
    case IndividualNomogramConfidence.acceptable:
      return 'Use a hybrid reference with stronger athlete-specific weighting '
          'and keep the population model as context.';
    case IndividualNomogramConfidence.robust:
      return 'Use the athlete-specific model as the primary reference, with '
          'the population model available for context.';
  }
}

({int low, int medium, int high}) _zoneCounts(List<NomogramPoint> points) {
  var low = 0;
  var medium = 0;
  var high = 0;
  for (final point in points) {
    if (point.intensityPercent < 70) {
      low++;
    } else if (point.intensityPercent <= 90) {
      medium++;
    } else {
      high++;
    }
  }
  return (low: low, medium: medium, high: high);
}

List<IndividualNomogramCurvePoint> _sampleCurve(
  PopulationNomogramSource preset,
  double Function(double intensityPercent) evaluator,
) {
  final range = _rangeFor(preset);
  const steps = 40;
  final dx = (range.end - range.start) / steps;
  return [
    for (var i = 0; i <= steps; i++)
      IndividualNomogramCurvePoint(
        intensityPercent: range.start + i * dx,
        slope: evaluator(range.start + i * dx),
      ),
  ];
}

({double start, double end}) _rangeFor(PopulationNomogramSource preset) {
  switch (preset) {
    case PopulationNomogramSource.excelOperational:
      return (start: 55.0, end: 105.0);
    case PopulationNomogramSource.paperOriginal2019:
      return (start: 60.0, end: 105.0);
  }
}

String _classificationKey(InternalLoadClassification classification) {
  switch (classification) {
    case InternalLoadClassification.veryHighInternalLoad:
      return 'very_high_internal_load';
    case InternalLoadClassification.highOrModerateInternalLoad:
      return 'high_or_moderate_internal_load';
    case InternalLoadClassification.expectedResponse:
      return 'expected_response';
    case InternalLoadClassification.lowInternalLoadOrFastRecovery:
      return 'low_internal_load_or_fast_recovery';
  }
}
