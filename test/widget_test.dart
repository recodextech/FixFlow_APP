// Basic smoke test verifying the app boots without throwing.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fixflow_app/main.dart';
import 'package:fixflow_app/screens/login_screen.dart';

void main() {
  testWidgets('App builds without throwing', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('Google sign-in stays disabled until agreement is checked', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.pumpAndSettle();

    final signInButton = find.byKey(const ValueKey('google-sign-in-button'));
    expect(tester.widget<ElevatedButton>(signInButton).onPressed, isNull);
    expect(
      tester.getTopLeft(find.byType(Checkbox)).dy,
      greaterThan(tester.getTopLeft(signInButton).dy),
    );
    expect(
      find.text('Contractor responsibility at the worksite'),
      findsNothing,
    );

    await tester.tap(find.text('View more'));
    await tester.pumpAndSettle();

    expect(find.text('FixFlow User Agreement'), findsOneWidget);
    expect(
      find.text('Contractor responsibility at the worksite'),
      findsOneWidget,
    );

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    expect(find.text('FixFlow User Agreement'), findsNothing);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    expect(tester.widget<ElevatedButton>(signInButton).onPressed, isNotNull);
    expect(
      (await SharedPreferences.getInstance()).getBool(
        'fixflow_user_agreement_accepted_v1',
      ),
      isTrue,
    );
  });

  testWidgets('Returning users do not see the agreement again', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'fixflow_user_agreement_accepted_v1': true,
    });
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.pumpAndSettle();

    expect(find.byType(Checkbox), findsNothing);
    expect(find.text('View more'), findsNothing);
    expect(
      tester
          .widget<ElevatedButton>(
            find.byKey(const ValueKey('google-sign-in-button')),
          )
          .onPressed,
      isNotNull,
    );
  });
}
