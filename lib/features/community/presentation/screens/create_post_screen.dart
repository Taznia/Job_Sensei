import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../shared/models/community_models.dart';
import '../../data/services/attachment_picker_service.dart';
import '../widgets/community_visuals.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({
    super.key,
    this.communityId,
    this.communityName,
    this.attachmentPicker,
  });

  final String? communityId;
  final String? communityName;
  final AttachmentPickerService? attachmentPicker;

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  late final AttachmentPickerService _attachmentPicker =
      widget.attachmentPicker ?? FilePickerAttachmentService();
  final _formKey = GlobalKey<FormState>();
  final _bodyController = TextEditingController();
  final _attachments = <PendingAttachment>[];
  String _type = 'Question';
  bool _pickingFile = false;

  static const _maxAttachments = 5;
  static const _maxFileSize = 10 * 1000 * 1000;

  @override
  void dispose() {
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _pick(AttachmentKind kind) async {
    if (_attachments.length >= _maxAttachments || _pickingFile) return;
    setState(() => _pickingFile = true);
    try {
      final picked = kind == AttachmentKind.image
          ? await _attachmentPicker.pickImages()
          : await _attachmentPicker.pickDocuments();
      if (!mounted || picked.isEmpty) {
        return;
      }

      final oversized = picked.where((file) => file.sizeBytes > _maxFileSize);
      final valid = picked.where((file) => file.sizeBytes <= _maxFileSize);
      final remaining = _maxAttachments - _attachments.length;
      setState(() => _attachments.addAll(valid.take(remaining)));

      if (oversized.isNotEmpty) {
        _showMessage('Files larger than 10 MB were not added.');
      } else if (valid.length > remaining) {
        _showMessage('You can attach up to $_maxAttachments files.');
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Could not access that file. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _pickingFile = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _publish() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      CreatePostRequest(
        body: _bodyController.text.trim(),
        type: _type,
        communityId: widget.communityId,
        communityName: widget.communityName,
        attachments: List.unmodifiable(_attachments),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create post'),
        actions: [
          TextButton(
            onPressed: _publish,
            child: const Text('Publish'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 32),
          children: [
            ScreenIntro(
              eyebrow: widget.communityName ?? 'Community discussion',
              title: 'Share something useful',
              description:
                  'Ask a focused question, share a resource, or start a thoughtful career conversation.',
            ),
            const SizedBox(height: 22),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _type,
                      decoration: const InputDecoration(
                        labelText: 'Post type',
                        prefixIcon: Icon(Icons.forum_outlined),
                      ),
                      items: const [
                        'Question',
                        'Resource',
                        'Experience',
                        'Career update',
                      ]
                          .map((value) => DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => _type = value!),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _bodyController,
                      maxLines: 8,
                      minLines: 5,
                      autofocus: true,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'What would you like to discuss?',
                        hintText: 'Add enough context so others can help…',
                        alignLabelWithHint: true,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().length < 15) {
                          return 'Please add at least 15 characters.';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Text('Attachments',
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Text(
                  '${_attachments.length}/$_maxAttachments',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 5),
            const Text(
              'Add images, PDFs, Word documents, text files, or presentations up to 10 MB each.',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _AttachmentButton(
                    icon: Icons.add_photo_alternate_outlined,
                    label: 'Photo',
                    color: AppColors.primary,
                    enabled:
                        !_pickingFile && _attachments.length < _maxAttachments,
                    onPressed: () => _pick(AttachmentKind.image),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _AttachmentButton(
                    icon: Icons.attach_file_rounded,
                    label: 'Document',
                    color: AppColors.violet,
                    enabled:
                        !_pickingFile && _attachments.length < _maxAttachments,
                    onPressed: () => _pick(AttachmentKind.document),
                  ),
                ),
              ],
            ),
            if (_pickingFile) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(minHeight: 3),
            ],
            if (_attachments.isNotEmpty) ...[
              const SizedBox(height: 14),
              ..._attachments.indexed.map((entry) {
                final (index, attachment) = entry;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: _PendingAttachmentTile(
                    attachment: attachment,
                    onRemove: () =>
                        setState(() => _attachments.removeAt(index)),
                  ),
                );
              }),
            ],
            const SizedBox(height: 26),
            FilledButton.icon(
              onPressed: _publish,
              icon: const Icon(Icons.send_rounded),
              label: const Text('Publish post'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachmentButton extends StatelessWidget {
  const _AttachmentButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, color: enabled ? color : null),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 52),
        side: BorderSide(
            color: enabled ? color.withOpacity(0.35) : AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }
}

class _PendingAttachmentTile extends StatelessWidget {
  const _PendingAttachmentTile(
      {required this.attachment, required this.onRemove});

  final PendingAttachment attachment;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final isImage = attachment.kind == AttachmentKind.image;
    final color = isImage ? AppColors.primary : AppColors.violet;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              isImage ? Icons.image_outlined : Icons.description_outlined,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  CommunityVisuals.fileSize(attachment.sizeBytes),
                  style: const TextStyle(color: AppColors.muted, fontSize: 10),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove attachment',
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded, size: 19),
          ),
        ],
      ),
    );
  }
}
