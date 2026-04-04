import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/contractor.dart';
import '../models/worker.dart';
import '../models/worker_assigned_job.dart';
import '../models/worker_job_suggestion.dart';
import '../providers/worker_provider.dart';
import '../services/api_service.dart';
import '../services/preferences_service.dart';
import '../theme.dart';
import 'worker_details_screen.dart';
import 'worker_widgets.dart';

class WorkerProfileScreen extends StatefulWidget {
  final String workerId;

  const WorkerProfileScreen({
    super.key,
    required this.workerId,
  });

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
  late Future<WorkerJobSuggestionResponse> _jobSuggestionsFuture;

  final Map<String, String> _jobStatusOverrides = {};
  final Set<String> _jobActionInProgress = {};
  final Map<String, Contractor?> _contractorCache = {};
  final Set<String> _loadingContractorIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProfileData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadProfileData() {
    _workerFuture = context.read<WorkerProvider>().getWorker(
          widget.workerId,
          accountId: PreferencesService().getAccountId(),
        );
    _pendingJobsFuture = _loadPendingJobs();
    _jobSuggestionsFuture = _loadJobSuggestions();
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

  Future<void> _refreshPendingJobs() async {
    setState(() {
      _pendingJobsFuture = _loadPendingJobs();
    });
  }

  Future<void> _refreshJobSuggestions() async {
    setState(() {
      _jobSuggestionsFuture = _loadJobSuggestions();
    });
  }

  Future<void> _acceptSuggestedJob(WorkerJobSuggestion suggestion) async {
    final accountId = PreferencesService().getAccountId();
    final jobId = suggestion.jobInformation.jobId;

    if (accountId == null || accountId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Account ID is missing. Please re-login.')),
      );
      return;
    }

    if (jobId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid job ID.')),
      );
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
      });

      _loadContractorContactIfNeeded(suggestion.jobInformation.contractorId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job accepted successfully')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to accept job: $e')),
      );
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
            content: Text('Account ID is missing. Please re-login.')),
      );
      return;
    }

    if (jobId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid job ID.')),
      );
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job started successfully')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start job: $e')),
      );
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
            content: Text('Account ID is missing. Please re-login.')),
      );
      return;
    }

    if (jobId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid job ID.')),
      );
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to complete job: $e')),
      );
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
            content: Text('Account ID is missing. Please re-login.')),
      );
      return;
    }

    if (jobId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid job ID.')),
      );
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job started successfully')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start job: $e')),
      );
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
            content: Text('Account ID is missing. Please re-login.')),
      );
      return;
    }

    if (jobId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid job ID.')),
      );
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to complete job: $e')),
      );
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
                  Icon(Icons.error_outline, size: 48, color: AppColors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}',
                      style: const TextStyle(color: AppColors.text2)),
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
                  Icon(Icons.person_outline, size: 48, color: AppColors.gray5),
                  const SizedBox(height: 16),
                  const Text('Worker profile not found'),
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

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(
                  child: FutureBuilder<List<WorkerAssignedJob>>(
                    future: _pendingJobsFuture,
                    builder: (context, pendingSnap) {
                      final status =
                          _resolveWorkerOverallStatus(pendingSnap);
                      return _buildGradientHeader(worker, status);
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
                      tabs: const [
                        Tab(text: 'Suggested Jobs'),
                        Tab(text: 'My Jobs'),
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
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGradientHeader(Worker worker, String status) {
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
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const Spacer(),
                  const Text(
                    'Worker Dashboard',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _openWorkerDetails,
                    child: const Icon(Icons.edit_outlined, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Profile info
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
                        _workerInitial(worker.workerName),
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
                          worker.workerName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            StatusBadge(status: status),
                            const SizedBox(width: 8),
                            if (worker.categories.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  worker.categories.first,
                                  style: const TextStyle(
                                    fontSize: 11,
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

        final pendingJobs =
            (snapshot.data ?? []).where(_isPendingAssignedJob).toList();

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

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: AppColors.gray4),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text)),
            const SizedBox(height: 6),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.text2)),
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
    final isContractorLoading =
        _loadingContractorIds.contains(job.contractorId);

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
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.greenPale,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.assignment, size: 18, color: AppColors.green),
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
            _buildDetailRow(Icons.business, 'Contractor',
                job.contractorName.isEmpty ? 'N/A' : job.contractorName),
            _buildDetailRow(
                Icons.phone,
                'Phone',
                isContractorLoading
                    ? 'Loading...'
                    : _resolveContractorPhone(contractor)),
            _buildDetailRow(
                Icons.schedule, 'Start', _formatAssignedJobStartTime(job)),
            _buildDetailRow(Icons.timer, 'Duration', '${job.duration}h'),
            _buildAddressRow(Icons.location_on, 'Location', job.latitude, job.longitude),
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
    final isContractorLoading =
        _loadingContractorIds.contains(job.contractorId);

    final workerPoint = LatLng(workerInfo.workerLatitude, workerInfo.workerLongitude);
    final jobPoint = LatLng(job.jobLatitude, job.jobLongitude);
    final distanceKm = _distance.as(LengthUnit.Kilometer, workerPoint, jobPoint);

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
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.orangePale,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.lightbulb_outline, size: 18, color: AppColors.orange),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.jobCategory.isEmpty ? 'Job #$index' : job.jobCategory,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                      ),
                      Text(
                        job.contractorCompany.isEmpty ? 'Unknown' : job.contractorCompany,
                        style: const TextStyle(fontSize: 12, color: AppColors.text2),
                      ),
                    ],
                  ),
                ),
                JobStatusChip(status: status),
              ],
            ),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.schedule, 'Start', _formatSuggestedJobStartTime(job)),
            _buildDetailRow(Icons.timer, 'Duration', '${job.jobDurationHours}h'),
            _buildDetailRow(Icons.alt_route, 'Distance', '${distanceKm.toStringAsFixed(1)} km'),
            _buildAddressRow(Icons.location_on, 'Location', job.jobLatitude, job.jobLongitude),
            if (showContractorAndDirection) ...[
              _buildDetailRow(Icons.phone, 'Phone',
                  isContractorLoading ? 'Loading...' : _resolveContractorPhone(contractor)),
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
              onPressed: () => _acceptSuggestedJob(suggestion),
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

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.gray5),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
                fontSize: 13, color: AppColors.text2, fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 13, color: AppColors.text)),
          ),
        ],
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
                fontSize: 13, color: AppColors.text2, fontWeight: FontWeight.w500),
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
              child: const Icon(Icons.person_pin_circle, color: Colors.green, size: 36),
            ),
            Marker(
              point: jobPoint,
              width: 36,
              height: 36,
              child: const Icon(Icons.location_pin, color: Colors.red, size: 36),
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

    const terminalJobStatuses = {
      'SUCCESS',
      'COMPLETED',
      'CANCELLED',
      'FAILED',
    };

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

  Color _getStatusBackgroundColor(String status) {
    switch (status) {
      case 'PENDING':
        return AppColors.orangePale;
      case 'ACCEPTED':
        return AppColors.bluePale;
      case 'STARTED':
      case 'IN_PROGRESS':
        return const Color(0xFFE8EAF6);
      case 'SUCCESS':
      case 'COMPLETED':
        return AppColors.greenPale;
      default:
        return AppColors.gray1;
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case 'PENDING':
        return AppColors.orange;
      case 'ACCEPTED':
        return AppColors.blue;
      case 'STARTED':
      case 'IN_PROGRESS':
        return const Color(0xFF283593);
      case 'SUCCESS':
      case 'COMPLETED':
        return AppColors.green;
      default:
        return AppColors.gray6;
    }
  }

  Color _getWorkerStatusBackgroundColor(String status) {
    switch (status) {
      case 'BUSY':
        return const Color(0xFFE8EAF6);
      case 'ASSIGNED':
        return AppColors.bluePale;
      case 'IDLE':
        return AppColors.greenPale;
      default:
        return AppColors.gray1;
    }
  }

  Color _getWorkerStatusTextColor(String status) {
    switch (status) {
      case 'BUSY':
        return const Color(0xFF283593);
      case 'ASSIGNED':
        return AppColors.blue;
      case 'IDLE':
        return AppColors.green;
      default:
        return AppColors.gray6;
    }
  }

  String _workerInitial(String workerName) {
    final trimmed = workerName.trim();
    if (trimmed.isEmpty) return 'W';
    return trimmed[0].toUpperCase();
  }
}


