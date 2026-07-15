import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Image cache to avoid repeated base64 decoding and memory image creation.
class ImageCache {
  static final ImageCache _instance = ImageCache._internal();
  final Map<String, Uint8List> _decodedImages = {};
  final Map<String, MemoryImage> _memoryImages = {};

  factory ImageCache() => _instance;
  ImageCache._internal();

  String _normalizeBase64(String raw) {
    final trimmed = raw.trim();
    final dataUriMatch = RegExp(
      r'^data:(image|application)/[^;]+;base64,',
    ).firstMatch(trimmed);

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

    if (_decodedImages.containsKey(normalized)) {
      return _decodedImages[normalized];
    }

    try {
      final bytes = base64Decode(normalized);
      _decodedImages[normalized] = bytes;
      return bytes;
    } catch (_) {
      return null;
    }
  }

  /// Get or create MemoryImage from base64, cached for performance.
  MemoryImage? getMemoryImage(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;

    final normalized = _normalizeBase64(base64String);
    if (normalized.isEmpty) return null;

    if (_memoryImages.containsKey(normalized)) {
      return _memoryImages[normalized];
    }

    final bytes = decodeBase64(normalized);
    if (bytes == null) return null;

    final image = MemoryImage(bytes);
    _memoryImages[normalized] = image;
    return image;
  }

  /// Clear cache to free memory when needed.
  void clear() {
    _decodedImages.clear();
    _memoryImages.clear();
  }

  /// Get current cache size (for debugging).
  int get cacheSize => _decodedImages.length + _memoryImages.length;
}

/// Memoized gradient builder to avoid recreating gradients.
class GradientCache {
  static final GradientCache _instance = GradientCache._internal();
  final Map<String, LinearGradient> _gradients = {};

  factory GradientCache() => _instance;
  GradientCache._internal();

  LinearGradient getLinearGradient({
    required String key,
    required Alignment begin,
    required Alignment end,
    required List<Color> colors,
  }) {
    if (_gradients.containsKey(key)) {
      return _gradients[key]!;
    }

    final gradient = LinearGradient(begin: begin, end: end, colors: colors);
    _gradients[key] = gradient;
    return gradient;
  }

  void clear() => _gradients.clear();
}

/// Utility for performance-conscious widgets.
class PerformanceUtils {
  static final ImageCache imageCache = ImageCache();
  static final GradientCache gradientCache = GradientCache();

  /// Decode base64 image with caching.
  static Uint8List? decodeImage(String? base64String) {
    return imageCache.decodeBase64(base64String);
  }

  /// Get MemoryImage provider with caching.
  static MemoryImage? getImageProvider(String? base64String) {
    return imageCache.getMemoryImage(base64String);
  }

  /// Clear all caches.
  static void clearCaches() {
    imageCache.clear();
    gradientCache.clear();
  }
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

    return Image.memory(
      bytes,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: errorBuilder,
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
    final imageProvider = PerformanceUtils.getImageProvider(base64String);

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      backgroundImage: imageProvider,
      child: imageProvider == null ? child : null,
    );
  }
}
