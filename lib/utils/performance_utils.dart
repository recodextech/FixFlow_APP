import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Small LRU cache of decoded base64 images, so rebuilds don't re-decode the
/// same payload. Bounded so photos from screens left long ago are released.
class Base64ImageCache {
  static const int maxEntries = 20;

  static final Base64ImageCache _instance = Base64ImageCache._internal();
  final LinkedHashMap<String, Uint8List> _decodedImages = LinkedHashMap();

  factory Base64ImageCache() => _instance;
  Base64ImageCache._internal();

  static final RegExp _dataUriPrefix = RegExp(
    r'^data:(image|application)/[^;]+;base64,',
  );

  String _normalizeBase64(String raw) {
    final trimmed = raw.trim();
    final dataUriMatch = _dataUriPrefix.firstMatch(trimmed);

    if (dataUriMatch != null) {
      return trimmed.substring(dataUriMatch.end);
    }

    return trimmed;
  }

  /// Get or decode base64 image bytes, cached for performance.
  Uint8List? decodeBase64(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;

    final normalized = _normalizeBase64(base64String);
    if (normalized.isEmpty) return null;

    final cached = _decodedImages.remove(normalized);
    if (cached != null) {
      // Re-insert to mark as most recently used.
      _decodedImages[normalized] = cached;
      return cached;
    }

    try {
      final bytes = base64Decode(normalized);
      _decodedImages[normalized] = bytes;
      if (_decodedImages.length > maxEntries) {
        _decodedImages.remove(_decodedImages.keys.first);
      }
      return bytes;
    } catch (_) {
      return null;
    }
  }

  /// Clear cache to free memory when needed.
  void clear() => _decodedImages.clear();

  /// Get current cache size (for debugging).
  int get cacheSize => _decodedImages.length;
}

/// Utility for performance-conscious widgets.
class PerformanceUtils {
  static final Base64ImageCache imageCache = Base64ImageCache();

  /// Decode base64 image with caching.
  static Uint8List? decodeImage(String? base64String) {
    return imageCache.decodeBase64(base64String);
  }

  /// Image provider decoded at [logicalWidth] instead of the photo's full
  /// resolution. The same bytes give an equal [MemoryImage], so Flutter's
  /// image cache reuses the decoded frame across rebuilds.
  static ImageProvider? getImageProvider(
    String? base64String, {
    required double logicalWidth,
    required double devicePixelRatio,
  }) {
    final bytes = decodeImage(base64String);
    if (bytes == null) return null;
    return ResizeImage.resizeIfNeeded(
      _decodeWidth(logicalWidth, devicePixelRatio),
      null,
      MemoryImage(bytes),
    );
  }

  static int? _decodeWidth(double? logicalWidth, double devicePixelRatio) {
    if (logicalWidth == null || !logicalWidth.isFinite || logicalWidth <= 0) {
      return null;
    }
    return (logicalWidth * devicePixelRatio).ceil();
  }

  /// Clear all caches.
  static void clearCaches() => imageCache.clear();
}

/// Wrapper for Image.memory with automatic caching and error handling.
class CachedMemoryImage extends StatelessWidget {
  final String? base64String;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;
  final Widget? placeholder;

  const CachedMemoryImage({
    super.key,
    required this.base64String,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.errorBuilder,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    final bytes = PerformanceUtils.decodeImage(base64String);

    if (bytes == null) {
      if (placeholder != null) {
        return placeholder!;
      }

      if (errorBuilder != null) {
        return errorBuilder!(
          context,
          Exception('Unable to decode image payload'),
          StackTrace.current,
        );
      }

      return Container(width: width, height: height, color: Colors.grey[200]);
    }

    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        // Decode at the box's longer side, not the photo's full resolution,
        // so cover-fit photos stay sharp whichever way they are cropped.
        final boxWidth = width ?? constraints.maxWidth;
        final boxHeight = height ?? constraints.maxHeight;
        final displayWidth = !boxHeight.isFinite || boxWidth >= boxHeight
            ? boxWidth
            : boxHeight;
        return Image.memory(
          bytes,
          fit: fit,
          width: width,
          height: height,
          cacheWidth: PerformanceUtils._decodeWidth(
            displayWidth,
            devicePixelRatio,
          ),
          errorBuilder: errorBuilder,
        );
      },
    );
  }
}

/// Wrapper for CircleAvatar with cached image.
class CachedCircleAvatar extends StatelessWidget {
  final String? base64String;
  final double radius;
  final Widget? child;
  final Color? backgroundColor;

  const CachedCircleAvatar({
    super.key,
    required this.base64String,
    required this.radius,
    this.child,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final imageProvider = PerformanceUtils.getImageProvider(
      base64String,
      logicalWidth: radius * 2,
      devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
    );

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      backgroundImage: imageProvider,
      child: imageProvider == null ? child : null,
    );
  }
}
