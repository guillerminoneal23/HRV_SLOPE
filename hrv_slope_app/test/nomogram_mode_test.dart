/// Tests for nomogram_mode.dart — NomogramMode enum and IndividualReadiness.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:hrv_slope_app/shared/engine/nomogram_mode.dart';

void main() {
  group('NomogramMode', () {
    test('enum values have correct keys', () {
      expect(NomogramMode.population.key, 'population');
      expect(NomogramMode.hybrid.key, 'hybrid');
      expect(NomogramMode.individual.key, 'individual');
    });

    test('enum values have labels', () {
      expect(NomogramMode.population.label, contains('population'));
      expect(NomogramMode.hybrid.label, contains('Hybrid'));
      expect(NomogramMode.individual.label, contains('Individual'));
    });

    test('enum values have short labels', () {
      expect(NomogramMode.population.shortLabel, 'Population');
      expect(NomogramMode.hybrid.shortLabel, 'Hybrid');
      expect(NomogramMode.individual.shortLabel, 'Individual');
    });
  });

  group('parseNomogramMode', () {
    test('parses known keys', () {
      expect(parseNomogramMode('population'), NomogramMode.population);
      expect(parseNomogramMode('hybrid'), NomogramMode.hybrid);
      expect(parseNomogramMode('individual'), NomogramMode.individual);
    });

    test('returns population for null', () {
      expect(parseNomogramMode(null), NomogramMode.population);
    });

    test('returns population for unknown string', () {
      expect(parseNomogramMode('unknown'), NomogramMode.population);
      expect(parseNomogramMode(''), NomogramMode.population);
    });

    test('trims whitespace', () {
      expect(parseNomogramMode('  hybrid  '), NomogramMode.hybrid);
    });
  });

  group('evaluateIndividualReadiness', () {
    test('fully ready with all criteria met', () {
      // 15 sessions, 5 bins, 40pp coverage, good R² and CV
      final intensities = [
        50.0, 52.0, 55.0, // bin 5
        60.0, 62.0, 65.0, // bin 6
        70.0, 72.0, 75.0, // bin 7
        80.0, 82.0, 85.0, // bin 8
        90.0, 92.0, 95.0, // bin 9
      ];
      final result = evaluateIndividualReadiness(
        intensities: intensities,
        rSquared: 0.85,
        cvRmse: 0.20,
      );

      expect(result.isReady, true);
      expect(result.gaps, isEmpty);
      expect(result.validSessions, 15);
      expect(result.qualifiedBins, 5);
      expect(result.coveragePp, 45.0);
      expect(result.rSquared, 0.85);
      expect(result.cvRmse, 0.20);
    });

    test('not ready: insufficient sessions', () {
      final intensities = [50.0, 60.0, 70.0, 80.0, 90.0];
      final result = evaluateIndividualReadiness(
        intensities: intensities,
        rSquared: 0.90,
        cvRmse: 0.10,
      );

      expect(result.isReady, false);
      expect(result.validSessions, 5);
      expect(result.gaps.any((g) => g.criterion == 'Valid sessions'), true);
    });

    test('not ready: insufficient bins', () {
      // 12 sessions but only 2 bins
      final intensities = [
        60.0, 61.0, 62.0, 63.0, 64.0, 65.0,
        70.0, 71.0, 72.0, 73.0, 74.0, 75.0,
      ];
      final result = evaluateIndividualReadiness(
        intensities: intensities,
        rSquared: 0.80,
        cvRmse: 0.20,
      );

      expect(result.isReady, false);
      expect(result.qualifiedBins, 2);
      expect(
        result.gaps.any((g) => g.criterion.contains('bins')),
        true,
      );
    });

    test('not ready: insufficient coverage', () {
      // 12 sessions, 4 bins, but only 20pp coverage
      final intensities = [
        60.0, 61.0, 62.0, // bin 6
        63.0, 64.0, 65.0, // still bin 6
        70.0, 71.0, 72.0, // bin 7
        73.0, 74.0, 75.0, // still bin 7
      ];
      final result = evaluateIndividualReadiness(
        intensities: intensities,
        rSquared: 0.85,
        cvRmse: 0.15,
      );

      expect(result.isReady, false);
      expect(result.coveragePp, closeTo(15.0, 0.1));
      expect(
        result.gaps.any((g) => g.criterion.contains('coverage')),
        true,
      );
    });

    test('not ready: R² too low', () {
      final intensities = [
        50.0, 52.0, 55.0,
        60.0, 62.0, 65.0,
        70.0, 72.0, 75.0,
        80.0, 82.0, 85.0,
      ];
      final result = evaluateIndividualReadiness(
        intensities: intensities,
        rSquared: 0.40,
        cvRmse: 0.20,
      );

      expect(result.isReady, false);
      expect(
        result.gaps.any((g) => g.criterion.contains('R²')),
        true,
      );
    });

    test('not ready: CV-RMSE too high', () {
      final intensities = [
        50.0, 52.0, 55.0,
        60.0, 62.0, 65.0,
        70.0, 72.0, 75.0,
        80.0, 82.0, 85.0,
      ];
      final result = evaluateIndividualReadiness(
        intensities: intensities,
        rSquared: 0.85,
        cvRmse: 0.80,
      );

      expect(result.isReady, false);
      expect(
        result.gaps.any((g) => g.criterion.contains('Cross-validation')),
        true,
      );
    });

    test('R² not available with enough sessions generates gap', () {
      final intensities = List.generate(12, (i) => 50.0 + i * 4.0);
      final result = evaluateIndividualReadiness(
        intensities: intensities,
        rSquared: null,
        cvRmse: null,
      );

      expect(result.isReady, false);
      expect(
        result.gaps.any((g) => g.criterion == 'Model R²'),
        true,
      );
    });

    test('R² not available with few sessions does not generate R² gap', () {
      final intensities = [50.0, 60.0, 70.0];
      final result = evaluateIndividualReadiness(
        intensities: intensities,
        rSquared: null,
        cvRmse: null,
      );

      // Should have session gap but not R² gap (too few to even expect it)
      expect(
        result.gaps.any((g) => g.criterion == 'Valid sessions'),
        true,
      );
      expect(
        result.gaps.any((g) => g.criterion == 'Model R²'),
        false,
      );
    });

    test('empty intensities list', () {
      final result = evaluateIndividualReadiness(
        intensities: [],
        rSquared: null,
        cvRmse: null,
      );

      expect(result.isReady, false);
      expect(result.validSessions, 0);
      expect(result.qualifiedBins, 0);
      expect(result.coveragePp, 0.0);
      expect(result.canAttemptFit, false);
    });

    test('boundary: exactly 12 sessions with all criteria met', () {
      final intensities = [
        40.0, 42.0, 44.0, // bin 4
        50.0, 52.0, 54.0, // bin 5
        60.0, 62.0, 64.0, // bin 6
        80.0, 82.0, 84.0, // bin 8
      ];
      final result = evaluateIndividualReadiness(
        intensities: intensities,
        rSquared: 0.65,
        cvRmse: 0.45,
      );

      expect(result.isReady, true);
      expect(result.validSessions, 12);
      expect(result.qualifiedBins, 4);
      expect(result.coveragePp, closeTo(44.0, 0.1));
    });

    test('canAttemptFit true with 3+ sessions and 2+ qualified bins', () {
      // Need ≥3 sessions AND ≥2 bins with ≥3 measurements each
      final intensities = [
        50.0, 52.0, 54.0, // bin 5 (3 pts)
        60.0, 62.0, 64.0, // bin 6 (3 pts)
      ];
      final result = evaluateIndividualReadiness(
        intensities: intensities,
      );
      expect(result.canAttemptFit, true);
    });

    test('canAttemptFit false with too few sessions', () {
      final intensities = [50.0, 60.0];
      final result = evaluateIndividualReadiness(
        intensities: intensities,
      );
      expect(result.canAttemptFit, false);
    });
  });

  group('IndividualReadiness.hybridWeight', () {
    test('0 sessions → weight 0.0', () {
      final r = evaluateIndividualReadiness(intensities: []);
      expect(r.hybridWeight, 0.0);
      expect(r.populationWeight, 1.0);
    });

    test('5 sessions → weight 0.0', () {
      final r = evaluateIndividualReadiness(
        intensities: List.generate(5, (i) => 50.0 + i * 10.0),
      );
      expect(r.hybridWeight, 0.0);
    });

    test('6 sessions → weight 0.3', () {
      final r = evaluateIndividualReadiness(
        intensities: List.generate(6, (i) => 50.0 + i * 10.0),
      );
      expect(r.hybridWeight, 0.3);
    });

    test('8 sessions → weight 0.3', () {
      final r = evaluateIndividualReadiness(
        intensities: List.generate(8, (i) => 50.0 + i * 5.0),
      );
      expect(r.hybridWeight, 0.3);
    });

    test('9 sessions → weight 0.7', () {
      final r = evaluateIndividualReadiness(
        intensities: List.generate(9, (i) => 50.0 + i * 5.0),
      );
      expect(r.hybridWeight, 0.7);
    });

    test('11 sessions → weight 0.7', () {
      final r = evaluateIndividualReadiness(
        intensities: List.generate(11, (i) => 50.0 + i * 4.0),
      );
      expect(r.hybridWeight, 0.7);
    });

    test('12 sessions, not fully ready → weight 0.7', () {
      // 12 sessions but R² too low
      final r = evaluateIndividualReadiness(
        intensities: List.generate(12, (i) => 50.0 + i * 4.0),
        rSquared: 0.30,
        cvRmse: 0.10,
      );
      expect(r.isReady, false);
      expect(r.hybridWeight, 0.7);
    });

    test('12+ sessions, fully ready → weight 1.0', () {
      final intensities = [
        40.0, 42.0, 44.0, // bin 4
        50.0, 52.0, 54.0, // bin 5
        60.0, 62.0, 64.0, // bin 6
        80.0, 82.0, 84.0, // bin 8
      ];
      final r = evaluateIndividualReadiness(
        intensities: intensities,
        rSquared: 0.85,
        cvRmse: 0.20,
      );
      expect(r.isReady, true);
      expect(r.hybridWeight, 1.0);
    });
  });

  group('IndividualReadiness.hybridLabel', () {
    test('displays correct percentages', () {
      final r = evaluateIndividualReadiness(
        intensities: List.generate(7, (i) => 50.0 + i * 10.0),
      );
      expect(r.hybridWeight, 0.3);
      expect(r.hybridLabel, '30% athlete / 70% study');
    });

    test('pure population shows 0/100', () {
      final r = evaluateIndividualReadiness(intensities: []);
      expect(r.hybridLabel, '0% athlete / 100% study');
    });
  });

  group('ReadinessGap', () {
    test('toString is human readable', () {
      const gap = ReadinessGap(
        criterion: 'Valid sessions',
        currentValue: '8',
        requiredValue: '>= 12',
      );
      expect(gap.toString(), 'Valid sessions: 8 (required: >= 12)');
    });
  });

  group('Bin distribution edge cases', () {
    test('all sessions at same intensity → 1 bin', () {
      final intensities = List.generate(15, (_) => 75.0);
      final r = evaluateIndividualReadiness(
        intensities: intensities,
        rSquared: 0.90,
        cvRmse: 0.10,
      );
      expect(r.qualifiedBins, 1);
      expect(r.isReady, false);
    });

    test('bins on boundaries are assigned correctly', () {
      // 60.0 → bin 6, 70.0 → bin 7 (boundary)
      final intensities = [
        60.0, 61.0, 62.0,
        70.0, 71.0, 72.0,
        80.0, 81.0, 82.0,
        90.0, 91.0, 92.0,
      ];
      final r = evaluateIndividualReadiness(
        intensities: intensities,
        rSquared: 0.80,
        cvRmse: 0.30,
      );
      expect(r.qualifiedBins, 4);
    });

    test('bin with only 2 measurements does not qualify', () {
      final intensities = [
        50.0, 52.0, 55.0, // bin 5 ✓
        60.0, 62.0, 65.0, // bin 6 ✓
        70.0, 72.0, 75.0, // bin 7 ✓
        80.0, 82.0, 85.0, // bin 8 ✓
        90.0, 91.0,        // bin 9 ✗ (only 2)
      ];
      final r = evaluateIndividualReadiness(
        intensities: intensities,
        rSquared: 0.85,
        cvRmse: 0.20,
      );
      expect(r.qualifiedBins, 4); // bin 9 does not count
      expect(r.isReady, true); // 4 bins is enough
    });
  });
}
