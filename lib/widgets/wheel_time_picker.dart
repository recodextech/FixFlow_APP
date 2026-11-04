import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Shows a 24-hour hour/minute wheel picker that lists only the times
/// between [earliest] and [latest] (inclusive, defaulting to the whole day).
/// Returns null when dismissed.
Future<TimeOfDay?> showWheelTimePicker(
  BuildContext context, {
  required TimeOfDay initial,
  TimeOfDay earliest = const TimeOfDay(hour: 0, minute: 0),
  TimeOfDay latest = const TimeOfDay(hour: 23, minute: 59),
}) {
  final range = (
    first: earliest.hour * 60 + earliest.minute,
    last: latest.hour * 60 + latest.minute,
  );
  if (range.first > range.last) return Future.value(null);

  final hours = [
    for (var h = range.first ~/ 60; h <= range.last ~/ 60; h++) h,
  ];
  List<int> minutesFor(int hour) => [
        for (var m = 0; m < 60; m++)
          if (hour * 60 + m >= range.first && hour * 60 + m <= range.last) m,
      ];

  final initialTotal =
      (initial.hour * 60 + initial.minute).clamp(range.first, range.last);
  var hour = initialTotal ~/ 60;
  var minute = initialTotal % 60;
  final hourController = FixedExtentScrollController(
    initialItem: hours.indexOf(hour),
  );
  var minuteController = FixedExtentScrollController(
    initialItem: minutesFor(hour).indexOf(minute),
  );

  return showDialog<TimeOfDay>(
    context: context,
    builder: (dialogContext) {
      final loc = MaterialLocalizations.of(dialogContext);
      return StatefulBuilder(
        builder: (context, setDialogState) {
          final minutes = minutesFor(hour);
          return AlertDialog(
            title: Text(loc.timePickerDialHelpText),
            content: SizedBox(
              height: 200,
              width: 240,
              child: Row(
                children: [
                  Expanded(
                    child: CupertinoPicker(
                      scrollController: hourController,
                      itemExtent: 40,
                      onSelectedItemChanged: (i) => setDialogState(() {
                        hour = hours[i];
                        final allowed = minutesFor(hour);
                        minute = minute.clamp(allowed.first, allowed.last);
                        minuteController = FixedExtentScrollController(
                          initialItem: allowed.indexOf(minute),
                        );
                      }),
                      children: [
                        for (final h in hours)
                          Center(child: Text(h.toString().padLeft(2, '0'))),
                      ],
                    ),
                  ),
                  const Text(':', style: TextStyle(fontSize: 20)),
                  Expanded(
                    child: CupertinoPicker(
                      // Rebuild when the hour changes, since its minutes differ.
                      key: ValueKey(hour),
                      scrollController: minuteController,
                      itemExtent: 40,
                      onSelectedItemChanged: (i) =>
                          setDialogState(() => minute = minutes[i]),
                      children: [
                        for (final m in minutes)
                          Center(child: Text(m.toString().padLeft(2, '0'))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(loc.cancelButtonLabel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(
                  dialogContext,
                  TimeOfDay(hour: hour, minute: minute),
                ),
                child: Text(loc.okButtonLabel),
              ),
            ],
          );
        },
      );
    },
  );
}
