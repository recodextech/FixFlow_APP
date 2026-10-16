import 'package:flutter/material.dart';

const Color starColor = Color(0xFFFFB300);

/// Read-only stars with the average and count, e.g. ★★★★☆ 4.3 (12).
/// Shows [emptyLabel] instead of the numbers when [count] is 0.
class StarRatingDisplay extends StatelessWidget {
  final double rating;
  final int count;
  final String emptyLabel;
  final double size;
  final Color textColor;

  const StarRatingDisplay({
    super.key,
    required this.rating,
    required this.count,
    required this.emptyLabel,
    this.size = 14,
    this.textColor = const Color(0xFF5D6D7E),
  });

  @override
  Widget build(BuildContext context) {
    final hasRatings = count > 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            !hasRatings
                ? Icons.star_border_rounded
                : rating >= i
                ? Icons.star_rounded
                : rating >= i - 0.5
                ? Icons.star_half_rounded
                : Icons.star_border_rounded,
            size: size,
            color: starColor,
          ),
        const SizedBox(width: 4),
        Text(
          hasRatings ? '${rating.toStringAsFixed(1)} ($count)' : emptyLabel,
          style: TextStyle(
            fontSize: size - 2,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    );
  }
}

/// Five tappable stars. [value] 0 shows them all empty.
class StarRatingInput extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final double size;

  const StarRatingInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          InkResponse(
            onTap: () => onChanged(i),
            radius: size * 0.7,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Icon(
                i <= value ? Icons.star_rounded : Icons.star_border_rounded,
                size: size,
                color: starColor,
              ),
            ),
          ),
      ],
    );
  }
}
