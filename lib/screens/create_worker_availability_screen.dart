import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/availability.dart';
import '../providers/worker_provider.dart';
import '../services/preferences_service.dart';
import 'location_picker_screen.dart';

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

  LatLng _selectedLocation = _defaultColombo;
  String _selectedAddress = 'Colombo, Sri Lanka';
  bool _isLoadingAddress = false;
  DateTime? _startDate;
  DateTime? _endDate;
  String _frequency = 'weekly';
  bool _isSubmitting = false;
  final List<_TimeWindowDraft> _timeWindows = [
    _TimeWindowDraft(duration: 1),
  ];

  Future<void> _openLocationPicker() async {
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(initialLocation: _selectedLocation),
      ),
    );
    if (result != null) {
      setState(() => _selectedLocation = result);
      _reverseGeocode(result);
    }
  }

  Future<void> _reverseGeocode(LatLng point) async {
    setState(() => _isLoadingAddress = true);
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=${point.latitude}&lon=${point.longitude}&format=json',
      );
      final response = await http.get(uri, headers: {
        'User-Agent': 'fixflow_app/1.0',
      });
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final display = data['display_name'] as String?;
        if (display != null && mounted) {
          setState(() => _selectedAddress = display);
        }
      }
    } catch (_) {
      // Fallback – keep previous address
    } finally {
      if (mounted) setState(() => _isLoadingAddress = false);
    }
  }

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
    final current = _timeWindows[index].startTime ?? const TimeOfDay(hour: 9, minute: 0);
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: current,
    );

    if (selectedTime == null) return;

    setState(() {
      _timeWindows[index].startTime = selectedTime;
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

  DateTime _combineDateTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
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
              startTime: _combineDateTime(_startDate!, window.startTime!),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context, '/home', (route) => false),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Location',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _openLocationPicker,
              child: SizedBox(
                height: 200,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      IgnorePointer(
                        child: FlutterMap(
                          key: ValueKey(_selectedLocation),
                          options: MapOptions(
                            initialCenter: _selectedLocation,
                            initialZoom: 13,
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
                      Positioned(
                        bottom: 8,
                        left: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.touch_app, color: Colors.white, size: 16),
                              SizedBox(width: 6),
                              Text(
                                'Tap to pick location',
                                style: TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.location_on, size: 18, color: Colors.red),
                const SizedBox(width: 6),
                Expanded(
                  child: _isLoadingAddress
                      ? const Text('Looking up address...',
                          style: TextStyle(color: Colors.grey, fontSize: 13))
                      : Text(
                          _selectedAddress,
                          style: const TextStyle(fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
              ],
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
                              : window.startTime!.format(context),
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
  TimeOfDay? startTime;
  int duration;

  _TimeWindowDraft({
    required this.duration,
  });
}
