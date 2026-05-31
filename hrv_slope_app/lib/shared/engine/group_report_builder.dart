/// Group Report Data Model and Builder.
///
/// Builds ranked group/session comparisons from already-loaded session detail
/// aggregates. The builder is pure and does not access the database.
library;

import 'package:hrv_slope_app/data/database/app_database.dart';
import 'package:hrv_slope_app/data/database/daos/sessions_dao.dart';
import 'package:hrv_slope_app/shared/engine/nomogram_engine.dart';

class GroupReportData {
  final String title;
  final String dateRange;
  final String? taskName;
  final String? sessionType;
  final String presetName;
  final List<GroupReportRow> rows;
  final GroupReportSummary summary;
  final List<String> warnings;

  const GroupReportData({
    required this.title,
    required this.dateRange,
    this.taskName,
    this.sessionType,
    required this.presetName,
    required this.rows,
    required this.summary,
    required this.warnings,
  });

  List<GroupReportRow> get rankedRows =>
      rows.where((row) => row.isRanked).toList();

  List<GroupReportRow> get incompleteRows =>
      rows.where((row) => !row.isRanked).toList();
}

class GroupReportRow {
  final int athleteId;
  final String athleteName;
  final int sessionId;
  final String sessionDate;
  final String? taskName;
  final double? intensityPercent;
  final double? rmssdExercise;
  final double? rmssdRecovery;
  final double? rawSlope;
  final double? interpretedSlope;
  final double? itlIndex;
  final String? classification;
  final double? residual;
  final double? residualPercent;
  final List<IntensityVariable> externalVariables;
  final List<IntensityVariable> internalVariables;
  final List<String> warnings;
  final bool isCompleteForNomogram;

  const GroupReportRow({
    required this.athleteId,
    required this.athleteName,
    required this.sessionId,
    required this.sessionDate,
    this.taskName,
    this.intensityPercent,
    this.rmssdExercise,
    this.rmssdRecovery,
    this.rawSlope,
    this.interpretedSlope,
    this.itlIndex,
    this.classification,
    this.residual,
    this.residualPercent,
    required this.externalVariables,
    required this.internalVariables,
    required this.warnings,
    required this.isCompleteForNomogram,
  });

  bool get isRanked => interpretedSlope != null;
}

class GroupReportSummary {
  final int nSessions;
  final int nAthletes;
  final int nComplete;
  final double? meanSlope;
  final double? medianSlope;
  final double? minSlope;
  final double? maxSlope;
  final double? meanItl;
  final int nVeryHighInternalLoad;
  final int nExpectedResponse;
  final int nLowInternalLoadOrFastRecovery;

  const GroupReportSummary({
    required this.nSessions,
    required this.nAthletes,
    required this.nComplete,
    this.meanSlope,
    this.medianSlope,
    this.minSlope,
    this.maxSlope,
    this.meanItl,
    this.nVeryHighInternalLoad = 0,
    this.nExpectedResponse = 0,
    this.nLowInternalLoadOrFastRecovery = 0,
  });
}

