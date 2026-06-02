/// Athlete longitudinal dashboard data builder.
///
/// This pure builder turns loaded session details into chronologically sorted
/// trend data, rolling averages, summary values, comparable-session filtering,
/// and training-load flags.
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
const double kRpeSlopeQuadrantHighRpeThreshold = 7.0;

enum LongitudinalTrendDirection {
  improving,
  worsening,
  stable,
  insufficientData,
}

enum LongitudinalXAxisMode { sessionOrder, date }

enum LongitudinalRecoveryZone { low, normal, favorable, unavailable }

enum RpeSlopeQuadrant {
  lowRpeLowSlopeResponse,
  lowRpeFavorableSlopeResponse,
  highRpeLowSlopeResponse,
  highRpeFavorableSlopeResponse,
  unavailable,
}

extension RpeSlopeQuadrantText on RpeSlopeQuadrant {
  String get key {
    switch (this) {
      case RpeSlopeQuadrant.lowRpeLowSlopeResponse:
        return 'low_rpe_low_slope_response';
      case RpeSlopeQuadrant.lowRpeFavorableSlopeResponse:
        return 'low_rpe_favorable_slope_response';
      case RpeSlopeQuadrant.highRpeLowSlopeResponse:
        return 'high_rpe_low_slope_response';
      case RpeSlopeQuadrant.highRpeFavorableSlopeResponse:
        return 'high_rpe_favorable_slope_response';
      case RpeSlopeQuadrant.unavailable:
        return 'unavailable';
    }
  }

  String get label {
    switch (this) {
      case RpeSlopeQuadrant.lowRpeLowSlopeResponse:
        return 'Low RPE + low slope response';
      case RpeSlopeQuadrant.lowRpeFavorableSlopeResponse:
        return 'Low RPE + adequate/favorable slope response';
      case RpeSlopeQuadrant.highRpeLowSlopeResponse:
        return 'High RPE + low slope response';
      case RpeSlopeQuadrant.highRpeFavorableSlopeResponse:
        return 'High RPE + adequate/favorable slope response';
      case RpeSlopeQuadrant.unavailable:
        return 'Unavailable';
    }
  }

  String get interpretation {
    switch (this) {
      case RpeSlopeQuadrant.lowRpeLowSlopeResponse:
        return 'Lower perceived effort but lower-than-expected recovery response. Review context.';
      case RpeSlopeQuadrant.lowRpeFavorableSlopeResponse:
        return 'Low perceived effort with adequate or favorable slope response.';
      case RpeSlopeQuadrant.highRpeLowSlopeResponse:
        return 'Demanding perceived effort with lower-than-expected recovery response.';
      case RpeSlopeQuadrant.highRpeFavorableSlopeResponse:
        return 'Demanding perceived effort with adequate or favorable recovery response.';
      case RpeSlopeQuadrant.unavailable:
        return 'Not enough data to classify.';
    }
  }
}

extension LongitudinalRecoveryZoneText on LongitudinalRecoveryZone {
  String get key {
    switch (this) {
      case LongitudinalRecoveryZone.low:
        return 'low';
      case LongitudinalRecoveryZone.normal:
        return 'normal';
      case LongitudinalRecoveryZone.favorable:
        return 'favorable';
      case LongitudinalRecoveryZone.unavailable:
        return 'unavailable';
    }
  }

  String get label {
    switch (this) {
      case LongitudinalRecoveryZone.low:
        return 'Low';
      case LongitudinalRecoveryZone.normal:
        return 'Normal';
      case LongitudinalRecoveryZone.favorable:
        return 'Favorable';
      case LongitudinalRecoveryZone.unavailable:
        return 'Unavailable';
    }
  }
}

class LongitudinalNomogramReferencePoint {
  final int sessionId;
  final String date;
  final double? primaryIntensityValue;
  final String? primaryIntensityMetric;
  final String intensitySourceForSlope;
  final double? observedSlope;
  final double? observedItl;
  final double? referenceSlope;
  final double? lowerSlopeThreshold;
  final double? upperSlopeThreshold;
  final double? referenceItl;
  final double? lowerItlThreshold;
  final double? upperItlThreshold;
  final LongitudinalRecoveryZone zone;
  final String source;
  final String? unavailableReason;

  const LongitudinalNomogramReferencePoint({
    required this.sessionId,
    required this.date,
    this.primaryIntensityValue,
    this.primaryIntensityMetric,
    this.intensitySourceForSlope = 'Unknown',
    this.observedSlope,
    this.observedItl,
    this.referenceSlope,
    this.lowerSlopeThreshold,
    this.upperSlopeThreshold,
    this.referenceItl,
    this.lowerItlThreshold,
    this.upperItlThreshold,
    required this.zone,
    this.source = kSlopeOrellana19PresetName,
    this.unavailableReason,
  });

  bool get isAvailable => zone != LongitudinalRecoveryZone.unavailable;
}

class LongitudinalNomogramReferenceSeries {
  final String source;
  final List<LongitudinalNomogramReferencePoint> points;

  const LongitudinalNomogramReferenceSeries({
    this.source = kSlopeOrellana19PresetName,
    this.points = const [],
  });

  int get availableCount => points.where((point) => point.isAvailable).length;
}

class RpeSlopeQuadrantPoint {
  final int sessionId;
  final String date;
  final String? sessionTaskName;
  final String? sessionType;
  final String? sport;
  final String? protocolName;
  final String? contextEnvironment;
  final double? rpe;
  final double? observedSlope;
  final double? observedItl;
  final double? primaryIntensityValue;
  final String? primaryIntensityMetric;
  final String intensitySourceForSlope;
  final double? referenceSlope;
  final double? slopeResponseIndex;
  final LongitudinalRecoveryZone recoveryZone;
  final RpeSlopeQuadrant quadrant;
  final String? unavailableReason;
  final String? notesSummary;

