import 'package:flutter/material.dart';
import '../models/availability.dart';
import '../models/worker.dart';
import '../models/worker_assigned_job.dart';
import '../models/worker_job_suggestion.dart';
import '../services/api_service.dart';

class WorkerProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  bool _isLoading = false;
  String? _error;
  List<Category> _categories = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Category> get categories => _categories;

  /// Fetch categories
  Future<void> fetchCategories() async {
    try {
      _categories = await _apiService.getCategories();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Create a new worker
  Future<Map<String, dynamic>> createWorker({
    required String workerName,
    required String email,
    required String phoneNumber,
    required List<String> workerCategories,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.createWorker(
        workerName: workerName,
        email: email,
        phoneNumber: phoneNumber,
        workerCategories: workerCategories,
      );
      _error = null;
      return result;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get a single worker
  Future<Worker?> getWorker(String workerId, {String? accountId}) async {
    try {
      return await _apiService.getWorker(workerId, accountId: accountId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Create worker availability windows
  Future<Map<String, dynamic>> createWorkerAvailability({
    required String workerId,
    required String accountId,
    required WorkerAvailabilityRequest request,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.createWorkerAvailability(
        workerId: workerId,
        accountId: accountId,
        request: request,
      );
      _error = null;
      return result;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get worker availability windows
  Future<WorkerAvailabilityResponse> getWorkerAvailabilities({
    required String workerId,
    String? accountId,
  }) async {
    try {
      return await _apiService.getWorkerAvailabilities(
        workerId: workerId,
        accountId: accountId,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return WorkerAvailabilityResponse(availabilities: [], total: 0);
    }
  }

  /// Get suggested jobs for worker
  Future<WorkerJobSuggestionResponse> getWorkerJobSuggestions({
    required String workerId,
    String? accountId,
  }) async {
    try {
      return await _apiService.getWorkerJobSuggestions(
        workerId: workerId,
        accountId: accountId,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return const WorkerJobSuggestionResponse(availableJobs: []);
    }
  }

  /// Get assigned jobs for worker
  Future<List<WorkerAssignedJob>> getWorkerAssignedJobs({
    required String workerId,
    String? accountId,
  }) async {
    try {
      return await _apiService.getWorkerAssignedJobs(
        workerId: workerId,
        accountId: accountId,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return const [];
    }
  }

  /// Accept worker job
  Future<void> acceptWorkerJob({
    required String workerId,
    required String jobId,
    required String accountId,
  }) async {
    await _apiService.acceptWorkerJob(
      workerId: workerId,
      jobId: jobId,
      accountId: accountId,
    );
  }

  /// Start worker job
  Future<void> startWorkerJob({
    required String workerId,
    required String jobId,
    required String accountId,
  }) async {
    await _apiService.startWorkerJob(
      workerId: workerId,
      jobId: jobId,
      accountId: accountId,
    );
  }

  /// Mark worker job as success
  Future<void> completeWorkerJobSuccess({
    required String workerId,
    required String jobId,
    required String accountId,
  }) async {
    await _apiService.completeWorkerJobSuccess(
      workerId: workerId,
      jobId: jobId,
      accountId: accountId,
    );
  }
}
