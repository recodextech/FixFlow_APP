import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/worker.dart';
import '../providers/worker_provider.dart';
import '../services/job_photo_upload.dart';
import '../services/preferences_service.dart';
import '../services/api_service.dart';
import '../theme.dart';
import 'worker_profile_screen.dart';

class CreateWorkerScreen extends StatefulWidget {
  const CreateWorkerScreen({super.key});

  @override
  State<CreateWorkerScreen> createState() => _CreateWorkerScreenState();
}

class _CreateWorkerScreenState extends State<CreateWorkerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  final List<Category> _selectedCategories = [];
  Uint8List? _profilePhotoBytes;
  bool _isSubmitting = false;
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  void _loadCategories() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkerProvider>().fetchCategories();
    });
  }

  void _addCategory(Category category) {
    if (!_selectedCategories.contains(category)) {
      setState(() {
        _selectedCategories.add(category);
      });
    }
  }

  void _removeCategory(Category category) {
    setState(() {
      _selectedCategories.removeWhere((c) => c.id == category.id);
    });
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

    setState(() => _profilePhotoBytes = bytes);
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategories.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one category')),
        );
        return;
      }

      setState(() => _isSubmitting = true);

      try {
        final workerName = _nameController.text.trim();
        final workerEmail = _emailController.text.trim();
        final workerPhone = _phoneController.text.trim();
        final photoBase64 = _profilePhotoBytes == null
            ? null
            : JobPhotoUpload.toBase64(_profilePhotoBytes!);

        final result = await context.read<WorkerProvider>().createWorker(
              workerName: workerName,
              email: workerEmail,
              phoneNumber: workerPhone,
              workerCategories: _selectedCategories.map((c) => c.id).toList(),
              photoBase64: photoBase64,
            );

        if (result['id'] != null) {
          final prefs = PreferencesService();
          prefs.setWorkerData(
            Worker.fromJson(result).copyWith(photoBase64: photoBase64),
          );
          await prefs.activateWorkerProfile();

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
          _selectedCategories.clear();
          _profilePhotoBytes = null;
          _nameController.clear();
          _emailController.clear();
          _phoneController.clear();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Worker created successfully')),
          );
          // Navigate to profile screen
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) =>
                      WorkerProfileScreen(workerId: result['id']),
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
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Create Worker Profile',
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
                                color: AppColors.greenPale,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: _profilePhotoBytes == null
                                  ? const Icon(
                                      Icons.camera_alt_outlined,
                                      color: AppColors.green,
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
                    // Personal Information section
                    const Text(
                      'Personal Information',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter worker name';
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
                    const SizedBox(height: 28),
                    // Skills & Categories section
                    const Text(
                      'Skills & Categories',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Select the categories you can work in',
                      style: TextStyle(fontSize: 13, color: AppColors.text3),
                    ),
                    const SizedBox(height: 12),
                    // Selected chips
                    if (_selectedCategories.isNotEmpty) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedCategories.map((category) {
                          return Chip(
                            label: Text(category.name,
                                style: const TextStyle(fontSize: 13)),
                            backgroundColor: AppColors.greenPale,
                            side: BorderSide.none,
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () => _removeCategory(category),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Category picker
                    Consumer<WorkerProvider>(
                      builder: (context, provider, _) {
                        if (provider.isLoading && provider.categories.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        if (provider.error != null &&
                            provider.categories.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.redPale,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Error: ${provider.error}',
                              style: const TextStyle(
                                  color: AppColors.red, fontSize: 13),
                            ),
                          );
                        }

                        final available = provider.categories
                            .where((cat) => !_selectedCategories
                                .any((s) => s.id == cat.id))
                            .toList();

                        if (available.isEmpty && provider.categories.isNotEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.greenPale,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'All categories selected',
                              style: TextStyle(
                                  color: AppColors.green, fontSize: 13),
                            ),
                          );
                        }

                        return Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.gray3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: SizedBox(
                            height: 160,
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: available.length,
                              itemBuilder: (context, index) {
                                final cat = available[index];
                                return ListTile(
                                  dense: true,
                                  title: Text(cat.name,
                                      style: const TextStyle(fontSize: 14)),
                                  trailing: const Icon(Icons.add_circle_outline,
                                      color: AppColors.green, size: 20),
                                  onTap: () => _addCategory(cat),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.green,
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
                                'Create Worker',
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
