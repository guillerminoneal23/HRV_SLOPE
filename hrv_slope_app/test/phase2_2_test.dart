// Phase 2.2 tests - RR/NN preprocessing for auditable RR-derived RMSSD.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrv_slope_app/core/constants/hrv_sources.dart';
import 'package:hrv_slope_app/shared/engine/calculation_preview.dart';
import 'package:hrv_slope_app/shared/engine/rmssd_calculator.dart';
import 'package:hrv_slope_app/shared/engine/rr_parser.dart';
import 'package:hrv_slope_app/shared/engine/rr_preprocessing.dart';
import 'package:hrv_slope_app/ui/widgets/rr_input_widget.dart';

void main() {
  group('Raw RMSSD', () {
    test('computeRawRmssdFromRr matches existing computeRmssd formula', () {
      final rr = [800.0, 810.0, 790.0, 815.0, 800.0];
      expect(computeRawRmssdFromRr(rr), computeRmssd(rr));
    });

    test('raw mode preserves raw RMSSD', () {
      final rr = List<double>.filled(301, 1000)..[100] = 267;
      final result = preprocessRrIntervals(
        rr,
        const RrPreprocessingOptions(mode: RrPreprocessingMode.rangeOnly),
      );
      expect(result.correctionApplied, isFalse);
      expect(result.correctedRmssd, isNull);
      expect(result.rmssdUsed, equals(result.rawRmssd));
      expect(result.artifactCount, equals(1));
    });
  });

  group('Range detection', () {
    test('RR 267 ms detected as tooShort', () {
      final events = detectRangeOutliers([1000, 267, 1000], 300, 2200);
      expect(events.single.artifactType, RrArtifactType.tooShort);
      expect(events.single.index, 1);
    });

    test('RR 2300 ms detected as tooLong', () {
      final events = detectRangeOutliers([1000, 2300, 1000], 300, 2200);
      expect(events.single.artifactType, RrArtifactType.tooLong);
      expect(events.single.index, 1);
    });

    test('no correction when correctionEnabled false', () {
      final rr = List<double>.filled(301, 1000)..[30] = 267;
      final result = preprocessRrIntervals(
        rr,
        const RrPreprocessingOptions(mode: RrPreprocessingMode.rangeOnly),
      );
      expect(result.cleanedNnIntervals[30], equals(267));
      expect(result.correctionApplied, isFalse);
    });
  });

  group('Interpolation', () {
    test('middle invalid value interpolates linearly', () {
      final result = interpolateMarkedIntervalsLinear(
        [1000.0, 900.0, 1000.0],
        {1},
      );
      expect(result.intervals, [1000.0, 1000.0, 1000.0]);
      expect(result.replacementsByIndex[1], equals(1000.0));
    });

    test('leading invalid values fill with first valid', () {
      final result = interpolateMarkedIntervalsLinear(
        [200.0, 250.0, 1000.0, 1010.0],
        {0, 1},
      );
      expect(result.intervals.take(2), [1000.0, 1000.0]);
    });

    test('trailing invalid values fill with last valid', () {
      final result = interpolateMarkedIntervalsLinear(
        [1000.0, 1010.0, 2500.0, 2600.0],
        {2, 3},
      );
      expect(result.intervals.skip(2), [1010.0, 1010.0]);
    });

    test('length is preserved', () {
      final rr = [1000.0, 200.0, 1020.0, 2500.0, 1000.0];
      final result = interpolateMarkedIntervalsLinear(rr, {1, 3});
      expect(result.intervals.length, equals(rr.length));
    });
  });

  group('Malik ectopic detection', () {
    test('sudden >20% change detected', () {
      final events = detectMalikEctopics([1000, 1250, 1000]);
      expect(
        events.any((e) => e.artifactType == RrArtifactType.malikEctopic),
        isTrue,
      );
    });

    test('normal small changes not detected', () {
      final events = detectMalikEctopics([1000, 1050, 1030, 1010]);
      expect(events, isEmpty);
    });
  });

  group('Karlsson ectopic detection', () {
    test('middle RR deviating >20% from mean(prev,next) detected', () {
      final events = detectKarlssonEctopics([1000, 1500, 1000]);
      expect(events.single.artifactType, RrArtifactType.karlssonEctopic);
      expect(events.single.index, 1);
    });

    test('normal middle RR not detected', () {
      final events = detectKarlssonEctopics([1000, 1030, 1010]);
      expect(events, isEmpty);
    });
  });

  group('Local median threshold', () {
    test('outlier detected using medium 250 ms threshold', () {
      final events = detectLocalMedianOutliers([
        1000,
        1010,
        1400,
        1005,
        1000,
      ], thresholdMs: 250);
      expect(events.single.artifactType, RrArtifactType.localMedianOutlier);
    });

    test('threshold selector changes detection sensitivity', () {
      final rr = [1000.0, 1010.0, 1200.0, 1005.0, 1000.0];
      final medium = detectLocalMedianOutliers(rr, thresholdMs: 250);
      final strong = detectLocalMedianOutliers(rr, thresholdMs: 150);
      expect(medium, isEmpty);
      expect(strong, isNotEmpty);
    });
  });

  group('Preprocessing flow', () {
    test('correction off -> rmssdUsed = rawRmssd', () {
      final rr = List<double>.filled(301, 1000)..[100] = 267;
      final result = preprocessRrIntervals(
        rr,
        const RrPreprocessingOptions(mode: RrPreprocessingMode.rangeOnly),
      );
      expect(result.rmssdUsed, equals(result.rawRmssd));
      expect(result.correctionApplied, isFalse);
    });

    test('correction on -> rmssdUsed = correctedRmssd', () {
      final rr = List<double>.filled(301, 1000)..[100] = 267;
      final result = preprocessRrIntervals(
        rr,
        const RrPreprocessingOptions(
          mode: RrPreprocessingMode.rangeOnly,
          correctionEnabled: true,
        ),
      );
      expect(result.correctedRmssd, isNotNull);
      expect(result.rmssdUsed, equals(result.correctedRmssd));
      expect(result.correctionApplied, isTrue);
    });

    test('artifactPercent computed correctly', () {
      final rr = List<double>.filled(300, 1000);
      rr[0] = 267;
      rr[1] = 2300;
      final result = preprocessRrIntervals(
        rr,
        const RrPreprocessingOptions(mode: RrPreprocessingMode.rangeOnly),
      );
      expect(result.artifactCount, equals(2));
      expect(result.artifactPercent, closeTo(2 / 300 * 100, 0.001));
    });

    test('artifactPercent > 5 -> warning', () {
      final rr = List<double>.filled(320, 1000);
      for (var i = 0; i < 20; i++) {
        rr[i] = 299;
      }
      final result = preprocessRrIntervals(
        rr,
        const RrPreprocessingOptions(mode: RrPreprocessingMode.rangeOnly),
      );
      expect(result.artifactPercent, greaterThan(5));
      expect(result.qualityDecision, RrQualityDecision.warning);
    });

    test('artifactPercent > 10 -> invalid', () {
      final rr = List<double>.filled(340, 1000);
      for (var i = 0; i < 40; i++) {
        rr[i] = 299;
      }
      final result = preprocessRrIntervals(
        rr,
        const RrPreprocessingOptions(mode: RrPreprocessingMode.rangeOnly),
      );
      expect(result.artifactPercent, greaterThan(10));
      expect(result.qualityDecision, RrQualityDecision.invalid);
    });

    test('RMSSD delta percent > 10 -> warning', () {
      final rr = List<double>.filled(301, 1000)..[100] = 1500;
      final result = preprocessRrIntervals(
        rr,
        const RrPreprocessingOptions(correctionEnabled: true),
      );
      expect(result.rmssdDeltaPercent!.abs(), greaterThan(10));
      expect(result.qualityDecision, RrQualityDecision.warning);
    });

    test(
      'single low RR artifact in long file is not invalid solely by count',
      () {
        final rr = List<double>.filled(263, 1150)..[100] = 267;
        final result = preprocessRrIntervals(
          rr,
          const RrPreprocessingOptions(mode: RrPreprocessingMode.rangeOnly),
        );
        expect(result.artifactCount, equals(1));
        expect(result.artifactPercent, closeTo(0.38, 0.02));
        expect(result.qualityDecision, isNot(RrQualityDecision.invalid));
      },
    );
  });

  group('Mandatory real RR fixtures', () {
    test('all three required files exist', () {
      expect(_fixtureDir.existsSync(), isTrue);
      for (final fixture in _fixtureExpectations) {
        expect(
          _fixtureFile(fixture.filename).existsSync(),
          isTrue,
          reason: 'Missing fixture ${fixture.filename}',
        );
      }
    });

    test('2026-05-25 count/duration/RMSSD/min/max/artifacts', () {
      final fixture = _loadFixture(_fixtureExpectations[0]);
      _expectFixtureMatches(fixture);
      expect(fixture.result.qualityDecision, isNot(RrQualityDecision.invalid));
    });

    test('2026-05-22 count/duration/RMSSD/min/max/artifacts', () {
      final fixture = _loadFixture(_fixtureExpectations[1]);
      _expectFixtureMatches(fixture);
      expect(fixture.result.qualityDecision, isNot(RrQualityDecision.invalid));
    });

    test('2026-05-21 count/duration/RMSSD/min/max/artifacts', () {
      final fixture = _loadFixture(_fixtureExpectations[2]);
      _expectFixtureMatches(fixture);
      expect(fixture.result.qualityDecision, isNot(RrQualityDecision.invalid));
    });

    test('2026-05-21 artifact event contains value 267 ms', () {
      final fixture = _loadFixture(_fixtureExpectations[2]);
      expect(
        fixture.result.artifactEvents.any(
          (event) =>
              event.artifactType == RrArtifactType.tooShort &&
              event.originalValueMs == 267,
        ),
        isTrue,
      );
      expect(
        fixture.result.qualityNotes.any((note) => note.contains('1 artifacts')),
        isTrue,
      );
    });

    test('fixture parser supports Windows and Unix line endings', () {
      final fixture = _loadFixture(_fixtureExpectations[0]);
      final unixText = fixture.parsed.rrIntervalsMs.join('\n');
      final windowsText = fixture.parsed.rrIntervalsMs.join('\r\n');

      expect(
        parseRrIntervals(unixText).rrIntervalsMs,
        fixture.parsed.rrIntervalsMs,
      );
      expect(
        parseRrIntervals(windowsText).rrIntervalsMs,
        fixture.parsed.rrIntervalsMs,
      );
    });

    test('parser ignores trailing blank lines', () {
      final fixture = _loadFixture(_fixtureExpectations[1]);
      final withTrailingBlanks =
          '${fixture.parsed.rrIntervalsMs.join('\n')}\n\n\n';

      expect(
        parseRrIntervals(withTrailingBlanks).rrIntervalsMs,
        fixture.parsed.rrIntervalsMs,
      );
    });

    test('quality decision is not invalid for the two clean fixtures', () {
      for (final expectation in _fixtureExpectations.take(2)) {
        final fixture = _loadFixture(expectation);
        expect(fixture.result.artifactCount, equals(0));
        expect(
          fixture.result.qualityDecision,
          isNot(RrQualityDecision.invalid),
        );
      }
    });

    test(
      'quality decision is not invalid solely due to 1 artifact in fixture 3',
      () {
        final fixture = _loadFixture(_fixtureExpectations[2]);
        expect(fixture.result.artifactCount, equals(1));
        expect(fixture.result.artifactPercent, closeTo(0.38, 0.01));
        expect(
          fixture.result.qualityDecision,
          isNot(RrQualityDecision.invalid),
        );
      },
    );
  });

  group('Calculation preview RR metadata', () {
    test('preview exposes raw RR mode metadata when correction is off', () {
      final rr = List<double>.filled(301, 1000);
      final preprocessing = preprocessRrIntervals(
        rr,
        const RrPreprocessingOptions(),
      );
      final preview = buildCalculationPreview(
        athleteName: 'Test',
        sessionDate: '2026-05-26',
        externalVariables: const [],
        internalVariables: const [],
        hrvInputMode: HrvInputMode.rrIntervals,
        rmssdRecovery: preprocessing.rmssdUsed,
        rmssdRecoverySource: RmssdSource.computedFromRr,
        recoveryRrPreprocessing: preprocessing,
        recoveryWindowStartMin: 5,
        recoveryWindowEndMin: 10,
      );

      expect(preview.hrvInputMode, HrvInputMode.rrIntervals);
      expect(preview.rrPreprocessingMode, RrPreprocessingMode.rangeAndEctopic);
      expect(preview.correctionEnabled, isFalse);
      expect(preview.rawRmssd, equals(preprocessing.rawRmssd));
      expect(preview.correctedRmssd, isNull);
      expect(preview.rmssdUsedForSlope, equals(preprocessing.rmssdUsed));
      expect(preview.hrvSource, 'computed_from_rr_raw');
    });

    test('preview exposes corrected RR metadata when correction is on', () {
      final rr = List<double>.filled(301, 1000)..[100] = 1500;
      final preprocessing = preprocessRrIntervals(
        rr,
        const RrPreprocessingOptions(correctionEnabled: true),
      );
      final preview = buildCalculationPreview(
        athleteName: 'Test',
        sessionDate: '2026-05-26',
        externalVariables: const [],
        internalVariables: const [],
        hrvInputMode: HrvInputMode.rrIntervals,
        rmssdRecovery: preprocessing.rmssdUsed,
        rmssdRecoverySource: RmssdSource.computedFromRr,
        recoveryRrPreprocessing: preprocessing,
        recoveryWindowStartMin: 5,
        recoveryWindowEndMin: 10,
      );

      expect(preview.correctionEnabled, isTrue);
      expect(preview.correctedRmssd, isNotNull);
      expect(preview.rmssdUsedForSlope, equals(preprocessing.correctedRmssd));
      expect(preview.artifactCount, greaterThan(0));
      expect(preview.hrvSource, 'computed_from_rr_corrected');
    });
  });

  group('RR preprocessing widget', () {
    testWidgets('RR preprocessing controls visible', (tester) async {
      await tester.pumpWidget(
        _wrap(RrInputWidget(label: 'RR', onResult: (_) {})),
      );

      expect(find.text('RR preprocessing'), findsOneWidget);
      expect(find.text('Correction'), findsOneWidget);
      expect(find.text('Method'), findsOneWidget);
      expect(find.text('Local median threshold'), findsOneWidget);
    });

    testWidgets('correction toggle changes RMSSD used', (tester) async {
      RrInputResult? latest;
      await tester.pumpWidget(
        _wrap(RrInputWidget(label: 'RR', onResult: (r) => latest = r)),
      );

      await tester.enterText(
        find.byType(TextField).first,
        _rrTextWithArtifact(),
      );
      await tester.tap(find.text('Parse & Compute RMSSD'));
      await tester.pumpAndSettle();
      final rawUsed = latest!.rmssd;

      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      expect(latest!.preprocessing.correctionApplied, isTrue);
      expect(latest!.rmssd, isNot(equals(rawUsed)));
    });

    testWidgets('artifact table displays detected artifact', (tester) async {
      await tester.pumpWidget(
        _wrap(RrInputWidget(label: 'RR', onResult: (_) {})),
      );

      await tester.enterText(
        find.byType(TextField).first,
        _rrTextWithArtifact(),
      );
      await tester.tap(find.text('Parse & Compute RMSSD'));
      await tester.pumpAndSettle();

      expect(find.text('Artifact table'), findsOneWidget);
      expect(find.text('tooShort'), findsOneWidget);
      expect(find.text('267'), findsWidgets);
    });
  });

  group('Legacy guard', () {
    test('no UI/import usage of legacy computeSlope()', () {
      final files = [
        File('lib/ui/screens/session/session_wizard_screen.dart'),
        File('lib/shared/engine/calculation_preview.dart'),
        File('lib/ui/widgets/rr_input_widget.dart'),
      ];
      for (final file in files) {
        expect(file.readAsStringSync().contains('computeSlope('), isFalse);
      }
    });
  });
}

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

