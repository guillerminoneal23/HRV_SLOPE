library;

import 'dart:convert';

import 'package:hrv_slope_app/data/database/app_database.dart';
import 'package:hrv_slope_app/data/database/daos/session_events_dao.dart';

enum TeamHeatmapCellState { valid, missing, incomplete, duplicate }

class TeamHeatmapData {
  final Team? team;
  final List<TeamHeatmapEvent> events;
  final List<TeamHeatmapAthlete> athletes;
  final List<TeamHeatmapRow> rows;
  final TeamHeatmapSummary summary;

  const TeamHeatmapData({
    required this.team,
    required this.events,
    required this.athletes,
    required this.rows,
    required this.summary,
  });
}

class TeamHeatmapEvent {
  final SessionEvent event;

  const TeamHeatmapEvent({required this.event});

  int get id => event.id;
  String get date => event.date;
}

class TeamHeatmapAthlete {
  final Athlete athlete;

  const TeamHeatmapAthlete({required this.athlete});

  int get id => athlete.id;
  String get name => athlete.name;
  bool get isArchived => athlete.isArchived;
}

class TeamHeatmapRow {
  final TeamHeatmapAthlete athlete;
  final List<TeamHeatmapCell> cells;

  const TeamHeatmapRow({required this.athlete, required this.cells});

  List<TeamHeatmapCell> get sessionCells => cells
      .where(
        (cell) =>
            cell.state == TeamHeatmapCellState.valid ||
            cell.state == TeamHeatmapCellState.incomplete,
      )
      .toList();

  int get visibleSessionCount => sessionCells.length;
  int get fallbackCount =>
      cells.where((cell) => cell.hasFallbackExercise).length;
  double? get lastSlope {
    final validCells = sessionCells
        .where(
          (cell) =>
              cell.state == TeamHeatmapCellState.valid &&
              cell.slope != null &&
              cell.slope!.isFinite,
        )
        .toList();
    if (validCells.isEmpty) return null;
    return validCells.last.slope;
  }

  double? get medianSlope {
    final values = sessionCells
        .where((cell) => cell.state == TeamHeatmapCellState.valid)
        .map((cell) => cell.slope)
        .whereType<double>()
        .where((value) => value.isFinite)
        .toList();
    return _median(values);
  }
}

class TeamHeatmapCell {
  final int eventId;
  final int athleteId;
  final TeamHeatmapCellState state;
  final int? sessionId;
  final List<int> duplicateSessionIds;
  final double? slope;
  final String? classification;
  final double? rmssdExercise;
  final bool rmssdExerciseIsDefault;
  final String? rmssdExerciseSource;
  final double? rmssdRecovery;
  final double? loadValue;
  final String? loadUnit;
  final bool loadUnitMismatch;
  final bool isIncomplete;
  final bool hasWarning;
  final List<String> warnings;
  final List<String> statusLabels;

  const TeamHeatmapCell({
    required this.eventId,
    required this.athleteId,
    required this.state,
    this.sessionId,
    this.duplicateSessionIds = const [],
    this.slope,
    this.classification,
    this.rmssdExercise,
    this.rmssdExerciseIsDefault = false,
    this.rmssdExerciseSource,
    this.rmssdRecovery,
    this.loadValue,
    this.loadUnit,
    this.loadUnitMismatch = false,
    this.isIncomplete = false,
    this.hasWarning = false,
    this.warnings = const [],
    this.statusLabels = const [],
  });

  bool get hasFallbackExercise =>
      rmssdExerciseIsDefault && rmssdExerciseSource == 'fallback_4_ms';

  bool get hasSession => sessionId != null || duplicateSessionIds.isNotEmpty;
}

class TeamHeatmapSummary {
  final int eventCount;
  final int athleteCount;
  final int validCellCount;
  final int incompleteCellCount;
  final int missingCellCount;
  final int fallbackCellCount;
  final int duplicateCellCount;

  const TeamHeatmapSummary({
    required this.eventCount,
    required this.athleteCount,
    required this.validCellCount,
    required this.incompleteCellCount,
    required this.missingCellCount,
    required this.fallbackCellCount,
    required this.duplicateCellCount,
  });
}

