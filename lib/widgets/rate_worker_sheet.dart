import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../theme.dart';
import 'app_toast.dart';
import 'star_rating.dart';

/// Bottom sheet where the contractor confirms the stars, adds an optional
/// comment and submits. [onSubmit] does the API call; when it throws, the
/// error is shown at the top of the screen. A job state conflict (already
/// rated, job not completed) closes the sheet; other errors keep it open to
/// retry. Resolves to true once submitted.
Future<bool> showRateWorkerSheet({
  required BuildContext context,
  required AppLocalizations loc,
  required String workerName,
  required int initialRating,
  required Future<void> Function(int rating, String comment) onSubmit,
}) async {
  final submitted = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _RateWorkerSheet(
      loc: loc,
      workerName: workerName,
      initialRating: initialRating,
      onSubmit: onSubmit,
    ),
  );
  return submitted == true;
}

class _RateWorkerSheet extends StatefulWidget {
  final AppLocalizations loc;
  final String workerName;
  final int initialRating;
  final Future<void> Function(int rating, String comment) onSubmit;

  const _RateWorkerSheet({
    required this.loc,
    required this.workerName,
    required this.initialRating,
    required this.onSubmit,
  });

  @override
  State<_RateWorkerSheet> createState() => _RateWorkerSheetState();
}

class _RateWorkerSheetState extends State<_RateWorkerSheet> {
  static const _maxCommentLength = 500;

  final TextEditingController _commentController = TextEditingController();
  late int _rating = widget.initialRating;
  bool _submitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await widget.onSubmit(_rating, _commentController.text.trim());
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      AppToast.fromError(
        e,
        loc: widget.loc,
        fallback: widget.loc.failedToSubmitRating,
      );
      if (e is ApiException && e.isConflict) {
        Navigator.pop(context, false);
        return;
      }
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = widget.loc;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.gray3,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            loc.rateWorkerName(widget.workerName),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            loc.howWasTheWork,
            style: const TextStyle(fontSize: 13, color: AppColors.text2),
          ),
          const SizedBox(height: 12),
          StarRatingInput(
            value: _rating,
            size: 40,
            onChanged: _submitting
                ? (_) {}
                : (v) => setState(() => _rating = v),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commentController,
            enabled: !_submitting,
            maxLines: 3,
            maxLength: _maxCommentLength,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: loc.addCommentOptional,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _submitting || _rating == 0 ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(loc.submit),
            ),
          ),
        ],
      ),
    );
  }
}
