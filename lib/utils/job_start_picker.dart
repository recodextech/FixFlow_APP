import 'package:flutter/material.dart';

import '../widgets/wheel_time_picker.dart';

/// A job may start from an hour from now up to 3 months ahead (the backend allows a month more).
DateTime earliestJobStart() => DateTime.now().add(const Duration(hours: 1));

DateTime latestJobStart() {
  final now = DateTime.now();
  return DateTime(now.year, now.month + 3, now.day, now.hour, now.minute);
}

bool isJobStartInRange(DateTime start) =>
    !start.isBefore(earliestJobStart()) && !start.isAfter(latestJobStart());

/// Formats a job start time as the backend expects it: `yyyy-MM-dd HH:mm`
/// in the account's local time.
String formatJobStartRequest(DateTime dateTime) =>
    '${dateTime.year.toString().padLeft(4, '0')}-'
    '${dateTime.month.toString().padLeft(2, '0')}-'
    '${dateTime.day.toString().padLeft(2, '0')} '
    '${dateTime.hour.toString().padLeft(2, '0')}:'
    '${dateTime.minute.toString().padLeft(2, '0')}';

/// Shows a date picker then a time picker for a job start time.
/// The time picker lists only the times allowed on the picked date.
/// Returns null when either picker is dismissed, and calls [onOutOfRange]
/// and returns null when the picked time is outside the allowed range.
Future<DateTime?> pickJobStartTime(
  BuildContext context, {
  DateTime? initial,
  required VoidCallback onOutOfRange,
}) async {
  final earliest = earliestJobStart();
  final latest = latestJobStart();
  final firstDate = DateTime(earliest.year, earliest.month, earliest.day);
  final lastDate = DateTime(latest.year, latest.month, latest.day);
  final initialStart = initial != null && isJobStartInRange(initial)
      ? initial
      : earliest;

  final date = await showDatePicker(
    context: context,
    initialDate: DateTime(
      initialStart.year,
      initialStart.month,
      initialStart.day,
    ),
    firstDate: firstDate,
    lastDate: lastDate,
  );

  if (date == null) return null;
  if (!context.mounted) return null;

  final range = _allowedMinutesOn(date, earliest, latest);
  if (range.first > range.last) return null;
  final time = await showWheelTimePicker(
    context,
    initial: TimeOfDay.fromDateTime(initialStart),
    earliest: TimeOfDay(hour: range.first ~/ 60, minute: range.first % 60),
    latest: TimeOfDay(hour: range.last ~/ 60, minute: range.last % 60),
  );

  if (time == null) return null;

  final dateTime = DateTime(
    date.year,
    date.month,
    date.day,
    time.hour,
    time.minute,
  );
  if (!isJobStartInRange(dateTime)) {
    onOutOfRange();
    return null;
  }
  return dateTime;
}

/// First and last selectable minute of the day (0..1439) on [date].
({int first, int last}) _allowedMinutesOn(
  DateTime date,
  DateTime earliest,
  DateTime latest,
) {
  bool sameDay(DateTime a) =>
      a.year == date.year && a.month == date.month && a.day == date.day;
  var first = 0;
  if (sameDay(earliest)) {
    // Round up to the next whole minute; picked times carry no seconds.
    final hasSeconds = earliest.second > 0 ||
        earliest.millisecond > 0 ||
        earliest.microsecond > 0;
    first = earliest.hour * 60 + earliest.minute + (hasSeconds ? 1 : 0);
  }
  var last = 24 * 60 - 1;
  if (sameDay(latest)) {
    last = latest.hour * 60 + latest.minute;
  }
  return (first: first, last: last);
}
