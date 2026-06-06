/// Population Nomogram Chart — fl_chart-based visualization.
///
/// Renders lower, mean, upper population bands and an optional observed
/// session point on an intensity vs slope chart.
library;

import 'dart:math' as math;

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
  final bool isExtrapolated;

  const NomogramObservedPoint({
    required this.xIntensityPercent,
    required this.ySlope,
    required this.label,
    this.classification,
    this.sessionId,
    this.athleteName,
    this.isExtrapolated = false,
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
class NomogramChart extends StatefulWidget {
  final PopulationNomogramSource preset;
  final double? observedIntensity;
  final double? observedSlope;
  final List<NomogramObservedPoint> observedPoints;
  final List<NomogramBandPoint> bandPoints;
  final List<NomogramCurveOverlayPoint> individualCurvePoints;
  final List<NomogramCurveOverlayPoint> hybridCurvePoints;
  final bool showIndividualCurve;
  final bool showHybridCurve;
  final bool showViewportControls;

  const NomogramChart({
    super.key,
    required this.preset,
    this.observedIntensity,
    this.observedSlope,
    this.observedPoints = const [],
    this.bandPoints = const [],
    this.individualCurvePoints = const [],
    this.hybridCurvePoints = const [],
    this.showIndividualCurve = false,
    this.showHybridCurve = false,
    this.showViewportControls = false,
  });

  @override
  State<NomogramChart> createState() => _NomogramChartState();
}

class _NomogramChartState extends State<NomogramChart> {
  double? _viewXMin;
  double? _viewXMax;
  double? _viewYMin;
  double? _viewYMax;

  @override
  Widget build(BuildContext context) {
    final points = [
      ...widget.observedPoints,
      if (widget.observedIntensity != null && widget.observedSlope != null)
        NomogramObservedPoint(
          xIntensityPercent: widget.observedIntensity!,
          ySlope: widget.observedSlope!,
          label: 'Session',
        ),
    ];

    final range = _chartRange(points);
    final fullXMin = range.start;
    final fullXMax = range.end;

    // Sample points for smooth curves
    final steps = 80;
    final dx = (fullXMax - fullXMin) / steps;

    final lowerSpots = widget.bandPoints
        .map((point) => FlSpot(point.intensityPercent, point.lower))
        .toList();
    final meanSpots = widget.bandPoints
        .map((point) => FlSpot(point.intensityPercent, point.mean))
        .toList();
    final upperSpots = widget.bandPoints
        .map((point) => FlSpot(point.intensityPercent, point.upper))
        .toList();
    final individualSpots = widget.individualCurvePoints
        .map((point) => FlSpot(point.intensityPercent, point.slope))
        .toList();
    final hybridSpots = widget.hybridCurvePoints
        .map((point) => FlSpot(point.intensityPercent, point.slope))
        .toList();

    if (widget.bandPoints.isEmpty) {
      for (int i = 0; i <= steps; i++) {
        final x = fullXMin + i * dx;
        final bands = evaluatePopulationNomogramBands(x, source: widget.preset);
        lowerSpots.add(FlSpot(x, bands.expectedLower));
        meanSpots.add(FlSpot(x, bands.expectedMean));
        upperSpots.add(FlSpot(x, bands.expectedUpper));
      }
    }

    final fullYRange = _chartYRange(
      points: points,
      upperSpots: upperSpots,
      lowerSpots: lowerSpots,
      meanSpots: meanSpots,
      individualSpots: individualSpots,
      hybridSpots: hybridSpots,
    );
    final fullYMin = fullYRange.start;
    final fullYMax = fullYRange.end;
    final viewXMin = _clamped(_viewXMin, fullXMin, fullXMax) ?? fullXMin;
    final viewXMax = _clamped(_viewXMax, fullXMin, fullXMax) ?? fullXMax;
    final viewYMin = _clamped(_viewYMin, fullYMin, fullYMax) ?? fullYMin;
    final viewYMax = _clamped(_viewYMax, fullYMin, fullYMax) ?? fullYMax;
    final resolvedXMin = viewXMin < viewXMax ? viewXMin : fullXMin;
    final resolvedXMax = viewXMin < viewXMax ? viewXMax : fullXMax;
    final resolvedYMin = viewYMin < viewYMax ? viewYMin : fullYMin;
    final resolvedYMax = viewYMin < viewYMax ? viewYMax : fullYMax;
    final yInterval = _niceAxisInterval(resolvedYMax - resolvedYMin);

    // Build line data
    final lines = <LineChartBarData>[
      // Lower band
      _bandLine(lowerSpots, AppColors.classVeryHigh.withValues(alpha: 0.7)),
      // Mean band
      _bandLine(meanSpots, AppColors.success),
      // Upper band
      _bandLine(upperSpots, AppColors.classLowFast.withValues(alpha: 0.7)),
    ];
    if (widget.showIndividualCurve && individualSpots.isNotEmpty) {
      lines.add(_bandLine(individualSpots, AppColors.tertiary, width: 3));
    }
    if (widget.showHybridCurve && hybridSpots.isNotEmpty) {
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
    final pointByBarIndex = <int, NomogramObservedPoint>{};
    for (final point in points) {
      final barIndex = lines.length;
      pointByBarIndex[barIndex] = point;
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
        if (widget.showViewportControls) ...[
          _viewportControls(
            fullXMin: fullXMin,
            fullXMax: fullXMax,
            fullYMin: fullYMin,
            fullYMax: fullYMax,
            viewXMin: resolvedXMin,
            viewXMax: resolvedXMax,
            viewYMin: resolvedYMin,
            viewYMax: resolvedYMax,
          ),
          const SizedBox(height: 8),
        ],
        SizedBox(
          height: 260,
          child: LineChart(
            LineChartData(
              minX: resolvedXMin,
              maxX: resolvedXMax,
              minY: resolvedYMin,
              maxY: resolvedYMax,
              lineBarsData: lines,
              betweenBarsData: betweenData,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                horizontalInterval: yInterval,
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
                    interval: yInterval,
                    reservedSize: 58,
                    getTitlesWidget: (v, _) => Text(
                      _formatAxisValue(v, resolvedYMax - resolvedYMin),
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
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  maxContentWidth: 220,
                  getTooltipItems: (spots) {
                    return [
                      for (final spot in spots)
                        _tooltipForPoint(pointByBarIndex[spot.barIndex]),
                    ];
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Legend
        _legend(),
      ],
    );
  }

  Widget _viewportControls({
    required double fullXMin,
    required double fullXMax,
    required double fullYMin,
    required double fullYMax,
    required double viewXMin,
    required double viewXMax,
    required double viewYMin,
    required double viewYMax,
  }) {
    final xEnabled = fullXMax - fullXMin > 1;
    final yEnabled = fullYMax - fullYMin > 0.1;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Viewport',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              TextButton.icon(
                onPressed: _resetViewport,
                icon: const Icon(Icons.fit_screen, size: 16),
                label: const Text('Reset view'),
              ),
            ],
          ),
          _rangeControl(
            label: 'Intensity range',
            valueLabel:
                '${viewXMin.toStringAsFixed(0)}-${viewXMax.toStringAsFixed(0)}%',
            min: fullXMin,
            max: fullXMax,
            values: RangeValues(viewXMin, viewXMax),
            enabled: xEnabled,
            onChanged: (values) {
              final next = _normalizeRange(values, fullXMin, fullXMax, 5);
              setState(() {
                _viewXMin = next.start;
                _viewXMax = next.end;
              });
            },
          ),
          _rangeControl(
            label: 'Slope range',
            valueLabel:
                '${_formatAxisValue(viewYMin, fullYMax - fullYMin)}-${_formatAxisValue(viewYMax, fullYMax - fullYMin)}',
            min: fullYMin,
            max: fullYMax,
            values: RangeValues(viewYMin, viewYMax),
            enabled: yEnabled,
            onChanged: (values) {
              final next = _normalizeRange(values, fullYMin, fullYMax, 0.1);
              setState(() {
                _viewYMin = next.start;
                _viewYMax = next.end;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _rangeControl({
    required String label,
    required String valueLabel,
    required double min,
    required double max,
    required RangeValues values,
    required bool enabled,
    required ValueChanged<RangeValues> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Text(valueLabel, style: const TextStyle(fontSize: 12)),
          ],
        ),
        RangeSlider(
          min: min,
          max: max,
          values: values,
          divisions: enabled ? 20 : null,
          labels: RangeLabels(
            values.start.toStringAsFixed(1),
            values.end.toStringAsFixed(1),
          ),
          onChanged: enabled ? onChanged : null,
        ),
      ],
    );
  }

  void _resetViewport() {
    setState(() {
      _viewXMin = null;
      _viewXMax = null;
      _viewYMin = null;
      _viewYMax = null;
    });
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
        if (widget.observedIntensity != null && widget.observedSlope != null)
          _legendItem('Session', AppColors.tertiary, isDot: true),
        if (widget.observedPoints.isNotEmpty)
          _legendItem('Session points', AppColors.tertiary, isDot: true),
        if (widget.showIndividualCurve &&
            widget.individualCurvePoints.isNotEmpty)
          _legendItem('Individual fit', AppColors.tertiary),
        if (widget.showHybridCurve && widget.hybridCurvePoints.isNotEmpty)
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
      case PopulationNomogramSource.slopeOrellana19:
        return (start: 60.0, end: 105.0);
    }
  }

  ({double start, double end}) _chartRange(List<NomogramObservedPoint> points) {
    final presetRange = _rangeFor(widget.preset);
    var start = presetRange.start;
    var end = presetRange.end;

    for (final point in points) {
      if (point.xIntensityPercent < start) start = point.xIntensityPercent;
      if (point.xIntensityPercent > end) end = point.xIntensityPercent;
    }
    for (final point in widget.bandPoints) {
      if (point.intensityPercent < start) start = point.intensityPercent;
      if (point.intensityPercent > end) end = point.intensityPercent;
    }

    start = (start / 5).floor() * 5.0;
    end = (end / 5).ceil() * 5.0;
    if ((end - start).abs() < 1e-9) {
      end = start + 5;
    }
    return (start: start, end: end);
  }

  ({double start, double end}) _chartYRange({
    required List<NomogramObservedPoint> points,
    required List<FlSpot> upperSpots,
    required List<FlSpot> lowerSpots,
    required List<FlSpot> meanSpots,
    required List<FlSpot> individualSpots,
    required List<FlSpot> hybridSpots,
  }) {
    final values = <double>[
      0.0,
      ...lowerSpots.map((spot) => spot.y),
      ...meanSpots.map((spot) => spot.y),
      ...upperSpots.map((spot) => spot.y),
      if (widget.showIndividualCurve) ...individualSpots.map((spot) => spot.y),
      if (widget.showHybridCurve) ...hybridSpots.map((spot) => spot.y),
      ...points.map((point) => point.ySlope),
    ];
    final maxValue = values.reduce(math.max);
    final minValue = math.min(0.0, values.reduce(math.min));
    final range = math.max(0.5, maxValue - minValue);
    final paddedMax = maxValue + range * 0.16;
    final roundedMax = _roundUpToNice(paddedMax);
    return (start: minValue, end: math.max(1.0, roundedMax));
  }

  RangeValues _normalizeRange(
    RangeValues values,
    double min,
    double max,
    double minSpan,
  ) {
    var start = values.start.clamp(min, max).toDouble();
    var end = values.end.clamp(min, max).toDouble();
    if (end - start < minSpan) {
      if (start + minSpan <= max) {
        end = start + minSpan;
      } else {
        start = math.max(min, end - minSpan);
      }
    }
    return RangeValues(start, end);
  }

  double? _clamped(double? value, double min, double max) {
    if (value == null) return null;
    return value.clamp(min, max).toDouble();
  }

  LineTooltipItem? _tooltipForPoint(NomogramObservedPoint? point) {
    if (point == null) return null;
    return LineTooltipItem(
      [
        point.label,
        if (point.athleteName != null) point.athleteName!,
        'Intensity: ${point.xIntensityPercent.toStringAsFixed(1)}%',
        'RMSSD-Slope: ${point.ySlope.toStringAsFixed(3)}',
        if (point.classification != null)
          'Response: ${_classificationLabel(point.classification!)}',
        if (point.isExtrapolated) 'Estimated zone',
      ].join('\n'),
      const TextStyle(color: Colors.white, fontSize: 11),
    );
  }

  double _niceAxisInterval(double range) {
    if (range <= 0) return 1;
    final raw = range / 5.0;
    final exponent = math
        .pow(10, (math.log(raw) / math.ln10).floor())
        .toDouble();
    final normalized = raw / exponent;
    final nice = normalized <= 1
        ? 1.0
        : normalized <= 2
        ? 2.0
        : normalized <= 5
        ? 5.0
        : 10.0;
    return nice * exponent;
  }

  double _roundUpToNice(double value) {
    final interval = _niceAxisInterval(value);
    return (value / interval).ceil() * interval;
  }

  String _formatAxisValue(double value, double range) {
    if (range >= 10) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }

  String _classificationLabel(String classification) {
    switch (classification) {
      case 'very_high_internal_load':
      case 'high_or_moderate_internal_load':
        return 'Lower-than-expected';
      case 'expected_response':
        return 'Expected';
      case 'low_internal_load_or_fast_recovery':
        return 'Favorable';
      default:
        return classification;
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
