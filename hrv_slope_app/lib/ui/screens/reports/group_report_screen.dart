library;

import 'package:flutter/material.dart';
import 'package:hrv_slope_app/core/constants/session_constants.dart';
import 'package:hrv_slope_app/data/database/app_database.dart';
import 'package:hrv_slope_app/data/database/daos/sessions_dao.dart';
import 'package:hrv_slope_app/data/export/csv_export_service.dart';
import 'package:hrv_slope_app/data/export/export_file_writer.dart';
import 'package:hrv_slope_app/data/services/reusable_tag_service.dart';
import 'package:hrv_slope_app/shared/engine/group_report_builder.dart';
import 'package:hrv_slope_app/shared/engine/nomogram_engine.dart';
import 'package:hrv_slope_app/shared/engine/recovery_response_labels.dart';
import 'package:hrv_slope_app/ui/theme/app_theme.dart';

class GroupReportScreen extends StatefulWidget {
  final AppDatabase database;

  const GroupReportScreen({super.key, required this.database});

  @override
  State<GroupReportScreen> createState() => _GroupReportScreenState();
}

class _GroupReportScreenState extends State<GroupReportScreen> {
  final _dateFromCtrl = TextEditingController();
  final _dateToCtrl = TextEditingController();
  final _taskSearchCtrl = TextEditingController();
  final _intensityMinCtrl = TextEditingController();
  final _intensityMaxCtrl = TextEditingController();
  final _rpeMinCtrl = TextEditingController();
  final _rpeMaxCtrl = TextEditingController();
  final _fatigueMinCtrl = TextEditingController();
  final _fatigueMaxCtrl = TextEditingController();
  final _slopeMinCtrl = TextEditingController();
  final _slopeMaxCtrl = TextEditingController();
  final _itlMinCtrl = TextEditingController();
  final _itlMaxCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  List<SessionDetail> _details = [];
  GroupReportData? _report;
  ReusableTagCatalog _tagCatalog = ReusableTagCatalog.empty();
  String? _filterError;
  bool _loading = true;

  Set<String> _athletes = {};
  Set<String> _sports = {};
  Set<String> _tasks = {};
  Set<String> _types = {};
  Set<String> _protocols = {};
  Set<String> _contexts = {};
  Set<String> _intensitySources = {};
  Set<String> _metrics = {};
  Set<String> _responses = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final controller in [
      _dateFromCtrl,
      _dateToCtrl,
      _taskSearchCtrl,
      _intensityMinCtrl,
      _intensityMaxCtrl,
      _rpeMinCtrl,
      _rpeMaxCtrl,
      _fatigueMinCtrl,
      _fatigueMaxCtrl,
      _slopeMinCtrl,
      _slopeMaxCtrl,
      _itlMinCtrl,
      _itlMaxCtrl,
      _notesCtrl,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final details = await widget.database.sessionsDao.getAllSessionDetails();
    final catalog = await ReusableTagService(
      widget.database.settingsDao,
    ).getCatalog();
    final report = buildGroupReport(
      details: details,
      nomogramPreset: PopulationNomogramSource.excelOperational,
    );
    if (mounted) {
      setState(() {
        _details = details;
        _tagCatalog = catalog;
        _report = report;
        _loading = false;
      });
    }
  }

