/// Group Report Data Model and Builder.
///
/// Builds ranked group/session comparisons from already-loaded session detail
/// aggregates. The builder is pure and does not access the database.
library;

import 'package:hrv_slope_app/data/database/app_database.dart';
import 'package:hrv_slope_app/data/database/daos/sessions_dao.dart';
import 'package:hrv_slope_app/shared/engine/intensity_resolver.dart';
import 'package:hrv_slope_app/shared/engine/nomogram_engine.dart';
import 'package:hrv_slope_app/shared/engine/recovery_response_labels.dart';

class GroupReportRange {
  final double? min;
  final double? max;

  const GroupReportRange({this.min, this.max});

  bool get isEmpty => min == null && max == null;

  bool contains(double? value) {
    if (isEmpty) return true;
    if (value == null) return false;
    if (min != null && value < min!) return false;
    if (max != null && value > max!) return false;
    return true;
  }
}

class GroupReportFilter {
  final String? dateFrom;
  final String? dateTo;
  final Set<String> athleteNames;
  final Set<String> sports;
  final Set<String> sessionTasks;
  final String? taskTextSearch;
  final Set<String> sessionTypes;
  final Set<String> protocolNames;
  final Set<String> contextEnvironmentTags;
  final Set<String> intensitySourcesForSlope;
  final Set<String> intensityMetricNames;
  final double? primaryIntensityMin;
  final double? primaryIntensityMax;
  final double? rpeMin;
  final double? rpeMax;
  final double? fatigueMin;
  final double? fatigueMax;
  final double? slopeMin;
  final double? slopeMax;
  final double? itlMin;
  final double? itlMax;
  final Set<String> recoveryResponses;
  final String? notesTextSearch;

  const GroupReportFilter({
    this.dateFrom,
    this.dateTo,
    this.athleteNames = const {},
    this.sports = const {},
    this.sessionTasks = const {},
    this.taskTextSearch,
    this.sessionTypes = const {},
    this.protocolNames = const {},
    this.contextEnvironmentTags = const {},
    this.intensitySourcesForSlope = const {},
    this.intensityMetricNames = const {},
    this.primaryIntensityMin,
    this.primaryIntensityMax,
    this.rpeMin,
    this.rpeMax,
    this.fatigueMin,
    this.fatigueMax,
    this.slopeMin,
    this.slopeMax,
    this.itlMin,
    this.itlMax,
    this.recoveryResponses = const {},
    this.notesTextSearch,
  });

  bool get isEmpty => activeFilterCount == 0;

  int get activeFilterCount {
    var count = 0;
    if (dateFrom != null) count++;
    if (dateTo != null) count++;
    if (athleteNames.isNotEmpty) count++;
    if (sports.isNotEmpty) count++;
    if (sessionTasks.isNotEmpty) count++;
    if ((taskTextSearch ?? '').trim().isNotEmpty) count++;
    if (sessionTypes.isNotEmpty) count++;
    if (protocolNames.isNotEmpty) count++;
    if (contextEnvironmentTags.isNotEmpty) count++;
    if (intensitySourcesForSlope.isNotEmpty) count++;
    if (intensityMetricNames.isNotEmpty) count++;
    if (primaryIntensityMin != null || primaryIntensityMax != null) count++;
    if (rpeMin != null || rpeMax != null) count++;
    if (fatigueMin != null || fatigueMax != null) count++;
    if (slopeMin != null || slopeMax != null) count++;
    if (itlMin != null || itlMax != null) count++;
    if (recoveryResponses.isNotEmpty) count++;
    if ((notesTextSearch ?? '').trim().isNotEmpty) count++;
    return count;
  }

