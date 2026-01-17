import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/worker.dart';
import '../models/contractor.dart';

class ApiService {
  // Base URLs - can be configured via environment
  static const String _baseUrl = 'http://localhost:8888';
  static const String _managementUrl = 'http://localhost:8090';
  static const String _userId = 'flutter-client';

  static final ApiService _instance = ApiService._internal();

  factory ApiService() {
    return _instance;
  }

  ApiService._internal();

  Map<String, String> _getHeaders({String? accountId}) {
    return {
      'Content-Type': 'application/json',
      'user-id': _userId,
      'Accept': 'application/json',
      if (accountId != null) 'account-id': accountId,
    };
  }

  /// Get all categories
  Future<List<Category>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$_managementUrl/categories'),
        headers: _getHeaders(),
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

  /// Get all workers
  Future<List<Worker>> getWorkers() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/workers'),
        headers: _getHeaders(),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load workers: ${response.statusCode}');
      }

      final List<dynamic> data = jsonDecode(response.body) ?? [];
      return data.map((json) => Worker.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Error fetching workers: $e');
      rethrow;
    }
  }

  /// Get all contractors
  Future<List<Contractor>> getContractors() async {
    try {
      final response = await http.get(
        Uri.parse('$_managementUrl/contractors'),
        headers: _getHeaders(),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load contractors: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      final List<dynamic> contractors = data['contractors'] ?? [];
      return contractors.map((json) => Contractor.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Error fetching contractors: $e');
      rethrow;
    }
  }

  /// Get single worker by ID
  Future<Worker?> getWorker(String workerId) async {
    try {
      final response = await http.get(
        Uri.parse('$_managementUrl/workers/$workerId'),
        headers: _getHeaders(),
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
  Future<Contractor?> getContractor(String contractorId) async {
    try {
      final response = await http.get(
        Uri.parse('$_managementUrl/contractors/$contractorId'),
        headers: _getHeaders(),
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
}
