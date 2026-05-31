import 'package:flutter_test/flutter_test.dart';
import 'package:hrv_slope_app/main.dart';

void main() {
  testWidgets('Phase 2 app shell renders navigation', (tester) async {
    await tester.pumpWidget(const HrvSlopeApp());

    // App should show the bottom navigation bar with all 4 tabs
    expect(find.text('Athletes'), findsWidgets);
    expect(find.text('New Session'), findsOneWidget);
    expect(find.text('Import'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
