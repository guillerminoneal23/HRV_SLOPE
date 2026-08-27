library;

import 'package:flutter/material.dart';
import 'package:hrv_slope_app/data/database/app_database.dart';
import 'package:hrv_slope_app/shared/engine/recovery_response_labels.dart';
import 'package:hrv_slope_app/shared/engine/team_heatmap_builder.dart';
import 'package:hrv_slope_app/shared/engine/team_heatmap_filter.dart';
import 'package:hrv_slope_app/shared/engine/team_load_trend_builder.dart';
import 'package:hrv_slope_app/ui/screens/session/session_detail_screen.dart';
import 'package:hrv_slope_app/ui/screens/teams/session_event_detail_screen.dart';
import 'package:hrv_slope_app/ui/theme/app_theme.dart';
import 'package:hrv_slope_app/ui/utils/session_datetime_format.dart';
import 'package:hrv_slope_app/ui/widgets/team_heatmap_grid.dart';
import 'package:hrv_slope_app/ui/widgets/team_load_trend_panel.dart';

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

  Set<String> _classificationFilters = {};
  TeamHeatmapFallbackFilter _fallbackFilter = TeamHeatmapFallbackFilter.all;
  TeamHeatmapSessionStateFilter _stateFilter =
      TeamHeatmapSessionStateFilter.all;
  String? _appliedDateFrom;
  String? _appliedDateTo;
  String _selectedLoadDefinitionId = teamLoadSlopeOnlyId;
  int? _selectedTrendAthleteId;
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
    final draftDateFrom = _normalizedDateText(_dateFromCtrl.text);
    final draftDateTo = _normalizedDateText(_dateToCtrl.text);
    final dateError = _dateFilterError(draftDateFrom, draftDateTo);
    if (dateError != null) {
      if (!mounted) return;
      setState(() {
        _error = dateError;
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final dateFrom = _dateBoundary(draftDateFrom, endOfDay: false);
      final dateTo = _dateBoundary(draftDateTo, endOfDay: true);

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
      final nextData = buildTeamHeatmap(bundle);
      final availableLoadDefinitionIds = availableTeamLoadDefinitions(
        nextData,
      ).map((definition) => definition.id).toSet();
      final selectedAthleteStillExists =
          _selectedTrendAthleteId == null ||
          nextData.rows.any((row) => row.athlete.id == _selectedTrendAthleteId);

      setState(() {
        _data = nextData;
        _appliedDateFrom = draftDateFrom;
        _appliedDateTo = draftDateTo;
        if (_selectedLoadDefinitionId != teamLoadSlopeOnlyId &&
            !availableLoadDefinitionIds.contains(_selectedLoadDefinitionId)) {
          _selectedLoadDefinitionId = teamLoadSlopeOnlyId;
        }
        if (!selectedAthleteStillExists) {
          _selectedTrendAthleteId = null;
        }
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
    final filter = _currentFilter();
    final filteredView = filterTeamHeatmap(data, filter);
    final activeFilterCount = _activeFilterCount(filter);
    final loadDefinitions = availableTeamLoadDefinitions(data);
    final trendAthleteRows = [for (final row in filteredView.rows) row.row];
    final header = _Header(
      data: data,
      filteredView: filteredView,
      periodLabel: _periodLabel(data),
    );
    final filters = _Filters(
      dateFromCtrl: _dateFromCtrl,
      dateToCtrl: _dateToCtrl,
      searchCtrl: _searchCtrl,
      classificationOptions: teamHeatmapClassificationOptions,
      selectedClassifications: _classificationFilters,
      fallbackFilter: _fallbackFilter,
      stateFilter: _stateFilter,
      activeFilterCount: activeFilterCount,
      onApply: _load,
      onClassificationChanged: _setClassificationFilter,
      onFallbackChanged: (value) => setState(() => _fallbackFilter = value),
      onStateChanged: (value) => setState(() => _stateFilter = value),
      onReset: _resetFilters,
    );
    final grid = TeamHeatmapGrid(
      data: data,
      view: filteredView,
      onCellSelected: _showCellDetail,
      onEventSelected: _openEvent,
    );
    final trendPanel = TeamLoadTrendPanel(
      data: data,
      filter: filter,
      athleteRows: trendAthleteRows,
      loadDefinitions: loadDefinitions,
      selectedLoadDefinitionId: _selectedLoadDefinitionId,
      selectedAthleteId: _selectedTrendAthleteId,
      onLoadDefinitionChanged: (value) =>
          setState(() => _selectedLoadDefinitionId = value),
      onAthleteChanged: (value) =>
          setState(() => _selectedTrendAthleteId = value),
      onOpenSession: _openSession,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 1100) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  header,
                  const SizedBox(height: 10),
                  if (_error != null) ...[
                    _InlineErrorBanner(message: _error!),
                    const SizedBox(height: 10),
                  ],
                  filters,
                  const SizedBox(height: 10),
                  const TeamHeatmapLegend(),
                  const SizedBox(height: 10),
                  SizedBox(height: 360, child: grid),
                  const SizedBox(height: 12),
                  SizedBox(height: 430, child: trendPanel),
                ],
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              const SizedBox(height: 10),
              if (_error != null) ...[
                _InlineErrorBanner(message: _error!),
                const SizedBox(height: 10),
              ],
              filters,
              const SizedBox(height: 10),
              const TeamHeatmapLegend(),
              const SizedBox(height: 10),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: grid),
                    const SizedBox(width: 12),
                    SizedBox(width: 390, child: trendPanel),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  TeamHeatmapFilter _currentFilter() {
    return TeamHeatmapFilter(
      athleteQuery: _searchCtrl.text,
      classificationOptionIds: _classificationFilters,
      fallbackFilter: _fallbackFilter,
      stateFilter: _stateFilter,
    );
  }

  int _activeFilterCount(TeamHeatmapFilter filter) {
    var count = filter.activeFilterCount;
    if (_appliedDateFrom != null) count++;
    if (_appliedDateTo != null) count++;
    return count;
  }

  void _setClassificationFilter(String id, bool selected) {
    final next = Set<String>.from(_classificationFilters);
    if (selected) {
      next.add(id);
    } else {
      next.remove(id);
    }
    setState(() => _classificationFilters = next);
  }

  void _resetFilters() {
    _dateFromCtrl.clear();
    _dateToCtrl.clear();
    _searchCtrl.clear();
    setState(() {
      _classificationFilters = {};
      _fallbackFilter = TeamHeatmapFallbackFilter.all;
      _stateFilter = TeamHeatmapSessionStateFilter.all;
    });
    _load();
  }

  void _showCellDetail(TeamHeatmapCellSelection selection) {
    showDialog<void>(
      context: context,
      builder: (_) => _CellDetailDialog(
        selection: selection,
        onOpenSession: _openSessionFromDialog,
      ),
    );
  }

  void _openSessionFromDialog(int sessionId) {
    Navigator.of(context).pop();
    _openSession(sessionId);
  }

  void _openSession(int sessionId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SessionDetailScreen(
          database: widget.database,
          sessionId: sessionId,
        ),
      ),
    );
  }

  void _openEvent(TeamHeatmapEvent event) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SessionEventDetailScreen(
          database: widget.database,
          eventId: event.id,
        ),
      ),
    );
  }

  String? _dateFilterError(String? dateFrom, String? dateTo) {
    if (_hasInvalidDate(dateFrom) || _hasInvalidDate(dateTo)) {
      return 'Use YYYY-MM-DD for date filters.';
    }
    return null;
  }

  String _periodLabel(TeamHeatmapData data) {
    final explicitFrom = _appliedDateFrom;
    final explicitTo = _appliedDateTo;
    if (explicitFrom != null || explicitTo != null) {
      return [explicitFrom ?? 'start', explicitTo ?? 'today'].join(' to ');
    }
    if (data.events.isEmpty) return '-';
    return '${_formatDateOnly(data.events.first.date)} to '
        '${_formatDateOnly(data.events.last.date)}';
  }
}

