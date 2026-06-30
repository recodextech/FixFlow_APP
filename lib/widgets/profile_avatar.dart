
import 'package:flutter/material.dart';
import '../models/job_images.dart';
import '../services/api_service.dart';
import '../services/preferences_service.dart';
import '../utils/performance_utils.dart';

class ProfileAvatar extends StatefulWidget {
  final String id;
  final bool isWorker;
  final double radius;

  const ProfileAvatar({super.key, required this.id, this.isWorker = true, this.radius = 20});

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  ImageItem? _item;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Only use locally saved profile photo when it belongs to the requested id.
    final prefs = PreferencesService();
    final prefsPhoto = widget.isWorker
        ? (prefs.getWorkerId() == widget.id ? prefs.getWorkerPhotoBase64() : null)
        : (prefs.getContractorId() == widget.id ? prefs.getContractorPhotoBase64() : null);

    if (prefsPhoto != null && prefsPhoto.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        _item = ImageItem(url: '', data: prefsPhoto);
        _loading = false;
      });
      return;
    }

    try {
      final accountId = prefs.getAccountId();
      final item = widget.isWorker
          ? await ApiService().getWorkerProfilePicture(workerId: widget.id, accountId: accountId)
          : await ApiService().getContractorProfilePicture(contractorId: widget.id, accountId: accountId);
      if (!mounted) return;
      setState(() {
        _item = item;
      });
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.radius;
    if (_loading) {
      return CircleAvatar(
        radius: r,
        backgroundColor: Colors.grey[200],
        child: const SizedBox.shrink(),
      );
    }

    if (_item == null || _item!.data.isEmpty) {
      return CircleAvatar(
        radius: r,
        backgroundColor: Colors.grey[200],
        child: Icon(widget.isWorker ? Icons.person : Icons.business, size: r),
      );
    }

    // Use cached circle avatar with base64 image
    return CachedCircleAvatar(
      base64String: _item!.data,
      radius: r,
      backgroundColor: Colors.grey[200],
      child: Icon(widget.isWorker ? Icons.person : Icons.business, size: r),
    );
  }
}
