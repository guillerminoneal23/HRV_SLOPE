library;

import 'package:flutter/material.dart';
import 'package:hrv_slope_app/data/database/app_database.dart';
import 'package:hrv_slope_app/shared/engine/recovery_response_labels.dart';
import 'package:hrv_slope_app/shared/engine/team_event_report_builder.dart';
import 'package:hrv_slope_app/ui/screens/session/session_detail_screen.dart';
import 'package:hrv_slope_app/ui/theme/app_theme.dart';

class SessionEventDetailScreen extends StatefulWidget {
  final AppDatabase database;
  final int eventId;

  const SessionEventDetailScreen({
    super.key,
    required this.database,
    required this.eventId,
  });

  @override
  State<SessionEventDetailScreen> createState() =>
      _SessionEventDetailScreenState();
}

class _SessionEventDetailScreenState extends State<SessionEventDetailScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  TeamEventReportData? _report;
  String? _error;
  bool _loading = true;
  String _classificationFilter = _allClassifications;
  _FallbackFilter _fallbackFilter = _FallbackFilter.all;
  bool _incompleteOnly = false;
  _SortMode _sortMode = _SortMode.defaultOrder;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final bundle = await widget.database.sessionEventsDao
          .getEventDetailBundle(widget.eventId);
      if (!mounted) return;
      setState(() {
        _report = bundle == null ? null : buildTeamEventReport(bundle);
        _error = bundle == null ? 'Session event not found' : null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final report = _report;
    if (report == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Session Event')),
        body: Center(child: Text(_error ?? 'Session event not found')),
      );
    }

    final rows = _filteredRows(report);
    return Scaffold(
      appBar: AppBar(title: Text(report.event.taskName ?? 'Session Event')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _EventHeader(report: report),
            const SizedBox(height: 12),
            _SummarySection(report: report),
            const SizedBox(height: 12),
            _ClassificationSummary(report: report),
            const SizedBox(height: 12),
            _FilterBar(
              searchCtrl: _searchCtrl,
              classifications: _visibleClassificationCounts(
                report.classificationCounts,
              ),
              classificationFilter: _classificationFilter,
              fallbackFilter: _fallbackFilter,
              incompleteOnly: _incompleteOnly,
              sortMode: _sortMode,
              onClassificationChanged: (value) => setState(
                () => _classificationFilter = value ?? _allClassifications,
              ),
              onFallbackChanged: (value) => setState(
                () => _fallbackFilter = value ?? _FallbackFilter.all,
              ),
              onIncompleteChanged: (value) =>
                  setState(() => _incompleteOnly = value ?? false),
              onSortChanged: (value) =>
                  setState(() => _sortMode = value ?? _SortMode.defaultOrder),
            ),
            const SizedBox(height: 12),
            _RowsTable(
              rows: rows,
              event: report.event,
              onOpenSession: _openSession,
            ),
          ],
        ),
      ),
    );
  }

  List<TeamEventReportRow> _filteredRows(TeamEventReportData report) {
    final query = _searchCtrl.text.trim().toLowerCase();
    final filtered = report.rows.where((row) {
      if (query.isNotEmpty && !row.athleteName.toLowerCase().contains(query)) {
        return false;
      }
      if (_classificationFilter != _allClassifications &&
          recoveryResponseZoneForClassificationKey(row.classification)?.id !=
              _classificationFilter) {
        return false;
      }
      if (_fallbackFilter == _FallbackFilter.fallback &&
          !row.hasFallbackExercise) {
        return false;
      }
      if (_fallbackFilter == _FallbackFilter.measured &&
          row.hasFallbackExercise) {
        return false;
      }
      if (_incompleteOnly && !row.isIncomplete) return false;
      return true;
    }).toList();

    switch (_sortMode) {
      case _SortMode.defaultOrder:
        filtered.sort(compareTeamEventRowsDefault);
      case _SortMode.name:
        filtered.sort(compareTeamEventRowsByName);
      case _SortMode.slope:
        filtered.sort((a, b) {
          final result = compareTeamEventRowsBySlope(a, b);
          return result == 0 ? compareTeamEventRowsByName(a, b) : result;
        });
      case _SortMode.load:
        filtered.sort((a, b) {
          final result = compareTeamEventRowsByLoad(a, b);
          return result == 0 ? compareTeamEventRowsByName(a, b) : result;
        });
    }
    return filtered;
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
}