String _rrTextWithArtifact() {
  final rr = List<double>.filled(301, 1000)..[100] = 267;
  return rr.map((v) => v.toStringAsFixed(0)).join('\n');
}

const _fixtureDirPath = 'test/fixtures/rr_samples';
final _fixtureDir = Directory(_fixtureDirPath);

final _fixtureExpectations = <_FixtureExpectation>[
  const _FixtureExpectation(
    filename: '2026-05-25_05-27-02.txt',
    rrCount: 226,
    durationSec: 301.920,
    rawRmssd: 201.249,
    minRrMs: 350,
    maxRrMs: 1788,
    rangeArtifactCount: 0,
    artifactPercent: 0,
  ),
  const _FixtureExpectation(
    filename: '2026-05-22_05-39-13.txt',
    rrCount: 252,
    durationSec: 300.935,
    rawRmssd: 139.966,
    minRrMs: 838,
    maxRrMs: 1665,
    rangeArtifactCount: 0,
    artifactPercent: 0,
  ),
  const _FixtureExpectation(
    filename: '2026-05-21_05-42-46.txt',
    rrCount: 263,
    durationSec: 302.200,
    rawRmssd: 112.875,
    minRrMs: 267,
    maxRrMs: 1379,
    rangeArtifactCount: 1,
    artifactPercent: 0.38,
  ),
];

