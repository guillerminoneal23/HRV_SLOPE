library;

import 'package:flutter/material.dart';
import 'package:hrv_slope_app/data/database/app_database.dart';
import 'package:hrv_slope_app/data/export/csv_export_service.dart';
import 'package:hrv_slope_app/data/export/export_file_writer.dart';
import 'package:hrv_slope_app/shared/engine/individual_nomogram_builder.dart';
import 'package:hrv_slope_app/shared/engine/recovery_response_labels.dart';
import 'package:hrv_slope_app/shared/engine/nomogram_engine.dart';
import 'package:hrv_slope_app/ui/theme/app_theme.dart';
import 'package:hrv_slope_app/ui/widgets/nomogram_chart.dart';

class IndividualNomogramScreen extends StatefulWidget {
  final AppDatabase database;
  final int athleteId;

  const IndividualNomogramScreen({
    super.key,
    required this.database,
    required this.athleteId,
  });

  @override
  State<IndividualNomogramScreen> createState() =>
      _IndividualNomogramScreenState();
}

class _IndividualNomogramScreenState extends State<IndividualNomogramScreen> {
  IndividualNomogramData? _data;
  Athlete? _athlete;
  PopulationNomogramSource _preset = PopulationNomogramSource.excelOperational;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final athlete = await widget.database.athletesDao.getAthleteById(
      widget.athleteId,
    );
    if (athlete == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final presetName = await widget.database.settingsDao.getSetting(
      'population_nomogram_preset',
    );
    final preset = parsePopulationNomogramSource(presetName);
    final details = await widget.database.sessionsDao
        .getSessionDetailsForAthlete(widget.athleteId);
    final data = buildIndividualNomogramData(
      athlete: athlete,
      details: details,
      populationPreset: preset,
    );
    if (mounted) {
      setState(() {
        _athlete = athlete;
        _preset = preset;
        _data = data;
        _loading = false;
      });
    }
  }

