import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fixflow_app/models/process.dart';
import 'package:fixflow_app/screens/contractor_widgets.dart';
import 'package:fixflow_app/utils/job_start_picker.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: SizedBox(width: 360, child: child)),
);

ContractorProcessJobSummary _job(
  String status, {
  String assignedWorkerId = '',
  String approvalStatus = '',
  JobClaim? claim,
}) => ContractorProcessJobSummary(
  id: 'job-1',
  status: status,
  latitude: 0,
  longitude: 0,
  jobStartTime: '2026-11-04 09:00',
  durationHours: 2,
  assignedWorkerId: assignedWorkerId,
  approvalStatus: approvalStatus,
  claim: claim,
);

void main() {
  group('canReschedule', () {
    test('open PENDING and EXPIRED jobs can be rescheduled', () {
      expect(_job('PENDING').canReschedule, isTrue);
      expect(_job('EXPIRED').canReschedule, isTrue);
      expect(_job('EXPIRED').isExpired, isTrue);
    });

    test('assigned, claimed or started jobs cannot', () {
      expect(_job('PENDING', assignedWorkerId: 'w1').canReschedule, isFalse);
      expect(_job('ACCEPTED').canReschedule, isFalse);
      expect(
        _job(
          'PENDING',
          approvalStatus: 'PENDING',
          claim: JobClaim.fromJson({'workerId': 'w1'}),
        ).canReschedule,
        isFalse,
      );
    });
  });

  test('formats the start time like the create-process request', () {
    expect(
      formatJobStartRequest(DateTime(2026, 3, 7, 8, 5)),
      '2026-03-07 08:05',
    );
  });

  testWidgets('expired banner shows the note and calls reschedule', (
    tester,
  ) async {
    var tapped = 0;
    await tester.pumpWidget(
      _wrap(
        ExpiredJobBanner(
          title: 'Expired – no worker accepted',
          hint: 'Pick a new start time.',
          buttonLabel: 'Reschedule',
          onReschedule: () => tapped++,
        ),
      ),
    );

    expect(find.text('Expired – no worker accepted'), findsOneWidget);
    await tester.tap(find.text('Reschedule'));
    expect(tapped, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('expired banner button is disabled while busy', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(
      _wrap(
        ExpiredJobBanner(
          title: 'Expired',
          hint: 'hint',
          buttonLabel: 'Reschedule',
          isBusy: true,
          onReschedule: () => tapped++,
        ),
      ),
    );

    await tester.tap(find.text('Reschedule'));
    expect(tapped, 0);
  });
}
