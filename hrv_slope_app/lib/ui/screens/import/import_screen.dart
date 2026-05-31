/// Import Screen — CSV import foundation.
library;

import 'dart:io';
import 'package:drift/drift.dart' as drift;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hrv_slope_app/core/constants/hrv_constants.dart';
import 'package:hrv_slope_app/data/database/app_database.dart';
import 'package:hrv_slope_app/shared/engine/csv_importer.dart';
import 'package:hrv_slope_app/shared/engine/intensity_resolver.dart';
import 'package:hrv_slope_app/shared/engine/nomogram_engine.dart';
import 'package:hrv_slope_app/shared/engine/slope_calculator.dart';
import 'package:hrv_slope_app/ui/theme/app_theme.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});
  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  late final AppDatabase _db;
  CsvImportResult? _result;
  String? _filename;
  bool _loading = false;
  bool _importing = false;
  bool _createMissingAthletes = true;

  @override
  void initState() {
    super.initState();
    _db = AppDatabase();
  }

  @override
  void dispose() {
    _db.close();
    super.dispose();
  }

  Future<void> _pickCsv() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'txt'],
    );
    if (picked == null || picked.files.isEmpty) return;
    final path = picked.files.first.path;
    if (path == null) return;

    setState(() {
      _loading = true;
      _filename = picked.files.first.name;
    });
    try {
      final content = await File(path).readAsString();
      final result = parseCsvImport(content);
      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _importRows() async {
    if (_result == null) return;
    setState(() => _importing = true);
    final now = DateTime.now().toIso8601String();
    int imported = 0;
    int errors = 0;

    try {
      // Create import batch
      final batchId = await _db.sessionsDao.createImportBatch(
        ImportBatchesCompanion.insert(
          importType: 'csv',
          filename: drift.Value(_filename),
          createdAt: now,
        ),
      );

      for (final row in _result!.rows.where((r) => r.isValid)) {
        try {
          // Resolve or create athlete
          final athleteName = row.athleteName!;
          var athlete = await _db.athletesDao.getAthleteByName(athleteName);
          if (athlete == null) {
            if (!_createMissingAthletes) {
              errors++;
              continue;
            }
            final id = await _db.athletesDao.insertAthlete(
              AthletesCompanion.insert(
                name: athleteName,
                sport: drift.Value(row.sport),
                createdAt: now,
                updatedAt: now,
              ),
            );
            athlete = await _db.athletesDao.getAthleteById(id);
          }
          if (athlete == null) {
            errors++;
            continue;
          }

          // Compute slope if HRV data exists
          double? slopeRaw, slopeInt, itl;
          double? recoveryTimeMin;
          double? intensityPct;
          String? intensitySrc;
          String? classification;
          bool usedFallback = false;
          final rmssdRec = row.rmssdRecovery;
          final rmssdEx = row.rmssdExercise;
          final winStart = row.recoveryWindowStartMin;
          final winEnd = row.recoveryWindowEndMin;

          if (rmssdRec != null && winStart != null && winEnd != null) {
            try {
              final window = RecoveryWindow(startMin: winStart, endMin: winEnd);
              window.validate();
              usedFallback = rmssdEx == null;
              final slopeResult = computeSlopeForRecoveryWindow(
                rmssdRecovery: rmssdRec,
                rmssdExercise: rmssdEx,
                recoveryWindow: window,
              );
              slopeRaw = slopeResult.rawSlope;
              slopeInt = slopeResult.interpretedSlope;
              itl = computeItlIndex(slopeResult.interpretedSlope);
              recoveryTimeMin = slopeResult.recoveryTimeForSlopeMin;

              // Intensity resolution
              final resolution = resolveIntensityPercent(
                inputs: IntensityInputs(
                  percentMas: row.percentMas,
                  percentVvo2max: row.percentVvo2max,
                  percentMap: row.percentMap,
                  speedKmh: row.speedKmh,
                  powerW: row.powerW,
                  rpe110: row.rpe110,
                ),
                athlete: AthleteReferenceValues(
                  masKmh: athlete.masKmh,
                  vvo2maxKmh: athlete.vvo2maxKmh,
                  mapW: athlete.mapW,
                ),
              );
              intensityPct = resolution.intensityPercent;
              intensitySrc = resolution.method;

              if (intensityPct != null && resolution.canUseNomogram) {
                final cls = classifySlopeWithPopulationNomogram(
                  intensityPct,
                  slopeResult.interpretedSlope,
                );
                classification = cls.classification.label;
              }
            } catch (_) {
              // Slope calc failed, save as draft
            }
          }

          await _db.sessionsDao.insertSession(
            SessionsCompanion.insert(
              athleteId: athlete.id,
              date: row.date ?? now,
              taskName: drift.Value(row.sessionName),
              sport: drift.Value(row.sport),
              sessionType: drift.Value(row.sessionType),
              isDraft: drift.Value(slopeRaw == null),
              intensityPercent: drift.Value(intensityPct),
              intensitySource: drift.Value(intensitySrc),
              recoveryTimeMin: drift.Value(recoveryTimeMin),
              recoveryWindowStartMin: drift.Value(winStart),
              recoveryWindowEndMin: drift.Value(winEnd),
              rmssdExercise: drift.Value(
                rmssdEx ?? (usedFallback ? kDefaultRmssdExerciseMs : null),
              ),
              rmssdExerciseIsDefault: drift.Value(usedFallback),
              rmssdRecovery: drift.Value(rmssdRec),
              slopeRaw: drift.Value(slopeRaw),
              slopeInterpreted: drift.Value(slopeInt),
              itlIndex: drift.Value(itl),
              classification: drift.Value(classification),
              importBatchId: drift.Value(batchId),
              notes: drift.Value(row.notes),
              createdAt: now,
            ),
          );
          imported++;
        } catch (e) {
          errors++;
        }
      }

      // Update batch counts
      await _db.sessionsDao.createImportBatch(
        ImportBatchesCompanion(
          id: drift.Value(batchId),
          importType: const drift.Value('csv'),
          filename: drift.Value(_filename),
          rowCount: drift.Value(imported),
          errorCount: drift.Value(errors),
          createdAt: drift.Value(now),
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported $imported rows, $errors errors')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Import error: $e')));
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import Data')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // CSV section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.table_chart, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'CSV Import',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Import session data from a CSV file.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _loading ? null : _pickCsv,
                    icon: const Icon(Icons.file_open),
                    label: const Text('Select CSV File'),
                  ),
                ],
              ),
            ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_result != null) ...[
            const SizedBox(height: 12),
            // Summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'File: $_filename',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text('Total rows: ${_result!.totalRows}'),
                    Text(
                      'Valid: ${_result!.validRows}',
                      style: TextStyle(color: AppColors.success),
                    ),
                    Text(
                      'Errors: ${_result!.errorRows}',
                      style: TextStyle(
                        color: _result!.errorRows > 0
                            ? AppColors.error
                            : AppColors.textSecondary,
                      ),
                    ),
                    Text('Athletes: ${_result!.athleteNames.join(", ")}'),
                    if (_result!.mapping.unmappedHeaders.isNotEmpty)
                      Text(
                        'Unmapped: ${_result!.mapping.unmappedHeaders.join(", ")}',
                        style: TextStyle(
                          color: AppColors.warning,
                          fontSize: 12,
                        ),
                      ),
                    if (_result!.globalErrors.isNotEmpty)
                      for (final e in _result!.globalErrors)
                        Text(
                          '⚠ $e',
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                          ),
                        ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Options
            SwitchListTile(
              title: const Text('Create missing athletes'),
              value: _createMissingAthletes,
              onChanged: (v) => setState(() => _createMissingAthletes = v),
            ),
            const SizedBox(height: 8),
            // Row preview (first 5)
            Text(
              'Preview (first ${_result!.rows.length > 5 ? 5 : _result!.rows.length} rows)',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ..._result!.rows
                .take(5)
                .map(
                  (r) => Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    child: ListTile(
                      leading: Icon(
                        r.isValid ? Icons.check_circle : Icons.error,
                        color: r.isValid ? AppColors.success : AppColors.error,
                        size: 20,
                      ),
                      title: Text(
                        '${r.athleteName ?? "?"} · ${r.date ?? "?"}',
                        style: const TextStyle(fontSize: 13),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (r.hasErrors)
                            ...r.errors.map(
                              (e) => Text(
                                e,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          if (r.warnings.isNotEmpty)
                            ...r.warnings.map(
                              (w) => Text(
                                w,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.warning,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _importing || _result!.validRows == 0
                  ? null
                  : _importRows,
              icon: _importing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload),
              label: Text(
                _importing
                    ? 'Importing...'
                    : 'Import ${_result!.validRows} Valid Rows',
              ),
            ),
          ],
          const SizedBox(height: 24),
          // XLSX note
          Card(
            color: AppColors.surfaceContainerHigh,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.textHint),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'XLSX import is deferred to Phase 2.1/3. Use CSV for now.',
                      style: TextStyle(fontSize: 12, color: AppColors.textHint),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