  void _changePreset(PopulationNomogramSource preset) async {
    final athlete = _athlete;
    if (athlete == null) return;
    final details = await widget.database.sessionsDao
        .getSessionDetailsForAthlete(widget.athleteId);
    if (mounted) {
      setState(() {
        _preset = preset;
        _data = buildIndividualNomogramData(
          athlete: athlete,
          details: details,
          populationPreset: preset,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final data = _data;
    final athlete = _athlete;
    if (data == null || athlete == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Individual Nomogram')),
        body: const Center(child: Text('Athlete not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Individual Nomogram'),
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
          _header(athlete, data),
          _confidenceCard(data),
          if (data.warnings.isNotEmpty) _warningsCard(data),
          _chartCard(data),
          _pointsList(data),
          _excludedList(data),
        ],
      ),
    );
  }

  Widget _header(Athlete athlete, IndividualNomogramData data) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        athlete.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (athlete.sport != null)
                        Text(
                          athlete.sport!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                Chip(label: Text(data.summary.recommendedMode.label)),
              ],
            ),
            const Divider(height: 20),
            _row('Valid points', '${data.summary.validPointCount}'),
            _row('Confidence', data.summary.confidenceLabel),
            _row('Recommended mode', data.summary.recommendedMode.label),
            _row('Population preset', data.populationPreset.presetName),
          ],
        ),
      ),
    );
  }

  Widget _confidenceCard(IndividualNomogramData data) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Confidence',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip('Low zone', data.summary.lowZoneCount),
                _chip('Medium zone', data.summary.mediumZoneCount),
                _chip('High zone', data.summary.highZoneCount),
                _chip(
                  'Individual weight',
                  data.hybridWeightIndividual,
                  digits: 1,
                ),
                _chip(
                  'Population weight',
                  data.hybridWeightPopulation,
                  digits: 1,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              data.summary.explanationText,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _warningsCard(IndividualNomogramData data) {
    return Card(
      color: AppColors.warning.withValues(alpha: 0.08),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Data Needs',
              style: TextStyle(
                color: AppColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            for (final warning in data.warnings)
              Text(
                warning,
                style: const TextStyle(fontSize: 12, color: AppColors.warning),
              ),
          ],
        ),
      ),
    );
  }

  Widget _chartCard(IndividualNomogramData data) {
    final mode = data.summary.recommendedMode;
    final showIndividual =
        data.fittedModel != null &&
        mode != IndividualNomogramRecommendedMode.populationOnly;
    final showHybrid =
        data.fittedModel != null &&
        mode == IndividualNomogramRecommendedMode.hybrid;
    final points = [
      for (final point in data.validPoints)
        NomogramObservedPoint(
          xIntensityPercent: point.intensityPercent,
          ySlope: point.interpretedSlope,
          label: point.taskName ?? point.date,
          classification: point.classification,
          sessionId: point.sessionId,
          athleteName: data.athleteName,
        ),
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Nomogram Overlay',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                DropdownButton<PopulationNomogramSource>(
                  value: _preset,
                  items: const [
                    DropdownMenuItem(
                      value: PopulationNomogramSource.excelOperational,
                      child: Text('Excel'),
                    ),
                    DropdownMenuItem(
                      value: PopulationNomogramSource.slopeOrellana19,
                      child: Text('slope_Orellana_19'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) _changePreset(value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _modeGuidance(data),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            NomogramChart(
              preset: data.populationPreset,
              observedPoints: points,
              individualCurvePoints: _chartCurve(data.individualCurvePoints),
              hybridCurvePoints: _chartCurve(data.hybridCurvePoints),
              showIndividualCurve: showIndividual,
              showHybridCurve: showHybrid,
            ),
          ],
        ),
      ),
    );
  }

  Widget _pointsList(IndividualNomogramData data) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Valid Points',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (data.validPoints.isEmpty)
              const Text(
                'No valid points yet. Sessions need intensity percent and interpreted slope.',
                style: TextStyle(color: AppColors.textHint),
              )
            else
              for (final point in data.validPoints)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(point.taskName ?? point.date),
                  subtitle: Text(
                    [
                      point.date,
                      '${point.intensityPercent.toStringAsFixed(1)}%',
                      'Slope ${point.interpretedSlope.toStringAsFixed(3)}',
                      'Population residual ${_fixed(point.residualPopulation, 3)}',
                      if (point.residualIndividual != null)
                        'Individual residual ${_fixed(point.residualIndividual, 3)}',
                      if (point.residualHybrid != null)
                        'Hybrid residual ${_fixed(point.residualHybrid, 3)}',
                    ].join(' · '),
                  ),
                  trailing: Text(_classificationLabel(point.classification)),
                ),
          ],
        ),
      ),
    );
  }

  Widget _excludedList(IndividualNomogramData data) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Excluded Sessions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (data.excludedSessions.isEmpty)
              const Text(
                'No sessions excluded from fitting.',
                style: TextStyle(color: AppColors.textHint),
              )
            else
              for (final session in data.excludedSessions)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(session.taskName ?? session.date),
                  subtitle: Text(session.date),
                  trailing: Text(session.reason.label),
                ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportCsv() async {
    final data = _data;
    if (data == null) return;
    final writer = ExportFileWriter();
    final points = await writer.writeCsv(
      exportIndividualNomogramValidPointsCsv(data),
    );
    await writer.writeCsv(exportIndividualNomogramExcludedCsv(data));
    await writer.writeCsv(exportIndividualNomogramSummaryCsv(data));
    await writer.writeCsv(exportIndividualNomogramCurvePointsCsv(data));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('CSV exported to ${points.path} and related files'),
      ),
    );
  }
}

Widget _row(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        SizedBox(
          width: 135,
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

Widget _chip(String label, num value, {int digits = 0}) {
  final display = value is double ? value.toStringAsFixed(digits) : '$value';
  return Chip(label: Text('$label: $display'));
}

List<NomogramCurveOverlayPoint> _chartCurve(
  List<IndividualNomogramCurvePoint> points,
) {
  return [
    for (final point in points)
      NomogramCurveOverlayPoint(
        intensityPercent: point.intensityPercent,
        slope: point.slope,
      ),
  ];
}

String _modeGuidance(IndividualNomogramData data) {
  switch (data.summary.recommendedMode) {
    case IndividualNomogramRecommendedMode.populationOnly:
      return 'Population-only mode: athlete points are shown, but no individual curve is used yet.';
    case IndividualNomogramRecommendedMode.hybrid:
      return 'Hybrid mode: expected slope blends population reference and athlete history.';
    case IndividualNomogramRecommendedMode.individual:
      return 'Individual model mode: athlete-specific fit is primary, with population bands retained as context.';
  }
}

String _fixed(double? value, int digits) =>
    value == null ? '-' : value.toStringAsFixed(digits);

String _classificationLabel(String? value) {
  return recoveryResponseShortLabelForClassificationKey(value);
}
