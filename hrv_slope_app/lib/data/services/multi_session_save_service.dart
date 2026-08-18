import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:hrv_slope_app/core/constants/hrv_sources.dart';
import 'package:hrv_slope_app/core/constants/session_constants.dart';
import 'package:hrv_slope_app/data/database/app_database.dart';
import 'package:hrv_slope_app/shared/engine/calculation_preview.dart';

class MultiSessionEventInput {
  final int? teamId;
  final String date;
  final String? taskName;
  final String? sport;
  final String? sessionType;
  final String? protocolName;
  final String? contextEnvironment;
  final double recoveryWindowStartMin;
  final double recoveryWindowEndMin;
  final String loadType;
  final String loadMetricName;
  final String? loadUnit;

  const MultiSessionEventInput({
    this.teamId,
    required this.date,
    this.taskName,
    this.sport,
    this.sessionType,
    this.protocolName,
    this.contextEnvironment,
    required this.recoveryWindowStartMin,
    required this.recoveryWindowEndMin,
    required this.loadType,
    required this.loadMetricName,
    this.loadUnit,
  });
}

class MultiSessionRowInput {
  final int athleteId;
  final CalculationPreview preview;
  final RmssdRecoverySourceType? rmssdRecoverySource;
  final String? notes;

  const MultiSessionRowInput({
    required this.athleteId,
    required this.preview,
    this.rmssdRecoverySource,
    this.notes,
  });
}

class MultiSessionSaveResult {
  final int eventId;
  final List<int> sessionIds;

  const MultiSessionSaveResult({
    required this.eventId,
    required this.sessionIds,
  });
}

class MultiSessionSaveService {
  final AppDatabase database;

  const MultiSessionSaveService(this.database);

  Future<MultiSessionSaveResult> saveEventWithSessions({
    required MultiSessionEventInput event,
    required List<MultiSessionRowInput> rows,
  }) async {
    await _validateInput(event, rows);
    final now = DateTime.now().toIso8601String();
    final cleanLoadType = _normalizeLoadType(event.loadType);
    final cleanLoadMetric = _requiredTrimmed(
      event.loadMetricName,
      'Load metric name',
    );
    final cleanLoadUnit = _blankToNull(event.loadUnit);

    return database.transaction(() async {
      final eventId = await database.sessionEventsDao.createEvent(
        SessionEventsCompanion.insert(
          teamId: drift.Value(event.teamId),
          date: _requiredTrimmed(event.date, 'Event date'),
          taskName: drift.Value(_blankToNull(event.taskName)),
          sport: drift.Value(_blankToNull(event.sport)),
          sessionType: drift.Value(_blankToNull(event.sessionType)),
          protocolName: drift.Value(_blankToNull(event.protocolName)),
          contextEnvironment: drift.Value(
            _blankToNull(event.contextEnvironment),
          ),
          recoveryWindowStartMin: event.recoveryWindowStartMin,
          recoveryWindowEndMin: event.recoveryWindowEndMin,
          loadType: cleanLoadType,
          loadMetricName: cleanLoadMetric,
          loadUnit: drift.Value(cleanLoadUnit),
          createdAt: now,
          updatedAt: now,
        ),
      );

      final sessionIds = <int>[];
      for (final row in rows) {
        final sessionId = await database.sessionsDao.insertSession(
          _sessionCompanion(event: event, row: row, eventId: eventId, now: now),
        );
        sessionIds.add(sessionId);

        await database.sessionsDao.insertHrvMeasurement(
          _hrvMeasurementCompanion(sessionId, row.preview, now),
        );
        await database.sessionsDao.insertVariables(
          _variableCompanions(sessionId, row.preview, now),
        );
      }

      return MultiSessionSaveResult(eventId: eventId, sessionIds: sessionIds);
    });
  }

  Future<void> _validateInput(
    MultiSessionEventInput event,
    List<MultiSessionRowInput> rows,
  ) async {
    _requiredTrimmed(event.date, 'Event date');
    final loadType = _normalizeLoadType(event.loadType);
    final loadMetricName = _requiredTrimmed(
      event.loadMetricName,
      'Load metric name',
    );
    final loadUnit = _blankToNull(event.loadUnit);
    _validateRecoveryWindow(
      event.recoveryWindowStartMin,
      event.recoveryWindowEndMin,
    );
    await _validateTeamCanCreateEvent(event.teamId);
    _validateLoadUnitAgainstKnownMetric(loadType, loadMetricName, loadUnit);
    if (rows.isEmpty) {
      throw ArgumentError('At least one athlete row is required.');
    }

    final athleteIds = <int>{};
    for (final row in rows) {
      if (!athleteIds.add(row.athleteId)) {
        throw ArgumentError('Duplicate athleteId ${row.athleteId}.');
      }
      _validatePreviewMatchesEventWindow(row.preview, event);
      _validateRowHasEventLoadVariable(
        row.preview,
        loadType,
        loadMetricName,
        loadUnit,
      );
    }
  }