  const RpeSlopeQuadrantPoint({
    required this.sessionId,
    required this.date,
    this.sessionTaskName,
    this.sessionType,
    this.sport,
    this.protocolName,
    this.contextEnvironment,
    this.rpe,
    this.observedSlope,
    this.observedItl,
    this.primaryIntensityValue,
    this.primaryIntensityMetric,
    this.intensitySourceForSlope = 'Unknown',
    this.referenceSlope,
    this.slopeResponseIndex,
    required this.recoveryZone,
    required this.quadrant,
    this.unavailableReason,
    this.notesSummary,
  });

  bool get isPlottable =>
      rpe != null && observedSlope != null && slopeResponseIndex != null;
}

class RpeSlopeQuadrantSummary {
  final int pointsShown;
  final int missingRpe;
  final int missingReference;
  final int lowRpeFavorableSlopeResponse;
  final int highRpeFavorableSlopeResponse;
  final int highRpeLowSlopeResponse;
  final int lowRpeLowSlopeResponse;

  const RpeSlopeQuadrantSummary({
    required this.pointsShown,
    required this.missingRpe,
    required this.missingReference,
    required this.lowRpeFavorableSlopeResponse,
    required this.highRpeFavorableSlopeResponse,
    required this.highRpeLowSlopeResponse,
    required this.lowRpeLowSlopeResponse,
  });

  int get omittedSessions => missingRpe + missingReference;
}

class RpeSlopeQuadrantData {
  final double highRpeThreshold;
  final List<RpeSlopeQuadrantPoint> points;
  final RpeSlopeQuadrantSummary summary;

  const RpeSlopeQuadrantData({
    this.highRpeThreshold = kRpeSlopeQuadrantHighRpeThreshold,
    this.points = const [],
    this.summary = const RpeSlopeQuadrantSummary(
      pointsShown: 0,
      missingRpe: 0,
      missingReference: 0,
      lowRpeFavorableSlopeResponse: 0,
      highRpeFavorableSlopeResponse: 0,
      highRpeLowSlopeResponse: 0,
      lowRpeLowSlopeResponse: 0,
    ),
  });

  Iterable<RpeSlopeQuadrantPoint> get plottablePoints =>
      points.where((point) => point.isPlottable);
}

class LongitudinalRange {
  final double? min;
  final double? max;

  const LongitudinalRange({this.min, this.max});

  bool get isEmpty => min == null && max == null;

  bool contains(double? value) {
    if (isEmpty) return true;
    if (value == null) return false;
    if (min != null && value < min!) return false;
    if (max != null && value > max!) return false;
    return true;
  }
}

class LongitudinalDashboardFilter {
  final String? dateFrom;
  final String? dateTo;
  final Set<String> sports;
  final Set<String> sessionTypes;
  final Set<String> sessionTasks;
  final Set<String> protocolNames;
  final Set<String> contextEnvironmentTags;
  final Set<String> intensitySourcesForSlope;
  final Set<String> intensityMetricNames;
  final double? intensityValueMin;
  final double? intensityValueMax;
  final double? rpeMin;
  final double? rpeMax;
  final double? fatigueMin;
  final double? fatigueMax;
  final double? slopeMin;
  final double? slopeMax;
  final double? itlMin;
  final double? itlMax;
  final Set<String> hrvInputModes;
  final Set<String> recoveryWindows;
  final String? notesTextSearch;
  final bool onlyCompleteSessions;
  final bool comparableSessionsOnly;

  const LongitudinalDashboardFilter({
    this.dateFrom,
    this.dateTo,
    this.sports = const {},
    this.sessionTypes = const {},
    this.sessionTasks = const {},
    this.protocolNames = const {},
    this.contextEnvironmentTags = const {},
    this.intensitySourcesForSlope = const {},
    this.intensityMetricNames = const {},
    this.intensityValueMin,
    this.intensityValueMax,
    this.rpeMin,
    this.rpeMax,
    this.fatigueMin,
    this.fatigueMax,
    this.slopeMin,
    this.slopeMax,
    this.itlMin,
    this.itlMax,
    this.hrvInputModes = const {},
    this.recoveryWindows = const {},
    this.notesTextSearch,
    this.onlyCompleteSessions = false,
    this.comparableSessionsOnly = false,
  });

  bool get isEmpty => activeFilterCount == 0;

  int get activeFilterCount {
    var count = 0;
    if (dateFrom != null) count++;
    if (dateTo != null) count++;
    if (sports.isNotEmpty) count++;
    if (sessionTypes.isNotEmpty) count++;
    if (sessionTasks.isNotEmpty) count++;
    if (protocolNames.isNotEmpty) count++;
    if (contextEnvironmentTags.isNotEmpty) count++;
    if (intensitySourcesForSlope.isNotEmpty) count++;
    if (intensityMetricNames.isNotEmpty) count++;
    if (intensityValueMin != null || intensityValueMax != null) count++;
    if (rpeMin != null || rpeMax != null) count++;
    if (fatigueMin != null || fatigueMax != null) count++;
    if (slopeMin != null || slopeMax != null) count++;
    if (itlMin != null || itlMax != null) count++;
    if (hrvInputModes.isNotEmpty) count++;
    if (recoveryWindows.isNotEmpty) count++;
    if ((notesTextSearch ?? '').trim().isNotEmpty) count++;
    if (onlyCompleteSessions) count++;
    if (comparableSessionsOnly) count++;
    return count;
  }

