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
  bool _hasPromptedAvailabilityCreation = false;
  bool _isAvailabilityScreenOpen = false;
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
      _hasPromptedAvailabilityCreation = false;
      _isAvailabilityScreenOpen = false;
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

    if (!_hasAvailability && !_hasPromptedAvailabilityCreation) {
      _promptAddAvailabilityOnEntry();
    }

    return response;
  }

  void _promptAddAvailabilityOnEntry() {
    if (!mounted || _hasAvailability || _hasPromptedAvailabilityCreation) {
      return;
    }

    _hasPromptedAvailabilityCreation = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }

      await _openAddAvailability();

      if (!mounted) {
        return;
      }

      if (!_hasAvailability) {
        _hasPromptedAvailabilityCreation = false;
        _promptAddAvailabilityOnEntry();
      }
    });
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
                                  color: totalWindows >= 3
                                      ? AppColors.orange
                                      : AppColors.text2,
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
                                      padding: const EdgeInsets.fromLTRB(
                                        16,
                                        12,
                                        16,
                                        4,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Schedule from ${DateFormat('MMM d').format(avail.startDate ?? DateTime.now())} to ${DateFormat('MMM d').format(avail.endDate ?? DateTime.now())}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.text2,
                                              ),
                                            ),
                                          ),
                                          if (avail.frequency.isNotEmpty)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppColors.greenPale,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                avail.frequency,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.green,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    ...avail.windows.map((window) {
                                      return ListTile(
                                        leading: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppColors.greenPale,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.schedule,
                                            color: AppColors.green,
                                            size: 20,
                                          ),
                                        ),
                                        title: Text(
                                          DateFormat(
                                            'EEEE, MMM d, HH:mm',
                                          ).format(
                                            window.startTime ?? DateTime.now(),
                                          ),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        subtitle: Text(
                                          '${window.duration} hours duration',
                                        ),
                                        trailing: IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: AppColors.red,
                                          ),
                                          onPressed: () async {
                                            final confirmed = await showDialog<bool>(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                title: const Text(
                                                  'Delete Window',
                                                ),
                                                content: const Text(
                                                  'Are you sure you want to delete this availability window?',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                          ctx,
                                                          false,
                                                        ),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                          ctx,
                                                          true,
                                                        ),
                                                    style: TextButton.styleFrom(
                                                      foregroundColor:
                                                          AppColors.red,
                                                    ),
                                                    child: const Text('Delete'),
                                                  ),
                                                ],
                                              ),
                                            );

                                            if (confirmed == true) {
                                              if (avail.id.isEmpty) {
                                                if (!context.mounted) return;
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Availability ID is missing. Please refresh and try again.',
                                                    ),
                                                  ),
                                                );
                                                return;
                                              }

                                              await _deleteAvailability(
                                                avail.id,
                                              );
                                              setModalState(
                                                () {},
                                              ); // Refresh modal
                                            }
                                          },
                                        ),
                                      );
                                    }),
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
                          label: Text(
                            canAddMore
                                ? 'Add More Availability'
                                : 'Limit Reached (Max 3)',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: canAddMore
                                ? AppColors.green
                                : AppColors.gray4,
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
    if (_isAvailabilityScreenOpen) {
      return;
    }

    if (_totalAvailabilityWindows >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Maximum of 3 availability windows reached. Please manage your availability.',
          ),
          backgroundColor: AppColors.orange,
        ),
      );
      return;
    }

    _isAvailabilityScreenOpen = true;
    try {
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) =>
              CreateWorkerAvailabilityScreen(workerId: widget.workerId),
        ),
      );

      if (!mounted) return;

      final refreshedResponse = await context
          .read<WorkerProvider>()
          .getWorkerAvailabilities(
            workerId: widget.workerId,
            accountId: PreferencesService().getAccountId(),
          );

      if (!mounted) {
        return;
      }

      setState(() {
        _availabilities = refreshedResponse.availabilities;
        _hasAvailability = refreshedResponse.availabilities.isNotEmpty;
      });

      if (result == true) {
        return;
      }

      if (!_hasAvailability) {
        _hasPromptedAvailabilityCreation = false;
        _promptAddAvailabilityOnEntry();
      }
    } finally {
      if (mounted) {
        _isAvailabilityScreenOpen = false;
      }
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
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.red,
                  ),
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
                  const Icon(
                    Icons.person_outline,
                    size: 48,
                    color: AppColors.gray5,
                  ),
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
                  ProfileAvatar(id: worker.id, isWorker: true, radius: 35),
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
                                    ...worker.categories.take(2).map((
                                      category,
                                    ) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withValues(
                                              alpha: 0.3,
                                            ),
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
                                    }),
                                    if (worker.categories.length > 2)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.15,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withValues(
                                              alpha: 0.25,
                                            ),
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
                            color: hasAvailability
                                ? AppColors.greenPale
                                : AppColors.orangePale,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            hasAvailability
                                ? Icons.event_available
                                : Icons.event_busy,
                            color: hasAvailability
                                ? AppColors.green
                                : AppColors.orange,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hasAvailability
                                    ? 'Availability Active'
                                    : 'No Availability Set',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: hasAvailability
                                      ? AppColors.green
                                      : AppColors.orange,
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Manage',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
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
                          label: const Text(
                            'Add Availability Window',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.green,
                            side: const BorderSide(
                              color: AppColors.green,
                              width: 1.5,
                            ),
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
                _buildSuggestedJobCard(suggestions[index]),
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
                _buildPendingJobCard(pendingJobs[index]),
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
                _buildPendingJobCard(historyJobs[index]),
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

  Widget _buildPendingJobCard(WorkerAssignedJob job) {
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

    final jobTitle = _resolveJobTitle(
      jobDescription: job.jobDescription,
      jobCategory: job.jobCategory,
    );
    final contractorSubtitle = job.contractorName.trim().isNotEmpty
        ? job.contractorName.trim()
        : 'Contractor';

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        jobTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        contractorSubtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.text2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                JobStatusChip(status: status),
              ],
            ),
            const SizedBox(height: 10),
            _buildJobDetailsButton(
              jobDescription: job.jobDescription,
              processDescription: job.processDescription,
              jobTitle: jobTitle,
              contractorName: contractorSubtitle,
              status: status,
            ),
            const SizedBox(height: 12),
            _buildScheduleHighlight(
              startTime: _formatAssignedJobStartTime(job),
              durationText: '${_formatDurationHours(job.duration)}h',
            ),
            const SizedBox(height: 8),
            _buildPaymentHighlight(job.jobPaymentAmount),
            const SizedBox(height: 12),
            // Job images (tap to cycle through available images)
            JobImagesWidget(
              jobId: job.jobId,
              height: 160,
              contractorId: job.contractorId,
            ),
            const SizedBox(height: 8),
            const SizedBox(height: 8),
            // Secondary info: Contractor & Phone
            _buildContractorContactSection(
              contractorName: job.contractorName,
              phone: phone,
              canCall: canCall,
              isContractorLoading: isContractorLoading,
            ),
            const SizedBox(height: 8),
            // Open Route + Location Details (Exclamation/Info)
            _buildRouteAndLocationActions(
              latitude: job.latitude,
              longitude: job.longitude,
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

  Widget _buildJobDetailsButton({
    required String jobDescription,
    required String processDescription,
    required String jobTitle,
    required String contractorName,
    required String status,
  }) {
    if (jobDescription.trim().isEmpty && processDescription.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => _showJobDetailsSheet(
          jobDescription: jobDescription,
          processDescription: processDescription,
          jobTitle: jobTitle,
          contractorName: contractorName,
          status: status,
        ),
        icon: const Icon(Icons.notes_outlined, size: 17),
        label: const Text('View job details'),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.blue,
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }

  Future<void> _showJobDetailsSheet({
    required String jobDescription,
    required String processDescription,
    required String jobTitle,
    required String contractorName,
    required String status,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.work_outline, color: AppColors.blue),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      jobTitle,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  Chip(
                    label: Text(status),
                    visualDensity: VisualDensity.compact,
                    labelStyle: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                contractorName,
                style: const TextStyle(fontSize: 13, color: AppColors.text2),
              ),
              const SizedBox(height: 20),
              if (processDescription.trim().isNotEmpty)
                _buildDescriptionSection(
                  title: 'Process description',
                  icon: Icons.account_tree_outlined,
                  description: processDescription,
                ),
              if (processDescription.trim().isNotEmpty &&
                  jobDescription.trim().isNotEmpty)
                const SizedBox(height: 14),
              if (jobDescription.trim().isNotEmpty)
                _buildDescriptionSection(
                  title: 'Job description',
                  icon: Icons.assignment_outlined,
                  description: jobDescription,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionSection({
    required String title,
    required IconData icon,
    required String description,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.gray0,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gray2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.blue),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description.trim(),
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: AppColors.text2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedJobCard(WorkerJobSuggestion suggestion) {
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

    final phone = _resolveContractorPhone(contractor);
    final canCall = phone != 'Loading...' && phone != 'Unavailable';

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

    final jobTitle = _resolveJobTitle(
      jobDescription: job.jobDescription,
      jobCategory: job.jobCategory,
    );
    final contractorSubtitle = job.contractorCompany.trim().isNotEmpty
        ? job.contractorCompany.trim()
        : 'Contractor';

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
                        jobTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        contractorSubtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.text2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                JobStatusChip(status: status),
              ],
            ),
            const SizedBox(height: 10),
            _buildJobDetailsButton(
              jobDescription: job.jobDescription,
              processDescription: job.processDescription,
              jobTitle: jobTitle,
              contractorName: contractorSubtitle,
              status: status,
            ),
            const SizedBox(height: 12),
            _buildScheduleHighlight(
              startTime: _formatSuggestedJobStartTime(job),
              durationText: '${job.jobDurationHours}h',
              distanceText: '${distanceKm.toStringAsFixed(1)} km',
            ),
            const SizedBox(height: 8),
            _buildPaymentHighlight(job.jobPaymentAmount),
            const SizedBox(height: 12),
            JobImagesWidget(
              jobId: job.jobId,
              height: 160,
              contractorId: job.contractorId,
            ),
            const SizedBox(height: 8),
            // Secondary info: Contractor & Phone
            _buildContractorContactSection(
              contractorName: job.contractorCompany,
              phone: isContractorLoading ? 'Loading...' : phone,
              canCall: canCall,
              isContractorLoading: isContractorLoading,
            ),
            const SizedBox(height: 8),
            // Open Route + Location Details (Exclamation/Info)
            _buildRouteAndLocationActions(
              latitude: job.jobLatitude,
              longitude: job.jobLongitude,
            ),
            if (showContractorAndDirection) ...[
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

  Widget _buildPaymentHighlight(double amount) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.greenPale,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '${AppConstants.currencySymbol} ${amount.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.green,
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleHighlight({
    required String startTime,
    required String durationText,
    String? distanceText,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.gray0,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.gray2),
      ),
      child: Row(
        children: [
          // Start time
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.bluePale,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.event_outlined,
                    color: AppColors.blue,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'START TIME',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text3,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        startTime,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 28,
            width: 1,
            color: AppColors.gray3,
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),
          // Duration
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.greenPale,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.timer_outlined,
                    color: AppColors.green,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'DURATION',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text3,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        durationText,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.green,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (distanceText != null) ...[
            Container(
              height: 28,
              width: 1,
              color: AppColors.gray3,
              margin: const EdgeInsets.symmetric(horizontal: 8),
            ),
            // Distance
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.orangePale,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.alt_route_outlined,
                      color: AppColors.orange,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'DISTANCE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text3,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          distanceText,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.orange,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContractorContactSection({
    required String contractorName,
    required String phone,
    required bool canCall,
    required bool isContractorLoading,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.gray2),
      ),
      child: Row(
        children: [
          const Icon(Icons.business_outlined, size: 18, color: AppColors.text2),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              contractorName.isEmpty ? 'Contractor' : contractorName,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (canCall)
            InkWell(
              onTap: () => _makePhoneCall(phone),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bluePale,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.phone, size: 14, color: AppColors.blue),
                    const SizedBox(width: 4),
                    Text(
                      phone,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (isContractorLoading)
            const Text(
              'Loading contact...',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppColors.text3,
              ),
            )
          else if (phone != 'Unavailable')
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.phone_outlined,
                  size: 14,
                  color: AppColors.text3,
                ),
                const SizedBox(width: 4),
                Text(
                  phone,
                  style: const TextStyle(fontSize: 12, color: AppColors.text3),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildRouteAndLocationActions({
    required double latitude,
    required double longitude,
  }) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _openGoogleMapsRoute(latitude, longitude),
            icon: const Icon(Icons.navigation_outlined, size: 16),
            label: const Text(
              'Open Route',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.blue,
              side: const BorderSide(color: AppColors.blue, width: 1.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.outlined(
          tooltip: 'Location Info',
          icon: const Icon(
            Icons.info_outline,
            size: 20,
            color: AppColors.orange,
          ),
          style: IconButton.styleFrom(
            side: const BorderSide(color: AppColors.orange, width: 1.2),
            backgroundColor: AppColors.orangePale,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(10),
          ),
          onPressed: () => _showLocationDetailsModal(latitude, longitude),
        ),
      ],
    );
  }

  void _showLocationDetailsModal(double latitude, double longitude) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.orangePale,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: AppColors.orange,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Job Location Details',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'ADDRESS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text3,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.gray0,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.gray2),
                  ),
                  child: FutureBuilder<String>(
                    future: ApiService().reverseGeocode(latitude, longitude),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Resolving address...',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.text2,
                              ),
                            ),
                          ],
                        );
                      }
                      return Text(
                        snap.data ?? 'Address unavailable',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.text,
                          height: 1.4,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.pin_drop_outlined,
                      size: 16,
                      color: AppColors.text3,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Coordinates: ${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.text2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _openGoogleMapsRoute(latitude, longitude);
                    },
                    icon: const Icon(Icons.navigation, size: 18),
                    label: const Text('Open Route in Maps'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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

  Future<void> _openGoogleMapsRoute(double latitude, double longitude) async {
    if (!latitude.isFinite ||
        !longitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This job has an invalid location.')),
      );
      return;
    }

    final routeUri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '$latitude,$longitude',
      'travelmode': 'driving',
    });

    try {
      final launched = await launchUrl(
        routeUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the route.')),
      );
      debugPrint('Could not open Google Maps route: $e');
    }
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
          userAgentPackageName: 'com.noventispvt.fixflow',
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

    return '';
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

  String _resolveJobTitle({
    required String jobDescription,
    required String jobCategory,
  }) {
    final description = jobDescription.trim();
    if (description.isNotEmpty) return description;

    final category = jobCategory.trim();
    if (category.isNotEmpty) return category;

    return 'Job';
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

  String _formatDurationHours(double duration) {
    return duration == duration.truncateToDouble()
        ? duration.toInt().toString()
        : duration.toString();
  }

  String _workerInitial(String workerName) {
    final trimmed = workerName.trim();
    if (trimmed.isEmpty) return 'W';
    return trimmed[0].toUpperCase();
  }
}
