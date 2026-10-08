class WorkerJobSuggestionResponse {
  /// Open jobs the worker can still claim.
  final List<WorkerJobSuggestion> availableJobs;

  /// Jobs the worker has claimed that wait for contractor approval
  /// (jobStatus AWAITING_APPROVAL). Once approved they move to assigned jobs.
  final List<WorkerJobSuggestion> awaitingApprovalJobs;

  const WorkerJobSuggestionResponse({
    required this.availableJobs,
    this.awaitingApprovalJobs = const [],
  });

  factory WorkerJobSuggestionResponse.fromJson(Map<String, dynamic> json) {
    return WorkerJobSuggestionResponse(
      availableJobs: _parseSuggestions(json['availableJobs']),
      awaitingApprovalJobs: _parseSuggestions(json['awaitingApprovalJobs']),
    );
  }
}

List<WorkerJobSuggestion> _parseSuggestions(dynamic value) {
  return (value as List<dynamic>? ?? [])
      .whereType<Map<String, dynamic>>()
      .map(WorkerJobSuggestion.fromJson)
      .toList();
}

class WorkerJobSuggestion {
  final SuggestedJobInformation jobInformation;
  final SuggestedWorkerInformation workerInformation;

  const WorkerJobSuggestion({
    required this.jobInformation,
    required this.workerInformation,
  });

  factory WorkerJobSuggestion.fromJson(Map<String, dynamic> json) {
    return WorkerJobSuggestion(
      jobInformation: SuggestedJobInformation.fromJson(
        json['jobInformation'] as Map<String, dynamic>? ?? {},
      ),
      workerInformation: SuggestedWorkerInformation.fromJson(
        json['workerInformation'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class SuggestedJobInformation {
  final String jobId;
  final String jobStatus;
  final String jobDescription;
  final double jobLatitude;
  final double jobLongitude;
  final String rawJobStartTime;
  final DateTime? jobStartTime;
  final int jobDurationHours;
  final String jobCategory;
  final String contractorId;
  final String contractorCompany;
  final String processId;
  final String processDescription;
  final double jobPaymentAmount;

  /// AWAITING_APPROVAL while this worker's claim waits for the contractor.
  bool get isAwaitingApproval => jobStatus.toUpperCase() == 'AWAITING_APPROVAL';

  const SuggestedJobInformation({
    required this.jobId,
    required this.jobStatus,
    required this.jobDescription,
    required this.jobLatitude,
    required this.jobLongitude,
    required this.rawJobStartTime,
    required this.jobStartTime,
    required this.jobDurationHours,
    required this.jobCategory,
    required this.contractorId,
    required this.contractorCompany,
    required this.processId,
    required this.processDescription,
    required this.jobPaymentAmount,
  });

  factory SuggestedJobInformation.fromJson(Map<String, dynamic> json) {
    final rawStartTime = (json['jobStartTime'] ?? '').toString();
    final normalizedStartTime = rawStartTime.contains(' ')
        ? rawStartTime.replaceFirst(' ', 'T')
        : rawStartTime;

    return SuggestedJobInformation(
      jobId: (json['jobId'] ?? '').toString(),
      jobStatus: (json['jobStatus'] ?? '').toString(),
      jobDescription: (json['jobDescription'] ?? json['description'] ?? '')
          .toString(),
      jobLatitude: _toDouble(json['jobLatitude']),
      jobLongitude: _toDouble(json['jobLongitude']),
      rawJobStartTime: rawStartTime,
      jobStartTime: DateTime.tryParse(normalizedStartTime),
      jobDurationHours: _toInt(json['jobDurationHours']),
      jobCategory: (json['jobCategory'] ?? '').toString(),
      contractorId: (json['contractorId'] ?? '').toString(),
      contractorCompany: (json['contractorCompany'] ?? '').toString(),
      processId: (json['processId'] ?? '').toString(),
      processDescription: (json['processDescription'] ?? '').toString(),
      jobPaymentAmount: _toDouble(json['jobPaymentAmount']),
    );
  }
}

class SuggestedWorkerInformation {
  final String workerId;
  final double workerLatitude;
  final double workerLongitude;
  final int workerStartTime;
  final int workerDuration;

  const SuggestedWorkerInformation({
    required this.workerId,
    required this.workerLatitude,
    required this.workerLongitude,
    required this.workerStartTime,
    required this.workerDuration,
  });

  factory SuggestedWorkerInformation.fromJson(Map<String, dynamic> json) {
    return SuggestedWorkerInformation(
      workerId: (json['workerId'] ?? '').toString(),
      workerLatitude: _toDouble(json['workerLatitude']),
      workerLongitude: _toDouble(json['workerLongitude']),
      workerStartTime: _toInt(json['workerStartTime']),
      workerDuration: _toInt(json['workerDuration']),
    );
  }
}

double _toDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value.toString()) ?? 0.0;
}

int _toInt(dynamic value) {
  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value.toString()) ?? 0;
}
