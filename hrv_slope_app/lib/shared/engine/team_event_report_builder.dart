library;

import 'dart:convert';
import 'package:hrv_slope_app/data/database/app_database.dart';
import 'package:hrv_slope_app/data/database/daos/session_events_dao.dart';
import 'package:hrv_slope_app/data/database/daos/sessions_dao.dart';
import 'package:hrv_slope_app/shared/engine/recovery_response_labels.dart';

class TeamEventReportData {
  final SessionEvent event;
  final Team? team;
  final TeamEventReportSummary summary;
  final List<TeamEventClassificationCount> classificationCounts;
  final List<TeamEventReportRow> rows;

  const TeamEventReportData({
    required this.event,
    required this.team,
    required this.summary,
    required this.classificationCounts,
    required this.rows,
  });
}

class TeamEventReportSummary {
  final int participantCount;
  final int validParticipantCount;
  final double? medianSlope;
  final double? iqrSlope;
  final int fallbackExerciseCount;
  final int incompleteCount;
  final double? medianLoad;

  const TeamEventReportSummary({
    required this.participantCount,
    required this.validParticipantCount,
    this.medianSlope,
    this.iqrSlope,
    required this.fallbackExerciseCount,
    required this.incompleteCount,
    this.medianLoad,
  });
}

class TeamEventClassificationCount {
  final String classification;
  final String label;
  final int count;

  const TeamEventClassificationCount({
    required this.classification,
    required this.label,
    required this.count,
  });
}

class TeamEventReportRow {
  final int sessionId;
  final int athleteId;
  final String athleteName;
  final bool athleteIsArchived;
  final Session session;
  final Athlete athlete;
  final double? rmssdExercise;
  final bool rmssdExerciseIsDefault;
  final String? rmssdExerciseSource;
  final double? rmssdRecovery;
  final double? loadValue;
  final String? loadUnit;
  final bool loadUnitMismatch;
  final double? slopeInterpreted;
  final String? classification;
  final bool isIncomplete;
  final bool hasWarnings;
  final List<String> warnings;
  final List<String> statusLabels;

  const TeamEventReportRow({
    required this.sessionId,
    required this.athleteId,
    required this.athleteName,
    required this.athleteIsArchived,
    required this.session,
    required this.athlete,
    this.rmssdExercise,
    required this.rmssdExerciseIsDefault,
    this.rmssdExerciseSource,
    this.rmssdRecovery,
    this.loadValue,
    this.loadUnit,
    this.loadUnitMismatch = false,
    this.slopeInterpreted,
    this.classification,
    this.isIncomplete = false,
    this.hasWarnings = false,
    this.warnings = const [],
    this.statusLabels = const [],
  });

  bool get hasFallbackExercise =>
      rmssdExerciseIsDefault && rmssdExerciseSource == 'fallback_4_ms';
}

TeamEventReportData buildTeamEventReport(SessionEventDetailBundle bundle) {
  final rows = [
    for (final detail in bundle.sessionDetails)
      _buildRow(detail: detail, event: bundle.event),
  ]..sort(compareTeamEventRowsDefault);

  final completeRows = rows.where((row) => !row.isIncomplete).toList();
  final slopes = completeRows
      .map((row) => row.slopeInterpreted)
      .whereType<double>()
      .where((value) => value.isFinite)
      .toList();
  final loadValues = rows
      .where((row) => !row.loadUnitMismatch)
      .map((row) => row.loadValue)
      .whereType<double>()
      .where((value) => value.isFinite)
      .toList();
  final classificationCounts = _classificationCounts(rows);

  return TeamEventReportData(
    event: bundle.event,
    team: bundle.team,
    rows: rows,
    classificationCounts: classificationCounts,
    summary: TeamEventReportSummary(
      participantCount: rows.length,
      validParticipantCount: completeRows.length,
      medianSlope: _median(slopes),
      iqrSlope: _iqr(slopes),
      fallbackExerciseCount: rows
          .where((row) => row.hasFallbackExercise)
          .length,
      incompleteCount: rows.where((row) => row.isIncomplete).length,
      medianLoad: _median(loadValues),
    ),
  );
}

