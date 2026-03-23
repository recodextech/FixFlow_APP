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
import '../theme.dart';
import 'contractor_info_screen.dart';

class ContractorProfileScreen extends StatefulWidget {
  final String contractorId;

  const ContractorProfileScreen({
    super.key,
    required this.contractorId,
  });

  @override
  State<ContractorProfileScreen> createState() =>
      _ContractorProfileScreenState();
}

class _ContractorProfileScreenState extends State<ContractorProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<Contractor?> _contractorFuture;
  late Future<List<ContractorProcessSummary>> _processesFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final accountId = PreferencesService().getAccountId();
    _contractorFuture = context.read<ContractorProvider>().getContractor(
          widget.contractorId,
          accountId: accountId,
        );
    _processesFuture = _loadContractorProcesses();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<List<ContractorProcessSummary>> _loadContractorProcesses() {
    final accountId = PreferencesService().getAccountId();
    return ApiService().getContractorProcesses(
      contractorId: widget.contractorId,
      accountId: accountId,
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

  Future<void> _openContractorInfo({Contractor? contractor}) async {
    final updatedContractor = await Navigator.of(context).push<Contractor>(
      MaterialPageRoute(
        builder: (_) => ContractorInfoScreen(
          contractorId: widget.contractorId,
          initialContractor: contractor,
        ),
      ),
    );

    if (!mounted || updatedContractor == null) return;

    setState(() {
      _contractorFuture = Future.value(updatedContractor);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateProcessDialog,
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Job'),
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
                  Icon(Icons.error_outline, size: 48, color: AppColors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}',
                      style: const TextStyle(color: AppColors.text2)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _contractorFuture = context
                            .read<ContractorProvider>()
                            .getContractor(widget.contractorId,
                                accountId: PreferencesService().getAccountId());
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
                  Icon(Icons.business_outlined, size: 48, color: AppColors.gray5),
                  const SizedBox(height: 16),
                  const Text('Contractor profile not found'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context, '/home', (_) => false),
                    child: const Text('Go to Home'),
                  ),
                ],
              ),
            );
          }

          final contractor = snapshot.data!;

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(
                  child: _buildGradientHeader(contractor),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _ContractorTabBarDelegate(
                    tabBar: TabBar(
                      controller: _tabController,
                      labelColor: AppColors.blue,
                      unselectedLabelColor: AppColors.gray5,
                      indicatorColor: AppColors.blue,
                      indicatorWeight: 3,
                      tabs: const [
                        Tab(text: 'Pending'),
                        Tab(text: 'History'),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: FutureBuilder<List<ContractorProcessSummary>>(
              future: _processesFuture,
              builder: (context, processSnapshot) {
                if (processSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (processSnapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 48, color: AppColors.orange),
                        const SizedBox(height: 12),
                        const Text('Could not load processes'),
                        TextButton.icon(
                          onPressed: () => setState(() {
                            _processesFuture = _loadContractorProcesses();
                          }),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final processes = processSnapshot.data ?? [];
                final ongoingProcesses = processes
                    .where((p) => !_isCompletedStatus(p.status))
                    .toList();
                final completedProcesses = processes
                    .where((p) => _isCompletedStatus(p.status))
                    .toList();

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildProcessList(ongoingProcesses, 'No pending processes',
                        'New processes will appear here.'),
                    _buildProcessList(completedProcesses, 'No completed processes',
                        'Completed jobs will show here.'),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildGradientHeader(Contractor contractor) {
    return Container(
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
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const Spacer(),
                  const Text(
                    'Contractor Dashboard',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _openContractorInfo(contractor: contractor),
                    child: const Icon(Icons.edit_outlined, color: Colors.white),
                  ),
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
                            ? contractor.contractorName[0].toUpperCase()
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
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                contractor.contractorType,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
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
    );
  }

  Widget _buildProcessList(
      List<ContractorProcessSummary> processes, String emptyTitle, String emptySubtitle) {
    if (processes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_rounded, size: 48, color: AppColors.gray4),
              const SizedBox(height: 16),
              Text(emptyTitle,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.text)),
              const SizedBox(height: 6),
              Text(emptySubtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: AppColors.text2)),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => setState(() {
        _processesFuture = _loadContractorProcesses();
      }),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: processes.length,
        itemBuilder: (context, index) => _buildProcessCard(processes[index]),
      ),
    );
  }

  bool _isCompletedStatus(String status) {
    return status.trim().toUpperCase() == 'COMPLETED';
  }

  Widget _buildProcessCard(ContractorProcessSummary process) {
    final job = process.job;
    final statusColor = _getStatusColor(process.status);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.gray2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.bluePale,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.work_outline, size: 20, color: AppColors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        process.name.isEmpty ? 'Unnamed Process' : process.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ID: ${process.processId}',
                        style: const TextStyle(fontSize: 11, color: AppColors.text3),
                      ),
                    ],
                  ),
                ),
                _ProcessStatusChip(
                  label: process.status,
                  color: statusColor,
                ),
              ],
            ),
            if (job != null) ...[
              const Divider(height: 20),
              _buildDetailRow(Icons.schedule, 'Start', _formatJobStartTime(job.jobStartTime)),
              const SizedBox(height: 6),
              _buildDetailRow(Icons.timer_outlined, 'Duration', '${job.durationHours}h'),
              const SizedBox(height: 6),
              _buildAddressRow(
                Icons.location_on_outlined,
                'Location',
                job.latitude,
                job.longitude,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.text3),
        const SizedBox(width: 6),
        Text('$label: ', style: const TextStyle(fontSize: 12, color: AppColors.text3)),
        Expanded(
          child: Text(value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.text2)),
        ),
      ],
    );
  }

  Widget _buildAddressRow(IconData icon, String label, double lat, double lng) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.text3),
        const SizedBox(width: 6),
        Text('$label: ', style: const TextStyle(fontSize: 12, color: AppColors.text3)),
        Expanded(
          child: FutureBuilder<String>(
            future: ApiService().reverseGeocode(lat, lng),
            builder: (context, snap) {
              return Text(
                snap.data ?? 'Loading...',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.text2),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'CREATED':
      case 'PENDING':
        return AppColors.orange;
      case 'IN_PROGRESS':
        return AppColors.blue;
      case 'COMPLETED':
        return AppColors.green;
      case 'FAILED':
      case 'CANCELLED':
        return AppColors.red;
      default:
        return AppColors.gray5;
    }
  }

  String _formatJobStartTime(String rawDateTime) {
    if (rawDateTime.trim().isEmpty) return 'N/A';
    final normalized = rawDateTime.contains(' ')
        ? rawDateTime.replaceFirst(' ', 'T')
        : rawDateTime;
    final parsed = DateTime.tryParse(normalized);
    if (parsed == null) return rawDateTime;
    return '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')} '
        '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
  }
}