GroupReportData buildGroupReport({
  required List<SessionDetail> details,
  required PopulationNomogramSource nomogramPreset,
  String? dateFrom,
  String? dateTo,
  String? taskName,
  String? sessionType,
}) {
  final filtered = details.where((detail) {
    final session = detail.session;
    if (dateFrom != null && session.date.compareTo(dateFrom) < 0) {
      return false;
    }
    if (dateTo != null && session.date.compareTo(dateTo) > 0) {
      return false;
    }
    final taskFilter = taskName?.trim().toLowerCase();
    if (taskFilter != null && taskFilter.isNotEmpty) {
      final task = session.taskName?.toLowerCase() ?? '';
      if (!task.contains(taskFilter)) return false;
    }
    final typeFilter = sessionType?.trim();
    if (typeFilter != null && typeFilter.isNotEmpty) {
      if (session.sessionType != typeFilter) return false;
    }
    return true;
  }).toList();

  final reportWarnings = <String>[];
  final rows = filtered.map((detail) {
    final session = detail.session;
    final rowWarnings = <String>[];
    if (session.intensityPercent == null) {
      rowWarnings.add('Intensity percent missing; classification unavailable.');
    }
    if (session.slopeInterpreted == null || session.rmssdRecovery == null) {
      rowWarnings.add('HRV or slope data missing; row is not ranked.');
    }
    if (session.isDraft) {
      rowWarnings.add('Draft session; results incomplete.');
    }

    NomogramClassificationResult? classification;
    if (!session.isDraft &&
        session.intensityPercent != null &&
        session.slopeInterpreted != null) {
      classification = classifySlopeWithPopulationNomogram(
        session.intensityPercent!,
        session.slopeInterpreted!,
        source: nomogramPreset,
      );
      rowWarnings.addAll(classification.warnings);
    }

    final isCompleteForNomogram =
        !session.isDraft &&
        session.intensityPercent != null &&
        session.slopeInterpreted != null;

    if (rowWarnings.isNotEmpty) {
      reportWarnings.addAll(
        rowWarnings.map((warning) => '${detail.athlete.name}: $warning'),
      );
    }

    return GroupReportRow(
      athleteId: detail.athlete.id,
      athleteName: detail.athlete.name,
      sessionId: session.id,
      sessionDate: session.date,
      taskName: session.taskName,
      intensityPercent: session.intensityPercent,
      rmssdExercise: session.rmssdExercise,
      rmssdRecovery: session.rmssdRecovery,
      rawSlope: session.slopeRaw,
      interpretedSlope: session.slopeInterpreted,
      itlIndex: session.itlIndex,
      classification: classification == null
          ? session.classification
          : _classificationKey(classification.classification),
      residual: classification?.residual,
      residualPercent: classification?.residualPercent,
      externalVariables: detail.variablesByCategory('external'),
      internalVariables: detail.variablesByCategory('internal'),
      warnings: rowWarnings,
      isCompleteForNomogram: isCompleteForNomogram,
    );
  }).toList();

  rows.sort((a, b) {
    if (a.isRanked && b.isRanked) {
      return a.interpretedSlope!.compareTo(b.interpretedSlope!);
    }
    if (a.isRanked) return -1;
    if (b.isRanked) return 1;
    return a.sessionDate.compareTo(b.sessionDate);
  });

  return GroupReportData(
    title: _titleFor(taskName, sessionType),
    dateRange: _dateRangeText(dateFrom, dateTo),
    taskName: _blankToNull(taskName),
    sessionType: _blankToNull(sessionType),
    presetName: nomogramPreset.presetName,
    rows: List.unmodifiable(rows),
    summary: _summary(rows),
    warnings: List.unmodifiable(reportWarnings),
  );
}

GroupReportSummary _summary(List<GroupReportRow> rows) {
  final ranked = rows.where((row) => row.isRanked).toList();
  final slopes = ranked.map((row) => row.interpretedSlope!).toList()..sort();
  final itls = ranked.map((row) => row.itlIndex).whereType<double>().toList();

  return GroupReportSummary(
    nSessions: rows.length,
    nAthletes: rows.map((row) => row.athleteId).toSet().length,
    nComplete: ranked.length,
    meanSlope: slopes.isEmpty ? null : _mean(slopes),
    medianSlope: slopes.isEmpty ? null : _median(slopes),
    minSlope: slopes.isEmpty ? null : slopes.first,
    maxSlope: slopes.isEmpty ? null : slopes.last,
    meanItl: itls.isEmpty ? null : _mean(itls),
    nVeryHighInternalLoad: rows
        .where((row) => row.classification == 'very_high_internal_load')
        .length,
    nExpectedResponse: rows
        .where((row) => row.classification == 'expected_response')
        .length,
    nLowInternalLoadOrFastRecovery: rows
        .where(
          (row) => row.classification == 'low_internal_load_or_fast_recovery',
        )
        .length,
  );
}

String _classificationKey(InternalLoadClassification classification) {
  switch (classification) {
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

double _mean(List<double> values) =>
    values.reduce((a, b) => a + b) / values.length;

double _median(List<double> sortedValues) {
  final middle = sortedValues.length ~/ 2;
  if (sortedValues.length.isOdd) return sortedValues[middle];
  return (sortedValues[middle - 1] + sortedValues[middle]) / 2;
}

String _titleFor(String? taskName, String? sessionType) {
  final parts = [
    if (_blankToNull(taskName) != null) _blankToNull(taskName)!,
    if (_blankToNull(sessionType) != null) _blankToNull(sessionType)!,
  ];
  if (parts.isEmpty) return 'Group Report';
  return 'Group Report - ${parts.join(' / ')}';
}

String _dateRangeText(String? dateFrom, String? dateTo) {
  if (_blankToNull(dateFrom) == null && _blankToNull(dateTo) == null) {
    return 'All dates';
  }
  return '${_blankToNull(dateFrom) ?? '...'} to ${_blankToNull(dateTo) ?? '...'}';
}

String? _blankToNull(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}
