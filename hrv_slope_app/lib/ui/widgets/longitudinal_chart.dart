library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hrv_slope_app/ui/theme/app_theme.dart';

class LongitudinalChartPoint {
  final int? sessionId;
  final String label;
  final double? value;
  final Color? color;
  final String? tooltip;

  const LongitudinalChartPoint({
    this.sessionId,
    required this.label,
    required this.value,
    this.color,
    this.tooltip,
  });
}

class LongitudinalChartReferenceSeries {
  final String label;
  final List<LongitudinalChartPoint> points;
  final Color color;

  const LongitudinalChartReferenceSeries({
    required this.label,
    required this.points,
    required this.color,
  });
}

class LongitudinalChartYAxisScale {
  final double minY;
  final double maxY;
  final double? interval;

  const LongitudinalChartYAxisScale({
    required this.minY,
    required this.maxY,
    this.interval,
  });
}

LongitudinalChartYAxisScale resolveLongitudinalYAxisScale(
  Iterable<double?> values, {
  double? yMin,
  double? yMax,
  double? yInterval,
}) {
  final valid = values.whereType<double>().toList();
  if (valid.isEmpty) {
    return LongitudinalChartYAxisScale(
      minY: yMin ?? 0,
      maxY: yMax ?? 1,
      interval: yInterval,
    );
  }

  final minValue = valid.reduce((a, b) => a < b ? a : b);
  final maxValue = valid.reduce((a, b) => a > b ? a : b);
  final range = (maxValue - minValue).abs();
  final padding = range == 0 ? _singleValuePadding(maxValue) : range * 0.12;

  var resolvedMin = yMin ?? (minValue < 0 ? minValue - padding : 0);
  var resolvedMax = yMax ?? (maxValue <= 0 ? 0 : maxValue + padding);

  if ((resolvedMax - resolvedMin).abs() < 1e-9) {
    resolvedMin -= 1;
    resolvedMax += 1;
  }

  return LongitudinalChartYAxisScale(
    minY: _roundDownAxis(resolvedMin),
    maxY: _roundUpAxis(resolvedMax),
    interval: yInterval,
  );
}

double resolvePrimaryIntensityOverlayMax(Iterable<double?> values) {
  final valid = values.whereType<double>().toList();
  if (valid.isEmpty) return 100;
  final maxValue = valid.reduce((a, b) => a > b ? a : b);
  if (maxValue <= 100) return 100;
  return _roundUpToStep(maxValue, 25);
}

double resolvePrimaryIntensityOverlayInterval(double maxY) {
  if (maxY <= 150) return 25;
  return _roundUpToStep(maxY / 5, 25);
}

class LongitudinalChart extends StatelessWidget {
  final String title;
  final String valueLabel;
  final List<LongitudinalChartPoint> points;
  final String emptyMessage;
  final int? selectedSessionId;
  final ValueChanged<int>? onPointSelected;
  final String xAxisLabel;
  final double? yMin;
  final double? yMax;
  final double? yInterval;
  final List<LongitudinalChartReferenceSeries> referenceSeries;
  final Widget? headerTrailing;

  const LongitudinalChart({
    super.key,
    required this.title,
    required this.valueLabel,
    required this.points,
    this.emptyMessage = 'Not enough complete sessions to draw this trend.',
    this.selectedSessionId,
    this.onPointSelected,
    this.xAxisLabel = 'Session order',
    this.yMin,
    this.yMax,
    this.yInterval,
    this.referenceSeries = const [],
    this.headerTrailing,
  });