  LongitudinalDashboardFilter clear() => const LongitudinalDashboardFilter();

  LongitudinalDashboardFilter copyWith({
    String? dateFrom,
    bool clearDateFrom = false,
    String? dateTo,
    bool clearDateTo = false,
    Set<String>? sports,
    Set<String>? sessionTypes,
    Set<String>? sessionTasks,
    Set<String>? protocolNames,
    Set<String>? contextEnvironmentTags,
    Set<String>? intensitySourcesForSlope,
    Set<String>? intensityMetricNames,
    double? intensityValueMin,
    bool clearIntensityValueMin = false,
    double? intensityValueMax,
    bool clearIntensityValueMax = false,
    double? rpeMin,
    bool clearRpeMin = false,
    double? rpeMax,
    bool clearRpeMax = false,
    double? fatigueMin,
    bool clearFatigueMin = false,
    double? fatigueMax,
    bool clearFatigueMax = false,
    double? slopeMin,
    bool clearSlopeMin = false,
    double? slopeMax,
    bool clearSlopeMax = false,
    double? itlMin,
    bool clearItlMin = false,
    double? itlMax,
    bool clearItlMax = false,
    Set<String>? hrvInputModes,
    Set<String>? recoveryWindows,
    String? notesTextSearch,
    bool clearNotesTextSearch = false,
    bool? onlyCompleteSessions,
    bool? comparableSessionsOnly,
  }) {
    return LongitudinalDashboardFilter(
      dateFrom: clearDateFrom ? null : dateFrom ?? this.dateFrom,
      dateTo: clearDateTo ? null : dateTo ?? this.dateTo,
      sports: sports ?? this.sports,
      sessionTypes: sessionTypes ?? this.sessionTypes,
      sessionTasks: sessionTasks ?? this.sessionTasks,
      protocolNames: protocolNames ?? this.protocolNames,
      contextEnvironmentTags:
          contextEnvironmentTags ?? this.contextEnvironmentTags,
      intensitySourcesForSlope:
          intensitySourcesForSlope ?? this.intensitySourcesForSlope,
      intensityMetricNames: intensityMetricNames ?? this.intensityMetricNames,
      intensityValueMin: clearIntensityValueMin
          ? null
          : intensityValueMin ?? this.intensityValueMin,
      intensityValueMax: clearIntensityValueMax
          ? null
          : intensityValueMax ?? this.intensityValueMax,
      rpeMin: clearRpeMin ? null : rpeMin ?? this.rpeMin,
      rpeMax: clearRpeMax ? null : rpeMax ?? this.rpeMax,
      fatigueMin: clearFatigueMin ? null : fatigueMin ?? this.fatigueMin,
      fatigueMax: clearFatigueMax ? null : fatigueMax ?? this.fatigueMax,
      slopeMin: clearSlopeMin ? null : slopeMin ?? this.slopeMin,
      slopeMax: clearSlopeMax ? null : slopeMax ?? this.slopeMax,
      itlMin: clearItlMin ? null : itlMin ?? this.itlMin,
      itlMax: clearItlMax ? null : itlMax ?? this.itlMax,
      hrvInputModes: hrvInputModes ?? this.hrvInputModes,
      recoveryWindows: recoveryWindows ?? this.recoveryWindows,
      notesTextSearch: clearNotesTextSearch
          ? null
          : notesTextSearch ?? this.notesTextSearch,
      onlyCompleteSessions: onlyCompleteSessions ?? this.onlyCompleteSessions,
      comparableSessionsOnly:
          comparableSessionsOnly ?? this.comparableSessionsOnly,
    );
  }

  bool matchesSession(LongitudinalPoint point) {
    if (!_matchesDateRange(point.date)) return false;
    if (!_matchesSet(sports, point.sport)) return false;
    if (!_matchesSet(sessionTypes, point.sessionType)) return false;
    if (!_matchesSet(sessionTasks, point.taskName)) return false;
    if (!_matchesSet(protocolNames, point.protocolName)) return false;
    if (!_matchesContextTags(
      contextEnvironmentTags,
      point.contextEnvironment,
    )) {
      return false;
    }
    if (!_matchesSet(intensitySourcesForSlope, point.intensitySourceForSlope)) {
      return false;
    }
    if (!_matchesSet(intensityMetricNames, point.primaryIntensityMetric)) {
      return false;
    }
    if (!LongitudinalRange(
      min: intensityValueMin,
      max: intensityValueMax,
    ).contains(point.primaryIntensityValue)) {
      return false;
    }
    if (!LongitudinalRange(min: rpeMin, max: rpeMax).contains(point.rpe)) {
      return false;
    }
    if (!LongitudinalRange(
      min: fatigueMin,
      max: fatigueMax,
    ).contains(point.fatigue)) {
      return false;
    }
    if (!LongitudinalRange(
      min: slopeMin,
      max: slopeMax,
    ).contains(point.interpretedSlope)) {
      return false;
    }
    if (!LongitudinalRange(min: itlMin, max: itlMax).contains(point.itlIndex)) {
      return false;
    }
    if (!_matchesSet(hrvInputModes, point.hrvInputMode)) return false;
    if (!_matchesSet(recoveryWindows, point.recoveryWindowLabel)) return false;
    final notesQuery = (notesTextSearch ?? '').trim().toLowerCase();
    if (notesQuery.isNotEmpty &&
        !((point.notes ?? '').toLowerCase().contains(notesQuery))) {
      return false;
    }
    if (onlyCompleteSessions && !point.isComplete) return false;
    return true;
  }

