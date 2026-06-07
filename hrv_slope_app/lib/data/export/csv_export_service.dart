library;

import 'dart:convert';

import 'package:hrv_slope_app/data/database/app_database.dart';
import 'package:hrv_slope_app/data/export/export_models.dart';
import 'package:hrv_slope_app/shared/engine/group_report_builder.dart';
import 'package:hrv_slope_app/shared/engine/individual_nomogram_builder.dart';
import 'package:hrv_slope_app/shared/engine/individual_report_builder.dart';
import 'package:hrv_slope_app/shared/engine/longitudinal_builder.dart';
import 'package:hrv_slope_app/shared/engine/nomogram_engine.dart';
import 'package:hrv_slope_app/shared/engine/nomogram_mode.dart';
import 'package:hrv_slope_app/shared/engine/recovery_response_labels.dart';

String csvField(Object? value) {
  if (value == null) return '';
  final text = _valueToText(value);
  final escaped = text.replaceAll('"', '""');
  final mustQuote =
      escaped.contains(',') ||
      escaped.contains('"') ||
      escaped.contains('\n') ||
      escaped.contains('\r') ||
      escaped.contains(';');
  return mustQuote ? '"$escaped"' : escaped;
}

String buildCsv(List<String> headers, List<List<Object?>> rows) {
  final buffer = StringBuffer();
  buffer.writeln(headers.map(csvField).join(','));
  for (final row in rows) {
    buffer.writeln(row.map(csvField).join(','));
  }
  return buffer.toString();
}

CsvExportData exportIndividualReportCsv(
  IndividualReportData data, {
  int? athleteId,
  int? sessionId,
}) {
  const headers = [
    'athlete_id',
    'athlete_name',
    'sport',
    'session_id',
    'session_date',
    'task_name',
    'session_type',
    'protocol_name',
    'context_environment',
    'intensity_percent',
    'intensity_source',
    'intensity_source_for_slope',
    'primary_intensity_value',
    'primary_intensity_metric',
    'external_variables_json',
    'internal_variables_json',
    'hrv_input_mode',
    'rmssd_recovery',
    'rmssd_recovery_source',
    'rmssd_exercise',
    'rmssd_exercise_source',
    'rmssd_exercise_is_default',
    'recovery_window_start_min',
    'recovery_window_end_min',
    'recovery_window_duration_min',
    'recovery_time_for_slope_min',
    'slope_raw',
    'slope_interpreted',
    'itl_index',
    'classification',
    'interpretation_text',
    'population_preset',
    'expected_lower',
    'expected_mean',
    'expected_upper',
    'residual',
    'residual_percent',
    'nomogram_warnings',
    'rr_preprocessing_mode',
    'rr_correction_enabled',
    'rr_correction_method',
    'rr_raw_rmssd',
    'rr_corrected_rmssd',
    'rr_rmssd_used',
    'rr_artifact_count',
    'rr_artifact_percent',
    'rr_quality_decision',
    'rr_rmssd_delta_percent',
    'report_warnings',
    'requested_nomogram_mode',
    'active_nomogram_mode',
    'athlete_weight_percent',
    'study_weight_percent',
    'is_extrapolated',
  ];

  final hrv = data.hrvSummary;
  final slope = data.slopeSummary;
  final nomogram = data.nomogramSummary;
  final duration =
      hrv.recoveryWindowStartMin == null || hrv.recoveryWindowEndMin == null
      ? null
      : hrv.recoveryWindowEndMin! - hrv.recoveryWindowStartMin!;

  final rows = [
    [
      athleteId,
      data.athleteName,
      data.sport,
      sessionId,
      data.sessionDate,
      data.taskName,
      data.sessionType,
      data.protocolName,
      data.contextEnvironment,
      slope.intensityPercent,
      slope.intensitySource,
      slope.intensitySourceForSlope,
      slope.intensityPercent,
      slope.primaryIntensityMetric,
      _variablesJson(data.externalVariables),
      _variablesJson(data.internalVariables),
      hrv.inputMode,
      hrv.rmssdRecovery,
      hrv.rmssdRecoverySource,
      hrv.rmssdExercise,
      hrv.rmssdExerciseSource,
      hrv.usedFallbackExercise,
      hrv.recoveryWindowStartMin,
      hrv.recoveryWindowEndMin,
      duration,
      hrv.tUsedForSlope,
      slope.rawSlope,
      slope.interpretedSlope,
      slope.itlIndex,
      nomogram == null
          ? recoveryResponseExportValueForClassificationKey(data.classification)
          : nomogram.classification.label,
      nomogram?.interpretationText,
      nomogram?.presetName,
      nomogram?.expectedLower,
      nomogram?.expectedMean,
      nomogram?.expectedUpper,
      nomogram?.residual,
      nomogram?.residualPercent,
      nomogram?.warnings.join('; '),
      hrv.inputMode == 'rr_intervals' ? 'stored_summary' : null,
      hrv.inputMode == 'rr_intervals' ? hrv.rrCorrectionEnabled : null,
      hrv.rrCorrectionMethod,
      hrv.rrRawRmssd,
      hrv.rrCorrectedRmssd,
      hrv.rrRmssdUsed,
      hrv.rrArtifactCount,
      hrv.rrArtifactPercent,
      hrv.rrQualityDecision,
      hrv.rrRmssdDeltaPercent,
      data.warnings.join('; '),
      nomogram?.requestedMode.key,
      nomogram?.activeMode.key,
      nomogram?.athleteWeightPercent,
      nomogram?.populationWeightPercent,
      nomogram?.isExtrapolated,
    ],
  ];

  return CsvExportData(
    filename: _filename('individual_report', data.athleteName),
    content: buildCsv(headers, rows),
    rowCount: rows.length,
    columnCount: headers.length,
    exportType: ExportDatasetType.individualReport,
    warnings: data.warnings,
  );
}

