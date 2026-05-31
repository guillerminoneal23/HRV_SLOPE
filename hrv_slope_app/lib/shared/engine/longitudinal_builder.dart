/// Athlete longitudinal dashboard data builder.
///
/// This pure builder turns loaded session details into chronologically sorted
/// trend data, rolling averages, summary values, and training-load flags.
library;

import 'package:hrv_slope_app/data/database/app_database.dart';
import 'package:hrv_slope_app/data/database/daos/sessions_dao.dart';
import 'package:hrv_slope_app/shared/engine/intensity_resolver.dart';
import 'package:hrv_slope_app/shared/engine/nomogram_engine.dart';
import 'package:hrv_slope_app/shared/engine/statistics.dart';

const int kLongitudinalShortWindow = 7;
const int kLongitudinalMediumWindow = 14;
const int kLongitudinalLongWindow = 28;
const double kNegativeResidualFlagThreshold = -0.5;
const int kNegativeResidualConsecutiveSessions = 3;
const double kSlopeShortVsLongDropPercentThreshold = 30.0;
const double kItlShortVsLongIncreasePercentThreshold = 50.0;

enum LongitudinalTrendDirection {
  improving,
  worsening,
  stable,
  insufficientData,
}

class LongitudinalPoint {
  final int sessionId;
  final String date;
  final String? taskName;
  final String? sessionType;
  final double? intensityPercent;
  final String intensitySourceForSlope;
  final String? primaryIntensityMetric;
  final double? interpretedSlope;
  final double? rawSlope;
  final double? itlIndex;
  final double? residual;
  final double? residualPercent;
  final String? classification;
  final double? rpe;
  final double? srpe;
  final double? trimp;
  final String? primaryExternalLoadName;
  final double? primaryExternalLoadValue;
  final List<String> warnings;

  const LongitudinalPoint({
    required this.sessionId,
    required this.date,
    this.taskName,
    this.sessionType,
    this.intensityPercent,
    this.intensitySourceForSlope = 'Unknown',
    this.primaryIntensityMetric,
    this.interpretedSlope,
    this.rawSlope,
    this.itlIndex,
    this.residual,
    this.residualPercent,
    this.classification,
    this.rpe,
    this.srpe,
    this.trimp,
    this.primaryExternalLoadName,
    this.primaryExternalLoadValue,
    this.warnings = const [],
  });

  bool get isComplete => interpretedSlope != null && itlIndex != null;
}

class LongitudinalSeries {
  final int athleteId;
  final String athleteName;
  final List<LongitudinalPoint> points;
  final List<double?> slopeRolling7;
  final List<double?> slopeRolling14;
  final List<double?> slopeRolling28;
  final List<double?> itlRolling7;
  final List<double?> itlRolling14;
  final List<double?> itlRolling28;
  final List<LongitudinalFatigueFlag> fatigueFlags;
  final LongitudinalSummary summary;

  const LongitudinalSeries({
    required this.athleteId,
    required this.athleteName,
    required this.points,
    required this.slopeRolling7,
    required this.slopeRolling14,
    required this.slopeRolling28,
    required this.itlRolling7,
    required this.itlRolling14,
    required this.itlRolling28,
    required this.fatigueFlags,
    required this.summary,
  });
}

class LongitudinalSummary {
  final int nSessions;
  final int nComplete;
  final double? latestSlope;
  final double? latestItl;
  final String? latestClassification;
  final double? meanSlope;
  final double? minSlope;
  final double? maxSlope;
  final double? meanItl;
  final LongitudinalTrendDirection trendDirection;

  const LongitudinalSummary({
    required this.nSessions,
    required this.nComplete,
    this.latestSlope,
    this.latestItl,
    this.latestClassification,
    this.meanSlope,
    this.minSlope,
    this.maxSlope,
    this.meanItl,
    required this.trendDirection,
  });
}

class LongitudinalFatigueFlag {
  final String ruleName;
  final String message;
  final String startDate;
  final String endDate;

  const LongitudinalFatigueFlag({
    required this.ruleName,
    required this.message,
    required this.startDate,
    required this.endDate,
  });
}

