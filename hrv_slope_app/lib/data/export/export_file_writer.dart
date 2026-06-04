library;

import 'dart:io';

import 'package:hrv_slope_app/data/export/export_models.dart';
import 'package:path/path.dart' as p;

class ExportFileWriter {
  final Directory exportsDirectory;

  ExportFileWriter({Directory? exportsDirectory})
    : exportsDirectory =
          exportsDirectory ??
          Directory(p.join(p.dirname(Platform.resolvedExecutable), 'exports'));

  Future<ExportResult> writeCsv(CsvExportData data) async {
    if (!exportsDirectory.existsSync()) {
      await exportsDirectory.create(recursive: true);
    }
    final safeFilename = _safeFilename(data.filename);
    final file = File(
      '${exportsDirectory.path}${Platform.pathSeparator}$safeFilename',
    );
    await file.writeAsString(data.content, flush: true);
    return ExportResult(
      filename: safeFilename,
      path: file.path,
      rowCount: data.rowCount,
      columnCount: data.columnCount,
      format: ExportFormat.csv,
      exportType: data.exportType,
      warnings: data.warnings,
      createdAt: DateTime.now(),
    );
  }
}

String _safeFilename(String filename) {
  final sanitized = filename
      .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
      .replaceAll(RegExp(r'\s+'), '_');
  return sanitized.endsWith('.csv') ? sanitized : '$sanitized.csv';
}
