import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/contractor.dart';
import '../models/process.dart';
import '../providers/contractor_provider.dart';
import '../services/preferences_service.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/job_images_widget.dart';
import '../widgets/profile_avatar.dart';
import 'contractor_info_screen.dart';
import 'contractor_widgets.dart';
import 'create_process_dialog.dart';

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
  late Future<List<ContractorProcessSummary>> _activeProcessesFuture;
  Future<List<ContractorProcessSummary>>? _historyProcessesFuture;
  bool _historyLoaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    final accountId = PreferencesService().getAccountId();
    _contractorFuture = context.read<ContractorProvider>().getContractor(
          widget.contractorId,
          accountId: accountId,
        );
    _activeProcessesFuture = _loadActiveProcesses();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.index == 1 && !_historyLoaded) {
      setState(() {
        _historyLoaded = true;
        _historyProcessesFuture = _loadHistoryProcesses();
      });
    }
  }

  Future<List<ContractorProcessSummary>> _loadActiveProcesses() {
    final accountId = PreferencesService().getAccountId();
    return ApiService().getActiveContractorProcesses(
      contractorId: widget.contractorId,
      accountId: accountId,
    );
  }

  Future<List<ContractorProcessSummary>> _loadHistoryProcesses() {
    final accountId = PreferencesService().getAccountId();
    return ApiService().getHistoryContractorProcesses(
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
      builder: (dialogContext) => CreateProcessDialog(
        contractorId: widget.contractorId,
        accountId: accountId,
      ),
    );

    if (!mounted || isCreated != true) return;

    setState(() {
      _activeProcessesFuture = _loadActiveProcesses();
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

  Future<void> _deleteProcess(String processId) async {
    final accountId = PreferencesService().getAccountId();
    if (accountId == null) return;

    try {
      await ApiService().deleteContractorProcess(
        contractorId: widget.contractorId,
        processId: processId,
        accountId: accountId,
      );

      if (!mounted) return;

      setState(() {
        _activeProcessesFuture = _loadActiveProcesses();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Process deleted successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete process: $e')),
      );
    }
  }

  Future<void> _confirmDeleteProcess(ContractorProcessSummary process) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Job'),
        content: Text('Are you sure you want to delete "${process.name.isNotEmpty ? process.name : 'this job'}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _deleteProcess(process.processId);
    }
  }

  bool _canDeleteProcess(ContractorProcessSummary process) {
    // Process can be deleted only if it's not assigned or accepted.
    // "Not assigned" means assignedWorkerId is empty.
    // "Not accepted" generally means status is CREATED or PENDING.
    final status = process.status.toUpperCase();
    final isPendingOrCreated = status == 'PENDING' || status == 'CREATED';
    final isNotAssigned = (process.job?.assignedWorkerId ?? '').isEmpty;
    
    return isPendingOrCreated && isNotAssigned;
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
                        _activeProcessesFuture = _loadActiveProcesses();
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

          return FutureBuilder<List<ContractorProcessSummary>>(
            future: _activeProcessesFuture,
            builder: (context, activeSnapshot) {
              final activeProcesses = (activeSnapshot.data ?? [])
                ..sort((a, b) {
                  final startA = a.job?.jobStartTime ?? '';
                  final startB = b.job?.jobStartTime ?? '';
                  return startB.compareTo(startA);
                });

              return NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverToBoxAdapter(
                      child: _buildGradientHeader(contractor),
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: ContractorTabBarDelegate(
                        tabBar: TabBar(
                          controller: _tabController,
                          labelColor: AppColors.blue,
                          unselectedLabelColor: AppColors.gray5,
                          indicatorColor: AppColors.blue,
                          indicatorWeight: 3,
                          tabs: [
                            Tab(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('Pending'),
                                  if (activeProcesses.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.blue,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${activeProcesses.length}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const Tab(text: 'History'),
                          ],
                        ),
                      ),
                    ),
                  ];
                },
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    activeSnapshot.connectionState == ConnectionState.waiting
                        ? const Center(child: CircularProgressIndicator())
                        : activeSnapshot.hasError
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.warning_amber_rounded,
                                        size: 48, color: AppColors.orange),
                                    const SizedBox(height: 12),
                                    const Text('Could not load processes'),
                                    TextButton.icon(
                                      onPressed: () => setState(() {
                                        _activeProcessesFuture =
                                            _loadActiveProcesses();
                                      }),
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              )
                            : _buildProcessList(
                                activeProcesses,
                                'No pending processes',
                                'New processes will appear here.',
                              ),
                    FutureBuilder<List<ContractorProcessSummary>>(
                      future: _historyProcessesFuture,
                      builder: (context, historySnapshot) {
                        if (_historyProcessesFuture == null) {
                          return const Center(
                            child: Text('Press History to load'),
                          );
                        }
                        if (historySnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (historySnapshot.hasError) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.warning_amber_rounded,
                                    size: 48, color: AppColors.orange),
                                const SizedBox(height: 12),
                                const Text('Could not load history'),
                                TextButton.icon(
                                  onPressed: () => setState(() {
                                    _historyProcessesFuture =
                                        _loadHistoryProcesses();
                                  }),
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Retry'),
                                ),
                              ],
                            ),
                          );
                        }
                        final historyProcesses = (historySnapshot.data ?? [])
                          ..sort((a, b) {
                            final startA = a.job?.jobStartTime ?? '';
                            final startB = b.job?.jobStartTime ?? '';
                            return startB.compareTo(startA);
                          });
                        return _buildProcessList(
                          historyProcesses,
                          'No completed processes',
                          'Completed jobs will show here.',
                        );
                      },
                    ),
                  ],
                ),
              );
            },
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
                  ProfileAvatar(
                    id: contractor.id,
                    isWorker: false,
                    radius: 28,
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
        if (_tabController.index == 0) {
          _activeProcessesFuture = _loadActiveProcesses();
        } else {
          _historyProcessesFuture = _loadHistoryProcesses();
        }
      }),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: processes.length,
        itemBuilder: (context, index) => _buildProcessCard(processes[index]),
      ),
    );
  }

  String _formatPayment(PaymentInformation payment) {
    final method = payment.method ?? 'N/A';
    final amount = payment.amount % 1 == 0
        ? payment.amount.toInt().toString()
        : payment.amount.toString();
    return '$method · $amount';
  }

  Widget _buildProcessCard(ContractorProcessSummary process) {
    final job = process.job;
    final statusColor = getProcessStatusColor(process.status);

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
                    ],
                  ),
                ),
                if (_canDeleteProcess(process))
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.red, size: 20),
                    onPressed: () => _confirmDeleteProcess(process),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                const SizedBox(width: 8),
                ProcessStatusChip(
                  label: process.status,
                  color: statusColor,
                ),
              ],
            ),
            if (job != null) ...[
              const Divider(height: 20),
              // Job images
              JobImagesWidget(jobId: job.id, height: 150, contractorId: widget.contractorId),
              const SizedBox(height: 8),
              _buildDetailRow(Icons.schedule, 'Start', formatJobStartTime(job.jobStartTime)),
              const SizedBox(height: 6),
              _buildDetailRow(Icons.timer_outlined, 'Duration', '${job.durationHours}h'),
              if (job.paymentInformation != null) ...[
                const SizedBox(height: 6),
                _buildDetailRow(
                  Icons.payments_outlined,
                  'Payment',
                  _formatPayment(job.paymentInformation!),
                ),
              ],
              const SizedBox(height: 6),
              _buildAddressRow(
                Icons.location_on_outlined,
                'Location',
                job.latitude,
                job.longitude,
              ),
              const SizedBox(height: 8),
              if (job.assignedWorkerId.isNotEmpty) ...[
                const Divider(height: 12),
                Row(
                  children: [
                    ProfileAvatar(id: job.assignedWorkerId, isWorker: true, radius: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.assignedWorkerName.isNotEmpty ? job.assignedWorkerName : 'Assigned worker',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text('Tap to view worker details', style: const TextStyle(fontSize: 12, color: AppColors.text3)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        // open worker details screen if available
                        final workerId = job.assignedWorkerId;
                        if (workerId.isNotEmpty) {
                          Navigator.pushNamed(context, '/worker/$workerId');
                        }
                      },
                      icon: const Icon(Icons.arrow_forward_ios, size: 18),
                    ),
                  ],
                ),
              ],
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

}


