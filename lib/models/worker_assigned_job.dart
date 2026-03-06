class WorkerAssignedJob {
  final String workerId;
  final String assignedJobStatus;
  final String jobId;
  final String jobStatus;
  final double latitude;
  final double longitude;
  final String rawJobStartTime;
  final DateTime? jobStartTime;
  final int duration;
  final String contractorId;
  final String contractorName;

  const WorkerAssignedJob({
    required this.workerId,
    required this.assignedJobStatus,
    required this.jobId,
    required this.jobStatus,
    required this.latitude,
    required this.longitude,
    required this.rawJobStartTime,
    required this.jobStartTime,
    required this.duration,
    required this.contractorId,
    required this.contractorName,
  });

  factory WorkerAssignedJob.fromJson(Map<String, dynamic> json) {
    final rawStartTime = (json['jobStartTime'] ?? '').toString();
    final normalizedStartTime = rawStartTime.contains(' ')
        ? rawStartTime.replaceFirst(' ', 'T')
        : rawStartTime;

    return WorkerAssignedJob(
      workerId: (json['workerId'] ?? '').toString(),
      assignedJobStatus: (json['assignedJobStatus'] ?? '').toString(),
      jobId: (json['jobId'] ?? '').toString(),
      jobStatus: (json['jobStatus'] ?? '').toString(),
      latitude: _workerAssignedToDouble(json['latitude']),
      longitude: _workerAssignedToDouble(json['longitude']),
      rawJobStartTime: rawStartTime,
      jobStartTime: DateTime.tryParse(normalizedStartTime),
      duration: _workerAssignedToInt(json['duration']),
      contractorId: (json['contractorId'] ?? '').toString(),
      contractorName: (json['contractorName'] ?? '').toString(),
    );
  }
}

double _workerAssignedToDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value.toString()) ?? 0.0;
}

int _workerAssignedToInt(dynamic value) {
  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value.toString()) ?? 0;
}
