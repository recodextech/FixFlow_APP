import 'package:flutter/material.dart';
import '../models/contractor.dart';
import '../services/api_service.dart';

class ContractorProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

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
      return result;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update an existing contractor
  Future<Contractor> updateContractor({
    required String contractorId,
    required String accountId,
    required String contractorName,
    required String contractorType,
    required String email,
    required String phoneNumber,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.updateContractor(
        contractorId: contractorId,
        accountId: accountId,
        contractorName: contractorName,
        contractorType: contractorType,
        email: email,
        phoneNumber: phoneNumber,
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

  /// Get a single contractor
  Future<Contractor?> getContractor(String contractorId, {String? accountId}) async {
    try {
      return await _apiService.getContractor(
        contractorId,
        accountId: accountId,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }
}
