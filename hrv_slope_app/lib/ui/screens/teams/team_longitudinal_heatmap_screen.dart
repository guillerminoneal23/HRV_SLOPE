library;

import 'package:flutter/material.dart';
import 'package:hrv_slope_app/data/database/app_database.dart';
import 'package:hrv_slope_app/shared/engine/recovery_response_labels.dart';
import 'package:hrv_slope_app/shared/engine/team_heatmap_builder.dart';
import 'package:hrv_slope_app/ui/screens/session/session_detail_screen.dart';
import 'package:hrv_slope_app/ui/theme/app_theme.dart';
import 'package:hrv_slope_app/ui/widgets/team_heatmap_grid.dart';

class TeamLongitudinalHeatmapScreen extends StatefulWidget {
  final AppDatabase database;
  final int teamId;

  const TeamLongitudinalHeatmapScreen({
    super.key,
    required this.database,
    required this.teamId,
  });

  @override
  State<TeamLongitudinalHeatmapScreen> createState() =>
      _TeamLongitudinalHeatmapScreenState();
}

class _TeamLongitudinalHeatmapScreenState
    extends State<TeamLongitudinalHeatmapScreen> {
  final TextEditingController _dateFromCtrl = TextEditingController();
  final TextEditingController _dateToCtrl = TextEditingController();
  final TextEditingController _searchCtrl = TextEditingController();

  TeamHeatmapData? _data;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _dateFromCtrl.dispose();
    _dateToCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final dateFrom = _dateBoundary(_dateFromCtrl.text, endOfDay: false);
      final dateTo = _dateBoundary(_dateToCtrl.text, endOfDay: true);
      if (_hasInvalidDate(_dateFromCtrl.text) ||
          _hasInvalidDate(_dateToCtrl.text)) {
        throw const FormatException('Use YYYY-MM-DD for date filters.');
      }

      final bundle = await widget.database.sessionEventsDao
          .getTeamLongitudinalBundle(
            teamId: widget.teamId,
            dateFrom: dateFrom,
            dateTo: dateTo,
          );
      if (!mounted) return;
      if (bundle.team == null) {
        setState(() {
          _data = null;
          _error = 'Team not found';
          _loading = false;
        });
        return;
      }
      setState(() {
        _data = buildTeamHeatmap(bundle);
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _data = null;
        _error = error.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _data?.team?.name ?? 'Team Longitudinal';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _data == null
          ? Center(child: Text(_error ?? 'Team not found'))
          : _buildContent(_data!),
    );
  }

  Widget _buildContent(TeamHeatmapData data) {
    final rows = _filteredRows(data);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(data: data, periodLabel: _periodLabel(data)),
          const SizedBox(height: 10),
          _Filters(
            dateFromCtrl: _dateFromCtrl,
            dateToCtrl: _dateToCtrl,
            searchCtrl: _searchCtrl,
            onApply: _load,
          ),
          const SizedBox(height: 10),
          const TeamHeatmapLegend(),
          const SizedBox(height: 10),
          Expanded(
            child: TeamHeatmapGrid(
              data: data,
              rows: rows,
              onCellSelected: _showCellDetail,
            ),
          ),
        ],
      ),
    );
  }

  List<TeamHeatmapRow> _filteredRows(TeamHeatmapData data) {
    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isEmpty) return data.rows;
    return data.rows
        .where((row) => row.athlete.name.toLowerCase().contains(query))
        .toList();
  }

  void _showCellDetail(TeamHeatmapCellSelection selection) {
    showDialog<void>(
      context: context,
      builder: (_) =>
          _CellDetailDialog(selection: selection, onOpenSession: _openSession),
    );
  }

  void _openSession(int sessionId) {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SessionDetailScreen(
          database: widget.database,
          sessionId: sessionId,
        ),
      ),
    );
  }

  String _periodLabel(TeamHeatmapData data) {
    final explicitFrom = _dateFromCtrl.text.trim();
    final explicitTo = _dateToCtrl.text.trim();
    if (explicitFrom.isNotEmpty || explicitTo.isNotEmpty) {
      return [
        explicitFrom.isEmpty ? 'start' : explicitFrom,
        explicitTo.isEmpty ? 'today' : explicitTo,
      ].join(' to ');
    }
    if (data.events.isEmpty) return '-';
    return '${_formatDateOnly(data.events.first.date)} to '
        '${_formatDateOnly(data.events.last.date)}';
  }
}

