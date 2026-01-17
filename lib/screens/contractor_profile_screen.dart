import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/contractor.dart';
import '../providers/contractor_provider.dart';
import '../services/preferences_service.dart';
import 'create_contractor_screen.dart';

class ContractorProfileScreen extends StatefulWidget {
  final String contractorId;

  const ContractorProfileScreen({
    super.key,
    required this.contractorId,
  });

  @override
  State<ContractorProfileScreen> createState() => _ContractorProfileScreenState();
}

class _ContractorProfileScreenState extends State<ContractorProfileScreen> {
  late Future<Contractor?> _contractorFuture;

  @override
  void initState() {
    super.initState();
    _contractorFuture =
        context.read<ContractorProvider>().getContractor(widget.contractorId);
  }

  void _editProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const CreateContractorScreen()),
    );
  }

  Future<void> _switchProfile() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Switch Profile'),
        content: const Text('Are you sure you want to switch profiles?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await PreferencesService().clearAll();
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
              }
            },
            child: const Text('Switch', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contractor Profile'),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Text('Edit Profile'),
                onTap: _editProfile,
              ),
              PopupMenuItem(
                child: const Text('Switch Profile'),
                onTap: _switchProfile,
              ),
            ],
          ),
        ],
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
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _contractorFuture = context
                            .read<ContractorProvider>()
                            .getContractor(widget.contractorId);
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.business_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Contractor profile not found'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _editProfile,
                    child: const Text('Create Profile'),
                  ),
                ],
              ),
            );
          }

          final contractor = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade400, Colors.orange.shade600],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.white,
                            child: Text(
                              contractor.contractorName[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  contractor.contractorName,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'ID: ${contractor.id}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
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
                const SizedBox(height: 24),
                // Personal Information
                const Text(
                  'Company Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoCard('Company Name', contractor.contractorName, Icons.business),
                const SizedBox(height: 12),
                _buildInfoCard('Type', contractor.contractorType, Icons.category),
                const SizedBox(height: 12),
                _buildInfoCard('Email', contractor.email, Icons.email),
                const SizedBox(height: 12),
                _buildInfoCard('Phone', contractor.phoneNumber, Icons.phone),
                const SizedBox(height: 12),
                _buildInfoCard(
                  'Account ID',
                  contractor.accountId ?? 'N/A',
                  Icons.account_circle,
                ),
                const SizedBox(height: 24),
                // Type Badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: contractor.contractorType == 'COMPANY'
                            ? Colors.blue.shade100
                            : Colors.purple.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        contractor.contractorType,
                        style: TextStyle(
                          color: contractor.contractorType == 'COMPANY'
                              ? Colors.blue.shade800
                              : Colors.purple.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Action Buttons
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _editProfile,
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Profile'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
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

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.orange.shade600),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
