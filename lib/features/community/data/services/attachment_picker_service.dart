import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../../../../shared/models/community_models.dart';

abstract interface class AttachmentPickerService {
  Future<List<PendingAttachment>> pickImages();

  Future<List<PendingAttachment>> pickDocuments();
}

class FilePickerAttachmentService implements AttachmentPickerService {
  @override
  Future<List<PendingAttachment>> pickImages() {
    return _pick(
      kind: AttachmentKind.image,
      type: FileType.image,
    );
  }

  @override
  Future<List<PendingAttachment>> pickDocuments() {
    return _pick(
      kind: AttachmentKind.document,
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'doc', 'docx', 'txt', 'ppt', 'pptx'],
    );
  }

  Future<List<PendingAttachment>> _pick({
    required AttachmentKind kind,
    required FileType type,
    List<String>? allowedExtensions,
  }) async {
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: type,
      allowedExtensions: allowedExtensions,
      withData: kIsWeb,
    );
    if (result == null) return const [];

    return result.files
        .map((file) => PendingAttachment(
              name: file.name,
              kind: kind,
              sizeBytes: file.size,
              extension: file.extension,
              localPath: file.path,
              bytes: file.bytes,
            ))
        .toList();
  }
}