  void _applyFilters() {
    final from = _blankToNull(_dateFromCtrl.text);
    final to = _blankToNull(_dateToCtrl.text);
    final fromDay = _calendarDayKey(from);
    final toDay = _calendarDayKey(to);
    if ((from != null && fromDay == null) || (to != null && toDay == null)) {
      setState(() => _filterError = 'Use YYYY-MM-DD for date filters.');
      return;
    }
    if (fromDay != null && toDay != null && fromDay.compareTo(toDay) > 0) {
      setState(() {
        _filterError = 'From date must be on or before To date.';
      });
      return;
    }
    final filter = GroupReportFilter(
      dateFrom: fromDay,
      dateTo: toDay,
      athleteNames: _athletes,
      sports: _sports,
      sessionTasks: _tasks,
      taskTextSearch: _blankToNull(_taskSearchCtrl.text),
      sessionTypes: _types,
      protocolNames: _protocols,
      contextEnvironmentTags: _contexts,
      intensitySourcesForSlope: _intensitySources,
      intensityMetricNames: _metrics,
      primaryIntensityMin: _number(_intensityMinCtrl.text),
      primaryIntensityMax: _number(_intensityMaxCtrl.text),
      rpeMin: _number(_rpeMinCtrl.text),
      rpeMax: _number(_rpeMaxCtrl.text),
      fatigueMin: _number(_fatigueMinCtrl.text),
      fatigueMax: _number(_fatigueMaxCtrl.text),
      slopeMin: _number(_slopeMinCtrl.text),
      slopeMax: _number(_slopeMaxCtrl.text),
      itlMin: _number(_itlMinCtrl.text),
      itlMax: _number(_itlMaxCtrl.text),
      recoveryResponses: _responses,
      notesTextSearch: _blankToNull(_notesCtrl.text),
    );
    setState(() {
      _filterError = null;
      _report = buildGroupReport(
        details: _details,
        nomogramPreset: PopulationNomogramSource.excelOperational,
        filter: filter,
      );
    });
  }

