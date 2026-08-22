import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/media/app_image_picker.dart';
import '../../../../shared/models/community_models.dart';

abstract interface class AttachmentPickerService {
  Future<List<PendingAttachment>> pickImages();

  Future<List<PendingAttachment>> pickCamera();

  Future<List<PendingAttachment>> pickDocuments();
}

class FilePickerAttachmentService implements AttachmentPickerService {
  @override
  Future<List<PendingAttachment>> pickImages() async {
    final images = await AppImagePicker.pickFromGallery();
    return images.map(_toAttachment).toList();
  }

  @override
  Future<List<PendingAttachment>> pickCamera() async {
    final images = await AppImagePicker.pickFromCamera();
    return images.map(_toAttachment).toList();
  }

  @override
  Future<List<PendingAttachment>> pickDocuments() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'doc', 'docx', 'txt', 'ppt', 'pptx'],
      withData: kIsWeb,
    );
    if (result == null) return const [];

    return result.files
        .map(
          (file) => PendingAttachment(
            name: file.name,
            kind: AttachmentKind.document,
            sizeBytes: file.size,
            extension: file.extension,
            localPath: file.path,
            bytes: file.bytes,
          ),
        )
        .toList();
  }

  PendingAttachment _toAttachment(PickedAppImage image) {
    return PendingAttachment(
      name: image.name,
      kind: AttachmentKind.image,
      sizeBytes: image.sizeBytes,
      extension: image.name.split('.').last,
      localPath: image.localPath,
      bytes: image.bytes,
    );
  }
}
