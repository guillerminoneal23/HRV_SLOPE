// Phase 5.1 tests — release readiness and local export safety.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hrv_slope_app/data/export/export_file_writer.dart';
import 'package:hrv_slope_app/data/export/export_models.dart';

void main() {
  group('Release readiness guards', () {
    test(
      'export writer creates exports directory and sanitizes filenames',
      () async {
        final tempRoot = await Directory.systemTemp.createTemp(
          'hrv_slope_exports_',
        );
        addTearDown(() async {
          if (tempRoot.existsSync()) {
            await tempRoot.delete(recursive: true);
          }
        });
        final exportsDirectory = Directory('${tempRoot.path}/exports');
        final writer = ExportFileWriter(exportsDirectory: exportsDirectory);

        final result = await writer.writeCsv(
          const CsvExportData(
            filename: 'VALORACION: atleta / sesion?.csv',
            content: 'athlete,slope\nVALORACION,0.42\n',
            rowCount: 1,
            columnCount: 2,
            exportType: ExportDatasetType.individualReport,
          ),
        );

        expect(exportsDirectory.existsSync(), isTrue);
        expect(File(result.path!).existsSync(), isTrue);
        expect(result.filename, endsWith('.csv'));
        expect(result.filename, isNot(contains(':')));
        expect(result.filename, isNot(contains('/')));
        expect(result.filename, isNot(contains('?')));
        expect(result.rowCount, 1);
        expect(result.columnCount, 2);
      },
    );

    test('root gitignore keeps local exports out of source control', () {
      final gitignore = File('../.gitignore').readAsStringSync();

      expect(gitignore, contains('exports/'));
      expect(gitignore, contains('*.sqlite'));
      expect(gitignore, contains('*.db'));
    });

    test('pubspec has no network, cloud, auth, or telemetry dependencies', () {
      final pubspec = File('pubspec.yaml').readAsStringSync().toLowerCase();
      final forbiddenDependencyPatterns = [
        RegExp(r'^\s*http\s*:', multiLine: true),
        RegExp(r'^\s*dio\s*:', multiLine: true),
        RegExp(r'^\s*firebase', multiLine: true),
        RegExp(r'^\s*firebase_analytics\s*:', multiLine: true),
        RegExp(r'^\s*firebase_crashlytics\s*:', multiLine: true),
        RegExp(r'^\s*sentry\s*:', multiLine: true),
        RegExp(r'^\s*telemetry\s*:', multiLine: true),
        RegExp(r'^\s*auth0\s*:', multiLine: true),
        RegExp(r'^\s*oauth', multiLine: true),
      ];

      for (final pattern in forbiddenDependencyPatterns) {
        expect(pubspec, isNot(matches(pattern)));
      }
    });
  });
}