  @override
  Widget build(BuildContext context) {
    final valid = <({int index, LongitudinalChartPoint point})>[];
    for (var i = 0; i < points.length; i++) {
      if (points[i].value != null) valid.add((index: i, point: points[i]));
    }
    final referenceBars = [
      for (final series in referenceSeries) ..._referenceBars(series),
    ];
    final hasReferenceLine = referenceBars.any((bar) => bar.spots.length >= 2);
    final yScale = resolveLongitudinalYAxisScale(
      [
        ...points.map((point) => point.value),
        for (final series in referenceSeries)
          ...series.points.map((point) => point.value),
      ],
      yMin: yMin,
      yMax: yMax,
      yInterval: yInterval,
    );

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
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (headerTrailing != null) ...[
                  const SizedBox(width: 8),
                  headerTrailing!,
                ],
              ],
            ),
            const SizedBox(height: 12),
            if (valid.length < 2 && !hasReferenceLine)
              Text(
                emptyMessage,
                style: const TextStyle(color: AppColors.textHint),
              )
            else
              SizedBox(
                height: 220,
                child: LineChart(
                  LineChartData(
                    minX: 0,
                    maxX: (points.length - 1).toDouble(),
                    minY: yScale.minY,
                    maxY: yScale.maxY,
                    lineBarsData: [
                      if (valid.isNotEmpty)
                        LineChartBarData(
                          spots: [
                            for (final item in valid)
                              FlSpot(item.index.toDouble(), item.point.value!),
                          ],
                          isCurved: false,
                          color: AppColors.primary,
                          barWidth: 2,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter:
                                (spot, xPercentage, bar, indexInBar) {
                                  final point = _pointForSpot(spot);
                                  final selected =
                                      point?.sessionId != null &&
                                      point?.sessionId == selectedSessionId;
                                  return FlDotCirclePainter(
                                    radius: selected ? 6 : 4,
                                    color: point?.color ?? AppColors.tertiary,
                                    strokeWidth: selected ? 2 : 1,
                                    strokeColor: Colors.white,
                                  );
                                },
                          ),
                        ),
                      ...referenceBars,
                    ],
                    gridData: FlGridData(
                      show: true,
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
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        axisNameWidget: const Text(''),
                        axisNameSize: 0,
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          interval: (points.length / 4).ceilToDouble(),
                          getTitlesWidget: (value, _) {
                            final index = value.round();
                            if (index < 0 || index >= points.length) {
                              return const SizedBox.shrink();
                            }
                            return Text(
                              xAxisLabel == 'Date'
                                  ? _shortDate(points[index].label)
                                  : '${index + 1}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textHint,
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        axisNameWidget: Text(
                          valueLabel,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 36,
                          interval: yScale.interval,
                          getTitlesWidget: (value, _) => Text(
                            _formatAxis(value),
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textHint,
                            ),
                          ),
                        ),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(
                        color: AppColors.cardBorder,
                        width: 0.5,
                      ),
                    ),
                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (spots) {
                          return [
                            for (final spot in spots)
                              LineTooltipItem(
                                _tooltipFor(spot),
                                const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                          ];
                        },
                      ),
                      touchCallback: (event, response) {
                        if (event is! FlTapDownEvent &&
                            event is! FlTapUpEvent) {
                          return;
                        }
                        final spot = response?.lineBarSpots?.firstOrNull;
                        if (spot == null) return;
                        final point = _pointForSpot(spot);
                        if (point == null) return;
                        final sessionId = point.sessionId;
                        if (sessionId != null) onPointSelected?.call(sessionId);
                      },
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            if (referenceSeries.isNotEmpty) ...[
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  _legendItem('Observed $valueLabel', AppColors.primary),
                  for (final series in referenceSeries)
                    if (series.points.any((point) => point.value != null))
                      _legendItem(series.label, series.color),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Text(
              'Line: session trend · Dots: available values · X-axis: $xAxisLabel',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  List<LineChartBarData> _referenceBars(
    LongitudinalChartReferenceSeries series,
  ) {
    final bars = <LineChartBarData>[];
    var segment = <FlSpot>[];

    void flushSegment() {
      if (segment.isEmpty) return;
      bars.add(_referenceBar(series, segment));
      segment = <FlSpot>[];
    }

    for (var i = 0; i < series.points.length; i++) {
      final value = series.points[i].value;
      if (value == null) {
        flushSegment();
      } else {
        segment.add(FlSpot(i.toDouble(), value));
      }
    }
    flushSegment();
    return bars;
  }

  LineChartBarData _referenceBar(
    LongitudinalChartReferenceSeries series,
    List<FlSpot> spots,
  ) {
    return LineChartBarData(
      spots: spots,
      isCurved: false,
      color: series.color,
      barWidth: 1.6,
      dotData: const FlDotData(show: false),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 18, height: 3, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  String _tooltipFor(LineBarSpot spot) {
    final point = _pointForSpot(spot);
    if (point == null) {
      final touchedValue = spot.y.isFinite ? spot.y.toStringAsFixed(2) : '-';
      return '$valueLabel: $touchedValue';
    }
    return point.tooltip ??
        '${point.label}\n$valueLabel: ${point.value?.toStringAsFixed(2) ?? '-'}';
  }

  LongitudinalChartPoint? _pointForSpot(FlSpot spot) {
    if (!spot.x.isFinite) return null;
    final index = spot.x.round();
    if (index < 0 || index >= points.length) return null;
    return points[index];
  }

  String _formatAxis(double value) {
    if ((value - value.round()).abs() < 1e-9) return value.round().toString();
    return value.toStringAsFixed(1);
  }

  String _shortDate(String value) {
    if (value.length >= 10) return value.substring(5, 10);
    return value;
  }
}

double _singleValuePadding(double value) {
  final magnitude = value.abs();
  if (magnitude < 1) return 1;
  return magnitude * 0.25;
}

double _roundDownAxis(double value) {
  if (value >= 0) return value;
  final step = _axisStep(value.abs());
  return (value / step).floor() * step;
}

double _roundUpAxis(double value) {
  if (value <= 0) return value;
  final step = _axisStep(value.abs());
  return (value / step).ceil() * step;
}

double _axisStep(double magnitude) {
  if (magnitude <= 1) return 0.1;
  if (magnitude <= 5) return 0.5;
  if (magnitude <= 20) return 1;
  if (magnitude <= 100) return 5;
  return 25;
}

double _roundUpToStep(double value, double step) {
  return (value / step).ceil() * step;
}
