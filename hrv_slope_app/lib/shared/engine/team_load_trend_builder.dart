library;

import 'package:hrv_slope_app/data/database/app_database.dart';
import 'package:hrv_slope_app/shared/engine/team_heatmap_builder.dart';
import 'package:hrv_slope_app/shared/engine/team_heatmap_filter.dart';

const String teamLoadSlopeOnlyId = 'slope_only';

class TeamLoadDefinition {
  final String loadType;
  final String loadMetricName;
  final String? loadUnit;

  const TeamLoadDefinition({
    required this.loadType,
    required this.loadMetricName,
    required this.loadUnit,
  });

  factory TeamLoadDefinition.fromEvent(SessionEvent event) {
    return TeamLoadDefinition(
      loadType: event.loadType,
      loadMetricName: event.loadMetricName,
      loadUnit: event.loadUnit,
    );
  }

  String get normalizedLoadType => _normalizeText(loadType);
  String get normalizedMetricName => _normalizeText(loadMetricName);
  String? get normalizedLoadUnit => _normalizeUnit(loadUnit);

  String get id =>
      '$normalizedLoadType|$normalizedMetricName|${normalizedLoadUnit ?? ''}';

  String get loadTypeLabel {
    switch (normalizedLoadType) {
      case 'external':
        return 'External';
      case 'internal':
        return 'Internal';
    }
    final trimmed = loadType.trim();
    return trimmed.isEmpty ? '-' : trimmed;
  }

  String get metricLabel => _displayText(loadMetricName);
  String? get unitLabel => _displayNullable(loadUnit);

  String get label {
    final unit = unitLabel;
    return [loadTypeLabel, metricLabel, ?unit].join(' - ');
  }

  String get valueLabel {
    final unit = unitLabel;
    if (unit == null) return metricLabel;
    return '$metricLabel ($unit)';
  }

  bool get isSupportedLoadType =>
      normalizedLoadType == 'external' || normalizedLoadType == 'internal';

  bool get isUsable => isSupportedLoadType && normalizedMetricName.isNotEmpty;

  bool matchesEvent(SessionEvent event) {
    return normalizedLoadType == _normalizeText(event.loadType) &&
        normalizedMetricName == _normalizeText(event.loadMetricName) &&
        normalizedLoadUnit == _normalizeUnit(event.loadUnit);
  }
}

class TeamLoadTrend {
  final TeamHeatmapAthlete athlete;
  final TeamLoadDefinition? loadDefinition;
  final List<TeamLoadTrendPoint> points;

  const TeamLoadTrend({
    required this.athlete,
    required this.loadDefinition,
    required this.points,
  });

  int get visibleSessionCount => points
      .where(
        (point) =>
            point.includedByFilter &&
            (point.cell.state == TeamHeatmapCellState.valid ||
                point.cell.state == TeamHeatmapCellState.incomplete),
      )
      .length;

  int get validSlopePointCount =>
      points.where((point) => point.slope != null).length;

  int get loadPointCount =>
      points.where((point) => point.loadValue != null).length;

  int get fallbackCount => points
      .where(
        (point) => point.includedByFilter && point.cell.hasFallbackExercise,
      )
      .length;

  double? get latestValidSlope {
    final values = points
        .map((point) => point.slope)
        .whereType<double>()
        .where((value) => value.isFinite)
        .toList();
    if (values.isEmpty) return null;
    return values.last;
  }

  double? get medianValidSlope {
    final values = points
        .map((point) => point.slope)
        .whereType<double>()
        .where((value) => value.isFinite)
        .toList();
    return _median(values);
  }
}

class TeamLoadTrendPoint {
  final TeamHeatmapEvent event;
  final TeamHeatmapCell cell;
  final bool includedByFilter;
  final double? slope;
  final double? loadValue;

  const TeamLoadTrendPoint({
    required this.event,
    required this.cell,
    required this.includedByFilter,
    required this.slope,
    required this.loadValue,
  });

  int get eventId => event.id;
  int get athleteId => cell.athleteId;
  int? get sessionId => cell.sessionId;
  String? get classification => cell.classification;
  bool get hasFallbackExercise => cell.hasFallbackExercise;
}

