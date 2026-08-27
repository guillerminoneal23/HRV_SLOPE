import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrv_slope_app/data/database/app_database.dart';
import 'package:hrv_slope_app/shared/engine/team_heatmap_builder.dart';
import 'package:hrv_slope_app/shared/engine/team_heatmap_filter.dart';
import 'package:hrv_slope_app/shared/engine/team_load_trend_builder.dart';
import 'package:hrv_slope_app/ui/screens/teams/team_longitudinal_heatmap_screen.dart';
import 'package:hrv_slope_app/ui/theme/app_theme.dart';
import 'package:hrv_slope_app/ui/widgets/longitudinal_chart.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Team load trend builder', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('deduplicates definitions and keeps type and unit identity', () async {
      final seed = await _seedLoadAnalysis(db);
      final data = await _loadData(db, seed.teamId);

      final definitions = availableTeamLoadDefinitions(data);

      expect(definitions.map((definition) => definition.id), [
        'external|playerload|au',
        'internal|rpe|1-10',
        'external|rpe|1-10',
        'external|playerload|kg',
      ]);
      expect(definitions.map((definition) => definition.label), [
        'External - PlayerLoad - AU',
        'Internal - RPE - 1-10',
        'External - RPE - 1-10',
        'External - PlayerLoad - kg',
      ]);
    });

    test('resolves athlete-specific load series with gaps by event', () async {
      final seed = await _seedLoadAnalysis(db);
      final data = await _loadData(db, seed.teamId);
      final playerLoad = availableTeamLoadDefinitions(
        data,
      ).singleWhere((definition) => definition.id == 'external|playerload|au');

      final trend = buildTeamLoadTrend(
        data: data,
        athleteId: seed.athleteIds['alpha']!,
        loadDefinition: playerLoad,
      )!;

      expect(trend.points.map((point) => point.eventId), [
        seed.eventIds['morning'],
        seed.eventIds['afternoon'],
        seed.eventIds['internalRpe'],
        seed.eventIds['missingLoad'],
        seed.eventIds['externalRpe'],
        seed.eventIds['kgLoad'],
      ]);
      expect(trend.points.map((point) => point.slope), [
        0.20,
        0.30,
        0.40,
        0.50,
        0.60,
        0.70,
      ]);
      expect(trend.points.map((point) => point.loadValue), [
        420,
        387,
        null,
        null,
        null,
        null,
      ]);
      expect(trend.validSlopePointCount, 6);
      expect(trend.loadPointCount, 2);
      expect(trend.points[0].event.date, '2026-08-20T10:00:00');
      expect(trend.points[1].event.date, '2026-08-20T17:00:00');
    });

    test(
      'separates internal, external and unit-specific load series',
      () async {
        final seed = await _seedLoadAnalysis(db);
        final data = await _loadData(db, seed.teamId);
        final definitions = availableTeamLoadDefinitions(data);

        TeamLoadTrend? trendFor(String id) => buildTeamLoadTrend(
          data: data,
          athleteId: seed.athleteIds['alpha']!,
          loadDefinition: definitions.singleWhere(
            (definition) => definition.id == id,
          ),
        );

        expect(
          trendFor('internal|rpe|1-10')!.points.map((point) => point.loadValue),
          [null, null, 7, null, null, null],
        );
        expect(
          trendFor('external|rpe|1-10')!.points.map((point) => point.loadValue),
          [null, null, null, null, 8, null],
        );
        expect(
          trendFor(
            'external|playerload|kg',
          )!.points.map((point) => point.loadValue),
          [null, null, null, null, null, 52],
        );
      },
    );

    test(
      'cell filters affect trend statistics without changing definitions',
      () async {
        final seed = await _seedFilteredTrend(db);
        final data = await _loadData(db, seed.teamId);
        final definitionsBefore = availableTeamLoadDefinitions(data);
        final playerLoad = definitionsBefore.singleWhere(
          (definition) => definition.id == 'external|playerload|au',
        );

        final trend = buildTeamLoadTrend(
          data: data,
          athleteId: seed.athleteId,
          loadDefinition: playerLoad,
          filter: const TeamHeatmapFilter(
            classificationOptionIds: {'expected'},
            fallbackFilter: TeamHeatmapFallbackFilter.measuredOnly,
          ),
        )!;

        expect(trend.visibleSessionCount, 1);
        expect(trend.validSlopePointCount, 1);
        expect(trend.latestValidSlope, closeTo(0.20, 0.000001));
        expect(trend.medianValidSlope, closeTo(0.20, 0.000001));
        expect(trend.fallbackCount, 0);
        expect(trend.points.map((point) => point.slope), [0.20, null, null]);
        expect(trend.points.map((point) => point.loadValue), [420, null, null]);
        expect(
          trend.points.last.cell.classification,
          'expected_response',
          reason: 'Filtering must not rewrite stored classification keys.',
        );
        expect(
          availableTeamLoadDefinitions(data).map((definition) => definition.id),
          [for (final definition in definitionsBefore) definition.id],
        );
      },
    );
  });

  group('Team load trend UI', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets(
      'selects athlete and one load metric without filtering heatmap',
      (tester) async {
        final seed = await _seedLoadAnalysis(db);

        await _pump(
          tester,
          TeamLongitudinalHeatmapScreen(database: db, teamId: seed.teamId),
        );

        expect(
          find.byKey(const Key('team_load_analysis_panel')),
          findsOneWidget,
        );
        expect(find.text('Slope only'), findsOneWidget);
        expect(
          find.text('Select an athlete to inspect slope and load trends.'),
          findsOneWidget,
        );

        await _tapVisible(
          tester,
          find.byKey(const Key('team_load_athlete_selector')),
        );
        await tester.tap(find.text('Alpha').last);
        await tester.pumpAndSettle();

        await _tapVisible(
          tester,
          find.byKey(const Key('team_load_metric_selector')),
        );
        await tester.tap(find.text('External - PlayerLoad - AU').last);
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('team_heatmap_grid')), findsOneWidget);
        expect(
          find.byKey(
            Key('team_heatmap_event_header_${seed.eventIds['internalRpe']}'),
          ),
          findsOneWidget,
        );

        final charts = tester.widgetList<LongitudinalChart>(
          find.byType(LongitudinalChart),
        );
        final slopeChart = charts.singleWhere(
          (chart) => chart.title == 'RMSSD-Slope trend',
        );
        final loadChart = charts.singleWhere(
          (chart) => chart.title == 'Load trend',
        );

        expect(slopeChart.points.map((point) => point.value), [
          0.20,
          0.30,
          0.40,
          0.50,
          0.60,
          0.70,
        ]);
        expect(loadChart.valueLabel, 'PlayerLoad (AU)');
        expect(loadChart.points.map((point) => point.value), [
          420,
          387,
          null,
          null,
          null,
          null,
        ]);
      },
    );

    testWidgets('keeps load analysis accessible below 1100px', (tester) async {
      final seed = await _seedLoadAnalysis(db);

      await _pump(
        tester,
        TeamLongitudinalHeatmapScreen(database: db, teamId: seed.teamId),
        size: const Size(900, 720),
      );

      expect(find.byKey(const Key('team_heatmap_grid')), findsOneWidget);
      expect(find.byKey(const Key('team_load_analysis_panel')), findsOneWidget);
      expect(
        find.byKey(const Key('team_load_athlete_selector')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('team_load_metric_selector')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'load chart preserves valid-null-valid timeline as a visual gap',
      (tester) async {
        final seed = await _seedLoadGap(db);

        await _pump(
          tester,
          TeamLongitudinalHeatmapScreen(database: db, teamId: seed.teamId),
        );

        await _tapVisible(
          tester,
          find.byKey(const Key('team_load_athlete_selector')),
        );
        await tester.tap(find.text('Alpha').last);
        await tester.pumpAndSettle();

        await _tapVisible(
          tester,
          find.byKey(const Key('team_load_metric_selector')),
        );
        await tester.tap(find.text('External - PlayerLoad - AU').last);
        await tester.pumpAndSettle();

        final loadChart = tester.widget<LongitudinalChart>(
          find.byKey(const Key('team_load_metric_chart')),
        );
        expect(loadChart.points.map((point) => point.value), [420, null, 510]);
        expect(loadChart.points.map((point) => point.label), [
          '2026-10-01 10:00',
          '2026-10-02 10:00',
          '2026-10-03 10:00',
        ]);

        final lineChart = tester.widget<LineChart>(
          find.descendant(
            of: find.byKey(const Key('team_load_metric_chart')),
            matching: find.byType(LineChart),
          ),
        );
        expect(
          lineChart.data.lineBarsData.map(
            (bar) => bar.spots.map((spot) => spot.x).toList(),
          ),
          [
            [0.0],
            [2.0],
          ],
        );
      },
    );

    testWidgets(
      'athlete search also limits trend athlete selector without changing metrics',
      (tester) async {
        final seed = await _seedLoadAnalysis(db);

        await _pump(
          tester,
          TeamLongitudinalHeatmapScreen(database: db, teamId: seed.teamId),
        );

        await _tapVisible(
          tester,
          find.byKey(const Key('team_load_athlete_selector')),
        );
        expect(find.text('Alpha'), findsWidgets);
        expect(find.text('Bravo'), findsWidgets);
        await tester.tap(find.text('Alpha').last);
        await tester.pumpAndSettle();

        await _tapVisible(
          tester,
          find.byKey(const Key('team_load_metric_selector')),
        );
        expect(find.text('Internal - RPE - 1-10'), findsWidgets);
        await tester.tapAt(const Offset(8, 8));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('team_heatmap_search')),
          'Alpha',
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(Key('team_heatmap_row_${seed.athleteIds['alpha']}')),
          findsOneWidget,
        );
        expect(
          find.byKey(Key('team_heatmap_row_${seed.athleteIds['bravo']}')),
          findsNothing,
        );

        await _tapVisible(
          tester,
          find.byKey(const Key('team_load_athlete_selector')),
        );
        expect(find.text('Alpha'), findsWidgets);
        expect(find.text('Bravo'), findsNothing);
        await tester.tap(find.text('Alpha').last);
        await tester.pumpAndSettle();

        await _tapVisible(
          tester,
          find.byKey(const Key('team_load_metric_selector')),
        );
        expect(find.text('Internal - RPE - 1-10'), findsWidgets);
        await tester.tapAt(const Offset(8, 8));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('team_heatmap_search')),
          '',
        );
        await tester.pumpAndSettle();

        await _tapVisible(
          tester,
          find.byKey(const Key('team_load_athlete_selector')),
        );
        expect(find.text('Alpha'), findsWidgets);
        expect(find.text('Bravo'), findsWidgets);
      },
    );

    testWidgets('filtered-out selected athlete does not keep showing a trend', (
      tester,
    ) async {
      final seed = await _seedLoadAnalysis(db);

      await _pump(
        tester,
        TeamLongitudinalHeatmapScreen(database: db, teamId: seed.teamId),
      );

      await _tapVisible(
        tester,
        find.byKey(const Key('team_load_athlete_selector')),
      );
      await tester.tap(find.text('Bravo').last);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('team_load_trend_summary')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('team_heatmap_search')),
        'Alpha',
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('team_load_trend_summary')), findsNothing);
      expect(
        find.text('Select an athlete to inspect slope and load trends.'),
        findsOneWidget,
      );
      await _tapVisible(
        tester,
        find.byKey(const Key('team_load_athlete_selector')),
      );
      expect(find.text('Alpha'), findsWidgets);
      expect(find.text('Bravo'), findsNothing);
    });

    testWidgets(
      'date reload resets unavailable metric but invalid draft does not',
      (tester) async {
        final seed = await _seedLoadAnalysis(db);

        await _pump(
          tester,
          TeamLongitudinalHeatmapScreen(database: db, teamId: seed.teamId),
        );

        await _tapVisible(
          tester,
          find.byKey(const Key('team_load_metric_selector')),
        );
        await tester.tap(find.text('Internal - RPE - 1-10').last);
        await tester.pumpAndSettle();
        expect(find.text('Internal - RPE - 1-10'), findsOneWidget);

        await tester.enterText(
          find.byKey(const Key('team_heatmap_date_from')),
          '2026-08-20',
        );
        await tester.enterText(
          find.byKey(const Key('team_heatmap_date_to')),
          '2026-08-20',
        );
        await tester.tap(find.byKey(const Key('team_heatmap_apply_filters')));
        await tester.pumpAndSettle();

        expect(find.text('Slope only'), findsOneWidget);
        expect(find.text('Internal - RPE - 1-10'), findsNothing);
        expect(
          find.byKey(
            Key('team_heatmap_event_header_${seed.eventIds['morning']}'),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(
            Key('team_heatmap_event_header_${seed.eventIds['afternoon']}'),
          ),
          findsOneWidget,
        );

        await _tapVisible(
          tester,
          find.byKey(const Key('team_load_metric_selector')),
        );
        await tester.tap(find.text('External - PlayerLoad - AU').last);
        await tester.pumpAndSettle();
        expect(find.text('External - PlayerLoad - AU'), findsOneWidget);

        await tester.enterText(
          find.byKey(const Key('team_heatmap_date_from')),
          '2026-99-99',
        );
        await tester.tap(find.byKey(const Key('team_heatmap_apply_filters')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('team_heatmap_inline_error')),
          findsOneWidget,
        );
        expect(find.text('External - PlayerLoad - AU'), findsOneWidget);
        expect(find.text('Period: 2026-08-20 to 2026-08-20'), findsOneWidget);
      },
    );

    testWidgets('in-memory heatmap filters do not change load definitions', (
      tester,
    ) async {
      final seed = await _seedLoadAnalysis(db);

      await _pump(
        tester,
        TeamLongitudinalHeatmapScreen(database: db, teamId: seed.teamId),
      );

      await tester.tap(
        find.byKey(const Key('team_heatmap_classification_filter_expected')),
      );
      await tester.pumpAndSettle();

      await _tapVisible(
        tester,
        find.byKey(const Key('team_load_metric_selector')),
      );

      expect(find.text('External - PlayerLoad - AU'), findsWidgets);
      expect(find.text('Internal - RPE - 1-10'), findsWidgets);
      expect(find.text('External - RPE - 1-10'), findsWidgets);
      expect(find.text('External - PlayerLoad - kg'), findsWidgets);
    });
  });
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(1280, 720),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(theme: buildAppTheme(), home: child));
  await tester.pumpAndSettle();
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<TeamHeatmapData> _loadData(AppDatabase db, int teamId) async {
  final bundle = await db.sessionEventsDao.getTeamLongitudinalBundle(
    teamId: teamId,
  );
  return buildTeamHeatmap(bundle);
}

