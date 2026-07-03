import 'package:flutter_test/flutter_test.dart';

import 'package:jobsensei_frontend/app/app.dart';

void main() {
  testWidgets('renders the app shell', (WidgetTester tester) async {
    await tester.pumpWidget(const JobSenseiApp());
    expect(find.text('Login'), findsOneWidget);
  });
}