  Future<void> _validateTeamCanCreateEvent(int? teamId) async {
    if (teamId == null) return;
    final team = await database.teamsDao.getTeamById(teamId);
    if (team == null) {
      throw StateError('Team not found.');
    }
    if (team.isArchived) {
      throw StateError('Archived teams cannot be used for new sessions.');
    }
  }

  SessionsCompanion _sessionCompanion({
    required MultiSessionEventInput event,
    required MultiSessionRowInput row,
    required int eventId,
    required String now,
  }) {
    final p = row.preview;
    final rrPrep = p.recoveryRrPreprocessing;
    final rrQuality =
        p.hrvInputMode == HrvInputMode.rrIntervals && rrPrep != null
        ? rrPrep.qualityDecision.name
        : null;
    final rrArtifactPercent =
        p.hrvInputMode == HrvInputMode.rrIntervals && rrPrep != null
        ? rrPrep.artifactPercent
        : null;

    return SessionsCompanion.insert(
      athleteId: row.athleteId,
      eventId: drift.Value(eventId),
      date: _requiredTrimmed(event.date, 'Event date'),
      taskName: drift.Value(_blankToNull(event.taskName)),
      sport: drift.Value(_blankToNull(event.sport)),
      sessionType: drift.Value(_blankToNull(event.sessionType)),
      protocolName: drift.Value(_blankToNull(event.protocolName)),
      contextEnvironment: drift.Value(_blankToNull(event.contextEnvironment)),
      isDraft: const drift.Value(false),
      intensityPercent: drift.Value(p.intensityPercent),
      intensitySource: drift.Value(p.intensityResolution?.method),
      recoveryTimeMin: drift.Value(p.tUsedForSlope),
      recoveryWindowStartMin: drift.Value(p.recoveryWindowStartMin),
      recoveryWindowEndMin: drift.Value(p.recoveryWindowEndMin),
      rmssdExercise: drift.Value(p.rmssdExercise),
      rmssdExerciseIsDefault: drift.Value(p.usedFallbackExercise),
      rmssdRecovery: drift.Value(p.rmssdRecovery),
      slopeRaw: drift.Value(p.rawSlope),
      slopeInterpreted: drift.Value(p.interpretedSlope),
      itlIndex: drift.Value(p.itlIndex),
      classification: drift.Value(p.classification),
      hrvInputMode: drift.Value(p.hrvInputMode.value),
      rmssdRecoverySource: drift.Value(
        row.rmssdRecoverySource?.value ?? _recoverySourceValue(p),
      ),
      rmssdExerciseSource: drift.Value(p.rmssdExerciseSource.storageValue),
      rrQualityFlag: drift.Value(rrQuality),
      rrArtifactPercent: drift.Value(rrArtifactPercent),
      rrPreprocessingMode: drift.Value(p.rrPreprocessingMode?.name),
      rrCorrectionEnabled: drift.Value(p.correctionEnabled),
      rrCorrectionMethod: drift.Value(p.correctionMethod?.name),
      rrRawRmssd: drift.Value(p.rawRmssd),
      rrCorrectedRmssd: drift.Value(p.correctedRmssd),
      rrRmssdUsed: drift.Value(
        p.hrvInputMode == HrvInputMode.rrIntervals ? p.rmssdUsedForSlope : null,
      ),
      rrArtifactCount: drift.Value(p.artifactCount),
      rrQualityDecision: drift.Value(p.qualityDecision?.name),
      rrQualityNotesJson: drift.Value(
        p.qualityNotes.isEmpty ? null : jsonEncode(p.qualityNotes),
      ),
      rrRmssdDeltaPercent: drift.Value(rrPrep?.rmssdDeltaPercent),
      notes: drift.Value(_blankToNull(row.notes)),
      createdAt: now,
    );
  }

  MeasurementsHrvCompanion _hrvMeasurementCompanion(
    int sessionId,
    CalculationPreview preview,
    String now,
  ) {
    return MeasurementsHrvCompanion.insert(
      sessionId: sessionId,
      phase: 'recovery',
      windowStartMin: drift.Value(preview.recoveryWindowStartMin),
      windowEndMin: drift.Value(preview.recoveryWindowEndMin),
      rmssd: drift.Value(preview.rmssdRecovery),
      createdAt: now,
    );
  }

