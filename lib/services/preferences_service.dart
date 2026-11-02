import 'dart:math';

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
  String? _workerPhoto;
  String? _contractorPhoto;

  factory PreferencesService() {
    return _instance;
  }

  PreferencesService._internal();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    // Older builds persisted profile photos here; Android loads this whole
    // file before the first frame, so drop them (they are refetched anyway).
    if (_prefs.containsKey(_legacyWorkerPhotoKey) ||
        _prefs.containsKey(_legacyContractorPhotoKey)) {
      await Future.wait([
        _prefs.remove(_legacyWorkerPhotoKey),
        _prefs.remove(_legacyContractorPhotoKey),
      ]);
    }
  }

  static const String _selectedTypeKey = 'selected_type';
  static const String _legacyWorkerPhotoKey = 'worker_photo_base64';
  static const String _legacyContractorPhotoKey = 'contractor_photo_base64';
  static const String _deviceIdKey = 'device_id';
  static const String _languageKey = 'app_language';

  /// Load user accounts data from API response into memory.
  void loadUserAccounts({
    required String userId,
    Worker? worker,
    Contractor? contractor,
  }) {
    _userId = userId;

    _worker = worker;
    _workerPhoto = _nonEmpty(worker?.photoBase64);
    _contractor = contractor;
    _contractorPhoto = _nonEmpty(contractor?.photoBase64);
  }

  void setWorkerData(Worker worker) {
    _workerPhoto = _nonEmpty(worker.photoBase64) ?? _workerPhoto;
    _worker = worker.copyWith(photoBase64: _workerPhoto);
  }

  void setContractorData(Contractor contractor) {
    _contractorPhoto = _nonEmpty(contractor.photoBase64) ?? _contractorPhoto;
    _contractor = contractor.copyWith(photoBase64: _contractorPhoto);
  }

  String? getWorkerPhotoBase64() => _workerPhoto;

  String? getContractorPhotoBase64() => _contractorPhoto;

  void cacheWorkerPhoto(String base64) {
    if (base64.isEmpty) return;
    _workerPhoto = base64;
    _worker = _worker?.copyWith(photoBase64: base64);
  }

  void cacheContractorPhoto(String base64) {
    if (base64.isEmpty) return;
    _contractorPhoto = base64;
    _contractor = _contractor?.copyWith(photoBase64: base64);
  }

  static String? _nonEmpty(String? value) =>
      value == null || value.isEmpty ? null : value;

  String? getUserId() => _userId;

  Future<String> getOrCreateDeviceId() async {
    final existingId = _prefs.getString(_deviceIdKey);
    if (existingId != null && existingId.isNotEmpty) {
      return existingId;
    }

    final random = Random.secure();
    final deviceId = List.generate(
      32,
      (_) => random.nextInt(16).toRadixString(16),
    ).join();
    await _prefs.setString(_deviceIdKey, deviceId);
    return deviceId;
  }

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

  Future<void> setLanguage(String languageCode) async {
    await _prefs.setString(_languageKey, languageCode);
  }

  String getLanguage() {
    return _prefs.getString(_languageKey) ?? 'en';
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
    _workerPhoto = null;
    _contractorPhoto = null;
    await _prefs.remove(_selectedTypeKey);
    await _prefs.remove(_languageKey);
  }

  bool hasWorkerProfile() => _worker != null;

  bool hasContractorProfile() => _contractor != null;

  bool hasAnyProfile() => hasWorkerProfile() || hasContractorProfile();
}