  void _clearFilters() {
    for (final controller in [
      _dateFromCtrl,
      _dateToCtrl,
      _taskSearchCtrl,
      _intensityMinCtrl,
      _intensityMaxCtrl,
      _rpeMinCtrl,
      _rpeMaxCtrl,
      _fatigueMinCtrl,
      _fatigueMaxCtrl,
      _slopeMinCtrl,
      _slopeMaxCtrl,
      _itlMinCtrl,
      _itlMaxCtrl,
      _notesCtrl,
    ]) {
      controller.clear();
    }
    setState(() {
      _athletes = {};
      _sports = {};
      _tasks = {};
      _types = {};
      _protocols = {};
      _contexts = {};
      _intensitySources = {};
      _metrics = {};
      _responses = {};
      _filterError = null;
      _report = buildGroupReport(
        details: _details,
        nomogramPreset: PopulationNomogramSource.excelOperational,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final report = _report!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Report'),
        actions: [
          IconButton(
            tooltip: 'Export CSV',
            onPressed: report.rows.isEmpty ? null : _exportCsv,
            icon: const Icon(Icons.download),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _filters(report),
          if (report.activeFilterLabels.isNotEmpty)
            _activeFilters(report.activeFilterLabels),
          if (report.rows.isEmpty)
            _emptyState()
          else ...[
            _summary(report.summary),
            if (report.warnings.isNotEmpty) _warnings(report.warnings),
            for (var i = 0; i < report.rows.length; i++)
              _rowCard(report.rows[i], report.rows[i].isRanked ? i + 1 : null),
          ],
        ],
      ),
    );
  }

  Widget _filters(GroupReportData report) {
    final options = report.filterOptions;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filters',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _filterActions(),
            const SizedBox(height: 12),
            _sectionTitle('Date range'),
            Row(
              children: [
                Expanded(child: _dateField(_dateFromCtrl, 'From date')),
                const SizedBox(width: 12),
                Expanded(child: _dateField(_dateToCtrl, 'To date')),
              ],
            ),
            if (_filterError != null) ...[
              const SizedBox(height: 8),
              Text(
                _filterError!,
                style: const TextStyle(color: AppColors.warning, fontSize: 12),
              ),
            ],
            const SizedBox(height: 16),
            _sectionTitle('Athlete and sport'),
            _CompactMultiSelectFilter(
              label: 'Athlete',
              options: _athleteOptions(options),
              selectedValues: _athletes,
              onChanged: (next) => setState(() => _athletes = next),
            ),
            _CompactMultiSelectFilter(
              label: 'Sport',
              options: _sportOptions(options),
              selectedValues: _sports,
              onChanged: (next) => setState(() => _sports = next),
            ),
            const SizedBox(height: 12),
            _sectionTitle('Session similarity'),
            _CompactMultiSelectFilter(
              label: 'Session task/name',
              options: _taskOptions(options),
              selectedValues: _tasks,
              onChanged: (next) => setState(() => _tasks = next),
            ),
            _text(_taskSearchCtrl, 'Search text'),
            const SizedBox(height: 8),
            _CompactMultiSelectFilter(
              label: 'Session type',
              options: _typeOptions(options),
              selectedValues: _types,
              onChanged: (next) => setState(() => _types = next),
            ),
            _CompactMultiSelectFilter(
              label: 'Protocol name',
              options: _protocolOptions(options),
              selectedValues: _protocols,
              onChanged: (next) => setState(() => _protocols = next),
            ),
            _CompactMultiSelectFilter(
              label: 'Context / Environment',
              options: _contextOptions(options),
              selectedValues: _contexts,
              onChanged: (next) => setState(() => _contexts = next),
            ),
            const SizedBox(height: 12),
            _sectionTitle('Recovery response'),
            _CompactMultiSelectFilter(
              label: 'Recovery response',
              options: options.recoveryResponses,
              selectedValues: _responses,
              onChanged: (next) => setState(() => _responses = next),
            ),
            const SizedBox(height: 8),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('Advanced filters'),
              childrenPadding: const EdgeInsets.only(top: 8),
              children: [
                _chipGroup(
                  'Intensity source for slope',
                  options.intensitySourcesForSlope,
                  _intensitySources,
                  (next) => setState(() => _intensitySources = next),
                ),
                _chipGroup(
                  'Metric used for slope',
                  options.intensityMetricNames,
                  _metrics,
                  (next) => setState(() => _metrics = next),
                  labelFor: _metricLabel,
                ),
                _rangeFields(
                  'Primary intensity used for slope (%)',
                  _intensityMinCtrl,
                  _intensityMaxCtrl,
                ),
                _rangeFields('RPE 1-10', _rpeMinCtrl, _rpeMaxCtrl),
                _rangeFields('Fatigue 1-10', _fatigueMinCtrl, _fatigueMaxCtrl),
                _rangeFields('Slope', _slopeMinCtrl, _slopeMaxCtrl),
                _rangeFields('ITL', _itlMinCtrl, _itlMaxCtrl),
                _text(_notesCtrl, 'Notes contains'),
              ],
            ),
            const SizedBox(height: 12),
            _filterActions(),
          ],
        ),
      ),
    );
  }

  Widget _filterActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton.icon(
          onPressed: _clearFilters,
          icon: const Icon(Icons.clear),
          label: const Text('Clear filters'),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: _applyFilters,
          icon: const Icon(Icons.filter_alt),
          label: const Text('Apply filters'),
        ),
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _dateField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Pick date',
              icon: const Icon(Icons.calendar_today),
              onPressed: () => _pickDate(controller),
            ),
            IconButton(
              tooltip: 'Clear date',
              icon: const Icon(Icons.clear),
              onPressed: () => setState(controller.clear),
            ),
          ],
        ),
      ),
      onTap: () => _pickDate(controller),
    );
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final current = DateTime.tryParse(controller.text.trim());
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    controller.text = _calendarKey(picked);
  }

  Widget _chipGroup(
    String label,
    Set<String> options,
    Set<String> selected,
    ValueChanged<Set<String>> onChanged, {
    String Function(String value)? labelFor,
  }) {
    if (options.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final option in options)
                FilterChip(
                  label: Text(labelFor == null ? option : labelFor(option)),
                  selected: selected.contains(option),
                  onSelected: (value) {
                    final next = {...selected};
                    if (value) {
                      next.add(option);
                    } else {
                      next.remove(option);
                    }
                    onChanged(next);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rangeFields(
    String label,
    TextEditingController min,
    TextEditingController max,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: _text(min, '$label min')),
          const SizedBox(width: 12),
          Expanded(child: _text(max, '$label max')),
        ],
      ),
    );
  }

  Widget _activeFilters(List<String> labels) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          for (final label in labels)
            Chip(
              label: Text(label),
              backgroundColor: AppColors.primary.withValues(alpha: 0.08),
              side: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.25),
              ),
            ),
        ],
      ),
    );
  }

  Widget _summary(GroupReportSummary s) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _metric('Sessions', '${s.nSessions}'),
            _metric('Athletes', '${s.nAthletes}'),
            _metric('Ranked', '${s.nComplete}'),
            _metric('Mean slope', _fixed(s.meanSlope, 3)),
            _metric('Median slope', _fixed(s.medianSlope, 3)),
            _metric('Min slope', _fixed(s.minSlope, 3)),
            _metric('Max slope', _fixed(s.maxSlope, 3)),
            _metric('Mean ITL', _fixed(s.meanItl, 3)),
          ],
        ),
      ),
    );
  }

  Widget _warnings(List<String> warnings) {
    return Card(
      color: AppColors.warning.withValues(alpha: 0.08),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Warnings',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(height: 8),
            for (final warning in warnings.take(6))
              Text(
                warning,
                style: const TextStyle(fontSize: 12, color: AppColors.warning),
              ),
            if (warnings.length > 6)
              Text(
                '+${warnings.length - 6} more',
                style: const TextStyle(fontSize: 12, color: AppColors.warning),
              ),
          ],
        ),
      ),
    );
  }

  Widget _rowCard(GroupReportRow row, int? rank) {
    final color = _classificationColor(row.classification);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: color.withValues(alpha: 0.18),
                  child: Text(
                    rank == null ? '-' : '$rank',
                    style: TextStyle(color: color, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.athleteName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${row.sessionDate} · ${row.taskName ?? 'Session'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (row.classification != null)
                  Chip(
                    label: Text(_classificationLabel(row.classification!)),
                    backgroundColor: color.withValues(alpha: 0.14),
                    side: BorderSide(color: color.withValues(alpha: 0.35)),
                  ),
              ],
            ),
            const Divider(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                _metric('Sport', row.sport ?? '-'),
                _metric('Type', row.sessionType ?? '-'),
                _metric('Protocol', row.protocolName ?? '-'),
                _metric('Context', row.contextEnvironment ?? '-'),
                _metric('Intensity', _percent(row.intensityPercent)),
                _metric('Intensity source', row.intensitySourceForSlope),
                _metric('Metric', _metricLabel(row.primaryIntensityMetric)),
                _metric('RPE', _fixed(row.rpe, 1)),
                _metric('Fatigue', _fixed(row.fatigue, 1)),
                _metric('RMSSD ex', _ms(row.rmssdExercise)),
                _metric('RMSSD rec', _ms(row.rmssdRecovery)),
                _metric('Slope', _fixed(row.interpretedSlope, 3)),
                _metric('ITL', _fixed(row.itlIndex, 3)),
                _metric('Residual', _fixed(row.residual, 3)),
              ],
            ),
            if (row.warnings.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (final warning in row.warnings)
                Text(
                  warning,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.warning,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'No sessions match the selected filters.',
              style: TextStyle(color: AppColors.textHint),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.clear),
              label: const Text('Clear filters'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportCsv() async {
    final report = _report;
    if (report == null) return;
    final writer = ExportFileWriter();
    final summary = await writer.writeCsv(exportGroupReportSummaryCsv(report));
    final rows = await writer.writeCsv(exportGroupReportRowsCsv(report));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('CSV exported to ${summary.path} and ${rows.path}'),
      ),
    );
  }

  Set<String> _athleteOptions(GroupReportFilterOptions options) {
    return options.athleteNames;
  }

  Set<String> _sportOptions(GroupReportFilterOptions options) {
    return _withTags(options.sports, ReusableTagCategory.sport);
  }

  Set<String> _taskOptions(GroupReportFilterOptions options) {
    return _withTags(options.sessionTasks, ReusableTagCategory.sessionTask);
  }

  Set<String> _typeOptions(GroupReportFilterOptions options) {
    final values = <String>{
      for (final type in SessionTypeOptions.newSessionOptions) type.label,
      ...options.sessionTypes,
    };
    return _sorted(values);
  }

  Set<String> _protocolOptions(GroupReportFilterOptions options) {
    return _withTags(options.protocolNames, ReusableTagCategory.protocol);
  }

  Set<String> _contextOptions(GroupReportFilterOptions options) {
    return _withTags(
      options.contextEnvironmentTags,
      ReusableTagCategory.contextEnvironment,
    );
  }

  Set<String> _withTags(Set<String> values, ReusableTagCategory category) {
    final tags = _tagCatalog.getTagsByCategory(category).map((tag) => tag.name);
    return _sorted({...tags, ...values});
  }
}

