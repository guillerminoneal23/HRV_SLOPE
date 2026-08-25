library;

import 'package:flutter/material.dart';
import 'package:hrv_slope_app/data/database/app_database.dart';
import 'package:hrv_slope_app/shared/engine/recovery_response_labels.dart';
import 'package:hrv_slope_app/shared/engine/team_heatmap_builder.dart';
import 'package:hrv_slope_app/shared/engine/team_heatmap_filter.dart';
import 'package:hrv_slope_app/ui/theme/app_theme.dart';

const double _athleteColumnWidth = 220;
const double _cellWidth = 88;
const double _headerHeight = 68;
const double _rowHeight = 46;

class TeamHeatmapCellSelection {
  final TeamHeatmapFilteredRow row;
  final TeamHeatmapEvent event;
  final TeamHeatmapFilteredCell filteredCell;

  const TeamHeatmapCellSelection({
    required this.row,
    required this.event,
    required this.filteredCell,
  });

  TeamHeatmapCell get cell => filteredCell.cell;
}

class TeamHeatmapGrid extends StatefulWidget {
  final TeamHeatmapData data;
  final TeamHeatmapFilteredView view;
  final ValueChanged<TeamHeatmapCellSelection> onCellSelected;
  final ValueChanged<TeamHeatmapEvent> onEventSelected;

  const TeamHeatmapGrid({
    super.key,
    required this.data,
    required this.view,
    required this.onCellSelected,
    required this.onEventSelected,
  });

  @override
  State<TeamHeatmapGrid> createState() => _TeamHeatmapGridState();
}

