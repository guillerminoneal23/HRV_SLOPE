import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrv_slope_app/ui/theme/app_theme.dart';
import 'package:hrv_slope_app/ui/widgets/date_filter_field.dart';

void main() {
  testWidgets('date filter field is read-only and supports picker and clear', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: DateFilterField(controller: controller, label: 'Date from'),
        ),
      ),
    );

    expect(find.text('YYYY-MM-DD'), findsOneWidget);
    expect(find.byTooltip('Clear date'), findsNothing);

    await tester.tap(find.byType(TextFormField));
    await tester.pumpAndSettle();

    expect(find.byType(CalendarDatePicker), findsOneWidget);
    expect(
      Theme.of(tester.element(find.byType(CalendarDatePicker))).brightness,
      Brightness.dark,
    );

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    controller.text = '2026-06-07';
    await tester.pump();
    expect(find.byTooltip('Clear date'), findsOneWidget);

    await tester.tap(find.byTooltip('Clear date'));
    await tester.pump();
    expect(controller.text, isEmpty);
    expect(find.byTooltip('Clear date'), findsNothing);
  });
}
