import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrv_slope_app/data/database/app_database.dart';
import 'package:hrv_slope_app/shared/engine/team_event_report_builder.dart';
import 'package:hrv_slope_app/ui/screens/session/session_detail_screen.dart';
import 'package:hrv_slope_app/ui/screens/teams/session_event_detail_screen.dart';
import 'package:hrv_slope_app/ui/screens/teams/team_detail_screen.dart';
import 'package:hrv_slope_app/ui/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SessionEvent batch query', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('loads one athlete with event, team and related rows', () async {
      final seed = await _seedEvent(db, count: 1, includeNotes: true);

      final bundle = await db.sessionEventsDao.getEventDetailBundle(
        seed.eventId,
      );

      expect(bundle, isNotNull);
      expect(bundle!.event.id, seed.eventId);
      expect(bundle.team!.id, seed.teamId);
      expect(bundle.sessionDetails, hasLength(1));
      expect(bundle.sessionDetails.single.athlete.id, seed.athleteIds.single);
      expect(bundle.sessionDetails.single.variables, isNotEmpty);
      expect(bundle.sessionDetails.single.hrvMeasurements, isNotEmpty);
      expect(bundle.sessionDetails.single.notes, isNotEmpty);
    });

    test(
      'loads multiple athletes, archived athlete and no-team event',
      () async {
        final seed = await _seedEvent(
          db,
          count: 3,
          noTeam: true,
          archivedAthleteIndex: 1,
        );

        final bundle = await db.sessionEventsDao.getEventDetailBundle(
          seed.eventId,
        );

        expect(bundle, isNotNull);
        expect(bundle!.team, isNull);
        expect(bundle.participantCount, 3);
        expect(bundle.sessionDetails[1].athlete.isArchived, isTrue);
        expect(
          bundle.sessionDetails.map((detail) => detail.session.eventId).toSet(),
          {seed.eventId},
        );
      },
    );

    test('getSessionDetailsForEvent delegates to batch aggregate', () async {
      final source = File(
        'lib/data/database/daos/session_events_dao.dart',
      ).readAsStringSync();
      final methodStart = source.indexOf('getSessionDetailsForEvent');
      final methodBody = source.substring(methodStart);

      expect(methodBody, contains('getEventDetailBundle(eventId)'));
      expect(methodBody, isNot(contains('getSessionDetail(')));
    });
  });

  group('Team event report builder', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'calculates median, IQR, counts and fallback from persisted results',
      () async {
        final seed = await _seedEvent(
          db,
          count: 4,
          fallbackIndexes: {0},
          incompleteIndexes: {3},
          slopes: [0.1, 0.3, 0.7, null],
          loads: [80, 90, 100, 110],
          classifications: [
            'very_high_internal_load',
            'expected_response',
            'low_internal_load_or_fast_recovery',
            null,
          ],
        );
        final bundle = await db.sessionEventsDao.getEventDetailBundle(
          seed.eventId,
        );

        final report = buildTeamEventReport(bundle!);

        expect(report.summary.participantCount, 4);
        expect(report.summary.validParticipantCount, 3);
        expect(report.summary.medianSlope, closeTo(0.3, 0.000001));
        expect(report.summary.iqrSlope, closeTo(0.3, 0.000001));
        expect(report.summary.fallbackExerciseCount, 1);
        expect(report.summary.incompleteCount, 1);
        expect(report.summary.medianLoad, 95);
        expect(report.classificationCounts.map((item) => item.count), [
          1,
          1,
          1,
        ]);
        expect(report.rows.first.isIncomplete, isTrue);
      },
    );

    test('handles N=1 with zero IQR', () async {
      final seed = await _seedEvent(db, count: 1, slopes: [0.42]);
      final bundle = await db.sessionEventsDao.getEventDetailBundle(
        seed.eventId,
      );

      final report = buildTeamEventReport(bundle!);

      expect(report.summary.validParticipantCount, 1);
      expect(report.summary.medianSlope, closeTo(0.42, 0.000001));
      expect(report.summary.iqrSlope, 0);
    });

    test(
      'excludes incompatible load unit from median while keeping row visible',
      () async {
        final seed = await _seedEvent(
          db,
          count: 4,
          loads: [10, 20, 30, 100000],
          loadUnits: ['%', '%', '%', 'AU'],
          athleteNames: [
            'Compatible A',
            'Compatible B',
            'Compatible C',
            'Mismatch Load',
          ],
        );
        final bundle = await db.sessionEventsDao.getEventDetailBundle(
          seed.eventId,
        );

        final report = buildTeamEventReport(bundle!);
        final mismatchRow = report.rows.singleWhere(
          (row) => row.athleteName == 'Mismatch Load',
        );

        expect(report.summary.medianLoad, 20);
        expect(mismatchRow.loadValue, 100000);
        expect(mismatchRow.loadUnit, 'AU');
        expect(mismatchRow.loadUnitMismatch, isTrue);
        expect(mismatchRow.statusLabels, contains('Unit mismatch'));
      },
    );
  });

  group('SessionEventDetailScreen UI', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets(
      'renders header, summary, table, fallback and incomplete state',
      (tester) async {
        final seed = await _seedEvent(
          db,
          count: 3,
          fallbackIndexes: {0},
          incompleteIndexes: {2},
          archivedTeam: true,
        );

        await _pump(
          tester,
          SessionEventDetailScreen(database: db, eventId: seed.eventId),
        );

        expect(find.byKey(const Key('session_event_header')), findsOneWidget);
        expect(find.text('Phase 3A Team'), findsOneWidget);
        expect(find.text('Archived team'), findsOneWidget);
        expect(find.text('Valid participants'), findsOneWidget);
        expect(find.text('2/3'), findsOneWidget);
        expect(find.byKey(const Key('session_event_table')), findsOneWidget);
        expect(find.text('default'), findsOneWidget);
        expect(find.text('Incomplete'), findsWidgets);
        expect(find.textContaining('Color = interpretation'), findsOneWidget);
      },
    );

    testWidgets('filters by search, fallback, incomplete and classification', (
      tester,
    ) async {
      final seed = await _seedEvent(
        db,
        count: 3,
        fallbackIndexes: {0},
        incompleteIndexes: {2},
        athleteNames: ['Alpha', 'Bravo', 'Charlie'],
        classifications: ['very_high_internal_load', 'expected_response', null],
      );

      await _pump(
        tester,
        SessionEventDetailScreen(database: db, eventId: seed.eventId),
      );

      await tester.enterText(
        find.byKey(const Key('session_event_search')),
        'Bravo',
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(Key('session_event_row_${seed.sessionIds[1]}')),
        findsOneWidget,
      );
      expect(find.text('Alpha'), findsNothing);

      await tester.enterText(find.byKey(const Key('session_event_search')), '');
      await tester.tap(find.byKey(const Key('session_event_filter_fallback')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fallback only').last);
      await tester.pumpAndSettle();
      expect(
        find.byKey(Key('session_event_row_${seed.sessionIds[0]}')),
        findsOneWidget,
      );
      expect(find.text('Bravo'), findsNothing);

      await tester.tap(find.byKey(const Key('session_event_filter_fallback')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('All').last);
      await tester.pumpAndSettle();
      final incompleteFilter = find.byKey(
        const Key('session_event_filter_incomplete'),
      );
      await tester.ensureVisible(incompleteFilter);
      await tester.pumpAndSettle();
      await tester.tap(incompleteFilter);
      await tester.pumpAndSettle();
      expect(
        find.byKey(Key('session_event_row_${seed.sessionIds[2]}')),
        findsOneWidget,
      );
      expect(find.text('Alpha'), findsNothing);

      await tester.ensureVisible(incompleteFilter);
      await tester.pumpAndSettle();
      await tester.tap(incompleteFilter);
      await tester.pumpAndSettle();
      final classificationFilter = find.byKey(
        const Key('session_event_filter_classification'),
      );
      await tester.ensureVisible(classificationFilter);
      await tester.pumpAndSettle();
      await tester.tap(classificationFilter);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Expected').last);
      await tester.pumpAndSettle();
      expect(
        find.byKey(Key('session_event_row_${seed.sessionIds[1]}')),
        findsOneWidget,
      );
      expect(find.text('Alpha'), findsNothing);
    });

    testWidgets('sorts by load and opens individual session detail', (
      tester,
    ) async {
      final seed = await _seedEvent(
        db,
        count: 3,
        athleteNames: ['Load C', 'Load A', 'Load B'],
        loads: [300, 100, 200],
      );

      await _pump(
        tester,
        SessionEventDetailScreen(database: db, eventId: seed.eventId),
      );

      await tester.ensureVisible(find.byKey(const Key('session_event_sort')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('session_event_sort')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Load').last);
      await tester.pumpAndSettle();

      final firstName = tester.getTopLeft(find.text('Load A')).dy;
      final secondName = tester.getTopLeft(find.text('Load B')).dy;
      expect(firstName, lessThan(secondName));

      final action = find.byKey(
        Key('session_event_open_session_${seed.sessionIds[1]}'),
      );
      await tester.ensureVisible(action);
      await tester.pumpAndSettle();
      await tester.tap(action);
      await tester.pumpAndSettle();

      expect(find.byType(SessionDetailScreen), findsOneWidget);
      expect(find.text('Load A'), findsOneWidget);
    });

    testWidgets('renders a large event without hiding historical athletes', (
      tester,
    ) async {
      final names = [
        for (var i = 1; i <= 40; i++) 'Player ${i.toString().padLeft(2, '0')}',
      ];
      final seed = await _seedEvent(
        db,
        count: 40,
        athleteNames: names,
        archivedAthleteIndex: 39,
      );

      await _pump(
        tester,
        SessionEventDetailScreen(database: db, eventId: seed.eventId),
      );

      expect(find.text('Player 01'), findsOneWidget);
      expect(find.text('Player 40'), findsOneWidget);
      expect(find.text('Archived athlete'), findsOneWidget);
    });

    testWidgets('aggregates lower recovery-response classes visibly', (
      tester,
    ) async {
      final seed = await _seedEvent(
        db,
        count: 8,
        classifications: [
          'very_high_internal_load',
          'very_high_internal_load',
          'high_or_moderate_internal_load',
          'high_or_moderate_internal_load',
          'high_or_moderate_internal_load',
          'expected_response',
          'low_internal_load_or_fast_recovery',
          'low_internal_load_or_fast_recovery',
        ],
      );

      await _pump(
        tester,
        SessionEventDetailScreen(database: db, eventId: seed.eventId),
      );

      expect(find.text('Lower-than-expected: 5'), findsOneWidget);
      expect(find.text('Expected: 1'), findsOneWidget);
      expect(find.text('Favorable: 2'), findsOneWidget);
      expect(find.text('Lower-than-expected: 2'), findsNothing);
      expect(find.text('Lower-than-expected: 3'), findsNothing);
    });

    testWidgets('team detail opens a recent archived-team event', (
      tester,
    ) async {
      final seed = await _seedEvent(db, count: 2, archivedTeam: true);

      await _pump(tester, TeamDetailScreen(database: db, teamId: seed.teamId!));

      expect(find.byKey(const Key('team_recent_events')), findsOneWidget);
      expect(find.text('RSA'), findsOneWidget);

      await tester.tap(find.byKey(Key('team_open_event_${seed.eventId}')));
      await tester.pumpAndSettle();

      expect(find.byType(SessionEventDetailScreen), findsOneWidget);
      expect(find.text('Phase 3A Team'), findsOneWidget);
      expect(find.text('Archived team'), findsOneWidget);
    });

    testWidgets('team detail formats date-only events without midnight', (
      tester,
    ) async {
      final dateOnly = await _seedEvent(db, count: 1, eventDate: '2026-08-20');
      await _seedEvent(
        db,
        teamId: dateOnly.teamId,
        count: 1,
        eventDate: '2026-08-20T10:00:00',
      );

      await _pump(
        tester,
        TeamDetailScreen(database: db, teamId: dateOnly.teamId!),
      );

      expect(find.textContaining('2026-08-20 00:00'), findsNothing);
      expect(find.textContaining('2026-08-20 10:00'), findsOneWidget);
      expect(find.textContaining('2026-08-20'), findsWidgets);
    });
  });
}

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(theme: buildAppTheme(), home: child));
  await tester.pumpAndSettle();
}

Future<_SeedResult> _seedEvent(
  AppDatabase db, {
  int? teamId,
  bool noTeam = false,
  int count = 3,
  bool archivedTeam = false,
  int? archivedAthleteIndex,
  bool includeNotes = false,
  Set<int> fallbackIndexes = const {},
  Set<int> incompleteIndexes = const {},
  List<double?>? slopes,
  List<double>? loads,
  List<String?>? loadUnits,
  List<String?>? classifications,
  List<String>? athleteNames,
  String eventDate = '2026-08-18T10:00:00',
}) async {
  final now = DateTime.now().toIso8601String();
  final effectiveTeamId = noTeam
      ? null
      : teamId ??
            await db.teamsDao.createTeam(
              name: 'Phase 3A Team',
              sport: 'Soccer',
            );

  final eventId = await db.sessionEventsDao.createEvent(
    SessionEventsCompanion.insert(
      teamId: drift.Value(effectiveTeamId),
      date: eventDate,
      taskName: const drift.Value('RSA'),
      sport: const drift.Value('Soccer'),
      sessionType: const drift.Value('Training'),
      protocolName: const drift.Value('5-10'),
      contextEnvironment: const drift.Value('Indoor'),
      recoveryWindowStartMin: 5,
      recoveryWindowEndMin: 10,
      loadType: 'external',
      loadMetricName: 'percent_mas',
      loadUnit: const drift.Value('%'),
      createdAt: now,
      updatedAt: now,
    ),
  );

  final athleteIds = <int>[];
  final sessionIds = <int>[];
  for (var i = 0; i < count; i++) {
    final athleteId = await _insertAthlete(
      db,
      name: athleteNames?[i] ?? 'Athlete ${i + 1}',
      isArchived: archivedAthleteIndex == i,
    );
    athleteIds.add(athleteId);
    if (effectiveTeamId != null) {
      await db.teamsDao.assignAthleteToTeam(
        athleteId: athleteId,
        teamId: effectiveTeamId,
      );
    }

    final incomplete = incompleteIndexes.contains(i);
    final fallback = fallbackIndexes.contains(i);
    final slope = incomplete ? null : (slopes?[i] ?? 0.2 + i * 0.1);
    final classification = incomplete
        ? null
        : (classifications?[i] ?? 'expected_response');
    final rmssdRecovery = incomplete ? null : 20.0 + i;
    final load = loads?[i] ?? 80.0 + i;

    final sessionId = await db.sessionsDao.insertSession(
      SessionsCompanion.insert(
        athleteId: athleteId,
        eventId: drift.Value(eventId),
        date: eventDate,
        taskName: const drift.Value('RSA'),
        sport: const drift.Value('Soccer'),
        sessionType: const drift.Value('Training'),
        protocolName: const drift.Value('5-10'),
        contextEnvironment: const drift.Value('Indoor'),
        isDraft: const drift.Value(false),
        intensityPercent: const drift.Value(80),
        intensitySource: const drift.Value('External'),
        recoveryTimeMin: const drift.Value(10),
        recoveryWindowStartMin: const drift.Value(5),
        recoveryWindowEndMin: const drift.Value(10),
        rmssdExercise: drift.Value(fallback ? 4 : 5.0 + i),
        rmssdExerciseIsDefault: drift.Value(fallback),
        rmssdRecovery: drift.Value(rmssdRecovery),
        slopeRaw: drift.Value(slope),
        slopeInterpreted: drift.Value(slope),
        itlIndex: drift.Value(slope == null ? null : slope * 1.5),
        classification: drift.Value(classification),
        hrvInputMode: const drift.Value('direct_rmssd'),
        rmssdRecoverySource: const drift.Value('manual'),
        rmssdExerciseSource: drift.Value(
          fallback ? 'fallback_4_ms' : 'measured',
        ),
        rrQualityFlag: const drift.Value(null),
        rrQualityDecision: const drift.Value(null),
        createdAt: now,
      ),
    );
    sessionIds.add(sessionId);

    if (rmssdRecovery != null) {
      await db.sessionsDao.insertHrvMeasurement(
        MeasurementsHrvCompanion.insert(
          sessionId: sessionId,
          phase: 'recovery',
          windowStartMin: const drift.Value(5),
          windowEndMin: const drift.Value(10),
          rmssd: drift.Value(rmssdRecovery),
          createdAt: now,
        ),
      );
    }
    await db.sessionsDao.insertVariable(
      IntensityVariablesCompanion.insert(
        sessionId: sessionId,
        category: 'external',
        name: 'percent_mas',
        unit: drift.Value(loadUnits == null ? '%' : loadUnits[i]),
        value: load,
        source: const drift.Value('manual'),
        isPrimaryForNomogram: const drift.Value(true),
        createdAt: now,
      ),
    );
    if (includeNotes && i == 0) {
      await db
          .into(db.exclusionsOrNotes)
          .insert(
            ExclusionsOrNotesCompanion.insert(
              sessionId: drift.Value(sessionId),
              athleteId: drift.Value(athleteId),
              type: 'flag',
              reason: 'Coach flag',
              createdAt: now,
            ),
          );
    }
  }

  if (archivedTeam && effectiveTeamId != null) {
    await db.teamsDao.archiveTeam(effectiveTeamId);
  }

  return _SeedResult(
    teamId: effectiveTeamId,
    eventId: eventId,
    athleteIds: athleteIds,
    sessionIds: sessionIds,
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
      masKmh: const drift.Value(20),
      isArchived: drift.Value(isArchived),
      createdAt: now,
      updatedAt: now,
    ),
  );
}

class _SeedResult {
  final int? teamId;
  final int eventId;
  final List<int> athleteIds;
  final List<int> sessionIds;

  const _SeedResult({
    required this.teamId,
    required this.eventId,
    required this.athleteIds,
    required this.sessionIds,
  });
}
