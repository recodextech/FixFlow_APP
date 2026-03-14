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
  static const String _selectedTypeKey =
      'selected_type'; // 'WORKER' or 'CONTRACTOR'
  static const String _workerNameKey = 'worker_name';
  static const String _contractorNameKey = 'contractor_name';
  static const String _workerAccountIdKey = 'worker_account_id';
  static const String _contractorAccountIdKey = 'contractor_account_id';

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

  // Worker Account ID
  Future<void> setWorkerAccountId(String accountId) async {
    await _prefs.setString(_workerAccountIdKey, accountId);
  }

  String? getWorkerAccountId() {
    final workerAccountId = _prefs.getString(_workerAccountIdKey);
    if (workerAccountId != null && workerAccountId.isNotEmpty) {
      return workerAccountId;
    }

    final selectedType = getSelectedType();
    if (selectedType == 'WORKER') {
      return getAccountId();
    }

    return null;
  }

  // Contractor ID
  Future<void> setContractorId(String contractorId) async {
    await _prefs.setString(_contractorIdKey, contractorId);
  }

  String? getContractorId() {
    return _prefs.getString(_contractorIdKey);
  }

  // Contractor Account ID
  Future<void> setContractorAccountId(String accountId) async {
    await _prefs.setString(_contractorAccountIdKey, accountId);
  }

  String? getContractorAccountId() {
    final contractorAccountId = _prefs.getString(_contractorAccountIdKey);
    if (contractorAccountId != null && contractorAccountId.isNotEmpty) {
      return contractorAccountId;
    }

    final selectedType = getSelectedType();
    if (selectedType == 'CONTRACTOR') {
      return getAccountId();
    }

    return null;
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

  // Active profile helpers
  Future<void> activateWorkerProfile() async {
    final workerAccountId = getWorkerAccountId() ?? getAccountId();
    if (workerAccountId != null && workerAccountId.isNotEmpty) {
      await setAccountId(workerAccountId);
    }
    await setSelectedType('WORKER');
  }

  Future<void> activateContractorProfile() async {
    final contractorAccountId = getContractorAccountId() ?? getAccountId();
    if (contractorAccountId != null && contractorAccountId.isNotEmpty) {
      await setAccountId(contractorAccountId);
    }
    await setSelectedType('CONTRACTOR');
  }

  // Clear all
  Future<void> clearAll() async {
    await _prefs.remove(_accountIdKey);
    await _prefs.remove(_workerIdKey);
    await _prefs.remove(_contractorIdKey);
    await _prefs.remove(_selectedTypeKey);
    await _prefs.remove(_workerNameKey);
    await _prefs.remove(_contractorNameKey);
    await _prefs.remove(_workerAccountIdKey);
    await _prefs.remove(_contractorAccountIdKey);
  }

  // Clear worker data
  Future<void> clearWorkerData() async {
    await _prefs.remove(_workerIdKey);
    await _prefs.remove(_workerNameKey);
    await _prefs.remove(_workerAccountIdKey);

    if (getSelectedType() == 'WORKER') {
      if (hasContractorProfile()) {
        await activateContractorProfile();
      } else {
        await _prefs.remove(_accountIdKey);
        await _prefs.remove(_selectedTypeKey);
      }
    }
  }

  // Clear contractor data
  Future<void> clearContractorData() async {
    await _prefs.remove(_contractorIdKey);
    await _prefs.remove(_contractorNameKey);
    await _prefs.remove(_contractorAccountIdKey);

    if (getSelectedType() == 'CONTRACTOR') {
      if (hasWorkerProfile()) {
        await activateWorkerProfile();
      } else {
        await _prefs.remove(_accountIdKey);
        await _prefs.remove(_selectedTypeKey);
      }
    }
  }

  // Check if has profile
  bool hasWorkerProfile() {
    final workerId = getWorkerId();
    if (workerId == null || workerId.isEmpty) {
      return false;
    }

    final workerAccountId = getWorkerAccountId();
    if (workerAccountId != null && workerAccountId.isNotEmpty) {
      return true;
    }

    final selectedType = getSelectedType();
    final accountId = getAccountId();
    return accountId != null &&
        (selectedType == null || selectedType == 'WORKER');
  }

  bool hasContractorProfile() {
    final contractorId = getContractorId();
    if (contractorId == null || contractorId.isEmpty) {
      return false;
    }

    final contractorAccountId = getContractorAccountId();
    if (contractorAccountId != null && contractorAccountId.isNotEmpty) {
      return true;
    }

    final selectedType = getSelectedType();
    final accountId = getAccountId();
    return accountId != null &&
        (selectedType == null || selectedType == 'CONTRACTOR');
  }

  bool hasAnyProfile() {
    return hasWorkerProfile() || hasContractorProfile();
  }
}
