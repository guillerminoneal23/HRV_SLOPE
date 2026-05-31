library;

import 'package:drift/drift.dart' as drift;
import 'package:hrv_slope_app/core/constants/hrv_sources.dart';
import 'package:hrv_slope_app/core/constants/session_constants.dart';
import 'package:hrv_slope_app/data/database/app_database.dart';
import 'package:hrv_slope_app/data/database/daos/sessions_dao.dart';
import 'package:hrv_slope_app/shared/engine/calculation_preview.dart';
import 'package:hrv_slope_app/shared/engine/intensity_resolver.dart';
import 'package:hrv_slope_app/shared/engine/nomogram_engine.dart';

class SessionEditInput {
  final int sessionId;
  final String date;
  final String? taskName;
  final String? sport;
  final String? sessionType;
  final String? protocolName;
  final String? contextEnvironment;
  final String? notes;
  final Map<String, double> externalVariables;
  final Map<String, double> internalVariables;
  final double rmssdRecovery;
  final double? rmssdExercise;
  final RmssdRecoverySourceType rmssdRecoverySource;
  final double recoveryWindowStartMin;
  final double recoveryWindowEndMin;
  final PopulationNomogramSource populationPreset;

  const SessionEditInput({
    required this.sessionId,
    required this.date,
    this.taskName,
    this.sport,
    this.sessionType,
    this.protocolName,
    this.contextEnvironment,
    this.notes,
    this.externalVariables = const {},
    this.internalVariables = const {},
    required this.rmssdRecovery,
    this.rmssdExercise,
    this.rmssdRecoverySource = RmssdRecoverySourceType.manual,
    required this.recoveryWindowStartMin,
    required this.recoveryWindowEndMin,
    this.populationPreset = PopulationNomogramSource.excelOperational,
  });
}

class SessionEditResult {
  final SessionDetail detail;
  final CalculationPreview preview;

  const SessionEditResult({required this.detail, required this.preview});
}

class SessionEditService {
  final AppDatabase database;

  const SessionEditService(this.database);

