import 'package:flutter_test/flutter_test.dart';
import 'package:fungro/main.dart';

void main() {
  testWidgets('App smoke test: loads MainNavigationShell with Home, Projects, and Earnings', (WidgetTester tester) async {
    await tester.pumpWidget(const FunngroAssessmentApp());

    expect(find.text('Welcome back, Alex! 👋'), findsOneWidget);
    expect(find.text('Part 1: Earnings'), findsOneWidget);
    expect(find.text('Part 2: Projects'), findsOneWidget);
  });
}
