import 'package:flutter/material.dart';
import '../theme.dart';

/// Pinned tab-bar delegate for worker profile screen.
class WorkerTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const WorkerTabBarDelegate({required this.tabBar});

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: Colors.white, child: tabBar);
  }

  @override
  bool shouldRebuild(covariant WorkerTabBarDelegate oldDelegate) => false;
}

/// Translucent badge shown in the gradient header.
class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Small coloured chip showing job status.
class JobStatusChip extends StatelessWidget {
  final String status;
  const JobStatusChip({super.key, required this.status});

  Color get _bg {
    switch (status) {
      case 'PENDING':
        return AppColors.orangePale;
      case 'ACCEPTED':
        return AppColors.bluePale;
      case 'STARTED':
      case 'IN_PROGRESS':
        return const Color(0xFFE8EAF6);
      case 'SUCCESS':
      case 'COMPLETED':
        return AppColors.greenPale;
      default:
        return AppColors.gray1;
    }
  }

  Color get _fg {
    switch (status) {
      case 'PENDING':
        return AppColors.orange;
      case 'ACCEPTED':
        return AppColors.blue;
      case 'STARTED':
      case 'IN_PROGRESS':
        return const Color(0xFF283593);
      case 'SUCCESS':
      case 'COMPLETED':
        return AppColors.green;
      default:
        return AppColors.gray6;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        status,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _fg),
      ),
    );
  }
}

/// Rounded action button used in job cards.
class ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final VoidCallback onPressed;

  const ActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
            : Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontSize: 13)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }
}

/// Badge shown when a job is completed.
class CompletedBadge extends StatelessWidget {
  const CompletedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.greenPale,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 16, color: AppColors.green),
          const SizedBox(width: 6),
          Text(
            'Completed',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.green,
            ),
          ),
        ],
      ),
    );
  }
}
