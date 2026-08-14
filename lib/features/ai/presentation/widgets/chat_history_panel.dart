import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/models/chat_message.dart';
import 'ai_buddy.dart';

class ChatHistoryPanel extends StatelessWidget {
  const ChatHistoryPanel({
    super.key,
    required this.conversations,
    required this.activeConversationId,
    required this.onNewChat,
    required this.onSelect,
    required this.onDelete,
  });

  final List<ChatConversation> conversations;
  final String? activeConversationId;
  final VoidCallback onNewChat;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A2F69), Color(0xFF0B57D0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 18, 18, 14),
              child: Row(
                children: [
                  AiBuddy(size: 42),
                  SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Momo',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Your AI career buddy',
                          overflow: TextOverflow.ellipsis,
                          style:
                              TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onNewChat,
                  icon: const Icon(Icons.add_comment_outlined),
                  label: const Text('New chat'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryDark,
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 22, 18, 8),
              child: Text(
                'CHAT HISTORY',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.3,
                ),
              ),
            ),
            Expanded(
              child: conversations.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(18),
                      child: Text(
                        'Your previous conversations will appear here.',
                        style: TextStyle(color: Colors.white60),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 20),
                      itemCount: conversations.length,
                      itemBuilder: (context, index) {
                        final conversation = conversations[index];
                        final selected =
                            conversation.id == activeConversationId;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Material(
                            color: selected
                                ? Colors.white.withOpacity(0.16)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(13),
                            child: ListTile(
                              dense: true,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13),
                              ),
                              onTap: () => onSelect(conversation.id),
                              leading: Icon(
                                Icons.chat_bubble_outline_rounded,
                                color: selected ? Colors.white : Colors.white60,
                                size: 19,
                              ),
                              title: Text(
                                conversation.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color:
                                      selected ? Colors.white : Colors.white70,
                                  fontWeight: selected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                              subtitle: Text(
                                _dateLabel(conversation.updatedAt),
                                style: const TextStyle(
                                    color: Colors.white38, fontSize: 9),
                              ),
                              trailing: IconButton(
                                tooltip: 'Delete chat',
                                onPressed: () => onDelete(conversation.id),
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.white54,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 10, 18, 18),
              child: Row(
                children: [
                  Icon(Icons.shield_outlined, color: Colors.white54, size: 16),
                  SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'Career guidance, not a hiring guarantee',
                      style: TextStyle(color: Colors.white54, fontSize: 9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _dateLabel(DateTime value) {
    final days = DateTime.now().difference(value).inDays;
    if (days <= 0) return 'Today';
    if (days == 1) return 'Yesterday';
    return '$days days ago';
  }
}
