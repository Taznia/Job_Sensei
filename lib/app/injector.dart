import '../features/ai/data/services/gemini_chat_service.dart';
import '../features/community/data/repositories/in_memory_community_repository.dart';
import '../features/community/domain/repositories/community_repository.dart';
import '../features/learning/data/services/youtube_resource_service.dart';

/// A lightweight composition root. Replace with get_it or Riverpod if the
/// larger team standardizes on a dependency-injection package.
abstract final class Injector {
  static ChatService chatService() => GeminiChatService();
  static CommunityRepository communityRepository() =>
      InMemoryCommunityRepository();
  static ResourceService resourceService() => YouTubeResourceService();
}
