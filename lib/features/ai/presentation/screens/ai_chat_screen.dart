import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/models/chat_message.dart';
import '../../data/repositories/in_memory_chat_history_repository.dart';
import '../../data/services/ai_attachment_picker_service.dart';
import '../../data/services/gemini_chat_service.dart';
import '../../domain/repositories/chat_history_repository.dart';
import '../controllers/ai_chat_controller.dart';
import '../widgets/ai_buddy.dart';
import '../widgets/animated_ai_background.dart';
import '../widgets/chat_composer.dart';
import '../widgets/chat_history_panel.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({
    super.key,
    this.service,
    this.historyRepository,
    this.attachmentPicker,
  });

  final ChatService? service;
  final ChatHistoryRepository? historyRepository;
  final AiAttachmentPickerService? attachmentPicker;

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  late final AiChatController _chatController = AiChatController(
    chatService: widget.service ?? GeminiChatService(),
    historyRepository:
        widget.historyRepository ?? InMemoryChatHistoryRepository(),
  )..addListener(_refresh);
  late final AiAttachmentPickerService _attachmentPicker =
      widget.attachmentPicker ?? FilePickerAiAttachmentService();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _pendingAttachments = <PendingChatAttachment>[];
  int _lastMessageCount = 0;
  bool _isPickingAttachment = false;

  static const _suggestions = [
    ('Interview prep', 'Prepare me for a frontend interview'),
    ('Resume help', 'Help me improve my resume bullets'),
    ('Career path', 'Which skill should I learn next?'),
  ];

  @override
  void initState() {
    super.initState();
    _chatController.load();
  }

  @override
  void dispose() {
    _chatController
      ..removeListener(_refresh)
      ..dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (!mounted) return;
    final messageCount =
        _chatController.activeConversation?.messages.length ?? 0;
    setState(() {});
    if (messageCount != _lastMessageCount) {
      _lastMessageCount = messageCount;
      _scrollToBottom();
    }
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _textController.text).trim();
    if ((text.isEmpty && _pendingAttachments.isEmpty) ||
        _chatController.isSending) {
      return;
    }
    final attachments = List<PendingChatAttachment>.from(_pendingAttachments);
    _textController.clear();
    setState(() => _pendingAttachments.clear());
    await _chatController.sendMessage(text: text, attachments: attachments);
  }

  Future<void> _showAttachmentMenu() async {
    if (_isPickingAttachment || _pendingAttachments.length >= 3) return;
    final kind = await showModalBottomSheet<ChatAttachmentKind>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 2, 18, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add an attachment',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 5),
              const Text(
                'Momo can review images, PDFs, text, and document metadata.',
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _AttachmentOption(
                      icon: Icons.add_photo_alternate_outlined,
                      title: 'Photo',
                      subtitle: 'PNG, JPG, WEBP',
                      color: AppColors.primary,
                      onTap: () =>
                          Navigator.pop(context, ChatAttachmentKind.image),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _AttachmentOption(
                      icon: Icons.description_outlined,
                      title: 'Document',
                      subtitle: 'PDF, TXT, DOCX',
                      color: AppColors.violet,
                      onTap: () => Navigator.pop(
                        context,
                        ChatAttachmentKind.document,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (kind == null || !mounted) return;
    await _pickAttachments(kind);
  }

  Future<void> _pickAttachments(ChatAttachmentKind kind) async {
    setState(() => _isPickingAttachment = true);
    try {
      final picked = kind == ChatAttachmentKind.image
          ? await _attachmentPicker.pickImages()
          : await _attachmentPicker.pickDocuments();
      if (!mounted || picked.isEmpty) return;
      final remaining = 3 - _pendingAttachments.length;
      final valid = picked.where((file) => file.sizeBytes <= 8 * 1000 * 1000);
      final oversized = picked.length - valid.length;
      setState(() => _pendingAttachments.addAll(valid.take(remaining)));
      if (oversized > 0) {
        _showMessage('Files larger than 8 MB were not added.');
      } else if (valid.length > remaining) {
        _showMessage('You can attach up to 3 files per message.');
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Could not attach that file. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingAttachment = false);
      }
    }
  }

  Future<void> _newChat({bool closeDrawer = false}) async {
    await _chatController.createConversation();
    if (closeDrawer && mounted) Navigator.of(context).pop();
    _textController.clear();
    setState(() => _pendingAttachments.clear());
  }

  void _selectConversation(String id, {required bool closeDrawer}) {
    _chatController.selectConversation(id);
    if (closeDrawer) Navigator.of(context).pop();
    _lastMessageCount =
        _chatController.activeConversation?.messages.length ?? 0;
    _scrollToBottom();
  }

  Future<void> _deleteConversation(String id) async {
    final conversation = _chatController.conversations.firstWhere(
      (item) => item.id == id,
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this chat?'),
        content: Text('"${conversation.title}" will be removed from history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _chatController.deleteConversation(id);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 980;
        final history = ChatHistoryPanel(
          conversations: _chatController.conversations,
          activeConversationId: _chatController.activeConversation?.id,
          onNewChat: () => _newChat(closeDrawer: !wide),
          onSelect: (id) => _selectConversation(id, closeDrawer: !wide),
          onDelete: _deleteConversation,
        );
        final workspace = _ChatWorkspace(
          controller: _chatController,
          textController: _textController,
          scrollController: _scrollController,
          pendingAttachments: _pendingAttachments,
          isPickingAttachment: _isPickingAttachment,
          showMenuButton: !wide,
          onOpenHistory: () => _scaffoldKey.currentState?.openDrawer(),
          onAttach: _showAttachmentMenu,
          onRemoveAttachment: (index) =>
              setState(() => _pendingAttachments.removeAt(index)),
          onSend: _send,
        );

        if (wide) {
          return SafeArea(
            child: Row(
              children: [
                SizedBox(width: 292, child: history),
                Expanded(child: workspace),
              ],
            ),
          );
        }
        return Scaffold(
          key: _scaffoldKey,
          drawer: Drawer(
            width: 310,
            child: history,
          ),
          body: SafeArea(child: workspace),
        );
      },
    );
  }
}

class _ChatWorkspace extends StatelessWidget {
  const _ChatWorkspace({
    required this.controller,
    required this.textController,
    required this.scrollController,
    required this.pendingAttachments,
    required this.isPickingAttachment,
    required this.showMenuButton,
    required this.onOpenHistory,
    required this.onAttach,
    required this.onRemoveAttachment,
    required this.onSend,
  });

  final AiChatController controller;
  final TextEditingController textController;
  final ScrollController scrollController;
  final List<PendingChatAttachment> pendingAttachments;
  final bool isPickingAttachment;
  final bool showMenuButton;
  final VoidCallback onOpenHistory;
  final VoidCallback onAttach;
  final ValueChanged<int> onRemoveAttachment;
  final void Function([String? preset]) onSend;

  @override
  Widget build(BuildContext context) {
    final conversation = controller.activeConversation;
    final messages = conversation?.messages ?? const <ChatMessage>[];
    return Stack(
      children: [
        const Positioned.fill(child: AnimatedAiBackground()),
        Column(
          children: [
            _ChatHeader(
              title: conversation?.title ?? 'AI Career Sensei',
              isThinking: controller.isSending,
              showMenuButton: showMenuButton,
              onOpenHistory: onOpenHistory,
            ),
            if (controller.isLoading && conversation == null)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: messages.isEmpty
                    ? _BuddyWelcome(onSuggestion: onSend)
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                        itemCount:
                            messages.length + (controller.isSending ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == messages.length) {
                            return const _TypingBubble();
                          }
                          return _MessageBubble(message: messages[index]);
                        },
                      ),
              ),
            if (isPickingAttachment)
              const LinearProgressIndicator(minHeight: 2),
            ChatComposer(
              controller: textController,
              enabled: !controller.isSending && !isPickingAttachment,
              attachments: pendingAttachments,
              onAttach: onAttach,
              onRemoveAttachment: onRemoveAttachment,
              onSend: onSend,
            ),
          ],
        ),
      ],
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.title,
    required this.isThinking,
    required this.showMenuButton,
    required this.onOpenHistory,
  });

  final String title;
  final bool isThinking;
  final bool showMenuButton;
  final VoidCallback onOpenHistory;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.86),
        border: const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (showMenuButton)
            IconButton(
              tooltip: 'Chat history',
              onPressed: onOpenHistory,
              icon: const Icon(Icons.menu_rounded),
            ),
          AiBuddy(size: 47, isThinking: isThinking),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 16),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const CircleAvatar(
                        radius: 4, backgroundColor: AppColors.success),
                    const SizedBox(width: 6),
                    Text(
                      isThinking
                          ? 'Momo is thinking...'
                          : 'Momo - powered by Gemini',
                      style:
                          const TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BuddyWelcome extends StatelessWidget {
  const _BuddyWelcome({required this.onSuggestion});

  final void Function([String? preset]) onSuggestion;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 30, 22, 18),
      child: Column(
        children: [
          const AiBuddy(size: 110, showGreeting: true),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SizedBox(
              width: double.infinity,
              child: Text(
                'Your AI career companion',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: const Text(
              'Your friendly AI career buddy. Let\'s make resumes sharper, interviews calmer, and your next step clearer.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, height: 1.5),
            ),
          ),
          const SizedBox(height: 24),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: _AiChatScreenState._suggestions.map((suggestion) {
                return ActionChip(
                  avatar: const Icon(Icons.auto_awesome_rounded, size: 16),
                  label: Text(suggestion.$1),
                  onPressed: () => onSuggestion(suggestion.$2),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.author == MessageAuthor.user;
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            const AiBuddy(size: 34),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 570),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              decoration: BoxDecoration(
                gradient: isUser
                    ? const LinearGradient(
                        colors: [AppColors.primary, Color(0xFF168FF5)])
                    : null,
                color: isUser ? null : Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(19),
                  topRight: const Radius.circular(19),
                  bottomLeft: Radius.circular(isUser ? 19 : 5),
                  bottomRight: Radius.circular(isUser ? 5 : 19),
                ),
                border: isUser ? null : Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.text.isNotEmpty)
                    Text(
                      message.text,
                      style: TextStyle(
                        color: isUser ? Colors.white : AppColors.ink,
                        height: 1.48,
                      ),
                    ),
                  if (message.attachments.isNotEmpty) ...[
                    if (message.text.isNotEmpty) const SizedBox(height: 10),
                    ...message.attachments.map(
                      (attachment) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: _MessageAttachment(
                          attachment: attachment,
                          light: isUser,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageAttachment extends StatelessWidget {
  const _MessageAttachment({required this.attachment, required this.light});

  final ChatAttachment attachment;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: light ? Colors.white.withOpacity(0.15) : const Color(0xFFF1F6FF),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            attachment.kind == ChatAttachmentKind.image
                ? Icons.image_outlined
                : Icons.description_outlined,
            color: light ? Colors.white : AppColors.primary,
            size: 19,
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              attachment.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: light ? Colors.white : AppColors.ink,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AiBuddy(size: 34, isThinking: true),
          SizedBox(width: 8),
          Card(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentOption extends StatelessWidget {
  const _AttachmentOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 27),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }
}
