import 'package:file_picker/file_picker.dart';

import '../../../../shared/models/chat_message.dart';

abstract interface class AiAttachmentPickerService {
  Future<List<PendingChatAttachment>> pickImages();

  Future<List<PendingChatAttachment>> pickDocuments();
}

class FilePickerAiAttachmentService implements AiAttachmentPickerService {
  @override
  Future<List<PendingChatAttachment>> pickImages() {
    return _pick(kind: ChatAttachmentKind.image, type: FileType.image);
  }

  @override
  Future<List<PendingChatAttachment>> pickDocuments() {
    return _pick(
      kind: ChatAttachmentKind.document,
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'txt', 'doc', 'docx'],
    );
  }

  Future<List<PendingChatAttachment>> _pick({
    required ChatAttachmentKind kind,
    required FileType type,
    List<String>? allowedExtensions,
  }) async {
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: type,
      allowedExtensions: allowedExtensions,
      withData: true,
    );
    if (result == null) return const [];

    return result.files.map((file) {
      return PendingChatAttachment(
        name: file.name,
        mimeType: _mimeType(file.extension, kind),
        kind: kind,
        sizeBytes: file.size,
        localPath: file.path,
        bytes: file.bytes,
      );
    }).toList();
  }

  String _mimeType(String? extension, ChatAttachmentKind kind) {
    return switch (extension?.toLowerCase()) {
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      'pdf' => 'application/pdf',
      'txt' => 'text/plain',
      'doc' => 'application/msword',
      'docx' =>
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      _ when kind == ChatAttachmentKind.image => 'image/jpeg',
      _ => 'application/octet-stream',
    };
  }
}