Future<_LoadAnalysisSeed> _seedLoadAnalysis(AppDatabase db) async {
  final teamId = await db.teamsDao.createTeam(name: 'Load Trend FC');
  final alpha = await _insertAthlete(db, name: 'Alpha');
  final bravo = await _insertAthlete(db, name: 'Bravo');
  await db.teamsDao.assignAthleteToTeam(athleteId: alpha, teamId: teamId);
  await db.teamsDao.assignAthleteToTeam(athleteId: bravo, teamId: teamId);

  final events = <String, int>{};
  events['morning'] = await _insertEvent(
    db,
    teamId: teamId,
    date: '2026-08-20T10:00:00',
    taskName: 'Training',
    loadType: 'external',
    loadMetricName: 'PlayerLoad',
    loadUnit: 'AU',
  );
  events['afternoon'] = await _insertEvent(
    db,
    teamId: teamId,
    date: '2026-08-20T17:00:00',
    taskName: 'Training',
    loadType: 'external',
    loadMetricName: ' playerload ',
    loadUnit: ' au ',
  );
  events['internalRpe'] = await _insertEvent(
    db,
    teamId: teamId,
    date: '2026-08-21T10:00:00',
    taskName: 'RPE',
    loadType: 'internal',
    loadMetricName: 'RPE',
    loadUnit: '1-10',
  );
  events['missingLoad'] = await _insertEvent(
    db,
    teamId: teamId,
    date: '2026-08-22T10:00:00',
    taskName: 'Missing load',
    loadType: 'external',
    loadMetricName: 'PlayerLoad',
    loadUnit: 'AU',
  );
  events['externalRpe'] = await _insertEvent(
    db,
    teamId: teamId,
    date: '2026-08-23T10:00:00',
    taskName: 'External RPE',
    loadType: 'external',
    loadMetricName: 'RPE',
    loadUnit: '1-10',
  );
  events['kgLoad'] = await _insertEvent(
    db,
    teamId: teamId,
    date: '2026-08-24T10:00:00',
    taskName: 'Gym',
    loadType: 'external',
    loadMetricName: 'PlayerLoad',
    loadUnit: 'kg',
  );

  final sessionSpecs = [
    ('morning', 'external', 'PlayerLoad', 'AU', 420.0, 0.20),
    ('afternoon', 'external', ' playerload ', ' au ', 387.0, 0.30),
    ('internalRpe', 'internal', 'RPE', '1-10', 7.0, 0.40),
    ('missingLoad', 'external', 'PlayerLoad', 'AU', null, 0.50),
    ('externalRpe', 'external', 'RPE', '1-10', 8.0, 0.60),
    ('kgLoad', 'external', 'PlayerLoad', 'kg', 52.0, 0.70),
  ];

  for (final spec in sessionSpecs) {
    final eventId = events[spec.$1]!;
    await _insertSession(
      db,
      athleteId: alpha,
      eventId: eventId,
      date: _eventDate(spec.$1),
      taskName: spec.$1,
      loadType: spec.$2,
      loadMetricName: spec.$3,
      loadUnit: spec.$4,
      loadValue: spec.$5,
      rmssdExercise: 5,
      rmssdExerciseIsDefault: false,
      rmssdExerciseSource: 'measured',
      rmssdRecovery: 20,
      slope: spec.$6,
      classification: 'expected_response',
    );
    await _insertSession(
      db,
      athleteId: bravo,
      eventId: eventId,
      date: _eventDate(spec.$1),
      taskName: spec.$1,
      loadType: spec.$2,
      loadMetricName: spec.$3,
      loadUnit: spec.$4,
      loadValue: spec.$5 == null ? null : spec.$5! + 1,
      rmssdExercise: 6,
      rmssdExerciseIsDefault: false,
      rmssdExerciseSource: 'measured',
      rmssdRecovery: 21,
      slope: spec.$6 + 0.01,
      classification: 'expected_response',
    );
  }

  return _LoadAnalysisSeed(
    teamId: teamId,
    athleteIds: {'alpha': alpha, 'bravo': bravo},
    eventIds: events,
  );
}

