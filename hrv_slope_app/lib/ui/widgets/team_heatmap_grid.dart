library;

import 'package:flutter/material.dart';
import 'package:hrv_slope_app/shared/engine/recovery_response_labels.dart';
import 'package:hrv_slope_app/shared/engine/team_heatmap_builder.dart';
import 'package:hrv_slope_app/ui/theme/app_theme.dart';

class TeamHeatmapCellSelection {
  final TeamHeatmapRow row;
  final TeamHeatmapEvent event;
  final TeamHeatmapCell cell;

  const TeamHeatmapCellSelection({
    required this.row,
    required this.event,
    required this.cell,
  });
}

class TeamHeatmapGrid extends StatefulWidget {
  final TeamHeatmapData data;
  final List<TeamHeatmapRow> rows;
  final ValueChanged<TeamHeatmapCellSelection> onCellSelected;

  const TeamHeatmapGrid({
    super.key,
    required this.data,
    required this.rows,
    required this.onCellSelected,
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
    if (widget.data.events.isEmpty || widget.rows.isEmpty) {
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
                  '${widget.rows.length} athletes x '
                  '${widget.data.events.length} events',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Scrollbar(
                controller: _horizontalController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  key: const Key('team_heatmap_horizontal_scroll'),
                  controller: _horizontalController,
                  scrollDirection: Axis.horizontal,
                  child: Scrollbar(
                    controller: _verticalController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      key: const Key('team_heatmap_vertical_scroll'),
                      controller: _verticalController,
                      child: Table(
                        defaultColumnWidth: const FixedColumnWidth(88),
                        columnWidths: const {0: FixedColumnWidth(220)},
                        border: TableBorder.all(
                          color: AppColors.cardBorder,
                          width: 0.5,
                        ),
                        children: [
                          TableRow(
                            children: [
                              const _CornerHeader(),
                              for (final event in widget.data.events)
                                _EventHeaderCell(event: event),
                            ],
                          ),
                          for (final row in widget.rows)
                            TableRow(
                              children: [
                                _AthleteHeaderCell(row: row),
                                for (
                                  var index = 0;
                                  index < widget.data.events.length;
                                  index++
                                )
                                  _HeatmapCellWidget(
                                    row: row,
                                    event: widget.data.events[index],
                                    cell: row.cells[index],
                                    onSelected: widget.onCellSelected,
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Color represents the interpretation stored for each session '
              'according to its active reference.',
              style: TextStyle(color: AppColors.textHint, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: const [
                _LegendSwatch(
                  color: AppColors.classVeryHigh,
                  label: 'Very high',
                ),
                _LegendSwatch(
                  color: AppColors.classHighMod,
                  label: 'High/moderate',
                ),
                _LegendSwatch(
                  color: AppColors.classExpected,
                  label: 'Expected',
                ),
                _LegendSwatch(
                  color: AppColors.classLowFast,
                  label: 'Favorable',
                ),
                _LegendToken(label: 'F', description: 'Fallback 4 ms'),
                _LegendToken(label: '!', description: 'Incomplete'),
                _LegendToken(label: '-', description: 'Missing'),
                _LegendToken(label: '2x', description: 'Duplicate'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CornerHeader extends StatelessWidget {
  const _CornerHeader();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 58,
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text('Athlete', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

class _EventHeaderCell extends StatelessWidget {
  final TeamHeatmapEvent event;

  const _EventHeaderCell({required this.event});

  @override
  Widget build(BuildContext context) {
    final raw = event.event;
    return Tooltip(
      message: [
        _formatDate(raw.date),
        if (raw.taskName != null) 'Task: ${raw.taskName}',
        if (raw.protocolName != null) 'Protocol: ${raw.protocolName}',
      ].join('\n'),
      child: Container(
        key: Key('team_heatmap_event_header_${event.id}'),
        height: 58,
        padding: const EdgeInsets.all(6),
        color: AppColors.surfaceContainerHigh,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _formatShortDate(raw.date),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 3),
            Text(
              _blankToDash(raw.taskName),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: AppColors.textHint),
            ),
          ],
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
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      alignment: Alignment.centerLeft,
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
  final TeamHeatmapRow row;
  final TeamHeatmapEvent event;
  final TeamHeatmapCell cell;
  final ValueChanged<TeamHeatmapCellSelection> onSelected;

  const _HeatmapCellWidget({
    required this.row,
    required this.event,
    required this.cell,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final canSelect =
        cell.state == TeamHeatmapCellState.valid ||
        cell.state == TeamHeatmapCellState.incomplete;
    final content = Stack(
      children: [
        Container(
          height: 46,
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
      ],
    );

    return Tooltip(
      message: _cellTooltip(row: row, event: event, cell: cell),
      child: Semantics(
        label: _cellTooltip(row: row, event: event, cell: cell),
        button: canSelect,
        child: InkWell(
          key: Key('team_heatmap_cell_${cell.athleteId}_${cell.eventId}'),
          onTap: canSelect
              ? () => onSelected(
                  TeamHeatmapCellSelection(row: row, event: event, cell: cell),
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
}) {
  final base = [
    row.athlete.name,
    _formatDate(event.event.date),
    if (event.event.taskName != null) event.event.taskName!,
  ].join(' - ');

  switch (cell.state) {
    case TeamHeatmapCellState.missing:
      return '$base\nNo participation';
    case TeamHeatmapCellState.duplicate:
      return '$base\nDuplicate sessions: ${cell.duplicateSessionIds.join(', ')}';
    case TeamHeatmapCellState.incomplete:
    case TeamHeatmapCellState.valid:
      return [
        base,
        'RMSSD-Slope: ${_formatNumber(cell.slope, digits: 3)}',
        'Classification: '
            '${recoveryResponseShortLabelForClassificationKey(cell.classification)}',
        if (cell.hasFallbackExercise) 'RMSSD exercise: fallback 4 ms',
        if (cell.statusLabels.isNotEmpty)
          'Status: ${cell.statusLabels.join(', ')}',
      ].join('\n');
  }
}

Color _classificationColor(String? value) {
  switch (value) {
    case 'very_high_internal_load':
    case 'veryHighInternalLoad':
    case 'Lower-than-expected recovery response':
    case 'Lower-than-expected':
      return AppColors.classVeryHigh;
    case 'high_or_moderate_internal_load':
    case 'highOrModerateInternalLoad':
      return AppColors.classHighMod;
    case 'expected_response':
    case 'expectedResponse':
    case 'Expected recovery response':
    case 'Expected':
      return AppColors.classExpected;
    case 'low_internal_load_or_fast_recovery':
    case 'lowInternalLoadOrFastRecovery':
    case 'Favorable recovery response':
    case 'Favorable':
      return AppColors.classLowFast;
    default:
      return AppColors.tertiary;
  }
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
  final time =
      '${parsed.hour.toString().padLeft(2, '0')}:'
      '${parsed.minute.toString().padLeft(2, '0')}';
  return '$date $time';
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