class _CompactMultiSelectFilter extends StatelessWidget {
  final String label;
  final Set<String> options;
  final Set<String> selectedValues;
  final ValueChanged<Set<String>> onChanged;

  const _CompactMultiSelectFilter({
    required this.label,
    required this.options,
    required this.selectedValues,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ExpansionTile(
          key: PageStorageKey<String>('group-report-filter-$label'),
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          dense: true,
          title: Text(label, style: const TextStyle(fontSize: 13)),
          subtitle: Text(
            _summaryLabel(),
            key: Key('group-report-filter-$label-summary'),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          children: [
            if (selectedValues.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => onChanged({}),
                  icon: const Icon(Icons.clear, size: 16),
                  label: Text('Clear $label'),
                ),
              ),
            for (final option in options)
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(option),
                value: selectedValues.contains(option),
                onChanged: (value) {
                  final next = {...selectedValues};
                  if (value == true) {
                    next.add(option);
                  } else {
                    next.remove(option);
                  }
                  onChanged(next);
                },
              ),
          ],
        ),
      ),
    );
  }

  String _summaryLabel() {
    if (selectedValues.isEmpty) return 'Any';
    if (selectedValues.length == 1) return selectedValues.single;
    return '${selectedValues.length} selected';
  }
}

Widget _text(TextEditingController controller, String label) {
  return TextField(
    controller: controller,
    decoration: InputDecoration(labelText: label),
    keyboardType: label.toLowerCase().contains('notes')
        ? TextInputType.text
        : TextInputType.number,
  );
}