CsvExportData exportGroupReportRowsCsv(GroupReportData data) {
  const headers = [
    'filter_summary',
    'rank',
    'athlete_id',
    'athlete_name',
    'session_id',
    'session_date',
    'task_name',
    'session_type',
    'intensity_percent',
    'intensity_source_for_slope',
    'primary_intensity_value',
    'primary_intensity_metric',
    'rmssd_exercise',
    'rmssd_recovery',
    'slope_raw',
    'slope_interpreted',
    'itl_index',
    'classification',
    'residual',
    'residual_percent',
    'external_variables_json',
    'internal_variables_json',
    'warnings',
    'is_complete_for_nomogram',
  ];
  var rank = 0;
  final rows = [
    for (final row in data.rows)
      [
        data.activeFilterLabels.join(' | '),
        if (row.isRanked) ++rank else null,
        row.athleteId,
        row.athleteName,
        row.sessionId,
        row.sessionDate,
        row.taskName,
        row.sessionType,
        row.intensityPercent,
        row.intensitySourceForSlope,
        row.intensityPercent,
        row.primaryIntensityMetric,
        row.rmssdExercise,
        row.rmssdRecovery,
        row.rawSlope,
        row.interpretedSlope,
        row.itlIndex,
        recoveryResponseExportValueForClassificationKey(row.classification),
        row.residual,
        row.residualPercent,
        _variablesJson(row.externalVariables),
        _variablesJson(row.internalVariables),
        row.warnings.join('; '),
        row.isCompleteForNomogram,
      ],
  ];
  return CsvExportData(
    filename: _filename('group_report_rows', data.title),
    content: buildCsv(headers, rows),
    rowCount: rows.length,
    columnCount: headers.length,
    exportType: ExportDatasetType.groupReport,
    warnings: data.warnings,
  );
}

CsvExportData exportGroupReportSummaryCsv(GroupReportData data) {
  const headers = [
    'filter_summary',
    'n_sessions',
    'n_athletes',
    'n_complete',
    'mean_slope',
    'median_slope',
    'min_slope',
    'max_slope',
    'mean_itl',
    'n_lower_than_expected_recovery_response',
    'n_expected_recovery_response',
    'n_favorable_recovery_response',
  ];
  final rows = [
    [
      data.activeFilterLabels.join(' | '),
      data.summary.nSessions,
      data.summary.nAthletes,
      data.summary.nComplete,
      data.summary.meanSlope,
      data.summary.medianSlope,
      data.summary.minSlope,
      data.summary.maxSlope,
      data.summary.meanItl,
      data.summary.nVeryHighInternalLoad +
          data.rows
              .where(
                (row) => row.classification == 'high_or_moderate_internal_load',
              )
              .length,
      data.summary.nExpectedResponse,
      data.summary.nLowInternalLoadOrFastRecovery,
    ],
  ];
  return CsvExportData(
    filename: _filename('group_report_summary', data.title),
    content: buildCsv(headers, rows),
    rowCount: rows.length,
    columnCount: headers.length,
    exportType: ExportDatasetType.groupReport,
    warnings: data.warnings,
  );
}

