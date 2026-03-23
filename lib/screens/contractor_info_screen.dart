import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/contractor.dart';
import '../providers/contractor_provider.dart';
import '../services/preferences_service.dart';
import '../services/api_service.dart';
import '../theme.dart';

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
                  Text('Error: ${snapshot.error}',
                      style: const TextStyle(color: AppColors.text2)),
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
                  Icon(Icons.business_outlined, size: 48, color: AppColors.gray5),
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
                                child: const Icon(Icons.arrow_back,
                                    color: Colors.white),
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
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(
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
                                        color:
                                            Colors.white.withValues(alpha: 0.8),
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
                        // Edit Information
                        const Text(
                          'Edit Information',
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
                            labelText: 'Name',
                            prefixIcon: Icon(Icons.business_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        // Type toggle
                        Row(
                          children: [
                            Expanded(
                              child: _buildTypeOption(
                                  'COMPANY', 'Company', Icons.business),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTypeOption(
                                  'INDIVIDUAL', 'Individual', Icons.person),
                            ),
                          ],
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
                            if (value == null || value.trim().isEmpty) {
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
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter phone number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _saveContractor,
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
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text(
                                    'Save Changes',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Payment Cards section (placeholder for future integration)
                        const Text(
                          'Payment Cards',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Manage your payment methods for job payments',
                          style: TextStyle(fontSize: 13, color: AppColors.text3),
                        ),
                        const SizedBox(height: 12),
                        _buildPaymentCardsSection(),
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

  Widget _buildTypeOption(String value, String label, IconData icon) {
    final selected = _contractorType == value;
    return GestureDetector(
      onTap: () => setState(() => _contractorType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.bluePale : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.blue : AppColors.gray3,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 24,
                color: selected ? AppColors.blue : AppColors.gray5),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? AppColors.blue : AppColors.text2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCardsSection() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: ApiService().getPaymentCards(
        accountId: PreferencesService().getAccountId() ?? '',
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final cards = snapshot.data ?? [];

        return Column(
          children: [
            if (cards.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.gray1,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(Icons.credit_card_off,
                        size: 36, color: AppColors.gray4),
                    const SizedBox(height: 8),
                    const Text(
                      'No payment cards added',
                      style:
                          TextStyle(fontSize: 14, color: AppColors.text2),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Add a card to enable job payments',
                      style:
                          TextStyle(fontSize: 12, color: AppColors.text3),
                    ),
                  ],
                ),
              )
            else
              ...cards.map((card) => _buildPaymentCardTile(card)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                onPressed: _showAddCardDialog,
                icon: const Icon(Icons.add_card, size: 20),
                label: const Text('Add Payment Card'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.blue,
                  side: const BorderSide(color: AppColors.blue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPaymentCardTile(Map<String, dynamic> card) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.gray2),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.bluePale,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.credit_card, color: AppColors.blue, size: 20),
        ),
        title: Text(
          card['cardNumber'] ?? '**** **** **** ****',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          card['cardHolder'] ?? 'Card holder',
          style: const TextStyle(fontSize: 12, color: AppColors.text3),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: AppColors.red, size: 20),
          onPressed: () => _deleteCard(card['id']),
        ),
      ),
    );
  }

  void _showAddCardDialog() {
    final cardNumberController = TextEditingController();
    final cardHolderController = TextEditingController();
    final expiryController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Payment Card'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: cardHolderController,
              decoration: const InputDecoration(
                labelText: 'Card Holder Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: cardNumberController,
              decoration: const InputDecoration(
                labelText: 'Card Number',
                prefixIcon: Icon(Icons.credit_card),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: expiryController,
              decoration: const InputDecoration(
                labelText: 'Expiry (MM/YY)',
                prefixIcon: Icon(Icons.date_range),
              ),
              keyboardType: TextInputType.datetime,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ApiService().addPaymentCard(
                  accountId: PreferencesService().getAccountId() ?? '',
                  cardHolder: cardHolderController.text.trim(),
                  cardNumber: cardNumberController.text.trim(),
                  expiry: expiryController.text.trim(),
                );
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) setState(() {});
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Add Card'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCard(String? cardId) async {
    if (cardId == null) return;
    try {
      await ApiService().deletePaymentCard(
        accountId: PreferencesService().getAccountId() ?? '',
        cardId: cardId,
      );
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
