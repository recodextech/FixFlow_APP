import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/availability.dart';
import '../models/worker.dart';
import '../providers/worker_provider.dart';
import '../services/api_service.dart';
import '../services/preferences_service.dart';
import '../theme.dart';
import 'create_worker_availability_screen.dart';

class WorkerDetailsScreen extends StatefulWidget {
  final String workerId;

  const WorkerDetailsScreen({
    super.key,
    required this.workerId,
  });

  @override
  State<WorkerDetailsScreen> createState() => _WorkerDetailsScreenState();
}

class _WorkerDetailsScreenState extends State<WorkerDetailsScreen> {
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  final DateFormat _dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm');

  late Future<Worker?> _workerFuture;
  late Future<WorkerAvailabilityResponse> _availabilityFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _workerFuture = _loadWorker();
    _availabilityFuture = _loadAvailabilities();
  }

  Future<Worker?> _loadWorker() {
    return context.read<WorkerProvider>().getWorker(
          widget.workerId,
          accountId: PreferencesService().getAccountId(),
        );
  }

  Future<WorkerAvailabilityResponse> _loadAvailabilities() {
    return context.read<WorkerProvider>().getWorkerAvailabilities(
          workerId: widget.workerId,
          accountId: PreferencesService().getAccountId(),
        );
  }

  Future<void> _refreshAvailabilities() async {
    setState(() {
      _availabilityFuture = _loadAvailabilities();
    });
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
      _refreshAvailabilities();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createAvailability,
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Availability'),
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
                  Icon(Icons.error_outline, size: 48, color: AppColors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}',
                      style: const TextStyle(color: AppColors.text2)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(_loadData),
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
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Back'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Green gradient header
                Container(
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
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: const Icon(Icons.arrow_back,
                                    color: Colors.white),
                              ),
                              const Spacer(),
                              const Text(
                                'Edit Worker Profile',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const Spacer(),
                              const SizedBox(width: 24),
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
                                    Text(
                                      worker.email,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white.withValues(alpha: 0.8),
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
                  ),
                ),
                // Body content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Personal Info
                      const Text(
                        'Personal Information',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(Icons.email_outlined, 'Email', worker.email),
                      _buildInfoRow(Icons.phone_outlined, 'Phone', worker.phoneNumber),
                      _buildInfoRow(Icons.badge_outlined, 'Account',
                          worker.accountId ?? 'N/A'),
                      const SizedBox(height: 24),
                      // Categories
                      const Text(
                        'Categories',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (worker.categories.isEmpty)
                        const Text(
                          'No categories assigned',
                          style: TextStyle(fontSize: 13, color: AppColors.text3),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: worker.categories.map((category) {
                            return Chip(
                              label: Text(category,
                                  style: const TextStyle(fontSize: 13)),
                              backgroundColor: AppColors.greenPale,
                              side: BorderSide.none,
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 24),
                      // Availability Windows
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Availability Windows',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.text,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _refreshAvailabilities,
                            child: const Icon(Icons.refresh,
                                size: 20, color: AppColors.green),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FutureBuilder<WorkerAvailabilityResponse>(
                        future: _availabilityFuture,
                        builder: (context, availabilitySnapshot) {
                          if (availabilitySnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child:
                                  Center(child: CircularProgressIndicator()),
                            );
                          }

                          if (availabilitySnapshot.hasError) {
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.redPale,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded,
                                      size: 18, color: AppColors.red),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text('Could not load availabilities',
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: AppColors.red)),
                                  ),
                                  TextButton(
                                    onPressed: _refreshAvailabilities,
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            );
                          }

                          final response = availabilitySnapshot.data ??
                              WorkerAvailabilityResponse(
                                  availabilities: [], total: 0);

                          if (response.availabilities.isEmpty) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.gray1,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.event_busy,
                                      size: 36, color: AppColors.gray4),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'No availability windows',
                                    style: TextStyle(
                                        fontSize: 14, color: AppColors.text2),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Tap the button below to add one',
                                    style: TextStyle(
                                        fontSize: 12, color: AppColors.text3),
                                  ),
                                ],
                              ),
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${response.total} total',
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.text3),
                              ),
                              const SizedBox(height: 8),
                              ...response.availabilities
                                  .asMap()
                                  .entries
                                  .map((entry) {
                                return _buildAvailabilityCard(
                                    entry.value, entry.key + 1);
                              }),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 80), // FAB clearance
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.green),
          const SizedBox(width: 10),
          Text('$label: ',
              style: const TextStyle(fontSize: 13, color: AppColors.text3)),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.text)),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityCard(WorkerAvailability availability, int index) {
    final status = availability.status.toUpperCase();
    final isOnline = status == 'ONLINE';

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
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isOnline ? AppColors.greenPale : AppColors.gray1,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.event_available,
                    size: 18,
                    color: isOnline ? AppColors.green : AppColors.gray5,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Availability $index',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: isOnline ? AppColors.greenPale : AppColors.gray1,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.isEmpty ? 'UNKNOWN' : status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isOnline ? AppColors.green : AppColors.gray5,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 15, color: AppColors.text3),
                const SizedBox(width: 6),
                Expanded(
                  child: FutureBuilder<String>(
                    future: ApiService().reverseGeocode(availability.latitude, availability.longitude),
                    builder: (context, snap) {
                      return Text(
                        snap.data ?? 'Loading address...',
                        style: const TextStyle(fontSize: 13, color: AppColors.text2),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _buildAvailabilityInfoRow(
              Icons.date_range,
              '${_formatDate(availability.startDate)} → ${_formatDate(availability.endDate)}',
            ),
            const SizedBox(height: 6),
            _buildAvailabilityInfoRow(
              Icons.repeat,
              availability.frequency.isEmpty ? 'N/A' : availability.frequency,
            ),
            if (availability.windows.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text(
                'Time Windows',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text2),
              ),
              const SizedBox(height: 6),
              ...availability.windows.map((window) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.gray1,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.schedule,
                          size: 15, color: AppColors.text3),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(_formatDateTime(window.startTime),
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.text2)),
                      ),
                      Text('${window.duration}h',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text)),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilityInfoRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.text3),
        const SizedBox(width: 6),
        Expanded(
          child: Text(value,
              style: const TextStyle(fontSize: 12, color: AppColors.text2)),
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

  String _workerInitial(String workerName) {
    final trimmed = workerName.trim();
    if (trimmed.isEmpty) {
      return 'W';
    }

    return trimmed[0].toUpperCase();
  }
}
