import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fungro/main.dart';

void main() {
  testWidgets('App smoke test: loads MainNavigationShell with Overview, Projects, and Earnings', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const FunngroAssessmentApp());
    await tester.pump();

    expect(find.text('Funngro Assessment'), findsOneWidget);
    expect(find.text('Earnings History Screen'), findsOneWidget);
    expect(find.text('Paginated Projects List'), findsOneWidget);
  });
}
