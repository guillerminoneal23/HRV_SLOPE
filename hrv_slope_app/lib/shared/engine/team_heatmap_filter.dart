library;

import 'package:hrv_slope_app/shared/engine/team_heatmap_builder.dart';

enum TeamHeatmapFallbackFilter { all, fallbackOnly, measuredOnly }

extension TeamHeatmapFallbackFilterLabel on TeamHeatmapFallbackFilter {
  String get label {
    switch (this) {
      case TeamHeatmapFallbackFilter.all:
        return 'All';
      case TeamHeatmapFallbackFilter.fallbackOnly:
        return 'Fallback only';
      case TeamHeatmapFallbackFilter.measuredOnly:
        return 'Measured only';
    }
  }
}

enum TeamHeatmapSessionStateFilter { all, valid, incomplete }

extension TeamHeatmapSessionStateFilterLabel on TeamHeatmapSessionStateFilter {
  String get label {
    switch (this) {
      case TeamHeatmapSessionStateFilter.all:
        return 'All';
      case TeamHeatmapSessionStateFilter.valid:
        return 'Valid';
      case TeamHeatmapSessionStateFilter.incomplete:
        return 'Incomplete';
    }
  }
}

class TeamHeatmapClassificationOption {
  final String id;
  final String label;
  final List<String> values;

  const TeamHeatmapClassificationOption({
    required this.id,
    required this.label,
    required this.values,
  });

  bool matches(String? classification) {
    if (classification == null) return false;
    final normalized = _normalizeClassification(classification);
    return values.map(_normalizeClassification).contains(normalized);
  }
}

const teamHeatmapClassificationOptions = [
  TeamHeatmapClassificationOption(
    id: 'very_high_internal_load',
    label: 'Very high',
    values: [
      'very_high_internal_load',
      'veryHighInternalLoad',
      'Lower-than-expected recovery response',
      'Lower-than-expected',
    ],
  ),
  TeamHeatmapClassificationOption(
    id: 'high_or_moderate_internal_load',
    label: 'High/moderate',
    values: ['high_or_moderate_internal_load', 'highOrModerateInternalLoad'],
  ),
  TeamHeatmapClassificationOption(
    id: 'expected_response',
    label: 'Expected',
    values: [
      'expected_response',
      'expectedResponse',
      'Expected recovery response',
      'Expected',
    ],
  ),
  TeamHeatmapClassificationOption(
    id: 'low_internal_load_or_fast_recovery',
    label: 'Favorable',
    values: [
      'low_internal_load_or_fast_recovery',
      'lowInternalLoadOrFastRecovery',
      'Favorable recovery response',
      'Favorable',
    ],
  ),
];

class TeamHeatmapFilter {
  final String athleteQuery;
  final Set<String> classificationOptionIds;
  final TeamHeatmapFallbackFilter fallbackFilter;
  final TeamHeatmapSessionStateFilter stateFilter;

  const TeamHeatmapFilter({
    this.athleteQuery = '',
    this.classificationOptionIds = const {},
    this.fallbackFilter = TeamHeatmapFallbackFilter.all,
    this.stateFilter = TeamHeatmapSessionStateFilter.all,
  });

  bool get hasAthleteQuery => athleteQuery.trim().isNotEmpty;

  bool get hasCellFilters =>
      classificationOptionIds.isNotEmpty ||
      fallbackFilter != TeamHeatmapFallbackFilter.all ||
      stateFilter != TeamHeatmapSessionStateFilter.all;

  int get activeFilterCount {
    var count = 0;
    if (hasAthleteQuery) count++;
    if (classificationOptionIds.isNotEmpty) count++;
    if (fallbackFilter != TeamHeatmapFallbackFilter.all) count++;
    if (stateFilter != TeamHeatmapSessionStateFilter.all) count++;
    return count;
  }

  TeamHeatmapFilter copyWith({
    String? athleteQuery,
    Set<String>? classificationOptionIds,
    TeamHeatmapFallbackFilter? fallbackFilter,
    TeamHeatmapSessionStateFilter? stateFilter,
  }) {
    return TeamHeatmapFilter(
      athleteQuery: athleteQuery ?? this.athleteQuery,
      classificationOptionIds:
          classificationOptionIds ?? this.classificationOptionIds,
      fallbackFilter: fallbackFilter ?? this.fallbackFilter,
      stateFilter: stateFilter ?? this.stateFilter,
    );
  }
}

class TeamHeatmapFilteredView {
  final TeamHeatmapData data;
  final TeamHeatmapFilter filter;
  final List<TeamHeatmapFilteredRow> rows;

  const TeamHeatmapFilteredView({
    required this.data,
    required this.filter,
    required this.rows,
  });

  List<TeamHeatmapEvent> get events => data.events;
  bool get hasCellFilters => filter.hasCellFilters;
  bool get hasActiveFilters => filter.activeFilterCount > 0;
}

class TeamHeatmapFilteredRow {
  final TeamHeatmapRow row;
  final List<TeamHeatmapFilteredCell> cells;
  final TeamHeatmapFilteredAthleteStats stats;

  const TeamHeatmapFilteredRow({
    required this.row,
    required this.cells,
    required this.stats,
  });

  TeamHeatmapAthlete get athlete => row.athlete;
}

class TeamHeatmapFilteredCell {
  final TeamHeatmapCell cell;
  final bool matches;

  const TeamHeatmapFilteredCell({required this.cell, required this.matches});
}