class _TeamHeatmapGridState extends State<TeamHeatmapGrid> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.events.isEmpty || widget.data.rows.isEmpty) {
      return const Card(
        key: Key('team_heatmap_empty'),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No team session events with participants in this period.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    if (widget.view.rows.isEmpty) {
      return const Card(
        key: Key('team_heatmap_filtered_empty'),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No athletes match current filters.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Card(
      key: const Key('team_heatmap_grid'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'RMSSD-Slope heatmap',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  '${widget.view.rows.length} athletes x '
                  '${widget.view.events.length} events',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final contentHeight =
                      _headerHeight + widget.view.rows.length * _rowHeight;
                  final matrixViewportWidth =
                      constraints.maxWidth > _athleteColumnWidth
                      ? constraints.maxWidth - _athleteColumnWidth
                      : 0.0;

                  return Scrollbar(
                    controller: _verticalController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      key: const Key('team_heatmap_vertical_scroll'),
                      controller: _verticalController,
                      child: SizedBox(
                        height: contentHeight,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              key: const Key(
                                'team_heatmap_fixed_athlete_column',
                              ),
                              width: _athleteColumnWidth,
                              height: contentHeight,
                              child: Column(
                                children: [
                                  const _CornerHeader(),
                                  for (final row in widget.view.rows)
                                    _AthleteHeaderCell(row: row.row),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: matrixViewportWidth,
                              height: contentHeight,
                              child: Scrollbar(
                                controller: _horizontalController,
                                thumbVisibility: true,
                                child: SingleChildScrollView(
                                  key: const Key(
                                    'team_heatmap_horizontal_scroll',
                                  ),
                                  controller: _horizontalController,
                                  scrollDirection: Axis.horizontal,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          for (final event
                                              in widget.view.events)
                                            _EventHeaderCell(
                                              event: event,
                                              onOpen: () =>
                                                  widget.onEventSelected(event),
                                            ),
                                        ],
                                      ),
                                      for (final row in widget.view.rows)
                                        Row(
                                          children: [
                                            for (
                                              var index = 0;
                                              index < widget.view.events.length;
                                              index++
                                            )
                                              _HeatmapCellWidget(
                                                row: row,
                                                event:
                                                    widget.view.events[index],
                                                filteredCell: row.cells[index],
                                                filtersActive:
                                                    widget.view.hasCellFilters,
                                                onSelected:
                                                    widget.onCellSelected,
                                              ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TeamHeatmapLegend extends StatelessWidget {
  const TeamHeatmapLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('team_heatmap_legend'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const [
              SizedBox(
                width: 360,
                child: Text(
                  'Color represents the interpretation stored for each '
                  'session according to its active reference.',
                  style: TextStyle(color: AppColors.textHint, fontSize: 12),
                ),
              ),
              SizedBox(width: 12),
              _LegendSwatch(
                color: AppColors.classVeryHigh,
                label: 'Lower-than-expected',
              ),
              SizedBox(width: 10),
              _LegendSwatch(color: AppColors.classExpected, label: 'Expected'),
              SizedBox(width: 10),
              _LegendSwatch(color: AppColors.classLowFast, label: 'Favorable'),
              SizedBox(width: 10),
              _LegendToken(label: 'F', description: 'Fallback 4 ms'),
              SizedBox(width: 10),
              _LegendToken(label: '!', description: 'Incomplete'),
              SizedBox(width: 10),
              _LegendToken(label: '-', description: 'No participation'),
              SizedBox(width: 10),
              _LegendToken(label: '2x', description: 'Duplicate'),
            ],
          ),
        ),
      ),
    );
  }
}

class _CornerHeader extends StatelessWidget {
  const _CornerHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _headerHeight,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        border: Border.all(color: AppColors.cardBorder, width: 0.5),
      ),
      padding: const EdgeInsets.all(8),
      alignment: Alignment.centerLeft,
      child: const Text(
        'Athlete',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _EventHeaderCell extends StatelessWidget {
  final TeamHeatmapEvent event;
  final VoidCallback onOpen;

  const _EventHeaderCell({required this.event, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final raw = event.event;
    final dateLabel = _formatShortDate(raw.date);
    final timeLabel = _formatTimeIfExplicit(raw.date);
    final fullDateLabel = _formatDate(raw.date);
    return Tooltip(
      message: [
        fullDateLabel,
        if (raw.taskName != null) 'Task: ${raw.taskName}',
        if (raw.protocolName != null) 'Protocol: ${raw.protocolName}',
        'Load: ${_loadDefinition(raw)}',
        'Open SessionEvent',
      ].join('\n'),
      child: Semantics(
        button: true,
        label:
            'Open SessionEvent ${_blankToDash(raw.taskName)}, $fullDateLabel',
        child: InkWell(
          key: Key('team_heatmap_event_header_${event.id}'),
          onTap: onOpen,
          child: Container(
            width: _cellWidth,
            height: _headerHeight,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              border: Border.all(color: AppColors.cardBorder, width: 0.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  dateLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (timeLabel != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    timeLabel,
                    key: Key('team_heatmap_event_time_${event.id}'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  _blankToDash(raw.taskName),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AthleteHeaderCell extends StatelessWidget {
  final TeamHeatmapRow row;

  const _AthleteHeaderCell({required this.row});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key('team_heatmap_row_${row.athlete.id}'),
      width: _athleteColumnWidth,
      height: _rowHeight,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        border: Border.all(color: AppColors.cardBorder, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              row.athlete.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
          if (row.athlete.isArchived)
            const Padding(
              padding: EdgeInsets.only(left: 6),
              child: _TinyBadge(label: 'arch', color: AppColors.warning),
            ),
        ],
      ),
    );
  }
}

class _HeatmapCellWidget extends StatelessWidget {
  final TeamHeatmapFilteredRow row;
  final TeamHeatmapEvent event;
  final TeamHeatmapFilteredCell filteredCell;
  final bool filtersActive;
  final ValueChanged<TeamHeatmapCellSelection> onSelected;

  const _HeatmapCellWidget({
    required this.row,
    required this.event,
    required this.filteredCell,
    required this.filtersActive,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final cell = filteredCell.cell;
    final filteredOut = filtersActive && !filteredCell.matches;
    final canSelect =
        !filteredOut &&
        (cell.state == TeamHeatmapCellState.valid ||
            cell.state == TeamHeatmapCellState.incomplete);
    final content = Opacity(
      opacity: filteredOut ? 0.24 : 1,
      child: Stack(
        children: [
          Container(
            width: _cellWidth,
            height: _rowHeight,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _cellBackground(cell),
              border: Border.all(color: _cellBorder(cell), width: 1),
            ),
            child: Text(
              _cellLabel(cell),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _cellTextColor(cell),
              ),
            ),
          ),
          if (cell.hasFallbackExercise)
            Positioned(
              right: 3,
              top: 3,
              child: Tooltip(
                message: 'Exercise RMSSD used default 4 ms fallback',
                child: Container(
                  key: Key(
                    'team_heatmap_fallback_${cell.athleteId}_${cell.eventId}',
                  ),
                  width: 14,
                  height: 14,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.tertiary,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Text(
                    'F',
                    style: TextStyle(
                      color: AppColors.surfaceDark,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    return Tooltip(
      message: _cellTooltip(
        row: row.row,
        event: event,
        cell: cell,
        filteredOut: filteredOut,
      ),
      child: Semantics(
        label: _cellTooltip(
          row: row.row,
          event: event,
          cell: cell,
          filteredOut: filteredOut,
        ),
        button: canSelect,
        child: InkWell(
          key: Key('team_heatmap_cell_${cell.athleteId}_${cell.eventId}'),
          onTap: canSelect
              ? () => onSelected(
                  TeamHeatmapCellSelection(
                    row: row,
                    event: event,
                    filteredCell: filteredCell,
                  ),
                )
              : null,
          child: content,
        ),
      ),
    );
  }
}

class _LegendSwatch extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendSwatch({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _LegendToken extends StatelessWidget {
  final String label;
  final String description;

  const _LegendToken({required this.label, required this.description});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _TinyBadge(label: label, color: AppColors.tertiary),
        const SizedBox(width: 6),
        Text(description, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _TinyBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _TinyBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

Color _cellBackground(TeamHeatmapCell cell) {
  switch (cell.state) {
    case TeamHeatmapCellState.valid:
      return _classificationColor(cell.classification).withValues(alpha: 0.28);
    case TeamHeatmapCellState.incomplete:
      return AppColors.warning.withValues(alpha: 0.14);
    case TeamHeatmapCellState.missing:
      return AppColors.surfaceContainerHigh.withValues(alpha: 0.35);
    case TeamHeatmapCellState.duplicate:
      return AppColors.error.withValues(alpha: 0.16);
  }
}

Color _cellBorder(TeamHeatmapCell cell) {
  switch (cell.state) {
    case TeamHeatmapCellState.valid:
      return _classificationColor(cell.classification).withValues(alpha: 0.62);
    case TeamHeatmapCellState.incomplete:
      return AppColors.warning.withValues(alpha: 0.75);
    case TeamHeatmapCellState.missing:
      return AppColors.cardBorder;
    case TeamHeatmapCellState.duplicate:
      return AppColors.error.withValues(alpha: 0.8);
  }
}

Color _cellTextColor(TeamHeatmapCell cell) {
  if (cell.state == TeamHeatmapCellState.missing) return AppColors.textHint;
  if (cell.state == TeamHeatmapCellState.duplicate) return AppColors.error;
  if (cell.state == TeamHeatmapCellState.incomplete) return AppColors.warning;
  return AppColors.textPrimary;
}

String _cellLabel(TeamHeatmapCell cell) {
  switch (cell.state) {
    case TeamHeatmapCellState.valid:
      return _formatNumber(cell.slope, digits: 2);
    case TeamHeatmapCellState.incomplete:
      return '!';
    case TeamHeatmapCellState.missing:
      return '-';
    case TeamHeatmapCellState.duplicate:
      return '${cell.duplicateSessionIds.length}x';
  }
}

String _cellTooltip({
  required TeamHeatmapRow row,
  required TeamHeatmapEvent event,
  required TeamHeatmapCell cell,
  required bool filteredOut,
}) {
  final base = [
    row.athlete.name,
    _formatDate(event.event.date),
    if (event.event.taskName != null) event.event.taskName!,
  ].join(' - ');

  final filteredLabel = filteredOut ? ['Filtered out by current filters'] : [];
  switch (cell.state) {
    case TeamHeatmapCellState.missing:
      return [...filteredLabel, base, 'No participation'].join('\n');
    case TeamHeatmapCellState.duplicate:
      return [
        ...filteredLabel,
        base,
        'Duplicate sessions detected',
        'Session IDs: ${cell.duplicateSessionIds.join(', ')}',
      ].join('\n');
    case TeamHeatmapCellState.incomplete:
    case TeamHeatmapCellState.valid:
      return [
        ...filteredLabel,
        base,
        'RMSSD-Slope: ${_formatNumber(cell.slope, digits: 3)}',
        'Classification: '
            '${cell.state == TeamHeatmapCellState.valid ? recoveryResponseShortLabelForClassificationKey(cell.classification) : '-'}',
        if (cell.hasFallbackExercise)
          'Exercise RMSSD used default 4 ms fallback',
        if (cell.statusLabels.isNotEmpty)
          'Status: ${cell.statusLabels.join(', ')}',
      ].join('\n');
  }
}

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

String _loadDefinition(SessionEvent event) {
  return [
    event.loadType,
    event.loadMetricName,
    if (_hasText(event.loadUnit)) event.loadUnit,
  ].join(' ');
}

String _formatShortDate(String raw) {
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw;
  return '${parsed.month.toString().padLeft(2, '0')}/'
      '${parsed.day.toString().padLeft(2, '0')}';
}

String _formatDate(String raw) {
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw;
  final date =
      '${parsed.year.toString().padLeft(4, '0')}-'
      '${parsed.month.toString().padLeft(2, '0')}-'
      '${parsed.day.toString().padLeft(2, '0')}';
  final time = _formatTimeIfExplicit(raw);
  return time == null ? date : '$date $time';
}

String _formatNumber(double? value, {int digits = 1}) {
  if (value == null || !value.isFinite) return '-';
  return value.toStringAsFixed(digits);
}

String _blankToDash(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return '-';
  return trimmed;
}

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

String? _formatTimeIfExplicit(String raw) {
  if (!_hasExplicitTime(raw)) return null;
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return null;
  return '${parsed.hour.toString().padLeft(2, '0')}:'
      '${parsed.minute.toString().padLeft(2, '0')}';
}

bool _hasExplicitTime(String raw) {
  final trimmed = raw.trim();
  return RegExp(r'(?:T|\s)\d{2}:\d{2}').hasMatch(trimmed);
}
