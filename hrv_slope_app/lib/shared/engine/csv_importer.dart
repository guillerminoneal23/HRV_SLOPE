/// CSV Importer — Pure Dart logic for parsing, validating, and mapping
/// CSV session data into the HRV Slope App data model.
///
/// This engine handles column mapping, row-level validation, and
/// produces structured import results without touching the database.
library;

import 'package:csv/csv.dart';

/// Standard column names supported by the CSV importer.
abstract final class CsvColumns {
  static const athleteName = 'athlete_name';
  static const date = 'date';
  static const sessionName = 'session_name';
  static const sport = 'sport';
  static const sessionType = 'session_type';
  static const speedKmh = 'speed_kmh';
  static const percentMas = 'percent_mas';
  static const percentVvo2max = 'percent_vvo2max';
  static const powerW = 'power_w';
  static const percentMap = 'percent_map';
  static const rpe110 = 'rpe_1_10';
  static const srpe = 'srpe';
  static const trimp = 'trimp';
  static const rmssdExercise = 'rmssd_exercise';
  static const rmssdRecovery = 'rmssd_recovery';
  static const recoveryWindowStartMin = 'recovery_window_start_min';
  static const recoveryWindowEndMin = 'recovery_window_end_min';
  static const notes = 'notes';

  static const allColumns = [
    athleteName,
    date,
    sessionName,
    sport,
    sessionType,
    speedKmh,
    percentMas,
    percentVvo2max,
    powerW,
    percentMap,
    rpe110,
    srpe,
    trimp,
    rmssdExercise,
    rmssdRecovery,
    recoveryWindowStartMin,
    recoveryWindowEndMin,
    notes,
  ];

  static const requiredColumns = [athleteName, date, rmssdRecovery];
}

/// Column mapping from CSV header to standard variable name.
class CsvColumnMapping {
  /// Map from CSV header index to standard column name.
  final Map<int, String> indexToColumn;

  /// Headers from the CSV file.
  final List<String> headers;

  const CsvColumnMapping({required this.indexToColumn, required this.headers});

  /// Columns that could not be mapped.
  List<String> get unmappedHeaders {
    final mapped = indexToColumn.keys.toSet();
    return [
      for (int i = 0; i < headers.length; i++)
        if (!mapped.contains(i)) headers[i],
    ];
  }

  /// Whether all required columns are mapped.
  bool get hasRequiredColumns {
    final mappedColumns = indexToColumn.values.toSet();
    return CsvColumns.requiredColumns.every(mappedColumns.contains);
  }

  /// Missing required columns.
  List<String> get missingRequired {
    final mappedColumns = indexToColumn.values.toSet();
    return CsvColumns.requiredColumns
        .where((c) => !mappedColumns.contains(c))
        .toList();
  }
}

/// A single parsed row from the CSV import.
class CsvParsedRow {
  final int rowIndex;
  final Map<String, String> values;
  final List<String> errors;
  final List<String> warnings;

  CsvParsedRow({
    required this.rowIndex,
    required this.values,
    List<String>? errors,
    List<String>? warnings,
  }) : errors = errors ?? [],
       warnings = warnings ?? [];

  bool get hasErrors => errors.isNotEmpty;
  bool get isValid => !hasErrors;

  String? get athleteName => values[CsvColumns.athleteName];
  String? get date => values[CsvColumns.date];
  String? get sessionName => values[CsvColumns.sessionName];
  String? get sport => values[CsvColumns.sport];
  String? get sessionType => values[CsvColumns.sessionType];
  double? get speedKmh => _tryDouble(CsvColumns.speedKmh);
  double? get percentMas => _tryDouble(CsvColumns.percentMas);
  double? get percentVvo2max => _tryDouble(CsvColumns.percentVvo2max);
  double? get powerW => _tryDouble(CsvColumns.powerW);
  double? get percentMap => _tryDouble(CsvColumns.percentMap);
  double? get rpe110 => _tryDouble(CsvColumns.rpe110);
  double? get srpe => _tryDouble(CsvColumns.srpe);
  double? get trimp => _tryDouble(CsvColumns.trimp);
  double? get rmssdExercise => _tryDouble(CsvColumns.rmssdExercise);
  double? get rmssdRecovery => _tryDouble(CsvColumns.rmssdRecovery);
  double? get recoveryWindowStartMin =>
      _tryDouble(CsvColumns.recoveryWindowStartMin);
  double? get recoveryWindowEndMin =>
      _tryDouble(CsvColumns.recoveryWindowEndMin);
  String? get notes => values[CsvColumns.notes];

