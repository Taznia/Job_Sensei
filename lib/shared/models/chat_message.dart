import 'dart:typed_data';

enum MessageAuthor { user, sensei }

enum ChatAttachmentKind { image, document }

class PendingChatAttachment {
  const PendingChatAttachment({
    required this.name,
    required this.mimeType,
    required this.kind,
    required this.sizeBytes,
    this.localPath,
    this.bytes,
  });

  final String name;
  final String mimeType;
  final ChatAttachmentKind kind;
  final int sizeBytes;
  final String? localPath;
  final Uint8List? bytes;
}

class ChatAttachment {
  const ChatAttachment({
    required this.id,
    required this.name,
    required this.mimeType,
    required this.kind,
    required this.sizeBytes,
    this.url,
    this.localPath,
  });

  final String id;
  final String name;
  final String mimeType;
  final ChatAttachmentKind kind;
  final int sizeBytes;
  final String? url;
  final String? localPath;
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.author,
    required this.sentAt,
    this.attachments = const [],
  });

  final String id;
  final String text;
  final MessageAuthor author;
  final DateTime sentAt;
  final List<ChatAttachment> attachments;
}

class ChatConversation {
  const ChatConversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
  });

  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ChatMessage> messages;

  ChatConversation copyWith({
    String? title,
    DateTime? updatedAt,
    List<ChatMessage>? messages,
  }) {
    return ChatConversation(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
    );
  }
}
