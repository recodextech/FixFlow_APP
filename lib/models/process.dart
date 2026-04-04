export 'wallet.dart';
export 'payment.dart';
export 'job.dart';

import 'job.dart';

class ProcessRequest {
  final String name;
  final String description;
  final List<Job> jobs;

  ProcessRequest({
    required this.name,
    required this.description,
    required this.jobs,
  });

  factory ProcessRequest.fromJson(Map<String, dynamic> json) {
    return ProcessRequest(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      jobs: (json['jobs'] as List<dynamic>?)
              ?.map((j) => Job.fromJson(j as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'jobs': jobs.map((j) => j.toJson()).toList(),
    };
  }
}

class ContractorProcessJobSummary {
  final String id;
  final String status;
  final double latitude;
  final double longitude;
  final String jobStartTime;
  final int durationHours;

  ContractorProcessJobSummary({
    required this.id,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.jobStartTime,
    required this.durationHours,
  });

  factory ContractorProcessJobSummary.fromJson(Map<String, dynamic> json) {
    return ContractorProcessJobSummary(
      id: json['id'] ?? '',
      status: json['status'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      jobStartTime: json['jobStartTime'] ?? json['startTime'] ?? '',
      durationHours: json['durationHours'] ?? json['duration'] ?? 0,
    );
  }
}

class ContractorProcessSummary {
  final String processId;
  final String name;
  final String status;
  final ContractorProcessJobSummary? job;

  ContractorProcessSummary({
    required this.processId,
    required this.name,
    required this.status,
    this.job,
  });

  factory ContractorProcessSummary.fromJson(Map<String, dynamic> json) {
    return ContractorProcessSummary(
      processId: json['processId'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      status: json['status'] ?? '',
      job: json['job'] is Map<String, dynamic>
          ? ContractorProcessJobSummary.fromJson(json['job'] as Map<String, dynamic>)
          : null,
    );
  }
}
