import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

class PickedAppImage {
  const PickedAppImage({
    required this.name,
    required this.mimeType,
    required this.sizeBytes,
    required this.bytes,
    this.localPath,
  });

  final String name;
  final String mimeType;
  final int sizeBytes;
  final Uint8List bytes;
  final String? localPath;
}

abstract final class AppImagePicker {
  static final ImagePicker _picker = ImagePicker();

  static Future<List<PickedAppImage>> pickFromGallery() async {
    final files = await _picker.pickMultiImage(
      imageQuality: 88,
      maxWidth: 2048,
    );
    return _readAll(files);
  }

  static Future<List<PickedAppImage>> pickFromCamera() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 88,
      maxWidth: 2048,
    );
    if (file == null) return const [];
    return _readAll([file]);
  }

  static Future<List<PickedAppImage>> _readAll(List<XFile> files) async {
    final images = <PickedAppImage>[];
    for (final file in files) {
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) continue;
      images.add(
        PickedAppImage(
          name: file.name.isEmpty ? 'photo.jpg' : file.name,
          mimeType: _mimeType(file.mimeType, file.name),
          sizeBytes: bytes.length,
          bytes: bytes,
          localPath: file.path,
        ),
      );
    }
    return images;
  }

  static String _mimeType(String? mimeType, String name) {
    if (mimeType != null && mimeType.startsWith('image/')) return mimeType;
    final ext = name.split('.').last.toLowerCase();
    return switch (ext) {
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      'heic' => 'image/heic',
      _ => 'image/jpeg',
    };
  }
}
