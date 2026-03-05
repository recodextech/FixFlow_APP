class WorkerJobSuggestionResponse {
  final List<WorkerJobSuggestion> availableJobs;

  const WorkerJobSuggestionResponse({
    required this.availableJobs,
  });

  factory WorkerJobSuggestionResponse.fromJson(Map<String, dynamic> json) {
    final jobs = (json['availableJobs'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(WorkerJobSuggestion.fromJson)
        .toList();

    return WorkerJobSuggestionResponse(availableJobs: jobs);
  }
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
  final double jobLatitude;
  final double jobLongitude;
  final String rawJobStartTime;
  final DateTime? jobStartTime;
  final int jobDurationHours;
  final String jobCategory;
  final String contractorId;
  final String contractorCompany;
  final String processId;

  const SuggestedJobInformation({
    required this.jobId,
    required this.jobStatus,
    required this.jobLatitude,
    required this.jobLongitude,
    required this.rawJobStartTime,
    required this.jobStartTime,
    required this.jobDurationHours,
    required this.jobCategory,
    required this.contractorId,
    required this.contractorCompany,
    required this.processId,
  });

  factory SuggestedJobInformation.fromJson(Map<String, dynamic> json) {
    final rawStartTime = (json['jobStartTime'] ?? '').toString();
    final normalizedStartTime = rawStartTime.contains(' ')
        ? rawStartTime.replaceFirst(' ', 'T')
        : rawStartTime;

    return SuggestedJobInformation(
      jobId: (json['jobId'] ?? '').toString(),
      jobStatus: (json['jobStatus'] ?? '').toString(),
      jobLatitude: _toDouble(json['jobLatitude']),
      jobLongitude: _toDouble(json['jobLongitude']),
      rawJobStartTime: rawStartTime,
      jobStartTime: DateTime.tryParse(normalizedStartTime),
      jobDurationHours: _toInt(json['jobDurationHours']),
      jobCategory: (json['jobCategory'] ?? '').toString(),
      contractorId: (json['contractorId'] ?? '').toString(),
      contractorCompany: (json['contractorCompany'] ?? '').toString(),
      processId: (json['processId'] ?? '').toString(),
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
