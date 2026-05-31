library;

import 'package:flutter/material.dart';
import 'package:hrv_slope_app/data/database/app_database.dart';
import 'package:hrv_slope_app/data/database/daos/sessions_dao.dart';
import 'package:hrv_slope_app/data/export/csv_export_service.dart';
import 'package:hrv_slope_app/data/export/export_file_writer.dart';
import 'package:hrv_slope_app/shared/engine/group_report_builder.dart';
import 'package:hrv_slope_app/shared/engine/nomogram_engine.dart';
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
  final _taskCtrl = TextEditingController();
  final _sessionTypeCtrl = TextEditingController();
  List<SessionDetail> _details = [];
  GroupReportData? _report;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _dateFromCtrl.dispose();
    _dateToCtrl.dispose();
    _taskCtrl.dispose();
    _sessionTypeCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final details = await widget.database.sessionsDao.getAllSessionDetails();
    final report = buildGroupReport(
      details: details,
      nomogramPreset: PopulationNomogramSource.excelOperational,
    );
    if (mounted) {
      setState(() {
        _details = details;
        _report = report;
        _loading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _report = buildGroupReport(
        details: _details,
        nomogramPreset: PopulationNomogramSource.excelOperational,
        dateFrom: _blankToNull(_dateFromCtrl.text),
        dateTo: _blankToNull(_dateToCtrl.text),
        taskName: _blankToNull(_taskCtrl.text),
        sessionType: _blankToNull(_sessionTypeCtrl.text),
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
          _filters(),
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

  Widget _filters() {
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
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _text(_dateFromCtrl, 'From date')),
                const SizedBox(width: 12),
                Expanded(child: _text(_dateToCtrl, 'To date')),
              ],
            ),
            const SizedBox(height: 12),
            _text(_taskCtrl, 'Task/session contains'),
            const SizedBox(height: 12),
            _text(_sessionTypeCtrl, 'Session type'),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _applyFilters,
                icon: const Icon(Icons.filter_alt),
                label: const Text('Apply'),
              ),
            ),
          ],
        ),
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
                _metric('Intensity', _percent(row.intensityPercent)),
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
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No sessions match these filters. Adjust the date, task, or session type.',
          style: TextStyle(color: AppColors.textHint),
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
}

Widget _text(TextEditingController controller, String label) {
  return TextField(
    controller: controller,
    decoration: InputDecoration(labelText: label),
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

String _classificationLabel(String value) {
  switch (value) {
    case 'very_high_internal_load':
    case 'veryHighInternalLoad':
      return 'Very high internal load';
    case 'high_or_moderate_internal_load':
    case 'highOrModerateInternalLoad':
      return 'High/moderate internal load';
    case 'expected_response':
    case 'expectedResponse':
      return 'Expected response';
    case 'low_internal_load_or_fast_recovery':
    case 'lowInternalLoadOrFastRecovery':
      return 'Low internal load / fast recovery';
    default:
      return value;
  }
}

Color _classificationColor(String? value) {
  switch (value) {
    case 'very_high_internal_load':
    case 'veryHighInternalLoad':
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
