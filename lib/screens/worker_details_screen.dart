import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/availability.dart';
import '../models/worker.dart';
import '../providers/worker_provider.dart';
import '../services/preferences_service.dart';
import '../widgets/home_navigation_button.dart';
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
      appBar: AppBar(
        title: const Text('Worker Details'),
        actions: [
          IconButton(
            onPressed: _createAvailability,
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Create Availability',
          ),
          const HomeNavigationButton(),
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
                      setState(_loadData);
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
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Back'),
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
                _buildProfileHeader(worker),
                const SizedBox(height: 24),
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
                _buildInfoCard(
                  'Account ID',
                  worker.accountId ?? 'N/A',
                  Icons.account_circle,
                ),
                const SizedBox(height: 24),
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
                  children: [
                    const Expanded(
                      child: Text(
                        'Availability Windows',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _refreshAvailabilities,
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
                FutureBuilder<WorkerAvailabilityResponse>(
                  future: _availabilityFuture,
                  builder: (context, availabilitySnapshot) {
                    if (availabilitySnapshot.connectionState ==
                        ConnectionState.waiting) {
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
                            onPressed: _refreshAvailabilities,
                            child: const Text('Retry'),
                          ),
                        ],
                      );
                    }

                    final response = availabilitySnapshot.data ??
                        WorkerAvailabilityResponse(
                            availabilities: [], total: 0);

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
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _createAvailability,
                    icon: const Icon(Icons.calendar_month),
                    label: const Text('Create More Availability'),
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

  Widget _buildProfileHeader(Worker worker) {
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
              ],
            ),
          ),
        ],
      ),
    );
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
