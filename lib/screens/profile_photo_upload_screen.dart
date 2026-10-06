import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/language_provider.dart';
import '../services/api_service.dart';
import '../services/job_photo_upload.dart';
import '../services/preferences_service.dart';
import '../theme.dart';
import 'home_screen.dart';

class ProfilePhotoUploadScreen extends StatefulWidget {
  final String profileType;
  final String profileId;
  final String? accountId;
  final String? profileName;
  final String? email;
  final String? phoneNumber;
  final List<String>? workerCategories;
  final String? contractorType;

  const ProfilePhotoUploadScreen({
    super.key,
    required this.profileType,
    required this.profileId,
    this.accountId,
    this.profileName,
    this.email,
    this.phoneNumber,
    this.workerCategories,
    this.contractorType,
  });

  @override
  State<ProfilePhotoUploadScreen> createState() =>
      _ProfilePhotoUploadScreenState();
}

class _ProfilePhotoUploadScreenState extends State<ProfilePhotoUploadScreen> {
  Uint8List? _selectedPhotoBytes;
  bool _isUploading = false;

  Future<void> _showPhotoSourceSheet(AppLocalizations loc) async {
    if (!mounted) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text(loc.takePhoto),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(loc.chooseFromGallery),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    final bytes = await JobPhotoUpload.pickAndPrepare(source);
    if (!mounted || bytes == null) return;

    setState(() => _selectedPhotoBytes = bytes);
  }

  Future<void> _continueToProfile(AppLocalizations loc) async {
    final accountId = widget.accountId ?? PreferencesService().getAccountId();
    if (accountId == null || accountId.isEmpty) {
      _goToHome();
      return;
    }

    if (_selectedPhotoBytes == null) {
      _goToHome();
      return;
    }

    setState(() => _isUploading = true);

    try {
      final photoBase64 = JobPhotoUpload.toBase64(_selectedPhotoBytes!);

      await ApiService().uploadUserProfilePicture(
        accountId: accountId,
        photoBase64: photoBase64,
      );

      final accounts = await ApiService().getUserAccounts();
      PreferencesService().loadUserAccounts(
        userId: accounts.userId,
        worker: accounts.worker,
        contractor: accounts.contractor,
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(loc.profilePhotoUpdated)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${loc.failedToUploadPhoto}: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }

    if (mounted) {
      _goToHome();
    }
  }

  void _goToHome() {
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        final loc = AppLocalizations.of(languageProvider.locale);
        return _buildPhotoUploadUI(loc);
      },
    );
  }

  Widget _buildPhotoUploadUI(AppLocalizations loc) {
    final accentColor = AppColors.brandGreen;
    final accentPale = AppColors.brandPale;

    return Scaffold(
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppColors.brandGradient,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _goToHome,
                      child: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        loc.addProfilePhoto,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Text(
                    loc.profileReadyAddPhoto,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: AppColors.text2),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      color: accentPale,
                      shape: BoxShape.circle,
                      border: Border.all(color: accentColor, width: 2),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _selectedPhotoBytes == null
                        ? Icon(
                            Icons.person_outline,
                            size: 56,
                            color: accentColor,
                          )
                        : Image.memory(_selectedPhotoBytes!, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showPhotoSourceSheet(loc),
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: Text(loc.chooseProfilePhoto),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isUploading
                          ? null
                          : () => _continueToProfile(loc),
                      icon: const Icon(Icons.skip_next_outlined),
                      label: Text(loc.skipForNow),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.brandGreen,
                        side: const BorderSide(color: AppColors.brandGold),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isUploading
                          ? null
                          : () => _continueToProfile(loc),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isUploading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              loc.goToHome,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
