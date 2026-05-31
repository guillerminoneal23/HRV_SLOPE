/// Population Nomogram Chart — fl_chart-based visualization.
///
/// Renders lower, mean, upper population bands and an optional observed
/// session point on an intensity vs slope chart.
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hrv_slope_app/shared/engine/nomogram_engine.dart';
import 'package:hrv_slope_app/ui/theme/app_theme.dart';

class NomogramObservedPoint {
  final double xIntensityPercent;
  final double ySlope;
  final String label;
  final String? classification;
  final int? sessionId;
  final String? athleteName;

  const NomogramObservedPoint({
    required this.xIntensityPercent,
    required this.ySlope,
    required this.label,
    this.classification,
    this.sessionId,
    this.athleteName,
  });
}

class NomogramCurveOverlayPoint {
  final double intensityPercent;
  final double slope;

  const NomogramCurveOverlayPoint({
    required this.intensityPercent,
    required this.slope,
  });
}

/// A reusable nomogram chart widget.
///
/// If [observedIntensity] and [observedSlope] are provided, the session
/// point is plotted. Otherwise only population curves are drawn.
class NomogramChart extends StatelessWidget {
  final PopulationNomogramSource preset;
  final double? observedIntensity;
  final double? observedSlope;
  final List<NomogramObservedPoint> observedPoints;
  final List<NomogramCurveOverlayPoint> individualCurvePoints;
  final List<NomogramCurveOverlayPoint> hybridCurvePoints;
  final bool showIndividualCurve;
  final bool showHybridCurve;

  const NomogramChart({
    super.key,
    required this.preset,
    this.observedIntensity,
    this.observedSlope,
    this.observedPoints = const [],
    this.individualCurvePoints = const [],
    this.hybridCurvePoints = const [],
    this.showIndividualCurve = false,
    this.showHybridCurve = false,
  });

