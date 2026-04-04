import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/contractor.dart';
import '../models/process.dart';
import '../providers/contractor_provider.dart';
import '../services/preferences_service.dart';
import '../services/api_service.dart';
import '../theme.dart';
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
      builder: (dialogContext) => CreateProcessDialog(
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
                  delegate: ContractorTabBarDelegate(
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
                      const SizedBox(height: 2),
                      Text(
                        'ID: ${process.processId}',
                        style: const TextStyle(fontSize: 11, color: AppColors.text3),
                      ),
                    ],
                  ),
                ),
                ProcessStatusChip(
                  label: process.status,
                  color: statusColor,
                ),
              ],
            ),
            if (job != null) ...[
              const Divider(height: 20),
              _buildDetailRow(Icons.schedule, 'Start', formatJobStartTime(job.jobStartTime)),
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

}