Future<_LoadAnalysisSeed> _seedLoadGap(AppDatabase db) async {
  final teamId = await db.teamsDao.createTeam(name: 'Load Gap FC');
  final alpha = await _insertAthlete(db, name: 'Alpha');
  await db.teamsDao.assignAthleteToTeam(athleteId: alpha, teamId: teamId);

  final events = <String, int>{};
  events['playerLoadA'] = await _insertEvent(
    db,
    teamId: teamId,
    date: '2026-10-01T10:00:00',
    taskName: 'PlayerLoad A',
    loadType: 'external',
    loadMetricName: 'PlayerLoad',
    loadUnit: 'AU',
  );
  events['rpe'] = await _insertEvent(
    db,
    teamId: teamId,
    date: '2026-10-02T10:00:00',
    taskName: 'RPE',
    loadType: 'internal',
    loadMetricName: 'RPE',
    loadUnit: '1-10',
  );
  events['playerLoadC'] = await _insertEvent(
    db,
    teamId: teamId,
    date: '2026-10-03T10:00:00',
    taskName: 'PlayerLoad C',
    loadType: 'external',
    loadMetricName: 'PlayerLoad',
    loadUnit: 'AU',
  );

  await _insertSession(
    db,
    athleteId: alpha,
    eventId: events['playerLoadA']!,
    date: '2026-10-01T10:00:00',
    taskName: 'PlayerLoad A',
    loadType: 'external',
    loadMetricName: 'PlayerLoad',
    loadUnit: 'AU',
    loadValue: 420,
    rmssdExercise: 5,
    rmssdExerciseIsDefault: false,
    rmssdExerciseSource: 'measured',
    rmssdRecovery: 20,
    slope: 0.20,
    classification: 'expected_response',
  );
  await _insertSession(
    db,
    athleteId: alpha,
    eventId: events['rpe']!,
    date: '2026-10-02T10:00:00',
    taskName: 'RPE',
    loadType: 'internal',
    loadMetricName: 'RPE',
    loadUnit: '1-10',
    loadValue: 7,
    rmssdExercise: 5,
    rmssdExerciseIsDefault: false,
    rmssdExerciseSource: 'measured',
    rmssdRecovery: 20,
    slope: 0.30,
    classification: 'expected_response',
  );
  await _insertSession(
    db,
    athleteId: alpha,
    eventId: events['playerLoadC']!,
    date: '2026-10-03T10:00:00',
    taskName: 'PlayerLoad C',
    loadType: 'external',
    loadMetricName: 'PlayerLoad',
    loadUnit: 'AU',
    loadValue: 510,
    rmssdExercise: 5,
    rmssdExerciseIsDefault: false,
    rmssdExerciseSource: 'measured',
    rmssdRecovery: 20,
    slope: 0.40,
    classification: 'expected_response',
  );

  return _LoadAnalysisSeed(
    teamId: teamId,
    athleteIds: {'alpha': alpha},
    eventIds: events,
  );
}

