import 'dart:convert';
import 'dart:math' show min;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/availability.dart';
import '../providers/language_provider.dart';
import '../providers/worker_provider.dart';
import '../services/preferences_service.dart';
import 'location_picker_screen.dart';

class CreateWorkerAvailabilityScreen extends StatefulWidget {
  final String workerId;

  const CreateWorkerAvailabilityScreen({super.key, required this.workerId});

  @override
  State<CreateWorkerAvailabilityScreen> createState() =>
      _CreateWorkerAvailabilityScreenState();
}

class _CreateWorkerAvailabilityScreenState
    extends State<CreateWorkerAvailabilityScreen> {
  static const LatLng _defaultColombo = LatLng(6.927079, 79.861244);
  static const double _mapZoom = 13;

  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  final MapController _mapController = MapController();

  LatLng _selectedLocation = _defaultColombo;
  String _selectedAddress = 'Colombo, Sri Lanka';
  bool _isLoadingAddress = false;
  DateTime? _startDate;
  DateTime? _endDate;
  String _frequency = 'weekly';
  bool _isSubmitting = false;
  final List<_TimeWindowDraft> _timeWindows = [_TimeWindowDraft(duration: 1)];

  @override
  void initState() {
    super.initState();
    _setInitialLocationFromDevice();
  }

  Future<void> _setInitialLocationFromDevice() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      final userLocation = LatLng(position.latitude, position.longitude);
      setState(() {
        _selectedLocation = userLocation;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _mapController.move(userLocation, _mapZoom);
      });
      _reverseGeocode(userLocation);
    } catch (_) {
      // Keep fallback Colombo location if device location is unavailable.
    }
  }

  Future<void> _openLocationPicker() async {
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            LocationPickerScreen(initialLocation: _selectedLocation),
      ),
    );
    if (result != null) {
      setState(() => _selectedLocation = result);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _mapController.move(result, _mapZoom);
      });
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
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'fixflow_app/1.0'},
      );
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

  /// Whole hours from [start] until midnight (end of that calendar day), capped at 12.
  int _maxDurationHoursForStart(TimeOfDay start) {
    final startDt = DateTime(2000, 1, 1, start.hour, start.minute);
    final endOfDay = DateTime(2000, 1, 2);
    final wholeHours = endOfDay.difference(startDt).inMinutes ~/ 60;
    return min(12, wholeHours);
  }

  int _effectiveMaxDurationHours(TimeOfDay? start) {
    return _maxDurationHoursForStart(
      start ?? const TimeOfDay(hour: 9, minute: 0),
    );
  }

  void _clampTimeWindowDuration(int index) {
    final w = _timeWindows[index];
    if (w.startTime == null) return;
    final maxH = _maxDurationHoursForStart(w.startTime!);
    if (maxH >= 1 && w.duration > maxH) w.duration = maxH;
  }

  Future<void> _pickTimeWindowStart(int index) async {
    final current =
        _timeWindows[index].startTime ?? const TimeOfDay(hour: 9, minute: 0);
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: current,
    );

    if (selectedTime == null) return;

    setState(() {
      _timeWindows[index].startTime = selectedTime;
      _clampTimeWindowDuration(index);
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

  bool get _canCreateAvailability {
    if (_isSubmitting) return false;
    if (_startDate == null || _endDate == null) return false;
    if (_endDate!.isBefore(_startDate!)) return false;
    if (_frequency.isEmpty) return false;

    for (final window in _timeWindows) {
      final startTime = window.startTime;
      if (startTime == null) return false;
      if (window.duration <= 0) return false;

      final maxHours = _maxDurationHoursForStart(startTime);
      if (maxHours < 1 || window.duration > maxHours) return false;
    }

    return true;
  }

  String? _validateForm(AppLocalizations loc) {
    if (_startDate == null) {
      return loc.pleaseSelectStartDate;
    }

    if (_endDate == null) {
      return loc.pleaseSelectEndDate;
    }

    if (_endDate!.isBefore(_startDate!)) {
      return loc.endDateMustBeAfterStart;
    }

    for (var index = 0; index < _timeWindows.length; index++) {
      final window = _timeWindows[index];
      if (window.startTime == null) {
        return '${loc.pleaseSelectStartTimeForWindow} ${index + 1}';
      }
      if (window.duration <= 0) {
        return '${loc.durationMustBeGreaterThanZero} ${index + 1}';
      }
      final maxH = _maxDurationHoursForStart(window.startTime!);
      if (maxH < 1) {
        return '${loc.window} ${index + 1}: ${loc.startTimeTooLateForSlot}';
      }
      if (window.duration > maxH) {
        return '${loc.window} ${index + 1}: ${loc.durationCannotExceedMaxHours} $maxH';
      }
    }

    return null;
  }

  DateTime _combineDateTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _submit() async {
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    final loc = AppLocalizations.of(languageProvider.locale);

    final validationError = _validateForm(loc);
    if (validationError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validationError)));
      return;
    }

    final accountId = PreferencesService().getAccountId();
    if (accountId == null || accountId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(loc.accountIdMissing)));
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
        SnackBar(content: Text(loc.availabilityCreatedSuccessfully)),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${loc.failedToCreateAvailability}: $e')),
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
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        final loc = AppLocalizations.of(languageProvider.locale);
        return Scaffold(
          appBar: AppBar(
            title: Text(loc.addAvailability),
            actions: [
              IconButton(
                icon: const Icon(Icons.home_outlined),
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/home',
                  (route) => false,
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.location,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
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
                              mapController: _mapController,
                              options: MapOptions(
                                initialCenter: _selectedLocation,
                                initialZoom: _mapZoom,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName:
                                      'com.noventispvt.fixflow',
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.touch_app,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    loc.tapToPickLocation,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
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
                          ? Text(
                              loc.loadingAddress,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            )
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
                Text(
                  loc.availabilityRange,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
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
                              ? loc.startDate
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
                              ? loc.endDate
                              : _dateFormat.format(_endDate!),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _frequency,
                  decoration: InputDecoration(
                    labelText: loc.frequency,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: 'daily', child: Text(loc.daily)),
                    DropdownMenuItem(value: 'weekly', child: Text(loc.weekly)),
                    DropdownMenuItem(
                      value: 'monthly',
                      child: Text(loc.monthly),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _frequency = value;
                    });
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  loc.timeWindows,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
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
                                '${loc.window} ${index + 1}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
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
                                  ? loc.startDate
                                  : window.startTime!.format(context),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Builder(
                            builder: (context) {
                              final maxHours = _effectiveMaxDurationHours(
                                window.startTime,
                              );
                              if (maxHours < 1) {
                                return Text(
                                  loc.notEnoughTimeBeforeMidnight,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                    fontSize: 13,
                                  ),
                                );
                              }
                              if (window.duration > maxHours) {
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  if (!context.mounted) return;
                                  setState(() {
                                    window.duration = maxHours;
                                  });
                                });
                              }
                              return DropdownButtonFormField<int>(
                                initialValue: window.duration > maxHours
                                    ? maxHours
                                    : window.duration,
                                decoration: InputDecoration(
                                  labelText: loc.durationHoursLongLabel,
                                  border: const OutlineInputBorder(),
                                ),
                                items: List.generate(
                                  maxHours,
                                  (i) => DropdownMenuItem(
                                    value: i + 1,
                                    child: Text(loc.hoursCount(i + 1)),
                                  ),
                                ),
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() {
                                    window.duration = value;
                                  });
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: _addTimeWindow,
                    icon: const Icon(Icons.add),
                    label: Text(loc.addTimeWindow),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _canCreateAvailability ? _submit : null,
                    icon: const Icon(Icons.check),
                    label: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _canCreateAvailability
                                ? loc.addAvailability
                                : loc.completeRequiredFields,
                          ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _canCreateAvailability
                          ? Colors.green
                          : null,
                      foregroundColor: _canCreateAvailability
                          ? Colors.white
                          : null,
                      padding: const EdgeInsets.symmetric(vertical: 14),
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
}

class _TimeWindowDraft {
  TimeOfDay? startTime;
  int duration;

  _TimeWindowDraft({required this.duration});
}
