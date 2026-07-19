import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/process.dart';
import '../models/worker.dart';
import '../services/api_service.dart';
import '../services/job_photo_upload.dart';
import '../theme.dart';
import 'location_picker_screen.dart';

class CreateProcessDialog extends StatefulWidget {
  final String contractorId;
  final String accountId;

  const CreateProcessDialog({
    super.key,
    required this.contractorId,
    required this.accountId,
  });

  @override
  State<CreateProcessDialog> createState() => _CreateProcessDialogState();
}

class _CreateProcessDialogState extends State<CreateProcessDialog> {
  static const LatLng _defaultLocation = LatLng(6.927079, 79.861244);
  static const double _mapZoom = 15.0;
  static final RegExp _jobStartFormat = RegExp(
    r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}$',
  );

  final _formKey = GlobalKey<FormState>();
  final _processNameController = TextEditingController();

  // Job fields
  final _jobDescriptionController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _durationController = TextEditingController();
  final _amountController = TextEditingController();
  final MapController _mapController = MapController();

  late Future<List<Category>> _categoriesFuture;
  String? _selectedParentType;
  String? _selectedCategoryId;
  String? _selectedWalletId;
  bool _isSubmitting = false;
  bool _isAddingJobPhoto = false;
  final List<Uint8List> _jobPhotoBytes = [];

  static const List<String> _parentTypeOrder = [
    'HOUSE_REPAIR',
    'GARDEN_WORKS',
    'MAINTENANCE',
  ];

  String _parentTypeLabel(String parentType) {
    switch (parentType) {
      case 'HOUSE_REPAIR':
        return 'House Repair';
      case 'GARDEN_WORKS':
        return 'Garden Works';
      case 'MAINTENANCE':
        return 'Maintenance';
      default:
        return parentType
            .replaceAll('_', ' ')
            .toLowerCase()
            .split(' ')
            .map(
              (word) => word.isEmpty
                  ? word
                  : '${word[0].toUpperCase()}${word.substring(1)}',
            )
            .join(' ');
    }
  }

  IconData _parentTypeIcon(String parentType) {
    switch (parentType) {
      case 'HOUSE_REPAIR':
        return Icons.home_repair_service;
      case 'GARDEN_WORKS':
        return Icons.grass;
      case 'MAINTENANCE':
        return Icons.settings;
      default:
        return Icons.category;
    }
  }

  Color _parentTypeColor(String parentType) {
    switch (parentType) {
      case 'HOUSE_REPAIR':
        return AppColors.green;
      case 'GARDEN_WORKS':
        return Colors.teal;
      case 'MAINTENANCE':
        return Colors.orange;
      default:
        return AppColors.green;
    }
  }

  void _toggleParentType(String parentType) {
    setState(() {
      _selectedParentType = _selectedParentType == parentType
          ? null
          : parentType;
    });
  }

  int _subcategoryCount(List<Category> categories, String parentType) {
    return categories.where((c) => c.parentType?.trim() == parentType).length;
  }

  List<Category> _categoriesForParent(
    List<Category> categories,
    String? parentType,
  ) {
    if (parentType == null) return const [];
    return categories.where((c) => c.parentType?.trim() == parentType).toList();
  }

  void _showCategoryDescription(Category category) {
    final description = category.description.trim();
    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No description available for this category.'),
        ),
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(category.name),
        content: Text(description),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryInfoButton(Category category) {
    return IconButton(
      tooltip: 'Category description',
      icon: const Icon(Icons.help_outline, size: 18, color: Colors.black54),
      splashRadius: 18,
      onPressed: () => _showCategoryDescription(category),
    );
  }

  Widget _buildParentTypeSelection(List<Category> categories) {
    return Row(
      children: _parentTypeOrder.map((parentType) {
        final count = _subcategoryCount(categories, parentType);
        final selected = _selectedParentType == parentType;
        final color = _parentTypeColor(parentType);

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: parentType == _parentTypeOrder.last ? 0 : 10,
            ),
            child: InkWell(
              onTap: count > 0 ? () => _toggleParentType(parentType) : null,
              borderRadius: BorderRadius.circular(14),
              child: Opacity(
                opacity: count > 0 ? 1 : 0.45,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? Color.lerp(Colors.white, color, 0.14)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected ? color : Colors.grey.shade300,
                      width: selected ? 1.8 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _parentTypeIcon(parentType),
                        color: selected ? color : Colors.black54,
                        size: 26,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _parentTypeLabel(parentType),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: selected ? color : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: selected ? color : Colors.black87,
                        ),
                      ),
                      Text(
                        'subcategories',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  LatLng _selectedLocation = _defaultLocation;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = ApiService().getCategories(accountId: widget.accountId);
    _loadCashWallet();
    _setInitialLocationFromDevice();
  }

  Future<void> _setInitialLocationFromDevice() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;
      final userLocation = LatLng(position.latitude, position.longitude);
      setState(() {
        _selectedLocation = userLocation;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _mapController.move(userLocation, _mapZoom);
      });
    } catch (_) {
      // Keep fallback Colombo location if device location is unavailable.
    }
  }

  Future<void> _loadCashWallet() async {
    final wallets = await ApiService().getWallets(accountId: widget.accountId);
    final cashWallet = wallets.firstWhere(
      (w) => w.type.toUpperCase() == 'CASH',
      orElse: () => wallets.isNotEmpty
          ? wallets.first
          : Wallet(id: '', type: 'CASH', balance: 0.0),
    );

    if (!mounted) return;

    setState(() {
      _selectedWalletId = cashWallet.id;
    });
  }

  /// Whole hours from [start] until midnight (end of that calendar day), capped at 12.
  int _maxDurationHoursForJobStart(DateTime start) {
    final endOfDay = DateTime(
      start.year,
      start.month,
      start.day,
    ).add(const Duration(days: 1));
    final wholeHours = endOfDay.difference(start).inMinutes ~/ 60;
    return min(12, wholeHours);
  }

  DateTime? _tryParseJobStart() {
    final t = _startTimeController.text.trim();
    if (!_jobStartFormat.hasMatch(t)) {
      return null;
    }
    return DateTime.tryParse(t);
  }

  void _clampDurationToJobStart() {
    final start = _tryParseJobStart();
    if (start == null) return;
    final maxH = _maxDurationHoursForJobStart(start);
    final d = int.tryParse(_durationController.text.trim());
    if (maxH < 1) {
      _durationController.clear();
      return;
    }
    if (d == null || d < 1) {
      _durationController.text = '1';
    } else if (d > maxH) {
      _durationController.text = maxH.toString();
    }
  }

  Future<void> _submitProcess() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select one category')),
      );
      return;
    }

    if (_selectedWalletId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a wallet')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final job = Job(
        description: _jobDescriptionController.text.trim(),
        startTime: _startTimeController.text.trim(),
        duration: int.parse(_durationController.text.trim()),
        latitude: _selectedLocation.latitude,
        longitude: _selectedLocation.longitude,
        jobCategories: [_selectedCategoryId!],
        paymentInformation: PaymentInformation(
          amount: double.parse(_amountController.text.trim()),
          walletId: _selectedWalletId!,
        ),
        photos: _jobPhotoBytes.map(JobPhotoUpload.toBase64).toList(),
      );

      final processRequest = ProcessRequest(
        name: _processNameController.text.trim(),
        jobs: [job],
      );

      await ApiService().createContractorProcess(
        contractorId: widget.contractorId,
        accountId: widget.accountId,
        processRequest: processRequest,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _selectStartTime() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final existing = _tryParseJobStart();
    var initialDate = existing ?? now;
    if (initialDate.isBefore(todayStart)) {
      initialDate = todayStart;
    }
    final initialTime = existing != null
        ? TimeOfDay.fromDateTime(existing)
        : TimeOfDay.now();

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: todayStart,
      lastDate: DateTime(now.year + 1, 12, 31),
    );

    if (date == null) return;
    if (!mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (time == null) return;

    final dateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    if (!mounted) return;
    setState(() {
      _startTimeController.text =
          '${dateTime.year.toString().padLeft(4, '0')}-'
          '${dateTime.month.toString().padLeft(2, '0')}-'
          '${dateTime.day.toString().padLeft(2, '0')} '
          '${dateTime.hour.toString().padLeft(2, '0')}:'
          '${dateTime.minute.toString().padLeft(2, '0')}';
      _clampDurationToJobStart();
    });
  }

  bool get _canCreateJob {
    final hasJobName = _processNameController.text.trim().isNotEmpty;
    final hasDescription = _jobDescriptionController.text.trim().isNotEmpty;
    final hasStartTime = _startTimeController.text.trim().isNotEmpty;
    final hasDuration =
        int.tryParse(_durationController.text.trim()) != null &&
        int.parse(_durationController.text.trim()) > 0;
    final hasCategory =
        _selectedCategoryId != null && _selectedCategoryId!.isNotEmpty;
    final hasWallet =
        _selectedWalletId != null && _selectedWalletId!.isNotEmpty;
    final hasAmount =
        double.tryParse(_amountController.text.trim()) != null &&
        double.parse(_amountController.text.trim()) > 0;

    return hasJobName &&
        hasDescription &&
        hasStartTime &&
        hasDuration &&
        hasCategory &&
        hasWallet &&
        hasAmount;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildSectionLabel('Job Details'),
                  const SizedBox(height: 12),
                  _buildJobFields(),
                  const SizedBox(height: 16),
                  _buildJobPhotosSection(),
                  const SizedBox(height: 12),
                  _buildSectionLabel('Job Location'),
                  const SizedBox(height: 12),
                  _buildLocationMap(),
                  const SizedBox(height: 12),
                  _buildCategoryDropdown(),
                  const SizedBox(height: 20),
                  _buildSectionLabel('Payment Details'),
                  const SizedBox(height: 12),
                  _buildAmountField(),
                  const SizedBox(height: 24),
                  _buildActions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Text(
      'Create Job',
      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildJobFields() {
    return Column(
      children: [
        TextFormField(
          controller: _processNameController,
          decoration: const InputDecoration(
            labelText: 'Job Name',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
          validator: (value) => (value == null || value.trim().isEmpty)
              ? 'Please enter job name'
              : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _jobDescriptionController,
          decoration: const InputDecoration(
            labelText: 'Job Description',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
          onChanged: (_) => setState(() {}),
          validator: (value) => (value == null || value.trim().isEmpty)
              ? 'Please enter job description'
              : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _startTimeController,
          readOnly: true,
          decoration: InputDecoration(
            labelText: 'Start Time',
            hintText: 'Pick date and time from calendar',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: _selectStartTime,
            ),
          ),
          onTap: _selectStartTime,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter start time';
            }
            final trimmed = value.trim();
            if (!_jobStartFormat.hasMatch(trimmed)) {
              return 'Use format: YYYY-MM-DDTHH:MM';
            }
            final start = DateTime.tryParse(trimmed);
            if (start == null) {
              return 'Invalid start date/time';
            }
            if (_maxDurationHoursForJobStart(start) < 1) {
              return 'Start is too late: no full hour remains before midnight';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        Builder(
          builder: (context) {
            final start = _tryParseJobStart();
            if (start == null) {
              return TextFormField(
                controller: _durationController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Duration (hours)',
                  hintText: 'Pick start date & time first',
                  border: OutlineInputBorder(),
                ),
                validator: (_) => null,
              );
            }
            final maxHours = _maxDurationHoursForJobStart(start);
            if (maxHours < 1) {
              return Text(
                'Not enough time before midnight for this start time. Pick an earlier start.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 13,
                ),
              );
            }
            final current = int.tryParse(_durationController.text.trim());
            if (current == null || current < 1 || current > maxHours) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!context.mounted) return;
                setState(_clampDurationToJobStart);
              });
            }
            final value = (int.tryParse(_durationController.text.trim()) ?? 1)
                .clamp(1, maxHours);
            return DropdownButtonFormField<int>(
              initialValue: value,
              decoration: const InputDecoration(
                labelText: 'Duration (hours, until midnight, max 12)',
                border: OutlineInputBorder(),
              ),
              items: List.generate(
                maxHours,
                (i) => DropdownMenuItem(
                  value: i + 1,
                  child: Text('${i + 1} hour${i == 0 ? '' : 's'}'),
                ),
              ),
              onChanged: (v) {
                if (v == null) return;
                setState(() => _durationController.text = v.toString());
              },
              validator: (_) {
                final d = int.tryParse(_durationController.text.trim());
                if (d == null || d < 1 || d > maxHours) {
                  return 'Choose a duration from 1 to $maxHours hour(s)';
                }
                return null;
              },
            );
          },
        ),
      ],
    );
  }

  Future<void> _showJobPhotoSourceSheet() async {
    if (_jobPhotoBytes.length >= JobPhotoUpload.maxPhotosPerJob) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You can attach at most ${JobPhotoUpload.maxPhotosPerJob} photos.',
          ),
        ),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take photo'),
              onTap: () {
                Navigator.pop(ctx);
                _addJobPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _addJobPhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addJobPhoto(ImageSource source) async {
    setState(() => _isAddingJobPhoto = true);
    try {
      final bytes = await JobPhotoUpload.pickAndPrepare(source);
      if (!mounted) return;
      if (bytes == null || bytes.isEmpty) return;
      if (_jobPhotoBytes.length >= JobPhotoUpload.maxPhotosPerJob) return;
      setState(() => _jobPhotoBytes.add(bytes));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not add photo: $e')));
    } finally {
      if (mounted) setState(() => _isAddingJobPhoto = false);
    }
  }

  void _removeJobPhoto(int index) {
    setState(() => _jobPhotoBytes.removeAt(index));
  }

  Widget _buildJobPhotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Job photos (optional)'),
        const SizedBox(height: 8),
        Text(
          'Up to ${JobPhotoUpload.maxPhotosPerJob} images, compressed as JPEG for smaller requests.',
          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._jobPhotoBytes.asMap().entries.map((e) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      e.value,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: -6,
                    right: -6,
                    child: Material(
                      color: Colors.black87,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => _removeJobPhoto(e.key),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
            if (_jobPhotoBytes.length < JobPhotoUpload.maxPhotosPerJob)
              Material(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: _isAddingJobPhoto ? null : _showJobPhotoSourceSheet,
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 72,
                    height: 72,
                    child: _isAddingJobPhoto
                        ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_a_photo_outlined, size: 28),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _openLocationPicker() async {
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            LocationPickerScreen(initialLocation: _selectedLocation),
      ),
    );
    if (result != null) {
      setState(() => _selectedLocation = result);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _mapController.move(result, _mapZoom);
      });
    }
  }

  Widget _buildLocationMap() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _openLocationPicker,
      child: SizedBox(
        height: 200,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              IgnorePointer(
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _selectedLocation,
                    initialZoom: _mapZoom,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.recodextech.fixflow_app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _selectedLocation,
                          width: 80.0,
                          height: 80.0,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.touch_app, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Tap to pick location',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return FutureBuilder<List<Category>>(
      future: _categoriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 60,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final categories = snapshot.data ?? [];
        if (categories.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Text('No categories available'),
          );
        }

        final availableCategories = categories;
        final parentCategories = _categoriesForParent(
          availableCategories,
          _selectedParentType,
        );
        final selectedCategory = availableCategories.where((category) {
          return category.id == _selectedCategoryId;
        }).toList();

        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.gray3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildParentTypeSelection(availableCategories),
                const SizedBox(height: 12),
                if (_selectedParentType == null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Text(
                      'Select a category type above to see subcategories.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_parentTypeLabel(_selectedParentType!)} Subcategories',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 180),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: parentCategories.length,
                          separatorBuilder: (_, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final category = parentCategories[index];
                            final selected = _selectedCategoryId == category.id;
                            return ListTile(
                              dense: true,
                              title: Text(category.name),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildCategoryInfoButton(category),
                                  selected
                                      ? const Icon(
                                          Icons.check_circle,
                                          color: AppColors.green,
                                        )
                                      : const Icon(
                                          Icons.radio_button_unchecked,
                                          color: Colors.black45,
                                        ),
                                ],
                              ),
                              onTap: () {
                                setState(() {
                                  _selectedCategoryId = category.id;
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                const Text(
                  'Selected Category',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                if (selectedCategory.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'No category selected yet.',
                      style: TextStyle(fontSize: 12.5, color: Colors.black54),
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      dense: true,
                      title: Text(selectedCategory.first.name),
                      subtitle: Text(
                        _parentTypeLabel(
                          selectedCategory.first.parentType?.trim() ?? '',
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildCategoryInfoButton(selectedCategory.first),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              setState(() {
                                _selectedCategoryId = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      decoration: InputDecoration(
        labelText: 'Amount',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        prefixIcon: const Icon(Icons.attach_money),
        prefixText: '${AppConstants.currencySymbol} ',
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      style: const TextStyle(fontSize: 16),
      onChanged: (_) => setState(() {}),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'Please enter amount';
        final parsed = double.tryParse(value);
        if (parsed == null || parsed <= 0) return 'Enter a valid amount';
        return null;
      },
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: (_isSubmitting || !_canCreateJob) ? null : _submitProcess,
          style: ElevatedButton.styleFrom(
            backgroundColor: _canCreateJob
                ? AppColors.green
                : Colors.grey.shade400,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade300,
            disabledForegroundColor: Colors.black38,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(_canCreateJob ? 'Create Job' : 'Complete required fields'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    _processNameController.dispose();
    _jobDescriptionController.dispose();
    _startTimeController.dispose();
    _durationController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}
