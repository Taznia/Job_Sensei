import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobsensei_frontend/app/app.dart';
import 'package:jobsensei_frontend/features/community/data/services/attachment_picker_service.dart';
import 'package:jobsensei_frontend/features/community/presentation/screens/create_post_screen.dart';
import 'package:jobsensei_frontend/shared/models/community_models.dart';

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
      find.widgetWithText(TextField, 'Search communities, roles, or skills'),
      'Flutter',
    );
    await tester.pump();

    expect(find.text('Flutter Developers'), findsOneWidget);
    expect(find.text('React Developers'), findsNothing);
  });

  testWidgets('top plus opens community creation instead of post creation',
      (tester) async {
    await tester.pumpWidget(const JobSenseiApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Create community'));
    await tester.pumpAndSettle();

    expect(find.text('Create a community'), findsOneWidget);
    expect(find.text('Community name'), findsOneWidget);
    expect(find.text('Create post'), findsNothing);
  });

  testWidgets('joined community opens and remains in My groups',
      (tester) async {
    await tester.pumpWidget(const JobSenseiApp());
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('My groups'));
    await tester.pumpAndSettle();
    expect(find.text('React Developers'), findsOneWidget);

    await tester.ensureVisible(find.text('React Developers'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('React Developers'));
    await tester.pumpAndSettle();
    expect(find.text('Community discussions'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('React Developers'), findsOneWidget);
  });

  testWidgets('post form displays selected photo attachment', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CreatePostScreen(attachmentPicker: _FakeAttachmentPicker()),
      ),
    );

    await tester.ensureVisible(find.text('Photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Photo'));
    await tester.pumpAndSettle();

    expect(find.text('portfolio-preview.png'), findsOneWidget);
    expect(find.text('420 KB'), findsOneWidget);
    expect(find.byTooltip('Remove attachment'), findsOneWidget);
  });
}

class _FakeAttachmentPicker implements AttachmentPickerService {
  @override
  Future<List<PendingAttachment>> pickDocuments() async => const [];

  @override
  Future<List<PendingAttachment>> pickImages() async {
    return const [
      PendingAttachment(
        name: 'portfolio-preview.png',
        kind: AttachmentKind.image,
        sizeBytes: 420000,
        extension: 'png',
      ),
    ];
  }
}