class TeamHeatmapFilteredAthleteStats {
  final int visibleSessionCount;
  final int validSessionCount;
  final double? latestValidSlope;
  final double? medianValidSlope;
  final int fallbackCount;

  const TeamHeatmapFilteredAthleteStats({
    required this.visibleSessionCount,
    required this.validSessionCount,
    required this.latestValidSlope,
    required this.medianValidSlope,
    required this.fallbackCount,
  });
}

TeamHeatmapFilteredView filterTeamHeatmap(
  TeamHeatmapData data,
  TeamHeatmapFilter filter,
) {
  final query = filter.athleteQuery.trim().toLowerCase();
  final rows = <TeamHeatmapFilteredRow>[];

  for (final row in data.rows) {
    if (query.isNotEmpty && !row.athlete.name.toLowerCase().contains(query)) {
      continue;
    }

    final cells = [
      for (final cell in row.cells)
        TeamHeatmapFilteredCell(
          cell: cell,
          matches: _cellMatchesFilter(cell, filter),
        ),
    ];
    if (filter.hasCellFilters && !cells.any((cell) => cell.matches)) {
      continue;
    }

    rows.add(
      TeamHeatmapFilteredRow(
        row: row,
        cells: cells,
        stats: _buildStats(row, cells, filter),
      ),
    );
  }

  return TeamHeatmapFilteredView(data: data, filter: filter, rows: rows);
}

List<TeamHeatmapClassificationOption> availableTeamHeatmapClassifications(
  TeamHeatmapData data,
) {
  return [
    for (final option in teamHeatmapClassificationOptions)
      if (data.rows
          .expand((row) => row.cells)
          .where((cell) => cell.state == TeamHeatmapCellState.valid)
          .any((cell) => option.matches(cell.classification)))
        option,
  ];
}

bool _cellMatchesFilter(TeamHeatmapCell cell, TeamHeatmapFilter filter) {
  if (!filter.hasCellFilters) return true;
  if (!_matchesState(cell, filter.stateFilter)) return false;
  if (!_matchesFallback(cell, filter.fallbackFilter)) return false;
  if (!_matchesClassification(cell, filter.classificationOptionIds)) {
    return false;
  }
  return true;
}

bool _matchesState(
  TeamHeatmapCell cell,
  TeamHeatmapSessionStateFilter stateFilter,
) {
  switch (stateFilter) {
    case TeamHeatmapSessionStateFilter.all:
      return cell.state == TeamHeatmapCellState.valid ||
          cell.state == TeamHeatmapCellState.incomplete;
    case TeamHeatmapSessionStateFilter.valid:
      return cell.state == TeamHeatmapCellState.valid;
    case TeamHeatmapSessionStateFilter.incomplete:
      return cell.state == TeamHeatmapCellState.incomplete;
  }
}

bool _matchesFallback(
  TeamHeatmapCell cell,
  TeamHeatmapFallbackFilter fallbackFilter,
) {
  switch (fallbackFilter) {
    case TeamHeatmapFallbackFilter.all:
      return true;
    case TeamHeatmapFallbackFilter.fallbackOnly:
      return cell.hasFallbackExercise;
    case TeamHeatmapFallbackFilter.measuredOnly:
      return cell.rmssdExercise != null && !cell.hasFallbackExercise;
  }
}

bool _matchesClassification(TeamHeatmapCell cell, Set<String> selectedIds) {
  if (selectedIds.isEmpty) return true;
  if (cell.state != TeamHeatmapCellState.valid) return false;
  final optionId = _classificationOptionIdFor(cell.classification);
  return optionId != null && selectedIds.contains(optionId);
}

TeamHeatmapFilteredAthleteStats _buildStats(
  TeamHeatmapRow row,
  List<TeamHeatmapFilteredCell> filteredCells,
  TeamHeatmapFilter filter,
) {
  final statCells = filter.hasCellFilters
      ? filteredCells
            .where((filteredCell) => filteredCell.matches)
            .map((filteredCell) => filteredCell.cell)
      : row.cells;
  final sessionCells = statCells
      .where(
        (cell) =>
            cell.state == TeamHeatmapCellState.valid ||
            cell.state == TeamHeatmapCellState.incomplete,
      )
      .toList();
  final validCells = sessionCells
      .where((cell) => cell.state == TeamHeatmapCellState.valid)
      .toList();
  final validSlopeValues = validCells
      .map((cell) => cell.slope)
      .whereType<double>()
      .where((value) => value.isFinite)
      .toList();

  return TeamHeatmapFilteredAthleteStats(
    visibleSessionCount: sessionCells.length,
    validSessionCount: validCells.length,
    latestValidSlope: validSlopeValues.isEmpty ? null : validSlopeValues.last,
    medianValidSlope: _median(validSlopeValues),
    fallbackCount: sessionCells
        .where((cell) => cell.hasFallbackExercise)
        .length,
  );
}

String? _classificationOptionIdFor(String? classification) {
  for (final option in teamHeatmapClassificationOptions) {
    if (option.matches(classification)) return option.id;
  }
  return null;
}

double? _median(List<double> values) {
  if (values.isEmpty) return null;
  final sorted = [...values]..sort();
  final mid = sorted.length ~/ 2;
  if (sorted.length.isOdd) return sorted[mid];
  return (sorted[mid - 1] + sorted[mid]) / 2;
}

String _normalizeClassification(String value) {
  return value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
}
