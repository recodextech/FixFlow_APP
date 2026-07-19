import 'dart:typed_data';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/contractor.dart';
import '../models/wallet.dart';
import '../providers/contractor_provider.dart';
import '../services/api_service.dart';
import '../services/job_photo_upload.dart';
import '../services/preferences_service.dart';
import '../theme.dart';
import '../utils/performance_utils.dart';

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

class ContractorInfoScreen extends StatefulWidget {
  final String contractorId;
  final Contractor? initialContractor;

  const ContractorInfoScreen({
    super.key,
    required this.contractorId,
    this.initialContractor,
  });

  @override
  State<ContractorInfoScreen> createState() => _ContractorInfoScreenState();
}

class _ContractorInfoScreenState extends State<ContractorInfoScreen> {
  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  late Future<Contractor?> _contractorFuture;
  late Future<List<Wallet>> _walletsFuture;

  String _contractorType = 'COMPANY';
  Uint8List? _selectedPhotoBytes;
  bool _isFormInitialized = false;
  Contractor? _currentContractor;
  late Debouncer _saveDebouncer;

  @override
  void initState() {
    super.initState();
    _saveDebouncer = Debouncer(delay: const Duration(milliseconds: 800));
    _contractorFuture = widget.initialContractor != null
        ? Future.value(widget.initialContractor)
        : _loadContractor();
    _walletsFuture = ApiService().getWallets(
      accountId: PreferencesService().getAccountId(),
    );
  }

  Future<Contractor?> _loadContractor() {
    return context.read<ContractorProvider>().getContractor(
      widget.contractorId,
      accountId: PreferencesService().getAccountId(),
    );
  }

