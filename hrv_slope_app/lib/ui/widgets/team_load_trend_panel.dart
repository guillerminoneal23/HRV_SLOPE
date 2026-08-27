library;

import 'package:flutter/material.dart';
import 'package:hrv_slope_app/shared/engine/recovery_response_labels.dart';
import 'package:hrv_slope_app/shared/engine/team_heatmap_builder.dart';
import 'package:hrv_slope_app/shared/engine/team_heatmap_filter.dart';
import 'package:hrv_slope_app/shared/engine/team_load_trend_builder.dart';
import 'package:hrv_slope_app/ui/theme/app_theme.dart';
import 'package:hrv_slope_app/ui/utils/session_datetime_format.dart';
import 'package:hrv_slope_app/ui/widgets/longitudinal_chart.dart';

class TeamLoadTrendPanel extends StatelessWidget {
  final TeamHeatmapData data;
  final TeamHeatmapFilter filter;
  final List<TeamHeatmapRow> athleteRows;
  final List<TeamLoadDefinition> loadDefinitions;
  final String selectedLoadDefinitionId;
  final int? selectedAthleteId;
  final ValueChanged<String> onLoadDefinitionChanged;
  final ValueChanged<int?> onAthleteChanged;
  final ValueChanged<int> onOpenSession;

  const TeamLoadTrendPanel({
    super.key,
    required this.data,
    required this.filter,
    required this.athleteRows,
    required this.loadDefinitions,
    required this.selectedLoadDefinitionId,
    required this.selectedAthleteId,
    required this.onLoadDefinitionChanged,
    required this.onAthleteChanged,
    required this.onOpenSession,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveLoadId = _effectiveLoadId;
    final selectedDefinition = _definitionForId(effectiveLoadId);
    final effectiveAthleteId = _effectiveAthleteId;
    final trend = effectiveAthleteId == null
        ? null
        : buildTeamLoadTrend(
            data: data,
            athleteId: effectiveAthleteId,
            loadDefinition: selectedDefinition,
            filter: filter,
          );

    return SingleChildScrollView(
      key: const Key('team_load_panel_scroll'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            key: const Key('team_load_analysis_panel'),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.stacked_line_chart,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Load analysis',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Select one athlete and one load metric. Heatmap filters '
                    'shape the trend; load selection does not filter events.',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    key: const Key('team_load_athlete_selector'),
                    child: DropdownButtonFormField<int>(
                      key: ValueKey(
                        'team_load_athlete_selector_${effectiveAthleteId ?? 'none'}',
                      ),
                      initialValue: effectiveAthleteId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Athlete',
                        prefixIcon: Icon(Icons.person_search),
                      ),
                      hint: const Text('Select athlete'),
                      items: [
                        for (final row in athleteRows)
                          DropdownMenuItem<int>(
                            value: row.athlete.id,
                            child: Text(
                              row.athlete.isArchived
                                  ? '${row.athlete.name} (archived)'
                                  : row.athlete.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: athleteRows.isEmpty ? null : onAthleteChanged,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    key: const Key('team_load_metric_selector'),
                    child: DropdownButtonFormField<String>(
                      key: ValueKey(
                        'team_load_metric_selector_$effectiveLoadId',
                      ),
                      initialValue: effectiveLoadId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Load metric',
                        prefixIcon: Icon(Icons.speed),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: teamLoadSlopeOnlyId,
                          child: Text('Slope only'),
                        ),
                        for (final definition in loadDefinitions)
                          DropdownMenuItem<String>(
                            value: definition.id,
                            child: Text(
                              definition.label,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) onLoadDefinitionChanged(value);
                      },
                    ),
                  ),
                  if (loadDefinitions.isEmpty) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'No load metrics available in the applied period. '
                      'Slope analysis remains available.',
                      key: Key('team_load_no_metrics'),
                      style: TextStyle(color: AppColors.textHint, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (trend == null)
            const _TrendEmptyState()
          else ...[
            _TrendSummary(trend: trend),
            LongitudinalChart(
              key: const Key('team_load_slope_chart'),
              title: 'RMSSD-Slope trend',
              valueLabel: 'Slope',
              points: _slopePoints(trend),
              emptyMessage:
                  'Not enough valid slope values for this athlete '
                  'and filtered period.',
              onPointSelected: onOpenSession,
              xAxisLabel: 'Date',
            ),
            if (selectedDefinition != null)
              LongitudinalChart(
                key: const Key('team_load_metric_chart'),
                title: 'Load trend',
                valueLabel: selectedDefinition.valueLabel,
                points: _loadPoints(trend, selectedDefinition),
                emptyMessage:
                    'No matching load values for this athlete and '
                    'metric in the visible period.',
                onPointSelected: onOpenSession,
                xAxisLabel: 'Date',
                connectMissingPoints: false,
              ),
          ],
        ],
      ),
    );
  }

  String get _effectiveLoadId {
    if (selectedLoadDefinitionId == teamLoadSlopeOnlyId) {
      return teamLoadSlopeOnlyId;
    }
    for (final definition in loadDefinitions) {
      if (definition.id == selectedLoadDefinitionId) {
        return selectedLoadDefinitionId;
      }
    }
    return teamLoadSlopeOnlyId;
  }

  int? get _effectiveAthleteId {
    if (selectedAthleteId == null) return null;
    for (final row in athleteRows) {
      if (row.athlete.id == selectedAthleteId) return selectedAthleteId;
    }
    return null;
  }

  TeamLoadDefinition? _definitionForId(String id) {
    if (id == teamLoadSlopeOnlyId) return null;
    for (final definition in loadDefinitions) {
      if (definition.id == id) return definition;
    }
    return null;
  }
}

class _TrendEmptyState extends StatelessWidget {
  const _TrendEmptyState();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Icon(Icons.person_search, color: AppColors.textHint),
            SizedBox(height: 10),
            Text(
              'Select an athlete to inspect slope and load trends.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendSummary extends StatelessWidget {
  final TeamLoadTrend trend;

  const _TrendSummary({required this.trend});

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('team_load_trend_summary'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              trend.athlete.isArchived
                  ? '${trend.athlete.name} (archived)'
                  : trend.athlete.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatChip(
                  label: 'Visible sessions',
                  value: trend.visibleSessionCount.toString(),
                ),
                _StatChip(
                  label: 'Valid slopes',
                  value: trend.validSlopePointCount.toString(),
                ),
                _StatChip(
                  label: 'Latest slope',
                  value: _formatNumber(trend.latestValidSlope, digits: 3),
                ),
                _StatChip(
                  label: 'Median slope',
                  value: _formatNumber(trend.medianValidSlope, digits: 3),
                ),
                _StatChip(
                  label: 'Fallback',
                  value: trend.fallbackCount.toString(),
                ),
                if (trend.loadDefinition != null)
                  _StatChip(
                    label: 'Load points',
                    value: trend.loadPointCount.toString(),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Statistics use the loaded period and currently active '
              'heatmap cell filters.',
              style: TextStyle(color: AppColors.textHint, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 92),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

List<LongitudinalChartPoint> _slopePoints(TeamLoadTrend trend) {
  return [
    for (final point in trend.points)
      LongitudinalChartPoint(
        sessionId: point.sessionId,
        label: formatSessionDateForDisplay(point.event.date),
        value: point.slope,
        color: _classificationColor(point.classification),
        tooltip: _slopeTooltip(trend, point),
      ),
  ];
}

List<LongitudinalChartPoint> _loadPoints(
  TeamLoadTrend trend,
  TeamLoadDefinition definition,
) {
  return [
    for (final point in trend.points)
      LongitudinalChartPoint(
        sessionId: point.sessionId,
        label: formatSessionDateForDisplay(point.event.date),
        value: point.loadValue,
        color: AppColors.secondary,
        tooltip: _loadTooltip(trend, point, definition),
      ),
  ];
}

String _slopeTooltip(TeamLoadTrend trend, TeamLoadTrendPoint point) {
  final event = point.event.event;
  return [
    trend.athlete.name,
    formatSessionDateForDisplay(event.date),
    if (_hasText(event.taskName)) 'Task: ${event.taskName}',
    if (_hasText(event.protocolName)) 'Protocol: ${event.protocolName}',
    'RMSSD-Slope: ${_formatNumber(point.slope, digits: 3)}',
    'Classification: ${point.slope == null ? '-' : recoveryResponseShortLabelForClassificationKey(point.classification)}',
    if (point.hasFallbackExercise) 'Fallback 4 ms',
    if (!point.includedByFilter) 'Filtered out by current heatmap filters',
  ].join('\n');
}

String _loadTooltip(
  TeamLoadTrend trend,
  TeamLoadTrendPoint point,
  TeamLoadDefinition definition,
) {
  final event = point.event.event;
  return [
    trend.athlete.name,
    formatSessionDateForDisplay(event.date),
    if (_hasText(event.taskName)) 'Task: ${event.taskName}',
    'Load: ${_formatLoad(point.loadValue, definition)}',
    if (!point.includedByFilter) 'Filtered out by current heatmap filters',
  ].join('\n');
}

String _formatLoad(double? value, TeamLoadDefinition definition) {
  if (value == null || !value.isFinite) return '-';
  final unit = definition.unitLabel;
  return [_formatNumber(value, digits: 1), ?unit].join(' ');
}

String _formatNumber(double? value, {int digits = 1}) {
  if (value == null || !value.isFinite) return '-';
  return value.toStringAsFixed(digits);
}

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

Color _classificationColor(String? value) {
  switch (recoveryResponseZoneForClassificationKey(value)) {
    case RecoveryResponseZone.lowerThanExpected:
      return AppColors.classVeryHigh;
    case RecoveryResponseZone.expected:
      return AppColors.classExpected;
    case RecoveryResponseZone.favorable:
      return AppColors.classLowFast;
    case null:
      return AppColors.tertiary;
  }
}
