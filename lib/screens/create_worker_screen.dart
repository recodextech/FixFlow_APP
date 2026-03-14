import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/worker.dart';
import '../providers/worker_provider.dart';
import '../services/preferences_service.dart';
import '../widgets/home_navigation_button.dart';
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

  List<Category> _selectedCategories = [];
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

        final result = await context.read<WorkerProvider>().createWorker(
              workerName: workerName,
              email: workerEmail,
              phoneNumber: workerPhone,
              workerCategories: _selectedCategories.map((c) => c.id).toList(),
            );

        // Persist created worker as the active profile without clearing contractor data.
        if (result['id'] != null) {
          final prefs = PreferencesService();
          final workerId = result['id'].toString();
          await prefs.setWorkerId(workerId);
          await prefs.setWorkerName(workerName);

          if (result['accountId'] != null) {
            await prefs.setWorkerAccountId(result['accountId'].toString());
          }

          await prefs.activateWorkerProfile();
        }

        setState(() {
          _result = result;
          _formKey.currentState!.reset();
          _selectedCategories.clear();
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
      appBar: AppBar(
        title: const Text('Create Worker'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [HomeNavigationButton()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Worker Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter worker name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),
              const Text(
                'Worker Categories',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Consumer<WorkerProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading && provider.categories.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (provider.error != null && provider.categories.isEmpty) {
                    return Text(
                      'Error loading categories: ${provider.error}',
                      style: const TextStyle(color: Colors.red),
                    );
                  }

                  return DropdownButton<Category>(
                    isExpanded: true,
                    hint: const Text('Select a category'),
                    items: provider.categories
                        .where((cat) =>
                            !_selectedCategories.any((s) => s.id == cat.id))
                        .map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category.name),
                      );
                    }).toList(),
                    onChanged: (Category? value) {
                      if (value != null) {
                        _addCategory(value);
                      }
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              // Selected categories
              if (_selectedCategories.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedCategories.map((category) {
                    return Chip(
                      label: Text(category.name),
                      onDeleted: () => _removeCategory(category),
                      deleteIcon: const Icon(Icons.close),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create Worker'),
              ),
              // Result display
              if (_result != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    border: Border.all(color: Colors.green),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Worker Created Successfully',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('ID: ${_result!['id']}'),
                      if (_result!['accountId'] != null)
                        Text('Account: ${_result!['accountId']}'),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
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
