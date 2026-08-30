import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/community_models.dart';
import 'community_visuals.dart';

class PostAttachmentTile extends StatelessWidget {
  const PostAttachmentTile({super.key, required this.attachment});

  final CommunityAttachment attachment;

  @override
  Widget build(BuildContext context) {
    final isImage = attachment.isImage;
    final color = isImage ? AppColors.primary : AppColors.violet;
    return Material(
      color: color.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openCommunityAttachment(context, attachment),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isImage)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: ColoredBox(
                  color: color.withValues(alpha: 0.08),
                  child: AttachmentPreview(
                    attachment: attachment,
                    fit: BoxFit.cover,
                    placeholder: Icon(
                      Icons.image_outlined,
                      color: color,
                      size: 36,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(11),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      isImage
                          ? Icons.image_outlined
                          : Icons.description_outlined,
                      color: color,
                      size: 21,
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
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          isImage
                              ? 'Tap to open image'
                              : 'Tap to open ${CommunityVisuals.fileSize(attachment.sizeBytes)}',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.open_in_new_rounded, size: 17, color: color),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AttachmentPreview extends StatefulWidget {
  const AttachmentPreview({
    super.key,
    required this.attachment,
    this.fit = BoxFit.contain,
    this.placeholder,
  });

  final CommunityAttachment attachment;
  final BoxFit fit;
  final Widget? placeholder;

  @override
  State<AttachmentPreview> createState() => _AttachmentPreviewState();
}

class _AttachmentPreviewState extends State<AttachmentPreview> {
  late Future<ImageProvider?> _future = _load();

  @override
  void didUpdateWidget(covariant AttachmentPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.attachment.id != widget.attachment.id ||
        oldWidget.attachment.url != widget.attachment.url ||
        oldWidget.attachment.localPath != widget.attachment.localPath) {
      _future = _load();
    }
  }

  Future<ImageProvider?> _load() {
    return loadAttachmentImage(widget.attachment);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ImageProvider?>(
      future: _future,
      builder: (context, snapshot) {
        final image = snapshot.data;
        if (image == null) {
          return Center(child: widget.placeholder ?? const SizedBox.shrink());
        }
        return Image(
          image: image,
          fit: widget.fit,
          errorBuilder: (_, __, ___) =>
              Center(child: widget.placeholder ?? const SizedBox.shrink()),
        );
      },
    );
  }
}

Future<void> openCommunityAttachment(
  BuildContext context,
  CommunityAttachment attachment,
) async {
  if (attachment.isImage) {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _AttachmentImageScreen(attachment: attachment),
        fullscreenDialog: true,
      ),
    );
    return;
  }

  final uri = resolveAttachmentUri(attachment.url);
  if (uri != null) {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      _attachmentMessage(context, 'Could not open that file.');
    }
    return;
  }

  final path = attachment.localPath?.trim();
  if (path != null && path.isNotEmpty) {
    final opened = await launchUrl(
      Uri.file(path),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      _attachmentMessage(context, 'Could not open that file.');
    }
    return;
  }

  if (context.mounted) {
    _attachmentMessage(context, 'This file is not available to open.');
  }
}

void _attachmentMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

Uri? resolveAttachmentUri(String? url) {
  final raw = url?.trim();
  if (raw == null || raw.isEmpty) return null;
  final parsed = Uri.tryParse(raw);
  if (parsed == null) return null;
  if (parsed.hasScheme) return parsed;
  final base = Uri.parse(AppConstants.apiBaseUrl);
  if (raw.startsWith('/')) {
    return Uri(
      scheme: base.scheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: raw,
    );
  }
  return base.resolve(raw);
}

Future<ImageProvider?> loadAttachmentImage(CommunityAttachment attachment) async {
  final bytes = attachment.bytes;
  if (bytes != null && bytes.isNotEmpty) return MemoryImage(bytes);

  final uri = resolveAttachmentUri(attachment.url);
  if (uri != null) return NetworkImage(uri.toString());

  final path = attachment.localPath?.trim();
  if (path == null || path.isEmpty) return null;
  try {
    final data = await XFile(path).readAsBytes();
    if (data.isEmpty) return null;
    return MemoryImage(data);
  } catch (_) {
    return null;
  }
}

class _AttachmentImageScreen extends StatelessWidget {
  const _AttachmentImageScreen({required this.attachment});

  final CommunityAttachment attachment;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1220),
        foregroundColor: Colors.white,
        title: Text(attachment.name, overflow: TextOverflow.ellipsis),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: AttachmentPreview(
            attachment: attachment,
            placeholder: const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Could not load this image.',
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
