import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/preferences_service.dart';
import '../services/auth_service.dart';
import 'worker_profile_screen.dart';
import 'contractor_profile_screen.dart';
import 'create_worker_screen.dart';
import 'create_contractor_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _onWorkerTap() async {
    final prefs = PreferencesService();
    final workerId = prefs.getWorkerId();
    final hasWorker = workerId != null && workerId.isNotEmpty;

    await prefs.activateWorkerProfile();
    if (!mounted) return;

    if (hasWorker) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WorkerProfileScreen(workerId: workerId),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CreateWorkerScreen()),
      );
    }
  }

  Future<void> _onContractorTap() async {
    final prefs = PreferencesService();
    final contractorId = prefs.getContractorId();
    final hasContractor = contractorId != null && contractorId.isNotEmpty;

    await prefs.activateContractorProfile();
    if (!mounted) return;

    if (hasContractor) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ContractorProfileScreen(contractorId: contractorId),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CreateContractorScreen()),
      );
    }
  }

  Future<void> _logout() async {
    await AuthService().logout();
    await PreferencesService().clearAll();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefs = PreferencesService();
    final workerName = prefs.getWorkerName();
    final contractorName = prefs.getContractorName();
    final hasWorker =
        prefs.getWorkerId() != null && prefs.getWorkerId()!.isNotEmpty;
    final hasContractor =
        prefs.getContractorId() != null && prefs.getContractorId()!.isNotEmpty;

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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                const SizedBox(height: 16),
                // App title
                const Text(
                  'FixFlow',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Worker & Contractor Manager',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  'Who are you?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 28),

                // Worker Card
                _RoleCard(
                  icon: Icons.groups_rounded,
                  title: 'I am a Worker',
                  subtitle: hasWorker
                      ? workerName ?? 'Worker profile'
                      : 'Create or manage your worker profile',
                  buttonLabel:
                      hasWorker ? 'Continue as Worker' : 'Create Worker Profile',
                  gradient: AppColors.workerGradient,
                  onTap: _onWorkerTap,
                ),
                const SizedBox(height: 20),

                // Contractor Card
                _RoleCard(
                  icon: Icons.apartment_rounded,
                  title: 'I am a Contractor',
                  subtitle: hasContractor
                      ? contractorName ?? 'Contractor profile'
                      : 'Create or manage your contractor profile',
                  buttonLabel: hasContractor
                      ? 'Continue as Contractor'
                      : 'Create Contractor Profile',
                  gradient: AppColors.contractorOrangeGradient,
                  onTap: _onContractorTap,
                ),
                const SizedBox(height: 32),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text(
                      'Sign Out',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 52, color: Colors.white),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                buttonLabel,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: gradient.first,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