  List<IntensityVariablesCompanion> _variableCompanions(
    int sessionId,
    CalculationPreview preview,
    String now,
  ) {
    final variables = <IntensityVariablesCompanion>[];
    for (final v in [
      ...preview.externalVariables,
      ...preview.internalVariables,
    ]) {
      variables.add(
        IntensityVariablesCompanion.insert(
          sessionId: sessionId,
          category: v.category,
          name: v.name,
          unit: drift.Value(v.unit),
          value: v.value,
          source: drift.Value(v.source),
          isPrimaryForNomogram: drift.Value(v.isPrimaryForNomogram),
          notes: drift.Value(v.notes),
          createdAt: now,
        ),
      );
    }
    variables.addAll([
      IntensityVariablesCompanion.insert(
        sessionId: sessionId,
        category: 'derived',
        name: 'raw_slope',
        value: preview.rawSlope,
        source: const drift.Value('calculated'),
        createdAt: now,
      ),
      IntensityVariablesCompanion.insert(
        sessionId: sessionId,
        category: 'derived',
        name: 'interpreted_slope',
        value: preview.interpretedSlope,
        source: const drift.Value('calculated'),
        createdAt: now,
      ),
      IntensityVariablesCompanion.insert(
        sessionId: sessionId,
        category: 'derived',
        name: 'itl_index',
        value: preview.itlIndex,
        source: const drift.Value('calculated'),
        createdAt: now,
      ),
    ]);
    if (preview.intensityPercent != null) {
      variables.add(
        IntensityVariablesCompanion.insert(
          sessionId: sessionId,
          category: 'derived',
          name: 'intensity_percent',
          value: preview.intensityPercent!,
          source: drift.Value(preview.intensityResolution?.method),
          isPrimaryForNomogram: const drift.Value(true),
          createdAt: now,
        ),
      );
    }
    return variables;
  }
}

String _recoverySourceValue(CalculationPreview preview) {
  if (preview.hrvInputMode == HrvInputMode.rrIntervals ||
      preview.rmssdRecoverySource == RmssdSource.computedFromRr) {
    return RmssdRecoverySourceType.computedFromRr.value;
  }
  return RmssdRecoverySourceType.manual.value;
}

void _validateRecoveryWindow(double startMin, double endMin) {
  if (!startMin.isFinite || !endMin.isFinite || startMin < 0 || endMin <= 0) {
    throw ArgumentError('Recovery window values must be finite and positive.');
  }
  if (endMin <= startMin) {
    throw ArgumentError('Recovery window end must be after start.');
  }
}

void _validatePreviewMatchesEventWindow(
  CalculationPreview preview,
  MultiSessionEventInput event,
) {
  const tolerance = 0.000001;
  final startDiff =
      (preview.recoveryWindowStartMin - event.recoveryWindowStartMin).abs();
  final endDiff = (preview.recoveryWindowEndMin - event.recoveryWindowEndMin)
      .abs();
  if (startDiff > tolerance || endDiff > tolerance) {
    throw ArgumentError(
      'Row preview recovery window must match the event recovery window.',
    );
  }
}

void _validateRowHasEventLoadVariable(
  CalculationPreview preview,
  String loadType,
  String loadMetricName,
  String? loadUnit,
) {
  final variables = loadType == 'external'
      ? preview.externalVariables
      : preview.internalVariables;
  final normalizedMetric = loadMetricName.trim().toLowerCase();
  final matchingVariables = variables.where(
    (v) => v.name.trim().toLowerCase() == normalizedMetric && v.value.isFinite,
  );
  if (matchingVariables.isEmpty) {
    throw ArgumentError(
      'Each row must contain the event load metric $loadMetricName.',
    );
  }
  for (final variable in matchingVariables) {
    if (_normalizeUnit(variable.unit) != _normalizeUnit(loadUnit)) {
      throw ArgumentError(
        'Load unit for $loadMetricName must match the event unit.',
      );
    }
  }
}

void _validateLoadUnitAgainstKnownMetric(
  String loadType,
  String loadMetricName,
  String? loadUnit,
) {
  final definition = _loadDefinition(loadType, loadMetricName);
  if (definition == null) return;
  if (_normalizeUnit(definition.unit) != _normalizeUnit(loadUnit)) {
    throw ArgumentError(
      'Load unit for $loadMetricName must be ${definition.unit ?? ''}.',
    );
  }
}

String _normalizeLoadType(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized != 'internal' && normalized != 'external') {
    throw ArgumentError('Load type must be internal or external.');
  }
  return normalized;
}

String _requiredTrimmed(String value, String fieldName) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    throw ArgumentError('$fieldName cannot be empty.');
  }
  return trimmed;
}

String? _blankToNull(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}

String? _normalizeUnit(String? value) {
  final trimmed = value?.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed.toLowerCase();
}

VariableDefinition? _loadDefinition(String loadType, String metricName) {
  final variables = loadType == 'external'
      ? StandardVariables.externalVariables
      : StandardVariables.internalVariables;
  final normalizedMetric = metricName.trim().toLowerCase();
  for (final variable in variables) {
    if (variable.name.toLowerCase() == normalizedMetric) {
      return variable;
    }
  }
  return null;
}