class _ContractorTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _ContractorTabBarDelegate({required this.tabBar});

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: Theme.of(context).scaffoldBackgroundColor, child: tabBar);
  }

  @override
  bool shouldRebuild(covariant _ContractorTabBarDelegate oldDelegate) => false;
}

class _ProcessStatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _ProcessStatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
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

  String? _selectedCategory;
  String? _selectedWalletId;
  bool _isSubmitting = false;
  LatLng _selectedLocation = _defaultLocation;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _categoriesFuture = ApiService().getCategories(accountId: widget.accountId);
    _walletsFuture = ApiService().getWallets(accountId: widget.accountId);
  }

  Future<void> _submitProcess() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
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
        jobCategories: [_selectedCategory!],
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

    final dateTime =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    final formattedDateTime = '${dateTime.year.toString().padLeft(4, '0')}-'
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
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                  FutureBuilder<List<Category>>(
                    future: _categoriesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const SizedBox(
                          height: 60,
                          child:
                              Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text('Error: ${snapshot.error}'),
                        );
                      }

                      final categories = snapshot.data ?? [];

                      return DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Select Category',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.category),
                        ),
                        value: _selectedCategory,
                        items: categories
                            .map((cat) => DropdownMenuItem(
                                  value: cat.id,
                                  child: Text(cat.name),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a category';
                          }
                          return null;
                        },
                      );
                    },
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
                          child:
                              Text('Error loading wallets: ${snapshot.error}'),
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
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
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
                        onPressed:
                            _isSubmitting ? null : () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitProcess,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
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
