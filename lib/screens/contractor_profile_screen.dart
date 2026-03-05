import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/contractor.dart';
import '../models/process.dart';
import '../models/worker.dart';
import '../providers/contractor_provider.dart';
import '../services/preferences_service.dart';
import '../services/api_service.dart';
import 'switch_account_screen.dart';

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
  late Future<List<ContractorProcessSummary>> _processesFuture;

  @override
  void initState() {
    super.initState();
    final accountId = PreferencesService().getAccountId();
    _contractorFuture = context.read<ContractorProvider>().getContractor(
      widget.contractorId,
      accountId: accountId,
    );
    _processesFuture = _loadContractorProcesses();
  }

  Future<List<ContractorProcessSummary>> _loadContractorProcesses() {
    final accountId = PreferencesService().getAccountId();
    return ApiService().getContractorProcesses(
      contractorId: widget.contractorId,
      accountId: accountId,
    );
  }

  void _switchProfile() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Switch Profile'),
        content: const Text('Open switch account to login as another user?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SwitchAccountScreen(),
                ),
              );
            },
            child: const Text('Switch Account', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateProcessDialog() async {
    final accountId = PreferencesService().getAccountId();
    if (accountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account ID not found')),
      );
      return;
    }

    final isCreated = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _CreateProcessDialog(
        contractorId: widget.contractorId,
        accountId: accountId,
      ),
    );

    if (!mounted || isCreated != true) return;

    setState(() {
      _processesFuture = _loadContractorProcesses();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Process created successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contractor Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_task),
            tooltip: 'Create Process',
            onPressed: _showCreateProcessDialog,
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
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
                            .getContractor(
                              widget.contractorId,
                              accountId: PreferencesService().getAccountId(),
                            );
                        _processesFuture = _loadContractorProcesses();
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
                    onPressed: () {
                      Navigator.of(context)
                          .pushNamedAndRemoveUntil('/', (_) => false);
                    },
                    child: const Text('Go to Home'),
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
                const Text(
                  'Created Processes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                FutureBuilder<List<ContractorProcessSummary>>(
                  future: _processesFuture,
                  builder: (context, processSnapshot) {
                    if (processSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (processSnapshot.hasError) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade100),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Error loading processes: ${processSnapshot.error}',
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _processesFuture = _loadContractorProcesses();
                                });
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }

                    final processes = processSnapshot.data ?? [];

                    if (processes.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('No processes created yet'),
                      );
                    }

                    return Column(
                      children: processes
                          .map(
                            (process) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildProcessCard(process),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProcessCard(ContractorProcessSummary process) {
    final job = process.job;
    final processStatusColor = _getStatusColor(process.status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  process.name.isEmpty ? 'Unnamed Process' : process.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: processStatusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  process.status,
                  style: TextStyle(
                    color: processStatusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Process ID: ${process.processId}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          if (job != null) ...[
            const SizedBox(height: 10),
            Text(
              'Job Status: ${job.status}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Start Time: ${_formatJobStartTime(job.jobStartTime)}',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              'Duration: ${job.durationHours} hour(s)',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              'Location: ${job.latitude.toStringAsFixed(6)}, ${job.longitude.toStringAsFixed(6)}',
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'CREATED':
      case 'PENDING':
        return Colors.orange.shade700;
      case 'IN_PROGRESS':
        return Colors.blue.shade700;
      case 'COMPLETED':
        return Colors.green.shade700;
      case 'FAILED':
      case 'CANCELLED':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  String _formatJobStartTime(String rawDateTime) {
    if (rawDateTime.trim().isEmpty) {
      return 'N/A';
    }

    final normalized = rawDateTime.contains(' ')
        ? rawDateTime.replaceFirst(' ', 'T')
        : rawDateTime;
    final parsed = DateTime.tryParse(normalized);

    if (parsed == null) {
      return rawDateTime;
    }

    final year = parsed.year.toString().padLeft(4, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    final day = parsed.day.toString().padLeft(2, '0');
    final hour = parsed.hour.toString().padLeft(2, '0');
    final minute = parsed.minute.toString().padLeft(2, '0');

    return '$year-$month-$day $hour:$minute';
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

class _CreateProcessDialog extends StatefulWidget {
  final String contractorId;
  final String accountId;

  const _CreateProcessDialog({
    required this.contractorId,
    required this.accountId,
  });

  @override
  State<_CreateProcessDialog> createState() => _CreateProcessDialogState();
}

class _CreateProcessDialogState extends State<_CreateProcessDialog> {
  static const LatLng _defaultLocation = LatLng(6.927079, 79.861244);
  
  final _formKey = GlobalKey<FormState>();
  final _processNameController = TextEditingController();
  final _processDescriptionController = TextEditingController();
  
  // Job fields
  final _jobDescriptionController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _durationController = TextEditingController();
  final _amountController = TextEditingController();

  late Future<List<Category>> _categoriesFuture;
  late Future<List<Wallet>> _walletsFuture;
  late MapController _mapController;

  List<String> _selectedCategories = [];
  String? _selectedWalletId;
  bool _isSubmitting = false;
  LatLng _selectedLocation = _defaultLocation;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _categoriesFuture =
        ApiService().getCategories(accountId: widget.accountId);
    _walletsFuture = ApiService().getWallets(accountId: widget.accountId);
  }

  Future<void> _submitProcess() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one category')),
      );
      return;
    }

    if (_selectedWalletId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a wallet')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final job = Job(
        description: _jobDescriptionController.text.trim(),
        startTime: _startTimeController.text.trim(),
        duration: int.parse(_durationController.text.trim()),
        latitude: _selectedLocation.latitude,
        longitude: _selectedLocation.longitude,
        jobCategories: _selectedCategories,
        paymentInformation: PaymentInformation(
          amount: double.parse(_amountController.text.trim()),
          walletId: _selectedWalletId!,
        ),
      );

      final processRequest = ProcessRequest(
        name: _processNameController.text.trim(),
        description: _processDescriptionController.text.trim(),
        jobs: [job],
      );

      await ApiService().createContractorProcess(
        contractorId: widget.contractorId,
        accountId: widget.accountId,
        processRequest: processRequest,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _selectStartTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );

    if (date == null) return;

    if (!mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null) return;

    final dateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    final formattedDateTime =
      '${dateTime.year.toString().padLeft(4, '0')}-'
      '${dateTime.month.toString().padLeft(2, '0')}-'
      '${dateTime.day.toString().padLeft(2, '0')}T'
      '${dateTime.hour.toString().padLeft(2, '0')}:'
      '${dateTime.minute.toString().padLeft(2, '0')}';

    _startTimeController.text = formattedDateTime;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create Process',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Process Information
                  const Text(
                    'Process Information',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _processNameController,
                    decoration: const InputDecoration(
                      labelText: 'Process Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter process name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _processDescriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Process Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  // Job Information
                  const Text(
                    'Job Information',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _jobDescriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Job Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter job description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _startTimeController,
                    decoration: InputDecoration(
                      labelText: 'Start Time',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: _selectStartTime,
                      ),
                    ),
                    readOnly: true,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please select start time';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _durationController,
                          decoration: const InputDecoration(
                            labelText: 'Duration (hours)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Required';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Invalid';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Job Location',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 250,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _selectedLocation,
                          initialZoom: 15.0,
                          minZoom: 3.0,
                          maxZoom: 18.0,
                          onTap: (_, position) {
                            setState(() {
                              _selectedLocation = position;
                            });
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.recodextech.fixflow_app',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _selectedLocation,
                                width: 80.0,
                                height: 80.0,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      color: Colors.red,
                                      size: 40,
                                      shadows: const [
                                        Shadow(
                                          color: Colors.black,
                                          blurRadius: 2,
                                        ),
                                      ],
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
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Latitude',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _selectedLocation.latitude.toStringAsFixed(8),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Courier',
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Longitude',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _selectedLocation.longitude.toStringAsFixed(8),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Courier',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Job Categories',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(7),
                              topRight: Radius.circular(7),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${_selectedCategories.length} Selected',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                              if (_selectedCategories.isNotEmpty)
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedCategories.clear();
                                    });
                                  },
                                  child: Text(
                                    'Clear All',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue.shade800,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        FutureBuilder<List<Category>>(
                          future: _categoriesFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const SizedBox(
                                height: 100,
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }

                            if (snapshot.hasError) {
                              return Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text('Error: ${snapshot.error}'),
                              );
                            }

                            final categories = snapshot.data ?? [];

                            return SizedBox(
                              height: 150,
                              child: ListView.builder(
                                itemCount: categories.length,
                                itemBuilder: (context, index) {
                                  final category = categories[index];
                                  return CheckboxListTile(
                                    title: Text(category.name),
                                    value: _selectedCategories.contains(category.id),
                                    dense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                    onChanged: (bool? value) {
                                      setState(() {
                                        if (value == true) {
                                          _selectedCategories.add(category.id);
                                        } else {
                                          _selectedCategories.remove(category.id);
                                        }
                                      });
                                    },
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Payment Information',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<List<Wallet>>(
                    future: _walletsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          height: 60,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text('Error loading wallets: ${snapshot.error}'),
                        );
                      }

                      final wallets = snapshot.data ?? [];

                      return DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Select Wallet',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.account_balance_wallet),
                        ),
                        value: _selectedWalletId,
                        items: wallets
                            .map((wallet) => DropdownMenuItem(
                                  value: wallet.id,
                                  child: Text(
                                    '${wallet.name} - \$${wallet.balance.toStringAsFixed(2)}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedWalletId = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a wallet';
                          }
                          return null;
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.attach_money),
                      prefixText: ' ',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter amount';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Invalid amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitProcess,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Create Process'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _processNameController.dispose();
    _processDescriptionController.dispose();
    _jobDescriptionController.dispose();
    _startTimeController.dispose();
    _durationController.dispose();
    _amountController.dispose();
    _mapController.dispose();
    super.dispose();
  }
}