  /// Whether this row has at least one external load variable.
  bool get hasExternalLoad =>
      speedKmh != null ||
      percentMas != null ||
      percentVvo2max != null ||
      powerW != null ||
      percentMap != null;

  /// Whether this row has at least one internal intensity variable.
  bool get hasInternalLoad => rpe110 != null || srpe != null || trimp != null;

  /// Whether this row has sufficient HRV data for slope calculation.
  bool get hasHrvForSlope =>
      rmssdRecovery != null &&
      recoveryWindowStartMin != null &&
      recoveryWindowEndMin != null;

  double? _tryDouble(String key) {
    final v = values[key];
    if (v == null || v.isEmpty) return null;
    return double.tryParse(v);
  }
}

/// Result of a full CSV import parse operation.
class CsvImportResult {
  final List<CsvParsedRow> rows;
  final CsvColumnMapping mapping;
  final List<String> globalErrors;
  final List<String> globalWarnings;

  CsvImportResult({
    required this.rows,
    required this.mapping,
    List<String>? globalErrors,
    List<String>? globalWarnings,
  }) : globalErrors = globalErrors ?? [],
       globalWarnings = globalWarnings ?? [];

  int get totalRows => rows.length;
  int get validRows => rows.where((r) => r.isValid).length;
  int get errorRows => rows.where((r) => r.hasErrors).length;

  /// All unique athlete names found in valid rows.
  Set<String> get athleteNames => rows
      .where((r) => r.isValid && r.athleteName != null)
      .map((r) => r.athleteName!)
      .toSet();
}

/// Automatically maps CSV headers to standard column names.
///
/// Uses case-insensitive matching and common aliases.
CsvColumnMapping autoMapColumns(List<String> headers) {
  final mapping = <int, String>{};

  final aliases = <String, String>{
    'athlete_name': CsvColumns.athleteName,
    'athlete': CsvColumns.athleteName,
    'name': CsvColumns.athleteName,
    'nombre': CsvColumns.athleteName,
    'deportista': CsvColumns.athleteName,
    'date': CsvColumns.date,
    'fecha': CsvColumns.date,
    'session_name': CsvColumns.sessionName,
    'task': CsvColumns.sessionName,
    'tarea': CsvColumns.sessionName,
    'session': CsvColumns.sessionName,
    'sport': CsvColumns.sport,
    'deporte': CsvColumns.sport,
    'session_type': CsvColumns.sessionType,
    'tipo': CsvColumns.sessionType,
    'type': CsvColumns.sessionType,
    'speed_kmh': CsvColumns.speedKmh,
    'speed': CsvColumns.speedKmh,
    'velocidad': CsvColumns.speedKmh,
    'percent_mas': CsvColumns.percentMas,
    '%mas': CsvColumns.percentMas,
    '%_mas': CsvColumns.percentMas,
    'percent_vvo2max': CsvColumns.percentVvo2max,
    '%vvo2max': CsvColumns.percentVvo2max,
    '%_vvo2max': CsvColumns.percentVvo2max,
    'power_w': CsvColumns.powerW,
    'power': CsvColumns.powerW,
    'potencia': CsvColumns.powerW,
    'percent_map': CsvColumns.percentMap,
    '%map': CsvColumns.percentMap,
    '%_map': CsvColumns.percentMap,
    'rpe_1_10': CsvColumns.rpe110,
    'rpe': CsvColumns.rpe110,
    'epe': CsvColumns.rpe110,
    'srpe': CsvColumns.srpe,
    'trimp': CsvColumns.trimp,
    'rmssd_exercise': CsvColumns.rmssdExercise,
    'rmssd_ej': CsvColumns.rmssdExercise,
    'rmssd_ejercicio': CsvColumns.rmssdExercise,
    'rmssd_recovery': CsvColumns.rmssdRecovery,
    'rmssd_rec': CsvColumns.rmssdRecovery,
    'rmssd_recuperacion': CsvColumns.rmssdRecovery,
    'rmssd_recuperación': CsvColumns.rmssdRecovery,
    'recovery_window_start_min': CsvColumns.recoveryWindowStartMin,
    'rec_start': CsvColumns.recoveryWindowStartMin,
    'inicio_ventana': CsvColumns.recoveryWindowStartMin,
    'recovery_window_end_min': CsvColumns.recoveryWindowEndMin,
    'rec_end': CsvColumns.recoveryWindowEndMin,
    'fin_ventana': CsvColumns.recoveryWindowEndMin,
    'notes': CsvColumns.notes,
    'notas': CsvColumns.notes,
  };

  for (int i = 0; i < headers.length; i++) {
    final normalized = headers[i].trim().toLowerCase();
    if (aliases.containsKey(normalized)) {
      // Avoid duplicate mappings for the same column
      if (!mapping.values.contains(aliases[normalized]!)) {
        mapping[i] = aliases[normalized]!;
      }
    }
  }

  return CsvColumnMapping(indexToColumn: mapping, headers: headers);
}

