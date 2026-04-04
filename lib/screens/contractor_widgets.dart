import 'package:flutter/material.dart';
import '../theme.dart';

/// Pinned tab-bar delegate for contractor profile screen.
class ContractorTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  ContractorTabBarDelegate({required this.tabBar});

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: Theme.of(context).scaffoldBackgroundColor, child: tabBar);
  }

  @override
  bool shouldRebuild(covariant ContractorTabBarDelegate oldDelegate) => false;
}

/// Coloured status chip used on process cards.
class ProcessStatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const ProcessStatusChip({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

/// Maps a process status string to a colour.
Color getProcessStatusColor(String status) {
  switch (status.toUpperCase()) {
    case 'CREATED':
    case 'PENDING':
      return AppColors.orange;
    case 'IN_PROGRESS':
      return AppColors.blue;
    case 'COMPLETED':
      return AppColors.green;
    case 'FAILED':
    case 'CANCELLED':
      return AppColors.red;
    default:
      return AppColors.gray5;
  }
}

/// Formats a raw date-time string for display.
String formatJobStartTime(String rawDateTime) {
  if (rawDateTime.trim().isEmpty) return 'N/A';
  final normalized =
      rawDateTime.contains(' ') ? rawDateTime.replaceFirst(' ', 'T') : rawDateTime;
  final parsed = DateTime.tryParse(normalized);
  if (parsed == null) return rawDateTime;
  return '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-'
      '${parsed.day.toString().padLeft(2, '0')} '
      '${parsed.hour.toString().padLeft(2, '0')}:'
      '${parsed.minute.toString().padLeft(2, '0')}';
}