LongitudinalSeries buildLongitudinalSeries({
  required Athlete athlete,
  required List<SessionDetail> details,
  PopulationNomogramSource nomogramPreset =
      PopulationNomogramSource.excelOperational,
}) {
  final sorted = List<SessionDetail>.from(details)
    ..sort((a, b) => a.session.date.compareTo(b.session.date));

  final points = sorted
      .map((detail) => _pointFromDetail(detail, nomogramPreset))
      .toList();
  final slopes = points.map((point) => point.interpretedSlope).toList();
  final itls = points.map((point) => point.itlIndex).toList();

  final slopeRolling7 = rollingAverage(slopes, kLongitudinalShortWindow);
  final slopeRolling14 = rollingAverage(slopes, kLongitudinalMediumWindow);
  final slopeRolling28 = rollingAverage(slopes, kLongitudinalLongWindow);
  final itlRolling7 = rollingAverage(itls, kLongitudinalShortWindow);
  final itlRolling14 = rollingAverage(itls, kLongitudinalMediumWindow);
  final itlRolling28 = rollingAverage(itls, kLongitudinalLongWindow);

  return LongitudinalSeries(
    athleteId: athlete.id,
    athleteName: athlete.name,
    points: List.unmodifiable(points),
    slopeRolling7: slopeRolling7,
    slopeRolling14: slopeRolling14,
    slopeRolling28: slopeRolling28,
    itlRolling7: itlRolling7,
    itlRolling14: itlRolling14,
    itlRolling28: itlRolling28,
    fatigueFlags: _fatigueFlags(
      points: points,
      slopeRolling7: slopeRolling7,
      slopeRolling28: slopeRolling28,
      itlRolling7: itlRolling7,
      itlRolling28: itlRolling28,
    ),
    summary: _summary(points),
  );
}

LongitudinalPoint _pointFromDetail(
  SessionDetail detail,
  PopulationNomogramSource preset,
) {
  final session = detail.session;
  final warnings = <String>[];

  if (session.intensityPercent == null) {
    warnings.add('Intensity percent missing; residual unavailable.');
  }
  if (session.slopeInterpreted == null) {
    warnings.add('Interpreted slope missing; trend point incomplete.');
  }
  if (session.itlIndex == null) {
    warnings.add('ITL missing; ITL trend point incomplete.');
  }

  NomogramClassificationResult? classification;
  if (!session.isDraft &&
      session.intensityPercent != null &&
      session.slopeInterpreted != null) {
    classification = classifySlopeWithPopulationNomogram(
      session.intensityPercent!,
      session.slopeInterpreted!,
      source: preset,
    );
    warnings.addAll(classification.warnings);
  }

  final internal = detail.variablesByCategory('internal');
  final external = detail.variablesByCategory('external');
  final primaryExternal =
      external.where((v) => v.isPrimaryForNomogram).firstOrNull ??
      (external.isEmpty ? null : external.first);

  return LongitudinalPoint(
    sessionId: session.id,
    date: session.date,
    taskName: session.taskName,
    sessionType: session.sessionType,
    intensityPercent: session.intensityPercent,
    intensitySourceForSlope: intensitySourceForSlopeLabel(
      session.intensitySource,
    ),
    primaryIntensityMetric: primaryIntensityMetricFromMethod(
      session.intensitySource,
    ),
    interpretedSlope: session.slopeInterpreted,
    rawSlope: session.slopeRaw,
    itlIndex: session.itlIndex,
    residual: classification?.residual,
    residualPercent: classification?.residualPercent,
    classification: classification == null
        ? session.classification
        : _classificationKey(classification.classification),
    rpe:
        _variableValue(internal, 'rpe_1_10') ??
        _variableValue(internal, 'rpe_borg'),
    srpe: _variableValue(internal, 'srpe'),
    trimp: _variableValue(internal, 'trimp'),
    primaryExternalLoadName: primaryExternal?.name,
    primaryExternalLoadValue: primaryExternal?.value,
    warnings: List.unmodifiable(warnings),
  );
}

