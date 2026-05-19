import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

/// Picks images from camera/gallery and prepares compressed JPEG bytes for API payloads.
///
/// On iOS/Android, [flutter_image_compress] is used to shrink file size. On web,
/// [XFile.readAsBytes] is used (no native compress in this path).
class JobPhotoUpload {
  JobPhotoUpload._();

  static final ImagePicker _picker = ImagePicker();

  /// Maximum number of photos attached to one job.
  static const int maxPhotosPerJob = 8;

  /// Longer edge cap before/after compress (picker also pre-scales).
  static const int maxEdgePixels = 1600;

  /// JPEG quality (0–100) after resize.
  static const int jpegQuality = 78;

  /// Opens system picker; returns `null` if cancelled.
  static Future<XFile?> pickXFile(ImageSource source) {
    return _picker.pickImage(
      source: source,
      maxWidth: maxEdgePixels.toDouble(),
      maxHeight: maxEdgePixels.toDouble(),
      imageQuality: 88,
    );
  }

  /// Compresses to JPEG when a file path exists; otherwise returns raw bytes.
  static Future<Uint8List?> preparePhotoBytes(XFile file) async {
    if (kIsWeb) {
      return file.readAsBytes();
    }
    final path = file.path;
    if (path.isEmpty) {
      return file.readAsBytes();
    }
    final compressed = await FlutterImageCompress.compressWithFile(
      path,
      minWidth: maxEdgePixels,
      minHeight: maxEdgePixels,
      quality: jpegQuality,
      format: CompressFormat.jpeg,
      keepExif: false,
    );
    return compressed ?? await file.readAsBytes();
  }

  /// Convenience for JSON: standard Base64 (no `data:` prefix), MIME implied as image/jpeg.
  static String toBase64(Uint8List bytes) => base64Encode(bytes);

  /// Picks one photo and returns JPEG-ready bytes, or `null` if cancelled / empty.
  static Future<Uint8List?> pickAndPrepare(ImageSource source) async {
    final x = await pickXFile(source);
    if (x == null) return null;
    return preparePhotoBytes(x);
  }
}
