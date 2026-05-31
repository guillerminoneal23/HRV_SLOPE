import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrv_slope_app/data/database/app_database.dart';
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
  });
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
