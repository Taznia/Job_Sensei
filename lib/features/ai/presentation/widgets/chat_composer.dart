import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/models/chat_message.dart';

class ChatComposer extends StatelessWidget {
  const ChatComposer({
    super.key,
    required this.controller,
    required this.enabled,
    required this.attachments,
    required this.onAttach,
    required this.onRemoveAttachment,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool enabled;
  final List<PendingChatAttachment> attachments;
  final VoidCallback onAttach;
  final ValueChanged<int> onRemoveAttachment;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        14,
        9,
        14,
        10 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        border: const Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (attachments.isNotEmpty) ...[
            SizedBox(
              height: 58,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: attachments.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) => _AttachmentDraft(
                  attachment: attachments[index],
                  onRemove: () => onRemoveAttachment(index),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withOpacity(0.18)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 5, bottom: 4),
                  child: IconButton(
                    tooltip: 'Attach a file',
                    onPressed: enabled ? onAttach : null,
                    icon: const Icon(Icons.attach_file_rounded),
                    color: AppColors.primary,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    enabled: enabled,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 4,
                    minLines: 1,
                    onSubmitted: (_) => onSend(),
                    decoration: const InputDecoration(
                      hintText: 'Ask Momo about your career...',
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(7, 6, 7, 6),
                  child: IconButton.filled(
                    tooltip: 'Send message',
                    onPressed: enabled ? onSend : null,
                    icon: const Icon(Icons.arrow_upward_rounded),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(43, 43),
                      backgroundColor: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Momo can make mistakes. Verify important career information.',
            style: TextStyle(color: AppColors.muted, fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _AttachmentDraft extends StatelessWidget {
  const _AttachmentDraft({required this.attachment, required this.onRemove});

  final PendingChatAttachment attachment;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final isImage = attachment.kind == ChatAttachmentKind.image;
    final color = isImage ? AppColors.primary : AppColors.violet;
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.fromLTRB(9, 7, 3, 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isImage ? Icons.image_outlined : Icons.description_outlined,
            color: color,
            size: 21,
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 11),
                ),
                Text(
                  _fileSize(attachment.sizeBytes),
                  style: const TextStyle(color: AppColors.muted, fontSize: 9),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove attachment',
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded, size: 17),
          ),
        ],
      ),
    );
  }

  String _fileSize(int bytes) {
    if (bytes >= 1000000) return '${(bytes / 1000000).toStringAsFixed(1)} MB';
    return '${(bytes / 1000).toStringAsFixed(0)} KB';
  }
}
