import 'package:flutter/foundation.dart';

import '../../../../core/config/app_config.dart';
import '../../../../shared/models/chat_message.dart';
import '../../data/services/gemini_chat_service.dart';
import '../../domain/repositories/chat_history_repository.dart';

class AiChatController extends ChangeNotifier {
  AiChatController({
    required ChatService chatService,
    required ChatHistoryRepository historyRepository,
  })  : _chatService = chatService,
        _historyRepository = historyRepository;

  final ChatService _chatService;
  final ChatHistoryRepository _historyRepository;

  List<ChatConversation> _conversations = const [];
  String? _activeConversationId;
  bool _isLoading = false;
  bool _isSending = false;
  String? _errorMessage;

  bool get isGeminiConfigured =>
      _chatService.isConfigured || AppConfig.isGeminiConfigured;

  List<ChatConversation> get conversations => List.unmodifiable(
        [..._conversations]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)),
      );
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get errorMessage => _errorMessage;

  ChatConversation? get activeConversation {
    final id = _activeConversationId;
    if (id == null) return null;
    for (final conversation in _conversations) {
      if (conversation.id == id) return conversation;
    }
    return null;
  }

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      final loaded = await _historyRepository.loadConversations();
      final nonempty =
          loaded.where((item) => item.messages.isNotEmpty).toList();
      final empty = loaded.where((item) => item.messages.isEmpty).toList();
      _errorMessage = null;

      if (nonempty.isNotEmpty) {
        for (final conversation in empty) {
          await _historyRepository.deleteConversation(conversation.id);
        }
        _conversations = nonempty;
        _activeConversationId = nonempty.first.id;
      } else if (empty.isNotEmpty) {
        _conversations = [empty.first];
        _activeConversationId = empty.first.id;
        for (final conversation in empty.skip(1)) {
          await _historyRepository.deleteConversation(conversation.id);
        }
      } else {
        await createConversation();
      }
    } catch (_) {
      _errorMessage = 'Could not load saved chats. New chats still work.';
      await createConversation(persist: false);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createConversation({bool persist = true}) async {
    final now = DateTime.now();
    final conversation = ChatConversation(
      id: 'chat-${now.microsecondsSinceEpoch}',
      title: 'New career chat',
      createdAt: now,
      updatedAt: now,
      messages: const [],
    );
    _conversations = [conversation, ..._conversations];
    _activeConversationId = conversation.id;
    notifyListeners();
    if (persist) {
      try {
        await _historyRepository.saveConversation(conversation);
      } catch (_) {
        _errorMessage = 'Chat will not be saved on this device right now.';
      }
    }
  }

  void selectConversation(String conversationId) {
    if (_activeConversationId == conversationId) return;
    _activeConversationId = conversationId;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> deleteConversation(String conversationId) async {
    try {
      await _historyRepository.deleteConversation(conversationId);
    } catch (_) {}
    _conversations = _conversations
        .where((conversation) => conversation.id != conversationId)
        .toList();
    if (_activeConversationId == conversationId) {
      if (_conversations.isEmpty) {
        await createConversation();
      } else {
        _activeConversationId = conversations.first.id;
      }
    }
    notifyListeners();
  }

  Future<void> sendMessage({
    required String text,
    List<PendingChatAttachment> attachments = const [],
  }) async {
    final normalized = text.trim();
    final current = activeConversation;
    if (current == null ||
        _isSending ||
        (normalized.isEmpty && attachments.isEmpty)) {
      return;
    }

    final timestamp = DateTime.now();
    final storedAttachments = attachments.indexed.map((entry) {
      final (index, attachment) = entry;
      return ChatAttachment(
        id: 'chat-file-${timestamp.microsecondsSinceEpoch}-$index',
        name: attachment.name,
        mimeType: attachment.mimeType,
        kind: attachment.kind,
        sizeBytes: attachment.sizeBytes,
        localPath: attachment.localPath,
      );
    }).toList();
    final userMessage = ChatMessage(
      id: 'message-${timestamp.microsecondsSinceEpoch}-user',
      text: normalized,
      author: MessageAuthor.user,
      sentAt: timestamp,
      attachments: storedAttachments,
    );
    final title = current.messages.isEmpty
        ? _titleFrom(normalized, attachments)
        : current.title;
    final withUserMessage = current.copyWith(
      title: title,
      updatedAt: timestamp,
      messages: [...current.messages, userMessage],
    );
    _replaceConversation(withUserMessage);
    _isSending = true;
    _errorMessage = null;
    notifyListeners();
    await _save(withUserMessage);

    try {
      final reply = await _chatService.sendMessage(
        message: normalized,
        history: current.messages,
        attachments: attachments,
      );
      final responseTime = DateTime.now();
      final senseiMessage = ChatMessage(
        id: 'message-${responseTime.microsecondsSinceEpoch}-sensei',
        text: reply,
        author: MessageAuthor.sensei,
        sentAt: responseTime,
      );
      final completed = withUserMessage.copyWith(
        updatedAt: responseTime,
        messages: [...withUserMessage.messages, senseiMessage],
      );
      _replaceConversation(completed);
      await _save(completed);
    } catch (error) {
      final detail = error is GeminiException
          ? error.message
          : 'Could not reach Gemini. Chat is on this device and does not use '
              'the Job Sensei API.';
      _errorMessage = detail;
      final failedAt = DateTime.now();
      final fallback = ChatMessage(
        id: 'message-${failedAt.microsecondsSinceEpoch}-error',
        text: detail,
        author: MessageAuthor.sensei,
        sentAt: failedAt,
      );
      final failed = withUserMessage.copyWith(
        updatedAt: failedAt,
        messages: [...withUserMessage.messages, fallback],
      );
      _replaceConversation(failed);
      await _save(failed);
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  Future<void> _save(ChatConversation conversation) async {
    try {
      await _historyRepository.saveConversation(conversation);
    } catch (_) {
      _errorMessage ??= 'Reply received, but history could not be saved.';
    }
  }

  void _replaceConversation(ChatConversation updated) {
    _conversations = _conversations
        .map((conversation) =>
            conversation.id == updated.id ? updated : conversation)
        .toList();
  }

  String _titleFrom(
    String text,
    List<PendingChatAttachment> attachments,
  ) {
    final source = text.isEmpty ? 'Review ${attachments.first.name}' : text;
    if (source.length <= 34) return source;
    return '${source.substring(0, 34).trim()}...';
  }
}