  Future<SessionEditResult> updateDirectRmssdSession(
    SessionEditInput input,
  ) async {
    final existing = await database.sessionsDao.getSessionDetail(
      input.sessionId,
    );
    if (existing == null) {
      throw StateError('Session not found.');
    }

    final extVars = _taggedVariables(
      input.externalVariables,
      StandardVariables.externalVariables,
      'external',
    );
    final intVars = _taggedVariables(
      input.internalVariables,
      StandardVariables.internalVariables,
      'internal',
    );
    final intensity = resolveIntensityPercent(
      inputs: IntensityInputs(
        percentMas: input.externalVariables['percent_mas'],
        percentVvo2max: input.externalVariables['percent_vvo2max'],
        percentMap: input.externalVariables['percent_map'],
        speedKmh: input.externalVariables['speed_kmh'],
        powerW: input.externalVariables['power_w'],
      ),
      athlete: AthleteReferenceValues(
        masKmh: existing.athlete.masKmh,
        vvo2maxKmh: existing.athlete.vvo2maxKmh,
        mapW: existing.athlete.mapW,
      ),
    );

    final preview = buildCalculationPreview(
      athleteName: existing.athlete.name,
      sessionDate: input.date,
      sessionName: input.taskName,
      sport: input.sport,
      externalVariables: extVars,
      internalVariables: intVars,
      intensityResolution: intensity,
      rmssdExercise: input.rmssdExercise,
      rmssdExerciseSource: input.rmssdExercise == null
          ? RmssdSource.fallback4Ms
          : RmssdSource.measured,
      rmssdRecovery: input.rmssdRecovery,
      rmssdRecoverySource: RmssdSource.measured,
      hrvInputMode: HrvInputMode.directRmssd,
      recoveryWindowStartMin: input.recoveryWindowStartMin,
      recoveryWindowEndMin: input.recoveryWindowEndMin,
      populationPreset: input.populationPreset,
    );

    final now = DateTime.now().toIso8601String();
    await database.transaction(() async {
      await database.sessionsDao.updateSessionPartial(
        input.sessionId,
        SessionsCompanion(
          date: drift.Value(input.date),
          taskName: drift.Value(_blankToNull(input.taskName)),
          sport: drift.Value(_blankToNull(input.sport)),
          sessionType: drift.Value(_blankToNull(input.sessionType)),
          protocolName: drift.Value(_blankToNull(input.protocolName)),
          contextEnvironment: drift.Value(
            _blankToNull(input.contextEnvironment),
          ),
          isDraft: const drift.Value(false),
          intensityPercent: drift.Value(preview.intensityPercent),
          intensitySource: drift.Value(preview.intensityResolution?.method),
          recoveryTimeMin: drift.Value(preview.tUsedForSlope),
          recoveryWindowStartMin: drift.Value(preview.recoveryWindowStartMin),
          recoveryWindowEndMin: drift.Value(preview.recoveryWindowEndMin),
          rmssdExercise: drift.Value(preview.rmssdExercise),
          rmssdExerciseIsDefault: drift.Value(preview.usedFallbackExercise),
          rmssdRecovery: drift.Value(preview.rmssdRecovery),
          slopeRaw: drift.Value(preview.rawSlope),
          slopeInterpreted: drift.Value(preview.interpretedSlope),
          itlIndex: drift.Value(preview.itlIndex),
          classification: drift.Value(preview.classification),
          hrvInputMode: drift.Value(HrvInputMode.directRmssd.value),
          rmssdRecoverySource: drift.Value(input.rmssdRecoverySource.value),
          rmssdExerciseSource: drift.Value(preview.rmssdExerciseSource.name),
          rrQualityFlag: const drift.Value(null),
          rrArtifactPercent: const drift.Value(null),
          rrPreprocessingMode: const drift.Value(null),
          rrCorrectionEnabled: const drift.Value(false),
          rrCorrectionMethod: const drift.Value(null),
          rrRawRmssd: const drift.Value(null),
          rrCorrectedRmssd: const drift.Value(null),
          rrRmssdUsed: const drift.Value(null),
          rrArtifactCount: const drift.Value(null),
          rrQualityDecision: const drift.Value(null),
          rrQualityNotesJson: const drift.Value(null),
          rrRmssdDeltaPercent: const drift.Value(null),
          notes: drift.Value(_blankToNull(input.notes)),
        ),
      );

      await database.sessionsDao.deleteHrvMeasurementsForSession(
        input.sessionId,
      );
      await database.sessionsDao.insertHrvMeasurement(
        MeasurementsHrvCompanion.insert(
          sessionId: input.sessionId,
          phase: 'recovery',
          windowStartMin: drift.Value(preview.recoveryWindowStartMin),
          windowEndMin: drift.Value(preview.recoveryWindowEndMin),
          rmssd: drift.Value(preview.rmssdRecovery),
          createdAt: now,
        ),
      );

      await database.sessionsDao.deleteVariablesForSession(input.sessionId);
      await database.sessionsDao.insertVariables(
        _variableCompanions(input.sessionId, preview, now),
      );
    });

    final detail = await database.sessionsDao.getSessionDetail(input.sessionId);
    if (detail == null) {
      throw StateError('Updated session could not be loaded.');
    }
    return SessionEditResult(detail: detail, preview: preview);
  }

  Future<void> deleteSessionCascade(int sessionId) {
    return database.sessionsDao.deleteSessionCascade(sessionId);
  }

  List<String> missingScientificFields(SessionDetail detail) {
    final missing = <String>[];
    final session = detail.session;
    final external = detail.variablesByCategory('external');
    final internal = detail.variablesByCategory('internal');

    if (external.isEmpty) missing.add('missing external variable');
    if (internal.isEmpty) missing.add('missing internal variable');
    if (session.rmssdRecovery == null) missing.add('missing HRV/RMSSD');
    if (session.recoveryWindowStartMin == null ||
        session.recoveryWindowEndMin == null) {
      missing.add('missing recovery window');
    }
    if (session.intensityPercent == null) {
      missing.add('missing intensity percent for classification');
    }
    return missing;
  }

  List<TaggedVariable> _taggedVariables(
    Map<String, double> values,
    List<VariableDefinition> definitions,
    String category,
  ) {
    return values.entries.map((entry) {
      final def = definitions.where((d) => d.name == entry.key).firstOrNull;
      return TaggedVariable(
        category: category,
        name: entry.key,
        unit: def?.unit,
        value: entry.value,
        source: 'manual',
      );
    }).toList();
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

String? _blankToNull(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}
