import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/availability.dart';
import '../models/worker.dart';
import '../models/contractor.dart';
import '../models/process.dart';
import '../models/worker_assigned_job.dart';
import '../models/worker_job_suggestion.dart';

class ApiService {
  // Base URLs - can be configured via environment
  static const String _baseUrl = 'http://localhost:8888';
  static const String _managementUrl = 'http://localhost:8090';
  static const String _paymentEngineUrl = 'http://localhost:8070';
  static const String _userId = 'flutter-client';

  static final ApiService _instance = ApiService._internal();

  factory ApiService() {
    return _instance;
  }

  ApiService._internal();

  Map<String, String> _getHeaders({
    String? accountId,
    String? traceId,
    String? userId,
  }) {
    return {
      'Content-Type': 'application/json',
      'user-id':
          userId != null && userId.isNotEmpty ? userId : _userId,
      'Accept': 'application/json',
      if (accountId != null) 'account-id': accountId,
      if (traceId != null) 'trace-id': traceId,
    };
  }

  String _buildTraceId() {
    return 'trace-${DateTime.now().microsecondsSinceEpoch}';
  }

  /// Get all categories
  Future<List<Category>> getCategories({String? accountId}) async {
    try {
      final response = await http.get(
        Uri.parse('$_managementUrl/categories'),
        headers: _getHeaders(accountId: accountId),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }

      final List<dynamic> data = jsonDecode(response.body) ?? [];
      return data.map((json) => Category.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Error fetching categories: $e');
      rethrow;
    }
  }

  /// Create a worker
  Future<Map<String, dynamic>> createWorker({
    required String workerName,
    required String email,
    required String phoneNumber,
    required List<String> workerCategories,
  }) async {
    try {
      final payload = {
        'workerName': workerName,
        'email': email,
        'phoneNumber': phoneNumber,
        'workerCategories': workerCategories,
      };

      final response = await http.post(
        Uri.parse('$_managementUrl/workers'),
        headers: _getHeaders(),
        body: jsonEncode(payload),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to create worker: ${response.statusCode} - ${response.body}');
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      print('Error creating worker: $e');
      rethrow;
    }
  }

  /// Create worker availability window
  Future<Map<String, dynamic>> createWorkerAvailability({
    required String workerId,
    required String accountId,
    required WorkerAvailabilityRequest request,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_managementUrl/worker/$workerId/availability'),
        headers: _getHeaders(
          accountId: accountId,
          traceId: _buildTraceId(),
        ),
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
          'Failed to create worker availability: '
          '${response.statusCode} - ${response.body}',
        );
      }

      if (response.body.isEmpty) {
        return {'status': 'success'};
      }

      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        return data;
      }

      return {'data': data};
    } catch (e) {
      print('Error creating worker availability: $e');
      rethrow;
    }
  }

  /// Get worker availability windows
  Future<WorkerAvailabilityResponse> getWorkerAvailabilities({
    required String workerId,
    String? accountId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_managementUrl/worker/$workerId/availability'),
        headers: _getHeaders(
          accountId: accountId,
          traceId: _buildTraceId(),
        ),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to load worker availabilities: '
          '${response.statusCode} - ${response.body}',
        );
      }

      if (response.body.isEmpty) {
        return WorkerAvailabilityResponse(availabilities: [], total: 0);
      }

      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        return WorkerAvailabilityResponse.fromJson(data);
      }

      if (data is List<dynamic>) {
        return WorkerAvailabilityResponse(
          availabilities: data
              .map((item) => WorkerAvailability.fromJson(item as Map<String, dynamic>))
              .toList(),
          total: data.length,
        );
      }

      return WorkerAvailabilityResponse(availabilities: [], total: 0);
    } catch (e) {
      print('Error fetching worker availabilities: $e');
      rethrow;
    }
  }

  /// Get suggested jobs for a worker from matching service
  Future<WorkerJobSuggestionResponse> getWorkerJobSuggestions({
    required String workerId,
    String? accountId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/jobs/worker/$workerId/suggestions'),
        headers: _getHeaders(
          accountId: accountId,
          traceId: _buildTraceId(),
          userId: workerId,
        ),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to load worker job suggestions: '
          '${response.statusCode} - ${response.body}',
        );
      }

      if (response.body.isEmpty) {
        return const WorkerJobSuggestionResponse(availableJobs: []);
      }

      final data = jsonDecode(response.body);

      if (data is Map<String, dynamic>) {
        return WorkerJobSuggestionResponse.fromJson(data);
      }

      if (data is List<dynamic>) {
        return WorkerJobSuggestionResponse(
          availableJobs: data
              .whereType<Map<String, dynamic>>()
              .map(WorkerJobSuggestion.fromJson)
              .toList(),
        );
      }

      return const WorkerJobSuggestionResponse(availableJobs: []);
    } catch (e) {
      print('Error fetching worker job suggestions: $e');
      rethrow;
    }
  }

  /// Get assigned jobs for a worker
  Future<List<WorkerAssignedJob>> getWorkerAssignedJobs({
    required String workerId,
    String? accountId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/jobs/worker/$workerId/assigned'),
        headers: _getHeaders(
          accountId: accountId,
          traceId: _buildTraceId(),
          userId: workerId,
        ),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to load worker assigned jobs: '
          '${response.statusCode} - ${response.body}',
        );
      }

      if (response.body.isEmpty) {
        return const [];
      }

      final data = jsonDecode(response.body);

      if (data is List<dynamic>) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(WorkerAssignedJob.fromJson)
            .toList();
      }

      if (data is Map<String, dynamic>) {
        final jobs = data['assignedJobs'] ?? data['jobs'] ?? data['pendingJobs'];
        if (jobs is List<dynamic>) {
          return jobs
              .whereType<Map<String, dynamic>>()
              .map(WorkerAssignedJob.fromJson)
              .toList();
        }
      }

      return const [];
    } catch (e) {
      print('Error fetching worker assigned jobs: $e');
      rethrow;
    }
  }

  /// Accept a worker job
  Future<void> acceptWorkerJob({
    required String workerId,
    required String jobId,
    required String accountId,
  }) async {
    await _updateWorkerJobStatus(
      workerId: workerId,
      jobId: jobId,
      accountId: accountId,
      action: 'accepted',
    );
  }

  /// Start a worker job
  Future<void> startWorkerJob({
    required String workerId,
    required String jobId,
    required String accountId,
  }) async {
    await _updateWorkerJobStatus(
      workerId: workerId,
      jobId: jobId,
      accountId: accountId,
      action: 'started',
    );
  }

  /// Complete a worker job as success
  Future<void> completeWorkerJobSuccess({
    required String workerId,
    required String jobId,
    required String accountId,
  }) async {
    await _updateWorkerJobStatus(
      workerId: workerId,
      jobId: jobId,
      accountId: accountId,
      action: 'success',
    );
  }

  Future<void> _updateWorkerJobStatus({
    required String workerId,
    required String jobId,
    required String accountId,
    required String action,
  }) async {
    final response = await http.patch(
      Uri.parse('$_managementUrl/worker/$workerId/job/$jobId/$action'),
      headers: _getHeaders(
        accountId: accountId,
        traceId: _buildTraceId(),
        userId: workerId,
      ),
    );

    if (response.statusCode != 200 &&
        response.statusCode != 202 &&
        response.statusCode != 204) {
      throw Exception(
        'Failed to update worker job status: '
        '${response.statusCode} - ${response.body}',
      );
    }
  }

  /// Create a contractor
  Future<Map<String, dynamic>> createContractor({
    required String contractorName,
    required String contractorType,
    required String email,
    required String phoneNumber,
  }) async {
    try {
      final payload = {
        'contractorName': contractorName,
        'contractorType': contractorType,
        'email': email,
        'phoneNumber': phoneNumber,
      };

      final response = await http.post(
        Uri.parse('$_managementUrl/contractors'),
        headers: _getHeaders(),
        body: jsonEncode(payload),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to create contractor: ${response.statusCode} - ${response.body}');
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      print('Error creating contractor: $e');
      rethrow;
    }
  }



  /// Get single worker by ID
  Future<Worker?> getWorker(String workerId, {String? accountId}) async {
    try {
      final response = await http.get(
        Uri.parse('$_managementUrl/workers/$workerId'),
        headers: _getHeaders(
          accountId: accountId,
          traceId: _buildTraceId(),
        ),
      );

      if (response.statusCode == 404) {
        return null;
      }

      if (response.statusCode != 200) {
        throw Exception('Failed to load worker: ${response.statusCode}');
      }

      return Worker.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } catch (e) {
      print('Error fetching worker: $e');
      rethrow;
    }
  }

  /// Get single contractor by ID
  Future<Contractor?> getContractor(String contractorId, {String? accountId}) async {
    try {
      final response = await http.get(
        Uri.parse('$_managementUrl/contractors/$contractorId'),
        headers: _getHeaders(
          accountId: accountId,
          traceId: _buildTraceId(),
        ),
      );

      if (response.statusCode == 404) {
        return null;
      }

      if (response.statusCode != 200) {
        throw Exception('Failed to load contractor: ${response.statusCode}');
      }

      return Contractor.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } catch (e) {
      print('Error fetching contractor: $e');
      rethrow;
    }
  }

  /// Get all wallets from payment engine
  Future<List<Wallet>> getWallets({String? accountId}) async {
    try {
      final response = await http.get(
        Uri.parse('$_paymentEngineUrl/wallets'),
        headers: _getHeaders(accountId: accountId),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load wallets: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      
      // Handle both list response and object with wallets key
      List<dynamic> walletList;
      if (data is List<dynamic>) {
        walletList = data;
      } else if (data is Map<String, dynamic>) {
        walletList = data['wallets'] ?? [];
      } else {
        walletList = [];
      }
      
      return walletList.map((json) => Wallet.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Error fetching wallets: $e');
      rethrow;
    }
  }

  /// Get processes for a contractor
  Future<List<ContractorProcessSummary>> getContractorProcesses({
    required String contractorId,
    String? accountId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_managementUrl/contractor/$contractorId/processes'),
        headers: _getHeaders(
          accountId: accountId,
          traceId: _buildTraceId(),
        ),
      );

      if (response.statusCode == 404) {
        return [];
      }

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to load contractor processes: ${response.statusCode} - ${response.body}',
        );
      }

      if (response.body.isEmpty) {
        return [];
      }

      final data = jsonDecode(response.body);

      List<dynamic> processList;
      if (data is Map<String, dynamic>) {
        processList = data['processes'] ?? [];
      } else if (data is List<dynamic>) {
        processList = data;
      } else {
        processList = [];
      }

      return processList
          .whereType<Map<String, dynamic>>()
          .map(ContractorProcessSummary.fromJson)
          .toList();
    } catch (e) {
      print('Error fetching contractor processes: $e');
      rethrow;
    }
  }

  /// Create a process with jobs for a contractor
  Future<Map<String, dynamic>> createContractorProcess({
    required String contractorId,
    required String accountId,
    required ProcessRequest processRequest,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_managementUrl/contractor/$contractorId/processes'),
        headers: _getHeaders(
          accountId: accountId,
          traceId: _buildTraceId(),
        ),
        body: jsonEncode(processRequest.toJson()),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
          'Failed to create process: ${response.statusCode} - ${response.body}',
        );
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      print('Error creating contractor process: $e');
      rethrow;
    }
  }
}
