import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrv_slope_app/data/database/app_database.dart';
import 'package:hrv_slope_app/ui/screens/reports/group_report_screen.dart';
import 'package:hrv_slope_app/ui/screens/reports/reports_screen.dart';
import 'package:hrv_slope_app/ui/screens/reports/team_reports_hub_screen.dart';
import 'package:hrv_slope_app/ui/screens/reports/team_session_events_screen.dart';
import 'package:hrv_slope_app/ui/screens/teams/session_event_detail_screen.dart';
import 'package:hrv_slope_app/ui/screens/teams/team_longitudinal_heatmap_screen.dart';
import 'package:hrv_slope_app/ui/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Reports navigation', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('exposes Team Reports and keeps Group Report available', (
      tester,
    ) async {
      await _pump(tester, ReportsScreen(database: db));

      expect(find.text('Team Reports'), findsOneWidget);
      expect(find.text('Group Report'), findsOneWidget);
      expect(find.text('Study Nomogram'), findsOneWidget);
      expect(
        find.textContaining('individually selected or filtered sessions'),
        findsOneWidget,
      );

      await tester.tap(find.text('Team Reports'));
      await tester.pumpAndSettle();
      expect(find.byType(TeamReportsHubScreen), findsOneWidget);

      Navigator.of(tester.element(find.byType(TeamReportsHubScreen))).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Group Report'));
      await tester.pumpAndSettle();
      expect(find.byType(GroupReportScreen), findsOneWidget);
    });
  });

  group('Team Reports hub', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('shows empty state when no teams exist', (tester) async {
      await _pump(tester, TeamReportsHubScreen(database: db));

      expect(find.byKey(const Key('team_reports_empty_state')), findsOneWidget);
      expect(find.text('No teams available.'), findsOneWidget);
      expect(
        find.text('Create a team first to use Team Reports.'),
        findsOneWidget,
      );
    });

    testWidgets('selects active and archived teams', (tester) async {
      await db.teamsDao.createTeam(name: 'Active Squad', sport: 'Soccer');
      final archivedId = await db.teamsDao.createTeam(
        name: 'Archived Squad',
        sport: 'Soccer',
      );
      await db.teamsDao.archiveTeam(archivedId);

      await _pump(tester, TeamReportsHubScreen(database: db));

      expect(
        find.byKey(const Key('team_reports_team_selector')),
        findsOneWidget,
      );
      expect(find.text('Active Squad'), findsOneWidget);

      await tester.tap(find.byKey(const Key('team_reports_team_selector')));
      await tester.pumpAndSettle();
      expect(find.text('Archived Squad'), findsWidgets);
      await tester.tap(find.text('Archived Squad').last);
      await tester.pumpAndSettle();

      expect(find.text('Archived Squad'), findsOneWidget);
      expect(find.text('Archived'), findsOneWidget);
      expect(
        find.text('Archived teams remain available for historical reports.'),
        findsOneWidget,
      );
    });

    testWidgets('opens Team Longitudinal using the existing heatmap screen', (
      tester,
    ) async {
      final seed = await _seedTeamWithEvents(db);

      await _pump(tester, TeamReportsHubScreen(database: db));

      expect(find.text('Team Longitudinal'), findsOneWidget);
      await tester.tap(find.text('Team Longitudinal'));
      await tester.pumpAndSettle();

      expect(find.byType(TeamLongitudinalHeatmapScreen), findsOneWidget);
      expect(find.text(seed.teamName), findsWidgets);
    });
  });

  group('Team Sessions report list', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets(
      'lists events newest first with participant counts and empty events',
      (tester) async {
        final seed = await _seedTeamWithEvents(db, archivedTeam: true);

        await _pump(
          tester,
          TeamSessionEventsScreen(database: db, teamId: seed.teamId),
        );

        expect(find.byKey(const Key('team_sessions_header')), findsOneWidget);
        expect(find.text(seed.teamName), findsOneWidget);
        expect(find.text('Archived'), findsOneWidget);
        expect(find.text('3 session events'), findsOneWidget);
        expect(find.text('0 participants'), findsOneWidget);
        expect(find.text('1 participant'), findsOneWidget);
        expect(find.text('2 participants'), findsOneWidget);

        final newestY = tester.getTopLeft(find.text('Recent Empty')).dy;
        final middleY = tester.getTopLeft(find.text('Middle Load')).dy;
        final oldestY = tester.getTopLeft(find.text('Old Load')).dy;
        expect(newestY, lessThan(middleY));
        expect(middleY, lessThan(oldestY));

        await tester.tap(
          find.byKey(Key('team_session_open_${seed.emptyEventId}')),
        );
        await tester.pumpAndSettle();
        expect(find.byType(SessionEventDetailScreen), findsOneWidget);
        expect(find.text('Recent Empty'), findsWidgets);
      },
    );

    testWidgets('shows empty state for a team without SessionEvents', (
      tester,
    ) async {
      final teamId = await db.teamsDao.createTeam(name: 'Quiet Team');

      await _pump(
        tester,
        TeamSessionEventsScreen(database: db, teamId: teamId),
      );

      expect(
        find.byKey(const Key('team_sessions_empty_state')),
        findsOneWidget,
      );
      expect(find.text('No team sessions recorded yet.'), findsOneWidget);
    });

    testWidgets('uses singular copy for one event and one participant', (
      tester,
    ) async {
      final teamId = await db.teamsDao.createTeam(name: 'Single Team');
      final athleteId = await _insertAthlete(db, 'Solo');
      final eventId = await _insertEvent(
        db,
        teamId: teamId,
        date: '2026-07-01T10:00:00',
        taskName: 'Only Load',
        protocolName: '5-10',
        context: 'Field',
        loadType: 'external',
        loadMetricName: 'player_load',
        loadUnit: 'AU',
      );
      await _insertSession(
        db,
        athleteId: athleteId,
        eventId: eventId,
        date: '2026-07-01T10:00:00',
        taskName: 'Only Load',
        loadType: 'external',
        loadMetricName: 'player_load',
        loadUnit: 'AU',
        loadValue: 100,
      );

      await _pump(
        tester,
        TeamSessionEventsScreen(database: db, teamId: teamId),
      );

      expect(find.text('1 session event'), findsOneWidget);
      expect(find.text('1 participant'), findsOneWidget);
    });

    testWidgets('uses plural copy for two events and two participants', (
      tester,
    ) async {
      final teamId = await db.teamsDao.createTeam(name: 'Plural Team');
      final athleteA = await _insertAthlete(db, 'Alpha');
      final athleteB = await _insertAthlete(db, 'Bravo');
      final eventA = await _insertEvent(
        db,
        teamId: teamId,
        date: '2026-07-01T10:00:00',
        taskName: 'First Load',
        protocolName: '5-10',
        context: 'Field',
        loadType: 'external',
        loadMetricName: 'player_load',
        loadUnit: 'AU',
      );
      await _insertEvent(
        db,
        teamId: teamId,
        date: '2026-07-02T10:00:00',
        taskName: 'Second Load',
        protocolName: '5-10',
        context: 'Field',
        loadType: 'external',
        loadMetricName: 'player_load',
        loadUnit: 'AU',
      );
      await _insertSession(
        db,
        athleteId: athleteA,
        eventId: eventA,
        date: '2026-07-01T10:00:00',
        taskName: 'First Load',
        loadType: 'external',
        loadMetricName: 'player_load',
        loadUnit: 'AU',
        loadValue: 100,
      );
      await _insertSession(
        db,
        athleteId: athleteB,
        eventId: eventA,
        date: '2026-07-01T10:00:00',
        taskName: 'First Load',
        loadType: 'external',
        loadMetricName: 'player_load',
        loadUnit: 'AU',
        loadValue: 120,
      );

      await _pump(
        tester,
        TeamSessionEventsScreen(database: db, teamId: teamId),
      );

      expect(find.text('2 session events'), findsOneWidget);
      expect(find.text('2 participants'), findsOneWidget);
    });

    testWidgets(
      'Team Reports opens Team Sessions and then SessionEvent detail',
      (tester) async {
        final seed = await _seedTeamWithEvents(db);

        await _pump(tester, TeamReportsHubScreen(database: db));

        await tester.tap(find.text('Team Sessions'));
        await tester.pumpAndSettle();
        expect(find.byType(TeamSessionEventsScreen), findsOneWidget);

        await tester.tap(
          find.byKey(Key('team_session_open_${seed.middleEventId}')),
        );
        await tester.pumpAndSettle();
        expect(find.byType(SessionEventDetailScreen), findsOneWidget);
        expect(find.text('Middle Load'), findsWidgets);
      },
    );

    test(
      'participant counts distinct athletes and preserves empty events',
      () async {
        final seed = await _seedTeamWithEvents(db);
        await _insertSession(
          db,
          athleteId: seed.athleteBId,
          eventId: seed.oldestEventId,
          date: '2026-06-01T10:00:00',
          taskName: 'Old Load',
          loadType: 'external',
          loadMetricName: 'percent_mas',
          loadUnit: '%',
          loadValue: 99,
        );

        final items = await db.sessionEventsDao.getEventsForTeamWithCounts(
          seed.teamId,
        );
        final countsByEvent = {
          for (final item in items) item.event.id: item.participantCount,
        };

        expect(countsByEvent[seed.oldestEventId], 2);
        expect(countsByEvent[seed.emptyEventId], 0);
      },
    );

    test(
      'participant counts are loaded without full session detail queries',
      () {
        final source = File(
          'lib/data/database/daos/session_events_dao.dart',
        ).readAsStringSync();
        final methodStart = source.indexOf('getEventsForTeamWithCounts');
        final methodEnd = source.indexOf(
          'Future<TeamLongitudinalBundle>',
          methodStart,
        );
        final methodBody = source.substring(methodStart, methodEnd);

        expect(methodBody, isNot(contains('getSessionDetail(')));
        expect(methodBody, isNot(contains('getAllSessionDetails')));
        expect(methodBody, contains('s.eventId.isIn(eventIds)'));
      },
    );
  });
}

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(theme: buildAppTheme(), home: child));
  await tester.pumpAndSettle();
}

