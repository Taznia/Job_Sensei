import '../../../../shared/models/chat_message.dart';

abstract interface class ChatHistoryRepository {
  Future<List<ChatConversation>> loadConversations();

  Future<void> saveConversation(ChatConversation conversation);

  Future<void> deleteConversation(String conversationId);
}
