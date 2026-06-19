import 'package:flutter/material.dart';
import '../models/job_images.dart';
import '../services/api_service.dart';
import '../services/preferences_service.dart';
import '../utils/performance_utils.dart';

class JobImagesWidget extends StatefulWidget {
  final String jobId;
  final double height;

  const JobImagesWidget({super.key, required this.jobId, this.height = 150});

  @override
  State<JobImagesWidget> createState() => _JobImagesWidgetState();
}

class _JobImagesWidgetState extends State<JobImagesWidget> {
  List<ImageItem> _images = [];
  int _index = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final accountId = PreferencesService().getAccountId();
      final resp = await ApiService().getJobImages(jobId: widget.jobId, accountId: accountId ?? '');
      setState(() {
        _images = resp.images;
        _index = 0;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _next() {
    if (_images.isEmpty) return;
    setState(() => _index = (_index + 1) % _images.length);
  }

  void _previous() {
    if (_images.isEmpty) return;
    setState(() => _index = (_index - 1 + _images.length) % _images.length);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return SizedBox(
        height: widget.height,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return SizedBox(
        height: widget.height,
        child: const Center(child: Text('Images not available')),
      );
    }

    if (_images.isEmpty) {
      return const SizedBox.shrink();
    }

    final current = _images[_index];

    return SizedBox(
      height: widget.height,
      child: GestureDetector(
        onTap: _next,
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity == null) return;
          if (details.primaryVelocity! < 0) {
            _next();
          } else if (details.primaryVelocity! > 0) {
            _previous();
          }
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedMemoryImage(
                base64String: current.data,
                fit: BoxFit.cover,
                placeholder: Container(
                  color: Colors.grey[200],
                  child: const Center(child: Text('Image unavailable')),
                ),
              ),
              _ImageOverlay(),
              _ImageCounter(index: _index, total: _images.length),
              _PreviousButton(onPressed: _previous),
              _NextButton(onPressed: _next),
              _ImageIndicators(
                currentIndex: _index,
                totalImages: _images.length,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageOverlay extends StatelessWidget {
  const _ImageOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.05),
            Colors.black.withValues(alpha: 0.18),
          ],
        ),
      ),
    );
  }
}

class _ImageCounter extends StatelessWidget {
  final int index;
  final int total;

  const _ImageCounter({required this.index, required this.total});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 8,
      top: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          '${index + 1}/$total',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _PreviousButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _PreviousButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 8,
      bottom: 8,
      child: IconButton(
        onPressed: onPressed,
        icon: const Icon(Icons.chevron_left_rounded, color: Colors.white),
        style: IconButton.styleFrom(
          backgroundColor: Colors.black.withValues(alpha: 0.35),
          padding: const EdgeInsets.all(6),
        ),
      ),
    );
  }
}

class _NextButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _NextButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 8,
      bottom: 8,
      child: IconButton(
        onPressed: onPressed,
        icon: const Icon(Icons.chevron_right_rounded, color: Colors.white),
        style: IconButton.styleFrom(
          backgroundColor: Colors.black.withValues(alpha: 0.35),
          padding: const EdgeInsets.all(6),
        ),
      ),
    );
  }
}

class _ImageIndicators extends StatelessWidget {
  final int currentIndex;
  final int totalImages;

  const _ImageIndicators({
    required this.currentIndex,
    required this.totalImages,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 10,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < totalImages; i++)
            _IndicatorDot(isActive: i == currentIndex),
        ],
      ),
    );
  }
}

class _IndicatorDot extends StatelessWidget {
  final bool isActive;

  const _IndicatorDot({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: isActive ? 14 : 6,
      height: 6,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}
