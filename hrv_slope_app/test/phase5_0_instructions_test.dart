// Phase 5.0 tests — In-app Instructions Book MVP.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrv_slope_app/main.dart';
import 'package:hrv_slope_app/shared/instructions/instructions_content.dart';
import 'package:hrv_slope_app/ui/screens/instructions/instructions_screen.dart';

void main() {
  group('Instructions content', () {
    test('has all required chapters', () {
      expect(instructionsChapters.map((chapter) => chapter.title), [
        'Overview',
        'Measurement Protocol',
        'Data Entry',
        'Direct RMSSD Workflow',
        'RR Interval Workflow',
        'Interpreting Results',
        'Reports and Exports',
        'Limitations and Good Practice',
      ]);
    });

    test('scientific disclaimer exists', () {
      expect(
        kInstructionsDisclaimer,
        contains('not a medical diagnostic tool'),
      );
      expect(kInstructionsDisclaimer, contains('training-load monitoring'));
    });

    test('RMSSD-Slope formula appears', () {
      expect(
        allInstructionText(),
        contains('RMSSD-Slope = (RMSSD_recovery - RMSSD_exercise) / t'),
      );
    });

    test('5-10 window means t=10 appears', () {
      expect(allInstructionText(), contains('Window 5-10 means t = 10'));
    });

    test('direct RMSSD recommended default appears', () {
      final text = allInstructionText();

      expect(
        text,
        contains('Direct RMSSD is the recommended/default workflow'),
      );
      expect(text, contains('Direct RMSSD -> session data'));
    });

    test('RR correction default and raw preservation appear', () {
      final text = allInstructionText();

      expect(text, contains('RR correction is off by default'));
      expect(text, contains('Raw RMSSD is always preserved'));
    });

    test('internal intensity fallback explanation appears', () {
      final text = allInstructionText();

      expect(text, contains('prioritizes external intensity'));
      expect(text, contains('use internal intensity such as RPE'));
      expect(text, contains('subjective fatigue'));
    });

    test('recovery-response framing explains high RPE is contextual', () {
      final text = allInstructionText();

      expect(text, contains('post-effort slope response versus the reference'));
      expect(
        text,
        contains(
          'High RPE or fatigue does not automatically mean poor recovery',
        ),
      );
      expect(
        text,
        contains(
          'RPE and fatigue describe perceived demand; they are not judged',
        ),
      );
    });

    test('nomogram model system and controls are explained', () {
      final text = allInstructionText();

      expect(text, contains('The Study model uses the study reference only'));
      expect(text, contains('no extra hybrid curve is drawn'));
      expect(text, contains('Individual model uses athlete-specific bands'));
      expect(text, contains('Requested model is the user selection'));
      expect(text, contains('Active model is the model actually used'));
      expect(text, contains('Estimated zone means an intensity is outside'));
      expect(text, contains('Viewport controls adjust the visible intensity'));
      expect(text, contains('Individual Nomogram filters limit'));
      expect(
        text,
        contains('Recovery status classifies the observed response'),
      );
    });

    test('forbidden medical diagnostic claims are absent', () {
      final text = allInstructionText().toLowerCase();

      expect(text, isNot(contains('disease')));
      expect(text, isNot(contains('pathological')));
      expect(text, isNot(contains('treatment')));
      expect(text, isNot(contains('therapy')));
    });

    test('no backend cloud or telemetry capability is introduced', () {
      final text = allInstructionText().toLowerCase();

      expect(text, contains('no cloud'));
      expect(text, contains('no telemetry'));
      expect(text, isNot(contains('cloud sync')));
      expect(text, isNot(contains('remote analytics')));
    });
  });

  group('Instructions screen', () {
    testWidgets('renders chapter list and overview sections', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: InstructionsScreen()));

      expect(find.text('Instructions Book'), findsOneWidget);
      expect(find.text('Chapters'), findsOneWidget);
      expect(find.text('Overview'), findsWidgets);
      await tester.scrollUntilVisible(
        find.text('What is RMSSD-Slope?'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('What is RMSSD-Slope?'), findsOneWidget);
      expect(
        find.textContaining('not a medical diagnostic tool'),
        findsWidgets,
      );
    });

    testWidgets('renders selected chapter sections', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: InstructionsScreen()));

      await tester.tap(find.text('Measurement Protocol'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Preferred Slope-10 protocol'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Preferred Slope-10 protocol'), findsOneWidget);
      expect(
        find.textContaining('t used for slope is 10 minutes'),
        findsOneWidget,
      );
    });

    testWidgets('search filters instruction sections', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: InstructionsScreen()));

      await tester.enterText(find.byType(TextField), 'XLSX');
      await tester.pumpAndSettle();

      expect(find.text('Reports and Exports'), findsWidgets);
      expect(find.text('XLSX/PDF status'), findsOneWidget);
    });
  });

  group('Navigation', () {
    testWidgets('app shell exposes Instructions navigation entry', (
      tester,
    ) async {
      await tester.pumpWidget(const HrvSlopeApp());

      expect(find.text('Instructions'), findsOneWidget);
    });
  });
}