List<TeamLoadDefinition> availableTeamLoadDefinitions(TeamHeatmapData data) {
  final definitions = <String, TeamLoadDefinition>{};

  for (var eventIndex = 0; eventIndex < data.events.length; eventIndex++) {
    final event = data.events[eventIndex];
    final definition = TeamLoadDefinition.fromEvent(event.event);
    if (!definition.isUsable) continue;
    if (!_eventHasCompatibleLoadValue(data, eventIndex, definition)) continue;
    definitions.putIfAbsent(definition.id, () => definition);
  }

  return List.unmodifiable(definitions.values);
}

TeamLoadTrend? buildTeamLoadTrend({
  required TeamHeatmapData data,
  required int athleteId,
  TeamLoadDefinition? loadDefinition,
  TeamHeatmapFilter filter = const TeamHeatmapFilter(),
}) {
  TeamHeatmapRow? row;
  for (final candidate in data.rows) {
    if (candidate.athlete.id == athleteId) {
      row = candidate;
      break;
    }
  }
  if (row == null) return null;

  final points = <TeamLoadTrendPoint>[];
  for (var index = 0; index < data.events.length; index++) {
    final event = data.events[index];
    final cell = row.cells[index];
    final includedByFilter =
        !filter.hasCellFilters || teamHeatmapCellMatchesFilter(cell, filter);
    final slope = _slopeForCell(cell, includedByFilter);
    final loadValue = _loadForCell(
      event: event,
      cell: cell,
      includedByFilter: includedByFilter,
      definition: loadDefinition,
    );
    points.add(
      TeamLoadTrendPoint(
        event: event,
        cell: cell,
        includedByFilter: includedByFilter,
        slope: slope,
        loadValue: loadValue,
      ),
    );
  }

  return TeamLoadTrend(
    athlete: row.athlete,
    loadDefinition: loadDefinition,
    points: List.unmodifiable(points),
  );
}

bool _eventHasCompatibleLoadValue(
  TeamHeatmapData data,
  int eventIndex,
  TeamLoadDefinition definition,
) {
  final event = data.events[eventIndex];
  if (!definition.matchesEvent(event.event)) return false;
  for (final row in data.rows) {
    final cell = row.cells[eventIndex];
    if (_cellHasCompatibleLoadValue(
      event: event,
      cell: cell,
      definition: definition,
    )) {
      return true;
    }
  }
  return false;
}

double? _slopeForCell(TeamHeatmapCell cell, bool includedByFilter) {
  if (!includedByFilter) return null;
  if (cell.state != TeamHeatmapCellState.valid) return null;
  final slope = cell.slope;
  if (slope == null || !slope.isFinite) return null;
  return slope;
}

double? _loadForCell({
  required TeamHeatmapEvent event,
  required TeamHeatmapCell cell,
  required bool includedByFilter,
  required TeamLoadDefinition? definition,
}) {
  if (!includedByFilter || definition == null) return null;
  if (!_cellHasCompatibleLoadValue(
    event: event,
    cell: cell,
    definition: definition,
  )) {
    return null;
  }
  return cell.loadValue;
}

bool _cellHasCompatibleLoadValue({
  required TeamHeatmapEvent event,
  required TeamHeatmapCell cell,
  required TeamLoadDefinition definition,
}) {
  if (!definition.matchesEvent(event.event)) return false;
  if (cell.state != TeamHeatmapCellState.valid &&
      cell.state != TeamHeatmapCellState.incomplete) {
    return false;
  }
  if (cell.sessionId == null || cell.loadUnitMismatch) return false;
  final value = cell.loadValue;
  if (value == null || !value.isFinite) return false;
  return definition.normalizedLoadUnit == _normalizeUnit(cell.loadUnit);
}

String _displayText(String value) {
  final trimmed = value.trim().replaceAll(RegExp(r'\s+'), ' ');
  return trimmed.isEmpty ? '-' : trimmed;
}

String? _displayNullable(String? value) {
  final trimmed = value?.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}

String _normalizeText(String value) {
  return value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
}

String? _normalizeUnit(String? value) {
  final trimmed = value?.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed.toLowerCase();
}

double? _median(List<double> values) {
  if (values.isEmpty) return null;
  final sorted = [...values]..sort();
  final mid = sorted.length ~/ 2;
  if (sorted.length.isOdd) return sorted[mid];
  return (sorted[mid - 1] + sorted[mid]) / 2;
}