Future<_FilteredTrendSeed> _seedFilteredTrend(AppDatabase db) async {
  final teamId = await db.teamsDao.createTeam(name: 'Filtered Trend FC');
  final athleteId = await _insertAthlete(db, name: 'Alpha');
  await db.teamsDao.assignAthleteToTeam(athleteId: athleteId, teamId: teamId);

  final expected = await _insertEvent(
    db,
    teamId: teamId,
    date: '2026-09-01T10:00:00',
    taskName: 'Expected',
    loadType: 'external',
    loadMetricName: 'PlayerLoad',
    loadUnit: 'AU',
  );
  final fallback = await _insertEvent(
    db,
    teamId: teamId,
    date: '2026-09-02T10:00:00',
    taskName: 'Fallback',
    loadType: 'external',
    loadMetricName: 'PlayerLoad',
    loadUnit: 'AU',
  );
  final incomplete = await _insertEvent(
    db,
    teamId: teamId,
    date: '2026-09-03T10:00:00',
    taskName: 'Incomplete',
    loadType: 'external',
    loadMetricName: 'PlayerLoad',
    loadUnit: 'AU',
  );

  await _insertSession(
    db,
    athleteId: athleteId,
    eventId: expected,
    date: '2026-09-01T10:00:00',
    taskName: 'Expected',
    loadType: 'external',
    loadMetricName: 'PlayerLoad',
    loadUnit: 'AU',
    loadValue: 420,
    rmssdExercise: 5,
    rmssdExerciseIsDefault: false,
    rmssdExerciseSource: 'measured',
    rmssdRecovery: 20,
    slope: 0.20,
    classification: 'expected_response',
  );
  await _insertSession(
    db,
    athleteId: athleteId,
    eventId: fallback,
    date: '2026-09-02T10:00:00',
    taskName: 'Fallback',
    loadType: 'external',
    loadMetricName: 'PlayerLoad',
    loadUnit: 'AU',
    loadValue: 600,
    rmssdExercise: 4,
    rmssdExerciseIsDefault: true,
    rmssdExerciseSource: 'fallback_4_ms',
    rmssdRecovery: 22,
    slope: 0.80,
    classification: 'low_internal_load_or_fast_recovery',
  );
  await _insertSession(
    db,
    athleteId: athleteId,
    eventId: incomplete,
    date: '2026-09-03T10:00:00',
    taskName: 'Incomplete',
    loadType: 'external',
    loadMetricName: 'PlayerLoad',
    loadUnit: 'AU',
    loadValue: 999,
    rmssdExercise: 6,
    rmssdExerciseIsDefault: false,
    rmssdExerciseSource: 'measured',
    rmssdRecovery: null,
    slope: 9.9,
    classification: 'expected_response',
  );

  return _FilteredTrendSeed(teamId: teamId, athleteId: athleteId);
}

