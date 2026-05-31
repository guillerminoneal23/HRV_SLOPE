library;

enum ExportFormat { csv, xlsx }

enum ExportDatasetType {
  individualReport,
  groupReport,
  longitudinalAthlete,
  individualNomogram,
  populationNomogramPoints,
}

class ExportResult {
  final String filename;
  final String? path;
  final int rowCount;
  final int columnCount;
  final ExportFormat format;
  final ExportDatasetType exportType;
  final List<String> warnings;
  final DateTime createdAt;

  const ExportResult({
    required this.filename,
    this.path,
    required this.rowCount,
    required this.columnCount,
    required this.format,
    required this.exportType,
    this.warnings = const [],
    required this.createdAt,
  });
}

class CsvExportData {
  final String filename;
  final String content;
  final int rowCount;
  final int columnCount;
  final ExportDatasetType exportType;
  final List<String> warnings;

  const CsvExportData({
    required this.filename,
    required this.content,
    required this.rowCount,
    required this.columnCount,
    required this.exportType,
    this.warnings = const [],
  });
}
