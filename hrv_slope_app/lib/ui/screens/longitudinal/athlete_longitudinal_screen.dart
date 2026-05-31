library;

import 'package:flutter/material.dart';
import 'package:hrv_slope_app/data/database/app_database.dart';
import 'package:hrv_slope_app/data/export/csv_export_service.dart';
import 'package:hrv_slope_app/data/export/export_file_writer.dart';
import 'package:hrv_slope_app/shared/engine/longitudinal_builder.dart';
import 'package:hrv_slope_app/ui/screens/nomogram/individual_nomogram_screen.dart';
import 'package:hrv_slope_app/ui/screens/reports/individual_report_screen.dart';
import 'package:hrv_slope_app/ui/theme/app_theme.dart';
import 'package:hrv_slope_app/ui/widgets/longitudinal_chart.dart';

enum _OverlayMetric { intensity, rpe, srpe, trimp }

class AthleteLongitudinalScreen extends StatefulWidget {
  final AppDatabase database;
  final int athleteId;

  const AthleteLongitudinalScreen({
    super.key,
    required this.database,
    required this.athleteId,
  });

  @override
  State<AthleteLongitudinalScreen> createState() =>
      _AthleteLongitudinalScreenState();
}

class _AthleteLongitudinalScreenState extends State<AthleteLongitudinalScreen> {
  LongitudinalSeries? _series;
  Athlete? _athlete;
  bool _loading = true;
  _OverlayMetric _overlay = _OverlayMetric.intensity;

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
    final details = await widget.database.sessionsDao
        .getSessionDetailsForAthlete(widget.athleteId);
    final series = buildLongitudinalSeries(athlete: athlete, details: details);
    if (mounted) {
      setState(() {
        _athlete = athlete;
        _series = series;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final athlete = _athlete;
    final series = _series;
    if (athlete == null || series == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Longitudinal')),
        body: const Center(child: Text('Athlete not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Longitudinal Dashboard'),
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
          _header(athlete, series),
          _summary(series),
          LongitudinalChart(
            title: 'Slope Trend',
            valueLabel: 'Slope',
            points: [
              for (final point in series.points)
                LongitudinalChartPoint(
                  label: point.date,
                  value: point.interpretedSlope,
                  color: _classificationColor(point.classification),
                ),
            ],
          ),
          LongitudinalChart(
            title: 'ITL Trend',
            valueLabel: 'ITL',
            points: [
              for (final point in series.points)
                LongitudinalChartPoint(
                  label: point.date,
                  value: point.itlIndex,
                  color: AppColors.tertiary,
                ),
            ],
            emptyMessage: 'No ITL values available for this athlete yet.',
          ),
          _overlaySelector(),
          LongitudinalChart(
            title: _overlayTitle(),
            valueLabel: _overlayLabel(),
            points: [
              for (final point in series.points)
                LongitudinalChartPoint(
                  label: point.date,
                  value: _overlayValue(point),
                  color: AppColors.secondary,
                ),
            ],
            emptyMessage: 'No values available for this selected overlay.',
          ),
          _residuals(series),
          _flags(series),
          _sessionList(series),
        ],
      ),
    );
  }

  Widget _header(Athlete athlete, LongitudinalSeries series) {
    final dateRange = series.points.isEmpty
        ? 'No sessions'
        : '${series.points.first.date} to ${series.points.last.date}';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              athlete.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            if (athlete.sport != null)
              Text(
                athlete.sport!,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            const Divider(height: 20),
            _row('Date range', dateRange),
            _row('Sessions', '${series.summary.nSessions}'),
            _row('Complete sessions', '${series.summary.nComplete}'),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => IndividualNomogramScreen(
                      database: widget.database,
                      athleteId: widget.athleteId,
                    ),
                  ),
                ),
                icon: const Icon(Icons.scatter_plot),
                label: const Text('Nomogram'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summary(LongitudinalSeries series) {
    final s = series.summary;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _metric('Latest slope', _fixed(s.latestSlope, 3)),
            _metric('Latest ITL', _fixed(s.latestItl, 3)),
            _metric('Latest class', _classLabel(s.latestClassification)),
            _metric('Mean slope', _fixed(s.meanSlope, 3)),
            _metric('Trend', _trendLabel(s.trendDirection)),
            _metric('Active flags', '${series.fatigueFlags.length}'),
          ],
        ),
      ),
    );
  }

  Widget _overlaySelector() {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DropdownButtonFormField<_OverlayMetric>(
          initialValue: _overlay,
          decoration: const InputDecoration(labelText: 'Load overlay'),
          items: const [
            DropdownMenuItem(
              value: _OverlayMetric.intensity,
              child: Text('Intensity percent'),
            ),
            DropdownMenuItem(value: _OverlayMetric.rpe, child: Text('RPE')),
            DropdownMenuItem(value: _OverlayMetric.srpe, child: Text('sRPE')),
            DropdownMenuItem(value: _OverlayMetric.trimp, child: Text('TRIMP')),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _overlay = value);
          },
        ),
      ),
    );
  }

  Widget _residuals(LongitudinalSeries series) {
    final hasResiduals = series.points.any((point) => point.residual != null);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Residual Trend',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (!hasResiduals)
              const Text(
                'Residuals require intensity percent and interpreted slope.',
                style: TextStyle(color: AppColors.textHint),
              )
            else
              for (final point in series.points)
                if (point.residual != null)
                  _row(
                    point.date,
                    '${point.residual!.toStringAsFixed(3)} '
                    '(${point.residualPercent!.toStringAsFixed(1)}%)',
                    valueColor: point.residual! < 0
                        ? AppColors.warning
                        : AppColors.textPrimary,
                  ),
          ],
        ),
      ),
    );
  }

  Widget _flags(LongitudinalSeries series) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fatigue Flags',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (series.fatigueFlags.isEmpty)
              const Text(
                'No current flags. Continue monitoring training context.',
                style: TextStyle(color: AppColors.textHint),
              )
            else
              for (final flag in series.fatigueFlags)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.warning_amber,
                    color: AppColors.warning,
                  ),
                  title: Text(flag.message),
                  subtitle: Text('${flag.startDate} to ${flag.endDate}'),
                ),
          ],
        ),
      ),
    );
  }

  Widget _sessionList(LongitudinalSeries series) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sessions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (series.points.isEmpty)
              const Text(
                'No sessions yet.',
                style: TextStyle(color: AppColors.textHint),
              )
            else
              for (final point in series.points)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(point.taskName ?? point.date),
                  subtitle: Text(
                    [
                      point.date,
                      'Slope ${_fixed(point.interpretedSlope, 3)}',
                      'ITL ${_fixed(point.itlIndex, 3)}',
                      'Intensity ${_fixed(point.intensityPercent, 1)}%',
                      _classLabel(point.classification),
                    ].join(' · '),
                  ),
                  trailing: TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => IndividualReportScreen(
                          database: widget.database,
                          sessionId: point.sessionId,
                        ),
                      ),
                    ),
                    child: const Text('Open Report'),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  String _overlayTitle() {
    return switch (_overlay) {
      _OverlayMetric.intensity => 'Intensity Overlay',
      _OverlayMetric.rpe => 'RPE Overlay',
      _OverlayMetric.srpe => 'sRPE Overlay',
      _OverlayMetric.trimp => 'TRIMP Overlay',
    };
  }

  String _overlayLabel() {
    return switch (_overlay) {
      _OverlayMetric.intensity => 'Intensity %',
      _OverlayMetric.rpe => 'RPE',
      _OverlayMetric.srpe => 'sRPE',
      _OverlayMetric.trimp => 'TRIMP',
    };
  }

  double? _overlayValue(LongitudinalPoint point) {
    return switch (_overlay) {
      _OverlayMetric.intensity => point.intensityPercent,
      _OverlayMetric.rpe => point.rpe,
      _OverlayMetric.srpe => point.srpe,
      _OverlayMetric.trimp => point.trimp,
    };
  }

  Future<void> _exportCsv() async {
    final series = _series;
    if (series == null) return;
    final writer = ExportFileWriter();
    final rows = await writer.writeCsv(exportLongitudinalCsv(series));
    final flags = await writer.writeCsv(
      exportLongitudinalFatigueFlagsCsv(series),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('CSV exported to ${rows.path} and ${flags.path}')),
    );
  }
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

Widget _row(String label, String value, {Color? valueColor}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(value, style: TextStyle(fontSize: 13, color: valueColor)),
        ),
      ],
    ),
  );
}

String _fixed(double? value, int digits) =>
    value == null ? '-' : value.toStringAsFixed(digits);

String _trendLabel(LongitudinalTrendDirection direction) {
  switch (direction) {
    case LongitudinalTrendDirection.improving:
      return 'Improving';
    case LongitudinalTrendDirection.worsening:
      return 'Worsening';
    case LongitudinalTrendDirection.stable:
      return 'Stable';
    case LongitudinalTrendDirection.insufficientData:
      return 'Insufficient data';
  }
}

String _classLabel(String? value) {
  switch (value) {
    case 'very_high_internal_load':
      return 'Very high internal load';
    case 'high_or_moderate_internal_load':
      return 'High/moderate internal load';
    case 'expected_response':
      return 'Expected response';
    case 'low_internal_load_or_fast_recovery':
      return 'Low internal load / fast recovery';
    default:
      return value ?? '-';
  }
}

Color _classificationColor(String? value) {
  switch (value) {
    case 'very_high_internal_load':
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
