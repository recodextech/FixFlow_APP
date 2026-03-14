import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/availability.dart';
import '../providers/worker_provider.dart';
import '../services/preferences_service.dart';
import '../widgets/home_navigation_button.dart';

class CreateWorkerAvailabilityScreen extends StatefulWidget {
  final String workerId;

  const CreateWorkerAvailabilityScreen({
    super.key,
    required this.workerId,
  });

  @override
  State<CreateWorkerAvailabilityScreen> createState() =>
      _CreateWorkerAvailabilityScreenState();
}

class _CreateWorkerAvailabilityScreenState
    extends State<CreateWorkerAvailabilityScreen> {
  static const LatLng _defaultColombo = LatLng(6.927079, 79.861244);

  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  final DateFormat _dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm');

  LatLng _selectedLocation = _defaultColombo;
  DateTime? _startDate;
  DateTime? _endDate;
  String _frequency = 'weekly';
  bool _isSubmitting = false;
  final List<_TimeWindowDraft> _timeWindows = [
    _TimeWindowDraft(duration: 1),
  ];

  Future<void> _pickStartDate() async {
    final initialDate = _startDate ?? DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (selected == null) return;

    setState(() {
      _startDate = selected;
      if (_endDate != null && _endDate!.isBefore(_startDate!)) {
        _endDate = _startDate;
      }
    });
  }

  Future<void> _pickEndDate() async {
    final initialDate = _endDate ?? _startDate ?? DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate:
          _startDate ?? DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (selected == null) return;

    setState(() {
      _endDate = selected;
    });
  }

  Future<void> _pickTimeWindowStart(int index) async {
    final current = _timeWindows[index].startTime ?? DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (selectedDate == null || !mounted) return;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );

    if (selectedTime == null) return;

    setState(() {
      _timeWindows[index].startTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );
    });
  }

  void _addTimeWindow() {
    setState(() {
      _timeWindows.add(_TimeWindowDraft(duration: 1));
    });
  }

  void _removeTimeWindow(int index) {
    if (_timeWindows.length == 1) return;
    setState(() {
      _timeWindows.removeAt(index);
    });
  }

  String? _validateForm() {
    if (_startDate == null) {
      return 'Please select a start date';
    }

    if (_endDate == null) {
      return 'Please select an end date';
    }

    if (_endDate!.isBefore(_startDate!)) {
      return 'End date must be on or after start date';
    }

    for (var index = 0; index < _timeWindows.length; index++) {
      final window = _timeWindows[index];
      if (window.startTime == null) {
        return 'Please select start time for window ${index + 1}';
      }
      if (window.duration <= 0) {
        return 'Duration must be greater than 0 for window ${index + 1}';
      }
    }

    return null;
  }

  Future<void> _submit() async {
    final validationError = _validateForm();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError)),
      );
      return;
    }

    final accountId = PreferencesService().getAccountId();
    if (accountId == null || accountId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Account ID is missing. Please re-login.')),
      );
      return;
    }

    final request = WorkerAvailabilityRequest(
      location: AvailabilityLocation(
        latitude: _selectedLocation.latitude,
        longitude: _selectedLocation.longitude,
      ),
      startDate: _startDate!,
      endDate: _endDate!,
      frequency: _frequency,
      timeWindow: _timeWindows
          .map(
            (window) => AvailabilityTimeWindow(
              startTime: window.startTime!,
              duration: window.duration,
            ),
          )
          .toList(),
    );

    setState(() {
      _isSubmitting = true;
    });

    try {
      await context.read<WorkerProvider>().createWorkerAvailability(
            workerId: widget.workerId,
            accountId: accountId,
            request: request,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Availability created successfully')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create availability: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Availability'),
        actions: const [HomeNavigationButton()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Location (Colombo, Sri Lanka)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 250,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: _defaultColombo,
                    initialZoom: 11,
                    onTap: (_, point) {
                      setState(() {
                        _selectedLocation = point;
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.recodextech.fixflow_app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _selectedLocation,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_pin,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Selected: ${_selectedLocation.latitude.toStringAsFixed(6)}, '
              '${_selectedLocation.longitude.toStringAsFixed(6)}',
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _selectedLocation = _defaultColombo;
                });
              },
              icon: const Icon(Icons.my_location),
              label: const Text('Reset to Colombo'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Availability Range',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickStartDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      _startDate == null
                          ? 'Start Date'
                          : _dateFormat.format(_startDate!),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickEndDate,
                    icon: const Icon(Icons.event),
                    label: Text(
                      _endDate == null
                          ? 'End Date'
                          : _dateFormat.format(_endDate!),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _frequency,
              decoration: const InputDecoration(
                labelText: 'Frequency',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'daily', child: Text('Daily')),
                DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _frequency = value;
                });
              },
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Time Windows',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                OutlinedButton.icon(
                  onPressed: _addTimeWindow,
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._timeWindows.asMap().entries.map((entry) {
              final index = entry.key;
              final window = entry.value;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Window ${index + 1}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          IconButton(
                            onPressed: _timeWindows.length == 1
                                ? null
                                : () => _removeTimeWindow(index),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => _pickTimeWindowStart(index),
                        icon: const Icon(Icons.schedule),
                        label: Text(
                          window.startTime == null
                              ? 'Select Start Time'
                              : _dateTimeFormat.format(window.startTime!),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: window.duration,
                        decoration: const InputDecoration(
                          labelText: 'Duration (hours)',
                          border: OutlineInputBorder(),
                        ),
                        items: List.generate(
                          24,
                          (i) => DropdownMenuItem(
                            value: i + 1,
                            child: Text('${i + 1} hour${i == 0 ? '' : 's'}'),
                          ),
                        ),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            window.duration = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: const Icon(Icons.check),
                label: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create Availability'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeWindowDraft {
  DateTime? startTime;
  int duration;

  _TimeWindowDraft({
    required this.duration,
  });
}