Future<_TeamReportsSeed> _seedTeamWithEvents(
  AppDatabase db, {
  bool archivedTeam = false,
}) async {
  const teamName = 'Reports FC';
  final teamId = await db.teamsDao.createTeam(name: teamName, sport: 'Soccer');
  final athleteA = await _insertAthlete(db, 'Alpha');
  final athleteB = await _insertAthlete(db, 'Bravo');
  await db.teamsDao.assignAthleteToTeam(athleteId: athleteA, teamId: teamId);
  await db.teamsDao.assignAthleteToTeam(athleteId: athleteB, teamId: teamId);

  final oldestEventId = await _insertEvent(
    db,
    teamId: teamId,
    date: '2026-06-01T10:00:00',
    taskName: 'Old Load',
    protocolName: '5-10',
    context: 'Field',
    loadType: 'external',
    loadMetricName: 'percent_mas',
    loadUnit: '%',
  );
  final middleEventId = await _insertEvent(
    db,
    teamId: teamId,
    date: '2026-06-02T10:00:00',
    taskName: 'Middle Load',
    protocolName: '5-10',
    context: 'Indoor',
    loadType: 'internal',
    loadMetricName: 'rpe',
    loadUnit: '1-10',
  );
  final emptyEventId = await _insertEvent(
    db,
    teamId: teamId,
    date: '2026-06-03T10:00:00',
    taskName: 'Recent Empty',
    protocolName: '5-10',
    context: 'Indoor',
    loadType: 'external',
    loadMetricName: 'player_load',
    loadUnit: 'AU',
  );

  await _insertSession(
    db,
    athleteId: athleteA,
    eventId: oldestEventId,
    date: '2026-06-01T10:00:00',
    taskName: 'Old Load',
    loadType: 'external',
    loadMetricName: 'percent_mas',
    loadUnit: '%',
    loadValue: 80,
  );
  await _insertSession(
    db,
    athleteId: athleteB,
    eventId: oldestEventId,
    date: '2026-06-01T10:00:00',
    taskName: 'Old Load',
    loadType: 'external',
    loadMetricName: 'percent_mas',
    loadUnit: '%',
    loadValue: 82,
  );
  await _insertSession(
    db,
    athleteId: athleteA,
    eventId: middleEventId,
    date: '2026-06-02T10:00:00',
    taskName: 'Middle Load',
    loadType: 'internal',
    loadMetricName: 'rpe',
    loadUnit: '1-10',
    loadValue: 6,
  );

  if (archivedTeam) {
    await db.teamsDao.archiveTeam(teamId);
  }

  return _TeamReportsSeed(
    teamId: teamId,
    teamName: teamName,
    athleteAId: athleteA,
    athleteBId: athleteB,
    oldestEventId: oldestEventId,
    middleEventId: middleEventId,
    emptyEventId: emptyEventId,
  );
}

