import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrv_slope_app/data/database/app_database.dart';
import 'package:hrv_slope_app/shared/engine/longitudinal_builder.dart';
import 'package:hrv_slope_app/ui/screens/athletes/athlete_detail_screen.dart';
import 'package:hrv_slope_app/ui/screens/session/session_detail_screen.dart';
import 'package:hrv_slope_app/ui/screens/session/session_edit_screen.dart';
import 'package:hrv_slope_app/ui/screens/session/session_wizard_screen.dart';

void main() {
  group('Session wizard step-scoped validation', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      await _seedAthlete(db);
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('External step accepts %MAS without RMSSD', (tester) async {
      await _pumpWizardAtExternalStep(tester, db);

      await tester.enterText(
        find.widgetWithText(TextFormField, '% MAS (%)'),
        '80',
      );
      await _tapNext(tester);

      expect(find.text('Internal Load Variables'), findsOneWidget);
      expect(find.textContaining('RMSSD recovery must be > 0'), findsNothing);
    });

    testWidgets('External step accepts empty external load without RMSSD', (
      tester,
    ) async {
      await _pumpWizardAtExternalStep(tester, db);

      await _tapNext(tester);

      expect(find.text('Internal Load Variables'), findsOneWidget);
      expect(find.textContaining('RMSSD recovery must be > 0'), findsNothing);
    });

    testWidgets('External step accepts zero external load without RMSSD', (
      tester,
    ) async {
      await _pumpWizardAtExternalStep(tester, db);

      await tester.enterText(
        find.widgetWithText(TextFormField, '% MAS (%)'),
        '0',
      );
      await _tapNext(tester);

      expect(find.text('Internal Load Variables'), findsOneWidget);
      expect(find.textContaining('RMSSD recovery must be > 0'), findsNothing);
    });

    testWidgets('HRV step validates missing RMSSD recovery', (tester) async {
      await _pumpWizardAtExternalStep(tester, db);
      await _tapNext(tester);
      expect(find.text('Internal Load Variables'), findsOneWidget);

      await _tapNext(tester);
      expect(find.text('HRV / RMSSD Data'), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
      await tester.pump();

      expect(find.text('HRV / RMSSD Data'), findsOneWidget);
      expect(find.textContaining('RMSSD recovery must be > 0'), findsOneWidget);
    });

    testWidgets('Session step exposes optional time and adds explicit time', (
      tester,
    ) async {
      await _pumpWizardAtSessionStep(tester, db);
      await _showSessionTimeControl(tester);

      expect(find.text('Time (optional)'), findsOneWidget);
      expect(find.text('Not set'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Add time'), findsOneWidget);

      await _pickSessionTime(tester, hour: 10, minute: 0);

      expect(find.text('10:00'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Change'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Remove'), findsOneWidget);
    });

    testWidgets('Saving without adding time keeps date-only session date', (
      tester,
    ) async {
      await _pumpWizardAtSessionStep(tester, db);
      await _completeAndSaveSession(tester);

      final sessions = await db.sessionsDao.getAllSessions();
      expect(sessions, hasLength(1));
      expect(sessions.single.date, _todayDateOnly());
      expect(sessions.single.date, isNot(contains('T')));
    });

    testWidgets('Saving with explicit time persists ISO date-time', (
      tester,
    ) async {
      await _pumpWizardAtSessionStep(tester, db);
      await _pickSessionTime(tester, hour: 10, minute: 0);
      await _completeAndSaveSession(tester);

      final sessions = await db.sessionsDao.getAllSessions();
      expect(sessions, hasLength(1));
      expect(sessions.single.date, startsWith('${_todayDateOnly()}T10:00'));
    });

    testWidgets('Calculation preview formats explicit time for display', (
      tester,
    ) async {
      await _pumpWizardAtSessionStep(tester, db);
      await _pickSessionTime(tester, hour: 10, minute: 0);

      await _advanceToPreview(tester);

      expect(find.text('${_todayDateOnly()} 10:00'), findsOneWidget);
      expect(find.textContaining('${_todayDateOnly()}T10:00'), findsNothing);
    });

    testWidgets('Removing explicit time restores date-only persistence', (
      tester,
    ) async {
      await _pumpWizardAtSessionStep(tester, db);
      await _pickSessionTime(tester, hour: 10, minute: 0);
      await tester.tap(find.widgetWithText(TextButton, 'Remove'));
      await tester.pumpAndSettle();

      expect(find.text('Not set'), findsOneWidget);
      await _completeAndSaveSession(tester);

      final sessions = await db.sessionsDao.getAllSessions();
      expect(sessions, hasLength(1));
      expect(sessions.single.date, _todayDateOnly());
      expect(sessions.single.date, isNot(contains('T')));
    });

    test(
      'same-day sessions remain independent and order by ISO time',
      () async {
        final athlete = (await db.athletesDao.getAllAthletes()).single;
        final morningId = await _insertMinimalSession(
          db,
          athleteId: athlete.id,
          date: '2026-08-20T10:00:00',
        );
        final afternoonId = await _insertMinimalSession(
          db,
          athleteId: athlete.id,
          date: '2026-08-20T17:00:00',
        );

        expect(morningId, isNot(afternoonId));

        final newestFirst = await db.sessionsDao.getSessionsForAthlete(
          athlete.id,
        );
        expect(newestFirst.map((session) => session.date), [
          '2026-08-20T17:00:00',
          '2026-08-20T10:00:00',
        ]);

        final details = await db.sessionsDao.getSessionDetailsForAthlete(
          athlete.id,
        );
        final series = buildLongitudinalSeries(
          athlete: athlete,
          details: details,
        );
        expect(series.points.map((point) => point.date), [
          '2026-08-20T10:00:00',
          '2026-08-20T17:00:00',
        ]);
      },
    );

    testWidgets(
      'Session detail displays explicit time without inventing midnight',
      (tester) async {
        final athlete = (await db.athletesDao.getAllAthletes()).single;
        final dateOnlyId = await _insertMinimalSession(
          db,
          athleteId: athlete.id,
          date: '2026-08-20',
        );
        final timedId = await _insertMinimalSession(
          db,
          athleteId: athlete.id,
          date: '2026-08-20T10:00:00',
        );

        await tester.pumpWidget(
          MaterialApp(
            key: ValueKey('session_detail_$timedId'),
            home: SessionDetailScreen(database: db, sessionId: timedId),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('2026-08-20 10:00'), findsOneWidget);

        await tester.pumpWidget(
          MaterialApp(
            key: ValueKey('session_detail_$dateOnlyId'),
            home: SessionDetailScreen(database: db, sessionId: dateOnlyId),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('2026-08-20'), findsOneWidget);
        expect(find.textContaining('00:00'), findsNothing);
      },
    );

    testWidgets(
      'Athlete detail lists same-day sessions newest first with time',
      (tester) async {
        final athlete = (await db.athletesDao.getAllAthletes()).single;
        await _insertMinimalSession(
          db,
          athleteId: athlete.id,
          date: '2026-08-20T10:00:00',
        );
        await _insertMinimalSession(
          db,
          athleteId: athlete.id,
          date: '2026-08-20T17:00:00',
        );
        await _insertMinimalSession(
          db,
          athleteId: athlete.id,
          date: '2026-08-21',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: AthleteDetailScreen(database: db, athleteId: athlete.id),
          ),
        );
        await tester.pumpAndSettle();

        final afternoon = find.textContaining('2026-08-20 17:00');
        final morning = find.textContaining('2026-08-20 10:00');
        expect(afternoon, findsOneWidget);
        expect(morning, findsOneWidget);
        expect(find.textContaining('2026-08-21 00:00'), findsNothing);
        expect(
          tester.getTopLeft(afternoon).dy,
          lessThan(tester.getTopLeft(morning).dy),
        );
      },
    );

    testWidgets(
      'Session edit preserves explicit time when a non-date field changes',
      (tester) async {
        final athlete = (await db.athletesDao.getAllAthletes()).single;
        final sessionId = await _insertMinimalSession(
          db,
          athleteId: athlete.id,
          date: '2026-08-20T10:00:00.000',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: SessionEditScreen(database: db, sessionId: sessionId),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Notes'),
          'Edited note',
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Save changes'));
        await tester.pumpAndSettle();

        final detail = await db.sessionsDao.getSessionDetail(sessionId);
        expect(detail!.session.date, '2026-08-20T10:00:00.000');
        expect(detail.session.notes, 'Edited note');
      },
    );

    testWidgets(
      'Session edit preserves date-only value when a non-date field changes',
      (tester) async {
        final athlete = (await db.athletesDao.getAllAthletes()).single;
        final sessionId = await _insertMinimalSession(
          db,
          athleteId: athlete.id,
          date: '2026-08-20',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: SessionEditScreen(database: db, sessionId: sessionId),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Notes'),
          'Date-only edit',
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Save changes'));
        await tester.pumpAndSettle();

        final detail = await db.sessionsDao.getSessionDetail(sessionId);
        expect(detail!.session.date, '2026-08-20');
        expect(detail.session.notes, 'Date-only edit');
      },
    );
  });
}

Future<void> _pumpWizardAtSessionStep(
  WidgetTester tester,
  AppDatabase db,
) async {
  await tester.pumpWidget(MaterialApp(home: SessionWizardScreen(database: db)));
  await tester.pumpAndSettle();

  await tester.tap(find.text('Runner One'));
  await tester.pump();
  await _tapNext(tester);
  expect(find.text('Session Details'), findsOneWidget);

  await tester.enterText(find.byType(TextFormField).at(0), 'HIIT');
  await tester.enterText(find.byType(TextFormField).at(1), 'Running');
}

Future<void> _pumpWizardAtExternalStep(
  WidgetTester tester,
  AppDatabase db,
) async {
  await tester.pumpWidget(MaterialApp(home: SessionWizardScreen(database: db)));
  await tester.pumpAndSettle();

  await tester.tap(find.text('Runner One'));
  await tester.pump();
  await _tapNext(tester);
  expect(find.text('Session Details'), findsOneWidget);

  await tester.enterText(find.byType(TextFormField).at(0), 'HIIT');
  await tester.enterText(find.byType(TextFormField).at(1), 'Running');
  await _tapNext(tester);

  expect(find.text('External Load Variables'), findsOneWidget);
  expect(find.textContaining('RMSSD recovery must be > 0'), findsNothing);
}

Future<void> _completeAndSaveSession(WidgetTester tester) async {
  await _advanceToPreview(tester);
  await tester.tap(find.widgetWithText(ElevatedButton, 'Save Session'));
  await tester.pumpAndSettle();
}

Future<void> _advanceToPreview(WidgetTester tester) async {
  await _tapNext(tester);

  expect(find.text('External Load Variables'), findsOneWidget);
  await tester.enterText(find.widgetWithText(TextFormField, '% MAS (%)'), '80');
  await _tapNext(tester);

  expect(find.text('Internal Load Variables'), findsOneWidget);
  await _tapNext(tester);

  expect(find.text('HRV / RMSSD Data'), findsOneWidget);
  await tester.enterText(
    find.widgetWithText(TextFormField, 'RMSSD Recovery (ms) *'),
    '20',
  );
  await _tapNext(tester);

  expect(find.text('Calculation Preview'), findsOneWidget);
}

Future<void> _pickSessionTime(
  WidgetTester tester, {
  required int hour,
  required int minute,
}) async {
  await _showSessionTimeControl(tester);
  await tester.tap(find.widgetWithText(OutlinedButton, 'Add time'));
  await tester.pumpAndSettle();

  final fields = find.descendant(
    of: find.byType(TimePickerDialog),
    matching: find.byType(TextField),
  );
  expect(fields, findsNWidgets(2));
  await tester.enterText(fields.at(0), hour.toString().padLeft(2, '0'));
  await tester.enterText(fields.at(1), minute.toString().padLeft(2, '0'));
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

Future<void> _showSessionTimeControl(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.byKey(const Key('session_time_optional')),
    160,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

Future<void> _tapNext(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
  await tester.pumpAndSettle();
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

Future<int> _insertMinimalSession(
  AppDatabase db, {
  required int athleteId,
  required String date,
}) {
  return db.sessionsDao.insertSession(
    SessionsCompanion.insert(
      athleteId: athleteId,
      date: date,
      taskName: const drift.Value('Training'),
      sport: const drift.Value('Running'),
      isDraft: const drift.Value(false),
      intensityPercent: const drift.Value(80),
      intensitySource: const drift.Value('External'),
      rmssdExercise: const drift.Value(4),
      rmssdExerciseIsDefault: const drift.Value(true),
      rmssdRecovery: const drift.Value(20),
      slopeRaw: const drift.Value(0.2),
      slopeInterpreted: const drift.Value(0.2),
      itlIndex: const drift.Value(5),
      classification: const drift.Value('expected_response'),
      hrvInputMode: const drift.Value('direct_rmssd'),
      rmssdRecoverySource: const drift.Value('manual'),
      rmssdExerciseSource: const drift.Value('fallback_4_ms'),
      createdAt: date.contains('T') ? date : '${date}T00:00:00',
    ),
  );
}

String _todayDateOnly() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
}
