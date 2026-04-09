import 'package:shared_preferences/shared_preferences.dart';
import '../models/worker.dart';
import '../models/contractor.dart';

class PreferencesService {
  static final PreferencesService _instance = PreferencesService._internal();
  late SharedPreferences _prefs;

  // In-memory account data (populated from API, never persisted locally)
  String? _userId;
  Worker? _worker;
  Contractor? _contractor;

  factory PreferencesService() {
    return _instance;
  }

  PreferencesService._internal();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Only selected_type is persisted locally (UI preference)
  static const String _selectedTypeKey = 'selected_type';

  /// Load user accounts data from API response into memory.
  void loadUserAccounts({
    required String userId,
    Worker? worker,
    Contractor? contractor,
  }) {
    _userId = userId;
    _worker = worker;
    _contractor = contractor;
  }

  /// Update worker data in memory (e.g., after creating a new worker).
  void setWorkerData(Worker worker) {
    _worker = worker;
  }

  /// Update contractor data in memory (e.g., after creating a new contractor).
  void setContractorData(Contractor contractor) {
    _contractor = contractor;
  }

  // User ID
  String? getUserId() => _userId;

  // Account ID (returns active account based on selected type)
  String? getAccountId() {
    final selectedType = getSelectedType();
    if (selectedType == 'WORKER') {
      return _worker?.accountId;
    } else if (selectedType == 'CONTRACTOR') {
      return _contractor?.accountId;
    }
    return _worker?.accountId ?? _contractor?.accountId;
  }

  // Worker ID
  String? getWorkerId() => _worker?.id;

  // Worker Account ID
  String? getWorkerAccountId() => _worker?.accountId;

  // Contractor ID
  String? getContractorId() => _contractor?.id;

  // Contractor Account ID
  String? getContractorAccountId() => _contractor?.accountId;

  // Selected Type (WORKER or CONTRACTOR) - persisted locally as UI preference
  Future<void> setSelectedType(String type) async {
    await _prefs.setString(_selectedTypeKey, type);
  }

  String? getSelectedType() {
    return _prefs.getString(_selectedTypeKey);
  }

  // Worker Name
  String? getWorkerName() => _worker?.workerName;

  // Contractor Name
  String? getContractorName() => _contractor?.contractorName;

  // Active profile helpers
  Future<void> activateWorkerProfile() async {
    await setSelectedType('WORKER');
  }

  Future<void> activateContractorProfile() async {
    await setSelectedType('CONTRACTOR');
  }

  // Clear all
  Future<void> clearAll() async {
    _userId = null;
    _worker = null;
    _contractor = null;
    await _prefs.remove(_selectedTypeKey);
  }

  // Check if has profile
  bool hasWorkerProfile() => _worker != null;

  bool hasContractorProfile() => _contractor != null;

  bool hasAnyProfile() => hasWorkerProfile() || hasContractorProfile();
}