Future<int> _insertAthlete(AppDatabase db, String name) {
  final now = DateTime.now().toIso8601String();
  return db.athletesDao.insertAthlete(
    AthletesCompanion.insert(
      name: name,
      sport: const drift.Value('Soccer'),
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
  required String protocolName,
  required String context,
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
      protocolName: drift.Value(protocolName),
      contextEnvironment: drift.Value(context),
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
      rmssdExercise: const drift.Value(5),
      rmssdExerciseIsDefault: const drift.Value(false),
      rmssdRecovery: const drift.Value(20),
      slopeRaw: const drift.Value(0.25),
      slopeInterpreted: const drift.Value(0.25),
      itlIndex: const drift.Value(0.4),
      classification: const drift.Value('expected_response'),
      hrvInputMode: const drift.Value('direct_rmssd'),
      rmssdRecoverySource: const drift.Value('manual'),
      rmssdExerciseSource: const drift.Value('measured'),
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

class _TeamReportsSeed {
  final int teamId;
  final String teamName;
  final int athleteAId;
  final int athleteBId;
  final int oldestEventId;
  final int middleEventId;
  final int emptyEventId;

  const _TeamReportsSeed({
    required this.teamId,
    required this.teamName,
    required this.athleteAId,
    required this.athleteBId,
    required this.oldestEventId,
    required this.middleEventId,
    required this.emptyEventId,
  });
}
