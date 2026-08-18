import 'package:hrv_slope_app/core/constants/hrv_sources.dart';
import 'package:hrv_slope_app/core/constants/session_constants.dart';
import 'package:hrv_slope_app/data/database/app_database.dart';
import 'package:hrv_slope_app/data/services/multi_session_save_service.dart';
import 'package:hrv_slope_app/shared/engine/calculation_preview.dart';
import 'package:hrv_slope_app/shared/engine/intensity_resolver.dart';
import 'package:hrv_slope_app/shared/engine/nomogram_engine.dart';

enum MultiSessionRowStatus { omitted, valid, invalid }

enum MultiSessionField {
  athlete,
  rmssdExercise,
  rmssdRecovery,
  load,
  unit,
  calculation,
}

class MultiSessionEntryHeader {
  final int? teamId;
  final String date;
  final String? taskName;
  final String? sport;
  final String? sessionType;
  final String? protocolName;
  final String? contextEnvironment;
  final double? recoveryWindowStartMin;
  final double? recoveryWindowEndMin;
  final String loadType;
  final String loadMetricName;
  final String? loadUnit;

  const MultiSessionEntryHeader({
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

  MultiSessionEventInput toSaveInput() {
    final start = recoveryWindowStartMin;
    final end = recoveryWindowEndMin;
    if (start == null || end == null) {
      throw StateError('Recovery window must be valid before saving.');
    }
    return MultiSessionEventInput(
      teamId: teamId,
      date: date,
      taskName: _blankToNull(taskName),
      sport: _blankToNull(sport),
      sessionType: _blankToNull(sessionType),
      protocolName: _blankToNull(protocolName),
      contextEnvironment: _blankToNull(contextEnvironment),
      recoveryWindowStartMin: start,
      recoveryWindowEndMin: end,
      loadType: loadType,
      loadMetricName: loadMetricName,
      loadUnit: _blankToNull(loadUnit),
    );
  }
}

class MultiSessionDraftRow {
  final int localId;
  final Athlete? athlete;
  final String rmssdExerciseText;
  final String rmssdRecoveryText;
  final String loadText;

  const MultiSessionDraftRow({
    required this.localId,
    required this.athlete,
    required this.rmssdExerciseText,
    required this.rmssdRecoveryText,
    required this.loadText,
  });

  bool get hasAnyInput {
    return rmssdExerciseText.trim().isNotEmpty ||
        rmssdRecoveryText.trim().isNotEmpty ||
        loadText.trim().isNotEmpty;
  }
}

class MultiSessionRowEvaluation {
  final int localId;
  final Athlete? athlete;
  final MultiSessionRowStatus status;
  final Map<MultiSessionField, String> fieldErrors;
  final CalculationPreview? preview;
  final bool usesExerciseFallback;
  final double? loadValue;

  const MultiSessionRowEvaluation({
    required this.localId,
    required this.athlete,
    required this.status,
    this.fieldErrors = const {},
    this.preview,
    this.usesExerciseFallback = false,
    this.loadValue,
  });

  bool get isValid => status == MultiSessionRowStatus.valid;
  bool get isInvalid => status == MultiSessionRowStatus.invalid;
  bool get isOmitted => status == MultiSessionRowStatus.omitted;

  String get statusLabel {
    return switch (status) {
      MultiSessionRowStatus.valid =>
        usesExerciseFallback ? 'Valid - 4.0 default' : 'Valid',
      MultiSessionRowStatus.invalid => fieldErrors.values.join('; '),
      MultiSessionRowStatus.omitted => 'Omitted',
    };
  }

  MultiSessionRowInput toSaveInput() {
    final currentAthlete = athlete;
    final currentPreview = preview;
    if (currentAthlete == null || currentPreview == null || !isValid) {
      throw StateError('Only valid rows can be converted to save input.');
    }
    return MultiSessionRowInput(
      athleteId: currentAthlete.id,
      preview: currentPreview,
      rmssdRecoverySource: RmssdRecoverySourceType.manual,
    );
  }
}

class MultiSessionTableEvaluation {
  final List<String> headerErrors;
  final List<MultiSessionRowEvaluation> rows;

  const MultiSessionTableEvaluation({
    required this.headerErrors,
    required this.rows,
  });

  int get rowCount => rows.length;
  int get validCount => rows.where((row) => row.isValid).length;
  int get errorCount => rows.where((row) => row.isInvalid).length;
  int get omittedCount => rows.where((row) => row.isOmitted).length;
  bool get canSave => headerErrors.isEmpty && errorCount == 0 && validCount > 0;

  List<MultiSessionRowInput> toSaveRows() {
    return rows
        .where((row) => row.isValid)
        .map((row) => row.toSaveInput())
        .toList(growable: false);
  }
}

class MultiSessionEntryValidationService {
  const MultiSessionEntryValidationService();

  MultiSessionTableEvaluation evaluate({
    required MultiSessionEntryHeader header,
    required List<MultiSessionDraftRow> rows,
    PopulationNomogramSource populationPreset =
        PopulationNomogramSource.excelOperational,
  }) {
    final headerErrors = _validateHeader(header);
    final duplicateAthleteIds = _duplicateAthleteIds(rows);
    final evaluations = rows
        .map(
          (row) => _evaluateRow(
            header: header,
            row: row,
            duplicateAthleteIds: duplicateAthleteIds,
            headerIsValid: headerErrors.isEmpty,
            populationPreset: populationPreset,
          ),
        )
        .toList(growable: false);

    return MultiSessionTableEvaluation(
      headerErrors: headerErrors,
      rows: evaluations,
    );
  }

  List<String> _validateHeader(MultiSessionEntryHeader header) {
    final errors = <String>[];
    if (header.date.trim().isEmpty || DateTime.tryParse(header.date) == null) {
      errors.add('Date/time is required.');
    }
    if (_blankToNull(header.taskName) == null) {
      errors.add('Task is required.');
    }
    if (_blankToNull(header.sport) == null) {
      errors.add('Sport is required.');
    }
    final loadType = header.loadType.trim().toLowerCase();
    if (loadType != 'internal' && loadType != 'external') {
      errors.add('Load type must be internal or external.');
    }
    if (_blankToNull(header.loadMetricName) == null) {
      errors.add('Load metric is required.');
    }
    final start = header.recoveryWindowStartMin;
    final end = header.recoveryWindowEndMin;
    if (start == null || end == null) {
      errors.add('Recovery window is required.');
    } else {
      if (!start.isFinite || !end.isFinite || start < 0 || end <= 0) {
        errors.add('Recovery window values must be finite and positive.');
      } else if (end <= start) {
        errors.add('Recovery window end must be after start.');
      }
    }
    final definition = _definitionFor(header);
    if (definition != null &&
        _normalizeUnit(definition.unit) != _normalizeUnit(header.loadUnit)) {
      errors.add('Load unit must be ${definition.unit ?? ''}.');
    }
    return errors;
  }

  Set<int> _duplicateAthleteIds(List<MultiSessionDraftRow> rows) {
    final seen = <int>{};
    final duplicates = <int>{};
    for (final row in rows) {
      final athleteId = row.athlete?.id;
      if (athleteId == null) continue;
      if (!seen.add(athleteId)) duplicates.add(athleteId);
    }
    return duplicates;
  }

  MultiSessionRowEvaluation _evaluateRow({
    required MultiSessionEntryHeader header,
    required MultiSessionDraftRow row,
    required Set<int> duplicateAthleteIds,
    required bool headerIsValid,
    required PopulationNomogramSource populationPreset,
  }) {
    final athlete = row.athlete;
    final errors = <MultiSessionField, String>{};

    if (athlete == null && !row.hasAnyInput) {
      return MultiSessionRowEvaluation(
        localId: row.localId,
        athlete: null,
        status: MultiSessionRowStatus.omitted,
      );
    }
    if (athlete == null) {
      errors[MultiSessionField.athlete] = 'Select athlete';
    } else if (duplicateAthleteIds.contains(athlete.id)) {
      errors[MultiSessionField.athlete] = 'Duplicate athlete';
    }

    final recoveryText = row.rmssdRecoveryText.trim();
    final loadText = row.loadText.trim();
    final exerciseText = row.rmssdExerciseText.trim();
    final rowHasSessionData =
        recoveryText.isNotEmpty ||
        loadText.isNotEmpty ||
        exerciseText.isNotEmpty;
    if (!rowHasSessionData && errors.isEmpty) {
      return MultiSessionRowEvaluation(
        localId: row.localId,
        athlete: athlete,
        status: MultiSessionRowStatus.omitted,
      );
    }

    final rmssdRecovery = _parseFinite(recoveryText);
    if (recoveryText.isEmpty) {
      errors[MultiSessionField.rmssdRecovery] = 'Required';
    } else if (rmssdRecovery == null || rmssdRecovery <= 0) {
      errors[MultiSessionField.rmssdRecovery] = 'Must be > 0';
    }

    double? rmssdExercise;
    final usesFallbackExercise = exerciseText.isEmpty;
    if (exerciseText.isNotEmpty) {
      rmssdExercise = _parseFinite(exerciseText);
      if (rmssdExercise == null || rmssdExercise <= 0) {
        errors[MultiSessionField.rmssdExercise] = 'Must be > 0';
      }
    }

    final loadValue = _parseFinite(loadText);
    if (loadText.isEmpty) {
      errors[MultiSessionField.load] = 'Required';
    } else if (loadValue == null) {
      errors[MultiSessionField.load] = 'Must be finite';
    }

    final definition = _definitionFor(header);
    if (definition != null &&
        _normalizeUnit(definition.unit) != _normalizeUnit(header.loadUnit)) {
      errors[MultiSessionField.unit] = 'Unit must be ${definition.unit ?? ''}';
    }

    if (!headerIsValid) {
      errors[MultiSessionField.calculation] = 'Fix header first';
    }

    if (errors.isNotEmpty ||
        athlete == null ||
        rmssdRecovery == null ||
        loadValue == null) {
      return MultiSessionRowEvaluation(
        localId: row.localId,
        athlete: athlete,
        status: MultiSessionRowStatus.invalid,
        fieldErrors: errors,
        usesExerciseFallback: usesFallbackExercise,
        loadValue: loadValue,
      );
    }

    try {
      final taggedVariable = TaggedVariable(
        category: header.loadType.trim().toLowerCase(),
        name: header.loadMetricName.trim(),
        unit: definition?.unit ?? _blankToNull(header.loadUnit),
        value: loadValue,
        source: 'manual',
      );
      final externalVariables =
          header.loadType.trim().toLowerCase() == 'external'
          ? [taggedVariable]
          : const <TaggedVariable>[];
      final internalVariables =
          header.loadType.trim().toLowerCase() == 'internal'
          ? [taggedVariable]
          : const <TaggedVariable>[];
      final values = {header.loadMetricName.trim(): loadValue};
      final intensity = resolveIntensityPercent(
        inputs: IntensityInputs(
          percentMas: values['percent_mas'],
          percentVvo2max: values['percent_vvo2max'],
          percentMap: values['percent_map'],
          speedKmh: values['speed_kmh'],
          powerW: values['power_w'],
          rpe110: values['rpe_1_10'],
          sessionRpe110: values['session_rpe_1_10'],
          subjectiveFatigue110: values['subjective_fatigue_1_10'],
          percentHrmax: values['percent_hrmax'],
          internalLoadPercent: values['internal_load_percent'],
        ),
        athlete: AthleteReferenceValues(
          masKmh: athlete.masKmh,
          vvo2maxKmh: athlete.vvo2maxKmh,
          mapW: athlete.mapW,
        ),
      );
      final preview = buildCalculationPreview(
        athleteName: athlete.name,
        sessionDate: header.date,
        sessionName: _blankToNull(header.taskName),
        sport: _blankToNull(header.sport),
        externalVariables: externalVariables,
        internalVariables: internalVariables,
        intensityResolution: intensity,
        rmssdExercise: rmssdExercise,
        rmssdExerciseSource: usesFallbackExercise
            ? RmssdSource.fallback4Ms
            : RmssdSource.measured,
        rmssdRecovery: rmssdRecovery,
        rmssdRecoverySource: RmssdSource.measured,
        hrvInputMode: HrvInputMode.directRmssd,
        recoveryWindowStartMin: header.recoveryWindowStartMin!,
        recoveryWindowEndMin: header.recoveryWindowEndMin!,
        populationPreset: populationPreset,
      );
      return MultiSessionRowEvaluation(
        localId: row.localId,
        athlete: athlete,
        status: MultiSessionRowStatus.valid,
        preview: preview,
        usesExerciseFallback: usesFallbackExercise,
        loadValue: loadValue,
      );
    } catch (error) {
      errors[MultiSessionField.calculation] = error.toString();
      return MultiSessionRowEvaluation(
        localId: row.localId,
        athlete: athlete,
        status: MultiSessionRowStatus.invalid,
        fieldErrors: errors,
        usesExerciseFallback: usesFallbackExercise,
        loadValue: loadValue,
      );
    }
  }
}

double? _parseFinite(String text) {
  final normalized = text.trim().replaceAll(',', '.');
  if (normalized.isEmpty) return null;
  final value = double.tryParse(normalized);
  if (value == null || !value.isFinite) return null;
  return value;
}

VariableDefinition? _definitionFor(MultiSessionEntryHeader header) {
  final loadType = header.loadType.trim().toLowerCase();
  final metricName = header.loadMetricName.trim().toLowerCase();
  final definitions = loadType == 'external'
      ? StandardVariables.externalVariables
      : StandardVariables.internalVariables;
  for (final definition in definitions) {
    if (definition.name.toLowerCase() == metricName) return definition;
  }
  return null;
}

String? _normalizeUnit(String? value) {
  final trimmed = value?.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed.toLowerCase();
}

String? _blankToNull(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}