int compareTeamEventRowsDefault(TeamEventReportRow a, TeamEventReportRow b) {
  final statusCompare = _statusPriority(a).compareTo(_statusPriority(b));
  if (statusCompare != 0) return statusCompare;

  final classCompare = _classificationPriority(
    a.classification,
  ).compareTo(_classificationPriority(b.classification));
  if (classCompare != 0) return classCompare;

  return _compareNames(a.athleteName, b.athleteName);
}

int compareTeamEventRowsByName(TeamEventReportRow a, TeamEventReportRow b) {
  return _compareNames(a.athleteName, b.athleteName);
}

int compareTeamEventRowsBySlope(TeamEventReportRow a, TeamEventReportRow b) {
  return _compareNullableNumbers(a.slopeInterpreted, b.slopeInterpreted);
}

int compareTeamEventRowsByLoad(TeamEventReportRow a, TeamEventReportRow b) {
  return _compareNullableNumbers(a.loadValue, b.loadValue);
}

TeamEventReportRow _buildRow({
  required SessionDetail detail,
  required SessionEvent event,
}) {
  final session = detail.session;
  final loadMatch = _findEventLoadVariable(
    detail.variables,
    loadType: event.loadType,
    loadMetricName: event.loadMetricName,
    loadUnit: event.loadUnit,
  );
  final fallback =
      session.rmssdExerciseIsDefault &&
      session.rmssdExerciseSource == 'fallback_4_ms';
  final missingRequiredData =
      session.isDraft ||
      session.rmssdExercise == null ||
      session.rmssdRecovery == null ||
      session.slopeInterpreted == null ||
      session.classification == null;
  final loadVariable = loadMatch.variable;
  final loadUnitMismatch = loadMatch.unitMismatch;

  final warnings = <String>[
    if (fallback) 'RMSSD exercise fallback 4 ms',
    if (session.isDraft) 'Draft session',
    if (session.rmssdExercise == null) 'RMSSD exercise missing',
    if (session.rmssdRecovery == null) 'RMSSD recovery missing',
    if (session.slopeInterpreted == null) 'RMSSD-Slope missing',
    if (session.classification == null) 'Classification unavailable',
    if (loadVariable == null) 'Event load variable unavailable',
    if (loadUnitMismatch) 'Load unit differs from event unit',
    if (session.rrQualityDecision == 'warning') 'RR quality warning',
    if (session.rrCorrectionEnabled) 'RR correction applied',
    ..._qualityNotes(session.rrQualityNotesJson),
    for (final note in detail.notes)
      if (note.type != 'note') note.reason,
  ];

  final hasWarnings = warnings.any(
    (warning) =>
        warning != 'RMSSD exercise fallback 4 ms' &&
        warning != 'Classification unavailable',
  );

  return TeamEventReportRow(
    sessionId: session.id,
    athleteId: detail.athlete.id,
    athleteName: detail.athlete.name,
    athleteIsArchived: detail.athlete.isArchived,
    session: session,
    athlete: detail.athlete,
    rmssdExercise: session.rmssdExercise,
    rmssdExerciseIsDefault: session.rmssdExerciseIsDefault,
    rmssdExerciseSource: session.rmssdExerciseSource,
    rmssdRecovery: session.rmssdRecovery,
    loadValue: loadVariable?.value,
    loadUnit: loadVariable?.unit ?? event.loadUnit,
    loadUnitMismatch: loadUnitMismatch,
    slopeInterpreted: session.slopeInterpreted,
    classification: session.classification,
    isIncomplete: missingRequiredData,
    hasWarnings: hasWarnings || missingRequiredData,
    warnings: List.unmodifiable(warnings),
    statusLabels: List.unmodifiable([
      if (missingRequiredData) 'Incomplete',
      if (fallback) 'Fallback 4 ms',
      if (session.rrQualityDecision == 'warning') 'Warning',
      if (session.rrCorrectionEnabled) 'RR corrected',
      if (detail.notes.any((note) => note.type == 'exclusion')) 'Exclusion',
      if (loadUnitMismatch) 'Unit mismatch',
    ]),
  );
}

