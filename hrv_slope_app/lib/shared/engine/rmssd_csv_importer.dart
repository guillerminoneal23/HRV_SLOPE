/// Generic RMSSD CSV Import Mapper — for Elite HRV, Kubios, etc.
///
/// Supports flexible column mapping for RMSSD-containing CSVs
/// from various HRV apps without hardcoding vendor schemas.
library;

/// Known column aliases for auto-detection.
const _dateAliases = ['date', 'timestamp', 'session_date', 'fecha', 'datetime'];
const _rmssdAliases = [
  'rmssd',
  'rmssd_recovery',
  'recovery_rmssd',
  'hrv',
  'rmssd_ms',
  'rmssd_value',
  'rmssd_recuperacion',
];
const _rmssdExAliases = [
  'rmssd_exercise',
  'rmssd_ejercicio',
  'rmssd_ex',
  'exercise_rmssd',
];
const _notesAliases = ['notes', 'source', 'app', 'tag', 'comments'];
const _nameAliases = ['name', 'athlete', 'athlete_name', 'nombre', 'subject'];

/// Column role in the RMSSD import.
enum RmssdImportColumn {
  date,
  rmssdRecovery,
  rmssdExercise,
  athleteName,
  notes,
  unmapped,
}

/// Result of auto-mapping RMSSD CSV columns.
class RmssdColumnMapping {
  final Map<int, RmssdImportColumn> indexToColumn;
  final List<String> headers;
  final List<String> unmappedHeaders;

  const RmssdColumnMapping({
    required this.indexToColumn,
    required this.headers,
    required this.unmappedHeaders,
  });

  bool get hasRmssdRecovery =>
      indexToColumn.values.contains(RmssdImportColumn.rmssdRecovery);
}

/// Auto-map RMSSD CSV column headers.
RmssdColumnMapping autoMapRmssdColumns(List<String> headers) {
  final map = <int, RmssdImportColumn>{};
  final unmapped = <String>[];

  for (var i = 0; i < headers.length; i++) {
    final h = headers[i].trim().toLowerCase();
    if (_dateAliases.contains(h)) {
      map[i] = RmssdImportColumn.date;
    } else if (_rmssdExAliases.contains(h)) {
      map[i] = RmssdImportColumn.rmssdExercise;
    } else if (_rmssdAliases.contains(h)) {
      map[i] = RmssdImportColumn.rmssdRecovery;
    } else if (_nameAliases.contains(h)) {
      map[i] = RmssdImportColumn.athleteName;
    } else if (_notesAliases.contains(h)) {
      map[i] = RmssdImportColumn.notes;
    } else {
      map[i] = RmssdImportColumn.unmapped;
      unmapped.add(headers[i]);
    }
  }

  return RmssdColumnMapping(
    indexToColumn: map,
    headers: headers,
    unmappedHeaders: unmapped,
  );
}

/// A parsed row from an RMSSD CSV.
class RmssdImportRow {
  final int rowIndex;
  final String? date;
  final double? rmssdRecovery;
  final double? rmssdExercise;
  final String? athleteName;
  final String? notes;
  final List<String> errors;
  final List<String> warnings;

  const RmssdImportRow({
    required this.rowIndex,
    this.date,
    this.rmssdRecovery,
    this.rmssdExercise,
    this.athleteName,
    this.notes,
    this.errors = const [],
    this.warnings = const [],
  });

  bool get isValid => errors.isEmpty && rmssdRecovery != null;
}

/// Result of parsing an RMSSD CSV file.
class RmssdImportResult {
  final RmssdColumnMapping mapping;
  final List<RmssdImportRow> rows;
  final List<String> globalErrors;

  const RmssdImportResult({
    required this.mapping,
    required this.rows,
    this.globalErrors = const [],
  });

  int get totalRows => rows.length;
  int get validRows => rows.where((r) => r.isValid).length;
  int get errorRows => rows.where((r) => !r.isValid).length;
}

/// Parse an RMSSD CSV file.
RmssdImportResult parseRmssdCsv(String content) {
  final lines = content
      .split(RegExp(r'\r?\n'))
      .where((l) => l.trim().isNotEmpty)
      .toList();
  if (lines.isEmpty) {
    return const RmssdImportResult(
      mapping: RmssdColumnMapping(
        indexToColumn: {},
        headers: [],
        unmappedHeaders: [],
      ),
      rows: [],
      globalErrors: ['Empty file'],
    );
  }

  final headers = lines[0].split(',').map((h) => h.trim()).toList();
  final mapping = autoMapRmssdColumns(headers);
  final globalErrors = <String>[];

  if (!mapping.hasRmssdRecovery) {
    globalErrors.add(
      'No RMSSD column detected. Map manually or rename column to "rmssd".',
    );
  }

  final rows = <RmssdImportRow>[];
  for (var i = 1; i < lines.length; i++) {
    final cells = lines[i].split(',');
    final errs = <String>[];
    final warns = <String>[];

    String? date, name, notes;
    double? rmssdRec, rmssdEx;

    for (var j = 0; j < cells.length && j < headers.length; j++) {
      final val = cells[j].trim();
      final role = mapping.indexToColumn[j];
      switch (role) {
        case RmssdImportColumn.date:
          date = val.isNotEmpty ? val : null;
        case RmssdImportColumn.rmssdRecovery:
          rmssdRec = double.tryParse(val);
          if (val.isNotEmpty && rmssdRec == null) {
            errs.add('Invalid RMSSD value: $val');
          }
        case RmssdImportColumn.rmssdExercise:
          rmssdEx = double.tryParse(val);
        case RmssdImportColumn.athleteName:
          name = val.isNotEmpty ? val : null;
        case RmssdImportColumn.notes:
          notes = val.isNotEmpty ? val : null;
        default:
          break;
      }
    }

    if (rmssdRec == null) errs.add('Missing RMSSD recovery');
    if (rmssdRec != null && rmssdRec <= 0) errs.add('RMSSD must be > 0');
    if (rmssdEx == null) warns.add('No RMSSD exercise; will use 4 ms fallback');

    rows.add(
      RmssdImportRow(
        rowIndex: i,
        date: date,
        rmssdRecovery: rmssdRec,
        rmssdExercise: rmssdEx,
        athleteName: name,
        notes: notes,
        errors: errs,
        warnings: warns,
      ),
    );
  }

  return RmssdImportResult(
    mapping: mapping,
    rows: rows,
    globalErrors: globalErrors,
  );
}
