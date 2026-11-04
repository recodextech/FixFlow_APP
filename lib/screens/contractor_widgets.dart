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
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant ContractorTabBarDelegate oldDelegate) => false;
}

/// Coloured status chip used on process cards.
class ProcessStatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const ProcessStatusChip({
    super.key,
    required this.label,
    required this.color,
  });

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
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

/// Shown on an EXPIRED job: why it expired and a button to reschedule it.
class ExpiredJobBanner extends StatelessWidget {
  final String title;
  final String hint;
  final String buttonLabel;
  final bool isBusy;
  final VoidCallback onReschedule;

  const ExpiredJobBanner({
    super.key,
    required this.title,
    required this.hint,
    required this.buttonLabel,
    required this.onReschedule,
    this.isBusy = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningPale,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.event_busy_outlined,
                size: 18,
                color: AppColors.warning,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            hint,
            style: const TextStyle(fontSize: 12, color: AppColors.text2),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isBusy ? null : onReschedule,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.white,
              ),
              icon: isBusy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.edit_calendar, size: 18),
              label: Text(buttonLabel),
            ),
          ),
        ],
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
    case 'AWAITING_APPROVAL':
      return const Color(0xFF6A1B9A);
    case 'EXPIRED':
      return AppColors.warning;
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
  final normalized = rawDateTime.contains(' ')
      ? rawDateTime.replaceFirst(' ', 'T')
      : rawDateTime;
  final parsed = DateTime.tryParse(normalized);
  if (parsed == null) return rawDateTime;
  return '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-'
      '${parsed.day.toString().padLeft(2, '0')} '
      '${parsed.hour.toString().padLeft(2, '0')}:'
      '${parsed.minute.toString().padLeft(2, '0')}';
}
