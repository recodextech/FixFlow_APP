import 'dart:typed_data';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/availability.dart';
import '../models/wallet.dart';
import '../models/worker.dart';
import '../providers/worker_provider.dart';
import '../services/api_service.dart';
import '../services/job_photo_upload.dart';
import '../services/preferences_service.dart';
import '../theme.dart';
import '../utils/performance_utils.dart';
import 'create_worker_availability_screen.dart';

class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 500)});

  void call(VoidCallback callback) {
    _timer?.cancel();
    _timer = Timer(delay, callback);
  }

  void dispose() {
    _timer?.cancel();
  }
}

class WorkerDetailsScreen extends StatefulWidget {
  final String workerId;

  const WorkerDetailsScreen({
    super.key,
    required this.workerId,
  });

  @override
  State<WorkerDetailsScreen> createState() => _WorkerDetailsScreenState();
}

class _WorkerDetailsScreenState extends State<WorkerDetailsScreen> {
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  final DateFormat _dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm');
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  late Future<Worker?> _workerFuture;
  late Future<WorkerAvailabilityResponse> _availabilityFuture;
  late Future<List<Wallet>> _walletsFuture;
  Uint8List? _selectedPhotoBytes;
  bool _isSaving = false;
  bool _isFormInitialized = false;
  Worker? _currentWorker;
  late Debouncer _saveDebouncer;

  @override
  void initState() {
    super.initState();
    _saveDebouncer = Debouncer(delay: const Duration(milliseconds: 800));
    _walletsFuture = ApiService().getWallets(
      accountId: PreferencesService().getAccountId(),
    );
    _loadData();
  }

  void _loadData() {
    _workerFuture = _loadWorker();
    _availabilityFuture = _loadAvailabilities();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _saveDebouncer.dispose();
    super.dispose();
  }

  Future<Worker?> _loadWorker() {
    return context.read<WorkerProvider>().getWorker(
          widget.workerId,
          accountId: PreferencesService().getAccountId(),
        );
  }

  Future<WorkerAvailabilityResponse> _loadAvailabilities() {
    return context.read<WorkerProvider>().getWorkerAvailabilities(
          workerId: widget.workerId,
          accountId: PreferencesService().getAccountId(),
        );
  }

  Future<void> _refreshAvailabilities() async {
    setState(() {
      _availabilityFuture = _loadAvailabilities();
    });
  }

