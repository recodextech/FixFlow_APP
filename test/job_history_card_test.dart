import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fixflow_app/widgets/job_history_card.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: SizedBox(width: 360, child: child)));

void main() {
  testWidgets('shows job, date, time, duration and amount', (tester) async {
    await tester.pumpWidget(
      _wrap(
        JobHistoryCard(
          title: 'Plumbing',
          details: 'Fix the kitchen sink',
          statusChip: const Text('Completed'),
          startTime: DateTime(2026, 10, 12, 9, 30),
          durationHours: 2.5,
          amountLabel: 'Earned',
          amount: 2500,
        ),
      ),
    );

    expect(find.text('Plumbing'), findsOneWidget);
    expect(find.text('Fix the kitchen sink'), findsOneWidget);
    expect(find.text('Oct 12, 2026'), findsOneWidget);
    expect(find.text('09:30'), findsOneWidget);
    expect(find.text('2.5h'), findsOneWidget);
    expect(find.text('Rs. 2,500.00'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('falls back to the raw start time and a dash for no amount', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const JobHistoryCard(
          title: 'Painting',
          statusChip: Text('Ended'),
          startTime: null,
          rawStartTime: 'tomorrow',
          durationHours: 3,
          amountLabel: 'Paid',
          amount: null,
        ),
      ),
    );

    expect(find.text('tomorrow'), findsOneWidget);
    expect(find.text('3h'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
  });
}
