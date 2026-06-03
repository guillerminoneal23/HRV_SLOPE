library;

import 'package:flutter/material.dart';
import 'package:hrv_slope_app/data/database/app_database.dart';
import 'package:hrv_slope_app/data/database/daos/sessions_dao.dart';
import 'package:hrv_slope_app/data/export/csv_export_service.dart';
import 'package:hrv_slope_app/data/export/export_file_writer.dart';
import 'package:hrv_slope_app/shared/engine/nomogram_engine.dart';
import 'package:hrv_slope_app/shared/engine/recovery_response_labels.dart';
import 'package:hrv_slope_app/ui/theme/app_theme.dart';
import 'package:hrv_slope_app/ui/widgets/nomogram_chart.dart';

class PopulationNomogramScreen extends StatefulWidget {
  final AppDatabase database;

  const PopulationNomogramScreen({super.key, required this.database});

  @override
  State<PopulationNomogramScreen> createState() =>
      _PopulationNomogramScreenState();
}

class _PopulationNomogramScreenState extends State<PopulationNomogramScreen> {
  PopulationNomogramSource _preset = PopulationNomogramSource.excelOperational;
  List<SessionDetail> _details = [];
  int? _athleteFilter;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final details = await widget.database.sessionsDao.getAllSessionDetails();
    final presetName = await widget.database.settingsDao.getSetting(
      'population_nomogram_preset',
    );
    if (mounted) {
      setState(() {
        _details = details;
        _preset = parsePopulationNomogramSource(presetName);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final athletes = {
      for (final detail in _details) detail.athlete.id: detail.athlete.name,
    };
    final eligible = _details.where((detail) {
      final session = detail.session;
      if (_athleteFilter != null && detail.athlete.id != _athleteFilter) {
        return false;
      }
      return !session.isDraft &&
          session.intensityPercent != null &&
          session.slopeInterpreted != null;
    }).toList();
    final points = eligible
        .map(
          (detail) => NomogramObservedPoint(
            xIntensityPercent: detail.session.intensityPercent!,
            ySlope: detail.session.slopeInterpreted!,
            label: detail.session.taskName ?? detail.session.date,
            classification: _classificationFor(detail.session),
            sessionId: detail.session.id,
            athleteName: detail.athlete.name,
          ),
        )
        .toList();
    final warnings = _rangeWarnings(eligible);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Population Nomogram'),
        actions: [
          IconButton(
            tooltip: 'Export CSV',
            onPressed: _exportCsv,
            icon: const Icon(Icons.download),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _controls(athletes),
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _row('Active preset', _preset.presetName),
                  _row('Eligible sessions', '${points.length}'),
                  const SizedBox(height: 12),
                  NomogramChart(preset: _preset, observedPoints: points),
                ],
              ),
            ),
          ),
          if (warnings.isNotEmpty) _warnings(warnings),
          _legend(),
          if (points.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No eligible sessions yet. Sessions need intensity percent and interpreted slope.',
                  style: TextStyle(color: AppColors.textHint),
                ),
              ),
            )
          else
            for (final detail in eligible) _pointCard(detail),
        ],
      ),
    );
  }

  Widget _controls(Map<int, String> athletes) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'View',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            SegmentedButton<PopulationNomogramSource>(
              segments: const [
                ButtonSegment(
                  value: PopulationNomogramSource.excelOperational,
                  label: Text('Excel operational'),
                ),
                ButtonSegment(
                  value: PopulationNomogramSource.slopeOrellana19,
                  label: Text('slope_Orellana_19'),
                ),
              ],
              selected: {_preset},
              onSelectionChanged: (selection) =>
                  setState(() => _preset = selection.first),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              initialValue: _athleteFilter,
              decoration: const InputDecoration(labelText: 'Athlete filter'),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('All athletes'),
                ),
                for (final entry in athletes.entries)
                  DropdownMenuItem<int?>(
                    value: entry.key,
                    child: Text(entry.value),
                  ),
              ],
              onChanged: (value) => setState(() => _athleteFilter = value),
            ),
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
                color: AppColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            for (final warning in warnings)
              Text(
                warning,
                style: const TextStyle(fontSize: 12, color: AppColors.warning),
              ),
          ],
        ),
      ),
    );
  }

  Widget _legend() {
    return const Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            Text('Lower band'),
            Text('Mean'),
            Text('Upper band'),
            Text('Session points'),
          ],
        ),
      ),
    );
  }

  Widget _pointCard(SessionDetail detail) {
    final session = detail.session;
    final classification = _classificationFor(session);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(
          Icons.circle,
          color: _classificationColor(classification),
        ),
        title: Text(detail.athlete.name),
        subtitle: Text(
          '${session.date} · ${session.taskName ?? 'Session'} · '
          '${session.intensityPercent!.toStringAsFixed(1)}% · '
          'Slope ${session.slopeInterpreted!.toStringAsFixed(3)}',
        ),
        trailing: Text(_classificationLabel(classification)),
      ),
    );
  }

  List<String> _rangeWarnings(List<SessionDetail> details) {
    final warnings = <String>{};
    for (final detail in details) {
      final bands = evaluatePopulationNomogramBands(
        detail.session.intensityPercent!,
        source: _preset,
      );
      for (final warning in bands.warnings) {
        warnings.add('${detail.athlete.name}: $warning');
      }
    }
    return warnings.toList();
  }

  Future<void> _exportCsv() async {
    final export = exportPopulationNomogramCsv(_preset);
    final result = await ExportFileWriter().writeCsv(export);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('CSV exported to ${result.path}')));
  }
}

Widget _row(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
      ],
    ),
  );
}

String _classificationFor(Session session) {
  if (session.intensityPercent == null || session.slopeInterpreted == null) {
    return session.classification ?? '';
  }
  final result = classifySlopeWithPopulationNomogram(
    session.intensityPercent!,
    session.slopeInterpreted!,
  );
  switch (result.classification) {
    case InternalLoadClassification.veryHighInternalLoad:
      return 'very_high_internal_load';
    case InternalLoadClassification.highOrModerateInternalLoad:
      return 'high_or_moderate_internal_load';
    case InternalLoadClassification.expectedResponse:
      return 'expected_response';
    case InternalLoadClassification.lowInternalLoadOrFastRecovery:
      return 'low_internal_load_or_fast_recovery';
  }
}

String _classificationLabel(String value) {
  if (value.isEmpty) return '-';
  return recoveryResponseShortLabelForClassificationKey(value);
}

Color _classificationColor(String value) {
  switch (value) {
    case 'very_high_internal_load':
    case 'Lower-than-expected recovery response':
    case 'Lower-than-expected':
      return AppColors.classVeryHigh;
    case 'high_or_moderate_internal_load':
      return AppColors.classHighMod;
    case 'expected_response':
      return AppColors.classExpected;
    case 'low_internal_load_or_fast_recovery':
      return AppColors.classLowFast;
    default:
      return AppColors.tertiary;
  }
}