  Future<void> _createAvailability() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) =>
            CreateWorkerAvailabilityScreen(workerId: widget.workerId),
      ),
    );

    if (!mounted) {
      return;
    }

    if (result == true) {
      _refreshAvailabilities();
    }
  }

  void _populateForm(Worker worker) {
    if (_isFormInitialized) {
      return;
    }

    _currentWorker = worker;
    _nameController.text = worker.workerName;
    _emailController.text = worker.email;
    _phoneController.text = worker.phoneNumber;
    _isFormInitialized = true;
  }

  Future<void> _showPhotoSourceSheet() async {
    if (!mounted) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    final bytes = await JobPhotoUpload.pickAndPrepare(source);
    if (!mounted) return;
    if (bytes == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Profile Photo'),
        content: const Text('Do you want to update your profile photo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _selectedPhotoBytes = bytes);
    _uploadPhoto(bytes);
  }

  Future<void> _uploadPhoto(Uint8List bytes) async {
    final accountId = PreferencesService().getAccountId();
    if (accountId == null || accountId.isEmpty) return;

    try {
      final photoBase64 = JobPhotoUpload.toBase64(bytes);
      final updated = await context.read<WorkerProvider>().updateWorker(
            workerId: widget.workerId,
            accountId: accountId,
            workerName: _nameController.text.trim(),
            email: _emailController.text.trim(),
            phoneNumber: _phoneController.text.trim(),
            workerCategories: _currentWorker?.workerCategories ?? [],
            photoBase64: photoBase64,
          );

      PreferencesService().setWorkerData(updated.copyWith(photoBase64: photoBase64));
      _currentWorker = updated;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile photo updated'),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update photo: \$e')),
      );
    }
  }

  Future<void> _saveWorker(Worker worker) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final accountId = PreferencesService().getAccountId();
    if (accountId == null || accountId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account ID not found')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final currentPhoto = _selectedPhotoBytes == null
          ? PreferencesService().getWorkerPhotoBase64() ?? worker.photoBase64
          : JobPhotoUpload.toBase64(_selectedPhotoBytes!);

      final updated = await context.read<WorkerProvider>().updateWorker(
            workerId: widget.workerId,
            accountId: accountId,
            workerName: _nameController.text.trim(),
            email: _emailController.text.trim(),
            phoneNumber: _phoneController.text.trim(),
            workerCategories: worker.workerCategories,
            photoBase64: _selectedPhotoBytes != null ? currentPhoto : null,
          );

      PreferencesService().setWorkerData(
        updated.copyWith(photoBase64: currentPhoto),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Worker profile updated successfully')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update worker: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _autoSaveWorker() async {
    if (_currentWorker == null || !_isFormInitialized) return;

    final accountId = PreferencesService().getAccountId();
    if (accountId == null || accountId.isEmpty) return;

    try {
      final updated = await context.read<WorkerProvider>().updateWorker(
            workerId: widget.workerId,
            accountId: accountId,
            workerName: _nameController.text.trim(),
            email: _emailController.text.trim(),
            phoneNumber: _phoneController.text.trim(),
            workerCategories: _currentWorker!.workerCategories,
            photoBase64: null, // Photo is updated separately via confirmation dialog
          );

      _currentWorker = updated;
      // Preserve the existing photo in preferences
      final existingPhoto = _selectedPhotoBytes != null
          ? JobPhotoUpload.toBase64(_selectedPhotoBytes!)
          : PreferencesService().getWorkerPhotoBase64() ?? _currentWorker!.photoBase64;
      PreferencesService().setWorkerData(updated.copyWith(photoBase64: existingPhoto));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated'),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Auto-save failed: \$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createAvailability,
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Availability'),
      ),
      body: FutureBuilder<Worker?>(
        future: _workerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: AppColors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}',
                      style: const TextStyle(color: AppColors.text2)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(_loadData),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final worker = snapshot.data;
          if (worker == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_outline, size: 48, color: AppColors.gray5),
                  const SizedBox(height: 16),
                  const Text('Worker profile not found'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Back'),
                  ),
                ],
              ),
            );
          }

          _populateForm(worker);

          final currentPhotoBase64 = _selectedPhotoBytes == null
              ? PreferencesService().getWorkerPhotoBase64()
              : JobPhotoUpload.toBase64(_selectedPhotoBytes!);

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Green gradient header
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: AppColors.workerGradient,
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: const Icon(Icons.arrow_back,
                                    color: Colors.white),
                              ),
                              const Spacer(),
                              const Text(
                                'Edit Worker Profile',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const Spacer(),
                              const SizedBox(width: 24),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: _showPhotoSourceSheet,
                                child: Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: (currentPhotoBase64 == null ||
                                          currentPhotoBase64.isEmpty)
                                      ? Center(
                                          child: Text(
                                            _workerInitial(worker.workerName),
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        )
                                      : CachedMemoryImage(
                                          base64String: currentPhotoBase64,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Center(
                                              child: Text(
                                                _workerInitial(worker.workerName),
                                                style: const TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      worker.workerName,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      worker.email,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white.withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Body content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Personal Information',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _showPhotoSourceSheet,
                            icon: const Icon(Icons.camera_alt_outlined, size: 18),
                            label: const Text('Update photo'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _nameController,
                              onChanged: (_) => _saveDebouncer(_autoSaveWorker),
                              decoration: const InputDecoration(
                                labelText: 'Name',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (value) =>
                                  (value == null || value.trim().isEmpty)
                                      ? 'Please enter a name'
                                      : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _emailController,
                              onChanged: (_) => _saveDebouncer(_autoSaveWorker),
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter an email';
                                }
                                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                    .hasMatch(value.trim())) {
                                  return 'Enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _phoneController,
                              onChanged: (_) => _saveDebouncer(_autoSaveWorker),
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Phone',
                                prefixIcon: Icon(Icons.phone_outlined),
                              ),
                              validator: (value) =>
                                  (value == null || value.trim().isEmpty)
                                      ? 'Please enter a phone number'
                                      : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Categories
                      const Text(
                        'Categories',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (worker.categories.isEmpty)
                        const Text(
                          'No categories assigned',
                          style: TextStyle(fontSize: 13, color: AppColors.text3),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: worker.categories.map((category) {
                            return Chip(
                              label: Text(category,
                                  style: const TextStyle(fontSize: 13)),
                              backgroundColor: AppColors.greenPale,
                              side: BorderSide.none,
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 24),
                      // Wallets
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.greenPale,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.account_balance_wallet_outlined,
                                    color: AppColors.green,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Wallets',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.text,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Your account wallet balances',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.text3,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildWalletSection(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Availability Windows
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Availability Windows',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.text,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _refreshAvailabilities,
                            child: const Icon(Icons.refresh,
                                size: 20, color: AppColors.green),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FutureBuilder<WorkerAvailabilityResponse>(
                        future: _availabilityFuture,
                        builder: (context, availabilitySnapshot) {
                          if (availabilitySnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child:
                                  Center(child: CircularProgressIndicator()),
                            );
                          }

                          if (availabilitySnapshot.hasError) {
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.redPale,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded,
                                      size: 18, color: AppColors.red),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text('Could not load availabilities',
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: AppColors.red)),
                                  ),
                                  TextButton(
                                    onPressed: _refreshAvailabilities,
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            );
                          }

                          final response = availabilitySnapshot.data ??
                              WorkerAvailabilityResponse(
                                  availabilities: [], total: 0);

                          if (response.availabilities.isEmpty) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.gray1,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.event_busy,
                                      size: 36, color: AppColors.gray4),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'No availability windows',
                                    style: TextStyle(
                                        fontSize: 14, color: AppColors.text2),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Tap the button below to add one',
                                    style: TextStyle(
                                        fontSize: 12, color: AppColors.text3),
                                  ),
                                ],
                              ),
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${response.total} total',
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.text3),
                              ),
                              const SizedBox(height: 8),
                              ...response.availabilities
                                  .asMap()
                                  .entries
                                  .map((entry) {
                                return _buildAvailabilityCard(
                                    entry.value, entry.key + 1);
                              }),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 80), // FAB clearance
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWalletSection() {
    return FutureBuilder<List<Wallet>>(
      future: _walletsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: AppColors.text3),
                const SizedBox(width: 8),
                const Text(
                  'No wallets found',
                  style: TextStyle(fontSize: 13, color: AppColors.text3),
                ),
              ],
            ),
          );
        }

        return Column(
          children: snapshot.data!
              .map((wallet) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildWalletTile(wallet),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildWalletTile(Wallet wallet) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray2, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: wallet.iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(wallet.icon, color: wallet.iconColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    wallet.displayName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    wallet.status,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.text3,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${AppConstants.currencySymbol} ${wallet.balance.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.green,
                  ),
                ),
                const Text(
                  'balance',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.text3,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.green),
          const SizedBox(width: 10),
          Text('$label: ',
              style: const TextStyle(fontSize: 13, color: AppColors.text3)),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.text)),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityCard(WorkerAvailability availability, int index) {
    final status = availability.status.toUpperCase();
    final isOnline = status == 'ONLINE';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.gray2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isOnline ? AppColors.greenPale : AppColors.gray1,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.event_available,
                    size: 18,
                    color: isOnline ? AppColors.green : AppColors.gray5,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Availability $index',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: isOnline ? AppColors.greenPale : AppColors.gray1,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.isEmpty ? 'UNKNOWN' : status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isOnline ? AppColors.green : AppColors.gray5,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 15, color: AppColors.text3),
                const SizedBox(width: 6),
                Expanded(
                  child: FutureBuilder<String>(
                    future: ApiService().reverseGeocode(availability.latitude, availability.longitude),
                    builder: (context, snap) {
                      return Text(
                        snap.data ?? 'Loading address...',
                        style: const TextStyle(fontSize: 13, color: AppColors.text2),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _buildAvailabilityInfoRow(
              Icons.date_range,
              '${_formatDate(availability.startDate)} → ${_formatDate(availability.endDate)}',
            ),
            const SizedBox(height: 6),
            _buildAvailabilityInfoRow(
              Icons.repeat,
              availability.frequency.isEmpty ? 'N/A' : availability.frequency,
            ),
            if (availability.windows.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text(
                'Time Windows',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text2),
              ),
              const SizedBox(height: 6),
              ...availability.windows.map((window) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.gray1,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.schedule,
                          size: 15, color: AppColors.text3),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(_formatDateTime(window.startTime),
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.text2)),
                      ),
                      Text('${window.duration}h',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text)),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilityInfoRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.text3),
        const SizedBox(width: 6),
        Expanded(
          child: Text(value,
              style: const TextStyle(fontSize: 12, color: AppColors.text2)),
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'N/A';
    }

    return _dateFormat.format(date);
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) {
      return 'N/A';
    }

    return _dateTimeFormat.format(dateTime);
  }

  String _workerInitial(String workerName) {
    final trimmed = workerName.trim();
    if (trimmed.isEmpty) {
      return 'W';
    }

    return trimmed[0].toUpperCase();
  }
}
