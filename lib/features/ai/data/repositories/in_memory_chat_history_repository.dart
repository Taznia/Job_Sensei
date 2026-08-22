import '../../../../shared/models/chat_message.dart';
import '../../domain/repositories/chat_history_repository.dart';

class InMemoryChatHistoryRepository implements ChatHistoryRepository {
  InMemoryChatHistoryRepository({bool seedDemoChats = false})
      : _conversations = seedDemoChats ? _seedConversations() : <ChatConversation>[];

  List<ChatConversation> _conversations;

  @override
  Future<List<ChatConversation>> loadConversations() async {
    await _latency();
    return List.unmodifiable(_conversations);
  }

  @override
  Future<void> saveConversation(ChatConversation conversation) async {
    await _latency();
    final index =
        _conversations.indexWhere((item) => item.id == conversation.id);
    if (index < 0) {
      _conversations = [conversation, ..._conversations];
    } else {
      _conversations = [..._conversations]..[index] = conversation;
    }
  }

  @override
  Future<void> deleteConversation(String conversationId) async {
    await _latency();
    _conversations = _conversations
        .where((conversation) => conversation.id != conversationId)
        .toList();
  }

  static List<ChatConversation> _seedConversations() {
    final now = DateTime.now();
    return [
      ChatConversation(
        id: 'chat-interview-plan',
        title: 'Frontend interview plan',
        createdAt: now.subtract(const Duration(days: 1, hours: 2)),
        updatedAt: now.subtract(const Duration(days: 1)),
        messages: [
          ChatMessage(
            id: 'message-interview-user',
            text: 'Help me prepare for a frontend developer interview.',
            author: MessageAuthor.user,
            sentAt: now.subtract(const Duration(days: 1, minutes: 8)),
          ),
          ChatMessage(
            id: 'message-interview-sensei',
            text:
                'We can focus on JavaScript fundamentals, React architecture, '
                'a small system-design exercise, and five STAR stories.',
            author: MessageAuthor.sensei,
            sentAt: now.subtract(const Duration(days: 1, minutes: 7)),
          ),
        ],
      ),
      ChatConversation(
        id: 'chat-resume-review',
        title: 'Resume improvement ideas',
        createdAt: now.subtract(const Duration(days: 4)),
        updatedAt: now.subtract(const Duration(days: 3, hours: 18)),
        messages: [
          ChatMessage(
            id: 'message-resume-user',
            text: 'What makes a project bullet stronger on my resume?',
            author: MessageAuthor.user,
            sentAt: now.subtract(const Duration(days: 3, hours: 18)),
          ),
          ChatMessage(
            id: 'message-resume-sensei',
            text:
                'Use an action, the technical challenge, and a measurable result. '
                'For example: reduced dashboard load time by 35% through caching.',
            author: MessageAuthor.sensei,
            sentAt:
                now.subtract(const Duration(days: 3, hours: 18, minutes: -1)),
          ),
        ],
      ),
    ];
  }

  Future<void> _latency() =>
      Future<void>.delayed(const Duration(milliseconds: 80));
}