  List<String> activeFilterLabels() {
    final labels = <String>[];
    if (dateFrom != null) labels.add('From $dateFrom');
    if (dateTo != null) labels.add('To $dateTo');
    _addSetLabel(labels, 'Sport', sports);
    _addSetLabel(labels, 'Type', sessionTypes);
    _addSetLabel(labels, 'Task', sessionTasks);
    _addSetLabel(labels, 'Protocol', protocolNames);
    _addSetLabel(labels, 'Context', contextEnvironmentTags);
    _addSetLabel(labels, 'Intensity source', intensitySourcesForSlope);
    _addSetLabel(labels, 'Intensity metric', intensityMetricNames);
    _addRangeLabel(labels, 'Intensity', intensityValueMin, intensityValueMax);
    _addRangeLabel(labels, 'RPE', rpeMin, rpeMax);
    _addRangeLabel(labels, 'Fatigue', fatigueMin, fatigueMax);
    _addRangeLabel(labels, 'Slope', slopeMin, slopeMax);
    _addRangeLabel(labels, 'ITL', itlMin, itlMax);
    _addSetLabel(labels, 'HRV mode', hrvInputModes);
    _addSetLabel(labels, 'Recovery window', recoveryWindows);
    final query = (notesTextSearch ?? '').trim();
    if (query.isNotEmpty) labels.add('Notes contains "$query"');
    if (onlyCompleteSessions) labels.add('Complete sessions only');
    if (comparableSessionsOnly) labels.add('Comparable sessions only');
    return labels;
  }

  bool _matchesSet(Set<String> selected, String? value) {
    if (selected.isEmpty) return true;
    return value != null && selected.contains(value);
  }

  bool _matchesDateRange(String sessionDate) {
    final sessionDay = _calendarDayKey(sessionDate);
    final fromDay = _calendarDayKey(dateFrom);
    final toDay = _calendarDayKey(dateTo);

    if (sessionDay == null) return true;
    if (fromDay != null && sessionDay.compareTo(fromDay) < 0) return false;
    if (toDay != null && sessionDay.compareTo(toDay) > 0) return false;
    return true;
  }

  bool _matchesContextTags(Set<String> selected, String? value) {
    if (selected.isEmpty) return true;
    final candidates = _contextEnvironmentOptions(
      value,
    ).map((text) => text.toLowerCase()).toSet();
    return selected.any((text) => candidates.contains(text.toLowerCase()));
  }

  void _addSetLabel(List<String> labels, String label, Set<String> values) {
    if (values.isEmpty) return;
    labels.add('$label: ${values.join(', ')}');
  }

  void _addRangeLabel(
    List<String> labels,
    String label,
    double? min,
    double? max,
  ) {
    if (min == null && max == null) return;
    final from = min?.toStringAsFixed(1) ?? '-';
    final to = max?.toStringAsFixed(1) ?? '-';
    labels.add('$label: $from to $to');
  }
}

class LongitudinalFilterOptions {
  final Set<String> sports;
  final Set<String> sessionTypes;
  final Set<String> sessionTasks;
  final Set<String> protocolNames;
  final Set<String> contextEnvironmentTags;
  final Set<String> intensitySourcesForSlope;
  final Set<String> intensityMetricNames;
  final Set<String> hrvInputModes;
  final Set<String> recoveryWindows;
  final String? dateMin;
  final String? dateMax;
  final LongitudinalRange intensityRange;
  final LongitudinalRange rpeRange;
  final LongitudinalRange fatigueRange;
  final LongitudinalRange slopeRange;
  final LongitudinalRange itlRange;

  const LongitudinalFilterOptions({
    this.sports = const {},
    this.sessionTypes = const {},
    this.sessionTasks = const {},
    this.protocolNames = const {},
    this.contextEnvironmentTags = const {},
    this.intensitySourcesForSlope = const {},
    this.intensityMetricNames = const {},
    this.hrvInputModes = const {},
    this.recoveryWindows = const {},
    this.dateMin,
    this.dateMax,
    this.intensityRange = const LongitudinalRange(),
    this.rpeRange = const LongitudinalRange(),
    this.fatigueRange = const LongitudinalRange(),
    this.slopeRange = const LongitudinalRange(),
    this.itlRange = const LongitudinalRange(),
  });
}

class LongitudinalDataCompleteness {
  final int includedSessions;
  final int totalSessions;
  final int withSlope;
  final int withItl;
  final int withExternalIntensity;
  final int withInternalFallback;
  final int withRpe;
  final int withFatigue;
  final int withSlopeOrellana19Reference;
  final int missingReferencePrimaryIntensity;
  final int referenceZoneLow;
  final int referenceZoneNormal;
  final int referenceZoneFavorable;
  final int missingKeyData;

  const LongitudinalDataCompleteness({
    required this.includedSessions,
    required this.totalSessions,
    required this.withSlope,
    required this.withItl,
    required this.withExternalIntensity,
    required this.withInternalFallback,
    required this.withRpe,
    required this.withFatigue,
    required this.withSlopeOrellana19Reference,
    required this.missingReferencePrimaryIntensity,
    required this.referenceZoneLow,
    required this.referenceZoneNormal,
    required this.referenceZoneFavorable,
    required this.missingKeyData,
  });
}

class LongitudinalPoint {
  final int sessionId;
  final String date;
  final String? taskName;
  final String? sport;
  final String? sessionType;
  final String? protocolName;
  final String? contextEnvironment;
  final Set<String> contextEnvironmentTags;
  final double? intensityPercent;
  final double? primaryIntensityValue;
  final String intensitySourceForSlope;
  final String? primaryIntensityMetric;
  final double? interpretedSlope;
  final double? rawSlope;
  final double? itlIndex;
  final double? residual;
  final double? residualPercent;
  final String? classification;
  final double? rpe;
  final double? fatigue;
  final double? srpe;
  final double? trimp;
  final String? primaryExternalLoadName;
  final double? primaryExternalLoadValue;
  final String? hrvInputMode;
  final String? recoveryWindowLabel;
  final String? notes;
  final LongitudinalNomogramReferencePoint nomogramReference;
  final List<String> warnings;

