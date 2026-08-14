import '../features/ai/data/repositories/in_memory_chat_history_repository.dart';
import '../features/ai/data/services/ai_attachment_picker_service.dart';
import '../features/ai/data/services/gemini_chat_service.dart';
import '../features/ai/domain/repositories/chat_history_repository.dart';
import '../features/community/data/repositories/in_memory_community_repository.dart';
import '../features/community/domain/repositories/community_repository.dart';
import '../features/learning/data/services/youtube_resource_service.dart';

/// A lightweight composition root. Replace with get_it or Riverpod if the
/// larger team standardizes on a dependency-injection package.
abstract final class Injector {
  static ChatService chatService() => GeminiChatService();
  static ChatHistoryRepository chatHistoryRepository() =>
      InMemoryChatHistoryRepository();
  static AiAttachmentPickerService aiAttachmentPickerService() =>
      FilePickerAiAttachmentService();
  static CommunityRepository communityRepository() =>
      InMemoryCommunityRepository();
  static ResourceService resourceService() => YouTubeResourceService();
}
