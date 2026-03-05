import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/availability.dart';
import '../models/contractor.dart';
import '../models/worker.dart';
import '../models/worker_job_suggestion.dart';
import '../providers/worker_provider.dart';
import '../services/api_service.dart';
import '../services/preferences_service.dart';
import 'create_worker_availability_screen.dart';
import 'switch_account_screen.dart';

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
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  final DateFormat _dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm');
  final Distance _distance = const Distance();

  late Future<Worker?> _workerFuture;
  late Future<WorkerAvailabilityResponse> _availabilityFuture;
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
    _availabilityFuture = _loadAvailabilities();
    _jobSuggestionsFuture = _loadJobSuggestions();
  }

  Future<WorkerAvailabilityResponse> _loadAvailabilities() {
    return context.read<WorkerProvider>().getWorkerAvailabilities(
          workerId: widget.workerId,
          accountId: PreferencesService().getAccountId(),
        );
  }

  Future<WorkerJobSuggestionResponse> _loadJobSuggestions() {
    return context.read<WorkerProvider>().getWorkerJobSuggestions(
          workerId: widget.workerId,
          accountId: PreferencesService().getAccountId(),
        );
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
        const SnackBar(content: Text('Account ID is missing. Please re-login.')),
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
        const SnackBar(content: Text('Account ID is missing. Please re-login.')),
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
        const SnackBar(content: Text('Account ID is missing. Please re-login.')),
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

  Future<void> _createAvailability() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) =>
            CreateWorkerAvailabilityScreen(workerId: widget.workerId),
      ),
    );

    if (!mounted) {
      return;
    }

    if (result == true) {
      setState(() {
        _availabilityFuture = _loadAvailabilities();
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Worker Profile'),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                onTap: _createAvailability,
                child: const Text('Create Availability'),
              ),
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
                      setState(() {
                        _loadProfileData();
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
                  const Icon(Icons.person_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Worker profile not found'),
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

          final worker = snapshot.data!;

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
                      colors: [Colors.green.shade400, Colors.green.shade600],
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
                              worker.workerName[0].toUpperCase(),
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
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoCard('Email', worker.email, Icons.email),
                const SizedBox(height: 12),
                _buildInfoCard('Phone', worker.phoneNumber, Icons.phone),
                const SizedBox(height: 12),
                _buildInfoCard('Account ID', worker.accountId ?? 'N/A', Icons.account_circle),
                const SizedBox(height: 24),
                // Categories
                const Text(
                  'Categories',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (worker.categories.isEmpty)
                  const Text(
                    'No categories assigned',
                    style: TextStyle(color: Colors.grey),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: worker.categories.map((category) {
                      return Chip(
                        label: Text(category),
                        backgroundColor: Colors.green.shade100,
                        labelStyle: TextStyle(color: Colors.green.shade800),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Availability Windows',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _availabilityFuture = _loadAvailabilities();
                        });
                      },
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                FutureBuilder<WorkerAvailabilityResponse>(
                  future: _availabilityFuture,
                  builder: (context, availabilitySnapshot) {
                    if (availabilitySnapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (availabilitySnapshot.hasError) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Error loading availabilities: ${availabilitySnapshot.error}',
                            style: const TextStyle(color: Colors.red),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _availabilityFuture = _loadAvailabilities();
                              });
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      );
                    }

                    final response = availabilitySnapshot.data ??
                        WorkerAvailabilityResponse(availabilities: [], total: 0);

                    if (response.availabilities.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'No availability windows found',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total: ${response.total}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        ...response.availabilities.asMap().entries.map((entry) {
                          return _buildAvailabilityCard(
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
                const SizedBox(height: 24),
                // Action Buttons
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _createAvailability,
                    icon: const Icon(Icons.calendar_month),
                    label: const Text('Create Availability'),
                    style: OutlinedButton.styleFrom(
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

  Widget _buildSuggestedJobCard(WorkerJobSuggestion suggestion, int index) {
    final job = suggestion.jobInformation;
    final workerInfo = suggestion.workerInformation;
    final status = _resolveSuggestionStatus(suggestion);
    final showContractorAndDirection = _showContractorAndDirection(status);

    if (showContractorAndDirection) {
      _loadContractorContactIfNeeded(job.contractorId);
    }

    final contractor = _contractorCache[job.contractorId];
    final isContractorLoading = _loadingContractorIds.contains(job.contractorId);

    final workerPoint = LatLng(
      workerInfo.workerLatitude,
      workerInfo.workerLongitude,
    );
    final jobPoint = LatLng(
      job.jobLatitude,
      job.jobLongitude,
    );
    final distanceKm = _distance.as(LengthUnit.Kilometer, workerPoint, jobPoint);

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
            _buildAvailabilityInfoRow(
              'Category',
              job.jobCategory.isEmpty ? 'N/A' : job.jobCategory,
              Icons.category,
            ),
            const SizedBox(height: 8),
            _buildAvailabilityInfoRow(
              'Contractor',
              job.contractorCompany.isEmpty ? 'N/A' : job.contractorCompany,
              Icons.business,
            ),
            const SizedBox(height: 8),
            _buildAvailabilityInfoRow(
              'Start Time',
              _formatSuggestedJobStartTime(job),
              Icons.schedule,
            ),
            const SizedBox(height: 8),
            _buildAvailabilityInfoRow(
              'Duration',
              '${job.jobDurationHours}h',
              Icons.timer,
            ),
            const SizedBox(height: 8),
            _buildAvailabilityInfoRow(
              'Location',
              '${job.jobLatitude.toStringAsFixed(6)}, '
                  '${job.jobLongitude.toStringAsFixed(6)}',
              Icons.location_on,
            ),
            const SizedBox(height: 8),
            _buildAvailabilityInfoRow(
              'Direction Distance',
              '${distanceKm.toStringAsFixed(2)} km',
              Icons.alt_route,
            ),
            if (showContractorAndDirection) ...[
              const SizedBox(height: 8),
              _buildAvailabilityInfoRow(
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
            onPressed: isInProgress ? null : () => _acceptSuggestedJob(suggestion),
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
            onPressed: isInProgress ? null : () => _startAcceptedJob(suggestion),
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
            onPressed: isInProgress ? null : () => _completeStartedJob(suggestion),
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

  Widget _buildAvailabilityCard(WorkerAvailability availability, int index) {
    final status = availability.status.toUpperCase();
    final isOnline = status == 'ONLINE';

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
                  'Availability $index',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Chip(
                  label: Text(status.isEmpty ? 'UNKNOWN' : status),
                  backgroundColor:
                      isOnline ? Colors.green.shade100 : Colors.grey.shade300,
                  labelStyle: TextStyle(
                    color: isOnline ? Colors.green.shade800 : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildAvailabilityInfoRow(
              'Location',
              '${availability.latitude.toStringAsFixed(6)}, '
                  '${availability.longitude.toStringAsFixed(6)}',
              Icons.location_on,
            ),
            const SizedBox(height: 8),
            _buildAvailabilityInfoRow(
              'Date Range',
              '${_formatDate(availability.startDate)} → ${_formatDate(availability.endDate)}',
              Icons.date_range,
            ),
            const SizedBox(height: 8),
            _buildAvailabilityInfoRow(
              'Frequency',
              availability.frequency.isEmpty ? 'N/A' : availability.frequency,
              Icons.repeat,
            ),
            const SizedBox(height: 12),
            const Text(
              'Windows',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            if (availability.windows.isEmpty)
              const Text(
                'No windows available',
                style: TextStyle(color: Colors.grey),
              )
            else
              Column(
                children: availability.windows.map((window) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_formatDateTime(window.startTime)),
                        ),
                        Text('Duration: ${window.duration}h'),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilityInfoRow(String label, String value, IconData icon) {
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

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'N/A';
    }

    return _dateFormat.format(date);
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) {
      return 'N/A';
    }

    return _dateTimeFormat.format(dateTime);
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
          Icon(icon, color: Colors.green.shade600),
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