TeamHeatmapData buildTeamHeatmap(TeamLongitudinalBundle bundle) {
  final sessionsWithEvents = bundle.sessions
      .where((session) => session.eventId != null)
      .toList();
  final eventIdsWithSessions = sessionsWithEvents
      .map((session) => session.eventId!)
      .toSet();
  final events =
      bundle.events
          .where((event) => eventIdsWithSessions.contains(event.id))
          .map((event) => TeamHeatmapEvent(event: event))
          .toList()
        ..sort(_compareEvents);

  final athletesById = {
    for (final athlete in bundle.athletes) athlete.id: athlete,
  };
  final athleteIdsWithSessions = sessionsWithEvents
      .map((session) => session.athleteId)
      .where(athletesById.containsKey)
      .toSet();
  final athletes = [
    for (final athleteId in athleteIdsWithSessions)
      TeamHeatmapAthlete(athlete: athletesById[athleteId]!),
  ]..sort(_compareAthletes);

  final sessionsByCell = <String, List<Session>>{};
  for (final session in sessionsWithEvents) {
    if (!eventIdsWithSessions.contains(session.eventId)) continue;
    if (!athletesById.containsKey(session.athleteId)) continue;
    sessionsByCell
        .putIfAbsent(_cellKey(session.athleteId, session.eventId!), () => [])
        .add(session);
  }

  final variablesBySession = _groupVariablesBySessionId(bundle.variables);
  final notesBySession = _groupNotesBySessionId(bundle.notes);

  final rows = [
    for (final athlete in athletes)
      TeamHeatmapRow(
        athlete: athlete,
        cells: [
          for (final event in events)
            _buildCell(
              athleteId: athlete.id,
              event: event.event,
              sessions:
                  sessionsByCell[_cellKey(athlete.id, event.id)] ?? const [],
              variablesBySession: variablesBySession,
              notesBySession: notesBySession,
            ),
        ],
      ),
  ];

  final cells = rows.expand((row) => row.cells).toList();
  return TeamHeatmapData(
    team: bundle.team,
    events: events,
    athletes: athletes,
    rows: rows,
    summary: TeamHeatmapSummary(
      eventCount: events.length,
      athleteCount: athletes.length,
      validCellCount: cells
          .where((cell) => cell.state == TeamHeatmapCellState.valid)
          .length,
      incompleteCellCount: cells
          .where((cell) => cell.state == TeamHeatmapCellState.incomplete)
          .length,
      missingCellCount: cells
          .where((cell) => cell.state == TeamHeatmapCellState.missing)
          .length,
      fallbackCellCount: cells.where((cell) => cell.hasFallbackExercise).length,
      duplicateCellCount: cells
          .where((cell) => cell.state == TeamHeatmapCellState.duplicate)
          .length,
    ),
  );
}