Widget _metric(String label, String value) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text('$label: $value', style: const TextStyle(fontSize: 12)),
  );
}

Set<String> _sorted(Iterable<String> values) {
  final byLower = <String, String>{};
  for (final value in values) {
    final text = value.trim();
    if (text.isEmpty) continue;
    byLower.putIfAbsent(text.toLowerCase(), () => text);
  }
  final sorted = byLower.values.toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return {for (final value in sorted) value};
}

String _fixed(double? value, int digits) =>
    value == null ? '-' : value.toStringAsFixed(digits);
String _percent(double? value) =>
    value == null ? '-' : '${value.toStringAsFixed(1)}%';
String _ms(double? value) =>
    value == null ? '-' : '${value.toStringAsFixed(1)} ms';

String? _blankToNull(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

double? _number(String value) {
  return double.tryParse(value.trim().replaceAll(',', '.'));
}

String? _calendarDayKey(String? value) {
  final text = (value ?? '').trim();
  if (text.isEmpty) return null;
  final parsed = DateTime.tryParse(text);
  if (parsed != null) return _calendarKey(parsed);
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(text);
  if (match == null) return null;
  return '${match.group(1)}-${match.group(2)}-${match.group(3)}';
}

String _calendarKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

String _classificationLabel(String value) {
  return recoveryResponseLabelForClassificationKey(value);
}

String _metricLabel(String? value) {
  switch (value) {
    case 'direct_percent_mas':
    case 'speed_kmh_div_mas':
      return '%MAS';
    case 'rpe_1_10':
      return 'RPE 1-10';
    case 'session_rpe_1_10':
      return 'Session RPE 1-10';
    case 'direct_percent_map':
    case 'power_w_div_map':
      return '%MAP';
    case 'direct_percent_vvo2max':
    case 'speed_kmh_div_vvo2max':
      return '%vVO2max';
    case 'subjective_fatigue_1_10':
      return 'Fatigue 1-10';
    case null:
      return '-';
    default:
      return value
          .split('_')
          .where((part) => part.isNotEmpty)
          .map((part) => part[0].toUpperCase() + part.substring(1))
          .join(' ');
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
      return AppColors.classExpected;
    case 'low_internal_load_or_fast_recovery':
    case 'lowInternalLoadOrFastRecovery':
      return AppColors.classLowFast;
    default:
      return AppColors.tertiary;
  }
}
