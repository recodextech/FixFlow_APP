import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/contractor.dart';
import '../models/process.dart';
import '../models/worker.dart';
import '../providers/contractor_provider.dart';
import '../providers/language_provider.dart';
import '../services/preferences_service.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/job_images_widget.dart';
import '../widgets/profile_avatar.dart';
import '../l10n/app_localizations.dart';
import 'contractor_info_screen.dart';
import 'contractor_widgets.dart';
import 'create_process_dialog.dart';

class ContractorProfileScreen extends StatefulWidget {
  final String contractorId;

  const ContractorProfileScreen({super.key, required this.contractorId});

  @override
  State<ContractorProfileScreen> createState() =>
      _ContractorProfileScreenState();
}

class _ContractorProfileScreenState extends State<ContractorProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<Contractor?> _contractorFuture;
  late Future<ContractorActiveProcesses> _activeProcessesFuture;
  Future<List<ContractorProcessSummary>>? _historyProcessesFuture;
  int _lastFetchedTabIndex = 0;
  bool _isActiveProcessesExpanded = false;
  final Set<String> _claimActionInProgress = {};
  final Map<String, Future<Worker?>> _claimWorkerFutures = {};

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
    // The listener fires more than once per switch (tap start + animation end),
    // so only refetch when the settled index actually differs.
    final index = _tabController.index;
    if (index == _lastFetchedTabIndex) return;
    _lastFetchedTabIndex = index;
    setState(() {
      if (index == 0) {
        _activeProcessesFuture = _loadActiveProcesses();
      } else {
        _historyProcessesFuture = _loadHistoryProcesses();
      }
    });
  }

  Future<ContractorActiveProcesses> _loadActiveProcesses() {
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

  AppLocalizations get _loc => AppLocalizations.of(
    Provider.of<LanguageProvider>(context, listen: false).locale,
  );

  Future<void> _showCreateProcessDialog() async {
    final accountId = PreferencesService().getAccountId();
    if (accountId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_loc.accountIdMissing)));
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

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(_loc.processCreatedSuccessfully)));
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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_loc.processDeletedSuccessfully)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_loc.failedToDeleteProcess}: $e')),
      );
    }
  }

  Future<void> _confirmDeleteProcess(ContractorProcessSummary process) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_loc.deleteJob),
        content: Text(
          _loc.confirmDeleteJob(
            process.name.isNotEmpty ? process.name : _loc.thisJob,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: Text(_loc.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _deleteProcess(process.processId);
    }
  }

  Future<void> _approveJobClaim(String jobId) async {
    await _runJobClaimAction(
      jobId: jobId,
      action: (accountId) => ApiService().approveJobClaim(
        contractorId: widget.contractorId,
        jobId: jobId,
        accountId: accountId,
      ),
      successMessage: _loc.jobClaimApproved,
      failureMessage: _loc.failedToApproveJobClaim,
    );
  }

  Future<void> _confirmRejectJobClaim(String jobId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_loc.rejectJobClaimTitle),
        content: Text(_loc.rejectJobClaimMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: Text(_loc.reject),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _runJobClaimAction(
      jobId: jobId,
      action: (accountId) => ApiService().rejectJobClaim(
        contractorId: widget.contractorId,
        jobId: jobId,
        accountId: accountId,
      ),
      successMessage: _loc.jobClaimRejected,
      failureMessage: _loc.failedToRejectJobClaim,
    );
  }

  Future<void> _runJobClaimAction({
    required String jobId,
    required Future<void> Function(String accountId) action,
    required String successMessage,
    required String failureMessage,
  }) async {
    final accountId = PreferencesService().getAccountId();
    if (accountId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_loc.accountIdMissing)));
      return;
    }

    setState(() => _claimActionInProgress.add(jobId));

    try {
      await action(accountId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$failureMessage: $e')));
    } finally {
      // Reload either way: on failure the claim may have expired or been
      // handled elsewhere, so show the current state.
      if (mounted) {
        setState(() {
          _claimActionInProgress.remove(jobId);
          _activeProcessesFuture = _loadActiveProcesses();
        });
      }
    }
  }

  Future<Worker?> _loadClaimWorker(String workerId) {
    return _claimWorkerFutures.putIfAbsent(
      workerId,
      () => ApiService()
          .getWorker(workerId, accountId: PreferencesService().getAccountId())
          .catchError((_) => null),
    );
  }

  /// Formats a UTC claim timestamp (RFC 3339) in the device's local time.
  String _formatClaimTime(String rawTime) {
    final parsed = DateTime.tryParse(rawTime);
    if (parsed == null) return rawTime;
    return formatJobStartTime(parsed.toLocal().toIso8601String());
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
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        final loc = AppLocalizations.of(languageProvider.locale);
        return _buildContractorProfileUI(context, loc);
      },
    );
  }

  Widget _buildContractorProfileUI(BuildContext context, AppLocalizations loc) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateProcessDialog,
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(loc.newJob),
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
                  Text(
                    '${loc.error}: ${snapshot.error}',
                    style: const TextStyle(color: AppColors.text2),
                  ),
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
                        _activeProcessesFuture = _loadActiveProcesses();
                      });
                    },
                    child: Text(loc.retry),
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
                  Icon(
                    Icons.business_outlined,
                    size: 48,
                    color: AppColors.gray5,
                  ),
                  const SizedBox(height: 16),
                  Text(loc.contractorProfileNotFound),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/home',
                      (_) => false,
                    ),
                    child: Text(loc.goToHome),
                  ),
                ],
              ),
            );
          }

          final contractor = snapshot.data!;

          return FutureBuilder<ContractorActiveProcesses>(
            future: _activeProcessesFuture,
            builder: (context, activeSnapshot) {
              final openProcesses =
                  activeSnapshot.data ?? const ContractorActiveProcesses();

              return NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverToBoxAdapter(
                      child: _buildGradientHeader(contractor, loc),
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
                                  Text(loc.pending),
                                  if (!openProcesses.isEmpty) ...[
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
                                        '${openProcesses.total}',
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
                            Tab(text: loc.history),
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
                                Icon(
                                  Icons.warning_amber_rounded,
                                  size: 48,
                                  color: AppColors.orange,
                                ),
                                const SizedBox(height: 12),
                                Text(loc.couldNotLoadProcesses),
                                TextButton.icon(
                                  onPressed: () => setState(() {
                                    _activeProcessesFuture =
                                        _loadActiveProcesses();
                                  }),
                                  icon: const Icon(Icons.refresh),
                                  label: Text(loc.retry),
                                ),
                              ],
                            ),
                          )
                        : _buildOpenProcessesTab(openProcesses, loc),
                    FutureBuilder<List<ContractorProcessSummary>>(
                      future: _historyProcessesFuture,
                      builder: (context, historySnapshot) {
                        if (_historyProcessesFuture == null) {
                          return Center(child: Text(loc.pressHistoryToLoad));
                        }
                        if (historySnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (historySnapshot.hasError) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  size: 48,
                                  color: AppColors.orange,
                                ),
                                const SizedBox(height: 12),
                                Text(loc.couldNotLoadHistory),
                                TextButton.icon(
                                  onPressed: () => setState(() {
                                    _historyProcessesFuture =
                                        _loadHistoryProcesses();
                                  }),
                                  icon: const Icon(Icons.refresh),
                                  label: Text(loc.retry),
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
                          loc.noCompletedProcesses,
                          loc.completedJobsWillShowHere,
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

  Widget _buildGradientHeader(Contractor contractor, AppLocalizations loc) {
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
                  Text(
                    loc.contractorDashboard,
                    style: const TextStyle(
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
                  ProfileAvatar(id: contractor.id, isWorker: false, radius: 28),
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
                                horizontal: 10,
                                vertical: 3,
                              ),
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

  int _compareByStartDesc(
    ContractorProcessSummary a,
    ContractorProcessSummary b,
  ) {
    final startA = a.job?.jobStartTime ?? '';
    final startB = b.job?.jobStartTime ?? '';
    return startB.compareTo(startA);
  }

  /// Approved processes sit in a foldable card on top; pending ones below,
  /// with claims waiting for the contractor's approval first.
  Widget _buildOpenProcessesTab(
    ContractorActiveProcesses openProcesses,
    AppLocalizations loc,
  ) {
    if (openProcesses.isEmpty) {
      return _buildProcessList(
        const [],
        loc.noPendingProcesses,
        loc.newProcessesWillAppearHere,
      );
    }

    final active = [...openProcesses.activeProcesses]
      ..sort(_compareByStartDesc);
    final pending = [...openProcesses.pendingProcesses]
      ..sort((a, b) {
        final awaitingA = a.job?.isAwaitingApproval == true;
        final awaitingB = b.job?.isAwaitingApproval == true;
        if (awaitingA != awaitingB) return awaitingA ? -1 : 1;
        return _compareByStartDesc(a, b);
      });

    final hasActiveSection = active.isNotEmpty;
    final offset = hasActiveSection ? 1 : 0;
    return RefreshIndicator(
      onRefresh: () async => setState(() {
        _activeProcessesFuture = _loadActiveProcesses();
      }),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: offset + (pending.isEmpty ? 1 : pending.length),
        itemBuilder: (context, index) {
          if (hasActiveSection && index == 0) {
            return _buildActiveProcessesSection(active, loc);
          }
          if (pending.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  loc.noPendingProcesses,
                  style: const TextStyle(color: AppColors.text2),
                ),
              ),
            );
          }
          return _buildProcessCard(pending[index - offset]);
        },
      ),
    );
  }

  Widget _buildActiveProcessesSection(
    List<ContractorProcessSummary> processes,
    AppLocalizations loc,
  ) {
    const accent = AppColors.blue;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(
              () => _isActiveProcessesExpanded = !_isActiveProcessesExpanded,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.engineering_outlined, color: accent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.activeProcesses,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          loc.approvedWorkersOnTheseJobs,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.text2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${processes.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _isActiveProcessesExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: accent,
                  ),
                ],
              ),
            ),
          ),
          if (_isActiveProcessesExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: Column(
                children: [
                  for (final process in processes) _buildProcessCard(process),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProcessList(
    List<ContractorProcessSummary> processes,
    String emptyTitle,
    String emptySubtitle,
  ) {
    if (processes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_rounded, size: 48, color: AppColors.gray4),
              const SizedBox(height: 16),
              Text(
                emptyTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                emptySubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.text2),
              ),
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
    final method = payment.method ?? _loc.unavailable;
    final amount = payment.amount % 1 == 0
        ? payment.amount.toInt().toString()
        : payment.amount.toString();
    return '$method · $amount';
  }

  Widget _buildProcessCard(ContractorProcessSummary process) {
    final loc = _loc;
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
                  child: const Icon(
                    Icons.work_outline,
                    size: 20,
                    color: AppColors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        process.name.isEmpty
                            ? loc.unnamedProcess
                            : process.name,
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
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppColors.red,
                      size: 20,
                    ),
                    onPressed: () => _confirmDeleteProcess(process),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                const SizedBox(width: 8),
                ProcessStatusChip(
                  label: loc.statusLabel(
                    job?.isAwaitingApproval == true
                        ? 'AWAITING_APPROVAL'
                        : process.status,
                  ),
                  color: job?.isAwaitingApproval == true
                      ? getProcessStatusColor('AWAITING_APPROVAL')
                      : statusColor,
                ),
              ],
            ),
            if (job != null) ...[
              const Divider(height: 20),
              // Job images
              JobImagesWidget(
                jobId: job.id,
                height: 150,
                contractorId: widget.contractorId,
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                Icons.schedule,
                loc.start,
                formatJobStartTime(job.jobStartTime),
              ),
              const SizedBox(height: 6),
              _buildDetailRow(
                Icons.timer_outlined,
                loc.duration,
                '${job.durationHours}h',
              ),
              if (job.paymentInformation != null) ...[
                const SizedBox(height: 6),
                _buildDetailRow(
                  Icons.payments_outlined,
                  loc.payment,
                  _formatPayment(job.paymentInformation!),
                ),
              ],
              const SizedBox(height: 6),
              _buildAddressRow(
                Icons.location_on_outlined,
                loc.location,
                job.latitude,
                job.longitude,
              ),
              const SizedBox(height: 8),
              if (job.isAwaitingApproval)
                _buildPendingClaimSection(job.id, job.claim!, loc)
              else if (job.hasClaim)
                _buildClosedClaimNote(job.approvalStatus, job.claim!, loc),
              if (job.assignedWorkerId.isNotEmpty) ...[
                const Divider(height: 12),
                Row(
                  children: [
                    ProfileAvatar(
                      id: job.assignedWorkerId,
                      isWorker: true,
                      radius: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.assignedWorkerName.isNotEmpty
                                ? job.assignedWorkerName
                                : loc.assignedWorker,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (job.assignedWorkerPhone.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            InkWell(
                              onTap: () =>
                                  _makePhoneCall(job.assignedWorkerPhone),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.phone_outlined,
                                    size: 14,
                                    color: AppColors.text3,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    job.assignedWorkerPhone,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            loc.tapToViewWorkerDetails,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.text3,
                            ),
                          ),
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

  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanPhone.isEmpty) return;

    final Uri launchUri = Uri(scheme: 'tel', path: cleanPhone);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      }
    } catch (e) {
      debugPrint('Could not launch phone call: $e');
    }
  }

  Widget _buildPendingClaimSection(
    String jobId,
    JobClaim claim,
    AppLocalizations loc,
  ) {
    final isInProgress = _claimActionInProgress.contains(jobId);

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.orangePale,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.workerRequestedJob,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.orange,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () =>
                Navigator.pushNamed(context, '/worker/${claim.workerId}'),
            child: Row(
              children: [
                ProfileAvatar(id: claim.workerId, isWorker: true, radius: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: FutureBuilder<Worker?>(
                    // The name normally comes with the process list; fetch the
                    // worker only when it is missing.
                    future: claim.workerName.trim().isNotEmpty
                        ? null
                        : _loadClaimWorker(claim.workerId),
                    builder: (context, snap) {
                      final name = claim.workerName.trim().isNotEmpty
                          ? claim.workerName.trim()
                          : snap.data?.workerName.trim() ?? '';
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name.isNotEmpty ? name : loc.tapToViewWorkerDetails,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (claim.requestedAt.isNotEmpty)
                            Text(
                              loc.claimRequestedAt(
                                _formatClaimTime(claim.requestedAt),
                              ),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.text3,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: AppColors.text3,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (isInProgress)
            const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmRejectJobClaim(jobId),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: Text(loc.reject),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.red,
                      side: const BorderSide(color: AppColors.red),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approveJobClaim(jobId),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: Text(loc.approve),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// Notes the last request on a job that is open again, after the
  /// contractor rejected it or it expired.
  Widget _buildClosedClaimNote(
    String approvalStatus,
    JobClaim claim,
    AppLocalizations loc,
  ) {
    final status = approvalStatus.toUpperCase();
    if (status != 'REJECTED' && status != 'EXPIRED') {
      return const SizedBox.shrink();
    }

    final name = claim.workerName.trim().isNotEmpty
        ? claim.workerName.trim()
        : loc.worker;
    final message = status == 'REJECTED'
        ? loc.lastRequestRejected(name)
        : loc.lastRequestExpired(name);

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(
            status == 'REJECTED'
                ? Icons.block_rounded
                : Icons.timer_off_outlined,
            size: 15,
            color: AppColors.text3,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, color: AppColors.text3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.text3),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 12, color: AppColors.text3),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.text2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddressRow(IconData icon, String label, double lat, double lng) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.text3),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 12, color: AppColors.text3),
        ),
        Expanded(
          child: FutureBuilder<String>(
            future: ApiService().reverseGeocode(lat, lng),
            builder: (context, snap) {
              return Text(
                snap.data ?? _loc.loading,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.text2,
                ),
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