CsvExportData exportLongitudinalCsv(LongitudinalSeries series) {
  const headers = [
    'filter_summary',
    'athlete_id',
    'athlete_name',
    'session_id',
    'date',
    'task_name',
    'sport',
    'session_type',
    'protocol_name',
    'context_environment',
    'intensity_percent',
    'intensity_source_for_slope',
    'primary_intensity_value',
    'primary_intensity_metric',
    'raw_slope',
    'interpreted_slope',
    'itl_index',
    'residual',
    'residual_percent',
    'classification',
    'nomogram_reference_source',
    'slope_orellana_19_reference_slope',
    'slope_orellana_19_lower_slope_threshold',
    'slope_orellana_19_upper_slope_threshold',
    'slope_orellana_19_reference_itl',
    'slope_orellana_19_lower_itl_threshold',
    'slope_orellana_19_upper_itl_threshold',
    'recovery_zone',
    'nomogram_reference_unavailable_reason',
    'rpe',
    'rpe_slope_response_index',
    'rpe_slope_quadrant',
    'rpe_high_threshold',
    'rpe_slope_quadrant_label',
    'fatigue',
    'srpe',
    'trimp',
    'primary_external_load_name',
    'primary_external_load_value',
    'notes',
    'slope_rolling_7',
    'slope_rolling_14',
    'slope_rolling_28',
    'itl_rolling_7',
    'itl_rolling_14',
    'itl_rolling_28',
    'warnings',
    'requested_nomogram_mode',
    'active_nomogram_mode',
    'athlete_weight_percent',
    'study_weight_percent',
    'is_extrapolated',
    'nomogram_warnings',
  ];
  final filterSummary = series.activeFilterLabels.isEmpty
      ? 'No filters'
      : series.activeFilterLabels.join('; ');
  final quadrantData =
      series.rpeSlopeQuadrantData.points.isEmpty && series.points.isNotEmpty
      ? buildRpeSlopeQuadrantData(series.points)
      : series.rpeSlopeQuadrantData;
  final quadrantBySessionId = {
    for (final point in quadrantData.points) point.sessionId: point,
  };
  final rows = <List<Object?>>[
    if (series.points.isEmpty && series.activeFilterLabels.isNotEmpty)
      _emptyLongitudinalMetadataRow(series, filterSummary, headers),
    for (var i = 0; i < series.points.length; i++)
      [
        filterSummary,
        series.athleteId,
        series.athleteName,
        series.points[i].sessionId,
        series.points[i].date,
        series.points[i].taskName,
        series.points[i].sport,
        series.points[i].sessionType,
        series.points[i].protocolName,
        series.points[i].contextEnvironment,
        series.points[i].intensityPercent,
        series.points[i].intensitySourceForSlope,
        series.points[i].primaryIntensityValue,
        series.points[i].primaryIntensityMetric,
        series.points[i].rawSlope,
        series.points[i].interpretedSlope,
        series.points[i].itlIndex,
        series.points[i].residual,
        series.points[i].residualPercent,
        recoveryResponseExportValueForClassificationKey(
          series.points[i].classification,
        ),
        series.points[i].nomogramReference.source,
        series.points[i].nomogramReference.referenceSlope,
        series.points[i].nomogramReference.lowerSlopeThreshold,
        series.points[i].nomogramReference.upperSlopeThreshold,
        series.points[i].nomogramReference.referenceItl,
        series.points[i].nomogramReference.lowerItlThreshold,
        series.points[i].nomogramReference.upperItlThreshold,
        series.points[i].nomogramReference.zone.key,
        series.points[i].nomogramReference.unavailableReason,
        series.points[i].rpe,
        quadrantBySessionId[series.points[i].sessionId]?.slopeResponseIndex,
        quadrantBySessionId[series.points[i].sessionId]?.quadrant.key,
        quadrantData.highRpeThreshold,
        quadrantBySessionId[series.points[i].sessionId]?.quadrant.label,
        series.points[i].fatigue,
        series.points[i].srpe,
        series.points[i].trimp,
        series.points[i].primaryExternalLoadName,
        series.points[i].primaryExternalLoadValue,
        series.points[i].notes,
        series.slopeRolling7[i],
        series.slopeRolling14[i],
        series.slopeRolling28[i],
        series.itlRolling7[i],
        series.itlRolling14[i],
        series.itlRolling28[i],
        series.points[i].warnings.join('; '),
        series.points[i].nomogramReference.requestedMode.key,
        series.points[i].nomogramReference.activeMode.key,
        series.points[i].nomogramReference.athleteWeightPercent,
        series.points[i].nomogramReference.populationWeightPercent,
        series.points[i].nomogramReference.isExtrapolated,
        series.points[i].nomogramReference.warnings.join('; '),
      ],
  ];
  return CsvExportData(
    filename: _filename('longitudinal', series.athleteName),
    content: buildCsv(headers, rows),
    rowCount: rows.length,
    columnCount: headers.length,
    exportType: ExportDatasetType.longitudinalAthlete,
    warnings: series.points.expand((point) => point.warnings).toList(),
  );
}