String _eventDate(String eventKey) {
  switch (eventKey) {
    case 'morning':
      return '2026-08-20T10:00:00';
    case 'afternoon':
      return '2026-08-20T17:00:00';
    case 'internalRpe':
      return '2026-08-21T10:00:00';
    case 'missingLoad':
      return '2026-08-22T10:00:00';
    case 'externalRpe':
      return '2026-08-23T10:00:00';
    case 'kgLoad':
      return '2026-08-24T10:00:00';
  }
  throw ArgumentError.value(eventKey, 'eventKey');
}

Future<int> _insertAthlete(
  AppDatabase db, {
  required String name,
  bool isArchived = false,
}) {
  final now = DateTime.now().toIso8601String();
  return db.athletesDao.insertAthlete(
    AthletesCompanion.insert(
      name: name,
      sport: const drift.Value('Soccer'),
      isArchived: drift.Value(isArchived),
      createdAt: now,
      updatedAt: now,
    ),
  );
}

Future<int> _insertEvent(
  AppDatabase db, {
  required int teamId,
  required String date,
  required String taskName,
  required String loadType,
  required String loadMetricName,
  required String loadUnit,
}) {
  final now = DateTime.now().toIso8601String();
  return db.sessionEventsDao.createEvent(
    SessionEventsCompanion.insert(
      teamId: drift.Value(teamId),
      date: date,
      taskName: drift.Value(taskName),
      sport: const drift.Value('Soccer'),
      sessionType: const drift.Value('Training'),
      protocolName: const drift.Value('5-10'),
      contextEnvironment: const drift.Value('Field'),
      recoveryWindowStartMin: 5,
      recoveryWindowEndMin: 10,
      loadType: loadType,
      loadMetricName: loadMetricName,
      loadUnit: drift.Value(loadUnit),
      createdAt: now,
      updatedAt: now,
    ),
  );
}

