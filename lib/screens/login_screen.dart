import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/preferences_service.dart';
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

  Future<void> _setAgreementAcceptance(bool? accepted) async {
    if (accepted == null) return;

    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(_agreementAcceptanceKey, accepted);
      if (!mounted) return;
      setState(() => _hasAcceptedAgreement = accepted);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save your agreement confirmation.'),
        ),
      );
    }
  }

  Future<void> _showAgreementDetails() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('FixFlow User Agreement'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('FixFlow is a connection platform'),
                Text(
                  'FixFlow only provides this app to help workers and contractors find and connect with each other. FixFlow is not a party to their work agreement and is not an employer, supervisor, or guarantor of either party.',
                ),
                SizedBox(height: 12),
                Text('Keep FixFlow connections in the app'),
                Text(
                  'Introductions, job requests, offers, acceptances, agreed terms, and changes arising from a FixFlow connection must be made or recorded in this app. Use emergency services or other necessary channels when a situation requires it.',
                ),
                SizedBox(height: 12),
                Text('Contractor responsibility at the worksite'),
                Text(
                  'When a worker arrives at the contractor’s worksite or starts work for the contractor, whichever happens first, the contractor is responsible for the worker and the work. This includes supervision, instructions, workplace safety, access, tools and equipment, agreed payment, and compliance with applicable laws, insurance, and permits, to the extent required by law.',
                ),
                SizedBox(height: 12),
                Text('Worker and contractor obligations'),
                Text(
                  'Workers and contractors must provide accurate information, agree directly on the scope, schedule, rate, and payment terms before work begins, act lawfully and respectfully, and raise safety concerns promptly. Each party is responsible for its own promises and conduct.',
                ),
                SizedBox(height: 12),
                Text('No guarantee or supervision by FixFlow'),
                Text(
                  'Unless the app expressly says otherwise, FixFlow does not guarantee a user’s identity, qualifications, availability, work quality, payment, or the outcome of a job, and does not inspect or supervise work. Workers and contractors must assess each other and resolve work-related issues directly.',
                ),
                SizedBox(height: 12),
                Text('Safety and disputes'),
                Text(
                  'Contractors must provide a safe work environment and take appropriate action if a worker may be at risk. Workers should stop unsafe work and seek appropriate help. The worker and contractor are responsible for resolving disputes between them; FixFlow is not responsible for their work relationship except where applicable law says otherwise.',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to load account. Please try again.'),
            ),
          );
          return;
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign-in failed. Please try again.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Sign-in error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    'Connect with top tradespeople\nand contractors instantly',
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
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'G',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 24,
                                    color: Color(0xFF4285F4),
                                  ),
                                ),
                                SizedBox(width: 14),
                                Text(
                                  'Continue with Google',
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
                            'I agree to the FixFlow User Agreement',
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
                      child: const Text('View more'),
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
