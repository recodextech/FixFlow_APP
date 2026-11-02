import 'package:fixflow_app/models/process.dart';
import 'package:fixflow_app/models/worker_assigned_job.dart';
import 'package:fixflow_app/models/worker_job_suggestion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('job title from matching-service', () {
    test('suggested job parses jobTitle and jobDescription', () {
      final job = SuggestedJobInformation.fromJson({
        'jobId': 'job-1',
        'jobStatus': 'PENDING',
        'jobTitle': 'Kitchen sink repair',
        'jobDescription': 'Fix the leaking kitchen sink',
        'jobStartTime': '2030-01-01 10:00:00',
      });

      expect(job.jobTitle, 'Kitchen sink repair');
      expect(job.jobDescription, 'Fix the leaking kitchen sink');
    });

    test('assigned job parses jobTitle and keeps old responses working', () {
      final job = WorkerAssignedJob.fromJson({
        'jobId': 'job-1',
        'jobTitle': 'Kitchen sink repair',
        'jobDescription': 'Fix the leaking kitchen sink',
      });
      final oldJob = WorkerAssignedJob.fromJson({
        'jobId': 'job-2',
        'jobDescription': 'Fix the leaking kitchen sink',
      });

      expect(job.jobTitle, 'Kitchen sink repair');
      expect(job.jobDescription, 'Fix the leaking kitchen sink');
      expect(oldJob.jobTitle, isEmpty);
    });
  });

  test('job title limit is shorter than the description limit', () {
    expect(maxJobTitleLength, 50);
    expect(maxJobDescriptionLength, 500);
  });
}
