import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobsensei_frontend/app/app.dart';

void main() {
  testWidgets('opens the community module and navigates between modules',
      (tester) async {
    await tester.pumpWidget(const JobSenseiApp());
    await tester.pumpAndSettle();

    expect(find.text('Community'), findsWidgets);
    expect(find.text('Popular communities'), findsOneWidget);

    await tester.tap(find.text('AI Sensei'));
    await tester.pumpAndSettle();

    expect(find.text('AI Career Sensei'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);
  });

  testWidgets('community search filters groups', (tester) async {
    await tester.pumpWidget(const JobSenseiApp());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Search communities or skills'),
      'Flutter',
    );
    await tester.pump();

    expect(find.text('Flutter Developers'), findsOneWidget);
    expect(find.text('React Developers'), findsNothing);
  });
}