LongitudinalSummary _summary(List<LongitudinalPoint> points) {
  final complete = points.where((point) => point.isComplete).toList();
  final slopes = complete.map((point) => point.interpretedSlope!).toList();
  final itls = complete.map((point) => point.itlIndex!).toList();
  final latest = complete.isEmpty ? null : complete.last;

  return LongitudinalSummary(
    nSessions: points.length,
    nComplete: complete.length,
    latestSlope: latest?.interpretedSlope,
    latestItl: latest?.itlIndex,
    latestClassification: latest?.classification,
    meanSlope: slopes.isEmpty ? null : _mean(slopes),
    minSlope: slopes.isEmpty ? null : slopes.reduce((a, b) => a < b ? a : b),
    maxSlope: slopes.isEmpty ? null : slopes.reduce((a, b) => a > b ? a : b),
    meanItl: itls.isEmpty ? null : _mean(itls),
    trendDirection: _trendDirection(slopes),
  );
}

LongitudinalTrendDirection _trendDirection(List<double> slopes) {
  if (slopes.length < 3) return LongitudinalTrendDirection.insufficientData;
  final firstWindow = slopes.take(3).toList();
  final lastWindow = slopes.skip(slopes.length - 3).toList();
  final first = _mean(firstWindow);
  final last = _mean(lastWindow);
  if (first == 0) return LongitudinalTrendDirection.stable;
  final changePercent = (last - first) / first * 100;
  if (changePercent > 5) return LongitudinalTrendDirection.improving;
  if (changePercent < -5) return LongitudinalTrendDirection.worsening;
  return LongitudinalTrendDirection.stable;
}

List<LongitudinalFatigueFlag> _fatigueFlags({
  required List<LongitudinalPoint> points,
  required List<double?> slopeRolling7,
  required List<double?> slopeRolling28,
  required List<double?> itlRolling7,
  required List<double?> itlRolling28,
}) {
  final flags = <LongitudinalFatigueFlag>[];

  var consecutiveNegative = 0;
  var startIndex = 0;
  for (var i = 0; i < points.length; i++) {
    final residual = points[i].residual;
    if (residual != null && residual < kNegativeResidualFlagThreshold) {
      if (consecutiveNegative == 0) startIndex = i;
      consecutiveNegative++;
      if (consecutiveNegative == kNegativeResidualConsecutiveSessions) {
        flags.add(
          LongitudinalFatigueFlag(
            ruleName: 'three_negative_residuals',
            message:
                'Review training context: 3 consecutive sessions were below expected recovery.',
            startDate: points[startIndex].date,
            endDate: points[i].date,
          ),
        );
      }
    } else {
      consecutiveNegative = 0;
    }
  }

  if (points.length >= kLongitudinalLongWindow) {
    final last = points.length - 1;
    final shortSlope = slopeRolling7[last];
    final longSlope = slopeRolling28[last];
    if (shortSlope != null && longSlope != null && longSlope > 0) {
      final dropPercent = (longSlope - shortSlope) / longSlope * 100;
      if (dropPercent > kSlopeShortVsLongDropPercentThreshold) {
        flags.add(
          LongitudinalFatigueFlag(
            ruleName: 'slope_7_vs_28_drop',
            message:
                'Monitor accumulated load: short-term slope average is ${dropPercent.toStringAsFixed(1)}% below the 28-session average.',
            startDate: points[last].date,
            endDate: points[last].date,
          ),
        );
      }
    }

    final shortItl = itlRolling7[last];
    final longItl = itlRolling28[last];
    if (shortItl != null && longItl != null && longItl > 0) {
      final increasePercent = (shortItl - longItl) / longItl * 100;
      if (increasePercent > kItlShortVsLongIncreasePercentThreshold) {
        flags.add(
          LongitudinalFatigueFlag(
            ruleName: 'itl_7_vs_28_increase',
            message:
                'Review training context: short-term ITL average is ${increasePercent.toStringAsFixed(1)}% above the 28-session average.',
            startDate: points[last].date,
            endDate: points[last].date,
          ),
        );
      }
    }
  }

  return flags;
}

double? _variableValue(List<IntensityVariable> variables, String name) {
  for (final variable in variables) {
    if (variable.name == name) return variable.value;
  }
  return null;
}

double _mean(List<double> values) =>
    values.reduce((a, b) => a + b) / values.length;

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
