// Phase 4.0B tests — Individual Nomogram Fitting UI + Hybrid Overlay.
import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrv_slope_app/data/database/app_database.dart';
import 'package:hrv_slope_app/data/database/daos/sessions_dao.dart';
import 'package:hrv_slope_app/shared/engine/individual_nomogram_builder.dart';
import 'package:hrv_slope_app/shared/engine/nomogram_engine.dart';
import 'package:hrv_slope_app/ui/screens/athletes/athlete_detail_screen.dart';
import 'package:hrv_slope_app/ui/screens/nomogram/individual_nomogram_screen.dart';
import 'package:hrv_slope_app/ui/widgets/nomogram_chart.dart';

void main() {
  group('Individual nomogram builder', () {
    test('excludes sessions missing intensity_percent', () {
      final data = _data([_detail(id: 1, intensity: null)]);

      expect(
        data.excludedSessions.single.reason,
        ExcludedNomogramReason.missingIntensity,
      );
    });

    test('excludes sessions missing interpreted_slope', () {
      final data = _data([_detail(id: 1, interpretedSlope: null)]);

      expect(
        data.excludedSessions.single.reason,
        ExcludedNomogramReason.missingSlope,
      );
    });

    test('excludes draft sessions', () {
      final data = _data([_detail(id: 1, isDraft: true)]);

      expect(
        data.excludedSessions.single.reason,
        ExcludedNomogramReason.draftSession,
      );
    });

    test('excludes invalid values', () {
      final data = _data([_detail(id: 1, intensity: -1)]);

      expect(
        data.excludedSessions.single.reason,
        ExcludedNomogramReason.invalidValue,
      );
    });

    test('counts low medium high intensity zones', () {
      final data = _data([
        _detail(id: 1, intensity: 60),
        _detail(id: 2, intensity: 80),
        _detail(id: 3, intensity: 95),
      ]);

      expect(data.summary.lowZoneCount, 1);
      expect(data.summary.mediumZoneCount, 1);
      expect(data.summary.highZoneCount, 1);
      expect(data.intensityZonesPresent, {'low', 'medium', 'high'});
    });

    test('confidence insufficient for fewer than 6 valid sessions', () {
      final data = _data([
        for (var i = 0; i < 5; i++) _detail(id: i + 1, intensity: 60 + i * 5),
      ]);

      expect(data.confidenceLevel, IndividualNomogramConfidence.insufficient);
      expect(
        data.summary.recommendedMode,
        IndividualNomogramRecommendedMode.populationOnly,
      );
    });

    test('confidence insufficient for 6 sessions in one zone', () {
      final data = _data([
        for (var i = 0; i < 6; i++) _detail(id: i + 1, intensity: 80.0 + i),
      ]);

      expect(data.confidenceLevel, IndividualNomogramConfidence.insufficient);
      expect(data.hybridWeightIndividual, 0.0);
      expect(data.hybridWeightPopulation, 1.0);
    });

    test('confidence initial for 6-8 sessions and 2 zones', () {
      final data = _data(_nomogramDetails([60, 62, 64, 78, 82, 86]));

      expect(data.confidenceLevel, IndividualNomogramConfidence.initial);
      expect(
        data.summary.recommendedMode,
        IndividualNomogramRecommendedMode.hybrid,
      );
    });

    test('confidence acceptable for 9-11 sessions and 3 zones', () {
      final data = _data(
        _nomogramDetails([60, 62, 68, 72, 78, 85, 92, 96, 100]),
      );

      expect(data.confidenceLevel, IndividualNomogramConfidence.acceptable);
      expect(
        data.summary.recommendedMode,
        IndividualNomogramRecommendedMode.hybrid,
      );
    });

    test('confidence robust for 12+ sessions and 3 zones', () {
      final data = _data(
        _nomogramDetails([58, 62, 66, 72, 76, 82, 86, 90, 92, 96, 100, 104]),
      );

      expect(data.confidenceLevel, IndividualNomogramConfidence.robust);
      expect(
        data.summary.recommendedMode,
        IndividualNomogramRecommendedMode.individual,
      );
    });

    test('hybrid weights match confidence levels', () {
      final initial = _data(_nomogramDetails([60, 62, 64, 78, 82, 86]));
      final acceptable = _data(
        _nomogramDetails([60, 62, 68, 72, 78, 85, 92, 96, 100]),
      );
      final robust = _data(
        _nomogramDetails([58, 62, 66, 72, 76, 82, 86, 90, 92, 96, 100, 104]),
      );

      expect(initial.hybridWeightIndividual, 0.3);
      expect(initial.hybridWeightPopulation, closeTo(0.7, 0.000001));
      expect(acceptable.hybridWeightIndividual, 0.7);
      expect(acceptable.hybridWeightPopulation, closeTo(0.3, 0.000001));
      expect(robust.hybridWeightIndividual, 1.0);
      expect(robust.hybridWeightPopulation, 0.0);
    });

    test('uses interpreted_slope not raw_slope', () {
      final data = _data([
        _detail(id: 1, intensity: 60, rawSlope: 9, interpretedSlope: 1.2),
        _detail(id: 2, intensity: 62, rawSlope: 8, interpretedSlope: 1.0),
        _detail(id: 3, intensity: 64, rawSlope: 7, interpretedSlope: 0.9),
        _detail(id: 4, intensity: 78, rawSlope: 6, interpretedSlope: 0.5),
        _detail(id: 5, intensity: 82, rawSlope: 5, interpretedSlope: 0.4),
        _detail(id: 6, intensity: 86, rawSlope: 4, interpretedSlope: 0.3),
      ]);

      expect(data.validPoints.first.interpretedSlope, 1.2);
      expect(data.validPoints.first.interpretedSlope, isNot(9));
    });

    test('fitted model generated when enough points exist', () {
      final data = _data(_nomogramDetails([60, 62, 64, 78, 82, 86]));

      expect(data.fittedModel, isNotNull);
      expect(data.individualCurvePoints, isNotEmpty);
    });

    test('population_only recommended when insufficient', () {
      final data = _data([_detail(id: 1)]);

      expect(data.summary.recommendedMode.key, 'population_only');
    });

    test('hybrid recommended when initial or acceptable', () {
      final data = _data(_nomogramDetails([60, 62, 64, 78, 82, 86]));

      expect(data.summary.recommendedMode.key, 'hybrid');
      expect(data.hybridCurvePoints, isNotEmpty);
    });

    test('individual recommended when robust', () {
      final data = _data(
        _nomogramDetails([58, 62, 66, 72, 76, 82, 86, 90, 92, 96, 100, 104]),
      );

      expect(data.summary.recommendedMode.key, 'individual');
      expect(data.hybridCurvePoints, isEmpty);
    });

    test('residuals computed for population individual and hybrid', () {
      final data = _data(_nomogramDetails([60, 62, 64, 78, 82, 86]));

      expect(data.validPoints.first.residualPopulation, isNotNull);
      expect(data.validPoints.first.residualIndividual, isNotNull);
      expect(data.validPoints.first.residualHybrid, isNotNull);
    });

    test('excluded sessions include reason', () {
      final data = _data([_detail(id: 1, intensity: null)]);

      expect(data.excludedSessions.single.reason.key, 'missing_intensity');
    });
  });

  group('Individual nomogram UI', () {
    late AppDatabase db;
    late int athleteId;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      athleteId = await _seedAthlete(db);
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('athlete detail exposes Individual Nomogram button', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AthleteDetailScreen(database: db, athleteId: athleteId),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Individual Nomogram'), findsOneWidget);
    });

    testWidgets(
      'individual nomogram screen renders header and confidence card',
      (tester) async {
        await _seedSession(db, athleteId, intensity: 80, slope: 0.5);

        await tester.pumpWidget(
          MaterialApp(
            home: IndividualNomogramScreen(database: db, athleteId: athleteId),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Runner One'), findsOneWidget);
        expect(find.text('Confidence'), findsWidgets);
      },
    );

    testWidgets('insufficient data state renders population-only guidance', (
      tester,
    ) async {
      await _seedSession(db, athleteId, intensity: 80, slope: 0.5);

      await tester.pumpWidget(
        MaterialApp(
          home: IndividualNomogramScreen(database: db, athleteId: athleteId),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.textContaining('Population-only mode'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('Population-only mode'), findsOneWidget);
    });

    testWidgets('robust data state renders individual model', (tester) async {
      await _seedMany(db, athleteId, [
        58,
        62,
        66,
        72,
        76,
        82,
        86,
        90,
        92,
        96,
        100,
        104,
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: IndividualNomogramScreen(database: db, athleteId: athleteId),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Individual model mode'), findsOneWidget);
      expect(find.text('Individual fit'), findsOneWidget);
    });

    testWidgets('points list renders valid points', (tester) async {
      await _seedSession(db, athleteId, intensity: 80, slope: 0.5);

      await tester.pumpWidget(
        MaterialApp(
          home: IndividualNomogramScreen(database: db, athleteId: athleteId),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Session 1'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Session 1'), findsWidgets);
    });

    testWidgets('excluded sessions list renders reasons', (tester) async {
      await _seedSession(db, athleteId, intensity: null, slope: 0.5);

      await tester.pumpWidget(
        MaterialApp(
          home: IndividualNomogramScreen(database: db, athleteId: athleteId),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Missing intensity'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Missing intensity'), findsOneWidget);
    });

    testWidgets('chart renders athlete points', (tester) async {
      await _seedSession(db, athleteId, intensity: 80, slope: 0.5);

      await tester.pumpWidget(
        MaterialApp(
          home: IndividualNomogramScreen(database: db, athleteId: athleteId),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Session points'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Session points'), findsOneWidget);
    });

    testWidgets('chart renders hybrid curve when applicable', (tester) async {
      await _seedMany(db, athleteId, [60, 62, 64, 78, 82, 86]);

      await tester.pumpWidget(
        MaterialApp(
          home: IndividualNomogramScreen(database: db, athleteId: athleteId),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Hybrid expected'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Hybrid expected'), findsOneWidget);
    });

    test('no medical diagnostic language', () {
      final text = File(
        'lib/ui/screens/nomogram/individual_nomogram_screen.dart',
      ).readAsStringSync().toLowerCase();

      expect(text, isNot(contains('diagnosis')));
      expect(text, isNot(contains('disease')));
      expect(text, isNot(contains('pathological')));
    });
  });

  group('Phase 4.0B regression guards', () {
    test('individual report chart still renders', () {
      const chart = NomogramChart(
        preset: PopulationNomogramSource.excelOperational,
        observedIntensity: 80,
        observedSlope: 0.5,
      );

      expect(chart.observedIntensity, 80);
      expect(chart.observedSlope, 0.5);
    });

    test('population nomogram chart still renders multiple points', () {
      const chart = NomogramChart(
        preset: PopulationNomogramSource.excelOperational,
        observedPoints: [
          NomogramObservedPoint(xIntensityPercent: 80, ySlope: 0.5, label: 'A'),
        ],
      );

      expect(chart.observedPoints.length, 1);
    });

    test(
      'no legacy computeSlope() usage in UI/report/import/edit/longitudinal/nomogram',
      () {
        final files = [
          File('lib/ui/screens/import/import_screen.dart'),
          File('lib/ui/screens/session/session_wizard_screen.dart'),
          File('lib/ui/screens/session/session_edit_screen.dart'),
          File('lib/ui/screens/reports/individual_report_screen.dart'),
          File('lib/ui/screens/reports/group_report_screen.dart'),
          File('lib/ui/screens/reports/population_nomogram_screen.dart'),
          File('lib/ui/screens/longitudinal/athlete_longitudinal_screen.dart'),
          File('lib/ui/screens/nomogram/individual_nomogram_screen.dart'),
          File('lib/data/services/session_edit_service.dart'),
        ];

        for (final file in files) {
          expect(file.readAsStringSync().contains('computeSlope('), isFalse);
        }
      },
    );

    test('direct RMSSD remains default', () {
      expect(_detail(id: 1).session.hrvInputMode, 'direct_rmssd');
    });

    test('RR correction remains off by default', () {
      expect(_detail(id: 1).session.rrCorrectionEnabled, isFalse);
    });

    test('real RR fixtures remain mandatory', () {
      for (final name in [
        '2026-05-25_05-27-02.txt',
        '2026-05-22_05-39-13.txt',
        '2026-05-21_05-42-46.txt',
      ]) {
        expect(File('test/fixtures/rr_samples/$name').existsSync(), isTrue);
      }
    });
  });
}

IndividualNomogramData _data(List<SessionDetail> details) {
  return buildIndividualNomogramData(athlete: _athlete(), details: details);
}

List<SessionDetail> _nomogramDetails(List<double> intensities) {
  return [
    for (var i = 0; i < intensities.length; i++)
      _detail(
        id: i + 1,
        intensity: intensities[i],
        interpretedSlope: _slopeForIntensity(intensities[i]),
      ),
  ];
}

double _slopeForIntensity(double intensity) => 2.2 - intensity / 80;

Athlete _athlete() {
  return const Athlete(
    id: 1,
    name: 'Runner One',
    sport: 'Running',
    birthDate: null,
    gender: null,
    positionOrEvent: null,
    masKmh: 20,
    vvo2maxKmh: null,
    mapW: null,
    fcMax: null,
    notes: null,
    isArchived: false,
    createdAt: '2026-05-26T00:00:00',
    updatedAt: '2026-05-26T00:00:00',
  );
}

SessionDetail _detail({
  required int id,
  double? intensity = 80,
  double? rawSlope,
  double? interpretedSlope = 0.5,
  bool isDraft = false,
}) {
  final date = '2026-05-${id.toString().padLeft(2, '0')}';
  return SessionDetail(
    athlete: _athlete(),
    session: Session(
      id: id,
      athleteId: 1,
      date: date,
      taskName: 'Session $id',
      sport: 'Running',
      sessionType: 'training',
      protocolName: null,
      contextEnvironment: null,
      isDraft: isDraft,
      intensityPercent: intensity,
      intensitySource: intensity == null ? null : 'direct_percent_mas',
      recoveryTimeMin: interpretedSlope == null ? null : 10,
      recoveryWindowStartMin: interpretedSlope == null ? null : 5,
      recoveryWindowEndMin: interpretedSlope == null ? null : 10,
      rmssdExercise: interpretedSlope == null ? null : 4,
      rmssdExerciseIsDefault: false,
      rmssdRecovery: interpretedSlope == null ? null : 24,
      slopeRaw: rawSlope ?? interpretedSlope,
      slopeInterpreted: interpretedSlope,
      itlIndex: interpretedSlope == null ? null : 1 / interpretedSlope,
      classification: null,
      hrvInputMode: 'direct_rmssd',
      rmssdRecoverySource: 'manual',
      rmssdExerciseSource: 'measured',
      rrQualityFlag: null,
      rrArtifactPercent: null,
      rrPreprocessingMode: null,
      rrCorrectionEnabled: false,
      rrCorrectionMethod: null,
      rrRawRmssd: null,
      rrCorrectedRmssd: null,
      rrRmssdUsed: null,
      rrArtifactCount: null,
      rrQualityDecision: null,
      rrQualityNotesJson: null,
      rrRmssdDeltaPercent: null,
      importBatchId: null,
      notes: null,
      createdAt: '${date}T00:00:00',
    ),
    variables: const [],
    hrvMeasurements: const [],
    notes: const [],
  );
}

Future<int> _seedAthlete(AppDatabase db) {
  final now = DateTime.now().toIso8601String();
  return db.athletesDao.insertAthlete(
    AthletesCompanion.insert(
      name: 'Runner One',
      sport: const drift.Value('Running'),
      masKmh: const drift.Value(20),
      createdAt: now,
      updatedAt: now,
    ),
  );
}

Future<void> _seedMany(
  AppDatabase db,
  int athleteId,
  List<double> intensities,
) async {
  for (var i = 0; i < intensities.length; i++) {
    await _seedSession(
      db,
      athleteId,
      day: i + 1,
      intensity: intensities[i],
      slope: _slopeForIntensity(intensities[i]),
    );
  }
}

Future<int> _seedSession(
  AppDatabase db,
  int athleteId, {
  int day = 1,
  double? intensity = 80,
  double? slope = 0.5,
  bool isDraft = false,
}) {
  final now = DateTime.now().toIso8601String();
  final date = '2026-05-${day.toString().padLeft(2, '0')}';
  return db.sessionsDao.insertSession(
    SessionsCompanion.insert(
      athleteId: athleteId,
      date: date,
      taskName: drift.Value('Session $day'),
      sport: const drift.Value('Running'),
      sessionType: const drift.Value('training'),
      isDraft: drift.Value(isDraft),
      intensityPercent: drift.Value(intensity),
      intensitySource: intensity == null
          ? const drift.Value.absent()
          : const drift.Value('direct_percent_mas'),
      recoveryTimeMin: slope == null
          ? const drift.Value.absent()
          : const drift.Value(10),
      recoveryWindowStartMin: slope == null
          ? const drift.Value.absent()
          : const drift.Value(5),
      recoveryWindowEndMin: slope == null
          ? const drift.Value.absent()
          : const drift.Value(10),
      rmssdExercise: slope == null
          ? const drift.Value.absent()
          : const drift.Value(4),
      rmssdRecovery: slope == null
          ? const drift.Value.absent()
          : const drift.Value(24),
      slopeRaw: drift.Value(slope),
      slopeInterpreted: drift.Value(slope),
      itlIndex: slope == null
          ? const drift.Value.absent()
          : drift.Value(1 / slope),
      hrvInputMode: const drift.Value('direct_rmssd'),
      rmssdRecoverySource: const drift.Value('manual'),
      rmssdExerciseSource: const drift.Value('measured'),
      createdAt: now,
    ),
  );
}
