import 'payment.dart';

class Job {
  final String description;
  final String startTime;
  final int duration;
  final double latitude;
  final double longitude;
  final List<String> jobCategories;
  final PaymentInformation paymentInformation;

  /// Base64-encoded JPEG strings (no `data:` prefix), for create/update payloads.
  final List<String> photos;

  Job({
    required this.description,
    required this.startTime,
    required this.duration,
    required this.latitude,
    required this.longitude,
    required this.jobCategories,
    required this.paymentInformation,
    this.photos = const [],
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      description: json['description'] ?? '',
      startTime: json['startTime'] ?? '',
      duration: json['duration'] ?? 0,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      jobCategories: List<String>.from(json['jobCategories'] ?? []),
      paymentInformation: PaymentInformation.fromJson(
        json['paymentInformation'] ?? {},
      ),
      photos: (json['photos'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'startTime': startTime,
      'duration': duration,
      'latitude': latitude,
      'longitude': longitude,
      'jobCategories': jobCategories,
      'paymentInformation': paymentInformation.toJson(),
      if (photos.isNotEmpty) 'photos': photos,
    };
  }
}