  const LongitudinalPoint({
    required this.sessionId,
    required this.date,
    this.taskName,
    this.sport,
    this.sessionType,
    this.protocolName,
    this.contextEnvironment,
    this.contextEnvironmentTags = const {},
    this.intensityPercent,
    this.primaryIntensityValue,
    this.intensitySourceForSlope = 'Unknown',
    this.primaryIntensityMetric,
    this.interpretedSlope,
    this.rawSlope,
    this.itlIndex,
    this.residual,
    this.residualPercent,
    this.classification,
    this.rpe,
    this.fatigue,
    this.srpe,
    this.trimp,
    this.primaryExternalLoadName,
    this.primaryExternalLoadValue,
    this.hrvInputMode,
    this.recoveryWindowLabel,
    this.notes,
    this.nomogramReference = const LongitudinalNomogramReferencePoint(
      sessionId: 0,
      date: '',
      zone: LongitudinalRecoveryZone.unavailable,
      unavailableReason: 'nomogram unavailable',
    ),
    this.warnings = const [],
  });

  bool get isComplete => interpretedSlope != null && itlIndex != null;
}

class LongitudinalSeries {
  final int athleteId;
  final String athleteName;
  final List<LongitudinalPoint> points;
  final List<LongitudinalPoint> allPoints;
  final List<LongitudinalPoint> excludedPoints;
  final List<double?> slopeRolling7;
  final List<double?> slopeRolling14;
  final List<double?> slopeRolling28;
  final List<double?> itlRolling7;
  final List<double?> itlRolling14;
  final List<double?> itlRolling28;
  final List<LongitudinalFatigueFlag> fatigueFlags;
  final LongitudinalSummary summary;
  final LongitudinalDashboardFilter filter;
  final LongitudinalFilterOptions filterOptions;
  final LongitudinalDataCompleteness completeness;
  final LongitudinalNomogramReferenceSeries nomogramReferenceSeries;
  final RpeSlopeQuadrantData rpeSlopeQuadrantData;
  final List<String> activeFilterLabels;
  final int comparableIncludedCount;
  final int comparableTotalCount;