File _fixtureFile(String filename) => File('$_fixtureDirPath/$filename');

_LoadedFixture _loadFixture(_FixtureExpectation expectation) {
  final file = _fixtureFile(expectation.filename);
  expect(
    file.existsSync(),
    isTrue,
    reason: 'Missing fixture ${expectation.filename}',
  );

  final parsed = parseRrIntervals(file.readAsStringSync());
  final result = preprocessRrIntervals(
    parsed.rrIntervalsMs,
    const RrPreprocessingOptions(mode: RrPreprocessingMode.rangeOnly),
  );
  return _LoadedFixture(
    expectation: expectation,
    parsed: parsed,
    result: result,
  );
}

void _expectFixtureMatches(_LoadedFixture fixture) {
  final expectation = fixture.expectation;
  final rr = fixture.parsed.rrIntervalsMs;
  expect(rr.length, equals(expectation.rrCount));
  expect(fixture.result.durationRawSec, closeTo(expectation.durationSec, 0.01));
  expect(fixture.result.rawRmssd, closeTo(expectation.rawRmssd, 0.05));
  expect(rr.reduce((a, b) => a < b ? a : b), equals(expectation.minRrMs));
  expect(rr.reduce((a, b) => a > b ? a : b), equals(expectation.maxRrMs));
  expect(fixture.result.artifactCount, equals(expectation.rangeArtifactCount));
  expect(
    fixture.result.artifactPercent,
    closeTo(expectation.artifactPercent, 0.01),
  );
}

class _FixtureExpectation {
  final String filename;
  final int rrCount;
  final double durationSec;
  final double rawRmssd;
  final double minRrMs;
  final double maxRrMs;
  final int rangeArtifactCount;
  final double artifactPercent;

  const _FixtureExpectation({
    required this.filename,
    required this.rrCount,
    required this.durationSec,
    required this.rawRmssd,
    required this.minRrMs,
    required this.maxRrMs,
    required this.rangeArtifactCount,
    required this.artifactPercent,
  });
}

class _LoadedFixture {
  final _FixtureExpectation expectation;
  final RrParseResult parsed;
  final RrPreprocessingResult result;

  const _LoadedFixture({
    required this.expectation,
    required this.parsed,
    required this.result,
  });
}
