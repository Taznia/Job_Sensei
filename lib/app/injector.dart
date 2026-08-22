import '../features/ai/data/repositories/in_memory_chat_history_repository.dart';
import '../features/ai/data/repositories/sqlite_chat_history_repository.dart';
import '../features/ai/data/services/ai_attachment_picker_service.dart';
import '../features/ai/data/services/gemini_chat_service.dart';
import '../features/ai/domain/repositories/chat_history_repository.dart';
import '../features/community/data/repositories/api_community_repository.dart';
import '../features/community/domain/repositories/community_repository.dart';
import '../features/learning/data/services/youtube_resource_service.dart';
import '../services/auth_service.dart';

/// A lightweight composition root. Replace with get_it or Riverpod if the
/// larger team standardizes on a dependency-injection package.
abstract final class Injector {
  static final AuthService _auth = AuthService();
  static ChatHistoryRepository? _chatHistory;
  static bool _memoryChatFallback = false;

  static void useMemoryChatHistory() {
    _memoryChatFallback = true;
    _chatHistory = InMemoryChatHistoryRepository();
  }

  static AuthService authService() => _auth;
  static ChatService chatService() => GeminiChatService();
  static ChatHistoryRepository chatHistoryRepository() {
    return _chatHistory ??= _memoryChatFallback
        ? InMemoryChatHistoryRepository()
        : SqliteChatHistoryRepository();
  }

  static AiAttachmentPickerService aiAttachmentPickerService() =>
      FilePickerAiAttachmentService();
  static CommunityRepository communityRepository() => ApiCommunityRepository();
  static ResourceService resourceService() => YouTubeResourceService();
}