_EventLoadMatch _findEventLoadVariable(
  List<IntensityVariable> variables, {
  required String loadType,
  required String loadMetricName,
  required String? loadUnit,
}) {
  final normalizedMetric = _normalizeText(loadMetricName);
  final normalizedUnit = _normalizeUnit(loadUnit);
  IntensityVariable? firstMetricMatch;
  IntensityVariable? compatibleMatch;

  for (final variable in variables) {
    if (_normalizeText(variable.category) != _normalizeText(loadType)) {
      continue;
    }
    if (_normalizeText(variable.name) != normalizedMetric) continue;
    firstMetricMatch ??= variable;
    if (_normalizeUnit(variable.unit) == normalizedUnit) {
      compatibleMatch ??= variable;
    }
  }

  return _EventLoadMatch(
    variable: compatibleMatch ?? firstMetricMatch,
    unitMismatch: firstMetricMatch != null && compatibleMatch == null,
  );
}

class _EventLoadMatch {
  final IntensityVariable? variable;
  final bool unitMismatch;

  const _EventLoadMatch({required this.variable, required this.unitMismatch});
}

List<TeamEventClassificationCount> _classificationCounts(
  List<TeamEventReportRow> rows,
) {
  final counts = <String, int>{};
  for (final row in rows) {
    final classification = row.classification;
    if (classification == null) continue;
    counts[classification] = (counts[classification] ?? 0) + 1;
  }

  final result = [
    for (final entry in counts.entries)
      TeamEventClassificationCount(
        classification: entry.key,
        label: recoveryResponseShortLabelForClassificationKey(entry.key),
        count: entry.value,
      ),
  ];
  result.sort(
    (a, b) => _classificationPriority(
      a.classification,
    ).compareTo(_classificationPriority(b.classification)),
  );
  return result;
}

double? _median(List<double> values) {
  if (values.isEmpty) return null;
  final sorted = [...values]..sort();
  final mid = sorted.length ~/ 2;
  if (sorted.length.isOdd) return sorted[mid];
  return (sorted[mid - 1] + sorted[mid]) / 2;
}

double? _iqr(List<double> values) {
  if (values.isEmpty) return null;
  final sorted = [...values]..sort();
  return _quantile(sorted, 0.75) - _quantile(sorted, 0.25);
}

double _quantile(List<double> sortedValues, double q) {
  if (sortedValues.length == 1) return sortedValues.single;
  final position = (sortedValues.length - 1) * q;
  final lower = position.floor();
  final upper = position.ceil();
  if (lower == upper) return sortedValues[lower];
  final fraction = position - lower;
  return sortedValues[lower] +
      (sortedValues[upper] - sortedValues[lower]) * fraction;
}

List<String> _qualityNotes(String? rawJson) {
  if (rawJson == null || rawJson.trim().isEmpty) return const [];
  try {
    final decoded = jsonDecode(rawJson);
    if (decoded is! List) return const [];
    return decoded.map((item) => item.toString()).toList();
  } catch (_) {
    return const [];
  }
}

int _statusPriority(TeamEventReportRow row) {
  if (row.isIncomplete) return 0;
  if (row.hasWarnings) return 1;
  return 2;
}

int _classificationPriority(String? classification) {
  switch (classification) {
    case null:
      return 0;
    case 'very_high_internal_load':
    case 'veryHighInternalLoad':
    case 'Lower-than-expected recovery response':
    case 'Lower-than-expected':
      return 1;
    case 'high_or_moderate_internal_load':
    case 'highOrModerateInternalLoad':
      return 2;
    case 'expected_response':
    case 'expectedResponse':
    case 'Expected recovery response':
    case 'Expected':
      return 3;
    case 'low_internal_load_or_fast_recovery':
    case 'lowInternalLoadOrFastRecovery':
    case 'Favorable recovery response':
    case 'Favorable':
      return 4;
    default:
      return 5;
  }
}

int _compareNames(String a, String b) {
  return a.toLowerCase().compareTo(b.toLowerCase());
}

int _compareNullableNumbers(double? a, double? b) {
  final aValid = a != null && a.isFinite;
  final bValid = b != null && b.isFinite;
  if (aValid && bValid) return a.compareTo(b);
  if (aValid) return -1;
  if (bValid) return 1;
  return 0;
}

String _normalizeText(String value) {
  return value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
}

String? _normalizeUnit(String? value) {
  final trimmed = value?.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed.toLowerCase();
}
