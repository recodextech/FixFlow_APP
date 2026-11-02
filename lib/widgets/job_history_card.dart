import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme.dart';

/// Compact card for a past job: what it was, when, how long and how much.
/// Shared by the worker and contractor history tabs, which deliberately leave
/// out the other party's name, phone and the job's route or photos.
class JobHistoryCard extends StatelessWidget {
  final String title;

  /// Category or description shown under the title; hidden when empty.
  final String details;
  final Widget statusChip;
  final DateTime? startTime;

  /// Shown when [startTime] could not be parsed.
  final String rawStartTime;
  final double durationHours;
  final String amountLabel;
  final double? amount;

  /// Optional row under the summary, e.g. the contractor's worker rating.
  final Widget? footer;

  const JobHistoryCard({
    super.key,
    required this.title,
    this.details = '',
    required this.statusChip,
    required this.startTime,
    this.rawStartTime = '',
    required this.durationHours,
    required this.amountLabel,
    required this.amount,
    this.footer,
  });

  static final DateFormat _dateFormat = DateFormat('MMM d, yyyy');
  static final DateFormat _timeFormat = DateFormat('HH:mm');

  @override
  Widget build(BuildContext context) {
    final start = startTime;
    final hours = durationHours == durationHours.truncateToDouble()
        ? durationHours.toInt().toString()
        : durationHours.toString();
    final amountValue = amount;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gray2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (details.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        details.trim(),
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.text2,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              statusChip,
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.gray0,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: _InfoItem(
                    icon: Icons.event_outlined,
                    value: start != null
                        ? _dateFormat.format(start)
                        : (rawStartTime.isNotEmpty ? rawStartTime : 'N/A'),
                    caption: start != null ? _timeFormat.format(start) : null,
                  ),
                ),
                const _Separator(),
                Expanded(
                  flex: 3,
                  child: _InfoItem(
                    icon: Icons.timer_outlined,
                    value: '${hours}h',
                  ),
                ),
                const _Separator(),
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        amountLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.text3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        amountValue != null
                            ? '${AppConstants.currencySymbol} '
                                  '${NumberFormat('#,##0.00').format(amountValue)}'
                            : '—',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.green,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (footer != null) ...[const SizedBox(height: 10), footer!],
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String? caption;

  const _InfoItem({required this.icon, required this.value, this.caption});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.text3),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (caption != null)
                Text(
                  caption!,
                  style: const TextStyle(fontSize: 11, color: AppColors.text3),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Separator extends StatelessWidget {
  const _Separator();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      color: AppColors.gray3,
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}
