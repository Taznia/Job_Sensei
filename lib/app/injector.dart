import '../features/ai/data/repositories/in_memory_chat_history_repository.dart';
import '../features/ai/data/repositories/sqlite_chat_history_repository.dart';
import '../features/ai/data/services/ai_attachment_picker_service.dart';
import '../features/ai/data/services/gemini_chat_service.dart';
import '../features/ai/data/services/privacy_safe_chat_service.dart';
import '../features/ai/domain/repositories/chat_history_repository.dart';
import '../features/community/data/repositories/api_community_repository.dart';
import '../features/community/domain/repositories/community_repository.dart';
import '../features/learning/data/services/youtube_resource_service.dart';
import '../features/learning/data/repositories/learning_progress_repository.dart';
import '../services/auth_service.dart';
import '../features/profile/data/repositories/api_career_profile_repository.dart';
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
  static ChatService chatService() => PrivacySafeChatService();
  static ChatHistoryRepository chatHistoryRepository() {
    return _chatHistory ??= _memoryChatFallback
        ? InMemoryChatHistoryRepository()
        : SqliteChatHistoryRepository();
  }

  static AiAttachmentPickerService aiAttachmentPickerService() =>
      FilePickerAiAttachmentService();
  static CommunityRepository communityRepository() => ApiCommunityRepository();
  static ResourceService resourceService() => YouTubeResourceService();
  /// Backed by the Node API (Module 1). The in-memory implementation is kept
  /// for widget tests, which pass it to CareerProfileScreen directly.

  static final LearningProgressRepository _learningProgress =
      ApiLearningProgressRepository();
  static LearningProgressRepository learningProgressRepository() =>
      _learningProgress;
  static CareerProfileRepository careerProfileRepository() =>
      ApiCareerProfileRepository();
}
