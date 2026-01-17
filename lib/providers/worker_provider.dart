import 'package:flutter/material.dart';
import '../models/worker.dart';
import '../services/api_service.dart';

class WorkerProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Worker> _workers = [];
  bool _isLoading = false;
  String? _error;
  List<Category> _categories = [];

  List<Worker> get workers => _workers;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Category> get categories => _categories;

  /// Fetch all workers
  Future<void> fetchWorkers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _workers = await _apiService.getWorkers();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _workers = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

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
      await fetchWorkers(); // Refresh the list
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
  Future<Worker?> getWorker(String workerId) async {
    try {
      return await _apiService.getWorker(workerId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }
}