  const LongitudinalSeries({
    required this.athleteId,
    required this.athleteName,
    required this.points,
    this.allPoints = const [],
    this.excludedPoints = const [],
    required this.slopeRolling7,
    required this.slopeRolling14,
    required this.slopeRolling28,
    required this.itlRolling7,
    required this.itlRolling14,
    required this.itlRolling28,
    required this.fatigueFlags,
    required this.summary,
    this.filter = const LongitudinalDashboardFilter(),
    this.filterOptions = const LongitudinalFilterOptions(),
    this.completeness = const LongitudinalDataCompleteness(
      includedSessions: 0,
      totalSessions: 0,
      withSlope: 0,
      withItl: 0,
      withExternalIntensity: 0,
      withInternalFallback: 0,
      withRpe: 0,
      withFatigue: 0,
      withSlopeOrellana19Reference: 0,
      missingReferencePrimaryIntensity: 0,
      referenceZoneLow: 0,
      referenceZoneNormal: 0,
      referenceZoneFavorable: 0,
      missingKeyData: 0,
    ),
    this.nomogramReferenceSeries = const LongitudinalNomogramReferenceSeries(),
    this.rpeSlopeQuadrantData = const RpeSlopeQuadrantData(),
    this.activeFilterLabels = const [],
    this.comparableIncludedCount = 0,
    this.comparableTotalCount = 0,
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
  LongitudinalDashboardFilter filter = const LongitudinalDashboardFilter(),
}) {
  final sorted = List<SessionDetail>.from(details)
    ..sort((a, b) => a.session.date.compareTo(b.session.date));

  final allPoints = sorted
      .map((detail) => _pointFromDetail(detail, nomogramPreset))
      .toList();
  final options = _filterOptions(allPoints);
  final activeLabels = filter.activeFilterLabels();
  final baseFilter = filter.copyWith(comparableSessionsOnly: false);
  final baseIncluded = allPoints.where(baseFilter.matchesSession).toList();

  var points = baseIncluded;
  var comparableTotal = baseIncluded.length;
  if (filter.comparableSessionsOnly && baseIncluded.isNotEmpty) {
    final reference = baseIncluded.last;
    points = baseIncluded
        .where((point) => _isComparableTo(point, reference))
        .toList();
  }

  final includedIds = points.map((point) => point.sessionId).toSet();
  final excluded = allPoints
      .where((point) => !includedIds.contains(point.sessionId))
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
    allPoints: List.unmodifiable(allPoints),
    excludedPoints: List.unmodifiable(excluded),
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
    filter: filter,
    filterOptions: options,
    completeness: _completeness(points, allPoints.length),
    nomogramReferenceSeries: LongitudinalNomogramReferenceSeries(
      points: List.unmodifiable(points.map((p) => p.nomogramReference)),
    ),
    rpeSlopeQuadrantData: buildRpeSlopeQuadrantData(points),
    activeFilterLabels: List.unmodifiable(activeLabels),
    comparableIncludedCount: filter.comparableSessionsOnly
        ? points.length
        : baseIncluded.length,
    comparableTotalCount: comparableTotal,
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
  final sourceLabel = intensitySourceForSlopeLabel(session.intensitySource);
  final primaryIntensityMetric = primaryIntensityMetricFromMethod(
    session.intensitySource,
  );
  final nomogramReference = buildSlopeOrellana19LongitudinalReference(
    sessionId: session.id,
    date: session.date,
    primaryIntensityValue: session.intensityPercent,
    primaryIntensityMetric: primaryIntensityMetric,
    intensitySourceForSlope: sourceLabel,
    observedSlope: session.slopeInterpreted,
    observedItl: session.itlIndex,
  );

  return LongitudinalPoint(
    sessionId: session.id,
    date: session.date,
    taskName: session.taskName,
    sport: session.sport,
    sessionType: session.sessionType,
    protocolName: session.protocolName,
    contextEnvironment: session.contextEnvironment,
    contextEnvironmentTags: _contextEnvironmentOptions(
      session.contextEnvironment,
    ),
    intensityPercent: session.intensityPercent,
    primaryIntensityValue: session.intensityPercent,
    intensitySourceForSlope: sourceLabel,
    primaryIntensityMetric: primaryIntensityMetric,
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
        _variableValue(internal, 'session_rpe_1_10') ??
        _variableValue(internal, 'rpe_borg'),
    fatigue: _variableValue(internal, 'subjective_fatigue_1_10'),
    srpe: _variableValue(internal, 'srpe'),
    trimp: _variableValue(internal, 'trimp'),
    primaryExternalLoadName: primaryExternal?.name,
    primaryExternalLoadValue: primaryExternal?.value,
    hrvInputMode: session.hrvInputMode,
    recoveryWindowLabel: _recoveryWindowLabel(session),
    notes: _notesText(detail),
    nomogramReference: nomogramReference,
    warnings: List.unmodifiable(warnings),
  );
}

LongitudinalNomogramReferencePoint buildSlopeOrellana19LongitudinalReference({
  required int sessionId,
  required String date,
  required double? primaryIntensityValue,
  required String? primaryIntensityMetric,
  required String intensitySourceForSlope,
  required double? observedSlope,
  required double? observedItl,
}) {
  if (!_isInformativeIntensity(primaryIntensityValue)) {
    return LongitudinalNomogramReferencePoint(
      sessionId: sessionId,
      date: date,
      primaryIntensityValue: primaryIntensityValue,
      primaryIntensityMetric: primaryIntensityMetric,
      intensitySourceForSlope: intensitySourceForSlope,
      observedSlope: observedSlope,
      observedItl: observedItl,
      zone: LongitudinalRecoveryZone.unavailable,
      unavailableReason: 'missing primary intensity',
    );
  }
  if (!_isPositiveFinite(observedSlope)) {
    return LongitudinalNomogramReferencePoint(
      sessionId: sessionId,
      date: date,
      primaryIntensityValue: primaryIntensityValue,
      primaryIntensityMetric: primaryIntensityMetric,
      intensitySourceForSlope: intensitySourceForSlope,
      observedSlope: observedSlope,
      observedItl: observedItl,
      zone: LongitudinalRecoveryZone.unavailable,
      unavailableReason: 'missing slope',
    );
  }

  final classification = classifySlopeWithPopulationNomogram(
    primaryIntensityValue!,
    observedSlope!,
    source: PopulationNomogramSource.slopeOrellana19,
  );
  final lowerSlope = classification.expectedLower;
  final referenceSlope = classification.expectedMean;
  final upperSlope = classification.expectedUpper;

  return LongitudinalNomogramReferencePoint(
    sessionId: sessionId,
    date: date,
    primaryIntensityValue: primaryIntensityValue,
    primaryIntensityMetric: primaryIntensityMetric,
    intensitySourceForSlope: intensitySourceForSlope,
    observedSlope: classification.observedSlope,
    observedItl: observedItl,
    referenceSlope: referenceSlope,
    lowerSlopeThreshold: lowerSlope,
    upperSlopeThreshold: upperSlope,
    referenceItl: _itlFromSlope(referenceSlope),
    lowerItlThreshold: _itlFromSlope(upperSlope),
    upperItlThreshold: _itlFromSlope(lowerSlope),
    zone: _recoveryZoneFromClassification(classification.classification),
    source: classification.presetName ?? kSlopeOrellana19PresetName,
  );
}

RpeSlopeQuadrantData buildRpeSlopeQuadrantData(
  List<LongitudinalPoint> points, {
  double highRpeThreshold = kRpeSlopeQuadrantHighRpeThreshold,
}) {
  final quadrantPoints = <RpeSlopeQuadrantPoint>[];
  var missingRpe = 0;
  var missingReference = 0;
  var lowRpeFavorable = 0;
  var highRpeFavorable = 0;
  var highRpeLow = 0;
  var lowRpeLow = 0;

  for (final point in points) {
    final reference = point.nomogramReference;
    final rpe = _validRpe(point.rpe);
    final observedSlope = point.interpretedSlope;
    final referenceSlope = reference.referenceSlope;
    final responseIndex = _slopeResponseIndex(
      observedSlope: observedSlope,
      referenceSlope: referenceSlope,
    );

    String? unavailableReason;
    if (rpe == null) {
      unavailableReason = 'missing RPE';
      missingRpe++;
    } else if (responseIndex == null) {
      unavailableReason =
          reference.unavailableReason ?? 'missing reference slope';
      missingReference++;
    }

    final quadrant = unavailableReason == null
        ? classifyRpeSlopeQuadrant(
            rpe: rpe!,
            slopeResponseIndex: responseIndex!,
            highRpeThreshold: highRpeThreshold,
          )
        : RpeSlopeQuadrant.unavailable;

    switch (quadrant) {
      case RpeSlopeQuadrant.lowRpeFavorableSlopeResponse:
        lowRpeFavorable++;
        break;
      case RpeSlopeQuadrant.highRpeFavorableSlopeResponse:
        highRpeFavorable++;
        break;
      case RpeSlopeQuadrant.highRpeLowSlopeResponse:
        highRpeLow++;
        break;
      case RpeSlopeQuadrant.lowRpeLowSlopeResponse:
        lowRpeLow++;
        break;
      case RpeSlopeQuadrant.unavailable:
        break;
    }

    quadrantPoints.add(
      RpeSlopeQuadrantPoint(
        sessionId: point.sessionId,
        date: point.date,
        sessionTaskName: point.taskName,
        sessionType: point.sessionType,
        sport: point.sport,
        protocolName: point.protocolName,
        contextEnvironment: point.contextEnvironment,
        rpe: rpe,
        observedSlope: observedSlope,
        observedItl: point.itlIndex,
        primaryIntensityValue: point.primaryIntensityValue,
        primaryIntensityMetric: point.primaryIntensityMetric,
        intensitySourceForSlope: point.intensitySourceForSlope,
        referenceSlope: referenceSlope,
        slopeResponseIndex: responseIndex,
        recoveryZone: reference.zone,
        quadrant: quadrant,
        unavailableReason: unavailableReason,
        notesSummary: _notesSummary(point.notes),
      ),
    );
  }

  return RpeSlopeQuadrantData(
    highRpeThreshold: highRpeThreshold,
    points: List.unmodifiable(quadrantPoints),
    summary: RpeSlopeQuadrantSummary(
      pointsShown: quadrantPoints.where((point) => point.isPlottable).length,
      missingRpe: missingRpe,
      missingReference: missingReference,
      lowRpeFavorableSlopeResponse: lowRpeFavorable,
      highRpeFavorableSlopeResponse: highRpeFavorable,
      highRpeLowSlopeResponse: highRpeLow,
      lowRpeLowSlopeResponse: lowRpeLow,
    ),
  );
}

RpeSlopeQuadrant classifyRpeSlopeQuadrant({
  required double rpe,
  required double slopeResponseIndex,
  double highRpeThreshold = kRpeSlopeQuadrantHighRpeThreshold,
}) {
  final highRpe = rpe >= highRpeThreshold;
  final lowSlopeResponse = slopeResponseIndex < 1.0;
  if (highRpe && lowSlopeResponse) {
    return RpeSlopeQuadrant.highRpeLowSlopeResponse;
  }
  if (highRpe) {
    return RpeSlopeQuadrant.highRpeFavorableSlopeResponse;
  }
  if (lowSlopeResponse) {
    return RpeSlopeQuadrant.lowRpeLowSlopeResponse;
  }
  return RpeSlopeQuadrant.lowRpeFavorableSlopeResponse;
}

LongitudinalFilterOptions _filterOptions(List<LongitudinalPoint> points) {
  return LongitudinalFilterOptions(
    sports: _stringOptions(points.map((p) => p.sport)),
    sessionTypes: _stringOptions(points.map((p) => p.sessionType)),
    sessionTasks: _stringOptions(points.map((p) => p.taskName)),
    protocolNames: _stringOptions(points.map((p) => p.protocolName)),
    contextEnvironmentTags: _stringOptions(
      points.expand((p) => p.contextEnvironmentTags),
    ),
    intensitySourcesForSlope: _stringOptions(
      points.map((p) => p.intensitySourceForSlope),
    ),
    intensityMetricNames: _stringOptions(
      points.map((p) => p.primaryIntensityMetric),
    ),
    hrvInputModes: _stringOptions(points.map((p) => p.hrvInputMode)),
    recoveryWindows: _stringOptions(points.map((p) => p.recoveryWindowLabel)),
    dateMin: _dateBound(points, first: true),
    dateMax: _dateBound(points, first: false),
    intensityRange: _range(points.map((p) => p.primaryIntensityValue)),
    rpeRange: _range(points.map((p) => p.rpe)),
    fatigueRange: _range(points.map((p) => p.fatigue)),
    slopeRange: _range(points.map((p) => p.interpretedSlope)),
    itlRange: _range(points.map((p) => p.itlIndex)),
  );
}

LongitudinalDataCompleteness _completeness(
  List<LongitudinalPoint> points,
  int totalSessions,
) {
  return LongitudinalDataCompleteness(
    includedSessions: points.length,
    totalSessions: totalSessions,
    withSlope: points.where((p) => p.interpretedSlope != null).length,
    withItl: points.where((p) => p.itlIndex != null).length,
    withExternalIntensity: points
        .where((p) => p.intensitySourceForSlope == 'External')
        .length,
    withInternalFallback: points
        .where((p) => p.intensitySourceForSlope == 'Internal')
        .length,
    withRpe: points.where((p) => p.rpe != null).length,
    withFatigue: points.where((p) => p.fatigue != null).length,
    withSlopeOrellana19Reference: points
        .where((p) => p.nomogramReference.isAvailable)
        .length,
    missingReferencePrimaryIntensity: points
        .where(
          (p) =>
              p.nomogramReference.unavailableReason ==
              'missing primary intensity',
        )
        .length,
    referenceZoneLow: points
        .where((p) => p.nomogramReference.zone == LongitudinalRecoveryZone.low)
        .length,
    referenceZoneNormal: points
        .where(
          (p) => p.nomogramReference.zone == LongitudinalRecoveryZone.normal,
        )
        .length,
    referenceZoneFavorable: points
        .where(
          (p) => p.nomogramReference.zone == LongitudinalRecoveryZone.favorable,
        )
        .length,
    missingKeyData: points.where((p) => !p.isComplete).length,
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

bool _isComparableTo(LongitudinalPoint point, LongitudinalPoint reference) {
  if (!_sameWhenBothPresent(point.sport, reference.sport)) return false;
  if (!_sameWhenBothPresent(point.taskName, reference.taskName)) return false;
  if (!_sameWhenBothPresent(point.protocolName, reference.protocolName)) {
    return false;
  }
  if (!_sameWhenBothPresent(
    point.contextEnvironment,
    reference.contextEnvironment,
  )) {
    return false;
  }
  if (!_sameWhenBothPresent(
    point.intensitySourceForSlope,
    reference.intensitySourceForSlope,
  )) {
    return false;
  }
  if (!_withinWhenBothPresent(
    point.primaryIntensityValue,
    reference.primaryIntensityValue,
    10,
  )) {
    return false;
  }
  if (!_withinWhenBothPresent(point.rpe, reference.rpe, 2)) return false;
  return true;
}

bool _sameWhenBothPresent(String? a, String? b) {
  final left = (a ?? '').trim();
  final right = (b ?? '').trim();
  if (left.isEmpty || right.isEmpty) return true;
  return left.toLowerCase() == right.toLowerCase();
}

bool _withinWhenBothPresent(double? a, double? b, double tolerance) {
  if (a == null || b == null) return true;
  return (a - b).abs() <= tolerance;
}

double? _variableValue(List<IntensityVariable> variables, String name) {
  for (final variable in variables) {
    if (variable.name == name) return variable.value;
  }
  return null;
}

String? _recoveryWindowLabel(Session session) {
  final start = session.recoveryWindowStartMin;
  final end = session.recoveryWindowEndMin;
  if (start == null || end == null) return null;
  return '${_formatNumber(start)}-${_formatNumber(end)} min';
}

String? _notesText(SessionDetail detail) {
  final values = <String>[
    if ((detail.session.notes ?? '').trim().isNotEmpty) detail.session.notes!,
    for (final note in detail.notes)
      if (note.reason.trim().isNotEmpty) note.reason,
  ];
  if (values.isEmpty) return null;
  return values.join(' | ');
}

Set<String> _stringOptions(Iterable<String?> values) {
  final set = <String>{};
  for (final value in values) {
    final text = (value ?? '').trim();
    if (text.isNotEmpty) set.add(text);
  }
  final sorted = set.toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return {for (final value in sorted) value};
}

Set<String> _contextEnvironmentOptions(String? value) {
  final text = (value ?? '').trim();
  if (text.isEmpty) return const {};
  final options = <String>{text};
  final parts = text.split(RegExp(r'[,;|#]'));
  for (final part in parts) {
    final tag = part.trim();
    if (tag.isNotEmpty) options.add(tag);
  }
  final sorted = options.toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return {for (final value in sorted) value};
}

String? _calendarDayKey(String? value) {
  final text = (value ?? '').trim();
  if (text.isEmpty) return null;
  final parsed = DateTime.tryParse(text);
  if (parsed != null) return _calendarKey(parsed);
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(text);
  if (match == null) return null;
  return '${match.group(1)}-${match.group(2)}-${match.group(3)}';
}

String _calendarKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

String? _dateBound(List<LongitudinalPoint> points, {required bool first}) {
  final dates =
      points
          .map((point) => _calendarDayKey(point.date))
          .whereType<String>()
          .toList()
        ..sort();
  if (dates.isEmpty) return null;
  return first ? dates.first : dates.last;
}

LongitudinalRange _range(Iterable<double?> values) {
  final valid = values.whereType<double>().toList();
  if (valid.isEmpty) return const LongitudinalRange();
  return LongitudinalRange(
    min: valid.reduce((a, b) => a < b ? a : b),
    max: valid.reduce((a, b) => a > b ? a : b),
  );
}

double _mean(List<double> values) =>
    values.reduce((a, b) => a + b) / values.length;

String _formatNumber(double value) {
  if ((value - value.round()).abs() < 1e-9) return value.round().toString();
  return value.toStringAsFixed(1);
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

LongitudinalRecoveryZone _recoveryZoneFromClassification(
  InternalLoadClassification classification,
) {
  switch (classification) {
    case InternalLoadClassification.veryHighInternalLoad:
    case InternalLoadClassification.highOrModerateInternalLoad:
      return LongitudinalRecoveryZone.low;
    case InternalLoadClassification.expectedResponse:
      return LongitudinalRecoveryZone.normal;
    case InternalLoadClassification.lowInternalLoadOrFastRecovery:
      return LongitudinalRecoveryZone.favorable;
  }
}

bool _isInformativeIntensity(double? value) {
  return value != null && value.isFinite && value > 0;
}

bool _isPositiveFinite(double? value) {
  return value != null && value.isFinite && value > 0;
}

double? _itlFromSlope(double? slope) {
  if (!_isPositiveFinite(slope)) return null;
  return 1 / slope!;
}

double? _validRpe(double? value) {
  if (value == null || !value.isFinite) return null;
  if (value < 1 || value > 10) return null;
  return value;
}

double? _slopeResponseIndex({
  required double? observedSlope,
  required double? referenceSlope,
}) {
  if (!_isPositiveFinite(observedSlope) || !_isPositiveFinite(referenceSlope)) {
    return null;
  }
  return observedSlope! / referenceSlope!;
}

String? _notesSummary(String? notes) {
  final text = (notes ?? '').trim();
  if (text.isEmpty) return null;
  if (text.length <= 90) return text;
  return '${text.substring(0, 90)}...';
}