String? _normalizedDateText(String raw) {
  final trimmed = raw.trim();
  return trimmed.isEmpty ? null : trimmed;
}

class _InlineErrorBanner extends StatelessWidget {
  final String message;

  const _InlineErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('team_heatmap_inline_error'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final TeamHeatmapData data;
  final TeamHeatmapFilteredView filteredView;
  final String periodLabel;

  const _Header({
    required this.data,
    required this.filteredView,
    required this.periodLabel,
  });

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
                  value: filteredView.rows.length == summary.athleteCount
                      ? '${summary.athleteCount}'
                      : '${filteredView.rows.length}/${summary.athleteCount}',
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
  final List<TeamHeatmapClassificationOption> classificationOptions;
  final Set<String> selectedClassifications;
  final TeamHeatmapFallbackFilter fallbackFilter;
  final TeamHeatmapSessionStateFilter stateFilter;
  final int activeFilterCount;
  final VoidCallback onApply;
  final void Function(String id, bool selected) onClassificationChanged;
  final ValueChanged<TeamHeatmapFallbackFilter> onFallbackChanged;
  final ValueChanged<TeamHeatmapSessionStateFilter> onStateChanged;
  final VoidCallback onReset;

  const _Filters({
    required this.dateFromCtrl,
    required this.dateToCtrl,
    required this.searchCtrl,
    required this.classificationOptions,
    required this.selectedClassifications,
    required this.fallbackFilter,
    required this.stateFilter,
    required this.activeFilterCount,
    required this.onApply,
    required this.onClassificationChanged,
    required this.onFallbackChanged,
    required this.onStateChanged,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('team_heatmap_filters'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
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
                  const SizedBox(width: 12),
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
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    key: const Key('team_heatmap_apply_filters'),
                    onPressed: onApply,
                    icon: const Icon(Icons.filter_alt),
                    label: const Text('Apply'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    key: const Key('team_heatmap_reset_filters'),
                    onPressed: onReset,
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Reset filters'),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _activeFilterLabel(activeFilterCount),
                    key: const Key('team_heatmap_active_filter_count'),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: activeFilterCount == 0
                          ? AppColors.textSecondary
                          : AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
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
                  const SizedBox(width: 12),
                  SizedBox(
                    key: const Key('team_heatmap_fallback_filter'),
                    width: 188,
                    child: DropdownButtonFormField<TeamHeatmapFallbackFilter>(
                      key: ValueKey('fallback_${fallbackFilter.name}'),
                      initialValue: fallbackFilter,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Fallback',
                        prefixIcon: Icon(Icons.rule),
                      ),
                      items: [
                        for (final value in TeamHeatmapFallbackFilter.values)
                          DropdownMenuItem(
                            value: value,
                            child: Text(value.label),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) onFallbackChanged(value);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    key: const Key('team_heatmap_state_filter'),
                    width: 170,
                    child:
                        DropdownButtonFormField<TeamHeatmapSessionStateFilter>(
                          key: ValueKey('state_${stateFilter.name}'),
                          initialValue: stateFilter,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'State',
                            prefixIcon: Icon(Icons.check_circle_outline),
                          ),
                          items: [
                            for (final value
                                in TeamHeatmapSessionStateFilter.values)
                              DropdownMenuItem(
                                value: value,
                                child: Text(value.label),
                              ),
                          ],
                          onChanged: (value) {
                            if (value != null) onStateChanged(value);
                          },
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Classification',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  for (final option in classificationOptions)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: FilterChip(
                        key: Key(
                          'team_heatmap_classification_filter_${option.id}',
                        ),
                        label: Text(option.label),
                        selected: selectedClassifications.contains(option.id),
                        onSelected: (selected) =>
                            onClassificationChanged(option.id, selected),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _activeFilterLabel(int count) {
  if (count == 0) return 'No filters active';
  return '$count ${count == 1 ? 'filter' : 'filters'} active';
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
    final filteredRow = selection.row;
    final row = filteredRow.row;
    final stats = filteredRow.stats;
    final event = selection.event.event;
    final cell = selection.cell;
    return AlertDialog(
      key: const Key('team_heatmap_cell_dialog'),
      title: Text(row.athlete.name),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _DetailSectionTitle('Session'),
              _DetailLine(label: 'Athlete', value: row.athlete.name),
              _DetailLine(label: 'Date', value: _formatDate(event.date)),
              _DetailLine(label: 'Task', value: _blankToDash(event.taskName)),
              _DetailLine(
                label: 'Protocol',
                value: _blankToDash(event.protocolName),
              ),
              const Divider(height: 20),
              const _DetailSectionTitle('RMSSD'),
              _DetailLine(
                label: 'RMSSD exercise',
                value: _formatRmssdExercise(cell),
              ),
              _DetailLine(
                label: 'RMSSD recovery',
                value: _formatMs(cell.rmssdRecovery),
              ),
              _DetailLine(
                label: 'RMSSD-Slope',
                value: _formatNumber(cell.slope, digits: 3),
              ),
              _DetailLine(
                label: 'Classification',
                value: cell.state == TeamHeatmapCellState.valid
                    ? recoveryResponseShortLabelForClassificationKey(
                        cell.classification,
                      )
                    : '-',
              ),
              const Divider(height: 20),
              const _DetailSectionTitle('Status'),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final label in cell.statusLabels)
                    _SmallChip(
                      label: label,
                      color:
                          label == 'Incomplete' ||
                              label == 'Unit mismatch' ||
                              label == 'Exclusion'
                          ? AppColors.warning
                          : AppColors.tertiary,
                    ),
                  if (cell.statusLabels.isEmpty)
                    const _SmallChip(label: 'OK', color: AppColors.success),
                ],
              ),
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
              const Divider(height: 20),
              const _DetailSectionTitle('Load'),
              _DetailLine(
                label: 'Metric',
                value: [
                  event.loadType,
                  event.loadMetricName,
                  if (event.loadUnit != null && event.loadUnit!.isNotEmpty)
                    event.loadUnit,
                ].join(' '),
              ),
              _DetailLine(label: 'Value', value: _formatLoad(cell, event)),
              const Divider(height: 20),
              const _DetailSectionTitle('Individual period context'),
              _DetailLine(
                label: 'Sessions visible',
                value: stats.visibleSessionCount.toString(),
              ),
              _DetailLine(
                label: 'Valid sessions',
                value: stats.validSessionCount.toString(),
              ),
              _DetailLine(
                label: 'Latest valid slope',
                value: _formatNumber(stats.latestValidSlope, digits: 3),
              ),
              _DetailLine(
                label: 'Median valid slope',
                value: _formatNumber(stats.medianValidSlope, digits: 3),
              ),
              _DetailLine(
                label: 'Fallback count',
                value: stats.fallbackCount.toString(),
              ),
              const Text(
                'Statistics use the currently visible filtered period.',
                style: TextStyle(color: AppColors.textHint, fontSize: 12),
              ),
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

class _DetailSectionTitle extends StatelessWidget {
  final String text;

  const _DetailSectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
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

String? _dateBoundary(String? raw, {required bool endOfDay}) {
  if (raw == null) return null;
  final parsed = _parseStrictDate(raw);
  if (parsed == null) return null;
  final bounded = endOfDay
      ? DateTime(parsed.year, parsed.month, parsed.day, 23, 59, 59, 999)
      : DateTime(parsed.year, parsed.month, parsed.day);
  return bounded.toIso8601String();
}

bool _hasInvalidDate(String? raw) {
  return raw != null && _parseStrictDate(raw) == null;
}

DateTime? _parseStrictDate(String raw) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(raw.trim());
  if (match == null) return null;
  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  final parsed = DateTime(year, month, day);
  if (parsed.year != year || parsed.month != month || parsed.day != day) {
    return null;
  }
  return parsed;
}

String _formatDateOnly(String raw) {
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw;
  return '${parsed.year.toString().padLeft(4, '0')}-'
      '${parsed.month.toString().padLeft(2, '0')}-'
      '${parsed.day.toString().padLeft(2, '0')}';
}

String _formatDate(String raw) {
  return formatSessionDateForDisplay(raw);
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
