import 'package:flutter/material.dart';
import '../models/contractor.dart';
import '../services/api_service.dart';

class ContractorProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Contractor> _contractors = [];
  bool _isLoading = false;
  String? _error;

  List<Contractor> get contractors => _contractors;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch all contractors
  Future<void> fetchContractors() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _contractors = await _apiService.getContractors();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _contractors = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new contractor
  Future<Map<String, dynamic>> createContractor({
    required String contractorName,
    required String contractorType,
    required String email,
    required String phoneNumber,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.createContractor(
        contractorName: contractorName,
        contractorType: contractorType,
        email: email,
        phoneNumber: phoneNumber,
      );
      _error = null;
      await fetchContractors(); // Refresh the list
      return result;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get a single contractor
  Future<Contractor?> getContractor(String contractorId) async {
    try {
      return await _apiService.getContractor(contractorId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }
}