  List<String> activeFilterLabels() {
    final labels = <String>[];
    if (dateFrom != null) labels.add('From $dateFrom');
    if (dateTo != null) labels.add('To $dateTo');
    _addSetLabel(labels, 'Athlete', athleteNames);
    _addSetLabel(labels, 'Sport', sports);
    _addSetLabel(labels, 'Task', sessionTasks);
    final taskSearch = (taskTextSearch ?? '').trim();
    if (taskSearch.isNotEmpty) labels.add('Search text: "$taskSearch"');
    _addSetLabel(labels, 'Type', sessionTypes);
    _addSetLabel(labels, 'Protocol', protocolNames);
    _addSetLabel(labels, 'Context', contextEnvironmentTags);
    _addSetLabel(labels, 'Intensity source', intensitySourcesForSlope);
    _addSetLabel(labels, 'Metric', intensityMetricNames);
    _addRangeLabel(
      labels,
      'Primary intensity',
      primaryIntensityMin,
      primaryIntensityMax,
    );
    _addRangeLabel(labels, 'RPE', rpeMin, rpeMax);
    _addRangeLabel(labels, 'Fatigue', fatigueMin, fatigueMax);
    _addRangeLabel(labels, 'Slope', slopeMin, slopeMax);
    _addRangeLabel(labels, 'ITL', itlMin, itlMax);
    _addSetLabel(labels, 'Response', recoveryResponses);
    final notesSearch = (notesTextSearch ?? '').trim();
    if (notesSearch.isNotEmpty) labels.add('Notes contains "$notesSearch"');
    return labels;
  }

  bool matchesDetail(SessionDetail detail) {
    final session = detail.session;
    if (!_matchesDateRange(session.date)) return false;
    if (!_matchesSet(athleteNames, detail.athlete.name)) return false;
    if (!_matchesSet(sports, session.sport ?? detail.athlete.sport)) {
      return false;
    }
    if (!_matchesSet(sessionTasks, session.taskName)) return false;
    final taskSearch = (taskTextSearch ?? '').trim().toLowerCase();
    if (taskSearch.isNotEmpty &&
        !((session.taskName ?? '').toLowerCase().contains(taskSearch))) {
      return false;
    }
    if (!_matchesSet(sessionTypes, session.sessionType)) return false;
    if (!_matchesSet(protocolNames, session.protocolName)) return false;
    if (!_matchesContextTags(
      contextEnvironmentTags,
      session.contextEnvironment,
    )) {
      return false;
    }
    final intensitySource = intensitySourceForSlopeLabel(
      session.intensitySource,
    );
    if (!_matchesSet(intensitySourcesForSlope, intensitySource)) return false;
    final metric = primaryIntensityMetricFromMethod(session.intensitySource);
    if (!_matchesSet(intensityMetricNames, metric)) return false;
    if (!GroupReportRange(
      min: primaryIntensityMin,
      max: primaryIntensityMax,
    ).contains(session.intensityPercent)) {
      return false;
    }
    if (!GroupReportRange(min: rpeMin, max: rpeMax).contains(_rpe(detail))) {
      return false;
    }
    if (!GroupReportRange(
      min: fatigueMin,
      max: fatigueMax,
    ).contains(_fatigue(detail))) {
      return false;
    }
    if (!GroupReportRange(
      min: slopeMin,
      max: slopeMax,
    ).contains(session.slopeInterpreted)) {
      return false;
    }
    if (!GroupReportRange(
      min: itlMin,
      max: itlMax,
    ).contains(session.itlIndex)) {
      return false;
    }
    final notesSearch = (notesTextSearch ?? '').trim().toLowerCase();
    if (notesSearch.isNotEmpty &&
        !_notesText(detail).toLowerCase().contains(notesSearch)) {
      return false;
    }
    return true;
  }

  bool _matchesDateRange(String sessionDate) {
    final sessionDay = _calendarDayKey(sessionDate);
    final fromDay = _calendarDayKey(dateFrom);
    final toDay = _calendarDayKey(dateTo);
    if (sessionDay == null) return true;
    if (fromDay != null && sessionDay.compareTo(fromDay) < 0) return false;
    if (toDay != null && sessionDay.compareTo(toDay) > 0) return false;
    return true;
  }

  bool _matchesSet(Set<String> selected, String? value) {
    if (selected.isEmpty) return true;
    final normalized = (value ?? '').trim().toLowerCase();
    return selected.any((item) => item.trim().toLowerCase() == normalized);
  }

  bool _matchesContextTags(Set<String> selected, String? value) {
    if (selected.isEmpty) return true;
    final options = contextEnvironmentOptions(
      value,
    ).map((text) => text.toLowerCase()).toSet();
    return selected.any((item) => options.contains(item.toLowerCase()));
  }

  void _addSetLabel(List<String> labels, String label, Set<String> values) {
    if (values.isEmpty) return;
    labels.add('$label: ${values.join(', ')}');
  }

