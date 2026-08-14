import 'package:flutter_test/flutter_test.dart';
import 'package:jobsensei_frontend/features/ai/data/repositories/in_memory_chat_history_repository.dart';
import 'package:jobsensei_frontend/features/ai/data/services/gemini_chat_service.dart';
import 'package:jobsensei_frontend/features/ai/presentation/controllers/ai_chat_controller.dart';
import 'package:jobsensei_frontend/shared/models/chat_message.dart';

void main() {
  group('AiChatController', () {
    test('loads history and starts a separate new conversation', () async {
      final controller = AiChatController(
        chatService: _RecordingChatService(),
        historyRepository: InMemoryChatHistoryRepository(),
      );

      await controller.load();

      expect(controller.conversations, hasLength(3));
      expect(controller.activeConversation?.title, 'New career chat');
      expect(controller.activeConversation?.messages, isEmpty);
      controller.dispose();
    });

    test('sends with history and saves a generated conversation title',
        () async {
      final service = _RecordingChatService();
      final controller = AiChatController(
        chatService: service,
        historyRepository: InMemoryChatHistoryRepository(),
      );
      await controller.load();

      await controller.sendMessage(
        text: 'Help me plan a backend developer interview',
      );

      expect(service.lastMessage, 'Help me plan a backend developer interview');
      expect(service.lastHistory, isEmpty);
      expect(controller.activeConversation?.title, startsWith('Help me plan'));
      expect(controller.activeConversation?.messages, hasLength(2));
      expect(
        controller.activeConversation?.messages.last.author,
        MessageAuthor.sensei,
      );
      controller.dispose();
    });

    test('passes pending attachment metadata to the AI service', () async {
      final service = _RecordingChatService();
      final controller = AiChatController(
        chatService: service,
        historyRepository: InMemoryChatHistoryRepository(),
      );
      await controller.load();

      await controller.sendMessage(
        text: 'Review this portfolio image',
        attachments: const [
          PendingChatAttachment(
            name: 'portfolio.png',
            mimeType: 'image/png',
            kind: ChatAttachmentKind.image,
            sizeBytes: 1000,
          ),
        ],
      );

      expect(service.lastAttachments.single.name, 'portfolio.png');
      expect(controller.activeConversation?.messages.first.attachments,
          hasLength(1));
      controller.dispose();
    });
  });
}

class _RecordingChatService implements ChatService {
  String? lastMessage;
  List<ChatMessage> lastHistory = const [];
  List<PendingChatAttachment> lastAttachments = const [];

  @override
  Future<String> sendMessage({
    required String message,
    required List<ChatMessage> history,
    List<PendingChatAttachment> attachments = const [],
  }) async {
    lastMessage = message;
    lastHistory = history;
    lastAttachments = attachments;
    return 'Here is your practical next step.';
  }
}
