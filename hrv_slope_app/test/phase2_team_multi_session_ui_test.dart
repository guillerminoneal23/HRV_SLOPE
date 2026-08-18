import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrv_slope_app/data/database/app_database.dart';
import 'package:hrv_slope_app/data/services/multi_session_entry_validation_service.dart';
import 'package:hrv_slope_app/data/services/multi_session_save_service.dart';
import 'package:hrv_slope_app/shared/engine/slope_calculator.dart';
import 'package:hrv_slope_app/ui/screens/athletes/athletes_screen.dart';
import 'package:hrv_slope_app/ui/screens/session/multi_session_entry_screen.dart';
import 'package:hrv_slope_app/ui/screens/session/new_session_mode_screen.dart';
import 'package:hrv_slope_app/ui/screens/session/session_wizard_screen.dart';
import 'package:hrv_slope_app/ui/screens/teams/team_detail_screen.dart';
import 'package:hrv_slope_app/ui/screens/teams/teams_screen.dart';
import 'package:hrv_slope_app/ui/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Teams UI', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('creates, edits, archives and restores a team', (tester) async {
      await _pump(tester, TeamsScreen(database: db));

      await tester.tap(find.byKey(const Key('teams_new_team')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('team_form_name')),
        'Squad A',
      );
      await tester.enterText(
        find.byKey(const Key('team_form_sport')),
        'Soccer',
      );
      await tester.tap(find.byKey(const Key('team_form_save')));
      await tester.pumpAndSettle();

      var teams = await db.teamsDao.getAllTeams(includeArchived: true);
      expect(teams.single.name, 'Squad A');
      expect(find.text('Squad A'), findsOneWidget);

      final teamId = teams.single.id;
      await tester.tap(find.byKey(Key('team_menu_$teamId')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('team_form_name')),
        'Squad Alpha',
      );
      await tester.tap(find.byKey(const Key('team_form_save')));
      await tester.pumpAndSettle();

      expect((await db.teamsDao.getTeamById(teamId))!.name, 'Squad Alpha');

      await tester.tap(find.byKey(Key('team_menu_$teamId')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Archive').last);
      await tester.pumpAndSettle();

      expect((await db.teamsDao.getTeamById(teamId))!.isArchived, isTrue);
      expect(await db.teamsDao.getActiveTeams(), isEmpty);

      await tester.tap(find.byKey(const Key('teams_toggle_archived')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('team_menu_$teamId')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Restore').last);
      await tester.pumpAndSettle();

      teams = await db.teamsDao.getActiveTeams();
      expect(teams.single.id, teamId);
      expect(teams.single.isArchived, isFalse);
    });

    testWidgets('assigns, removes, moves and blocks archived team assignment', (
      tester,
    ) async {
      final teamA = await db.teamsDao.createTeam(name: 'Team A');
      final teamB = await db.teamsDao.createTeam(name: 'Team B');
      final athleteA = await _insertAthlete(db, name: 'Alex Runner');
      final athleteB = await _insertAthlete(db, name: 'Alex Runner');

      await db.teamsDao.assignAthleteToTeam(athleteId: athleteA, teamId: teamB);

      await _pump(tester, TeamDetailScreen(database: db, teamId: teamA));
      await tester.tap(find.byKey(const Key('team_detail_add_players')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('team_assign_player_$athleteA')));
      await tester.pumpAndSettle();

      expect(
        (await db.teamsDao.getAssignmentForAthlete(athleteA))!.teamId,
        teamA,
      );

      await tester.tap(find.byKey(const Key('team_detail_add_players')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('team_assign_player_$athleteB')));
      await tester.pumpAndSettle();

      expect(await db.teamsDao.getAthletesForTeam(teamA), hasLength(2));

      await tester.tap(find.byKey(Key('team_remove_player_$athleteB')));
      await tester.pumpAndSettle();

      expect(await db.teamsDao.getAssignmentForAthlete(athleteB), isNull);

      await tester.tap(find.byKey(const Key('team_detail_archive_restore')));
      await tester.pumpAndSettle();
      final addButton = tester.widget<FilledButton>(
        find.byKey(const Key('team_detail_add_players')),
      );
      expect(addButton.onPressed, isNull);
      expect(
        () =>
            db.teamsDao.assignAthleteToTeam(athleteId: athleteB, teamId: teamA),
        throwsA(isA<StateError>()),
      );
    });

    testWidgets('athletes screen identifies current team and no-team filter', (
      tester,
    ) async {
      final teamId = await db.teamsDao.createTeam(name: 'Roster One');
      final assigned = await _insertAthlete(db, name: 'Assigned Player');
      await _insertAthlete(db, name: 'Free Player');
      await db.teamsDao.assignAthleteToTeam(
        athleteId: assigned,
        teamId: teamId,
      );

      await _pump(tester, AthletesScreen(database: db));
      expect(find.text('Roster One'), findsOneWidget);
      expect(find.text('Assigned Player'), findsOneWidget);
      expect(find.text('Free Player'), findsOneWidget);

      await tester.tap(find.byKey(const Key('athletes_team_filter')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('No team').last);
      await tester.pumpAndSettle();

      expect(find.text('Free Player'), findsOneWidget);
      expect(find.text('Assigned Player'), findsNothing);
    });
  });

  group('New session selector', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('opens individual wizard and multi-session entry', (
      tester,
    ) async {
      await _pump(tester, NewSessionModeScreen(database: db));

      await tester.tap(find.byKey(const Key('new_session_individual')));
      await tester.pumpAndSettle();
      expect(find.byType(SessionWizardScreen), findsOneWidget);

      Navigator.of(tester.element(find.byType(SessionWizardScreen))).pop();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('new_session_multiple')));
      await tester.pumpAndSettle();
      expect(find.byType(MultiSessionEntryScreen), findsOneWidget);
      expect(find.text('Multiple / Team Entry'), findsOneWidget);
    });
  });

  group('Multi-session validation', () {
    test('distinguishes 4 ms measured from missing exercise fallback', () {
      final athleteA = _athlete(id: 1, name: 'Duplicate Name');
      final athleteB = _athlete(id: 2, name: 'Duplicate Name');

      final evaluation = const MultiSessionEntryValidationService().evaluate(
        header: _validHeader(),
        rows: [
          MultiSessionDraftRow(
            localId: 1,
            athlete: athleteA,
            rmssdExerciseText: '',
            rmssdRecoveryText: '20',
            loadText: '80',
          ),
          MultiSessionDraftRow(
            localId: 2,
            athlete: athleteB,
            rmssdExerciseText: '4',
            rmssdRecoveryText: '22',
            loadText: '82',
          ),
        ],
      );

      expect(evaluation.validCount, 2);
      expect(evaluation.rows[0].usesExerciseFallback, isTrue);
      expect(evaluation.rows[0].preview!.rmssdExercise, 4);
      expect(evaluation.rows[0].preview!.usedFallbackExercise, isTrue);
      expect(evaluation.rows[1].usesExerciseFallback, isFalse);
      expect(evaluation.rows[1].preview!.rmssdExercise, 4);
      expect(evaluation.rows[1].preview!.usedFallbackExercise, isFalse);
      expect(evaluation.rows.map((row) => row.toSaveInput().athleteId), [1, 2]);
    });

    test('validates duplicate athleteId, recovery, load and unit errors', () {
      final athlete = _athlete(id: 1, name: 'Player One');

      final duplicates = const MultiSessionEntryValidationService().evaluate(
        header: _validHeader(),
        rows: [
          MultiSessionDraftRow(
            localId: 1,
            athlete: athlete,
            rmssdExerciseText: '',
            rmssdRecoveryText: '20',
            loadText: '80',
          ),
          MultiSessionDraftRow(
            localId: 2,
            athlete: athlete,
            rmssdExerciseText: '',
            rmssdRecoveryText: '',
            loadText: 'NaN',
          ),
        ],
      );

      expect(duplicates.errorCount, 2);
      expect(
        duplicates.rows[0].fieldErrors[MultiSessionField.athlete],
        'Duplicate athlete',
      );
      expect(
        duplicates.rows[1].fieldErrors[MultiSessionField.rmssdRecovery],
        'Required',
      );
      expect(
        duplicates.rows[1].fieldErrors[MultiSessionField.load],
        'Must be finite',
      );

      final wrongUnit = const MultiSessionEntryValidationService().evaluate(
        header: _validHeader(loadUnit: 'AU'),
        rows: [
          MultiSessionDraftRow(
            localId: 1,
            athlete: athlete,
            rmssdExerciseText: '',
            rmssdRecoveryText: '20',
            loadText: '80',
          ),
        ],
      );
      expect(wrongUnit.headerErrors, contains('Load unit must be %.'));
      expect(
        wrongUnit.rows.single.fieldErrors[MultiSessionField.unit],
        'Unit must be %',
      );
    });

    test('row slope comes from the shared recovery window engine', () {
      final evaluation = const MultiSessionEntryValidationService().evaluate(
        header: _validHeader(),
        rows: [
          MultiSessionDraftRow(
            localId: 1,
            athlete: _athlete(id: 1, name: 'Player One'),
            rmssdExerciseText: '',
            rmssdRecoveryText: '24',
            loadText: '80',
          ),
        ],
      );

      final preview = evaluation.rows.single.preview!;
      final slope = computeSlopeForRecoveryWindow(
        rmssdRecovery: 24,
        rmssdExercise: null,
        recoveryWindow: const RecoveryWindow(startMin: 5, endMin: 10),
      );

      expect(preview.rawSlope, closeTo(slope.rawSlope, 0.000001));
      expect(
        preview.interpretedSlope,
        closeTo(slope.interpretedSlope, 0.000001),
      );
    });
  });

  group('Multi-session entry UI and persistence', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets(
      'loads team players, saves N individual sessions and fallback',
      (tester) async {
        final teamId = await db.teamsDao.createTeam(
          name: 'Squad Multi',
          sport: 'Soccer',
        );
        final athleteIds = [
          await _insertAthlete(db, name: 'Athlete A'),
          await _insertAthlete(db, name: 'Athlete B'),
          await _insertAthlete(db, name: 'Athlete C'),
        ];
        for (final athleteId in athleteIds) {
          await db.teamsDao.assignAthleteToTeam(
            athleteId: athleteId,
            teamId: teamId,
          );
        }

        await _pump(tester, MultiSessionEntryScreen(database: db));
        await tester.enterText(find.byKey(const Key('multi_task')), 'RSA');
        await tester.tap(find.byKey(const Key('multi_team_dropdown')));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(find.text('Squad Multi').last);
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.textContaining('3 players added'), findsOneWidget);
        expect(find.text('Athlete A'), findsOneWidget);

        await _enterRow(tester, rowId: 1, recovery: '20', load: '80');
        await _enterRow(
          tester,
          rowId: 2,
          exercise: '4',
          recovery: '22',
          load: '82',
        );
        await _enterRow(
          tester,
          rowId: 3,
          exercise: '5',
          recovery: '18',
          load: '78',
        );
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('4.0 default'), findsOneWidget);
        expect(find.textContaining('3 valid'), findsWidgets);

        await tester.tap(find.byKey(const Key('multi_save_button')));
        await _pumpUntilFound(tester, find.text('Group session saved'));

        expect(find.text('Group session saved'), findsOneWidget);
        expect(find.text('Players saved: 3'), findsOneWidget);

        final events = await db.sessionEventsDao.getEventsForTeam(teamId);
        expect(events, hasLength(1));
        final sessions = await db.sessionEventsDao.getSessionsForEvent(
          events.single.id,
        );
        expect(sessions, hasLength(3));
        expect(sessions.map((session) => session.eventId).toSet(), {
          events.single.id,
        });
        expect(sessions.map((session) => session.athleteId).toSet(), {
          ...athleteIds,
        });

        final fallbackSession = sessions.singleWhere(
          (session) => session.athleteId == athleteIds[0],
        );
        expect(fallbackSession.rmssdExercise, 4);
        expect(fallbackSession.rmssdExerciseIsDefault, isTrue);
        expect(fallbackSession.rmssdExerciseSource, 'fallback_4_ms');

        final measuredFourSession = sessions.singleWhere(
          (session) => session.athleteId == athleteIds[1],
        );
        expect(measuredFourSession.rmssdExercise, 4);
        expect(measuredFourSession.rmssdExerciseIsDefault, isFalse);
        expect(measuredFourSession.rmssdExerciseSource, 'measured');

        final variables = await db.sessionsDao.getVariablesForSession(
          measuredFourSession.id,
        );
        final loadVariable = variables.singleWhere(
          (variable) => variable.name == 'percent_mas',
        );
        expect(loadVariable.unit, '%');
        expect(loadVariable.value, 82);
      },
    );

    testWidgets('removing a row does not remove the athlete from the team', (
      tester,
    ) async {
      final teamId = await db.teamsDao.createTeam(name: 'Squad Remove');
      final athleteId = await _insertAthlete(db, name: 'Row Player');
      await db.teamsDao.assignAthleteToTeam(
        athleteId: athleteId,
        teamId: teamId,
      );

      await _pump(tester, MultiSessionEntryScreen(database: db));
      await tester.tap(find.byKey(const Key('multi_team_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Squad Remove').last);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('multi_row_1_remove')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('multi_row_1_remove')));
      await tester.pumpAndSettle();

      expect(find.text('Row Player'), findsNothing);
      expect(
        (await db.teamsDao.getAssignmentForAthlete(athleteId))!.teamId,
        teamId,
      );
    });

    testWidgets('archived teams are not available for multi-session entry', (
      tester,
    ) async {
      await db.teamsDao.createTeam(name: 'Active Team');
      final archivedId = await db.teamsDao.createTeam(name: 'Archived Team');
      await db.teamsDao.archiveTeam(archivedId);

      await _pump(tester, MultiSessionEntryScreen(database: db));
      await tester.tap(find.byKey(const Key('multi_team_dropdown')));
      await tester.pumpAndSettle();

      expect(find.text('Active Team'), findsOneWidget);
      expect(find.text('Archived Team'), findsNothing);
    });

    test('service validation prevents partial rows from being saved', () async {
      final athleteId = await _insertAthlete(db, name: 'Atomic UI');
      final preview = const MultiSessionEntryValidationService()
          .evaluate(
            header: _validHeader(),
            rows: [
              MultiSessionDraftRow(
                localId: 1,
                athlete: _athlete(id: athleteId, name: 'Atomic UI'),
                rmssdExerciseText: '',
                rmssdRecoveryText: '20',
                loadText: '80',
              ),
            ],
          )
          .rows
          .single
          .preview!;

      expect(
        () => MultiSessionSaveService(db).saveEventWithSessions(
          event: _validHeader(loadUnit: 'AU').toSaveInput(),
          rows: [MultiSessionRowInput(athleteId: athleteId, preview: preview)],
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(await db.sessionEventsDao.getEventsInDateRange(), isEmpty);
      expect(await db.sessionsDao.getAllSessions(), isEmpty);
      expect(await db.select(db.measurementsHrv).get(), isEmpty);
      expect(await db.select(db.intensityVariables).get(), isEmpty);
    });
  });
}

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(theme: buildAppTheme(), home: child));
  await tester.pumpAndSettle();
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) return;
  }
  expect(finder, findsOneWidget);
}