  void _addRangeLabel(
    List<String> labels,
    String label,
    double? min,
    double? max,
  ) {
    if (min == null && max == null) return;
    if (min != null && max != null) {
      labels.add('$label: ${_formatNumber(min)}-${_formatNumber(max)}');
    } else if (min != null) {
      labels.add('$label >= ${_formatNumber(min)}');
    } else {
      labels.add('$label <= ${_formatNumber(max!)}');
    }
  }
}

class GroupReportFilterOptions {
  final Set<String> athleteNames;
  final Set<String> sports;
  final Set<String> sessionTasks;
  final Set<String> sessionTypes;
  final Set<String> protocolNames;
  final Set<String> contextEnvironmentTags;
  final Set<String> intensitySourcesForSlope;
  final Set<String> intensityMetricNames;
  final Set<String> recoveryResponses;
  final String? dateMin;
  final String? dateMax;
  final GroupReportRange primaryIntensityRange;
  final GroupReportRange rpeRange;
  final GroupReportRange fatigueRange;
  final GroupReportRange slopeRange;
  final GroupReportRange itlRange;

  const GroupReportFilterOptions({
    this.athleteNames = const {},
    this.sports = const {},
    this.sessionTasks = const {},
    this.sessionTypes = const {},
    this.protocolNames = const {},
    this.contextEnvironmentTags = const {},
    this.intensitySourcesForSlope = const {},
    this.intensityMetricNames = const {},
    this.recoveryResponses = const {},
    this.dateMin,
    this.dateMax,
    this.primaryIntensityRange = const GroupReportRange(),
    this.rpeRange = const GroupReportRange(),
    this.fatigueRange = const GroupReportRange(),
    this.slopeRange = const GroupReportRange(),
    this.itlRange = const GroupReportRange(),
  });
}

class GroupReportData {
  final String title;
  final String dateRange;
  final String? taskName;
  final String? sessionType;
  final GroupReportFilter filter;
  final GroupReportFilterOptions filterOptions;
  final List<String> activeFilterLabels;
  final String presetName;
  final List<GroupReportRow> rows;
  final GroupReportSummary summary;
  final List<String> warnings;