TeamHeatmapCell _buildCell({
  required int athleteId,
  required SessionEvent event,
  required List<Session> sessions,
  required Map<int, List<IntensityVariable>> variablesBySession,
  required Map<int, List<ExclusionsOrNote>> notesBySession,
}) {
  if (sessions.isEmpty) {
    return TeamHeatmapCell(
      eventId: event.id,
      athleteId: athleteId,
      state: TeamHeatmapCellState.missing,
      statusLabels: const ['No participation'],
    );
  }
  if (sessions.length > 1) {
    final sessionIds = sessions.map((session) => session.id).toList()..sort();
    return TeamHeatmapCell(
      eventId: event.id,
      athleteId: athleteId,
      state: TeamHeatmapCellState.duplicate,
      duplicateSessionIds: List.unmodifiable(sessionIds),
      hasWarning: true,
      warnings: List.unmodifiable([
        'Duplicate sessions for athlete $athleteId in event ${event.id}: '
            '${sessionIds.join(', ')}',
      ]),
      statusLabels: const ['Duplicate sessions'],
    );
  }

  final session = sessions.single;
  final fallback =
      session.rmssdExerciseIsDefault &&
      session.rmssdExerciseSource == 'fallback_4_ms';
  final incomplete =
      session.isDraft ||
      session.rmssdExercise == null ||
      session.rmssdRecovery == null ||
      session.slopeInterpreted == null ||
      session.classification == null;
  final loadMatch = _findEventLoadVariable(
    variablesBySession[session.id] ?? const [],
    loadType: event.loadType,
    loadMetricName: event.loadMetricName,
    loadUnit: event.loadUnit,
  );
  final notes = notesBySession[session.id] ?? const [];
  final warnings = <String>[
    if (session.isDraft) 'Draft session',
    if (session.slopeInterpreted == null) 'RMSSD-Slope missing',
    if (session.classification == null) 'Classification unavailable',
    if (session.rmssdExercise == null) 'RMSSD exercise missing',
    if (session.rmssdRecovery == null) 'RMSSD recovery missing',
    if (session.rrQualityDecision == 'warning') 'RR quality warning',
    if (session.rrCorrectionEnabled) 'RR correction applied',
    ..._qualityNotes(session.rrQualityNotesJson),
    if (loadMatch.unitMismatch) 'Load unit differs from event unit',
    for (final note in notes)
      if (note.type != 'note') note.reason,
  ];
  final hasWarning = warnings.isNotEmpty;

  return TeamHeatmapCell(
    eventId: event.id,
    athleteId: athleteId,
    state: incomplete
        ? TeamHeatmapCellState.incomplete
        : TeamHeatmapCellState.valid,
    sessionId: session.id,
    slope: session.slopeInterpreted,
    classification: session.classification,
    rmssdExercise: session.rmssdExercise,
    rmssdExerciseIsDefault: session.rmssdExerciseIsDefault,
    rmssdExerciseSource: session.rmssdExerciseSource,
    rmssdRecovery: session.rmssdRecovery,
    loadValue: loadMatch.variable?.value,
    loadUnit: loadMatch.variable?.unit ?? event.loadUnit,
    loadUnitMismatch: loadMatch.unitMismatch,
    isIncomplete: incomplete,
    hasWarning: hasWarning,
    warnings: List.unmodifiable(warnings),
    statusLabels: List.unmodifiable([
      if (incomplete) 'Incomplete',
      if (fallback) 'Fallback 4 ms',
      if (session.rrQualityDecision == 'warning') 'Warning',
      if (session.rrCorrectionEnabled) 'RR corrected',
      if (notes.any((note) => note.type == 'exclusion')) 'Exclusion',
      if (loadMatch.unitMismatch) 'Unit mismatch',
      if (!incomplete &&
          !fallback &&
          session.rrQualityDecision != 'warning' &&
          !session.rrCorrectionEnabled &&
          !notes.any((note) => note.type == 'exclusion') &&
          !loadMatch.unitMismatch)
        'OK',
    ]),
  );
}

_EventLoadMatch _findEventLoadVariable(
  List<IntensityVariable> variables, {
  required String loadType,
  required String loadMetricName,
  required String? loadUnit,
}) {
  final normalizedType = _normalizeText(loadType);
  final normalizedMetric = _normalizeText(loadMetricName);
  final normalizedUnit = _normalizeUnit(loadUnit);
  IntensityVariable? firstMetricMatch;
  IntensityVariable? compatibleMatch;

  for (final variable in variables) {
    if (_normalizeText(variable.category) != normalizedType) continue;
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

Map<int, List<IntensityVariable>> _groupVariablesBySessionId(
  List<IntensityVariable> rows,
) {
  final grouped = <int, List<IntensityVariable>>{};
  for (final row in rows) {
    grouped.putIfAbsent(row.sessionId, () => []).add(row);
  }
  return grouped;
}

Map<int, List<ExclusionsOrNote>> _groupNotesBySessionId(
  List<ExclusionsOrNote> rows,
) {
  final grouped = <int, List<ExclusionsOrNote>>{};
  for (final row in rows) {
    final sessionId = row.sessionId;
    if (sessionId == null) continue;
    grouped.putIfAbsent(sessionId, () => []).add(row);
  }
  return grouped;
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

String _cellKey(int athleteId, int eventId) => '$athleteId:$eventId';

int _compareEvents(TeamHeatmapEvent a, TeamHeatmapEvent b) {
  final dateCompare = a.event.date.compareTo(b.event.date);
  if (dateCompare != 0) return dateCompare;
  return a.id.compareTo(b.id);
}

int _compareAthletes(TeamHeatmapAthlete a, TeamHeatmapAthlete b) {
  final nameCompare = a.name.toLowerCase().compareTo(b.name.toLowerCase());
  if (nameCompare != 0) return nameCompare;
  return a.id.compareTo(b.id);
}

double? _median(List<double> values) {
  if (values.isEmpty) return null;
  final sorted = [...values]..sort();
  final mid = sorted.length ~/ 2;
  if (sorted.length.isOdd) return sorted[mid];
  return (sorted[mid - 1] + sorted[mid]) / 2;
}

String _normalizeText(String value) {
  return value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
}

String? _normalizeUnit(String? value) {
  final trimmed = value?.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed.toLowerCase();
}
