import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobsensei_frontend/features/jobs/jobs_page.dart';

void main() {
  testWidgets('opening a job shows match and hands analysis to Learn',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: JobsPage()));
    await tester.pumpAndSettle();

    expect(find.text('Flutter Developer'), findsOneWidget);
    await tester.tap(find.text('Flutter Developer'));
    await tester.pumpAndSettle();

    expect(find.text('Job Match'), findsOneWidget);
    expect(find.text('Analyze Skills in Learn'), findsOneWidget);
  });
}