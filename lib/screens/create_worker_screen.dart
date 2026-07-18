import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/worker.dart';
import '../providers/worker_provider.dart';
import '../services/preferences_service.dart';
import '../services/api_service.dart';
import '../theme.dart';
import 'profile_photo_upload_screen.dart';

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

  String? _activeParentType;
  final Set<String> _selectedCategoryIds = <String>{};
  bool _isSubmitting = false;

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

  int _subcategoryCount(List<Category> categories, String parentType) {
    return categories.where((c) => c.parentType?.trim() == parentType).length;
  }

  void _toggleParentType(String parentType) {
    setState(() {
      _activeParentType = _activeParentType == parentType ? null : parentType;
    });
  }

  List<Category> _categoriesForParent(
    List<Category> categories,
    String? parentType,
  ) {
    if (parentType == null) return const [];
    return categories.where((c) => c.parentType?.trim() == parentType).toList();
  }

  List<Category> _selectedCategoryObjects(List<Category> categories) {
    return categories
        .where((c) => _selectedCategoryIds.contains(c.id))
        .toList();
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

  void _toggleCategorySelection(String categoryId) {
    setState(() {
      if (_selectedCategoryIds.contains(categoryId)) {
        _selectedCategoryIds.remove(categoryId);
      } else {
        _selectedCategoryIds.add(categoryId);
      }
    });
  }

  Widget _buildParentTypeSelection(List<Category> categories) {
    return Row(
      children: _parentTypeOrder.map((parentType) {
        final count = _subcategoryCount(categories, parentType);
        final selected = _activeParentType == parentType;
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

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final selectedCategoryIds = _selectedCategoryIds.toList();

      if (selectedCategoryIds.isEmpty) {
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

        final result = await context.read<WorkerProvider>().createWorker(
          workerName: workerName,
          email: workerEmail,
          phoneNumber: workerPhone,
          workerCategories: selectedCategoryIds,
          photoBase64: null,
        );

        if (result['id'] != null) {
          final prefs = PreferencesService();
          prefs.setWorkerData(Worker.fromJson(result));
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
          _formKey.currentState!.reset();
          _activeParentType = null;
          _selectedCategoryIds.clear();
          _nameController.clear();
          _emailController.clear();
          _phoneController.clear();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Worker created successfully')),
          );
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => ProfilePhotoUploadScreen(
                    profileType: 'WORKER',
                    profileId: result['id'],
                    accountId: PreferencesService().getAccountId(),
                    profileName: workerName,
                    email: workerEmail,
                    phoneNumber: workerPhone,
                    workerCategories: selectedCategoryIds,
                  ),
                ),
              );
            }
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
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
                                color: AppColors.red,
                                fontSize: 13,
                              ),
                            ),
                          );
                        }

                        final allCategories = provider.categories;
                        if (allCategories.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'No category types available',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 13,
                              ),
                            ),
                          );
                        }

                        final parentCategories = _categoriesForParent(
                          allCategories,
                          _activeParentType,
                        );
                        final selectedCategories = _selectedCategoryObjects(
                          allCategories,
                        );

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
                                _buildParentTypeSelection(allCategories),
                                const SizedBox(height: 12),
                                if (_activeParentType == null)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${_parentTypeLabel(_activeParentType!)} Subcategories',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        constraints: const BoxConstraints(
                                          maxHeight: 180,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: ListView.separated(
                                          padding: EdgeInsets.zero,
                                          shrinkWrap: true,
                                          itemCount: parentCategories.length,
                                          separatorBuilder: (_, index) =>
                                              const Divider(height: 1),
                                          itemBuilder: (context, index) {
                                            final category =
                                                parentCategories[index];
                                            final selected =
                                                _selectedCategoryIds.contains(
                                                  category.id,
                                                );
                                            return CheckboxListTile(
                                              dense: true,
                                              value: selected,
                                              controlAffinity:
                                                  ListTileControlAffinity
                                                      .leading,
                                              title: Text(category.name),
                                              secondary:
                                                  _buildCategoryInfoButton(
                                                    category,
                                                  ),
                                              onChanged: (_) =>
                                                  _toggleCategorySelection(
                                                    category.id,
                                                  ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: 12),
                                Text(
                                  'Selected Subcategories (${selectedCategories.length})',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (selectedCategories.isEmpty)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      'No subcategories selected yet.',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    constraints: const BoxConstraints(
                                      maxHeight: 180,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: ListView.separated(
                                      padding: EdgeInsets.zero,
                                      shrinkWrap: true,
                                      itemCount: selectedCategories.length,
                                      separatorBuilder: (_, index) =>
                                          const Divider(height: 1),
                                      itemBuilder: (context, index) {
                                        final category =
                                            selectedCategories[index];
                                        return ListTile(
                                          dense: true,
                                          title: Text(category.name),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              _buildCategoryInfoButton(
                                                category,
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.close,
                                                  size: 18,
                                                ),
                                                onPressed: () =>
                                                    _toggleCategorySelection(
                                                      category.id,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                              ],
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
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Create Worker',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
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
