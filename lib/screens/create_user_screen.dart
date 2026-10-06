import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/worker.dart';
import '../models/user_accounts.dart';
import '../providers/language_provider.dart';
import '../providers/worker_provider.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/preferences_service.dart';
import '../theme.dart';
import 'home_screen.dart';
import 'profile_photo_upload_screen.dart';

class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({super.key});

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _includeEmail = false;
  String? _activeParentType;
  final Set<String> _selectedCategoryIds = <String>{};
  bool _isSubmitting = false;
  String? _skillsError;

  static const List<String> _parentTypeOrder = [
    'HOUSE_REPAIR',
    'GARDEN_WORKS',
    'MAINTENANCE',
  ];

  String _parentTypeLabel(String parentType, AppLocalizations loc) {
    switch (parentType) {
      case 'HOUSE_REPAIR':
        return loc.houseRepair;
      case 'GARDEN_WORKS':
        return loc.gardenWorks;
      case 'MAINTENANCE':
        return loc.maintenance;
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
        return AppColors.brandGreen;
      case 'GARDEN_WORKS':
        return AppColors.brandGreenLight;
      case 'MAINTENANCE':
        return AppColors.brandGold;
      default:
        return AppColors.brandGreen;
    }
  }

  int _subcategoryCount(List<Category> categories, String parentType) {
    return categories
        .where((category) => category.parentType?.trim() == parentType)
        .length;
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
    return categories
        .where((category) => category.parentType?.trim() == parentType)
        .toList();
  }

  List<Category> _selectedCategoryObjects(List<Category> categories) {
    return categories
        .where((category) => _selectedCategoryIds.contains(category.id))
        .toList();
  }

  void _showCategoryDescription(Category category, AppLocalizations loc) {
    final description = category.description.trim();
    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.noDescriptionAvailableForThisCategory)),
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

  Widget _buildCategoryInfoButton(Category category, AppLocalizations loc) {
    return IconButton(
      tooltip: loc.categoryDescription,
      icon: const Icon(
        Icons.help_outline,
        size: 18,
        color: AppColors.brandGreen,
      ),
      splashRadius: 18,
      onPressed: () => _showCategoryDescription(category, loc),
    );
  }

  void _toggleCategorySelection(String categoryId) {
    setState(() {
      if (_selectedCategoryIds.contains(categoryId)) {
        _selectedCategoryIds.remove(categoryId);
      } else {
        _selectedCategoryIds.add(categoryId);
      }

      if (_selectedCategoryIds.isNotEmpty) {
        _skillsError = null;
      }
    });
  }

  Widget _buildParentTypeSelection(
    List<Category> categories,
    AppLocalizations loc,
  ) {
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
                        _parentTypeLabel(parentType, loc),
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
                        loc.subcategoriesLabel,
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
    if (!_formKey.currentState!.validate()) return;

    final selectedCategoryIds = _selectedCategoryIds.toList();
    if (selectedCategoryIds.isEmpty) {
      final loc = AppLocalizations.of(context.read<LanguageProvider>().locale);
      setState(() {
        _skillsError = loc.selectAtLeastOneSkill;
      });
      return;
    }

    _skillsError = null;

    setState(() => _isSubmitting = true);

    try {
      final userName = _nameController.text.trim();
      final userEmail = _includeEmail ? _emailController.text.trim() : '';
      final userPhone = _phoneController.text.trim();

      final result = await ApiService().createUserAccount(
        name: userName,
        email: userEmail,
        phoneNumber: userPhone,
        workerCategories: selectedCategoryIds,
      );

      final prefs = PreferencesService();
      prefs.loadUserAccounts(
        userId: result.userId,
        worker: result.worker,
        contractor: result.contractor,
      );

      var latestAccounts = UserAccounts(
        userId: result.userId,
        worker: result.worker,
        contractor: result.contractor,
      );

      try {
        final accounts = await ApiService().getUserAccounts();
        prefs.loadUserAccounts(
          userId: accounts.userId,
          worker: accounts.worker,
          contractor: accounts.contractor,
        );
        latestAccounts = accounts;
      } catch (_) {}

      if (!mounted) return;

      if (latestAccounts.worker != null) {
        await prefs.activateWorkerProfile();
      } else if (latestAccounts.contractor != null) {
        await prefs.activateContractorProfile();
      }
      await NotificationService.registerDeviceForActiveAccount();

      if (!mounted) return;

      if (latestAccounts.worker != null || latestAccounts.contractor != null) {
        final worker = latestAccounts.worker;
        final contractor = latestAccounts.contractor;
        final profileType = worker != null ? 'WORKER' : 'CONTRACTOR';
        final profileId = worker?.id ?? contractor!.id;
        final accountId = worker?.accountId ?? contractor?.accountId;

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => ProfilePhotoUploadScreen(
              profileType: profileType,
              profileId: profileId,
              accountId: accountId,
              profileName: worker?.workerName ?? contractor?.contractorName,
              email: worker?.email ?? contractor?.email,
              phoneNumber: worker?.phoneNumber ?? contractor?.phoneNumber,
              workerCategories: worker?.workerCategories,
              contractorType: contractor?.contractorType,
            ),
          ),
          (route) => false,
        );
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
      return;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context.read<LanguageProvider>().locale).error}: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        final loc = AppLocalizations.of(languageProvider.locale);
        return _buildUserCreationUI(loc);
      },
    );
  }

  Widget _buildUserCreationUI(AppLocalizations loc) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppColors.brandGradient,
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
                    Text(
                      loc.createUserProfile,
                      style: const TextStyle(
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
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.userDetailsLabel,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: loc.fullNameLabel,
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return loc.pleaseEnterName;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _includeEmail,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(
                        loc.addEmailAddress,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _includeEmail = value ?? false;
                          if (!_includeEmail) {
                            _emailController.clear();
                          }
                        });
                      },
                    ),
                    if (_includeEmail) ...[
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: loc.email,
                          hintText: loc.exampleEmail,
                          prefixIcon: const Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          final trimmed = value?.trim() ?? '';
                          if (trimmed.isEmpty) {
                            return loc.pleaseEnterEmail;
                          }
                          final emailRegex = RegExp(
                            r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$',
                          );
                          if (!emailRegex.hasMatch(trimmed)) {
                            return loc.pleaseEnterValidEmail;
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: '${loc.phone} *',
                        hintText: loc.examplePhone,
                        prefixIcon: const Icon(Icons.phone_outlined),
                      ),
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        final trimmed = value?.trim() ?? '';
                        if (trimmed.isEmpty) {
                          return loc.pleaseEnterPhoneNumber;
                        }
                        if (!RegExp(r'^0\d{9}$').hasMatch(trimmed)) {
                          return loc.enterValidPhoneNumber;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),
                    Text(
                      loc.skillsAndExpertise,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      loc.selectAtLeastOneSkill,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.text3,
                      ),
                    ),
                    const SizedBox(height: 12),
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
                            child: Text(
                              loc.noCategoriesAvailable,
                              style: const TextStyle(
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
                            color: AppColors.brandPale,
                            border: Border.all(
                              color: AppColors.brandGreen.withValues(
                                alpha: 0.25,
                              ),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildParentTypeSelection(allCategories, loc),
                                const SizedBox(height: 12),
                                if (_activeParentType == null)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: AppColors.brandGreen.withValues(
                                          alpha: 0.25,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      loc.selectCategoryTypeAboveToSeeSubcategories,
                                      style: const TextStyle(
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
                                        '${_parentTypeLabel(_activeParentType!, loc)} ${loc.subcategoriesLabel}',
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
                                                    loc,
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
                                if (_skillsError != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Text(
                                      _skillsError!,
                                      style: const TextStyle(
                                        color: AppColors.red,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                Text(
                                  '${loc.selectedSkills} (${selectedCategories.length})',
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
                                    child: Text(
                                      loc.noSkillsSelected,
                                      style: const TextStyle(
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
                                                loc,
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
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandGreen,
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
                            : Text(
                                loc.createUser,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
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
