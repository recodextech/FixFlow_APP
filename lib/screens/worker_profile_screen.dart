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
import '../widgets/home_navigation_button.dart';
import 'switch_account_screen.dart';
import 'worker_details_screen.dart';

class WorkerProfileScreen extends StatefulWidget {
  final String workerId;

  const WorkerProfileScreen({
    super.key,
    required this.workerId,
  });

  @override
  State<WorkerProfileScreen> createState() => _WorkerProfileScreenState();
}

class _WorkerProfileScreenState extends State<WorkerProfileScreen> {
  final DateFormat _dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm');
  final Distance _distance = const Distance();

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
    _loadProfileData();
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WorkerDetailsScreen(workerId: widget.workerId),
      ),
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
            child: const Text('Switch Account',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Worker Profile'),
        actions: [
          const HomeNavigationButton(),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                onTap: _switchProfile,
                child: const Text('Switch Profile'),
              ),
            ],
          ),
        ],
      ),
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
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(_loadProfileData);
                    },
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
                  const Icon(Icons.person_outline,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Worker profile not found'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      navigateToHomeScreen(context);
                    },
                    child: const Text('Go to Home'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<List<WorkerAssignedJob>>(
                  future: _pendingJobsFuture,
                  builder: (context, pendingStatusSnapshot) {
                    final status = _resolveWorkerOverallStatus(
                      pendingStatusSnapshot,
                    );
                    return _buildProfileHeader(worker, status);
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _openWorkerDetails,
                    icon: const Icon(Icons.badge_outlined),
                    label: const Text('View Worker Details & Availability'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pending Jobs',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: _refreshPendingJobs,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                FutureBuilder<List<WorkerAssignedJob>>(
                  future: _pendingJobsFuture,
                  builder: (context, pendingSnapshot) {
                    if (pendingSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (pendingSnapshot.hasError) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Error loading pending jobs: ${pendingSnapshot.error}',
                            style: const TextStyle(color: Colors.red),
                          ),
                          TextButton(
                            onPressed: _refreshPendingJobs,
                            child: const Text('Retry'),
                          ),
                        ],
                      );
                    }

                    final pendingJobs = (pendingSnapshot.data ?? [])
                        .where(_isPendingAssignedJob)
                        .toList();

                    if (pendingJobs.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'No pending jobs available',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total: ${pendingJobs.length}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        ...pendingJobs.asMap().entries.map((entry) {
                          return _buildPendingJobCard(
                            entry.value,
                            entry.key + 1,
                          );
                        }),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Suggested Jobs',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: _refreshJobSuggestions,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                FutureBuilder<WorkerJobSuggestionResponse>(
                  future: _jobSuggestionsFuture,
                  builder: (context, suggestionSnapshot) {
                    if (suggestionSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (suggestionSnapshot.hasError) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Error loading suggestions: ${suggestionSnapshot.error}',
                            style: const TextStyle(color: Colors.red),
                          ),
                          TextButton(
                            onPressed: _refreshJobSuggestions,
                            child: const Text('Retry'),
                          ),
                        ],
                      );
                    }

                    final suggestions =
                        suggestionSnapshot.data?.availableJobs ?? [];

                    if (suggestions.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'No suggested jobs available',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total: ${suggestions.length}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        ...suggestions.asMap().entries.map((entry) {
                          return _buildSuggestedJobCard(
                            entry.value,
                            entry.key + 1,
                          );
                        }),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(Worker worker, String status) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade600],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            child: Text(
              _workerInitial(worker.workerName),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
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
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${worker.id}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    const Text(
                      'Status',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Chip(
                      label: Text(status),
                      backgroundColor: _getWorkerStatusBackgroundColor(status),
                      labelStyle: TextStyle(
                        color: _getWorkerStatusTextColor(status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Pending Job $index',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Chip(
                  label: Text(status),
                  backgroundColor: _getStatusBackgroundColor(status),
                  labelStyle: TextStyle(
                    color: _getStatusTextColor(status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Assigned Status',
              job.assignedJobStatus.isEmpty
                  ? 'N/A'
                  : job.assignedJobStatus.toUpperCase(),
              Icons.assignment_turned_in,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Job Status',
              job.jobStatus.isEmpty ? 'N/A' : job.jobStatus.toUpperCase(),
              Icons.info_outline,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Contractor',
              job.contractorName.isEmpty ? 'N/A' : job.contractorName,
              Icons.business,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Contractor Phone',
              isContractorLoading
                  ? 'Loading...'
                  : _resolveContractorPhone(contractor),
              Icons.phone,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Start Time',
              _formatAssignedJobStartTime(job),
              Icons.schedule,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Duration',
              '${job.duration}h',
              Icons.timer,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Location',
              '${job.latitude.toStringAsFixed(6)}, '
                  '${job.longitude.toStringAsFixed(6)}',
              Icons.location_on,
            ),
            const SizedBox(height: 12),
            _buildPendingJobActionButtons(
              job: job,
              status: status,
            ),
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

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (canStart)
          ElevatedButton.icon(
            onPressed: isInProgress ? null : () => _startPendingJob(job),
            icon: isInProgress
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow),
            label: const Text('Start Job'),
          ),
        if (canSuccess)
          ElevatedButton.icon(
            onPressed: isInProgress ? null : () => _completePendingJob(job),
            icon: isInProgress
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.task_alt),
            label: const Text('Success Job'),
          ),
        if (isCompleted)
          Chip(
            label: const Text('Completed'),
            backgroundColor: Colors.green.shade100,
            labelStyle: TextStyle(
              color: Colors.green.shade800,
              fontWeight: FontWeight.w600,
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

    final workerPoint = LatLng(
      workerInfo.workerLatitude,
      workerInfo.workerLongitude,
    );
    final jobPoint = LatLng(
      job.jobLatitude,
      job.jobLongitude,
    );
    final distanceKm =
        _distance.as(LengthUnit.Kilometer, workerPoint, jobPoint);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Suggested Job $index',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Chip(
                  label: Text(status),
                  backgroundColor: _getStatusBackgroundColor(status),
                  labelStyle: TextStyle(
                    color: _getStatusTextColor(status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Category',
              job.jobCategory.isEmpty ? 'N/A' : job.jobCategory,
              Icons.category,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Contractor',
              job.contractorCompany.isEmpty ? 'N/A' : job.contractorCompany,
              Icons.business,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Start Time',
              _formatSuggestedJobStartTime(job),
              Icons.schedule,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Duration',
              '${job.jobDurationHours}h',
              Icons.timer,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Location',
              '${job.jobLatitude.toStringAsFixed(6)}, '
                  '${job.jobLongitude.toStringAsFixed(6)}',
              Icons.location_on,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Direction Distance',
              '${distanceKm.toStringAsFixed(2)} km',
              Icons.alt_route,
            ),
            if (showContractorAndDirection) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                'Contractor Phone',
                isContractorLoading
                    ? 'Loading...'
                    : _resolveContractorPhone(contractor),
                Icons.phone,
              ),
              const SizedBox(height: 10),
              const Text(
                'Location Direction',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 180,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildDirectionMap(workerPoint, jobPoint),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Green marker: worker • Red marker: job',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 12),
            _buildJobActionButtons(
              suggestion: suggestion,
              status: status,
            ),
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

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (canAccept)
          ElevatedButton.icon(
            onPressed:
                isInProgress ? null : () => _acceptSuggestedJob(suggestion),
            icon: isInProgress
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle),
            label: const Text('Accept Job'),
          ),
        if (canStart)
          ElevatedButton.icon(
            onPressed:
                isInProgress ? null : () => _startAcceptedJob(suggestion),
            icon: isInProgress
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow),
            label: const Text('Start Job'),
          ),
        if (canSuccess)
          ElevatedButton.icon(
            onPressed:
                isInProgress ? null : () => _completeStartedJob(suggestion),
            icon: isInProgress
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.task_alt),
            label: const Text('Success Job'),
          ),
        if (isCompleted)
          Chip(
            label: const Text('Completed'),
            backgroundColor: Colors.green.shade100,
            labelStyle: TextStyle(
              color: Colors.green.shade800,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  Widget _buildDirectionMap(LatLng workerPoint, LatLng jobPoint) {
    final center = LatLng(
      (workerPoint.latitude + jobPoint.latitude) / 2,
      (workerPoint.longitude + jobPoint.longitude) / 2,
    );

    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: 13,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.recodextech.fixflow_app',
        ),
        PolylineLayer(
          polylines: [
            Polyline(
              points: [workerPoint, jobPoint],
              color: Colors.blue.shade600,
              strokeWidth: 4,
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

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.green.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label: $value',
            style: const TextStyle(fontSize: 14),
          ),
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
        return Colors.orange.shade100;
      case 'ACCEPTED':
        return Colors.blue.shade100;
      case 'STARTED':
      case 'IN_PROGRESS':
        return Colors.indigo.shade100;
      case 'SUCCESS':
      case 'COMPLETED':
        return Colors.green.shade100;
      default:
        return Colors.grey.shade300;
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.orange.shade800;
      case 'ACCEPTED':
        return Colors.blue.shade800;
      case 'STARTED':
      case 'IN_PROGRESS':
        return Colors.indigo.shade800;
      case 'SUCCESS':
      case 'COMPLETED':
        return Colors.green.shade800;
      default:
        return Colors.black87;
    }
  }

  Color _getWorkerStatusBackgroundColor(String status) {
    switch (status) {
      case 'BUSY':
        return Colors.indigo.shade100;
      case 'ASSIGNED':
        return Colors.blue.shade100;
      case 'IDLE':
        return Colors.green.shade100;
      case 'LOADING':
      case 'UNKNOWN':
        return Colors.grey.shade300;
      default:
        return Colors.grey.shade300;
    }
  }

  Color _getWorkerStatusTextColor(String status) {
    switch (status) {
      case 'BUSY':
        return Colors.indigo.shade800;
      case 'ASSIGNED':
        return Colors.blue.shade800;
      case 'IDLE':
        return Colors.green.shade800;
      case 'LOADING':
      case 'UNKNOWN':
        return Colors.black87;
      default:
        return Colors.black87;
    }
  }

  String _workerInitial(String workerName) {
    final trimmed = workerName.trim();
    if (trimmed.isEmpty) {
      return 'W';
    }

    return trimmed[0].toUpperCase();
  }
}
