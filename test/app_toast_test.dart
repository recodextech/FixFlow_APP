import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fixflow_app/l10n/app_localizations.dart';
import 'package:fixflow_app/services/api_service.dart';
import 'package:fixflow_app/widgets/app_toast.dart';

void main() {
  final loc = AppLocalizations(const Locale('en'));

  Future<void> pumpApp(WidgetTester tester) {
    return tester.pumpWidget(
      MaterialApp(
        navigatorKey: AppToast.navigatorKey,
        home: const Scaffold(body: SizedBox.expand()),
      ),
    );
  }

  testWidgets('success toast shows at the top and disappears', (tester) async {
    await pumpApp(tester);

    AppToast.success('Signed in successfully');
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    final text = find.text('Signed in successfully');
    expect(text, findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(
      tester.getTopLeft(text).dy,
      lessThan(100),
      reason: 'shown at the top',
    );

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(text, findsNothing);
  });

  testWidgets('tapping the toast dismisses it early', (tester) async {
    await pumpApp(tester);

    AppToast.info('New job suggestion');
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    await tester.tap(find.text('New job suggestion'));
    await tester.pumpAndSettle();

    expect(find.text('New job suggestion'), findsNothing);
  });

  testWidgets('a new toast replaces the current one', (tester) async {
    await pumpApp(tester);

    AppToast.success('First');
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    AppToast.error('Second');
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    expect(find.text('First'), findsNothing);
    expect(find.text('Second'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('409 conflict shows the friendly message as a warning', (
    tester,
  ) async {
    await pumpApp(tester);

    AppToast.fromError(
      const ApiException(
        statusCode: 409,
        code: ApiException.conflictCode,
        message: 'job is not open for claiming',
      ),
      loc: loc,
      fallback: loc.failedToAcceptJob,
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    expect(
      find.text(
        'This job was already picked by another worker or is no longer open',
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('other errors show the fallback with the reason', (tester) async {
    await pumpApp(tester);

    AppToast.fromError(
      const ApiException(statusCode: 500, message: 'unknown error'),
      loc: loc,
      fallback: loc.failedToStartJob,
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    expect(find.text('${loc.failedToStartJob}: unknown error'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  test('every backend conflict description has its own message', () {
    const descriptions = [
      'job is not open for claiming',
      'contractor already rejected this worker for the job',
      "job has no claim awaiting this contractor's approval",
      'job is not approved for this worker',
      'job is not started by this worker',
      'job is not completed for this contractor',
      'worker is already rated for this job',
    ];
    final fallback = loc.conflictMessage('something else');
    final si = AppLocalizations(const Locale('si', 'LK'));

    for (final d in descriptions) {
      expect(loc.conflictMessage(d), isNot(fallback), reason: d);
      expect(si.conflictMessage(d), isNot(loc.conflictMessage(d)), reason: d);
    }
  });

  test('ApiException detects conflicts by status or code', () {
    expect(
      const ApiException(message: 'x', statusCode: 409).isConflict,
      isTrue,
    );
    expect(
      const ApiException(
        message: 'x',
        code: ApiException.conflictCode,
      ).isConflict,
      isTrue,
    );
    expect(
      const ApiException(message: 'x', statusCode: 500).isConflict,
      isFalse,
    );
  });
}
