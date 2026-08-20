import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrv_slope_app/data/database/app_database.dart';
import 'package:hrv_slope_app/shared/engine/team_heatmap_builder.dart';
import 'package:hrv_slope_app/ui/screens/session/session_detail_screen.dart';
import 'package:hrv_slope_app/ui/screens/teams/team_detail_screen.dart';
import 'package:hrv_slope_app/ui/screens/teams/team_longitudinal_heatmap_screen.dart';
import 'package:hrv_slope_app/ui/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Team longitudinal batch query', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'loads events, sessions and historical athletes for a team in one batch',
      () async {
        final seed = await _seedLongitudinal(
          db,
          archivedTeam: true,
          removeAlphaFromRoster: true,
        );

        final bundle = await db.sessionEventsDao.getTeamLongitudinalBundle(
          teamId: seed.teamId,
        );

        expect(bundle.team!.isArchived, isTrue);
        expect(bundle.events.map((event) => event.id), [
          seed.eventIds['event1'],
          seed.eventIds['event2'],
          seed.eventIds['empty'],
        ]);
        expect(bundle.sessions, hasLength(4));
        expect(bundle.athletes.map((athlete) => athlete.id).toSet(), {
          seed.athleteIds['alpha'],
          seed.athleteIds['bravo'],
          seed.athleteIds['charlie'],
        });
        expect(
          bundle.athletes
              .singleWhere((athlete) => athlete.name == 'Charlie Historic')
              .isArchived,
          isTrue,
        );
        expect(bundle.variables, hasLength(4));
      },
    );

    test('respects date range filters', () async {
      final seed = await _seedLongitudinal(db);

      final bundle = await db.sessionEventsDao.getTeamLongitudinalBundle(
        teamId: seed.teamId,
        dateFrom: '2026-01-02T00:00:00',
        dateTo: '2026-01-02T23:59:59.999',
      );

      expect(bundle.events.map((event) => event.id), [seed.eventIds['event2']]);
      expect(bundle.sessions, hasLength(2));
      expect(bundle.athletes.map((athlete) => athlete.name).toSet(), {
        'Bravo',
        'Charlie Historic',
      });
    });

    test('loads and builds a dense 40 athlete x 50 event matrix', () async {
      final seed = await _seedDenseHeatmap(
        db,
        athleteCount: 40,
        eventCount: 50,
      );

      final bundle = await db.sessionEventsDao.getTeamLongitudinalBundle(
        teamId: seed.teamId,
      );
      final data = buildTeamHeatmap(bundle);

      expect(bundle.events, hasLength(50));
      expect(bundle.sessions, hasLength(2000));
      expect(bundle.athletes, hasLength(40));
      expect(data.events, hasLength(50));
      expect(data.rows, hasLength(40));
      expect(data.summary.validCellCount, 2000);
      expect(data.summary.incompleteCellCount, 0);
      expect(data.summary.missingCellCount, 0);
      expect(data.summary.duplicateCellCount, 0);
      expect(data.rows.every((row) => row.cells.length == 50), isTrue);
      expect(
        data.rows
            .expand((row) => row.cells)
            .every((cell) => cell.state == TeamHeatmapCellState.valid),
        isTrue,
      );
    });

    test('getTeamLongitudinalBundle is structurally batch-based', () {
      final source = File(
        'lib/data/database/daos/session_events_dao.dart',
      ).readAsStringSync();
      final methodStart = source.indexOf('getTeamLongitudinalBundle');
      final methodEnd = source.indexOf(
        'Future<List<SessionDetail>>',
        methodStart,
      );
      final methodBody = source.substring(methodStart, methodEnd);

      expect(methodBody, isNot(contains('getAllSessionDetails')));
      expect(methodBody, isNot(contains('getSessionDetail(')));
      expect(methodBody, contains('session.eventId.isIn(eventIds)'));
      expect(methodBody, contains('athlete.id.isIn(athleteIds)'));
    });
  });

  group('Team heatmap builder', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'builds chronological events, alphabetical athletes and cell states',
      () async {
        final seed = await _seedLongitudinal(db, removeAlphaFromRoster: true);
        final bundle = await db.sessionEventsDao.getTeamLongitudinalBundle(
          teamId: seed.teamId,
        );

        final data = buildTeamHeatmap(bundle);
        final alpha = _row(data, 'Alpha');
        final bravo = _row(data, 'Bravo');
        final charlie = _row(data, 'Charlie Historic');
        final alphaEvent1 = _cell(alpha, seed.eventIds['event1']!);
        final alphaEvent2 = _cell(alpha, seed.eventIds['event2']!);
        final bravoEvent1 = _cell(bravo, seed.eventIds['event1']!);
        final charlieEvent2 = _cell(charlie, seed.eventIds['event2']!);

        expect(data.events.map((event) => event.id), [
          seed.eventIds['event1'],
          seed.eventIds['event2'],
        ]);
        expect(data.rows.map((row) => row.athlete.name), [
          'Alpha',
          'Bravo',
          'Charlie Historic',
        ]);
        expect(data.summary.eventCount, 2);
        expect(data.summary.athleteCount, 3);
        expect(data.summary.validCellCount, 3);
        expect(data.summary.incompleteCellCount, 1);
        expect(data.summary.missingCellCount, 2);
        expect(data.summary.fallbackCellCount, 1);
        expect(alphaEvent1.state, TeamHeatmapCellState.valid);
        expect(alphaEvent1.hasFallbackExercise, isTrue);
        expect(alphaEvent1.classification, 'very_high_internal_load');
        expect(alphaEvent2.state, TeamHeatmapCellState.missing);
        expect(bravoEvent1.rmssdExercise, 4);
        expect(bravoEvent1.hasFallbackExercise, isFalse);
        expect(charlie.athlete.isArchived, isTrue);
        expect(charlieEvent2.state, TeamHeatmapCellState.incomplete);
        expect(charlieEvent2.statusLabels, contains('Incomplete'));
      },
    );

    test('marks duplicate athlete-event sessions as inconsistent', () async {
      final seed = await _seedLongitudinal(db, includeDuplicate: true);
      final bundle = await db.sessionEventsDao.getTeamLongitudinalBundle(
        teamId: seed.teamId,
      );

      final data = buildTeamHeatmap(bundle);
      final duplicate = _cell(_row(data, 'Alpha'), seed.eventIds['event1']!);

      expect(duplicate.state, TeamHeatmapCellState.duplicate);
      expect(duplicate.duplicateSessionIds, hasLength(2));
      expect(duplicate.sessionId, isNull);
      expect(duplicate.statusLabels, contains('Duplicate sessions'));
      expect(data.summary.duplicateCellCount, 1);
    });

    test(
      'excludes incomplete persisted slopes from row last and median slope',
      () async {
        final seed = await _seedIncompletePersistedSlopes(db);
        final bundle = await db.sessionEventsDao.getTeamLongitudinalBundle(
          teamId: seed.teamId,
        );

        final data = buildTeamHeatmap(bundle);
        final row = _row(data, 'Incomplete Persisted');

        expect(row.visibleSessionCount, 3);
        expect(row.lastSlope, closeTo(0.2, 0.000001));
        expect(row.medianSlope, closeTo(0.2, 0.000001));
        expect(data.summary.validCellCount, 1);
        expect(data.summary.incompleteCellCount, 2);
        expect(
          row.cells
              .where((cell) => cell.state == TeamHeatmapCellState.incomplete)
              .map((cell) => cell.slope),
          containsAll([8.8, 9.9]),
        );
      },
    );
  });

  group('TeamLongitudinalHeatmapScreen UI', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('renders header, legend, heatmap and cell states', (
      tester,
    ) async {
      final seed = await _seedLongitudinal(db, archivedTeam: true);

      await _pump(
        tester,
        TeamLongitudinalHeatmapScreen(database: db, teamId: seed.teamId),
      );

      expect(find.byType(TeamLongitudinalHeatmapScreen), findsOneWidget);
      expect(find.byKey(const Key('team_heatmap_header')), findsOneWidget);
      expect(find.text('Phase 3B Team'), findsWidgets);
      expect(find.text('Archived team'), findsOneWidget);
      expect(find.byKey(const Key('team_heatmap_legend')), findsOneWidget);
      expect(find.byKey(const Key('team_heatmap_grid')), findsOneWidget);
      expect(
        find.byKey(
          Key(
            'team_heatmap_fallback_${seed.athleteIds['alpha']}_${seed.eventIds['event1']}',
          ),
        ),
        findsOneWidget,
      );
      expect(find.text('!'), findsWidgets);
      expect(find.text('arch'), findsOneWidget);
      expect(
        find.byKey(
          Key(
            'team_heatmap_cell_${seed.athleteIds['alpha']}_${seed.eventIds['event2']}',
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('filters by athlete search and date range', (tester) async {
      final seed = await _seedLongitudinal(db);

      await _pump(
        tester,
        TeamLongitudinalHeatmapScreen(database: db, teamId: seed.teamId),
      );

      await tester.enterText(
        find.byKey(const Key('team_heatmap_search')),
        'Charlie',
      );
      await tester.pumpAndSettle();
      expect(find.text('Charlie Historic'), findsOneWidget);
      expect(find.text('Alpha'), findsNothing);

      await tester.enterText(find.byKey(const Key('team_heatmap_search')), '');
      await tester.enterText(
        find.byKey(const Key('team_heatmap_date_from')),
        '2026-01-02',
      );
      await tester.enterText(
        find.byKey(const Key('team_heatmap_date_to')),
        '2026-01-02',
      );
      await tester.tap(find.byKey(const Key('team_heatmap_apply_filters')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(Key('team_heatmap_event_header_${seed.eventIds['event1']}')),
        findsNothing,
      );
      expect(
        find.byKey(Key('team_heatmap_event_header_${seed.eventIds['event2']}')),
        findsOneWidget,
      );
    });

    testWidgets('opens contextual cell detail and individual session', (
      tester,
    ) async {
      final seed = await _seedLongitudinal(db);

      await _pump(
        tester,
        TeamLongitudinalHeatmapScreen(database: db, teamId: seed.teamId),
      );

      final cellFinder = find.byKey(
        Key(
          'team_heatmap_cell_${seed.athleteIds['alpha']}_${seed.eventIds['event1']}',
        ),
      );
      await tester.ensureVisible(cellFinder);
      await tester.pumpAndSettle();
      await tester.tap(cellFinder);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('team_heatmap_cell_dialog')), findsOneWidget);
      expect(find.textContaining('fallback 4 ms'), findsOneWidget);
      await tester.tap(find.byKey(const Key('team_heatmap_open_session')));
      await tester.pumpAndSettle();

      expect(find.byType(SessionDetailScreen), findsOneWidget);
      expect(find.text('Alpha'), findsOneWidget);
    });

    testWidgets('handles a 40 athlete x 50 event matrix with scrolls', (
      tester,
    ) async {
      final seed = await _seedLargeHeatmap(
        db,
        athleteCount: 40,
        eventCount: 50,
      );

      await _pump(
        tester,
        TeamLongitudinalHeatmapScreen(database: db, teamId: seed.teamId),
      );

      expect(find.byKey(const Key('team_heatmap_grid')), findsOneWidget);
      expect(
        find.byKey(const Key('team_heatmap_horizontal_scroll')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('team_heatmap_vertical_scroll')),
        findsOneWidget,
      );
      expect(find.text('Player 40'), findsOneWidget);
      expect(
        find.byKey(Key('team_heatmap_event_header_${seed.lastEventId}')),
        findsOneWidget,
      );

      await tester.dragFrom(const Offset(700, 540), const Offset(-500, 0));
      await tester.pumpAndSettle();
    });

    testWidgets('team detail opens the longitudinal heatmap', (tester) async {
      final seed = await _seedLongitudinal(db, archivedTeam: true);

      await _pump(tester, TeamDetailScreen(database: db, teamId: seed.teamId));

      await tester.tap(find.byKey(const Key('team_open_longitudinal_heatmap')));
      await tester.pumpAndSettle();

      expect(find.byType(TeamLongitudinalHeatmapScreen), findsOneWidget);
      expect(find.byKey(const Key('team_heatmap_grid')), findsOneWidget);
      expect(find.text('Archived team'), findsOneWidget);
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

TeamHeatmapRow _row(TeamHeatmapData data, String name) {
  return data.rows.singleWhere((row) => row.athlete.name == name);
}

TeamHeatmapCell _cell(TeamHeatmapRow row, int eventId) {
  return row.cells.singleWhere((cell) => cell.eventId == eventId);
}

Future<_LongitudinalSeed> _seedLongitudinal(
  AppDatabase db, {
  bool archivedTeam = false,
  bool removeAlphaFromRoster = false,
  bool includeDuplicate = false,
}) async {
  final teamId = await db.teamsDao.createTeam(
    name: 'Phase 3B Team',
    sport: 'Soccer',
  );
  final alpha = await _insertAthlete(db, name: 'Alpha');
  final bravo = await _insertAthlete(db, name: 'Bravo');
  final charlie = await _insertAthlete(
    db,
    name: 'Charlie Historic',
    isArchived: true,
  );
  for (final athleteId in [alpha, bravo, charlie]) {
    await db.teamsDao.assignAthleteToTeam(athleteId: athleteId, teamId: teamId);
  }
  if (removeAlphaFromRoster) {
    await db.teamsDao.removeAthleteFromTeam(alpha);
  }

  final event1 = await _insertEvent(
    db,
    teamId: teamId,
    date: '2026-01-01T10:00:00',
    taskName: 'RSA 1',
    loadType: 'external',
    loadMetricName: 'percent_mas',
    loadUnit: '%',
  );
  final event2 = await _insertEvent(
    db,
    teamId: teamId,
    date: '2026-01-02T10:00:00',
    taskName: 'RSA 2',
    loadType: 'internal',
    loadMetricName: 'rpe',
    loadUnit: '1-10',
  );
  final empty = await _insertEvent(
    db,
    teamId: teamId,
    date: '2026-01-03T10:00:00',
    taskName: 'Empty trace',
    loadType: 'external',
    loadMetricName: 'player_load',
    loadUnit: 'AU',
  );

  final alphaEvent1 = await _insertSession(
    db,
    athleteId: alpha,
    eventId: event1,
    date: '2026-01-01T10:00:00',
    taskName: 'RSA 1',
    loadType: 'external',
    loadMetricName: 'percent_mas',
    loadUnit: '%',
    loadValue: 100,
    rmssdExercise: 4,
    rmssdExerciseIsDefault: true,
    rmssdExerciseSource: 'fallback_4_ms',
    rmssdRecovery: 20,
    slope: 0.12,
    classification: 'very_high_internal_load',
  );
  final bravoEvent1 = await _insertSession(
    db,
    athleteId: bravo,
    eventId: event1,
    date: '2026-01-01T10:00:00',
    taskName: 'RSA 1',
    loadType: 'external',
    loadMetricName: 'percent_mas',
    loadUnit: '%',
    loadValue: 110,
    rmssdExercise: 4,
    rmssdExerciseIsDefault: false,
    rmssdExerciseSource: 'measured',
    rmssdRecovery: 22,
    slope: 0.24,
    classification: 'expected_response',
  );
  final bravoEvent2 = await _insertSession(
    db,
    athleteId: bravo,
    eventId: event2,
    date: '2026-01-02T10:00:00',
    taskName: 'RSA 2',
    loadType: 'internal',
    loadMetricName: 'rpe',
    loadUnit: '1-10',
    loadValue: 6,
    rmssdExercise: 6,
    rmssdExerciseIsDefault: false,
    rmssdExerciseSource: 'measured',
    rmssdRecovery: 26,
    slope: 0.42,
    classification: 'low_internal_load_or_fast_recovery',
  );
  final charlieEvent2 = await _insertSession(
    db,
    athleteId: charlie,
    eventId: event2,
    date: '2026-01-02T10:00:00',
    taskName: 'RSA 2',
    loadType: 'internal',
    loadMetricName: 'rpe',
    loadUnit: '1-10',
    loadValue: 7,
    rmssdExercise: 5,
    rmssdExerciseIsDefault: false,
    rmssdExerciseSource: 'measured',
    rmssdRecovery: 23,
    slope: null,
    classification: null,
  );
  if (includeDuplicate) {
    await _insertSession(
      db,
      athleteId: alpha,
      eventId: event1,
      date: '2026-01-01T10:00:00',
      taskName: 'RSA 1 duplicate',
      loadType: 'external',
      loadMetricName: 'percent_mas',
      loadUnit: '%',
      loadValue: 115,
      rmssdExercise: 7,
      rmssdExerciseIsDefault: false,
      rmssdExerciseSource: 'measured',
      rmssdRecovery: 28,
      slope: 0.9,
      classification: 'expected_response',
    );
  }

  if (archivedTeam) {
    await db.teamsDao.archiveTeam(teamId);
  }

  return _LongitudinalSeed(
    teamId: teamId,
    athleteIds: {'alpha': alpha, 'bravo': bravo, 'charlie': charlie},
    eventIds: {'event1': event1, 'event2': event2, 'empty': empty},
    sessionIds: {
      'alpha_event1': alphaEvent1,
      'bravo_event1': bravoEvent1,
      'bravo_event2': bravoEvent2,
      'charlie_event2': charlieEvent2,
    },
  );
}

Future<_LargeHeatmapSeed> _seedLargeHeatmap(
  AppDatabase db, {
  required int athleteCount,
  required int eventCount,
}) async {
  final teamId = await db.teamsDao.createTeam(name: 'Large Heatmap Team');
  final athleteIds = <int>[];
  for (var i = 1; i <= athleteCount; i++) {
    final athleteId = await _insertAthlete(
      db,
      name: 'Player ${i.toString().padLeft(2, '0')}',
    );
    athleteIds.add(athleteId);
    await db.teamsDao.assignAthleteToTeam(athleteId: athleteId, teamId: teamId);
  }

  var lastEventId = 0;
  for (var i = 1; i <= eventCount; i++) {
    final day = ((i - 1) % 28) + 1;
    final eventId = await _insertEvent(
      db,
      teamId: teamId,
      date: '2026-02-${day.toString().padLeft(2, '0')}T10:00:00',
      taskName: 'E$i',
      loadType: 'external',
      loadMetricName: 'percent_mas',
      loadUnit: '%',
    );
    lastEventId = eventId;
    final athleteId = athleteIds[(i - 1) % athleteIds.length];
    await _insertSession(
      db,
      athleteId: athleteId,
      eventId: eventId,
      date: '2026-02-${day.toString().padLeft(2, '0')}T10:00:00',
      taskName: 'E$i',
      loadType: 'external',
      loadMetricName: 'percent_mas',
      loadUnit: '%',
      loadValue: 80 + i.toDouble(),
      rmssdExercise: 5,
      rmssdExerciseIsDefault: false,
      rmssdExerciseSource: 'measured',
      rmssdRecovery: 20 + i.toDouble(),
      slope: 0.2 + i / 100,
      classification: 'expected_response',
    );
  }

  return _LargeHeatmapSeed(teamId: teamId, lastEventId: lastEventId);
}

Future<_LargeHeatmapSeed> _seedDenseHeatmap(
  AppDatabase db, {
  required int athleteCount,
  required int eventCount,
}) async {
  final teamId = await db.teamsDao.createTeam(name: 'Dense Heatmap Team');
  final athleteIds = <int>[];
  for (var i = 1; i <= athleteCount; i++) {
    final athleteId = await _insertAthlete(
      db,
      name: 'Dense Player ${i.toString().padLeft(2, '0')}',
    );
    athleteIds.add(athleteId);
    await db.teamsDao.assignAthleteToTeam(athleteId: athleteId, teamId: teamId);
  }

  var lastEventId = 0;
  for (var eventIndex = 0; eventIndex < eventCount; eventIndex++) {
    final date = DateTime(2026, 3, 1 + eventIndex, 10).toIso8601String();
    final eventId = await _insertEvent(
      db,
      teamId: teamId,
      date: date,
      taskName: 'Dense E${eventIndex + 1}',
      loadType: 'external',
      loadMetricName: 'percent_mas',
      loadUnit: '%',
    );
    lastEventId = eventId;
    for (
      var athleteIndex = 0;
      athleteIndex < athleteIds.length;
      athleteIndex++
    ) {
      await _insertSession(
        db,
        athleteId: athleteIds[athleteIndex],
        eventId: eventId,
        date: date,
        taskName: 'Dense E${eventIndex + 1}',
        loadType: 'external',
        loadMetricName: 'percent_mas',
        loadUnit: '%',
        loadValue: 70 + eventIndex + athleteIndex / 10,
        rmssdExercise: 5 + athleteIndex / 10,
        rmssdExerciseIsDefault: false,
        rmssdExerciseSource: 'measured',
        rmssdRecovery: 20 + eventIndex / 10 + athleteIndex / 20,
        slope: 0.2 + eventIndex / 100 + athleteIndex / 1000,
        classification: 'expected_response',
      );
    }
  }

  return _LargeHeatmapSeed(teamId: teamId, lastEventId: lastEventId);
}

Future<_LongitudinalSeed> _seedIncompletePersistedSlopes(AppDatabase db) async {
  final teamId = await db.teamsDao.createTeam(name: 'Incomplete Slope Team');
  final athleteId = await _insertAthlete(db, name: 'Incomplete Persisted');
  await db.teamsDao.assignAthleteToTeam(athleteId: athleteId, teamId: teamId);

  final event1 = await _insertEvent(
    db,
    teamId: teamId,
    date: '2026-04-01T10:00:00',
    taskName: 'Valid',
    loadType: 'external',
    loadMetricName: 'percent_mas',
    loadUnit: '%',
  );
  final event2 = await _insertEvent(
    db,
    teamId: teamId,
    date: '2026-04-02T10:00:00',
    taskName: 'Missing recovery',
    loadType: 'external',
    loadMetricName: 'percent_mas',
    loadUnit: '%',
  );
  final event3 = await _insertEvent(
    db,
    teamId: teamId,
    date: '2026-04-03T10:00:00',
    taskName: 'Missing exercise',
    loadType: 'external',
    loadMetricName: 'percent_mas',
    loadUnit: '%',
  );

  final session1 = await _insertSession(
    db,
    athleteId: athleteId,
    eventId: event1,
    date: '2026-04-01T10:00:00',
    taskName: 'Valid',
    loadType: 'external',
    loadMetricName: 'percent_mas',
    loadUnit: '%',
    loadValue: 80,
    rmssdExercise: 5,
    rmssdExerciseIsDefault: false,
    rmssdExerciseSource: 'measured',
    rmssdRecovery: 20,
    slope: 0.2,
    classification: 'expected_response',
  );
  final session2 = await _insertSession(
    db,
    athleteId: athleteId,
    eventId: event2,
    date: '2026-04-02T10:00:00',
    taskName: 'Missing recovery',
    loadType: 'external',
    loadMetricName: 'percent_mas',
    loadUnit: '%',
    loadValue: 90,
    rmssdExercise: 5,
    rmssdExerciseIsDefault: false,
    rmssdExerciseSource: 'measured',
    rmssdRecovery: null,
    slope: 9.9,
    classification: 'expected_response',
  );
  final session3 = await _insertSession(
    db,
    athleteId: athleteId,
    eventId: event3,
    date: '2026-04-03T10:00:00',
    taskName: 'Missing exercise',
    loadType: 'external',
    loadMetricName: 'percent_mas',
    loadUnit: '%',
    loadValue: 95,
    rmssdExercise: null,
    rmssdExerciseIsDefault: false,
    rmssdExerciseSource: 'measured',
    rmssdRecovery: 24,
    slope: 8.8,
    classification: 'expected_response',
  );

  return _LongitudinalSeed(
    teamId: teamId,
    athleteIds: {'athlete': athleteId},
    eventIds: {'event1': event1, 'event2': event2, 'event3': event3},
    sessionIds: {
      'valid': session1,
      'missing_recovery': session2,
      'missing_exercise': session3,
    },
  );
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
  required double loadValue,
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
  return sessionId;
}

class _LongitudinalSeed {
  final int teamId;
  final Map<String, int> athleteIds;
  final Map<String, int> eventIds;
  final Map<String, int> sessionIds;

  const _LongitudinalSeed({
    required this.teamId,
    required this.athleteIds,
    required this.eventIds,
    required this.sessionIds,
  });
}

class _LargeHeatmapSeed {
  final int teamId;
  final int lastEventId;

  const _LargeHeatmapSeed({required this.teamId, required this.lastEventId});
}
