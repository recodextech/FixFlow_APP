import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/contractor_provider.dart';
import '../services/preferences_service.dart';
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
  bool _isSubmitting = false;
  Map<String, dynamic>? _result;

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      try {
        final result = await context.read<ContractorProvider>().createContractor(
          contractorName: _nameController.text,
          contractorType: _contractorType,
          email: _emailController.text,
          phoneNumber: _phoneController.text,
        );

        setState(() {
          _result = result;
          _formKey.currentState!.reset();
          _contractorType = 'COMPANY';
          _nameController.clear();
          _emailController.clear();
          _phoneController.clear();
        });

        // Save to preferences
        if (result['id'] != null) {
          await PreferencesService().setContractorId(result['id']);
          await PreferencesService().setContractorName(_nameController.text);
          if (result['accountId'] != null) {
            await PreferencesService().setAccountId(result['accountId']);
          }
        }

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
      appBar: AppBar(
        title: const Text('Create Contractor'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
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
                  labelText: 'Contractor Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter contractor name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _contractorType,
                decoration: const InputDecoration(
                  labelText: 'Contractor Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'COMPANY', child: Text('Company')),
                  DropdownMenuItem(value: 'INDIVIDUAL', child: Text('Individual')),
                ]
                    .map((item) => item)
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _contractorType = value);
                  }
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
                    : const Text('Create Contractor'),
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
                        'Contractor Created Successfully',
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
