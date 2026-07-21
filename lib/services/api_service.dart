import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/availability.dart';
import '../models/worker.dart';
import '../models/contractor.dart';
import '../models/user_accounts.dart';
import '../models/process.dart';
import '../models/worker_assigned_job.dart';
import '../models/worker_job_suggestion.dart';
import '../models/job_images.dart';
import 'auth_service.dart';
import 'preferences_service.dart';

class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final String? trace;
  final String? debug;

  const ApiException({
    required this.message,
    this.statusCode,
    this.trace,
    this.debug,
  });

  @override
  String toString() => message;
}

class ApiService {
  // All API calls route through KrakenD gateway
  static const String _gatewayUrl = 'http://noventispvt.xyz:8081';

  // Gateway path prefixes for each backend service
  static const String _managementPath = '/api/v1/management';
  static const String _paymentPath = '/api/v1/payment-engine';
  static const String _userId = 'flutter-client';

  static final ApiService _instance = ApiService._internal();

  factory ApiService() {
    return _instance;
  }

  ApiService._internal();

  // Address cache for reverse geocoding
  final Map<String, String> _addressCache = {};

  Future<String> reverseGeocode(double latitude, double longitude) async {
    final key =
        '${latitude.toStringAsFixed(6)},${longitude.toStringAsFixed(6)}';
    if (_addressCache.containsKey(key)) return _addressCache[key]!;

    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=$latitude&lon=$longitude&format=json',
      );
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'fixflow_app/1.0'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final display = data['display_name'] as String?;
        if (display != null) {
          _addressCache[key] = display;
          return display;
        }
      }
    } catch (_) {
      // Fallback to coordinates
    }
    return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
  }

  Future<Map<String, String>> _getHeaders({
    String? accountId,
    String? traceId,
    String? userId,
  }) async {
    final token = await AuthService().getAccessToken();
    final resolvedAccountId = accountId ?? PreferencesService().getAccountId();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      'user-id': userId != null && userId.isNotEmpty ? userId : _userId,
      if (resolvedAccountId != null && resolvedAccountId.isNotEmpty)
        'account-id': resolvedAccountId,
      if (traceId != null && traceId.isNotEmpty) 'trace-id': traceId,
    };
  }

  String _buildTraceId() {
    return 'trace-${DateTime.now().microsecondsSinceEpoch}';
  }

  Future<http.Response> _sendWithAuthRetry({
    required String method,
    required Uri uri,
    String? accountId,
    String? traceId,
    String? userId,
    Object? body,
    bool retryOnUnauthorized = true,
  }) async {
    final headers = await _getHeaders(
      accountId: accountId,
      traceId: traceId,
      userId: userId,
    );

    late final http.Response response;
    switch (method.toUpperCase()) {
      case 'GET':
        response = await http.get(uri, headers: headers);
        break;
      case 'POST':
        response = await http.post(uri, headers: headers, body: body);
        break;
      case 'PATCH':
        response = await http.patch(uri, headers: headers, body: body);
        break;
      case 'DELETE':
        response = await http.delete(uri, headers: headers, body: body);
        break;
      case 'PUT':
        response = await http.put(uri, headers: headers, body: body);
        break;
      default:
        throw Exception('Unsupported HTTP method: $method');
    }

    if (response.statusCode == 401 && retryOnUnauthorized) {
      final refreshed = await AuthService().refreshTokens();
      if (!refreshed) {
        return response;
      }

      return _sendWithAuthRetry(
        method: method,
        uri: uri,
        accountId: accountId,
        traceId: traceId,
        userId: userId,
        body: body,
        retryOnUnauthorized: false,
      );
    }

    return response;
  }

  ApiException _buildApiException({
    required String fallbackMessage,
    required http.Response response,
  }) {
    String message = fallbackMessage;
    String? trace;
    String? debug;

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final description = decoded['description']?.toString().trim();
        final apiMessage = decoded['message']?.toString().trim();
        trace = decoded['trace']?.toString();
        debug = decoded['debug']?.toString();

        if (description != null && description.isNotEmpty) {
          message = description;
        } else if (apiMessage != null && apiMessage.isNotEmpty) {
          message = apiMessage;
        }
      }
    } catch (_) {
      final body = response.body.trim();
      if (body.isNotEmpty) {
        message = body;
      }
    }

    return ApiException(
      message: message,
      statusCode: response.statusCode,
      trace: trace,
      debug: debug,
    );
  }

  /// Get user accounts (worker and contractor profiles for the authenticated user)
  Future<UserAccounts> getUserAccounts() async {
    try {
      final response = await _sendWithAuthRetry(
        method: 'GET',
        uri: Uri.parse('$_gatewayUrl$_managementPath/user/accounts'),
      );

      if (response.statusCode != 200) {
        throw _buildApiException(
          fallbackMessage: 'Failed to load user accounts',
          response: response,
        );
      }

      return UserAccounts.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } catch (e) {
      print('Error fetching user accounts: $e');
      rethrow;
    }
  }

  /// Get all categories
  Future<List<Category>> getCategories({String? accountId}) async {
    try {
      final response = await _sendWithAuthRetry(
        method: 'GET',
        uri: Uri.parse('$_gatewayUrl$_managementPath/categories'),
        accountId: accountId,
      );

      if (response.statusCode != 200) {
        throw _buildApiException(
          fallbackMessage: 'Failed to load categories',
          response: response,
        );
      }

      final List<dynamic> data = jsonDecode(response.body) ?? [];
      return data
          .map((json) => Category.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching categories: $e');
      rethrow;
    }
  }

  /// Update worker by ID
  Future<Worker> updateWorker({
    required String workerId,
    required String accountId,
    required String workerName,
    required String email,
    required String phoneNumber,
    required List<String> workerCategories,
    String? photoBase64,
  }) async {
    try {
      final normalizedEmail = email.trim();
      final payload = {
        'workerCategories': workerCategories,
        if (normalizedEmail.isNotEmpty) 'email': normalizedEmail,
        'phoneNumber': phoneNumber,
        if (photoBase64 != null && photoBase64.isNotEmpty)
          'profilePicture': photoBase64,
      };

      final response = await _sendWithAuthRetry(
        method: 'PATCH',
        uri: Uri.parse('$_gatewayUrl$_managementPath/workers/$workerId'),
        accountId: accountId,
        traceId: _buildTraceId(),
        userId: workerId,
        body: jsonEncode(payload),
      );

      if (response.statusCode != 200 &&
          response.statusCode != 201 &&
          response.statusCode != 202 &&
          response.statusCode != 204) {
        throw _buildApiException(
          fallbackMessage: 'Failed to update worker',
          response: response,
        );
      }

      if (response.body.isEmpty) {
        final refreshed = await getWorker(workerId, accountId: accountId);
        return refreshed ??
            Worker(
              id: workerId,
              workerName: workerName,
              email: normalizedEmail,
              phoneNumber: phoneNumber,
              workerCategories: workerCategories,
              accountId: accountId,
            );
      }

      return Worker.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } catch (e) {
      print('Error updating worker: $e');
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
      final response = await _sendWithAuthRetry(
        method: 'POST',
        uri: Uri.parse(
          '$_gatewayUrl$_managementPath/worker/$workerId/availability',
        ),
        accountId: accountId,
        traceId: _buildTraceId(),
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw _buildApiException(
          fallbackMessage: 'Failed to create worker availability',
          response: response,
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

  /// Delete worker availability window
  Future<void> deleteWorkerAvailability({
    required String workerId,
    required String availabilityId,
    required String accountId,
  }) async {
    try {
      final response = await _sendWithAuthRetry(
        method: 'DELETE',
        uri: Uri.parse(
          '$_gatewayUrl$_managementPath/worker/$workerId/availability/$availabilityId',
        ),
        accountId: accountId,
        traceId: _buildTraceId(),
      );

      if (response.statusCode != 200 &&
          response.statusCode != 204 &&
          response.statusCode != 202) {
        throw _buildApiException(
          fallbackMessage: 'Failed to delete worker availability',
          response: response,
        );
      }
    } catch (e) {
      print('Error deleting worker availability: $e');
      rethrow;
    }
  }

  /// Get worker availability windows
  Future<WorkerAvailabilityResponse> getWorkerAvailabilities({
    required String workerId,
    String? accountId,
  }) async {
    try {
      final response = await _sendWithAuthRetry(
        method: 'GET',
        uri: Uri.parse(
          '$_gatewayUrl$_managementPath/worker/$workerId/availability',
        ),
        accountId: accountId,
        traceId: _buildTraceId(),
      );

      if (response.statusCode != 200) {
        throw _buildApiException(
          fallbackMessage: 'Failed to load worker availabilities',
          response: response,
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
              .map(
                (item) =>
                    WorkerAvailability.fromJson(item as Map<String, dynamic>),
              )
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
      final response = await _sendWithAuthRetry(
        method: 'GET',
        uri: Uri.parse(
          '$_gatewayUrl$_managementPath/jobs/worker/$workerId/suggestions',
        ),
        accountId: accountId,
        traceId: _buildTraceId(),
        userId: workerId,
      );

      if (response.statusCode != 200) {
        throw _buildApiException(
          fallbackMessage: 'Failed to load worker job suggestions',
          response: response,
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

  /// Get images for a job via contractor endpoint
  Future<ImagesResponse> getContractorJobImages({
    required String contractorId,
    required String jobId,
    required String accountId,
  }) async {
    try {
      final response = await _sendWithAuthRetry(
        method: 'GET',
        uri: Uri.parse(
          '$_gatewayUrl$_managementPath/contractor/$contractorId/job/$jobId/images',
        ),
        accountId: accountId,
      );

      if (response.statusCode == 404) {
        return ImagesResponse(images: []);
      }

      if (response.statusCode != 200) {
        throw _buildApiException(
          fallbackMessage: 'Failed to load contractor job images',
          response: response,
        );
      }

      if (response.body.isEmpty) {
        return ImagesResponse(images: []);
      }

      return ImagesResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } catch (e) {
      print('Error fetching contractor job images: $e');
      rethrow;
    }
  }

  /// Get images for a job
  Future<ImagesResponse> getJobImages({
    required String jobId,
    required String accountId,
  }) async {
    try {
      final response = await _sendWithAuthRetry(
        method: 'GET',
        uri: Uri.parse('$_gatewayUrl$_managementPath/job/$jobId/images'),
        accountId: accountId,
      );

      if (response.statusCode == 404) {
        return ImagesResponse(images: []);
      }

      if (response.statusCode != 200) {
        throw _buildApiException(
          fallbackMessage: 'Failed to load job images',
          response: response,
        );
      }

      if (response.body.isEmpty) {
        return ImagesResponse(images: []);
      }

      return ImagesResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } catch (e) {
      print('Error fetching job images: $e');
      rethrow;
    }
  }

  /// Get worker profile picture
  Future<ImageItem?> getWorkerProfilePicture({
    required String workerId,
    String? accountId,
  }) async {
    try {
      final response = await _sendWithAuthRetry(
        method: 'GET',
        uri: Uri.parse(
          '$_gatewayUrl$_managementPath/workers/$workerId/profile-picture',
        ),
        accountId: accountId,
      );

      if (response.statusCode == 404) return null;
      if (response.statusCode != 200) {
        throw _buildApiException(
          fallbackMessage: 'Failed to load worker profile picture',
          response: response,
        );
      }

      if (response.body.isEmpty) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return ImageItem.fromJson(data);
    } catch (e) {
      print('Error fetching worker profile picture: $e');
      rethrow;
    }
  }

  /// Get contractor profile picture
  Future<ImageItem?> getContractorProfilePicture({
    required String contractorId,
    String? accountId,
  }) async {
    try {
      final response = await _sendWithAuthRetry(
        method: 'GET',
        uri: Uri.parse(
          '$_gatewayUrl$_managementPath/contractors/$contractorId/profile-picture',
        ),
        accountId: accountId,
      );

      if (response.statusCode == 404) return null;
      if (response.statusCode != 200) {
        throw _buildApiException(
          fallbackMessage: 'Failed to load contractor profile picture',
          response: response,
        );
      }

      if (response.body.isEmpty) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return ImageItem.fromJson(data);
    } catch (e) {
      print('Error fetching contractor profile picture: $e');
      rethrow;
    }
  }

  /// Get assigned jobs for a worker
  Future<List<WorkerAssignedJob>> getWorkerAssignedJobs({
    required String workerId,
    String? accountId,
  }) async {
    try {
      final response = await _sendWithAuthRetry(
        method: 'GET',
        uri: Uri.parse(
          '$_gatewayUrl$_managementPath/jobs/worker/$workerId/assigned',
        ),
        accountId: accountId,
        traceId: _buildTraceId(),
        userId: workerId,
      );

      if (response.statusCode != 200) {
        throw _buildApiException(
          fallbackMessage: 'Failed to load worker assigned jobs',
          response: response,
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
        final jobs =
            data['assignedJobs'] ?? data['jobs'] ?? data['pendingJobs'];
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

  /// Get job history for a worker
  Future<List<WorkerAssignedJob>> getWorkerJobHistory({
    required String workerId,
    String? accountId,
  }) async {
    try {
      final response = await _sendWithAuthRetry(
        method: 'GET',
        uri: Uri.parse(
          '$_gatewayUrl$_managementPath/jobs/worker/$workerId/history',
        ),
        accountId: accountId,
        traceId: _buildTraceId(),
        userId: workerId,
      );

      if (response.statusCode != 200) {
        throw _buildApiException(
          fallbackMessage: 'Failed to load worker job history',
          response: response,
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
        final jobs = data['historyJobs'] ?? data['jobs'] ?? data['history'];
        if (jobs is List<dynamic>) {
          return jobs
              .whereType<Map<String, dynamic>>()
              .map(WorkerAssignedJob.fromJson)
              .toList();
        }
      }

      return const [];
    } catch (e) {
      print('Error fetching worker job history: $e');
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
    final response = await _sendWithAuthRetry(
      method: 'PATCH',
      uri: Uri.parse(
        '$_gatewayUrl$_managementPath/worker/$workerId/job/$jobId/$action',
      ),
      accountId: accountId,
      traceId: _buildTraceId(),
      userId: workerId,
    );

    if (response.statusCode != 200 &&
        response.statusCode != 202 &&
        response.statusCode != 204) {
      throw _buildApiException(
        fallbackMessage: 'Failed to update worker job status',
        response: response,
      );
    }
  }

  /// Create a user account with both worker and contractor profiles.
  Future<UserAccounts> createUserAccount({
    required String name,
    required String email,
    required String phoneNumber,
    required List<String> workerCategories,
    String? photoBase64,
  }) async {
    try {
      final payload = {
        'name': name,
        'email': email,
        'phoneNumber': phoneNumber,
        'workerCategories': workerCategories,
        if (photoBase64 != null && photoBase64.isNotEmpty)
          'profilePicture': photoBase64,
      };

      final response = await _sendWithAuthRetry(
        method: 'POST',
        uri: Uri.parse('$_gatewayUrl$_managementPath/user/accounts'),
        traceId: _buildTraceId(),
        body: jsonEncode(payload),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw _buildApiException(
          fallbackMessage: 'Failed to create user account',
          response: response,
        );
      }

      return UserAccounts.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } catch (e) {
      print('Error creating user account: $e');
      rethrow;
    }
  }

  /// Upload or replace the profile picture for the active user account.
  Future<void> uploadUserProfilePicture({
    required String accountId,
    required String photoBase64,
  }) async {
    try {
      final payload = {'profilePicture': photoBase64};

      final response = await _sendWithAuthRetry(
        method: 'PATCH',
        uri: Uri.parse(
          '$_gatewayUrl$_managementPath/user/accounts/profile-picture',
        ),
        accountId: accountId,
        traceId: _buildTraceId(),
        body: jsonEncode(payload),
      );

      if (response.statusCode != 200 &&
          response.statusCode != 201 &&
          response.statusCode != 202 &&
          response.statusCode != 204) {
        throw _buildApiException(
          fallbackMessage: 'Failed to upload profile picture',
          response: response,
        );
      }
    } catch (e) {
      print('Error uploading profile picture: $e');
      rethrow;
    }
  }

  /// Update contractor by ID
  Future<Contractor> updateContractor({
    required String contractorId,
    required String accountId,
    required String contractorName,
    required String contractorType,
    required String email,
    required String phoneNumber,
    String? photoBase64,
  }) async {
    try {
      final normalizedEmail = email.trim();
      final payload = {
        if (normalizedEmail.isNotEmpty) 'email': normalizedEmail,
        'phoneNumber': phoneNumber,
        if (photoBase64 != null && photoBase64.isNotEmpty)
          'profilePicture': photoBase64,
      };

      final response = await _sendWithAuthRetry(
        method: 'PATCH',
        uri: Uri.parse('$_gatewayUrl$_managementPath/contractor/$contractorId'),
        accountId: accountId,
        traceId: _buildTraceId(),
        userId: contractorId,
        body: jsonEncode(payload),
      );

      if (response.statusCode != 200 &&
          response.statusCode != 201 &&
          response.statusCode != 202 &&
          response.statusCode != 204) {
        throw _buildApiException(
          fallbackMessage: 'Failed to update contractor',
          response: response,
        );
      }

      if (response.body.isEmpty) {
        final refreshed = await getContractor(
          contractorId,
          accountId: accountId,
        );

        return refreshed ??
            Contractor(
              id: contractorId,
              contractorName: contractorName,
              contractorType: contractorType,
              email: normalizedEmail,
              phoneNumber: phoneNumber,
              accountId: accountId,
            );
      }

      return Contractor.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } catch (e) {
      print('Error updating contractor: $e');
      rethrow;
    }
  }

  /// Get single worker by ID
  Future<Worker?> getWorker(String workerId, {String? accountId}) async {
    try {
      final response = await _sendWithAuthRetry(
        method: 'GET',
        uri: Uri.parse('$_gatewayUrl$_managementPath/workers/$workerId'),
        accountId: accountId,
        traceId: _buildTraceId(),
      );

      if (response.statusCode == 404) {
        return null;
      }

      if (response.statusCode != 200) {
        throw _buildApiException(
          fallbackMessage: 'Failed to load worker',
          response: response,
        );
      }

      return Worker.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } catch (e) {
      print('Error fetching worker: $e');
      rethrow;
    }
  }

  /// Get single contractor by ID
  Future<Contractor?> getContractor(
    String contractorId, {
    String? accountId,
  }) async {
    try {
      final response = await _sendWithAuthRetry(
        method: 'GET',
        uri: Uri.parse(
          '$_gatewayUrl$_managementPath/contractors/$contractorId',
        ),
        accountId: accountId,
        traceId: _buildTraceId(),
      );

      if (response.statusCode == 404) {
        return null;
      }

      if (response.statusCode != 200) {
        throw _buildApiException(
          fallbackMessage: 'Failed to load contractor',
          response: response,
        );
      }

      return Contractor.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } catch (e) {
      print('Error fetching contractor: $e');
      rethrow;
    }
  }

  /// Get all wallets from payment engine
  Future<List<Wallet>> getWallets({String? accountId}) async {
    try {
      final response = await _sendWithAuthRetry(
        method: 'GET',
        uri: Uri.parse('$_gatewayUrl$_paymentPath/wallets'),
        accountId: accountId,
      );

      if (response.statusCode != 200) {
        throw _buildApiException(
          fallbackMessage: 'Failed to load wallets',
          response: response,
        );
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

      return walletList
          .map((json) => Wallet.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching wallets: $e');
      rethrow;
    }
  }

  /// Get active processes for a contractor
  Future<List<ContractorProcessSummary>> getActiveContractorProcesses({
    required String contractorId,
    String? accountId,
  }) async {
    return _fetchContractorProcesses(
      contractorId: contractorId,
      accountId: accountId,
      path: 'active',
    );
  }

  /// Get history processes for a contractor
  Future<List<ContractorProcessSummary>> getHistoryContractorProcesses({
    required String contractorId,
    String? accountId,
  }) async {
    return _fetchContractorProcesses(
      contractorId: contractorId,
      accountId: accountId,
      path: 'history',
    );
  }

  Future<List<ContractorProcessSummary>> _fetchContractorProcesses({
    required String contractorId,
    required String path,
    String? accountId,
  }) async {
    try {
      final response = await _sendWithAuthRetry(
        method: 'GET',
        uri: Uri.parse(
          '$_gatewayUrl$_managementPath/contractor/$contractorId/processes/$path',
        ),
        accountId: accountId,
        traceId: _buildTraceId(),
      );

      if (response.statusCode == 404) {
        return [];
      }

      if (response.statusCode != 200) {
        throw _buildApiException(
          fallbackMessage: 'Failed to load contractor processes ($path)',
          response: response,
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
      print('Error fetching contractor processes ($path): $e');
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
      final response = await _sendWithAuthRetry(
        method: 'POST',
        uri: Uri.parse(
          '$_gatewayUrl$_managementPath/contractor/$contractorId/processes',
        ),
        accountId: accountId,
        traceId: _buildTraceId(),
        body: jsonEncode(processRequest.toJson()),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw _buildApiException(
          fallbackMessage: 'Failed to create process',
          response: response,
        );
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      print('Error creating contractor process: $e');
      rethrow;
    }
  }

  /// Delete a contractor process
  Future<void> deleteContractorProcess({
    required String contractorId,
    required String processId,
    required String accountId,
  }) async {
    try {
      final response = await _sendWithAuthRetry(
        method: 'DELETE',
        uri: Uri.parse(
          '$_gatewayUrl$_managementPath/contractor/$contractorId/processes/$processId',
        ),
        accountId: accountId,
        traceId: _buildTraceId(),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw _buildApiException(
          fallbackMessage: 'Failed to delete process',
          response: response,
        );
      }
    } catch (e) {
      print('Error deleting contractor process: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Payment Card API stubs (to be implemented when payment service is ready)
  // ---------------------------------------------------------------------------

  /// Get payment cards for an account
  Future<List<Map<String, dynamic>>> getPaymentCards({
    required String accountId,
  }) async {
    try {
      final response = await _sendWithAuthRetry(
        method: 'GET',
        uri: Uri.parse('$_gatewayUrl$_paymentPath/accounts/$accountId/cards'),
        accountId: accountId,
      );

      if (response.statusCode != 200) {
        // Payment service may not be running yet – return empty list
        return [];
      }

      final data = jsonDecode(response.body);
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      } else if (data is Map<String, dynamic>) {
        return (data['cards'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      }
      return [];
    } catch (e) {
      // Payment service not available yet – return empty list gracefully
      print('Payment cards not available: $e');
      return [];
    }
  }

  /// Add a payment card to an account
  Future<Map<String, dynamic>> addPaymentCard({
    required String accountId,
    required String cardHolder,
    required String cardNumber,
    required String expiry,
  }) async {
    try {
      final response = await _sendWithAuthRetry(
        method: 'POST',
        uri: Uri.parse('$_gatewayUrl$_paymentPath/accounts/$accountId/cards'),
        accountId: accountId,
        body: jsonEncode({
          'cardHolder': cardHolder,
          'cardNumber': cardNumber,
          'expiry': expiry,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw _buildApiException(
          fallbackMessage: 'Failed to add payment card',
          response: response,
        );
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      print('Error adding payment card: $e');
      rethrow;
    }
  }

  /// Delete a payment card
  Future<void> deletePaymentCard({
    required String accountId,
    required String cardId,
  }) async {
    try {
      final response = await _sendWithAuthRetry(
        method: 'DELETE',
        uri: Uri.parse(
          '$_gatewayUrl$_paymentPath/accounts/$accountId/cards/$cardId',
        ),
        accountId: accountId,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw _buildApiException(
          fallbackMessage: 'Failed to delete payment card',
          response: response,
        );
      }
    } catch (e) {
      print('Error deleting payment card: $e');
      rethrow;
    }
  }
}