Future<void> _enterRow(
  WidgetTester tester, {
  required int rowId,
  String? exercise,
  required String recovery,
  required String load,
}) async {
  if (exercise != null) {
    await tester.enterText(
      find.byKey(Key('multi_row_${rowId}_exercise')),
      exercise,
    );
  }
  await tester.enterText(
    find.byKey(Key('multi_row_${rowId}_recovery')),
    recovery,
  );
  await tester.enterText(find.byKey(Key('multi_row_${rowId}_load')), load);
}

Future<int> _insertAthlete(
  AppDatabase db, {
  required String name,
  String sport = 'Soccer',
}) {
  final now = DateTime.now().toIso8601String();
  return db.athletesDao.insertAthlete(
    AthletesCompanion.insert(
      name: name,
      sport: drift.Value(sport),
      masKmh: const drift.Value(20),
      createdAt: now,
      updatedAt: now,
    ),
  );
}

Athlete _athlete({required int id, required String name}) {
  const now = '2026-08-18T00:00:00';
  return Athlete(
    id: id,
    name: name,
    sport: 'Soccer',
    masKmh: 20,
    isArchived: false,
    createdAt: now,
    updatedAt: now,
  );
}

MultiSessionEntryHeader _validHeader({String loadUnit = '%'}) {
  return MultiSessionEntryHeader(
    date: '2026-08-18T10:00:00',
    taskName: 'RSA',
    sport: 'Soccer',
    sessionType: 'training',
    protocolName: '5-10',
    contextEnvironment: 'Indoor',
    recoveryWindowStartMin: 5,
    recoveryWindowEndMin: 10,
    loadType: 'external',
    loadMetricName: 'percent_mas',
    loadUnit: loadUnit,
  );
}