/// Parses a CSV string into structured import rows.
///
/// [csvContent] is the raw CSV text.
/// [mapping] is the column mapping to use. If null, auto-mapping is attempted.
/// [validateCalculation] when true, adds warnings for rows missing
/// external intensity, internal intensity, or HRV data.
CsvImportResult parseCsvImport(
  String csvContent, {
  CsvColumnMapping? mapping,
  bool validateCalculation = true,
}) {
  final globalErrors = <String>[];
  final globalWarnings = <String>[];

  List<List<dynamic>> csvData;
  try {
    csvData = const CsvToListConverter().convert(csvContent, eol: '\n');
  } catch (e) {
    try {
      csvData = const CsvToListConverter().convert(csvContent);
    } catch (e2) {
      globalErrors.add('Failed to parse CSV: $e2');
      return CsvImportResult(
        rows: [],
        mapping:
            mapping ?? const CsvColumnMapping(indexToColumn: {}, headers: []),
        globalErrors: globalErrors,
      );
    }
  }

  if (csvData.isEmpty) {
    globalErrors.add('CSV file is empty.');
    return CsvImportResult(
      rows: [],
      mapping:
          mapping ?? const CsvColumnMapping(indexToColumn: {}, headers: []),
      globalErrors: globalErrors,
    );
  }

  // First row is headers
  final headers = csvData.first.map((h) => h.toString()).toList();
  final effectiveMapping = mapping ?? autoMapColumns(headers);

  if (!effectiveMapping.hasRequiredColumns) {
    globalErrors.add(
      'Missing required columns: ${effectiveMapping.missingRequired.join(", ")}.',
    );
  }

  if (effectiveMapping.unmappedHeaders.isNotEmpty) {
    globalWarnings.add(
      'Unmapped columns: ${effectiveMapping.unmappedHeaders.join(", ")}.',
    );
  }

  final rows = <CsvParsedRow>[];

  for (int rowIdx = 1; rowIdx < csvData.length; rowIdx++) {
    final row = csvData[rowIdx];
    final values = <String, String>{};
    final rowErrors = <String>[];
    final rowWarnings = <String>[];

    for (final entry in effectiveMapping.indexToColumn.entries) {
      final colIdx = entry.key;
      final colName = entry.value;
      if (colIdx < row.length) {
        values[colName] = row[colIdx].toString().trim();
      }
    }

    // Validate required fields
    if ((values[CsvColumns.athleteName] ?? '').isEmpty) {
      rowErrors.add('Row $rowIdx: athlete_name is missing.');
    }
    if ((values[CsvColumns.date] ?? '').isEmpty) {
      rowErrors.add('Row $rowIdx: date is missing.');
    }
    if ((values[CsvColumns.rmssdRecovery] ?? '').isEmpty) {
      rowErrors.add('Row $rowIdx: rmssd_recovery is missing.');
    } else if (double.tryParse(values[CsvColumns.rmssdRecovery]!) == null) {
      rowErrors.add('Row $rowIdx: rmssd_recovery is not a valid number.');
    }

    final parsedRow = CsvParsedRow(
      rowIndex: rowIdx,
      values: values,
      errors: rowErrors,
      warnings: rowWarnings,
    );

    // Calculation readiness warnings
    if (validateCalculation && rowErrors.isEmpty) {
      if (!parsedRow.hasExternalLoad) {
        rowWarnings.add(
          'Row $rowIdx: No external load variable found. '
          'Internal intensity can be used for slope interpretation if available.',
        );
      }
      if (!parsedRow.hasInternalLoad) {
        rowWarnings.add(
          'Row $rowIdx: No internal intensity variable found. '
          'Cannot compute full analysis.',
        );
      }
      if (!parsedRow.hasHrvForSlope) {
        rowWarnings.add(
          'Row $rowIdx: Incomplete HRV data for slope calculation.',
        );
      }
    }

    rows.add(parsedRow);
  }

  return CsvImportResult(
    rows: rows,
    mapping: effectiveMapping,
    globalErrors: globalErrors,
    globalWarnings: globalWarnings,
  );
}
