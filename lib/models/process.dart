export 'wallet.dart';
export 'payment.dart';
export 'job.dart';

import 'job.dart';
import 'payment.dart';

class ProcessRequest {
  final String name;
  final String description;
  final List<Job> jobs;

  ProcessRequest({
    required this.name,
    this.description = '',
    required this.jobs,
  });

  factory ProcessRequest.fromJson(Map<String, dynamic> json) {
    return ProcessRequest(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      jobs:
          (json['jobs'] as List<dynamic>?)
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

/// The worker who claimed a job. Comes with [ContractorProcessJobSummary.approvalStatus].
class JobClaim {
  final String workerId;
  final String workerName;
  final String requestedAt;

  /// The worker's average rating; 5 when [ratingCount] is 0 (not rated yet).
  final double rating;
  final int ratingCount;

  const JobClaim({
    required this.workerId,
    this.workerName = '',
    this.requestedAt = '',
    this.rating = 5,
    this.ratingCount = 0,
  });

  factory JobClaim.fromJson(Map<String, dynamic> json) {
    return JobClaim(
      workerId: (json['workerId'] ?? '').toString(),
      workerName: (json['workerName'] ?? '').toString(),
      requestedAt: (json['requestedAt'] ?? '').toString(),
      rating: (json['rating'] as num?)?.toDouble() ?? 5,
      ratingCount: (json['ratingCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class ContractorProcessJobSummary {
  final String id;
  final String status;
  final double latitude;
  final double longitude;
  final String jobStartTime;
  final int durationHours;
  final String assignedWorkerId;
  final String assignedWorkerName;

  /// Phone number of the assigned worker. Sent once the contractor approved
  /// the worker's claim; empty otherwise.
  final String assignedWorkerPhone;
  final PaymentInformation? paymentInformation;

  /// State of the job's current worker claim while the job is still open
  /// (process CREATED, job PENDING): PENDING (contractor can approve or
  /// reject), REJECTED or EXPIRED (job is open to workers again).
  /// Empty, with [claim] null, when no worker has claimed the job.
  final String approvalStatus;
  final JobClaim? claim;

  bool get hasClaim => claim != null && claim!.workerId.isNotEmpty;

  bool get isAwaitingApproval =>
      hasClaim && approvalStatus.toUpperCase() == 'PENDING';

  ContractorProcessJobSummary({
    required this.id,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.jobStartTime,
    required this.durationHours,
    this.assignedWorkerId = '',
    this.assignedWorkerName = '',
    this.assignedWorkerPhone = '',
    this.paymentInformation,
    this.approvalStatus = '',
    this.claim,
  });

  factory ContractorProcessJobSummary.fromJson(Map<String, dynamic> json) {
    return ContractorProcessJobSummary(
      id: json['id'] ?? '',
      status: json['status'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      jobStartTime: json['jobStartTime'] ?? json['startTime'] ?? '',
      durationHours: json['durationHours'] ?? json['duration'] ?? 0,
      assignedWorkerId: (json['assignedWorkerId'] ?? json['workerId'] ?? '')
          .toString(),
      assignedWorkerName:
          (json['assignedWorkerName'] ?? json['workerName'] ?? '').toString(),
      assignedWorkerPhone: (json['assignedWorkerPhone'] ?? '').toString(),
      paymentInformation: json['paymentInformation'] is Map<String, dynamic>
          ? PaymentInformation.fromJson(
              json['paymentInformation'] as Map<String, dynamic>,
            )
          : null,
      approvalStatus: (json['approvalStatus'] ?? '').toString(),
      claim: json['claim'] is Map<String, dynamic>
          ? JobClaim.fromJson(json['claim'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ContractorProcessSummary {
  final String processId;
  final String name;
  final String status;
  final ContractorProcessJobSummary? job;

  /// History only: true once the contractor rated the worker of the
  /// completed job.
  final bool workerRatingCompleted;

  ContractorProcessSummary({
    required this.processId,
    required this.name,
    required this.status,
    this.job,
    this.workerRatingCompleted = false,
  });

  /// A completed job whose worker the contractor can rate (or already did).
  bool get isWorkerRatable =>
      status.toUpperCase() == 'COMPLETED' &&
      job != null &&
      job!.status.toUpperCase() == 'ENDED' &&
      job!.assignedWorkerId.isNotEmpty;

  factory ContractorProcessSummary.fromJson(Map<String, dynamic> json) {
    return ContractorProcessSummary(
      processId: json['processId'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      status: json['status'] ?? '',
      job: json['job'] is Map<String, dynamic>
          ? ContractorProcessJobSummary.fromJson(
              json['job'] as Map<String, dynamic>,
            )
          : null,
      workerRatingCompleted: json['workerRatingCompleted'] == true,
    );
  }
}

List<ContractorProcessSummary> parseContractorProcessList(dynamic raw) {
  if (raw is! List) return [];
  return raw
      .whereType<Map<String, dynamic>>()
      .map(ContractorProcessSummary.fromJson)
      .toList();
}

/// The contractor's open processes: [activeProcesses] already have an
/// approved, assigned worker; [pendingProcesses] still wait for one, with the
/// ones whose claim awaits the contractor's approval first.
class ContractorActiveProcesses {
  final List<ContractorProcessSummary> activeProcesses;
  final List<ContractorProcessSummary> pendingProcesses;

  const ContractorActiveProcesses({
    this.activeProcesses = const [],
    this.pendingProcesses = const [],
  });

  int get total => activeProcesses.length + pendingProcesses.length;

  bool get isEmpty => total == 0;

  factory ContractorActiveProcesses.fromJson(Map<String, dynamic> json) {
    return ContractorActiveProcesses(
      activeProcesses: parseContractorProcessList(json['activeProcesses']),
      pendingProcesses: parseContractorProcessList(json['pendingProcesses']),
    );
  }
}
