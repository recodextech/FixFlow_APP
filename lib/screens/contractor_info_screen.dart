import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/contractor.dart';
import '../providers/contractor_provider.dart';
import '../services/preferences_service.dart';
import '../widgets/home_navigation_button.dart';

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
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  late Future<Contractor?> _contractorFuture;

  String _contractorType = 'COMPANY';
  bool _isSubmitting = false;
  bool _isFormInitialized = false;

  @override
  void initState() {
    super.initState();
    _contractorFuture = widget.initialContractor != null
        ? Future.value(widget.initialContractor)
        : _loadContractor();
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

    _nameController.text = contractor.contractorName;
    _emailController.text = contractor.email;
    _phoneController.text = contractor.phoneNumber;
    _contractorType = contractor.contractorType.isEmpty
        ? 'COMPANY'
        : contractor.contractorType;
    _isFormInitialized = true;
  }

  Future<void> _saveContractor() async {
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

    setState(() {
      _isSubmitting = true;
    });

    try {
      final updated = await context.read<ContractorProvider>().updateContractor(
            contractorId: widget.contractorId,
            accountId: accountId,
            contractorName: _nameController.text.trim(),
            contractorType: _contractorType,
            email: _emailController.text.trim(),
            phoneNumber: _phoneController.text.trim(),
          );

      await PreferencesService().setContractorName(updated.contractorName);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(updated);
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update contractor: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contractor Information'),
        actions: const [HomeNavigationButton()],
      ),
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
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 12),
                  Text('Error: ${snapshot.error}'),
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
                  const Icon(Icons.business_outlined,
                      size: 64, color: Colors.grey),
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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Contractor ID: ${contractor.id}'),
                        const SizedBox(height: 6),
                        Text('Account ID: ${contractor.accountId ?? 'N/A'}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Contractor Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter contractor name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _contractorType,
                    decoration: const InputDecoration(
                      labelText: 'Contractor Type',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'COMPANY', child: Text('Company')),
                      DropdownMenuItem(
                          value: 'INDIVIDUAL', child: Text('Individual')),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      setState(() {
                        _contractorType = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter phone number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _saveContractor,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save Changes'),
                  ),
                ],
              ),
            ),
          );
        },
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
