import 'package:intl/intl.dart';

class AvailabilityLocation {
  final double latitude;
  final double longitude;

  AvailabilityLocation({
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

class AvailabilityTimeWindow {
  final DateTime startTime;
  final int duration;

  AvailabilityTimeWindow({
    required this.startTime,
    required this.duration,
  });

  Map<String, dynamic> toJson() {
    return {
      'startTime': DateFormat("yyyy-MM-dd'T'HH:mm").format(startTime),
      'duration': duration,
    };
  }
}

class WorkerAvailabilityRequest {
  final AvailabilityLocation location;
  final DateTime startDate;
  final DateTime endDate;
  final String frequency;
  final List<AvailabilityTimeWindow> timeWindow;

  WorkerAvailabilityRequest({
    required this.location,
    required this.startDate,
    required this.endDate,
    required this.frequency,
    required this.timeWindow,
  });

  Map<String, dynamic> toJson() {
    return {
      'location': location.toJson(),
      'startDate': DateFormat('yyyy-MM-dd').format(startDate),
      'endDate': DateFormat('yyyy-MM-dd').format(endDate),
      'frequency': frequency,
      'timeWindow': timeWindow.map((window) => window.toJson()).toList(),
    };
  }
}

class WorkerAvailabilityWindow {
  final String id;
  final DateTime? startTime;
  final int duration;

  WorkerAvailabilityWindow({
    required this.id,
    required this.startTime,
    required this.duration,
  });

  factory WorkerAvailabilityWindow.fromJson(Map<String, dynamic> json) {
    return WorkerAvailabilityWindow(
      id: json['id']?.toString() ?? '',
      startTime: _parseDateTime(json['startTime']?.toString()),
      duration: (json['duration'] as num?)?.toInt() ?? 0,
    );
  }
}

class WorkerAvailability {
  final double latitude;
  final double longitude;
  final DateTime? startDate;
  final DateTime? endDate;
  final String status;
  final String frequency;
  final List<WorkerAvailabilityWindow> windows;

  WorkerAvailability({
    required this.latitude,
    required this.longitude,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.frequency,
    required this.windows,
  });

  factory WorkerAvailability.fromJson(Map<String, dynamic> json) {
    return WorkerAvailability(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      startDate: _parseDate(json['startDate']?.toString()),
      endDate: _parseDate(json['endDate']?.toString()),
      status: json['status']?.toString() ?? '',
      frequency: json['frequency']?.toString() ?? '',
      windows: (json['windows'] as List<dynamic>? ?? [])
          .map((item) => WorkerAvailabilityWindow.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class WorkerAvailabilityResponse {
  final List<WorkerAvailability> availabilities;
  final int total;

  WorkerAvailabilityResponse({
    required this.availabilities,
    required this.total,
  });

  factory WorkerAvailabilityResponse.fromJson(Map<String, dynamic> json) {
    final availabilities = (json['availabilities'] as List<dynamic>? ?? [])
        .map((item) => WorkerAvailability.fromJson(item as Map<String, dynamic>))
        .toList();

    return WorkerAvailabilityResponse(
      availabilities: availabilities,
      total: (json['total'] as num?)?.toInt() ?? availabilities.length,
    );
  }
}

DateTime? _parseDate(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }

  return DateTime.tryParse(value);
}

DateTime? _parseDateTime(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }

  final parsed = DateTime.tryParse(value);
  if (parsed != null) {
    return parsed;
  }

  final normalized = value.replaceFirst(' ', 'T');
  final normalizedParsed = DateTime.tryParse(normalized);
  if (normalizedParsed != null) {
    return normalizedParsed;
  }

  try {
    return DateFormat('yyyy-MM-dd HH:mm:ss').parse(value);
  } catch (_) {
    return null;
  }
}