Future<int> _insertSession(
  AppDatabase db, {
  required int athleteId,
  required int eventId,
  required String date,
  required String taskName,
  required String loadType,
  required String loadMetricName,
  required String loadUnit,
  required double? loadValue,
  required double? rmssdExercise,
  required bool rmssdExerciseIsDefault,
  required String rmssdExerciseSource,
  required double? rmssdRecovery,
  required double? slope,
  required String? classification,
}) async {
  final now = DateTime.now().toIso8601String();
  final sessionId = await db.sessionsDao.insertSession(
    SessionsCompanion.insert(
      athleteId: athleteId,
      eventId: drift.Value(eventId),
      date: date,
      taskName: drift.Value(taskName),
      sport: const drift.Value('Soccer'),
      sessionType: const drift.Value('Training'),
      protocolName: const drift.Value('5-10'),
      contextEnvironment: const drift.Value('Field'),
      isDraft: const drift.Value(false),
      intensityPercent: const drift.Value(80),
      intensitySource: drift.Value(
        loadType == 'external' ? 'External' : 'Internal',
      ),
      recoveryTimeMin: const drift.Value(10),
      recoveryWindowStartMin: const drift.Value(5),
      recoveryWindowEndMin: const drift.Value(10),
      rmssdExercise: drift.Value(rmssdExercise),
      rmssdExerciseIsDefault: drift.Value(rmssdExerciseIsDefault),
      rmssdRecovery: drift.Value(rmssdRecovery),
      slopeRaw: drift.Value(slope),
      slopeInterpreted: drift.Value(slope),
      itlIndex: drift.Value(slope == null ? null : slope * 1.5),
      classification: drift.Value(classification),
      hrvInputMode: const drift.Value('direct_rmssd'),
      rmssdRecoverySource: const drift.Value('manual'),
      rmssdExerciseSource: drift.Value(rmssdExerciseSource),
      rrQualityFlag: const drift.Value(null),
      rrQualityDecision: const drift.Value(null),
      createdAt: now,
    ),
  );
  if (loadValue != null) {
    await db.sessionsDao.insertVariable(
      IntensityVariablesCompanion.insert(
        sessionId: sessionId,
        category: loadType,
        name: loadMetricName,
        unit: drift.Value(loadUnit),
        value: loadValue,
        source: const drift.Value('manual'),
        isPrimaryForNomogram: const drift.Value(true),
        createdAt: now,
      ),
    );
  }
  return sessionId;
}

class _LoadAnalysisSeed {
  final int teamId;
  final Map<String, int> athleteIds;
  final Map<String, int> eventIds;

  const _LoadAnalysisSeed({
    required this.teamId,
    required this.athleteIds,
    required this.eventIds,
  });
}

class _FilteredTrendSeed {
  final int teamId;
  final int athleteId;

  const _FilteredTrendSeed({required this.teamId, required this.athleteId});
}
