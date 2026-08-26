import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobsensei_frontend/app/theme.dart';
import 'package:jobsensei_frontend/features/authentication/authentication_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpAuth(
    WidgetTester tester, {
    bool register = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AuthenticationPage(register: register),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('signup separates job seeker and employer fields',
      (tester) async {
    await pumpAuth(tester, register: true);

    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Job seeker'), findsOneWidget);
    expect(find.text('Employer'), findsOneWidget);
    expect(find.text('ORGANIZATION'), findsNothing);
    expect(find.text('SIGN UP'), findsOneWidget);

    await tester.tap(find.text('Employer'));
    await tester.pumpAndSettle();

    expect(find.text('ORGANIZATION'), findsOneWidget);
    expect(find.text('WORK EMAIL'), findsOneWidget);
    expect(find.text('SIGN UP'), findsOneWidget);
    expect(
      find.textContaining('Admin verification is required'),
      findsOneWidget,
    );
  });

  testWidgets('login shows password recovery and hides signup-only fields',
      (tester) async {
    await pumpAuth(tester);

    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Please sign in to continue.'), findsOneWidget);
    expect(find.text('FORGOT'), findsOneWidget);
    expect(find.text('ORGANIZATION'), findsNothing);
    expect(find.text('CONFIRM PASSWORD'), findsNothing);
    expect(find.text('TEST ACCOUNTS'), findsOneWidget);
    expect(find.textContaining('demo@jobsensei.app'), findsOneWidget);
    expect(find.textContaining('recruiter@jobsensei.app'), findsOneWidget);
    expect(find.textContaining('admin@jobsensei.app'), findsOneWidget);

    final forgotPassword = find.widgetWithText(TextButton, 'FORGOT');
    await tester.ensureVisible(forgotPassword);
    await tester.pumpAndSettle();
    await tester.tap(forgotPassword);
    await tester.pumpAndSettle();

    expect(find.text('Recover password'), findsOneWidget);
    expect(find.text('Send code'), findsOneWidget);
  });

  testWidgets('signup validates matching passwords', (tester) async {
    await pumpAuth(tester, register: true);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Ada Lovelace');
    await tester.enterText(fields.at(1), 'ada@example.com');
    await tester.enterText(fields.at(2), 'Password123!');
    await tester.enterText(fields.at(3), 'Different123!');

    final submit = find.text('SIGN UP');
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.pump();

    expect(find.text('Passwords do not match'), findsOneWidget);
  });
}
