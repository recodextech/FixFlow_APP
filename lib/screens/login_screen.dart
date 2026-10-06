import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/preferences_service.dart';
import '../providers/language_provider.dart';
import '../l10n/app_localizations.dart';
import 'create_user_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const String _agreementAcceptanceKey =
      'fixflow_user_agreement_accepted_v1';

  bool _isLoading = false;
  bool _hasAcceptedAgreement = false;
  bool _agreementPreferenceLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAgreementAcceptance();
  }

  Future<void> _loadAgreementAcceptance() async {
    var accepted = false;
    try {
      final preferences = await SharedPreferences.getInstance();
      accepted = preferences.getBool(_agreementAcceptanceKey) ?? false;
    } catch (_) {
      // Keep the consent unchecked if local storage cannot be read.
    }

    if (!mounted) return;
    setState(() {
      _hasAcceptedAgreement = accepted;
      _agreementPreferenceLoaded = true;
    });
  }

  AppLocalizations get _loc => AppLocalizations.of(
    Provider.of<LanguageProvider>(context, listen: false).locale,
  );

  Future<void> _setAgreementAcceptance(bool? accepted) async {
    if (accepted == null) return;

    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(_agreementAcceptanceKey, accepted);
      if (!mounted) return;
      setState(() => _hasAcceptedAgreement = accepted);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_loc.couldNotSaveAgreement)));
    }
  }

  Future<void> _showLanguageSelector() async {
    final languageProvider = context.read<LanguageProvider>();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.of(languageProvider.locale).selectYourLanguage,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(AppLocalizations.of(const Locale('en')).english),
              leading: Radio<bool>(
                value: true,
                groupValue: languageProvider.isEnglish,
                onChanged: (value) {
                  if (value == true) {
                    languageProvider.setLocale(const Locale('en'));
                    Navigator.pop(context);
                  }
                },
              ),
            ),
            ListTile(
              title: Text(
                AppLocalizations.of(const Locale('si', 'LK')).sinhala,
              ),
              leading: Radio<bool>(
                value: false,
                groupValue: languageProvider.isEnglish,
                onChanged: (value) {
                  if (value == false) {
                    languageProvider.setLocale(const Locale('si', 'LK'));
                    Navigator.pop(context);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAgreementDetails() async {
    final loc = _loc;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.userAgreement),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loc.agreementContent1),
                Text(loc.agreementDesc1),
                const SizedBox(height: 12),
                Text(loc.agreementContent2),
                Text(loc.agreementDesc2),
                const SizedBox(height: 12),
                Text(loc.agreementContent3),
                Text(loc.agreementDesc3),
                const SizedBox(height: 12),
                Text(loc.agreementContent4),
                Text(loc.agreementDesc4),
                const SizedBox(height: 12),
                Text(loc.agreementContent5),
                Text(loc.agreementDesc5),
                const SizedBox(height: 12),
                Text(loc.agreementContent6),
                Text(loc.agreementDesc6),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(loc.close),
          ),
        ],
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final success = await AuthService().signInWithGoogle();
      if (!mounted) return;

      if (success) {
        // Fetch user accounts after login
        try {
          final accounts = await ApiService().getUserAccounts();
          PreferencesService().loadUserAccounts(
            userId: accounts.userId,
            worker: accounts.worker,
            contractor: accounts.contractor,
          );
          await NotificationService.registerDeviceForActiveAccount();

          if (!mounted) return;
          final nextScreen = accounts.hasAnyProfile
              ? const HomeScreen()
              : const CreateUserScreen();

          Navigator.of(
            context,
          ).pushReplacement(MaterialPageRoute(builder: (_) => nextScreen));
          return;
        } catch (_) {
          if (!mounted) return;
          await AuthService().logout();
          await PreferencesService().clearAll();
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(_loc.failedToLoadAccount)));
          return;
        }
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_loc.signInFailed)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${_loc.signInError}: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        final loc = AppLocalizations.of(languageProvider.locale);
        return _buildLoginUI(context, loc);
      },
    );
  }

  Widget _buildLoginUI(BuildContext context, AppLocalizations loc) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.loginGradient,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  // Animated Logo Container
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.1),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/icons/icon.png',
                        width: 72,
                        height: 72,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // App Title with better typography
                  const Text(
                    'FixFlow',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Subtitle with improved styling
                  Text(
                    loc.loginSubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.78),
                      height: 1.6,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 56),
                  // Decorative divider
                  Container(
                    width: 56,
                    height: 1.5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0),
                          Colors.white.withValues(alpha: 0.3),
                          Colors.white.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                  // Google Sign-in Button with enhanced styling
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      key: const ValueKey('google-sign-in-button'),
                      onPressed:
                          _isLoading ||
                              !_agreementPreferenceLoaded ||
                              !_hasAcceptedAgreement
                          ? null
                          : _signInWithGoogle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF3C4043),
                        elevation: 8,
                        shadowColor: Colors.black.withValues(alpha: 0.25),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF4285F4),
                                ),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'G',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 24,
                                    color: Color(0xFF4285F4),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Text(
                                  loc.signInWithGoogle,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF3C4043),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  if (_agreementPreferenceLoaded && !_hasAcceptedAgreement) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Checkbox(
                          value: _hasAcceptedAgreement,
                          activeColor: Colors.white,
                          checkColor: const Color(0xFF267A68),
                          side: const BorderSide(color: Colors.white70),
                          onChanged: _isLoading
                              ? null
                              : _setAgreementAcceptance,
                        ),
                        Flexible(
                          child: Text(
                            loc.agreeToTerms,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.88),
                            ),
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: _showAgreementDetails,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: Text(loc.viewMore),
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showLanguageSelector,
        backgroundColor: Colors.white.withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Text(
          loc.isEnglish ? 'සි' : 'EN',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.brandGreen,
          ),
        ),
      ),
    );
  }
}
