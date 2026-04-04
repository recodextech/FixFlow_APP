import 'payment.dart';

class Job {
  final String description;
  final String startTime;
  final int duration;
  final double latitude;
  final double longitude;
  final List<String> jobCategories;
  final PaymentInformation paymentInformation;

  Job({
    required this.description,
    required this.startTime,
    required this.duration,
    required this.latitude,
    required this.longitude,
    required this.jobCategories,
    required this.paymentInformation,
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
    };
  }
}
