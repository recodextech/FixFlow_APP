import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static final PreferencesService _instance = PreferencesService._internal();
  late SharedPreferences _prefs;

  factory PreferencesService() {
    return _instance;
  }

  PreferencesService._internal();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Keys
  static const String _accountIdKey = 'account_id';
  static const String _workerIdKey = 'worker_id';
  static const String _contractorIdKey = 'contractor_id';
  static const String _selectedTypeKey = 'selected_type'; // 'WORKER' or 'CONTRACTOR'
  static const String _workerNameKey = 'worker_name';
  static const String _contractorNameKey = 'contractor_name';

  // Account ID
  Future<void> setAccountId(String accountId) async {
    await _prefs.setString(_accountIdKey, accountId);
  }

  String? getAccountId() {
    return _prefs.getString(_accountIdKey);
  }

  // Worker ID
  Future<void> setWorkerId(String workerId) async {
    await _prefs.setString(_workerIdKey, workerId);
  }

  String? getWorkerId() {
    return _prefs.getString(_workerIdKey);
  }

  // Contractor ID
  Future<void> setContractorId(String contractorId) async {
    await _prefs.setString(_contractorIdKey, contractorId);
  }

  String? getContractorId() {
    return _prefs.getString(_contractorIdKey);
  }

  // Selected Type (WORKER or CONTRACTOR)
  Future<void> setSelectedType(String type) async {
    await _prefs.setString(_selectedTypeKey, type);
  }

  String? getSelectedType() {
    return _prefs.getString(_selectedTypeKey);
  }

  // Worker Name
  Future<void> setWorkerName(String name) async {
    await _prefs.setString(_workerNameKey, name);
  }

  String? getWorkerName() {
    return _prefs.getString(_workerNameKey);
  }

  // Contractor Name
  Future<void> setContractorName(String name) async {
    await _prefs.setString(_contractorNameKey, name);
  }

  String? getContractorName() {
    return _prefs.getString(_contractorNameKey);
  }

  // Clear all
  Future<void> clearAll() async {
    await _prefs.remove(_accountIdKey);
    await _prefs.remove(_workerIdKey);
    await _prefs.remove(_contractorIdKey);
    await _prefs.remove(_selectedTypeKey);
    await _prefs.remove(_workerNameKey);
    await _prefs.remove(_contractorNameKey);
  }

  // Clear worker data
  Future<void> clearWorkerData() async {
    await _prefs.remove(_workerIdKey);
    await _prefs.remove(_accountIdKey);
    await _prefs.remove(_workerNameKey);
  }

  // Clear contractor data
  Future<void> clearContractorData() async {
    await _prefs.remove(_contractorIdKey);
    await _prefs.remove(_accountIdKey);
    await _prefs.remove(_contractorNameKey);
  }

  // Check if has profile
  bool hasWorkerProfile() {
    return getWorkerId() != null && getAccountId() != null;
  }

  bool hasContractorProfile() {
    return getContractorId() != null && getAccountId() != null;
  }

  bool hasAnyProfile() {
    return hasWorkerProfile() || hasContractorProfile();
  }
}
