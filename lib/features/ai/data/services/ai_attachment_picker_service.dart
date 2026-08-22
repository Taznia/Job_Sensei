import 'package:file_picker/file_picker.dart';

import '../../../../core/media/app_image_picker.dart';
import '../../../../shared/models/chat_message.dart';

abstract interface class AiAttachmentPickerService {
  Future<List<PendingChatAttachment>> pickImages();

  Future<List<PendingChatAttachment>> pickCamera();

  Future<List<PendingChatAttachment>> pickDocuments();
}

class FilePickerAiAttachmentService implements AiAttachmentPickerService {
  @override
  Future<List<PendingChatAttachment>> pickImages() async {
    final images = await AppImagePicker.pickFromGallery();
    return images.map(_toAttachment).toList();
  }

  @override
  Future<List<PendingChatAttachment>> pickCamera() async {
    final images = await AppImagePicker.pickFromCamera();
    return images.map(_toAttachment).toList();
  }

  @override
  Future<List<PendingChatAttachment>> pickDocuments() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'txt', 'doc', 'docx'],
      withData: true,
    );
    if (result == null) return const [];

    return result.files.map((file) {
      return PendingChatAttachment(
        name: file.name,
        mimeType: _documentMime(file.extension),
        kind: ChatAttachmentKind.document,
        sizeBytes: file.size,
        localPath: file.path,
        bytes: file.bytes,
      );
    }).toList();
  }

  PendingChatAttachment _toAttachment(PickedAppImage image) {
    return PendingChatAttachment(
      name: image.name,
      mimeType: image.mimeType,
      kind: ChatAttachmentKind.image,
      sizeBytes: image.sizeBytes,
      localPath: image.localPath,
      bytes: image.bytes,
    );
  }

  String _documentMime(String? extension) {
    return switch (extension?.toLowerCase()) {
      'pdf' => 'application/pdf',
      'txt' => 'text/plain',
      'doc' => 'application/msword',
      'docx' =>
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      _ => 'application/octet-stream',
    };
  }
}