  const GroupReportData({
    required this.title,
    required this.dateRange,
    this.taskName,
    this.sessionType,
    this.filter = const GroupReportFilter(),
    this.filterOptions = const GroupReportFilterOptions(),
    this.activeFilterLabels = const [],
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
  final String? sessionType;
  final String? sport;
  final String? protocolName;
  final String? contextEnvironment;
  final double? intensityPercent;
  final String intensitySourceForSlope;
  final String? primaryIntensityMetric;
  final double? rpe;
  final double? fatigue;
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
  final String? notes;

  const GroupReportRow({
    required this.athleteId,
    required this.athleteName,
    required this.sessionId,
    required this.sessionDate,
    this.taskName,
    this.sessionType,
    this.sport,
    this.protocolName,
    this.contextEnvironment,
    this.intensityPercent,
    this.intensitySourceForSlope = 'Unknown',
    this.primaryIntensityMetric,
    this.rpe,
    this.fatigue,
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
    this.notes,
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
  GroupReportFilter filter = const GroupReportFilter(),
  String? dateFrom,
  String? dateTo,
  String? taskName,
  String? sessionType,
}) {
  final effectiveFilter = _legacyAwareFilter(
    filter: filter,
    dateFrom: dateFrom,
    dateTo: dateTo,
    taskName: taskName,
    sessionType: sessionType,
  );
  final options = _filterOptions(details);
  final filtered = details
      .where((detail) => effectiveFilter.matchesDetail(detail))
      .toList();

  final builtRows = filtered.map((detail) {
    final session = detail.session;
    final rowWarnings = <String>[];
    if (session.intensityPercent == null) {
      rowWarnings.add(
        'Intensity percent missing; recovery interpretation unavailable.',
      );
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

    final externalVariables = detail.variablesByCategory('external');
    final internalVariables = detail.variablesByCategory('internal');
    final intensitySourceForSlope = intensitySourceForSlopeLabel(
      session.intensitySource,
    );
    final primaryIntensityMetric = primaryIntensityMetricFromMethod(
      session.intensitySource,
    );

    return GroupReportRow(
      athleteId: detail.athlete.id,
      athleteName: detail.athlete.name,
      sessionId: session.id,
      sessionDate: session.date,
      taskName: session.taskName,
      sessionType: session.sessionType,
      sport: session.sport ?? detail.athlete.sport,
      protocolName: session.protocolName,
      contextEnvironment: session.contextEnvironment,
      intensityPercent: session.intensityPercent,
      intensitySourceForSlope: intensitySourceForSlope,
      primaryIntensityMetric: primaryIntensityMetric,
      rpe: _rpe(detail),
      fatigue: _fatigue(detail),
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
      externalVariables: externalVariables,
      internalVariables: internalVariables,
      warnings: rowWarnings,
      isCompleteForNomogram: isCompleteForNomogram,
      notes: _notesText(detail),
    );
  }).toList();

  final rows = builtRows
      .where(
        (row) =>
            effectiveFilter.recoveryResponses.isEmpty ||
            effectiveFilter.recoveryResponses.contains(
              _responseShortLabel(row.classification),
            ),
      )
      .toList();
  final reportWarnings = [
    for (final row in rows)
      for (final warning in row.warnings) '${row.athleteName}: $warning',
  ];

  rows.sort((a, b) {
    if (a.isRanked && b.isRanked) {
      return a.interpretedSlope!.compareTo(b.interpretedSlope!);
    }
    if (a.isRanked) return -1;
    if (b.isRanked) return 1;
    return a.sessionDate.compareTo(b.sessionDate);
  });

  return GroupReportData(
    title: _titleFor(effectiveFilter),
    dateRange: _dateRangeText(effectiveFilter.dateFrom, effectiveFilter.dateTo),
    taskName: _blankToNull(taskName),
    sessionType: _blankToNull(sessionType),
    filter: effectiveFilter,
    filterOptions: options,
    activeFilterLabels: List.unmodifiable(effectiveFilter.activeFilterLabels()),
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

GroupReportFilter _legacyAwareFilter({
  required GroupReportFilter filter,
  String? dateFrom,
  String? dateTo,
  String? taskName,
  String? sessionType,
}) {
  if (dateFrom == null &&
      dateTo == null &&
      taskName == null &&
      sessionType == null) {
    return filter;
  }
  return GroupReportFilter(
    dateFrom: _blankToNull(dateFrom) ?? filter.dateFrom,
    dateTo: _blankToNull(dateTo) ?? filter.dateTo,
    athleteNames: filter.athleteNames,
    sports: filter.sports,
    sessionTasks: filter.sessionTasks,
    taskTextSearch: _blankToNull(taskName) ?? filter.taskTextSearch,
    sessionTypes: _blankToNull(sessionType) == null
        ? filter.sessionTypes
        : {...filter.sessionTypes, _blankToNull(sessionType)!},
    protocolNames: filter.protocolNames,
    contextEnvironmentTags: filter.contextEnvironmentTags,
    intensitySourcesForSlope: filter.intensitySourcesForSlope,
    intensityMetricNames: filter.intensityMetricNames,
    primaryIntensityMin: filter.primaryIntensityMin,
    primaryIntensityMax: filter.primaryIntensityMax,
    rpeMin: filter.rpeMin,
    rpeMax: filter.rpeMax,
    fatigueMin: filter.fatigueMin,
    fatigueMax: filter.fatigueMax,
    slopeMin: filter.slopeMin,
    slopeMax: filter.slopeMax,
    itlMin: filter.itlMin,
    itlMax: filter.itlMax,
    recoveryResponses: filter.recoveryResponses,
    notesTextSearch: filter.notesTextSearch,
  );
}

GroupReportFilterOptions _filterOptions(List<SessionDetail> details) {
  return GroupReportFilterOptions(
    athleteNames: _stringOptions(details.map((d) => d.athlete.name)),
    sports: _stringOptions(
      details.map((d) => d.session.sport ?? d.athlete.sport),
    ),
    sessionTasks: _stringOptions(details.map((d) => d.session.taskName)),
    sessionTypes: _stringOptions(details.map((d) => d.session.sessionType)),
    protocolNames: _stringOptions(details.map((d) => d.session.protocolName)),
    contextEnvironmentTags: _stringOptions(
      details.expand(
        (d) => contextEnvironmentOptions(d.session.contextEnvironment),
      ),
    ),
    intensitySourcesForSlope: _stringOptions(
      details.map(
        (d) => intensitySourceForSlopeLabel(d.session.intensitySource),
      ),
    ),
    intensityMetricNames: _stringOptions(
      details.map(
        (d) => primaryIntensityMetricFromMethod(d.session.intensitySource),
      ),
    ),
    recoveryResponses: const {
      'Lower-than-expected',
      'Expected',
      'Favorable',
      'Unavailable',
    },
    dateMin: _dateBound(details, first: true),
    dateMax: _dateBound(details, first: false),
    primaryIntensityRange: _range(
      details.map((d) => d.session.intensityPercent),
    ),
    rpeRange: _range(details.map(_rpe)),
    fatigueRange: _range(details.map(_fatigue)),
    slopeRange: _range(details.map((d) => d.session.slopeInterpreted)),
    itlRange: _range(details.map((d) => d.session.itlIndex)),
  );
}

Set<String> _stringOptions(Iterable<String?> values) {
  final byLower = <String, String>{};
  for (final value in values) {
    final text = (value ?? '').trim();
    if (text.isEmpty) continue;
    byLower.putIfAbsent(text.toLowerCase(), () => text);
  }
  final sorted = byLower.values.toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return {for (final value in sorted) value};
}

Set<String> contextEnvironmentOptions(String? value) {
  final text = (value ?? '').trim();
  if (text.isEmpty) return const {};
  final options = <String>{text};
  final parts = text.split(RegExp(r'[,;|#]'));
  for (final part in parts) {
    final tag = part.trim();
    if (tag.isNotEmpty) options.add(tag);
  }
  final sorted = options.toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return {for (final value in sorted) value};
}

String? _calendarDayKey(String? value) {
  final text = (value ?? '').trim();
  if (text.isEmpty) return null;
  final parsed = DateTime.tryParse(text);
  if (parsed != null) return _calendarKey(parsed);
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(text);
  if (match == null) return null;
  return '${match.group(1)}-${match.group(2)}-${match.group(3)}';
}

String _calendarKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

String? _dateBound(List<SessionDetail> details, {required bool first}) {
  final dates =
      details
          .map((detail) => _calendarDayKey(detail.session.date))
          .whereType<String>()
          .toList()
        ..sort();
  if (dates.isEmpty) return null;
  return first ? dates.first : dates.last;
}

GroupReportRange _range(Iterable<double?> values) {
  final valid = values.whereType<double>().toList();
  if (valid.isEmpty) return const GroupReportRange();
  return GroupReportRange(
    min: valid.reduce((a, b) => a < b ? a : b),
    max: valid.reduce((a, b) => a > b ? a : b),
  );
}

double? _rpe(SessionDetail detail) {
  return _variableValue(detail, const {'rpe_1_10', 'session_rpe_1_10'});
}

double? _fatigue(SessionDetail detail) {
  return _variableValue(detail, const {
    'subjective_fatigue_1_10',
    'fatigue_1_10',
    'fatigue',
  });
}

double? _variableValue(SessionDetail detail, Set<String> names) {
  for (final variable in detail.variablesByCategory('internal')) {
    if (names.contains(variable.name.trim().toLowerCase())) {
      return variable.value;
    }
  }
  return null;
}

String _notesText(SessionDetail detail) {
  return [
    if ((detail.session.notes ?? '').trim().isNotEmpty) detail.session.notes!,
    for (final note in detail.notes)
      if (note.reason.trim().isNotEmpty) note.reason,
  ].join(' | ');
}

String _responseShortLabel(String? classification) {
  if (_blankToNull(classification) == null) return 'Unavailable';
  return recoveryResponseShortLabelForClassificationKey(classification);
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

String _formatNumber(double value) {
  if ((value - value.round()).abs() < 1e-9) return value.round().toString();
  return value.toStringAsFixed(1);
}

double _median(List<double> sortedValues) {
  final middle = sortedValues.length ~/ 2;
  if (sortedValues.length.isOdd) return sortedValues[middle];
  return (sortedValues[middle - 1] + sortedValues[middle]) / 2;
}

String _titleFor(GroupReportFilter filter) {
  final parts = [
    if (filter.sessionTasks.isNotEmpty) filter.sessionTasks.join(', '),
    if ((filter.taskTextSearch ?? '').trim().isNotEmpty)
      '"${filter.taskTextSearch!.trim()}"',
    if (filter.sessionTypes.isNotEmpty) filter.sessionTypes.join(', '),
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