  void _populateForm(Contractor contractor) {
    if (_isFormInitialized) {
      return;
    }

    _currentContractor = contractor;
    _nameController.text = contractor.contractorName;
    _emailController.text = contractor.email;
    _phoneController.text = contractor.phoneNumber;
    _contractorType = contractor.contractorType.isEmpty
        ? 'COMPANY'
        : contractor.contractorType;
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
      final updated = await context.read<ContractorProvider>().updateContractor(
        contractorId: widget.contractorId,
        accountId: accountId,
        contractorName: _nameController.text.trim(),
        contractorType: _contractorType,
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        photoBase64: photoBase64,
      );

      final savedContractor = updated.copyWith(photoBase64: photoBase64);
      PreferencesService().setContractorData(savedContractor);
      _currentContractor = updated;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile photo updated'),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showTopError(_errorMessage(e));
    }
  }

  bool _isOptionalEmailValid(String email) {
    return email.isEmpty || _emailPattern.hasMatch(email);
  }

  bool _canAutoSave() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    return name.isNotEmpty && phone.isNotEmpty && _isOptionalEmailValid(email);
  }

  String _errorMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }

    final message = error.toString().trim();
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }
    return message;
  }

  void _showTopError(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentMaterialBanner()
      ..showMaterialBanner(
        MaterialBanner(
          backgroundColor: AppColors.redPale,
          leading: const Icon(Icons.error_outline, color: AppColors.red),
          content: Text(message, style: const TextStyle(color: AppColors.text)),
          actions: [
            TextButton(
              onPressed: messenger.hideCurrentMaterialBanner,
              child: const Text('Dismiss'),
            ),
          ],
        ),
      );
  }

  Future<void> _autoSaveContractor() async {
    if (_currentContractor == null || !_isFormInitialized || !_canAutoSave()) {
      return;
    }

    final accountId = PreferencesService().getAccountId();
    if (accountId == null || accountId.isEmpty) return;

    try {
      final updated = await context.read<ContractorProvider>().updateContractor(
        contractorId: widget.contractorId,
        accountId: accountId,
        contractorName: _nameController.text.trim(),
        contractorType: _contractorType,
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        photoBase64:
            null, // Photo is updated separately via confirmation dialog
      );

      _currentContractor = updated;
      // Preserve the existing photo in preferences
      final existingPhoto = _selectedPhotoBytes != null
          ? JobPhotoUpload.toBase64(_selectedPhotoBytes!)
          : PreferencesService().getContractorPhotoBase64() ??
                _currentContractor!.photoBase64;
      PreferencesService().setContractorData(
        updated.copyWith(photoBase64: existingPhoto),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated'),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showTopError(_errorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Contractor?>(
        future: _contractorFuture,
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
                  const SizedBox(height: 12),
                  Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: AppColors.text2),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isFormInitialized = false;
                        _contractorFuture = _loadContractor();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final contractor = snapshot.data;
          if (contractor == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.business_outlined,
                    size: 48,
                    color: AppColors.gray5,
                  ),
                  const SizedBox(height: 12),
                  const Text('Contractor not found'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Back'),
                  ),
                ],
              ),
            );
          }

          _populateForm(contractor);

          final currentPhotoBase64 = _selectedPhotoBytes == null
              ? PreferencesService().getContractorPhotoBase64() ??
                    contractor.photoBase64
              : JobPhotoUpload.toBase64(_selectedPhotoBytes!);

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Blue gradient header
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: AppColors.contractorGradient,
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
                                child: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                ),
                              ),
                              const Spacer(),
                              const Text(
                                'Contractor Information',
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
                                  child:
                                      (currentPhotoBase64 == null ||
                                          currentPhotoBase64.isEmpty)
                                      ? Center(
                                          child: Text(
                                            contractor.contractorName.isNotEmpty
                                                ? contractor.contractorName[0]
                                                      .toUpperCase()
                                                : 'C',
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
                                                    contractor
                                                            .contractorName
                                                            .isNotEmpty
                                                        ? contractor
                                                              .contractorName[0]
                                                              .toUpperCase()
                                                        : 'C',
                                                    style: const TextStyle(
                                                      fontSize: 24,
                                                      fontWeight:
                                                          FontWeight.w700,
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
                                      contractor.contractorName,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      contractor.contractorType,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white.withValues(
                                          alpha: 0.8,
                                        ),
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
                // Form
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Personal Information Section
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
                              // Section header
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.bluePale,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.person_outline,
                                      color: AppColors.blue,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'Personal Information',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.text,
                                      ),
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: _showPhotoSourceSheet,
                                    icon: const Icon(
                                      Icons.camera_alt_outlined,
                                      size: 18,
                                    ),
                                    label: const Text('Photo'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.blue,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _nameController,
                                onChanged: (_) =>
                                    _saveDebouncer(_autoSaveContractor),
                                decoration: InputDecoration(
                                  labelText: 'Business Name',
                                  hintText: 'Enter contractor name',
                                  prefixIcon: const Icon(
                                    Icons.business_outlined,
                                  ),
                                  filled: true,
                                  fillColor: AppColors.gray1,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.blue,
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _emailController,
                                onChanged: (_) =>
                                    _saveDebouncer(_autoSaveContractor),
                                decoration: InputDecoration(
                                  labelText: 'Email Address',
                                  hintText: 'Enter email',
                                  prefixIcon: const Icon(Icons.email_outlined),
                                  filled: true,
                                  fillColor: AppColors.gray1,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.blue,
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  final email = value?.trim() ?? '';
                                  if (!_isOptionalEmailValid(email)) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _phoneController,
                                onChanged: (_) =>
                                    _saveDebouncer(_autoSaveContractor),
                                decoration: InputDecoration(
                                  labelText: 'Phone Number',
                                  hintText: 'Enter phone number',
                                  prefixIcon: const Icon(Icons.phone_outlined),
                                  filled: true,
                                  fillColor: AppColors.gray1,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.blue,
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                                keyboardType: TextInputType.phone,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter phone number';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Wallet Points section
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
                              // Section header
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.bluePale,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.account_balance_wallet_outlined,
                                      color: AppColors.blue,
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
                              _buildWalletPointsSection(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWalletPointsSection() {
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

        final wallets = snapshot.data!;
        return Column(
          children: wallets.map((wallet) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildWalletTile(wallet),
            );
          }).toList(),
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
                    color: AppColors.blue,
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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _saveDebouncer.dispose();
    super.dispose();
  }
}
