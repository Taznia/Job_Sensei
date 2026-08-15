import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobsensei_frontend/app/app.dart';
import 'package:jobsensei_frontend/features/ai/data/repositories/in_memory_chat_history_repository.dart';
import 'package:jobsensei_frontend/features/ai/data/services/ai_attachment_picker_service.dart';
import 'package:jobsensei_frontend/features/ai/data/services/gemini_chat_service.dart';
import 'package:jobsensei_frontend/features/ai/presentation/screens/ai_chat_screen.dart';
import 'package:jobsensei_frontend/features/ai/presentation/widgets/ai_buddy.dart';
import 'package:jobsensei_frontend/features/community/data/services/attachment_picker_service.dart';
import 'package:jobsensei_frontend/features/community/presentation/screens/create_post_screen.dart';
import 'package:jobsensei_frontend/shared/models/chat_message.dart';
import 'package:jobsensei_frontend/shared/models/community_models.dart';

void main() {
  testWidgets('opens the community module and navigates between modules',
      (tester) async {
    await tester.pumpWidget(const JobSenseiApp());
    await tester.pumpAndSettle();

    expect(find.text('Community'), findsWidgets);
    expect(find.text('Popular communities'), findsOneWidget);

    await tester.tap(find.text('AI Sensei'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.textContaining('Momo'), findsWidgets);
    expect(find.text('Hi! I\'m Momo'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is AiBuddy && widget.showGreeting,
      ),
      findsOneWidget,
    );
    expect(find.byTooltip('Chat history'), findsOneWidget);
    expect(find.byTooltip('New chat'), findsNothing);
    expect(find.byIcon(Icons.refresh_rounded), findsNothing);
    expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);

    final screenCenter =
        tester.view.physicalSize.width / tester.view.devicePixelRatio / 2;
    expect(
      tester.getCenter(find.byKey(const ValueKey('momo-welcome-body'))).dx,
      closeTo(screenCenter, 1.5),
    );
    expect(
      tester.getCenter(find.text('Your AI career companion')).dx,
      closeTo(screenCenter, 1.5),
    );
  });

  testWidgets('community cards do not overflow on a scaled phone display',
      (tester) async {
    tester.view.physicalSize = const Size(720, 1600);
    tester.view.devicePixelRatio = 2;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(
      tester.platformDispatcher.clearTextScaleFactorTestValue,
    );

    await tester.pumpWidget(const JobSenseiApp());
    await tester.pumpAndSettle();

    expect(find.text('Popular communities'), findsOneWidget);
    expect(tester.takeException(), isNull);
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

  testWidgets('trending post requires choosing a community', (tester) async {
    await tester.pumpWidget(const JobSenseiApp());
    await tester.pumpAndSettle();

    await tester.drag(
      find.byType(CustomScrollView).first,
      const Offset(0, -650),
    );
    await tester.pumpAndSettle();
    expect(find.text('Trending discussions'), findsWidgets);
    await tester.tap(find.text('Create post'));
    await tester.pumpAndSettle();

    expect(find.text('Choose a community'), findsOneWidget);
    expect(find.textContaining('Your post will appear'), findsOneWidget);

    await tester.tap(find.text('React Developers').last);
    await tester.pumpAndSettle();
    expect(find.text('Share something useful'), findsOneWidget);
    expect(find.text('REACT DEVELOPERS'), findsOneWidget);
  });

  testWidgets('trending post supports comments, love, and sharing',
      (tester) async {
    await tester.pumpWidget(const JobSenseiApp());
    await tester.pumpAndSettle();

    await tester.drag(
      find.byType(CustomScrollView).first,
      const Offset(0, -1200),
    );
    await tester.pumpAndSettle();
    expect(find.text('Interview'), findsNothing);
    expect(find.text('System Design'), findsNothing);

    await tester.tap(find.byTooltip('View comments').first);
    await tester.pumpAndSettle();
    expect(find.text('Comments'), findsOneWidget);
    expect(find.textContaining('Start with scalability'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Write a helpful reply...'),
      'This explanation helped me prepare.',
    );
    await tester.tap(find.byTooltip('Post reply'));
    await tester.pumpAndSettle();
    expect(find.text('This explanation helped me prepare.'), findsOneWidget);

    await tester.tap(find.byTooltip('Close comments'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Love post').first);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Remove love'), findsWidgets);

    await tester.tap(find.byTooltip('Share post').first);
    await tester.pumpAndSettle();
    expect(find.text('Share post'), findsOneWidget);
    expect(find.text('WhatsApp'), findsOneWidget);
    expect(find.text('Copy post text'), findsOneWidget);
  });

  testWidgets('AI history drawer shows previous conversations', (tester) async {
    await tester.pumpWidget(const JobSenseiApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('AI Sensei'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byTooltip('Chat history'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('CHAT HISTORY'), findsOneWidget);
    expect(find.text('Frontend interview plan'), findsOneWidget);
    expect(find.text('Resume improvement ideas'), findsOneWidget);
    expect(find.text('New chat'), findsOneWidget);
  });

  testWidgets('AI composer displays a selected attachment', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AiChatScreen(
          service: _FakeChatService(),
          historyRepository: InMemoryChatHistoryRepository(),
          attachmentPicker: _FakeAiAttachmentPicker(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    await tester.tap(find.byTooltip('Attach a file'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Add an attachment'), findsOneWidget);

    await tester.tap(find.text('Photo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('career-board.png'), findsOneWidget);
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

class _FakeAiAttachmentPicker implements AiAttachmentPickerService {
  @override
  Future<List<PendingChatAttachment>> pickDocuments() async => const [];

  @override
  Future<List<PendingChatAttachment>> pickImages() async {
    return const [
      PendingChatAttachment(
        name: 'career-board.png',
        mimeType: 'image/png',
        kind: ChatAttachmentKind.image,
        sizeBytes: 360000,
      ),
    ];
  }
}

class _FakeChatService implements ChatService {
  @override
  Future<String> sendMessage({
    required String message,
    required List<ChatMessage> history,
    List<PendingChatAttachment> attachments = const [],
  }) async {
    return 'Test response';
  }
}
