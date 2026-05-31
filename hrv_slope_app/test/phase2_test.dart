// Phase 2 tests — intensity resolver, RR parser, CSV importer,
// calculation preview, and slope guard checks.
import 'package:flutter_test/flutter_test.dart';
import 'package:hrv_slope_app/core/constants/hrv_constants.dart';
import 'package:hrv_slope_app/shared/engine/calculation_preview.dart';
import 'package:hrv_slope_app/shared/engine/csv_importer.dart';
import 'package:hrv_slope_app/shared/engine/intensity_resolver.dart';
import 'package:hrv_slope_app/shared/engine/nomogram_engine.dart';
import 'package:hrv_slope_app/shared/engine/rr_parser.dart';
import 'package:hrv_slope_app/shared/engine/rr_quality.dart';
import 'package:hrv_slope_app/shared/engine/slope_calculator.dart';

void main() {
  // ── Intensity Resolver ──────────────────────────────────────────────────

  group('resolveIntensityPercent', () {
    test('direct percent_mas returns value and method', () {
      final r = resolveIntensityPercent(
        inputs: const IntensityInputs(percentMas: 85.0),
        athlete: const AthleteReferenceValues(),
      );
      expect(r.intensityPercent, 85.0);
      expect(r.method, 'direct_percent_mas');
      expect(r.canUseNomogram, isTrue);
    });

    test('direct percent_vvo2max returns value', () {
      final r = resolveIntensityPercent(
        inputs: const IntensityInputs(percentVvo2max: 92.0),
        athlete: const AthleteReferenceValues(),
      );
      expect(r.intensityPercent, 92.0);
      expect(r.method, 'direct_percent_vvo2max');
      expect(r.canUseNomogram, isTrue);
    });

    test('direct percent_map returns value', () {
      final r = resolveIntensityPercent(
        inputs: const IntensityInputs(percentMap: 78.0),
        athlete: const AthleteReferenceValues(),
      );
      expect(r.intensityPercent, 78.0);
      expect(r.method, 'direct_percent_map');
      expect(r.canUseNomogram, isTrue);
    });

    test('speed_kmh / MAS_kmh calculates percent', () {
      final r = resolveIntensityPercent(
        inputs: const IntensityInputs(speedKmh: 14.0),
        athlete: const AthleteReferenceValues(masKmh: 17.5),
      );
      expect(r.intensityPercent, closeTo(80.0, 0.01));
      expect(r.method, 'speed_kmh_div_mas');
      expect(r.canUseNomogram, isTrue);
    });

    test('speed_kmh / vVO2max_kmh calculates percent', () {
      final r = resolveIntensityPercent(
        inputs: const IntensityInputs(speedKmh: 16.0),
        athlete: const AthleteReferenceValues(vvo2maxKmh: 18.0),
      );
      expect(r.intensityPercent, closeTo(88.89, 0.01));
      expect(r.method, 'speed_kmh_div_vvo2max');
    });

    test('power_w / MAP_w calculates percent', () {
      final r = resolveIntensityPercent(
        inputs: const IntensityInputs(powerW: 250.0),
        athlete: const AthleteReferenceValues(mapW: 350.0),
      );
      expect(r.intensityPercent, closeTo(71.43, 0.01));
      expect(r.method, 'power_w_div_map');
    });

    test('percent_mas takes priority over speed/MAS', () {
      final r = resolveIntensityPercent(
        inputs: const IntensityInputs(percentMas: 90, speedKmh: 14),
        athlete: const AthleteReferenceValues(masKmh: 17.5),
      );
      expect(r.method, 'direct_percent_mas');
      expect(r.intensityPercent, 90.0);
    });

    test('missing reference returns unresolved', () {
      final r = resolveIntensityPercent(
        inputs: const IntensityInputs(speedKmh: 14.0),
        athlete: const AthleteReferenceValues(),
      );
      expect(r.intensityPercent, isNull);
      expect(r.method, 'unresolved');
      expect(r.canUseNomogram, isFalse);
      expect(r.warnings, isNotEmpty);
    });

    test('all empty returns unresolved with warning', () {
      final r = resolveIntensityPercent(
        inputs: const IntensityInputs(),
        athlete: const AthleteReferenceValues(),
      );
      expect(r.intensityPercent, isNull);
      expect(r.canUseNomogram, isFalse);
      expect(r.warnings.any((w) => w.contains('required')), isTrue);
    });
  });

  // ── RR Parser ───────────────────────────────────────────────────────────

  group('parseRrIntervals', () {
    test('comma-separated RR intervals', () {
      final r = parseRrIntervals('800,810,790,815');
      expect(r.rrIntervalsMs, [800, 810, 790, 815]);
      expect(r.invalidTokens, isEmpty);
      expect(r.totalTokens, 4);
    });

    test('newline-separated RR intervals', () {
      final r = parseRrIntervals('800\n810\n790');
      expect(r.rrIntervalsMs, [800, 810, 790]);
    });

    test('semicolon-separated RR intervals', () {
      final r = parseRrIntervals('800;810;790');
      expect(r.rrIntervalsMs, [800, 810, 790]);
    });

    test('tab-separated RR intervals', () {
      final r = parseRrIntervals('800\t810\t790');
      expect(r.rrIntervalsMs, [800, 810, 790]);
    });

    test('detects invalid tokens', () {
      final r = parseRrIntervals('800,abc,810,xyz');
      expect(r.rrIntervalsMs, [800, 810]);
      expect(r.invalidTokens, ['abc', 'xyz']);
      expect(r.hasErrors, isTrue);
    });

    test('empty input returns empty result', () {
      final r = parseRrIntervals('');
      expect(r.rrIntervalsMs, isEmpty);
      expect(r.totalTokens, 0);
      expect(r.hasData, isFalse);
    });

    test('whitespace-only input returns empty', () {
      final r = parseRrIntervals('   \n\t  ');
      expect(r.hasData, isFalse);
    });
  });

  // ── RR Quality integration ─────────────────────────────────────────────

  group('RR parser + quality', () {
    test('parsed valid RR passes quality assessment', () {
      final input = List.generate(300, (_) => '1000').join(',');
      final parsed = parseRrIntervals(input);
      expect(parsed.hasData, isTrue);
      final quality = assessRrQuality(parsed.rrIntervalsMs);
      expect(quality.qualityFlag, RrQualityFlag.valid);
    });

    test('parsed RR with few values fails quality', () {
      final parsed = parseRrIntervals('800,810,790');
      final quality = assessRrQuality(parsed.rrIntervalsMs);
      expect(quality.qualityFlag, RrQualityFlag.invalid);
    });
  });

  // ── CSV Importer ────────────────────────────────────────────────────────

  group('parseCsvImport', () {
    test('valid CSV parses correctly', () {
      const csv =
          'athlete_name,date,rmssd_recovery,speed_kmh,rpe_1_10,recovery_window_start_min,recovery_window_end_min\n'
          'John,2024-01-15,25.5,14.0,7,5,10\n';
      final r = parseCsvImport(csv);
      expect(r.totalRows, 1);
      expect(r.validRows, 1);
      expect(r.rows.first.athleteName, 'John');
      expect(r.rows.first.rmssdRecovery, 25.5);
      expect(r.rows.first.speedKmh, 14.0);
      expect(r.rows.first.hasExternalLoad, isTrue);
      expect(r.rows.first.hasInternalLoad, isTrue);
      expect(r.rows.first.hasHrvForSlope, isTrue);
    });

    test('missing athlete_name produces row error', () {
      const csv = 'athlete_name,date,rmssd_recovery\n,2024-01-15,25.5\n';
      final r = parseCsvImport(csv);
      expect(r.rows.first.hasErrors, isTrue);
      expect(
        r.rows.first.errors.any((e) => e.contains('athlete_name')),
        isTrue,
      );
    });

    test('missing rmssd_recovery produces row error', () {
      const csv = 'athlete_name,date,rmssd_recovery\nJohn,2024-01-15,\n';
      final r = parseCsvImport(csv);
      expect(r.rows.first.hasErrors, isTrue);
    });

    test('warns when no external load variable', () {
      const csv =
          'athlete_name,date,rmssd_recovery,rpe_1_10\nJohn,2024-01-15,25.5,7\n';
      final r = parseCsvImport(csv);
      expect(r.rows.first.warnings.any((w) => w.contains('external')), isTrue);
    });

    test('warns when no internal load variable', () {
      const csv =
          'athlete_name,date,rmssd_recovery,speed_kmh\nJohn,2024-01-15,25.5,14.0\n';
      final r = parseCsvImport(csv);
      expect(r.rows.first.warnings.any((w) => w.contains('internal')), isTrue);
    });

    test('warns when HRV incomplete', () {
      const csv =
          'athlete_name,date,rmssd_recovery,speed_kmh,rpe_1_10\nJohn,2024-01-15,25.5,14.0,7\n';
      final r = parseCsvImport(csv);
      expect(r.rows.first.warnings.any((w) => w.contains('HRV')), isTrue);
    });

    test('auto-maps Spanish column aliases', () {
      final mapping = autoMapColumns(['nombre', 'fecha', 'rmssd_recuperacion']);
      expect(mapping.indexToColumn[0], CsvColumns.athleteName);
      expect(mapping.indexToColumn[1], CsvColumns.date);
      expect(mapping.indexToColumn[2], CsvColumns.rmssdRecovery);
    });

    test('reports missing required columns', () {
      final mapping = autoMapColumns(['speed_kmh', 'rpe_1_10']);
      expect(mapping.hasRequiredColumns, isFalse);
      expect(mapping.missingRequired, contains('athlete_name'));
    });
  });

  // ── Calculation Preview ─────────────────────────────────────────────────

  group('buildCalculationPreview', () {
    test('window 5-10 uses t = 10', () {
      final p = buildCalculationPreview(
        athleteName: 'Test',
        sessionDate: '2024-01-15',
        externalVariables: [
          const TaggedVariable(
            category: 'external',
            name: 'speed_kmh',
            value: 14.0,
          ),
        ],
        internalVariables: [
          const TaggedVariable(
            category: 'internal',
            name: 'rpe_1_10',
            value: 7,
          ),
        ],
        intensityResolution: resolveIntensityPercent(
          inputs: const IntensityInputs(percentMas: 80),
          athlete: const AthleteReferenceValues(),
        ),
        rmssdExercise: 4.0,
        rmssdRecovery: 19.0,
        recoveryWindowStartMin: 5,
        recoveryWindowEndMin: 10,
      );
      expect(p.tUsedForSlope, 10.0);
      expect(p.recoveryWindowDurationMin, 5.0);
      expect(p.rawSlope, closeTo(1.5, 0.001));
    });

    test('fallback RMSSD exercise = 4 ms when not provided', () {
      final p = buildCalculationPreview(
        athleteName: 'Test',
        sessionDate: '2024-01-15',
        externalVariables: [],
        internalVariables: [],
        rmssdRecovery: 19.0,
        recoveryWindowStartMin: 5,
        recoveryWindowEndMin: 10,
      );
      expect(p.usedFallbackExercise, isTrue);
      expect(p.rmssdExercise, kDefaultRmssdExerciseMs);
      expect(p.rmssdExerciseSource, RmssdSource.fallback4Ms);
      expect(p.warnings.any((w) => w.contains('fallback')), isTrue);
    });

    test('raw_slope and interpreted_slope both present', () {
      final p = buildCalculationPreview(
        athleteName: 'Test',
        sessionDate: '2024-01-15',
        externalVariables: [],
        internalVariables: [],
        rmssdExercise: 4.0,
        rmssdRecovery: 4.5,
        recoveryWindowStartMin: 5,
        recoveryWindowEndMin: 10,
      );
      expect(p.rawSlope, closeTo(0.05, 0.001));
      expect(p.interpretedSlope, 0.1);
    });

    test('ITL = 1 / interpreted_slope', () {
      final p = buildCalculationPreview(
        athleteName: 'Test',
        sessionDate: '2024-01-15',
        externalVariables: [],
        internalVariables: [],
        rmssdExercise: 4.0,
        rmssdRecovery: 14.0,
        recoveryWindowStartMin: 5,
        recoveryWindowEndMin: 10,
      );
      // slope = (14-4)/10 = 1.0, ITL = 1/1.0 = 1.0
      expect(p.itlIndex, closeTo(1.0, 0.001));
    });

    test('no classification when intensity_percent is missing', () {
      final p = buildCalculationPreview(
        athleteName: 'Test',
        sessionDate: '2024-01-15',
        externalVariables: [],
        internalVariables: [],
        rmssdExercise: 4.0,
        rmssdRecovery: 19.0,
        recoveryWindowStartMin: 5,
        recoveryWindowEndMin: 10,
      );
      expect(p.canClassify, isFalse);
      expect(p.classification, isNull);
      expect(p.expectedLower, isNull);
    });

    test('classification generated with intensity_percent', () {
      final p = buildCalculationPreview(
        athleteName: 'Test',
        sessionDate: '2024-01-15',
        externalVariables: [],
        internalVariables: [],
        intensityResolution: resolveIntensityPercent(
          inputs: const IntensityInputs(percentMas: 80),
          athlete: const AthleteReferenceValues(),
        ),
        rmssdExercise: 4.0,
        rmssdRecovery: 19.0,
        recoveryWindowStartMin: 5,
        recoveryWindowEndMin: 10,
      );
      expect(p.canClassify, isTrue);
      expect(p.classification, isNotNull);
      expect(p.expectedLower, isNotNull);
      expect(p.expectedMean, isNotNull);
      expect(p.expectedUpper, isNotNull);
      expect(p.residual, isNotNull);
      expect(p.residualPercent, isNotNull);
    });

    test('classification uses specified nomogram preset', () {
      final p = buildCalculationPreview(
        athleteName: 'Test',
        sessionDate: '2024-01-15',
        externalVariables: [],
        internalVariables: [],
        intensityResolution: resolveIntensityPercent(
          inputs: const IntensityInputs(percentMas: 80),
          athlete: const AthleteReferenceValues(),
        ),
        rmssdExercise: 4.0,
        rmssdRecovery: 19.0,
        recoveryWindowStartMin: 5,
        recoveryWindowEndMin: 10,
        populationPreset: PopulationNomogramSource.paperOriginal2019,
      );
      expect(p.populationNomogramPreset, 'paper_original_2019');
    });

    test('window 10-15 uses t = 15', () {
      final p = buildCalculationPreview(
        athleteName: 'Test',
        sessionDate: '2024-01-15',
        externalVariables: [],
        internalVariables: [],
        rmssdExercise: 4.0,
        rmssdRecovery: 19.0,
        recoveryWindowStartMin: 10,
        recoveryWindowEndMin: 15,
      );
      expect(p.tUsedForSlope, 15.0);
      expect(p.rawSlope, closeTo(1.0, 0.001));
    });

    test('window 25-30 uses t = 30', () {
      final p = buildCalculationPreview(
        athleteName: 'Test',
        sessionDate: '2024-01-15',
        externalVariables: [],
        internalVariables: [],
        rmssdExercise: 4.0,
        rmssdRecovery: 19.0,
        recoveryWindowStartMin: 25,
        recoveryWindowEndMin: 30,
      );
      expect(p.tUsedForSlope, 30.0);
      expect(p.rawSlope, closeTo(0.5, 0.001));
    });
  });

  // ── Guard: legacy computeSlope not used in preview ────────────────────

  group('slope API guard', () {
    test('computeSlopeForRecoveryWindow delegates correctly', () {
      final result = computeSlopeForRecoveryWindow(
        rmssdRecovery: 19.0,
        rmssdExercise: 4.0,
        recoveryWindow: const RecoveryWindow(startMin: 5, endMin: 10),
      );
      expect(result.recoveryTimeForSlopeMin, 10.0);
      expect(result.recoveryWindowStartMin, 5.0);
      expect(result.recoveryWindowEndMin, 10.0);
      expect(result.recoveryWindowDurationMin, 5.0);
    });
  });
}
