library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hrv_slope_app/ui/theme/app_theme.dart';

class LongitudinalChartPoint {
  final String label;
  final double? value;
  final Color? color;

  const LongitudinalChartPoint({
    required this.label,
    required this.value,
    this.color,
  });
}

class LongitudinalChart extends StatelessWidget {
  final String title;
  final String valueLabel;
  final List<LongitudinalChartPoint> points;
  final String emptyMessage;

  const LongitudinalChart({
    super.key,
    required this.title,
    required this.valueLabel,
    required this.points,
    this.emptyMessage = 'Not enough complete sessions to draw this trend.',
  });

  @override
  Widget build(BuildContext context) {
    final valid = <({int index, LongitudinalChartPoint point})>[];
    for (var i = 0; i < points.length; i++) {
      if (points[i].value != null) valid.add((index: i, point: points[i]));
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            if (valid.length < 2)
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
                    minY: 0,
                    maxY: _maxY(valid),
                    lineBarsData: [
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
                          getDotPainter: (spot, xPercentage, bar, indexInBar) {
                            final point = valid
                                .firstWhere(
                                  (item) => item.index.toDouble() == spot.x,
                                )
                                .point;
                            return FlDotCirclePainter(
                              radius: 4,
                              color: point.color ?? AppColors.tertiary,
                              strokeWidth: 1,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                      ),
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
                        axisNameWidget: const Text(
                          'Sessions',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
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
                              '${index + 1}',
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
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        sideTitles: const SideTitles(
                          showTitles: true,
                          reservedSize: 36,
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
                    lineTouchData: const LineTouchData(enabled: false),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            const Text(
              'Line: session trend · Dots: available values',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  double _maxY(List<({int index, LongitudinalChartPoint point})> valid) {
    final max = valid
        .map((item) => item.point.value!)
        .reduce((a, b) => a > b ? a : b);
    if (max <= 0) return 1;
    return max * 1.25;
  }
}
