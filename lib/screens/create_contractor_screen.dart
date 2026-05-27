import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/contractor.dart';
import '../providers/contractor_provider.dart';
import '../services/job_photo_upload.dart';
import '../services/preferences_service.dart';
import '../services/api_service.dart';
import '../theme.dart';
import 'contractor_profile_screen.dart';

class CreateContractorScreen extends StatefulWidget {
  const CreateContractorScreen({super.key});

  @override
  State<CreateContractorScreen> createState() => _CreateContractorScreenState();
}

class _CreateContractorScreenState extends State<CreateContractorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  String _contractorType = 'COMPANY';
  Uint8List? _profilePhotoBytes;
  bool _isSubmitting = false;
  Map<String, dynamic>? _result;

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

    setState(() => _profilePhotoBytes = bytes);
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      try {
        final contractorName = _nameController.text.trim();
        final contractorEmail = _emailController.text.trim();
        final contractorPhone = _phoneController.text.trim();
        final photoBase64 = _profilePhotoBytes == null
            ? null
            : JobPhotoUpload.toBase64(_profilePhotoBytes!);

        final result =
            await context.read<ContractorProvider>().createContractor(
                  contractorName: contractorName,
                  contractorType: _contractorType,
                  email: contractorEmail,
                  phoneNumber: contractorPhone,
                  photoBase64: photoBase64,
                );

        if (result['id'] != null) {
          final prefs = PreferencesService();
          prefs.setContractorData(
            Contractor.fromJson(result).copyWith(photoBase64: photoBase64),
          );
          await prefs.activateContractorProfile();

          try {
            final accounts = await ApiService().getUserAccounts();
            prefs.loadUserAccounts(
              userId: accounts.userId,
              worker: accounts.worker,
              contractor: accounts.contractor,
            );
          } catch (_) {}
        }

        setState(() {
          _result = result;
          _formKey.currentState!.reset();
          _contractorType = 'COMPANY';
          _profilePhotoBytes = null;
          _nameController.clear();
          _emailController.clear();
          _phoneController.clear();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Contractor created successfully')),
          );
          // Navigate to profile screen
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) =>
                      ContractorProfileScreen(contractorId: result['id']),
                ),
              );
            }
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSubmitting = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
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
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Create Contractor Profile',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Form body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type toggle
                    const Text(
                      'Contractor Type',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _TypeToggle(
                            label: 'Company',
                            icon: Icons.business,
                            selected: _contractorType == 'COMPANY',
                            onTap: () =>
                                setState(() => _contractorType = 'COMPANY'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _TypeToggle(
                            label: 'Individual',
                            icon: Icons.person,
                            selected: _contractorType == 'INDIVIDUAL',
                            onTap: () =>
                                setState(() => _contractorType = 'INDIVIDUAL'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Profile Photo',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _showPhotoSourceSheet,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.gray3),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: AppColors.bluePale,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: _profilePhotoBytes == null
                                  ? const Icon(
                                      Icons.camera_alt_outlined,
                                      color: AppColors.blue,
                                      size: 30,
                                    )
                                  : Image.memory(
                                      _profilePhotoBytes!,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Upload a profile photo',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.text,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Tap to choose a photo from camera or gallery.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.text3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Details section
                    const Text(
                      'Details',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: _contractorType == 'COMPANY'
                            ? 'Company Name'
                            : 'Full Name',
                        prefixIcon: Icon(_contractorType == 'COMPANY'
                            ? Icons.business_outlined
                            : Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 32),
                    // Submit
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text(
                                'Create Contractor',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}

class _TypeToggle extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TypeToggle({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? AppColors.bluePale : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.blue : AppColors.gray3,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: selected ? AppColors.blue : AppColors.gray5),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? AppColors.blue : AppColors.text2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