  @override
  Widget build(BuildContext context) {
    final points = [
      ...observedPoints,
      if (observedIntensity != null && observedSlope != null)
        NomogramObservedPoint(
          xIntensityPercent: observedIntensity!,
          ySlope: observedSlope!,
          label: 'Session',
        ),
    ];

    // Determine X-axis range from preset
    final range = _rangeFor(preset);
    final xMin = range.start;
    final xMax = range.end;

    // Sample points for smooth curves
    final steps = 80;
    final dx = (xMax - xMin) / steps;

    final lowerSpots = <FlSpot>[];
    final meanSpots = <FlSpot>[];
    final upperSpots = <FlSpot>[];
    final individualSpots = individualCurvePoints
        .map((point) => FlSpot(point.intensityPercent, point.slope))
        .toList();
    final hybridSpots = hybridCurvePoints
        .map((point) => FlSpot(point.intensityPercent, point.slope))
        .toList();

    for (int i = 0; i <= steps; i++) {
      final x = xMin + i * dx;
      final bands = evaluatePopulationNomogramBands(x, source: preset);
      lowerSpots.add(FlSpot(x, bands.expectedLower));
      meanSpots.add(FlSpot(x, bands.expectedMean));
      upperSpots.add(FlSpot(x, bands.expectedUpper));
    }

    // Determine Y range
    double yMax = 3.0;
    if (upperSpots.isNotEmpty) {
      final maxY = upperSpots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
      yMax = (maxY * 1.2).ceilToDouble();
      if (yMax < 1.0) yMax = 1.0;
    }
    if (observedSlope != null && observedSlope! > yMax * 0.9) {
      yMax = (observedSlope! * 1.3).ceilToDouble();
    }
    for (final spot in [
      if (showIndividualCurve) ...individualSpots,
      if (showHybridCurve) ...hybridSpots,
    ]) {
      if (spot.y > yMax * 0.9) {
        yMax = (spot.y * 1.3).ceilToDouble();
      }
    }
    for (final point in points) {
      if (point.ySlope > yMax * 0.9) {
        yMax = (point.ySlope * 1.3).ceilToDouble();
      }
    }

    // Build line data
    final lines = <LineChartBarData>[
      // Lower band
      _bandLine(lowerSpots, AppColors.classVeryHigh.withValues(alpha: 0.7)),
      // Mean band
      _bandLine(meanSpots, AppColors.success),
      // Upper band
      _bandLine(upperSpots, AppColors.classLowFast.withValues(alpha: 0.7)),
    ];
    if (showIndividualCurve && individualSpots.isNotEmpty) {
      lines.add(_bandLine(individualSpots, AppColors.tertiary, width: 3));
    }
    if (showHybridCurve && hybridSpots.isNotEmpty) {
      lines.add(_bandLine(hybridSpots, AppColors.secondary, width: 3));
    }

    // Between-area shading: fill between lower and upper
    final betweenData = <BetweenBarsData>[
      BetweenBarsData(
        fromIndex: 0,
        toIndex: 2,
        color: AppColors.success.withValues(alpha: 0.06),
      ),
    ];

    // Session points. Each point is drawn as a one-spot transparent line with
    // visible dot so the chart supports both single and grouped reports.
    for (final point in points) {
      lines.add(
        LineChartBarData(
          spots: [FlSpot(point.xIntensityPercent, point.ySlope)],
          isCurved: false,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, xPercentage, bar, index) =>
                FlDotCirclePainter(
                  radius: 6,
                  color: _pointColor(point.classification),
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                ),
          ),
          barWidth: 0,
          color: Colors.transparent,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 260,
          child: LineChart(
            LineChartData(
              minX: xMin,
              maxX: xMax,
              minY: 0,
              maxY: yMax,
              lineBarsData: lines,
              betweenBarsData: betweenData,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                horizontalInterval: yMax > 2 ? 0.5 : 0.2,
                verticalInterval: 10,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: AppColors.cardBorder.withValues(alpha: 0.4),
                  strokeWidth: 0.5,
                ),
                getDrawingVerticalLine: (_) => FlLine(
                  color: AppColors.cardBorder.withValues(alpha: 0.4),
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
                    'Intensity (%)',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 10,
                    reservedSize: 28,
                    getTitlesWidget: (v, _) => Text(
                      '${v.toInt()}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textHint,
                      ),
                    ),
                  ),
                ),
                leftTitles: AxisTitles(
                  axisNameWidget: const Text(
                    'RMSSD-Slope',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: yMax > 2 ? 0.5 : 0.2,
                    reservedSize: 36,
                    getTitlesWidget: (v, _) => Text(
                      v.toStringAsFixed(1),
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
                border: Border.all(color: AppColors.cardBorder, width: 0.5),
              ),
              lineTouchData: const LineTouchData(enabled: false),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Legend
        _legend(),
      ],
    );
  }

  Widget _legend() {
    return Wrap(
      spacing: 16,
      runSpacing: 4,
      children: [
        _legendItem(
          'Lower band',
          AppColors.classVeryHigh.withValues(alpha: 0.7),
        ),
        _legendItem('Mean', AppColors.success),
        _legendItem(
          'Upper band',
          AppColors.classLowFast.withValues(alpha: 0.7),
        ),
        if (observedIntensity != null && observedSlope != null)
          _legendItem('Session', AppColors.tertiary, isDot: true),
        if (observedPoints.isNotEmpty)
          _legendItem('Session points', AppColors.tertiary, isDot: true),
        if (showIndividualCurve && individualCurvePoints.isNotEmpty)
          _legendItem('Individual fit', AppColors.tertiary),
        if (showHybridCurve && hybridCurvePoints.isNotEmpty)
          _legendItem('Hybrid expected', AppColors.secondary),
      ],
    );
  }

  Widget _legendItem(String label, Color color, {bool isDot = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isDot)
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1),
            ),
          )
        else
          Container(width: 16, height: 3, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  LineChartBarData _bandLine(
    List<FlSpot> spots,
    Color color, {
    double width = 2,
  }) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.2,
      color: color,
      barWidth: width,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
    );
  }

  ({double start, double end}) _rangeFor(PopulationNomogramSource preset) {
    switch (preset) {
      case PopulationNomogramSource.excelOperational:
        return (start: 55.0, end: 105.0);
      case PopulationNomogramSource.paperOriginal2019:
        return (start: 60.0, end: 105.0);
    }
  }

  Color _pointColor(String? classification) {
    switch (classification) {
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
}