List<Object?> _emptyLongitudinalMetadataRow(
  LongitudinalSeries series,
  String filterSummary,
  List<String> headers,
) {
  final row = List<Object?>.filled(headers.length, '');
  void setValue(String header, Object? value) {
    row[headers.indexOf(header)] = value;
  }

  setValue('filter_summary', filterSummary);
  setValue('athlete_id', series.athleteId);
  setValue('athlete_name', series.athleteName);
  setValue(
    'requested_nomogram_mode',
    series.nomogramReferenceSeries.requestedMode.key,
  );
  setValue(
    'active_nomogram_mode',
    series.nomogramReferenceSeries.activeMode.key,
  );
  setValue(
    'athlete_weight_percent',
    series.nomogramReferenceSeries.athleteWeightPercent,
  );
  setValue(
    'study_weight_percent',
    series.nomogramReferenceSeries.populationWeightPercent,
  );
  setValue(
    'is_extrapolated',
    series.nomogramReferenceSeries.hasExtrapolatedPoints,
  );
  setValue(
    'nomogram_warnings',
    series.nomogramReferenceSeries.warnings.join('; '),
  );
  return row;
}

CsvExportData exportLongitudinalFatigueFlagsCsv(LongitudinalSeries series) {
  const headers = [
    'flag_type',
    'threshold',
    'triggered',
    'explanation',
    'affected_sessions',
  ];
  final rows = series.fatigueFlags.isEmpty
      ? [
          ['none', null, false, 'No current fatigue flags.', null],
        ]
      : [
          for (final flag in series.fatigueFlags)
            [
              flag.ruleName,
              _thresholdForFlag(flag.ruleName),
              true,
              flag.message,
              '${flag.startDate} to ${flag.endDate}',
            ],
        ];
  return CsvExportData(
    filename: _filename('longitudinal_fatigue_flags', series.athleteName),
    content: buildCsv(headers, rows),
    rowCount: rows.length,
    columnCount: headers.length,
    exportType: ExportDatasetType.longitudinalAthlete,
  );
}

CsvExportData exportIndividualNomogramValidPointsCsv(
  IndividualNomogramData data,
) {
  const headers = [
    'athlete_id',
    'athlete_name',
    'session_id',
    'date',
    'task_name',
    'intensity_percent',
    'interpreted_slope',
    'classification',
    'residual_population',
    'residual_individual',
    'residual_hybrid',
  ];
  final rows = [
    for (final point in data.validPoints)
      [
        data.athleteId,
        data.athleteName,
        point.sessionId,
        point.date,
        point.taskName,
        point.intensityPercent,
        point.interpretedSlope,
        recoveryResponseExportValueForClassificationKey(point.classification),
        point.residualPopulation,
        point.residualIndividual,
        point.residualHybrid,
      ],
  ];
  return CsvExportData(
    filename: _filename('individual_nomogram_points', data.athleteName),
    content: buildCsv(headers, rows),
    rowCount: rows.length,
    columnCount: headers.length,
    exportType: ExportDatasetType.individualNomogram,
    warnings: data.warnings,
  );
}

CsvExportData exportIndividualNomogramExcludedCsv(IndividualNomogramData data) {
  const headers = ['session_id', 'date', 'task_name', 'exclusion_reason'];
  final rows = [
    for (final session in data.excludedSessions)
      [session.sessionId, session.date, session.taskName, session.reason.key],
  ];
  return CsvExportData(
    filename: _filename('individual_nomogram_excluded', data.athleteName),
    content: buildCsv(headers, rows),
    rowCount: rows.length,
    columnCount: headers.length,
    exportType: ExportDatasetType.individualNomogram,
    warnings: data.warnings,
  );
}