class _EventHeader extends StatelessWidget {
  final TeamEventReportData report;

  const _EventHeader({required this.report});

  @override
  Widget build(BuildContext context) {
    final event = report.event;
    final team = report.team;
    return Card(
      key: const Key('session_event_header'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  child: const Icon(Icons.groups, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        team?.name ?? 'No team',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        _formatDate(event.date),
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (team?.isArchived == true)
                  const _SmallChip(
                    label: 'Archived team',
                    color: AppColors.warning,
                  ),
              ],
            ),
            const Divider(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                _HeaderItem(label: 'Task', value: event.taskName),
                _HeaderItem(label: 'Sport', value: event.sport),
                _HeaderItem(label: 'Protocol', value: event.protocolName),
                _HeaderItem(label: 'Context', value: event.contextEnvironment),
                _HeaderItem(
                  label: 'Recovery window',
                  value:
                      '${_formatCompact(event.recoveryWindowStartMin)}-${_formatCompact(event.recoveryWindowEndMin)} min',
                ),
                _HeaderItem(label: 'Load type', value: event.loadType),
                _HeaderItem(label: 'Load metric', value: event.loadMetricName),
                _HeaderItem(label: 'Load unit', value: event.loadUnit),
                _HeaderItem(
                  label: 'Participants',
                  value: report.summary.participantCount.toString(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  final TeamEventReportData report;

  const _SummarySection({required this.report});

  @override
  Widget build(BuildContext context) {
    final summary = report.summary;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _SummaryTile(
          key: const Key('session_event_summary_participants'),
          label: 'Valid participants',
          value: '${summary.validParticipantCount}/${summary.participantCount}',
        ),
        _SummaryTile(
          key: const Key('session_event_summary_median_slope'),
          label: 'Median RMSSD-Slope',
          value: _formatNumber(summary.medianSlope, digits: 3),
        ),
        _SummaryTile(
          key: const Key('session_event_summary_iqr'),
          label: 'IQR',
          value: _formatNumber(summary.iqrSlope, digits: 3),
        ),
        _SummaryTile(
          key: const Key('session_event_summary_fallback'),
          label: 'Fallback 4 ms',
          value: summary.fallbackExerciseCount.toString(),
        ),
        _SummaryTile(
          key: const Key('session_event_summary_incomplete'),
          label: 'Incomplete',
          value: summary.incompleteCount.toString(),
        ),
        _SummaryTile(
          key: const Key('session_event_summary_median_load'),
          label: 'Median load',
          value: _formatNumber(summary.medianLoad, digits: 1),
        ),
      ],
    );
  }
}

class _ClassificationSummary extends StatelessWidget {
  final TeamEventReportData report;

  const _ClassificationSummary({required this.report});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Classification',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in _visibleClassificationCounts(
                  report.classificationCounts,
                ))
                  _ClassificationChip(
                    classification: item.label,
                    label: '${item.label}: ${item.count}',
                  ),
                if (report.classificationCounts.isEmpty)
                  const Text(
                    'No classified sessions',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Color = interpretation according to the active reference.',
              style: TextStyle(color: AppColors.textHint, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final TextEditingController searchCtrl;
  final List<_VisibleClassificationCount> classifications;
  final String classificationFilter;
  final _FallbackFilter fallbackFilter;
  final bool incompleteOnly;
  final _SortMode sortMode;
  final ValueChanged<String?> onClassificationChanged;
  final ValueChanged<_FallbackFilter?> onFallbackChanged;
  final ValueChanged<bool?> onIncompleteChanged;
  final ValueChanged<_SortMode?> onSortChanged;

  const _FilterBar({
    required this.searchCtrl,
    required this.classifications,
    required this.classificationFilter,
    required this.fallbackFilter,
    required this.incompleteOnly,
    required this.sortMode,
    required this.onClassificationChanged,
    required this.onFallbackChanged,
    required this.onIncompleteChanged,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 260,
              child: TextField(
                key: const Key('session_event_search'),
                controller: searchCtrl,
                decoration: const InputDecoration(
                  labelText: 'Search athlete',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            SizedBox(
              width: 250,
              child: DropdownButtonFormField<String>(
                key: const Key('session_event_filter_classification'),
                initialValue: classificationFilter,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Classification'),
                items: [
                  const DropdownMenuItem(
                    value: _allClassifications,
                    child: Text('All classifications'),
                  ),
                  for (final item in classifications)
                    DropdownMenuItem(
                      value: item.zone.id,
                      child: Text(item.label),
                    ),
                ],
                onChanged: onClassificationChanged,
              ),
            ),
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<_FallbackFilter>(
                key: const Key('session_event_filter_fallback'),
                initialValue: fallbackFilter,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Fallback'),
                items: const [
                  DropdownMenuItem(
                    value: _FallbackFilter.all,
                    child: Text('All'),
                  ),
                  DropdownMenuItem(
                    value: _FallbackFilter.fallback,
                    child: Text('Fallback only'),
                  ),
                  DropdownMenuItem(
                    value: _FallbackFilter.measured,
                    child: Text('Measured only'),
                  ),
                ],
                onChanged: onFallbackChanged,
              ),
            ),
            SizedBox(
              width: 170,
              child: DropdownButtonFormField<_SortMode>(
                key: const Key('session_event_sort'),
                initialValue: sortMode,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Sort'),
                items: const [
                  DropdownMenuItem(
                    value: _SortMode.defaultOrder,
                    child: Text('Status'),
                  ),
                  DropdownMenuItem(value: _SortMode.name, child: Text('Name')),
                  DropdownMenuItem(
                    value: _SortMode.slope,
                    child: Text('Slope'),
                  ),
                  DropdownMenuItem(value: _SortMode.load, child: Text('Load')),
                ],
                onChanged: onSortChanged,
              ),
            ),
            FilterChip(
              key: const Key('session_event_filter_incomplete'),
              selected: incompleteOnly,
              onSelected: (selected) => onIncompleteChanged(selected),
              avatar: const Icon(Icons.warning_amber, size: 16),
              label: const Text('Incomplete'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RowsTable extends StatelessWidget {
  final List<TeamEventReportRow> rows;
  final SessionEvent event;
  final ValueChanged<int> onOpenSession;

  const _RowsTable({
    required this.rows,
    required this.event,
    required this.onOpenSession,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('session_event_table'),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
              child: Text(
                'Players (${rows.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (rows.isEmpty)
              const Padding(
                padding: EdgeInsets.all(18),
                child: Text(
                  'No players match the current filters.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              )
            else
              Scrollbar(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 18,
                    dataRowMinHeight: 58,
                    dataRowMaxHeight: 92,
                    columns: const [
                      DataColumn(label: Text('Athlete')),
                      DataColumn(label: Text('RMSSD exercise')),
                      DataColumn(label: Text('RMSSD recovery')),
                      DataColumn(label: Text('Load')),
                      DataColumn(label: Text('RMSSD-Slope')),
                      DataColumn(label: Text('Classification')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Action')),
                    ],
                    rows: [
                      for (final row in rows)
                        DataRow(
                          color: WidgetStateProperty.resolveWith(
                            (_) => row.isIncomplete
                                ? AppColors.warning.withValues(alpha: 0.08)
                                : row.hasWarnings
                                ? AppColors.tertiary.withValues(alpha: 0.06)
                                : null,
                          ),
                          cells: [
                            DataCell(_AthleteCell(row: row)),
                            DataCell(_rmssdExerciseCell(row)),
                            DataCell(Text(_formatMs(row.rmssdRecovery))),
                            DataCell(Text(_formatLoad(row, event))),
                            DataCell(
                              Text(
                                _formatNumber(row.slopeInterpreted, digits: 3),
                              ),
                            ),
                            DataCell(
                              _ClassificationChip(
                                classification: row.classification,
                                label:
                                    recoveryResponseShortLabelForClassificationKey(
                                      row.classification,
                                    ),
                              ),
                            ),
                            DataCell(_StatusCell(row: row)),
                            DataCell(
                              IconButton(
                                key: Key(
                                  'session_event_open_session_${row.sessionId}',
                                ),
                                tooltip: 'Open session detail',
                                icon: const Icon(Icons.open_in_new),
                                onPressed: () => onOpenSession(row.sessionId),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AthleteCell extends StatelessWidget {
  final TeamEventReportRow row;

  const _AthleteCell({required this.row});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: Key('session_event_row_${row.sessionId}'),
      width: 190,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            row.athleteName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Text(
            'ID ${row.athleteId}',
            style: const TextStyle(fontSize: 11, color: AppColors.textHint),
          ),
          if (row.athleteIsArchived)
            const Text(
              'Archived athlete',
              style: TextStyle(fontSize: 11, color: AppColors.warning),
            ),
        ],
      ),
    );
  }
}

class _StatusCell extends StatelessWidget {
  final TeamEventReportRow row;

  const _StatusCell({required this.row});

  @override
  Widget build(BuildContext context) {
    if (row.statusLabels.isEmpty) {
      return const _SmallChip(label: 'OK', color: AppColors.success);
    }
    final content = Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        for (final label in row.statusLabels)
          _SmallChip(
            label: label,
            color: label == 'Incomplete' || label == 'Unit mismatch'
                ? AppColors.warning
                : AppColors.tertiary,
          ),
      ],
    );
    if (row.warnings.isEmpty) return content;
    return Tooltip(message: row.warnings.join('\n'), child: content);
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryTile({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 176,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              Text(value, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderItem extends StatelessWidget {
  final String label;
  final String? value;

  const _HeaderItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            _blankToDash(value),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _ClassificationChip extends StatelessWidget {
  final String? classification;
  final String label;

  const _ClassificationChip({
    required this.classification,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final color = _classificationColor(classification);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.42)),
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

Widget _rmssdExerciseCell(TeamEventReportRow row) {
  final value = row.rmssdExercise == null ? '-' : _formatMs(row.rmssdExercise);
  if (!row.hasFallbackExercise) return Text(value);
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(value),
      const SizedBox(width: 6),
      const _SmallChip(label: 'default', color: AppColors.tertiary),
    ],
  );
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

List<_VisibleClassificationCount> _visibleClassificationCounts(
  List<TeamEventClassificationCount> rawCounts,
) {
  final counts = <RecoveryResponseZone, int>{};
  for (final item in rawCounts) {
    final zone = recoveryResponseZoneForClassificationKey(item.classification);
    if (zone == null) continue;
    counts[zone] = (counts[zone] ?? 0) + item.count;
  }
  return [
    for (final zone in visibleRecoveryResponseZones)
      if ((counts[zone] ?? 0) > 0)
        _VisibleClassificationCount(zone: zone, count: counts[zone]!),
  ];
}

class _VisibleClassificationCount {
  final RecoveryResponseZone zone;
  final int count;

  const _VisibleClassificationCount({required this.zone, required this.count});

  String get label => zone.shortLabel;
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

String _formatMs(double? value) {
  if (value == null || !value.isFinite) return '-';
  return '${_formatNumber(value)} ms';
}

String _formatLoad(TeamEventReportRow row, SessionEvent event) {
  final value = row.loadValue;
  if (value == null || !value.isFinite) return '-';
  final unit = row.loadUnit ?? event.loadUnit;
  return [
    _formatNumber(value, digits: 1),
    unit,
  ].whereType<String>().where((part) => part.trim().isNotEmpty).join(' ');
}

String _formatCompact(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(1);
}

String _blankToDash(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return '-';
  return trimmed;
}

const _allClassifications = '__all__';

enum _FallbackFilter { all, fallback, measured }

enum _SortMode { defaultOrder, name, slope, load }
