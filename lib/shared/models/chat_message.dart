enum MessageAuthor { user, sensei }

class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.author,
    required this.sentAt,
  });

  final String text;
  final MessageAuthor author;
  final DateTime sentAt;
}
