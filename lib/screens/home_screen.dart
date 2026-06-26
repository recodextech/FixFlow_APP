import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/preferences_service.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../widgets/profile_avatar.dart';
import '../utils/performance_utils.dart';
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
  @override
  void initState() {
    super.initState();
    _fetchMissingPhotos();
  }

  Future<void> _fetchMissingPhotos() async {
    final prefs = PreferencesService();
    final api = ApiService();

    final workerId = prefs.getWorkerId();
    final workerAccountId = prefs.getWorkerAccountId();
    if (workerId != null &&
        workerId.isNotEmpty &&
        (prefs.getWorkerPhotoBase64() ?? '').isEmpty) {
      try {
        final image = await api.getWorkerProfilePicture(
          workerId: workerId,
          accountId: workerAccountId,
        );
        if (image != null && image.data.isNotEmpty && mounted) {
          prefs.cacheWorkerPhoto(image.data);
          setState(() {});
        }
      } catch (_) {}
    }

    final contractorId = prefs.getContractorId();
    final contractorAccountId = prefs.getContractorAccountId();
    if (contractorId != null &&
        contractorId.isNotEmpty &&
        (prefs.getContractorPhotoBase64() ?? '').isEmpty) {
      try {
        final image = await api.getContractorProfilePicture(
          contractorId: contractorId,
          accountId: contractorAccountId,
        );
        if (image != null && image.data.isNotEmpty && mounted) {
          prefs.cacheContractorPhoto(image.data);
          setState(() {});
        }
      } catch (_) {}
    }
  }

  Future<void> _onWorkerTap() async {
    final prefs = PreferencesService();
    final workerId = prefs.getWorkerId();
    final hasWorker = workerId != null && workerId.isNotEmpty;

    await prefs.activateWorkerProfile();
    if (!mounted) return;

    if (hasWorker) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WorkerProfileScreen(workerId: workerId),
        ),
      );
    } else {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CreateWorkerScreen()),
      );
    }
    if (mounted) setState(() {});
  }

  Future<void> _onContractorTap() async {
    final prefs = PreferencesService();
    final contractorId = prefs.getContractorId();
    final hasContractor = contractorId != null && contractorId.isNotEmpty;

    await prefs.activateContractorProfile();
    if (!mounted) return;

    if (hasContractor) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ContractorProfileScreen(contractorId: contractorId),
        ),
      );
    } else {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CreateContractorScreen()),
      );
    }
    if (mounted) setState(() {});
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

  String _getFirstName(String? fullName) {
    if (fullName == null || fullName.isEmpty) return '';
    return fullName.split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    final prefs = PreferencesService();
    final workerName = prefs.getWorkerName();
    final contractorName = prefs.getContractorName();
    final workerPhotoBase64 = prefs.getWorkerPhotoBase64();
    final contractorPhotoBase64 = prefs.getContractorPhotoBase64();
    final workerId = prefs.getWorkerId();
    final contractorId = prefs.getContractorId();
    final hasWorker = workerId != null && workerId.isNotEmpty;
    final hasContractor = contractorId != null && contractorId.isNotEmpty;

    final workerFirstName = _getFirstName(workerName);
    final contractorFirstName = _getFirstName(contractorName);

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
                // Header with app name
                const _HomeHeader(),
                const SizedBox(height: 40),
                
                // Personalized greeting with first name if available
                if (hasWorker || hasContractor)
                  Column(
                    children: [
                      Text(
                        'Welcome back${hasWorker && workerFirstName.isNotEmpty ? ', $workerFirstName' : hasContractor && contractorFirstName.isNotEmpty ? ', $contractorFirstName' : ''}!',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],
                  )
                else
                  const SizedBox(height: 28),

                const _WhoAreYouText(),
                const SizedBox(height: 28),

                // Worker Card
                _RoleCard(
                  icon: Icons.groups_rounded,
                  title: hasWorker ? (workerFirstName.isNotEmpty ? workerFirstName : 'Worker Profile') : 'Worker Profile',
                  subtitle: hasWorker
                      ? 'Continue to your worker profile'
                      : 'Create your worker profile',
                  buttonLabel:
                      hasWorker ? 'Continue as Worker' : 'Create Worker Profile',
                  gradient: AppColors.workerGradient,
                  photoBase64: workerPhotoBase64,
                  fullName: workerName,
                  onTap: _onWorkerTap,
                ),
                const SizedBox(height: 20),

                // Contractor Card
                _RoleCard(
                  icon: Icons.apartment_rounded,
                  title: hasContractor
                      ? (contractorFirstName.isNotEmpty ? contractorFirstName : 'Contractor Profile')
                      : 'Contractor Profile',
                  subtitle: hasContractor
                      ? 'Continue to your contractor profile'
                      : 'Create your contractor profile',
                  buttonLabel: hasContractor
                      ? 'Continue as Contractor'
                      : 'Create Contractor Profile',
                  gradient: AppColors.contractorOrangeGradient,
                  photoBase64: contractorPhotoBase64,
                  fullName: contractorName,
                  onTap: _onContractorTap,
                ),
                const SizedBox(height: 32),

                // Logout Button
                _LogoutButton(onLogout: _logout),
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
  final String? photoBase64;
  final String? fullName;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.gradient,
    required this.photoBase64,
    required this.fullName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
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
            _RoleCardImage(
              photoBase64: photoBase64,
              icon: icon,
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 22),
            _RoleCardButton(
              label: buttonLabel,
              color: gradient.first,
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCardImage extends StatelessWidget {
  final String? photoBase64;
  final IconData icon;

  const _RoleCardImage({
    required this.photoBase64,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: photoBase64 == null || photoBase64!.isEmpty
          ? Icon(icon, size: 56, color: Colors.white)
          : CachedMemoryImage(
              base64String: photoBase64,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(icon, size: 56, color: Colors.white),
            ),
    );
  }
}

class _RoleCardButton extends StatelessWidget {
  final String label;
  final Color color;

  const _RoleCardButton({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      ],
    );
  }
}

class _WhoAreYouText extends StatelessWidget {
  const _WhoAreYouText();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Who are you?',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onLogout;

  const _LogoutButton({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onLogout,
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
    );
  }
}
