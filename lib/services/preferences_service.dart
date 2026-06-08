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

  static const String _selectedTypeKey = 'selected_type';
  static const String _workerPhotoKey = 'worker_photo_base64';
  static const String _contractorPhotoKey = 'contractor_photo_base64';

  /// Load user accounts data from API response into memory.
  void loadUserAccounts({
    required String userId,
    Worker? worker,
    Contractor? contractor,
  }) {
    _userId = userId;

    if (worker != null) {
      _worker = worker;
      if (worker.photoBase64 != null && worker.photoBase64!.isNotEmpty) {
        _prefs.setString(_workerPhotoKey, worker.photoBase64!);
      } else {
        _prefs.remove(_workerPhotoKey);
      }
    } else {
      _worker = null;
      _prefs.remove(_workerPhotoKey);
    }

    if (contractor != null) {
      _contractor = contractor;
      if (contractor.photoBase64 != null && contractor.photoBase64!.isNotEmpty) {
        _prefs.setString(_contractorPhotoKey, contractor.photoBase64!);
      } else {
        _prefs.remove(_contractorPhotoKey);
      }
    } else {
      _contractor = null;
      _prefs.remove(_contractorPhotoKey);
    }
  }

  void setWorkerData(Worker worker) {
    final mergedPhoto = worker.photoBase64 ?? _prefs.getString(_workerPhotoKey);
    _worker = worker.copyWith(photoBase64: mergedPhoto);
    if (mergedPhoto == null || mergedPhoto.isEmpty) {
      _prefs.remove(_workerPhotoKey);
    } else {
      _prefs.setString(_workerPhotoKey, mergedPhoto);
    }
  }

  void setContractorData(Contractor contractor) {
    final mergedPhoto =
        contractor.photoBase64 ?? _prefs.getString(_contractorPhotoKey);
    _contractor = contractor.copyWith(photoBase64: mergedPhoto);
    if (mergedPhoto == null || mergedPhoto.isEmpty) {
      _prefs.remove(_contractorPhotoKey);
    } else {
      _prefs.setString(_contractorPhotoKey, mergedPhoto);
    }
  }

  String? getWorkerPhotoBase64() {
    return _worker?.photoBase64 ?? _prefs.getString(_workerPhotoKey);
  }

  String? getContractorPhotoBase64() {
    return _contractor?.photoBase64 ?? _prefs.getString(_contractorPhotoKey);
  }

  String? getUserId() => _userId;

  String? getAccountId() {
    final selectedType = getSelectedType();
    if (selectedType == 'WORKER') {
      return _worker?.accountId;
    } else if (selectedType == 'CONTRACTOR') {
      return _contractor?.accountId;
    }
    return _worker?.accountId ?? _contractor?.accountId;
  }

  String? getWorkerId() => _worker?.id;

  String? getWorkerAccountId() => _worker?.accountId;

  String? getContractorId() => _contractor?.id;

  String? getContractorAccountId() => _contractor?.accountId;

  Future<void> setSelectedType(String type) async {
    await _prefs.setString(_selectedTypeKey, type);
  }

  String? getSelectedType() {
    return _prefs.getString(_selectedTypeKey);
  }

  String? getWorkerName() => _worker?.workerName;

  String? getContractorName() => _contractor?.contractorName;

  Future<void> activateWorkerProfile() async {
    await setSelectedType('WORKER');
  }

  Future<void> activateContractorProfile() async {
    await setSelectedType('CONTRACTOR');
  }

  Future<void> clearAll() async {
    _userId = null;
    _worker = null;
    _contractor = null;
    await _prefs.remove(_selectedTypeKey);
    await _prefs.remove(_workerPhotoKey);
    await _prefs.remove(_contractorPhotoKey);
  }

  bool hasWorkerProfile() => _worker != null;

  bool hasContractorProfile() => _contractor != null;

  bool hasAnyProfile() => hasWorkerProfile() || hasContractorProfile();
}