class _Header extends StatelessWidget {
  final TeamHeatmapData data;
  final String periodLabel;

  const _Header({required this.data, required this.periodLabel});

  @override
  Widget build(BuildContext context) {
    final team = data.team!;
    final summary = data.summary;
    return Card(
      key: const Key('team_heatmap_header'),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              child: const Icon(Icons.grid_view, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          team.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      if (team.isArchived) ...[
                        const SizedBox(width: 8),
                        const _SmallChip(
                          label: 'Archived team',
                          color: AppColors.warning,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Period: $periodLabel',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _HeaderMetric(label: 'Events', value: '${summary.eventCount}'),
                _HeaderMetric(
                  label: 'Athletes',
                  value: '${summary.athleteCount}',
                ),
                _HeaderMetric(
                  label: 'Fallback',
                  value: '${summary.fallbackCellCount}',
                ),
                if (summary.duplicateCellCount > 0)
                  _HeaderMetric(
                    label: 'Duplicates',
                    value: '${summary.duplicateCellCount}',
                    color: AppColors.error,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  final TextEditingController dateFromCtrl;
  final TextEditingController dateToCtrl;
  final TextEditingController searchCtrl;
  final VoidCallback onApply;

  const _Filters({
    required this.dateFromCtrl,
    required this.dateToCtrl,
    required this.searchCtrl,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('team_heatmap_filters'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 160,
              child: TextField(
                key: const Key('team_heatmap_date_from'),
                controller: dateFromCtrl,
                decoration: const InputDecoration(
                  labelText: 'From',
                  hintText: 'YYYY-MM-DD',
                  prefixIcon: Icon(Icons.date_range),
                ),
                onSubmitted: (_) => onApply(),
              ),
            ),
            SizedBox(
              width: 160,
              child: TextField(
                key: const Key('team_heatmap_date_to'),
                controller: dateToCtrl,
                decoration: const InputDecoration(
                  labelText: 'To',
                  hintText: 'YYYY-MM-DD',
                  prefixIcon: Icon(Icons.event),
                ),
                onSubmitted: (_) => onApply(),
              ),
            ),
            FilledButton.icon(
              key: const Key('team_heatmap_apply_filters'),
              onPressed: onApply,
              icon: const Icon(Icons.filter_alt),
              label: const Text('Apply'),
            ),
            SizedBox(
              width: 260,
              child: TextField(
                key: const Key('team_heatmap_search'),
                controller: searchCtrl,
                decoration: const InputDecoration(
                  labelText: 'Search athlete',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CellDetailDialog extends StatelessWidget {
  final TeamHeatmapCellSelection selection;
  final ValueChanged<int> onOpenSession;

  const _CellDetailDialog({
    required this.selection,
    required this.onOpenSession,
  });

  @override
  Widget build(BuildContext context) {
    final row = selection.row;
    final event = selection.event.event;
    final cell = selection.cell;
    return AlertDialog(
      key: const Key('team_heatmap_cell_dialog'),
      title: Text(row.athlete.name),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailLine(label: 'Event', value: _formatDate(event.date)),
              _DetailLine(label: 'Task', value: _blankToDash(event.taskName)),
              _DetailLine(
                label: 'Protocol',
                value: _blankToDash(event.protocolName),
              ),
              const Divider(height: 20),
              _DetailLine(
                label: 'RMSSD-Slope',
                value: _formatNumber(cell.slope, digits: 3),
              ),
              _DetailLine(
                label: 'Classification',
                value: recoveryResponseShortLabelForClassificationKey(
                  cell.classification,
                ),
              ),
              _DetailLine(
                label: 'RMSSD exercise',
                value: _formatRmssdExercise(cell),
              ),
              _DetailLine(
                label: 'RMSSD recovery',
                value: _formatMs(cell.rmssdRecovery),
              ),
              _DetailLine(label: 'Load', value: _formatLoad(cell, event)),
              const Divider(height: 20),
              _DetailLine(
                label: 'Visible sessions',
                value: row.visibleSessionCount.toString(),
              ),
              _DetailLine(
                label: 'Latest slope',
                value: _formatNumber(row.lastSlope, digits: 3),
              ),
              _DetailLine(
                label: 'Median in period',
                value: _formatNumber(row.medianSlope, digits: 3),
              ),
              _DetailLine(
                label: 'Fallback count',
                value: row.fallbackCount.toString(),
              ),
              if (cell.statusLabels.isNotEmpty) ...[
                const Divider(height: 20),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final label in cell.statusLabels)
                      _SmallChip(
                        label: label,
                        color: label == 'Incomplete' || label == 'Unit mismatch'
                            ? AppColors.warning
                            : AppColors.tertiary,
                      ),
                  ],
                ),
              ],
              if (cell.warnings.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  cell.warnings.join('\n'),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        FilledButton.icon(
          key: const Key('team_heatmap_open_session'),
          onPressed: cell.sessionId == null
              ? null
              : () => onOpenSession(cell.sessionId!),
          icon: const Icon(Icons.open_in_new),
          label: const Text('Open individual session'),
        ),
      ],
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _HeaderMetric({
    required this.label,
    required this.value,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  final String label;
  final String value;

  const _DetailLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallChip extends StatelessWidget {
  final String label;
  final Color color;

  const _SmallChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

String? _dateBoundary(String raw, {required bool endOfDay}) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  final parsed = DateTime.tryParse(trimmed);
  if (parsed == null) return null;
  final bounded = endOfDay
      ? DateTime(parsed.year, parsed.month, parsed.day, 23, 59, 59, 999)
      : DateTime(parsed.year, parsed.month, parsed.day);
  return bounded.toIso8601String();
}

bool _hasInvalidDate(String raw) {
  final trimmed = raw.trim();
  return trimmed.isNotEmpty && DateTime.tryParse(trimmed) == null;
}

String _formatDateOnly(String raw) {
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw;
  return '${parsed.year.toString().padLeft(4, '0')}-'
      '${parsed.month.toString().padLeft(2, '0')}-'
      '${parsed.day.toString().padLeft(2, '0')}';
}

String _formatDate(String raw) {
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw;
  final date = _formatDateOnly(raw);
  final time =
      '${parsed.hour.toString().padLeft(2, '0')}:'
      '${parsed.minute.toString().padLeft(2, '0')}';
  return '$date $time';
}

String _formatNumber(double? value, {int digits = 1}) {
  if (value == null || !value.isFinite) return '-';
  return value.toStringAsFixed(digits);
}

String _formatMs(double? value) {
  if (value == null || !value.isFinite) return '-';
  return '${_formatNumber(value)} ms';
}

String _formatRmssdExercise(TeamHeatmapCell cell) {
  final base = _formatMs(cell.rmssdExercise);
  if (cell.hasFallbackExercise) return '$base (fallback 4 ms)';
  return base;
}

String _formatLoad(TeamHeatmapCell cell, SessionEvent event) {
  final value = cell.loadValue;
  if (value == null || !value.isFinite) return '-';
  final unit = cell.loadUnit ?? event.loadUnit;
  final parts = [
    _formatNumber(value, digits: 1),
    if (unit != null && unit.trim().isNotEmpty) unit,
    if (cell.loadUnitMismatch) '(unit mismatch)',
  ];
  return parts.join(' ');
}

String _blankToDash(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return '-';
  return trimmed;
}
