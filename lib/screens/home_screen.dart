import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';
import '../services/preferences_service.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../utils/performance_utils.dart';
import 'worker_profile_screen.dart';
import 'contractor_profile_screen.dart';
import 'create_user_screen.dart';
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
    if (workerId == null || workerId.isEmpty) {
      return;
    }

    await prefs.activateWorkerProfile();
    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkerProfileScreen(workerId: workerId),
      ),
    );

    if (!mounted) return;
    await _fetchMissingPhotos();
    if (mounted) setState(() {});
  }

  Future<void> _onContractorTap() async {
    final prefs = PreferencesService();
    final contractorId = prefs.getContractorId();
    if (contractorId == null || contractorId.isEmpty) {
      return;
    }

    await prefs.activateContractorProfile();
    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ContractorProfileScreen(contractorId: contractorId),
      ),
    );

    if (!mounted) return;
    await _fetchMissingPhotos();
    if (mounted) setState(() {});
  }

  Future<void> _onCreateUserTap() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateUserScreen()),
    );

    if (!mounted) return;
    await _fetchMissingPhotos();
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
                        'Welcome back${hasWorker && workerFirstName.isNotEmpty
                            ? ', $workerFirstName'
                            : hasContractor && contractorFirstName.isNotEmpty
                            ? ', $contractorFirstName'
                            : ''}!',
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

                if (!hasWorker && !hasContractor)
                  _RoleCard(
                    icon: Icons.person_add_alt_1_rounded,
                    title: 'Create User Profile',
                    subtitle:
                        'Create one user and continue as a worker or contractor',
                    buttonLabel: 'Create User',
                    gradient: AppColors.loginGradient,
                    photoBase64: null,
                    fullName: null,
                    onTap: _onCreateUserTap,
                  )
                else ...[
                  if (hasWorker)
                    _RoleCard(
                      icon: Icons.groups_rounded,
                      title: workerFirstName.isNotEmpty
                          ? workerFirstName
                          : 'Worker Profile',
                      subtitle: 'Continue to your worker profile',
                      buttonLabel: 'Continue as Worker',
                      gradient: AppColors.workerGradient,
                      photoBase64: workerPhotoBase64,
                      fullName: workerName,
                      onTap: _onWorkerTap,
                    ),
                  if (hasWorker && hasContractor) const SizedBox(height: 20),
                  if (hasContractor)
                    _RoleCard(
                      icon: Icons.apartment_rounded,
                      title: contractorFirstName.isNotEmpty
                          ? contractorFirstName
                          : 'Contractor Profile',
                      subtitle: 'Continue to your contractor profile',
                      buttonLabel: 'Continue as Contractor',
                      gradient: AppColors.contractorOrangeGradient,
                      photoBase64: contractorPhotoBase64,
                      fullName: contractorName,
                      onTap: _onContractorTap,
                    ),
                ],
                const SizedBox(height: 32),

                const _AboutUsCard(),
                const SizedBox(height: 20),

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
            _RoleCardImage(photoBase64: photoBase64, icon: icon),
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
            _RoleCardButton(label: buttonLabel, color: gradient.first),
          ],
        ),
      ),
    );
  }
}

class _RoleCardImage extends StatelessWidget {
  final String? photoBase64;
  final IconData icon;

  const _RoleCardImage({required this.photoBase64, required this.icon});

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
              placeholder: Icon(icon, size: 56, color: Colors.white),
              errorBuilder: (_, _, _) =>
                  Icon(icon, size: 56, color: Colors.white),
            ),
    );
  }
}

class _RoleCardButton extends StatelessWidget {
  final String label;
  final Color color;

  const _RoleCardButton({required this.label, required this.color});

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
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.42),
                  Colors.white.withValues(alpha: 0.18),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.45),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: ClipOval(
                child: Image.asset(
                  'assets/icons/home_header_icon.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'FixFlow',
            textAlign: TextAlign.center,
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
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutUsCard extends StatelessWidget {
  const _AboutUsCard();

  Future<void> _callPhone(BuildContext context, String phoneNumber) async {
    final telUri = Uri(scheme: 'tel', path: phoneNumber);
    final launched = await launchUrl(telUri);
    if (!launched) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Unable to open phone dialer')),
      );
    }
  }

  Future<void> _copyEmail(BuildContext context, String email) async {
    await Clipboard.setData(ClipboardData(text: email));
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(const SnackBar(content: Text('Email copied to clipboard')));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.2),
            Colors.white.withValues(alpha: 0.1),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -18,
            right: -10,
            child: Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.brandGold.withValues(alpha: 0.22),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.brandPale.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.info_outline,
                      color: AppColors.brandGreen,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'About Us',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Need help or partnership details? Reach our team directly:',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.88),
                  height: 1.35,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 14),
              _ContactTile(
                icon: Icons.phone_rounded,
                label: 'Phone',
                value: '077 644 3476',
                actionLabel: 'Tap to call',
                trailingIcon: Icons.call_rounded,
                onTap: () => _callPhone(context, '0776443476'),
              ),
              const SizedBox(height: 10),
              _ContactTile(
                icon: Icons.email_rounded,
                label: 'Email',
                value: 'inquiries@noventispvt.xyz',
                actionLabel: 'Tap to copy',
                trailingIcon: Icons.copy_rounded,
                onTap: () => _copyEmail(context, 'inquiries@noventispvt.xyz'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? actionLabel;
  final IconData? trailingIcon;
  final VoidCallback? onTap;

  const _ContactTile({
    required this.icon,
    required this.label,
    required this.value,
    this.actionLabel,
    this.trailingIcon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$label:',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (actionLabel != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        actionLabel!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailingIcon != null)
                Icon(
                  trailingIcon,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: 18,
                ),
            ],
          ),
        ),
      ),
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
          side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
