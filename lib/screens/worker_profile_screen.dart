import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/availability.dart';
import '../models/contractor.dart';
import '../models/worker.dart';
import '../models/worker_assigned_job.dart';
import '../models/worker_job_suggestion.dart';
import '../widgets/job_images_widget.dart';
import '../widgets/profile_avatar.dart';
import '../providers/worker_provider.dart';
import '../services/api_service.dart';
import '../services/preferences_service.dart';
import '../theme.dart';
import 'create_worker_availability_screen.dart';
import 'worker_details_screen.dart';
import 'worker_widgets.dart';

class WorkerProfileScreen extends StatefulWidget {
  final String workerId;

  const WorkerProfileScreen({super.key, required this.workerId});

  @override
  State<WorkerProfileScreen> createState() => _WorkerProfileScreenState();
}

class _WorkerProfileScreenState extends State<WorkerProfileScreen>
    with SingleTickerProviderStateMixin {
  final DateFormat _dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm');
  final Distance _distance = const Distance();
  late TabController _tabController;

  late Future<Worker?> _workerFuture;
  late Future<List<WorkerAssignedJob>> _pendingJobsFuture;
  late Future<List<WorkerAssignedJob>> _historyJobsFuture;
  late Future<WorkerJobSuggestionResponse> _jobSuggestionsFuture;

  final Map<String, String> _jobStatusOverrides = {};
  final Set<String> _jobActionInProgress = {};
  bool _hasAvailability = false;
  List<WorkerAvailability> _availabilities = [];
  final Map<String, Contractor?> _contractorCache = {};
  final Set<String> _loadingContractorIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        switch (_tabController.index) {
          case 0:
            _refreshJobSuggestions();
            break;
          case 1:
            _refreshPendingJobs();
            break;
          case 2:
            _refreshHistoryJobs();
            break;
        }
      }
    });

    // Initialize futures with empty lists/placeholders for lazy loading
    _pendingJobsFuture = Future.value([]);
    _historyJobsFuture = Future.value([]);
    
    _loadProfileData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadProfileData() {
    setState(() {
      _hasAvailability = false;
      _availabilities = [];
    });

    _workerFuture = context.read<WorkerProvider>().getWorker(
      widget.workerId,
      accountId: PreferencesService().getAccountId(),
    );
    
    // First fetch only suggested jobs endpoint
    _jobSuggestionsFuture = _loadJobSuggestions();
    _loadAvailabilities();
  }

  Future<WorkerAvailabilityResponse> _loadAvailabilities() async {
    final response = await context
        .read<WorkerProvider>()
        .getWorkerAvailabilities(
          workerId: widget.workerId,
          accountId: PreferencesService().getAccountId(),
        );

    if (!mounted) {
      return response;
    }

    setState(() {
      _availabilities = response.availabilities;
      _hasAvailability = response.availabilities.isNotEmpty;
    });

    return response;
  }

  Future<void> _deleteAvailability(String availabilityId) async {
    final accountId = PreferencesService().getAccountId();
    if (accountId == null || accountId.isEmpty) return;

    try {
      await ApiService().deleteWorkerAvailability(
        workerId: widget.workerId,
        availabilityId: availabilityId,
        accountId: accountId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Availability window deleted')),
      );

      _loadAvailabilities();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete availability: $e')),
      );
    }
  }

  int get _totalAvailabilityWindows {
    return _availabilities.fold(0, (sum, a) => sum + a.windows.length);
  }

  void _manageAvailability() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final totalWindows = _totalAvailabilityWindows;
            final canAddMore = totalWindows < 3;

            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Manage Availability',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '$totalWindows / 3 Windows used',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: totalWindows >= 3 ? AppColors.orange : AppColors.text2,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: _availabilities.isEmpty
                          ? const Center(child: Text('No availability set'))
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: _availabilities.length,
                              itemBuilder: (context, index) {
                                final avail = _availabilities[index];
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                                      child: Text(
                                        'Schedule from ${DateFormat('MMM d').format(avail.startDate ?? DateTime.now())} to ${DateFormat('MMM d').format(avail.endDate ?? DateTime.now())}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.text2,
                                        ),
                                      ),
                                    ),
                                    ...avail.windows.map((window) {
                                      return ListTile(
                                        leading: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppColors.greenPale,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(Icons.schedule, color: AppColors.green, size: 20),
                                        ),
                                        title: Text(
                                          DateFormat('EEEE, MMM d, HH:mm').format(window.startTime ?? DateTime.now()),
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                        ),
                                        subtitle: Text('${window.duration} hours duration'),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.delete_outline, color: AppColors.red),
                                          onPressed: () async {
                                            final confirmed = await showDialog<bool>(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                title: const Text('Delete Window'),
                                                content: const Text('Are you sure you want to delete this availability window?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(ctx, false),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(ctx, true),
                                                    style: TextButton.styleFrom(foregroundColor: AppColors.red),
                                                    child: const Text('Delete'),
                                                  ),
                                                ],
                                              ),
                                            );

                                            if (confirmed == true) {
                                              if (avail.id.isEmpty) {
                                                if (!context.mounted) return;
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('Availability ID is missing. Please refresh and try again.'),
                                                  ),
                                                );
                                                return;
                                              }

                                              await _deleteAvailability(avail.id);
                                              setModalState(() {}); // Refresh modal
                                            }
                                          },
                                        ),
                                      );
                                    }).toList(),
                                    const Divider(),
                                  ],
                                );
                              },
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: !canAddMore
                              ? null
                              : () {
                                  Navigator.pop(context);
                                  _openAddAvailability();
                                },
                          icon: Icon(canAddMore ? Icons.add : Icons.block),
                          label: Text(canAddMore ? 'Add More Availability' : 'Limit Reached (Max 3)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: canAddMore ? AppColors.green : AppColors.gray4,
                            foregroundColor: Colors.white,
                            elevation: 0,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Future<WorkerJobSuggestionResponse> _loadJobSuggestions() {
    return context.read<WorkerProvider>().getWorkerJobSuggestions(
      workerId: widget.workerId,
      accountId: PreferencesService().getAccountId(),
    );
  }

  Future<List<WorkerAssignedJob>> _loadPendingJobs() {
    return context.read<WorkerProvider>().getWorkerAssignedJobs(
      workerId: widget.workerId,
      accountId: PreferencesService().getAccountId(),
    );
  }

  Future<List<WorkerAssignedJob>> _loadHistoryJobs() {
    return context.read<WorkerProvider>().getWorkerJobHistory(
      workerId: widget.workerId,
      accountId: PreferencesService().getAccountId(),
    );
  }

  Future<void> _refreshPendingJobs() async {
    setState(() {
      _pendingJobsFuture = _loadPendingJobs();
    });
  }

  Future<void> _refreshHistoryJobs() async {
    setState(() {
      _historyJobsFuture = _loadHistoryJobs();
    });
  }

  Future<void> _refreshJobSuggestions() async {
    setState(() {
      _jobSuggestionsFuture = _loadJobSuggestions();
    });
  }

  Future<bool> _ensureAvailabilityBeforeAction() async {
    if (_hasAvailability) {
      return true;
    }

    final response = await context
        .read<WorkerProvider>()
        .getWorkerAvailabilities(
          workerId: widget.workerId,
          accountId: PreferencesService().getAccountId(),
        );

    if (!mounted) {
      return false;
    }

    setState(() {
      _availabilities = response.availabilities;
      _hasAvailability = response.availabilities.isNotEmpty;
    });

    return _hasAvailability;
  }

  Future<void> _acceptSuggestedJob(WorkerJobSuggestion suggestion) async {
    final accountId = PreferencesService().getAccountId();
    final jobId = suggestion.jobInformation.jobId;

    if (accountId == null || accountId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account ID is missing. Please re-login.'),
        ),
      );
      return;
    }

    if (jobId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid job ID.')));
      return;
    }

    final canAccept = await _ensureAvailabilityBeforeAction();
    if (!mounted) {
      return;
    }

    if (!canAccept) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add your availability first to accept jobs.'),
        ),
      );
      await _openAddAvailability();
      return;
    }

    setState(() {
      _jobActionInProgress.add(jobId);
    });

    try {
      await context.read<WorkerProvider>().acceptWorkerJob(
        workerId: widget.workerId,
        jobId: jobId,
        accountId: accountId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _jobStatusOverrides[jobId] = 'ACCEPTED';
        _pendingJobsFuture = _loadPendingJobs();
        _jobSuggestionsFuture = _loadJobSuggestions();
        _tabController.animateTo(1);
      });

      _loadContractorContactIfNeeded(suggestion.jobInformation.contractorId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job accepted successfully')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to accept job: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _jobActionInProgress.remove(jobId);
        });
      }
    }
  }

  Future<void> _startAcceptedJob(WorkerJobSuggestion suggestion) async {
    final accountId = PreferencesService().getAccountId();
    final jobId = suggestion.jobInformation.jobId;

    if (accountId == null || accountId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account ID is missing. Please re-login.'),
        ),
      );
      return;
    }

    if (jobId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid job ID.')));
      return;
    }

    setState(() {
      _jobActionInProgress.add(jobId);
    });

    try {
      await context.read<WorkerProvider>().startWorkerJob(
        workerId: widget.workerId,
        jobId: jobId,
        accountId: accountId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _jobStatusOverrides[jobId] = 'STARTED';
        _pendingJobsFuture = _loadPendingJobs();
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Job started successfully')));
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to start job: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _jobActionInProgress.remove(jobId);
        });
      }
    }
  }

  Future<void> _completeStartedJob(WorkerJobSuggestion suggestion) async {
    final accountId = PreferencesService().getAccountId();
    final jobId = suggestion.jobInformation.jobId;

    if (accountId == null || accountId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account ID is missing. Please re-login.'),
        ),
      );
      return;
    }

    if (jobId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid job ID.')));
      return;
    }

    setState(() {
      _jobActionInProgress.add(jobId);
    });

    try {
      await context.read<WorkerProvider>().completeWorkerJobSuccess(
        workerId: widget.workerId,
        jobId: jobId,
        accountId: accountId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _jobStatusOverrides[jobId] = 'SUCCESS';
        _pendingJobsFuture = _loadPendingJobs();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job completed successfully')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to complete job: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _jobActionInProgress.remove(jobId);
        });
      }
    }
  }

  Future<void> _startPendingJob(WorkerAssignedJob job) async {
    final accountId = PreferencesService().getAccountId();
    final jobId = job.jobId;

    if (accountId == null || accountId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account ID is missing. Please re-login.'),
        ),
      );
      return;
    }

    if (jobId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid job ID.')));
      return;
    }

    setState(() {
      _jobActionInProgress.add(jobId);
    });

    try {
      await context.read<WorkerProvider>().startWorkerJob(
        workerId: widget.workerId,
        jobId: jobId,
        accountId: accountId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _jobStatusOverrides[jobId] = 'STARTED';
        _pendingJobsFuture = _loadPendingJobs();
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Job started successfully')));
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to start job: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _jobActionInProgress.remove(jobId);
        });
      }
    }
  }

  Future<void> _completePendingJob(WorkerAssignedJob job) async {
    final accountId = PreferencesService().getAccountId();
    final jobId = job.jobId;

    if (accountId == null || accountId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account ID is missing. Please re-login.'),
        ),
      );
      return;
    }

    if (jobId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid job ID.')));
      return;
    }

    setState(() {
      _jobActionInProgress.add(jobId);
    });

    try {
      await context.read<WorkerProvider>().completeWorkerJobSuccess(
        workerId: widget.workerId,
        jobId: jobId,
        accountId: accountId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _jobStatusOverrides[jobId] = 'SUCCESS';
        _pendingJobsFuture = _loadPendingJobs();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job completed successfully')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to complete job: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _jobActionInProgress.remove(jobId);
        });
      }
    }
  }

  void _loadContractorContactIfNeeded(String contractorId) {
    if (contractorId.isEmpty ||
        _contractorCache.containsKey(contractorId) ||
        _loadingContractorIds.contains(contractorId)) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          contractorId.isEmpty ||
          _contractorCache.containsKey(contractorId) ||
          _loadingContractorIds.contains(contractorId)) {
        return;
      }

      _loadContractorContact(contractorId);
    });
  }

  Future<void> _loadContractorContact(String contractorId) async {
    final accountId = PreferencesService().getAccountId();
    if (accountId == null || accountId.isEmpty) {
      return;
    }

    setState(() {
      _loadingContractorIds.add(contractorId);
    });

    try {
      final contractor = await ApiService().getContractor(
        contractorId,
        accountId: accountId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _contractorCache[contractorId] = contractor;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingContractorIds.remove(contractorId);
        });
      }
    }
  }

  void _openWorkerDetails() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => WorkerDetailsScreen(workerId: widget.workerId),
          ),
        )
        .then((_) => setState(_loadProfileData));
  }

  Future<void> _openAddAvailability() async {
    if (_totalAvailabilityWindows >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum of 3 availability windows reached. Please manage your availability.'),
          backgroundColor: AppColors.orange,
        ),
      );
      return;
    }

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            CreateWorkerAvailabilityScreen(workerId: widget.workerId),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      setState(_loadProfileData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Worker?>(
        future: _workerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: AppColors.text2),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(_loadProfileData),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final worker = snapshot.data;
          if (worker == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_outline, size: 48, color: AppColors.gray5),
                  const SizedBox(height: 16),
                  const Text('Worker profile not found'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/home',
                      (_) => false,
                    ),
                    child: const Text('Go to Home'),
                  ),
                ],
              ),
            );
          }

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(
                  child: FutureBuilder<List<WorkerAssignedJob>>(
                    future: _pendingJobsFuture,
                    builder: (context, pendingSnap) {
                      final status = _resolveWorkerOverallStatus(pendingSnap);
                      return _buildGradientHeader(
                        worker,
                        status,
                        _hasAvailability,
                      );
                    },
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: WorkerTabBarDelegate(
                    tabBar: TabBar(
                      controller: _tabController,
                      labelColor: AppColors.green,
                      unselectedLabelColor: AppColors.gray5,
                      indicatorColor: AppColors.green,
                      indicatorWeight: 3,
                      tabs: [
                        const Tab(text: 'Suggested Jobs'),
                        Tab(
                          child: Consumer<WorkerProvider>(
                            builder: (context, provider, _) {
                              final count = provider.assignedJobs
                                  .where(_isPendingAssignedJob)
                                  .length;
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('My Jobs'),
                                  if (count > 0) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.red,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '$count',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            },
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
                _buildSuggestedJobsTab(),
                _buildPendingJobsTab(),
                _buildHistoryJobsTab(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGradientHeader(
    Worker worker,
    String status,
    bool hasAvailability,
  ) {
    final totalWindows = _totalAvailabilityWindows;
    final canAddMore = totalWindows < 3;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.workerGradient,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            children: [
              // Top bar
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                    visualDensity: VisualDensity.compact,
                  ),
                  const Expanded(
                    child: Text(
                      'Worker Dashboard',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Balance for back button
                ],
              ),
              const SizedBox(height: 16),
              
              // Profile info
              Row(
                children: [
                  ProfileAvatar(
                    id: worker.id,
                    isWorker: true,
                    radius: 35,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          worker.workerName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            StatusBadge(status: status),
                            const SizedBox(width: 12),
                            if (worker.categories.isNotEmpty)
                              Flexible(
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    ...worker.categories.take(2).map((category) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(
                                            color: Colors.white.withValues(alpha: 0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          category,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    if (worker.categories.length > 2)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(
                                            color: Colors.white.withValues(alpha: 0.25),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          '+${worker.categories.length - 2}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
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
                  IconButton(
                    onPressed: _openWorkerDetails,
                    icon: const Icon(Icons.edit_outlined),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    tooltip: 'Edit Profile',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Availability Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: hasAvailability ? AppColors.greenPale : AppColors.orangePale,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            hasAvailability
                                ? Icons.event_available
                                : Icons.event_busy,
                            color: hasAvailability ? AppColors.green : AppColors.orange,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hasAvailability ? 'Availability Active' : 'No Availability Set',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: hasAvailability ? AppColors.green : AppColors.orange,
                                ),
                              ),
                              Text(
                                hasAvailability
                                    ? '$totalWindows / 3 windows configured'
                                    : 'Add slots to appear in job searches',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.text2,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (hasAvailability)
                          TextButton(
                            onPressed: _manageAvailability,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.green,
                              backgroundColor: AppColors.greenPale,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Manage', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    if (!hasAvailability || canAddMore) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton.icon(
                          onPressed: _openAddAvailability,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add Availability Window', style: TextStyle(fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.green,
                            side: const BorderSide(color: AppColors.green, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Categories Section
              if (worker.categories.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.greenPale,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.category_outlined,
                              color: AppColors.green,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Work Categories',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.text,
                                  ),
                                ),
                                Text(
                                  '${worker.categories.length} category${worker.categories.length > 1 ? 'ies' : ''}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.text3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: worker.categories.map((category) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.greenPale,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.green.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  size: 16,
                                  color: AppColors.green,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  category,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.green,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestedJobsTab() {
    return FutureBuilder<WorkerJobSuggestionResponse>(
      future: _jobSuggestionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorState(
            'Could not load suggestions',
            _refreshJobSuggestions,
          );
        }

        final suggestions = snapshot.data?.availableJobs ?? [];
        if (suggestions.isEmpty) {
          return _buildEmptyState(
            'No suggested jobs',
            'Job suggestions will appear here when available.',
            Icons.search_off_rounded,
          );
        }

        return RefreshIndicator(
          onRefresh: () async => _refreshJobSuggestions(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: suggestions.length,
            itemBuilder: (context, index) =>
                _buildSuggestedJobCard(suggestions[index], index + 1),
          ),
        );
      },
    );
  }

  Widget _buildPendingJobsTab() {
    return FutureBuilder<List<WorkerAssignedJob>>(
      future: _pendingJobsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorState(
            'Could not load pending jobs',
            _refreshPendingJobs,
          );
        }

        final pendingJobs = snapshot.data ?? [];

        if (pendingJobs.isEmpty) {
          return _buildEmptyState(
            'No pending jobs',
            'Accept a suggested job to see it here.',
            Icons.assignment_outlined,
          );
        }

        return RefreshIndicator(
          onRefresh: () async => _refreshPendingJobs(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pendingJobs.length,
            itemBuilder: (context, index) =>
                _buildPendingJobCard(pendingJobs[index], index + 1),
          ),
        );
      },
    );
  }

  Widget _buildHistoryJobsTab() {
    return FutureBuilder<List<WorkerAssignedJob>>(
      future: _historyJobsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorState(
            'Could not load history',
            _refreshHistoryJobs,
          );
        }

        final historyJobs = snapshot.data ?? [];

        if (historyJobs.isEmpty) {
          return _buildEmptyState(
            'No completed jobs',
            'Your completed jobs will appear here.',
            Icons.history_rounded,
          );
        }

        return RefreshIndicator(
          onRefresh: () async => _refreshHistoryJobs(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: historyJobs.length,
            itemBuilder: (context, index) =>
                _buildPendingJobCard(historyJobs[index], index + 1),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: AppColors.gray4),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.text2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning_amber_rounded, size: 48, color: AppColors.orange),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: AppColors.text2)),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingJobCard(WorkerAssignedJob job, int index) {
    final status = _resolvePendingJobStatus(job);
    _loadContractorContactIfNeeded(job.contractorId);
    final contractor = _contractorCache[job.contractorId];
    final isContractorLoading = _loadingContractorIds.contains(
      job.contractorId,
    );

    final phone = job.contractorPhoneNumber.isNotEmpty
        ? job.contractorPhoneNumber
        : (isContractorLoading
            ? 'Loading...'
            : _resolveContractorPhone(contractor));
    final canCall = phone != 'Loading...' && phone != 'Unavailable';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gray2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ProfileAvatar(
                  id: job.contractorId,
                  isWorker: false,
                  radius: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Job #$index',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                ),
                JobStatusChip(status: status),
              ],
            ),
            const SizedBox(height: 12),
            // Job images (tap to cycle through available images)
            JobImagesWidget(jobId: job.jobId, height: 160),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.greenPale,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '\$${job.jobPaymentAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.green,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.business,
              'Contractor',
              job.contractorName.isEmpty ? 'N/A' : job.contractorName,
            ),
            _buildDetailRow(
              Icons.phone,
              'Phone',
              phone,
              onTap: canCall ? () => _makePhoneCall(phone) : null,
            ),
            _buildDetailRow(
              Icons.schedule,
              'Start',
              _formatAssignedJobStartTime(job),
            ),
            _buildDetailRow(Icons.timer, 'Duration', '${job.duration}h'),
            _buildAddressRow(
              Icons.location_on,
              'Location',
              job.latitude,
              job.longitude,
            ),
            const SizedBox(height: 10),
            _buildPendingJobActionButtons(job: job, status: status),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingJobActionButtons({
    required WorkerAssignedJob job,
    required String status,
  }) {
    final jobId = job.jobId;
    final isInProgress = _jobActionInProgress.contains(jobId);
    final canStart = status == 'ACCEPTED';
    final canSuccess = status == 'STARTED' || status == 'IN_PROGRESS';
    final isCompleted = status == 'SUCCESS' || status == 'COMPLETED';

    if (isCompleted) {
      return CompletedBadge();
    }

    return Row(
      children: [
        if (canStart)
          Expanded(
            child: ActionButton(
              label: 'Start Job',
              icon: Icons.play_arrow_rounded,
              color: AppColors.blue,
              isLoading: isInProgress,
              onPressed: () => _startPendingJob(job),
            ),
          ),
        if (canSuccess)
          Expanded(
            child: ActionButton(
              label: 'Complete',
              icon: Icons.task_alt_rounded,
              color: AppColors.green,
              isLoading: isInProgress,
              onPressed: () => _completePendingJob(job),
            ),
          ),
      ],
    );
  }

  Widget _buildSuggestedJobCard(WorkerJobSuggestion suggestion, int index) {
    final job = suggestion.jobInformation;
    final workerInfo = suggestion.workerInformation;
    final status = _resolveSuggestionStatus(suggestion);
    final showContractorAndDirection = _showContractorAndDirection(status);

    if (showContractorAndDirection) {
      _loadContractorContactIfNeeded(job.contractorId);
    }

    final contractor = _contractorCache[job.contractorId];
    final isContractorLoading = _loadingContractorIds.contains(
      job.contractorId,
    );

    final workerPoint = LatLng(
      workerInfo.workerLatitude,
      workerInfo.workerLongitude,
    );
    final jobPoint = LatLng(job.jobLatitude, job.jobLongitude);
    final distanceKm = _distance.as(
      LengthUnit.Kilometer,
      workerPoint,
      jobPoint,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gray2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SizedBox(width: 4),
                ProfileAvatar(
                  id: job.contractorId,
                  isWorker: false,
                  radius: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.jobCategory.isEmpty
                            ? 'Job #$index'
                            : job.jobCategory,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                      ),
                      Text(
                        job.contractorCompany.isEmpty
                            ? 'Unknown'
                            : job.contractorCompany,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.text2,
                        ),
                      ),
                    ],
                  ),
                ),
                JobStatusChip(status: status),
              ],
            ),
            const SizedBox(height: 12),
            JobImagesWidget(jobId: job.jobId, height: 160),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.greenPale,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '\$${job.jobPaymentAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.green,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.schedule,
              'Start',
              _formatSuggestedJobStartTime(job),
            ),
            _buildDetailRow(
              Icons.timer,
              'Duration',
              '${job.jobDurationHours}h',
            ),
            _buildDetailRow(
              Icons.alt_route,
              'Distance',
              '${distanceKm.toStringAsFixed(1)} km',
            ),
            _buildAddressRow(
              Icons.location_on,
              'Location',
              job.jobLatitude,
              job.jobLongitude,
            ),
            if (showContractorAndDirection) ...[
              _buildDetailRow(
                Icons.phone,
                'Phone',
                isContractorLoading
                    ? 'Loading...'
                    : _resolveContractorPhone(contractor),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 150,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _buildDirectionMap(workerPoint, jobPoint),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Green: your location • Red: job site',
                style: TextStyle(fontSize: 11, color: AppColors.text3),
              ),
            ],
            const SizedBox(height: 10),
            _buildJobActionButtons(suggestion: suggestion, status: status),
          ],
        ),
      ),
    );
  }

  Widget _buildJobActionButtons({
    required WorkerJobSuggestion suggestion,
    required String status,
  }) {
    final jobId = suggestion.jobInformation.jobId;
    final isInProgress = _jobActionInProgress.contains(jobId);
    final canAccept = status == 'PENDING';
    final canStart = status == 'ACCEPTED';
    final canSuccess = status == 'STARTED' || status == 'IN_PROGRESS';
    final isCompleted = status == 'SUCCESS' || status == 'COMPLETED';

    if (isCompleted) {
      return CompletedBadge();
    }

    return Row(
      children: [
        if (canAccept)
          Expanded(
            child: ActionButton(
              label: 'Accept',
              icon: Icons.check_circle_outline,
              color: AppColors.green,
              isLoading: isInProgress,
              onPressed: _hasAvailability
                  ? () => _acceptSuggestedJob(suggestion)
                  : null,
            ),
          ),
        if (canStart)
          Expanded(
            child: ActionButton(
              label: 'Start',
              icon: Icons.play_arrow_rounded,
              color: AppColors.blue,
              isLoading: isInProgress,
              onPressed: () => _startAcceptedJob(suggestion),
            ),
          ),
        if (canSuccess)
          Expanded(
            child: ActionButton(
              label: 'Complete',
              icon: Icons.task_alt_rounded,
              color: AppColors.green,
              isLoading: isInProgress,
              onPressed: () => _completeStartedJob(suggestion),
            ),
          ),
      ],
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanPhone.isEmpty) return;

    final Uri launchUri = Uri(
      scheme: 'tel',
      path: cleanPhone,
    );
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      }
    } catch (e) {
      debugPrint('Could not launch phone call: $e');
    }
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    VoidCallback? onTap,
    Color? valueColor,
    FontWeight? valueFontWeight,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: onTap != null
                  ? AppColors.blue
                  : (valueColor ?? AppColors.gray5),
            ),
            const SizedBox(width: 8),
            Text(
              '$label: ',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.text2,
                fontWeight: FontWeight.w500,
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  color: onTap != null
                      ? AppColors.blue
                      : (valueColor ?? AppColors.text),
                  fontWeight: valueFontWeight,
                  decoration: onTap != null ? TextDecoration.underline : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressRow(IconData icon, String label, double lat, double lng) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.gray5),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.text2,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: FutureBuilder<String>(
              future: ApiService().reverseGeocode(lat, lng),
              builder: (context, snap) {
                return Text(
                  snap.data ?? 'Loading...',
                  style: const TextStyle(fontSize: 13, color: AppColors.text),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectionMap(LatLng workerPoint, LatLng jobPoint) {
    final center = LatLng(
      (workerPoint.latitude + jobPoint.latitude) / 2,
      (workerPoint.longitude + jobPoint.longitude) / 2,
    );

    return FlutterMap(
      options: MapOptions(initialCenter: center, initialZoom: 13),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.recodextech.fixflow_app',
        ),
        PolylineLayer(
          polylines: [
            Polyline(
              points: [workerPoint, jobPoint],
              color: AppColors.blue,
              strokeWidth: 3,
            ),
          ],
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: workerPoint,
              width: 36,
              height: 36,
              child: const Icon(
                Icons.person_pin_circle,
                color: Colors.green,
                size: 36,
              ),
            ),
            Marker(
              point: jobPoint,
              width: 36,
              height: 36,
              child: const Icon(
                Icons.location_pin,
                color: Colors.red,
                size: 36,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _resolveWorkerOverallStatus(
    AsyncSnapshot<List<WorkerAssignedJob>> snapshot,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return 'LOADING';
    }

    if (snapshot.hasError) {
      return 'UNKNOWN';
    }

    final jobs = snapshot.data ?? const [];
    return _deriveWorkerStatus(jobs);
  }

  String _deriveWorkerStatus(List<WorkerAssignedJob> jobs) {
    final activeJobs = jobs.where(_isPendingAssignedJob).toList();

    final hasStartedJob = activeJobs.any((job) {
      final status = _resolvePendingJobStatus(job);
      return status == 'STARTED' || status == 'IN_PROGRESS';
    });

    if (hasStartedJob) {
      return 'BUSY';
    }

    final hasAssignedJob = activeJobs.any((job) {
      final status = _resolvePendingJobStatus(job);
      return status == 'ACCEPTED' || status == 'PENDING';
    });

    if (hasAssignedJob) {
      return 'ASSIGNED';
    }

    return 'IDLE';
  }

  String _resolveSuggestionStatus(WorkerJobSuggestion suggestion) {
    final jobId = suggestion.jobInformation.jobId;
    final overridden = _jobStatusOverrides[jobId];

    if (overridden != null && overridden.isNotEmpty) {
      return overridden;
    }

    final serverStatus = suggestion.jobInformation.jobStatus.trim();
    if (serverStatus.isEmpty) {
      return 'UNKNOWN';
    }

    return serverStatus.toUpperCase();
  }

  bool _isPendingAssignedJob(WorkerAssignedJob job) {
    final assignedStatus = job.assignedJobStatus.trim().toUpperCase();
    final jobStatus = _resolvePendingJobStatus(job);

    const terminalAssignedStatuses = {
      'UNASSIGNED',
      'COMPLETED',
      'CANCELLED',
      'REJECTED',
    };

    const terminalJobStatuses = {'SUCCESS', 'COMPLETED', 'CANCELLED', 'FAILED'};

    return !terminalAssignedStatuses.contains(assignedStatus) &&
        !terminalJobStatuses.contains(jobStatus);
  }

  String _resolvePendingJobStatus(WorkerAssignedJob job) {
    final jobId = job.jobId;
    final overridden = _jobStatusOverrides[jobId];
    if (overridden != null && overridden.isNotEmpty) {
      return overridden.toUpperCase();
    }

    final normalizedJobStatus = job.jobStatus.trim();
    if (normalizedJobStatus.isNotEmpty) {
      return normalizedJobStatus.toUpperCase();
    }

    final normalizedAssignedStatus = job.assignedJobStatus.trim();
    if (normalizedAssignedStatus.isNotEmpty) {
      return normalizedAssignedStatus.toUpperCase();
    }

    return 'UNKNOWN';
  }

  bool _showContractorAndDirection(String status) {
    return status == 'ACCEPTED' ||
        status == 'STARTED' ||
        status == 'IN_PROGRESS' ||
        status == 'SUCCESS' ||
        status == 'COMPLETED';
  }

  String _resolveContractorPhone(Contractor? contractor) {
    if (contractor == null) {
      return 'Unavailable';
    }

    final phone = contractor.phoneNumber.trim();
    if (phone.isEmpty) {
      return 'Unavailable';
    }

    return phone;
  }

  String _formatSuggestedJobStartTime(SuggestedJobInformation job) {
    if (job.jobStartTime != null) {
      return _dateTimeFormat.format(job.jobStartTime!);
    }

    if (job.rawJobStartTime.isNotEmpty) {
      return job.rawJobStartTime;
    }

    return 'N/A';
  }

  String _formatAssignedJobStartTime(WorkerAssignedJob job) {
    if (job.jobStartTime != null) {
      return _dateTimeFormat.format(job.jobStartTime!);
    }

    if (job.rawJobStartTime.isNotEmpty) {
      return job.rawJobStartTime;
    }

    return 'N/A';
  }

  String _workerInitial(String workerName) {
    final trimmed = workerName.trim();
    if (trimmed.isEmpty) return 'W';
    return trimmed[0].toUpperCase();
  }
}
