import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../models/job_images.dart';
import '../services/api_service.dart';
import '../services/preferences_service.dart';

class JobImagesWidget extends StatefulWidget {
  final String jobId;
  final double height;

  const JobImagesWidget({super.key, required this.jobId, this.height = 180});

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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return SizedBox(
        height: widget.height,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return SizedBox(
        height: widget.height,
        child: Center(child: Text('Images not available')),
      );
    }

    if (_images.isEmpty) {
      return const SizedBox.shrink();
    }

    final current = _images[_index];
    Uint8List? bytes;
    try {
      bytes = base64Decode(current.data);
    } catch (_) {
      bytes = null;
    }

    return SizedBox(
      height: widget.height,
      child: GestureDetector(
        onTap: _next,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: bytes == null
              ? Container(
                  color: Colors.grey[200],
                  child: Center(child: Text('Image unavailable')),
                )
              : Image.memory(bytes, fit: BoxFit.cover, width: double.infinity),
        ),
      ),
    );
  }
}
