import '../features/ai/data/repositories/in_memory_chat_history_repository.dart';
import '../features/ai/data/repositories/sqlite_chat_history_repository.dart';
import '../features/ai/data/services/ai_attachment_picker_service.dart';
import '../features/ai/data/services/gemini_chat_service.dart';
import '../features/ai/domain/repositories/chat_history_repository.dart';
import '../features/community/data/repositories/api_community_repository.dart';
import '../features/community/domain/repositories/community_repository.dart';
import '../features/learning/data/services/youtube_resource_service.dart';
import '../services/auth_service.dart';
import '../features/profile/data/repositories/in_memory_career_profile_repository.dart';
import '../features/profile/domain/repositories/career_profile_repository.dart';

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

  /// Single seeded profile for now. A REST implementation drops in here without
  /// the profile screens changing.
  static final CareerProfileRepository _careerProfileRepository =
      InMemoryCareerProfileRepository();

  static CareerProfileRepository careerProfileRepository() =>
      _careerProfileRepository;
}