CsvExportData exportIndividualNomogramSummaryCsv(IndividualNomogramData data) {
  const headers = [
    'confidence_level',
    'recommended_mode',
    'valid_point_count',
    'excluded_count',
    'low_zone_count',
    'medium_zone_count',
    'high_zone_count',
    'individual_weight',
    'population_weight',
    'model_a',
    'model_b',
    'model_c',
    'r_squared',
    'requested_nomogram_mode',
    'active_nomogram_mode',
    'athlete_weight_percent',
    'study_weight_percent',
    'is_extrapolated',
    'nomogram_warnings',
  ];
  final rows = [
    [
      data.confidenceLevel.name,
      data.summary.recommendedMode.key,
      data.summary.validPointCount,
      data.summary.excludedCount,
      data.summary.lowZoneCount,
      data.summary.mediumZoneCount,
      data.summary.highZoneCount,
      data.hybridWeightIndividual,
      data.hybridWeightPopulation,
      data.fittedModel?.params.a,
      data.fittedModel?.params.b,
      data.fittedModel?.params.c,
      data.fittedModel?.rSquared,
      data.requestedMode.key,
      data.activeMode.key,
      data.athleteWeightPercent,
      data.populationWeightPercent,
      data.hasExtrapolatedPoints,
      data.modelWarnings.join('; '),
    ],
  ];
  return CsvExportData(
    filename: _filename('individual_nomogram_summary', data.athleteName),
    content: buildCsv(headers, rows),
    rowCount: rows.length,
    columnCount: headers.length,
    exportType: ExportDatasetType.individualNomogram,
    warnings: data.warnings,
  );
}

CsvExportData exportIndividualNomogramCurvePointsCsv(
  IndividualNomogramData data,
) {
  const headers = ['curve_type', 'intensity_percent', 'expected_slope'];
  final rows = <List<Object?>>[
    for (final point in data.individualCurvePoints)
      ['individual', point.intensityPercent, point.slope],
    for (final point in data.hybridCurvePoints)
      ['hybrid', point.intensityPercent, point.slope],
  ];
  return CsvExportData(
    filename: _filename('individual_nomogram_curves', data.athleteName),
    content: buildCsv(headers, rows),
    rowCount: rows.length,
    columnCount: headers.length,
    exportType: ExportDatasetType.individualNomogram,
    warnings: data.warnings,
  );
}

CsvExportData exportPopulationNomogramCsv(
  PopulationNomogramSource preset, {
  double startIntensity = 40,
  double endIntensity = 130,
  double step = 1,
}) {
  if (step <= 0) {
    throw ArgumentError.value(step, 'step', 'Must be greater than zero.');
  }
  const headers = [
    'preset',
    'intensity_percent',
    'expected_lower',
    'expected_mean',
    'expected_upper',
    'warning_if_extrapolated',
  ];
  final rows = <List<Object?>>[];
  for (
    var intensity = startIntensity;
    intensity <= endIntensity + 1e-9;
    intensity += step
  ) {
    final normalized = (intensity * 1000000).round() / 1000000;
    final bands = evaluatePopulationNomogramBands(normalized, source: preset);
    rows.add([
      preset.presetName,
      normalized,
      bands.expectedLower,
      bands.expectedMean,
      bands.expectedUpper,
      bands.warnings.join('; '),
    ]);
  }
  return CsvExportData(
    filename: _filename('population_nomogram', preset.presetName),
    content: buildCsv(headers, rows),
    rowCount: rows.length,
    columnCount: headers.length,
    exportType: ExportDatasetType.populationNomogramPoints,
  );
}

String _variablesJson(List<IntensityVariable> variables) {
  if (variables.isEmpty) return '';
  return jsonEncode([
    for (final variable in variables)
      {
        'name': variable.name,
        'value': variable.value,
        'unit': variable.unit,
        'source': variable.source,
        'is_primary_for_nomogram': variable.isPrimaryForNomogram,
      },
  ]);
}

String _valueToText(Object value) {
  if (value is DateTime) return value.toIso8601String();
  if (value is double) return _formatNumber(value);
  if (value is num) return _formatNumber(value);
  return value.toString();
}

String _formatNumber(num value) {
  if (value.isNaN || value.isInfinite) return value.toString();
  if ((value - value.round()).abs() < 1e-9) return value.round().toString();
  return value
      .toStringAsFixed(6)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

String _filename(String prefix, String label) {
  final date = DateTime.now().toIso8601String().split('T').first;
  final normalized = label
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9_ -]'), '')
      .replaceAll(RegExp(r'\s+'), '_');
  return '${prefix}_${normalized.isEmpty ? 'export' : normalized}_$date.csv';
}

String _thresholdForFlag(String ruleName) {
  switch (ruleName) {
    case 'three_negative_residuals':
      return '3 consecutive residuals below -0.5';
    case 'slope_7_vs_28_drop':
      return '7-session slope average >30% below 28-session average';
    case 'itl_7_vs_28_increase':
      return '7-session ITL average >50% above 28-session average';
    default:
      return '';
  }
}
