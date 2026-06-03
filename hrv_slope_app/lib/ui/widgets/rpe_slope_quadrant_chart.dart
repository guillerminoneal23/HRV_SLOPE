library;

import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hrv_slope_app/shared/engine/longitudinal_builder.dart';
import 'package:hrv_slope_app/ui/theme/app_theme.dart';

class RpeSlopeQuadrantChart extends StatelessWidget {
  final RpeSlopeQuadrantData data;
  final int? selectedSessionId;
  final ValueChanged<int>? onPointSelected;

  const RpeSlopeQuadrantChart({
    super.key,
    required this.data,
    this.selectedSessionId,
    this.onPointSelected,
  });

  @override
  Widget build(BuildContext context) {
    final points = data.plottablePoints.toList();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'RPE vs Slope response',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            const Text(
              "Y-axis shows observed slope relative to the slope_Orellana_19 reference for each session's primary intensity.",
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            const Text(
              'X-axis: RPE 1-10 · Y-axis: observed slope / slope_Orellana_19 reference · RPE threshold: 7.0 · Expected response line: 1.0',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Quadrants combine perceived effort and slope response: left = lower RPE, right = high RPE, above 1.0 = adequate/favorable slope response, below 1.0 = lower-than-expected slope response.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _SummaryPill('${data.summary.pointsShown} points shown'),
                _SummaryPill('${data.summary.missingRpe} missing RPE'),
                _SummaryPill(
                  '${data.summary.missingReference} missing reference',
                ),
                _SummaryPill(
                  'High RPE threshold: ${data.highRpeThreshold.toStringAsFixed(1)}',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _SummaryPill(
                  '${data.summary.lowRpeFavorableSlopeResponse} low/moderate RPE + adequate/favorable',
                ),
                _SummaryPill(
                  '${data.summary.highRpeFavorableSlopeResponse} high RPE + adequate/favorable',
                ),
                _SummaryPill(
                  '${data.summary.highRpeLowSlopeResponse} high RPE + lower-than-expected',
                ),
                _SummaryPill(
                  '${data.summary.lowRpeLowSlopeResponse} low/moderate RPE + lower-than-expected',
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (points.isEmpty)
              _EmptyQuadrantState(omittedSessions: data.summary.omittedSessions)
            else ...[
              SizedBox(height: 260, child: LineChart(_chartData(points))),
              const SizedBox(height: 10),
              const Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _LineLegendItem(label: 'RPE threshold'),
                  _LineLegendItem(label: 'Expected slope response = 1.0'),
                  _ZoneLegendItem(
                    color: AppColors.warning,
                    label: 'Lower-than-expected',
                    detail: 'recovery response below reference',
                  ),
                  _ZoneLegendItem(
                    color: AppColors.primary,
                    label: 'Expected',
                    detail: 'recovery response within reference',
                  ),
                  _ZoneLegendItem(
                    color: AppColors.success,
                    label: 'Favorable',
                    detail: 'recovery response above favorable threshold',
                  ),
                  _ZoneLegendItem(
                    color: AppColors.textHint,
                    label: 'Unavailable',
                    detail: 'reference cannot be calculated',
                  ),
                ],
              ),
              if (data.summary.omittedSessions > 0) ...[
                const SizedBox(height: 8),
                const Text(
                  'Some sessions were omitted because RPE or reference slope was unavailable.',
                  style: TextStyle(fontSize: 12, color: AppColors.textHint),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  LineChartData _chartData(List<RpeSlopeQuadrantPoint> points) {
    final yValues = <double>[
      1.0,
      for (final point in points) point.slopeResponseIndex!,
    ];
    final yMinRaw = yValues.reduce(math.min);
    final yMaxRaw = yValues.reduce(math.max);
    final yPad = math.max(0.15, (yMaxRaw - yMinRaw) * 0.18);
    final yMin = math.max(0.0, yMinRaw - yPad);
    final yMax = yMaxRaw + yPad;
    final yInterval = _axisInterval(yMin, yMax);

    return LineChartData(
      minX: 1,
      maxX: 10,
      minY: yMin,
      maxY: yMax,
      lineBarsData: [
        LineChartBarData(
          spots: [
            for (final point in points)
              FlSpot(point.rpe!, point.slopeResponseIndex!),
          ],
          isCurved: false,
          color: Colors.transparent,
          barWidth: 0,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, xPercentage, bar, indexInBar) {
              final point = _pointAt(points, indexInBar);
              final selected = point?.sessionId == selectedSessionId;
              return FlDotCirclePainter(
                radius: selected ? 6 : 4.5,
                color: _zoneColor(point?.recoveryZone),
                strokeWidth: selected ? 2 : 1,
                strokeColor: Colors.white,
              );
            },
          ),
        ),
      ],
      extraLinesData: ExtraLinesData(
        horizontalLines: [
          HorizontalLine(
            y: 1.0,
            color: AppColors.textSecondary.withValues(alpha: 0.65),
            strokeWidth: 1,
            dashArray: const [6, 4],
          ),
        ],
        verticalLines: [
          VerticalLine(
            x: data.highRpeThreshold,
            color: AppColors.textSecondary.withValues(alpha: 0.65),
            strokeWidth: 1,
            dashArray: const [6, 4],
          ),
        ],
      ),
      gridData: FlGridData(
        show: true,
        horizontalInterval: yInterval,
        verticalInterval: 1,
        getDrawingHorizontalLine: (_) => FlLine(
          color: AppColors.cardBorder.withValues(alpha: 0.4),
          strokeWidth: 0.5,
        ),
        getDrawingVerticalLine: (_) => FlLine(
          color: AppColors.cardBorder.withValues(alpha: 0.25),
          strokeWidth: 0.5,
        ),
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          axisNameWidget: const Text(
            'RPE 1-10',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          axisNameSize: 20,
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            reservedSize: 30,
            getTitlesWidget: (value, _) {
              if (value < 1 || value > 10 || value % 1 != 0) {
                return const SizedBox.shrink();
              }
              return Text(
                value.toInt().toString(),
                style: const TextStyle(fontSize: 10, color: AppColors.textHint),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          axisNameWidget: const Text(
            'Slope response index',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          sideTitles: SideTitles(
            showTitles: true,
            interval: yInterval,
            reservedSize: 42,
            getTitlesWidget: (value, _) => Text(
              value.toStringAsFixed(1),
              style: const TextStyle(fontSize: 10, color: AppColors.textHint),
            ),
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: AppColors.cardBorder, width: 0.5),
      ),
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          maxContentWidth: 220,
          getTooltipItems: (spots) {
            return [
              for (final spot in spots)
                LineTooltipItem(
                  _tooltipText(_pointAt(points, spot.spotIndex)),
                  const TextStyle(color: Colors.white, fontSize: 11),
                ),
            ];
          },
        ),
        touchCallback: (event, response) {
          if (event is! FlTapDownEvent && event is! FlTapUpEvent) {
            return;
          }
          final spot = response?.lineBarSpots?.firstOrNull;
          if (spot == null) return;
          final point = _pointAt(points, spot.spotIndex);
          if (point == null) return;
          onPointSelected?.call(point.sessionId);
        },
      ),
    );
  }

  RpeSlopeQuadrantPoint? _pointAt(
    List<RpeSlopeQuadrantPoint> points,
    int index,
  ) {
    if (index < 0 || index >= points.length) return null;
    return points[index];
  }

  String _tooltipText(RpeSlopeQuadrantPoint? point) {
    if (point == null) return 'Session unavailable';
    return [
      point.date,
      point.sessionTaskName ?? 'Session',
      'RPE: ${_fixed(point.rpe, 1)}',
      'Slope: ${_fixed(point.observedSlope, 3)}',
      'Response index: ${_fixed(point.slopeResponseIndex, 2)}',
      'Response: ${point.recoveryZone.label}',
      _intensityLine(point),
    ].join('\n');
  }

  String _intensityLine(RpeSlopeQuadrantPoint point) {
    final metric = point.primaryIntensityMetric == null
        ? '-'
        : _metricLabel(point.primaryIntensityMetric!);
    return 'Intensity: ${_fixed(point.primaryIntensityValue, 1)}% · $metric · ${_sourceLabel(point.intensitySourceForSlope)}';
  }
}

class _EmptyQuadrantState extends StatelessWidget {
  final int omittedSessions;

  const _EmptyQuadrantState({required this.omittedSessions});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'No sessions with both RPE and slope_Orellana_19 reference are available for the quadrant chart.',
            style: TextStyle(color: AppColors.textHint),
          ),
          if (omittedSessions > 0) ...[
            const SizedBox(height: 6),
            const Text(
              'Some sessions were omitted because RPE or reference slope was unavailable.',
              style: TextStyle(fontSize: 12, color: AppColors.textHint),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final String label;

  const _SummaryPill(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}

class _LineLegendItem extends StatelessWidget {
  final String label;

  const _LineLegendItem({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 0,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: AppColors.textSecondary.withValues(alpha: 0.75),
                width: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _ZoneLegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String detail;

  const _ZoneLegendItem({
    required this.color,
    required this.label,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: $detail',
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

double _axisInterval(double min, double max) {
  final range = max - min;
  if (range <= 0.5) return 0.1;
  if (range <= 1.0) return 0.2;
  if (range <= 2.0) return 0.5;
  return 1.0;
}

Color _zoneColor(LongitudinalRecoveryZone? zone) {
  switch (zone) {
    case LongitudinalRecoveryZone.low:
      return AppColors.warning;
    case LongitudinalRecoveryZone.normal:
      return AppColors.primary;
    case LongitudinalRecoveryZone.favorable:
      return AppColors.success;
    case LongitudinalRecoveryZone.unavailable:
    case null:
      return AppColors.textHint;
  }
}

String _sourceLabel(String source) {
  return switch (source) {
    'External' => 'External load',
    'Internal' => 'Internal load',
    'Unknown' => 'Unknown',
    _ => _humanize(source),
  };
}

String _metricLabel(String metric) {
  return switch (metric) {
    'direct_percent_mas' || 'percent_mas' => '%MAS',
    'internal_rpe_1_10' || 'rpe_1_10' => 'RPE 1-10',
    'session_rpe_1_10' => 'Session RPE 1-10',
    'percent_map' => '%MAP',
    'percent_vvo2max' || 'percent_vvo2_max' => '%vVO2max',
    'percent_vam' => '%VAM',
    'subjective_fatigue_1_10' || 'internal_fatigue_1_10' => 'Fatigue 1-10',
    'subjective_intensity_1_10' => 'Subjective intensity 1-10',
    'subjective_intensity_percent' => 'Subjective intensity %',
    'internal_load_percent' => 'Internal load %',
    'percent_hrmax' || 'percent_hr_max' => '%HRmax',
    'speed_kmh' => 'Speed',
    'power_w' => 'Power',
    _ => _humanize(metric),
  };
}

String _humanize(String value) {
  final words = value
      .replaceAll(RegExp(r'[_-]+'), ' ')
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();
  return words
      .map((word) {
        final lower = word.toLowerCase();
        if (lower == 'rpe') return 'RPE';
        if (lower == 'itl') return 'ITL';
        if (lower == 'hrv') return 'HRV';
        if (lower == 'mas') return 'MAS';
        if (lower == 'map') return 'MAP';
        if (lower == 'vam') return 'VAM';
        if (lower == 'vvo2max') return 'vVO2max';
        if (lower == 'hrmax') return 'HRmax';
        if (lower == 'kmh') return 'km/h';
        return '${lower[0].toUpperCase()}${lower.substring(1)}';
      })
      .join(' ');
}

String _fixed(double? value, int digits) =>
    value == null ? '-' : value.toStringAsFixed(digits);
