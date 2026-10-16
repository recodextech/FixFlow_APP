import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fixflow_app/l10n/app_localizations.dart';
import 'package:fixflow_app/models/wallet.dart';
import 'package:fixflow_app/theme.dart';
import 'package:fixflow_app/widgets/wallet_card.dart';

void main() {
  final loc = AppLocalizations(const Locale('en'));

  test('wallet parses balance and ledger totals', () {
    final wallet = Wallet.fromJson({
      'id': 'w1',
      'type': 'CASH',
      'balance': -50,
      'status': 'ACTIVE',
      'totalCredited': 0,
      'totalDebited': 50,
    });

    expect(wallet.balance, -50);
    expect(wallet.totalCredited, 0);
    expect(wallet.totalDebited, 50);
  });

  test('wallet without totals defaults them to zero', () {
    final wallet = Wallet.fromJson({
      'id': 'w1',
      'type': 'POINTS',
      'balance': 10,
    });

    expect(wallet.totalCredited, 0);
    expect(wallet.totalDebited, 0);
  });

  test('transaction parses direction and amount', () {
    final debit = WalletTransaction.fromJson({
      'id': 't1',
      'paymentId': 'p1',
      'jobId': 'j1',
      'type': 'CASH',
      'direction': 'DEBIT',
      'amount': 50,
      'balanceAfter': -50,
      'createdAt': '2026-10-16T05:00:00Z',
    });

    expect(debit.isCredit, isFalse);
    expect(debit.amount, 50);
    expect(debit.balanceAfter, -50);
    expect(debit.createdAt, isNotNull);
  });

  Future<void> pumpCard(WidgetTester tester, Wallet wallet, bool isWorker) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WalletCard(
            wallet: wallet,
            loc: loc,
            accountId: 'a1',
            isWorker: isWorker,
            balanceColor: AppColors.green,
          ),
        ),
      ),
    );
  }

  testWidgets('worker card shows what was earned', (tester) async {
    await pumpCard(
      tester,
      Wallet(id: 'w1', type: 'CASH', balance: 100, totalCredited: 100),
      true,
    );

    expect(find.text('Earned ${formatMoney(100)}'), findsOneWidget);
    expect(find.text(formatMoney(100)), findsOneWidget);
  });

  testWidgets(
    'contractor card shows what was paid and a negative balance in red',
    (tester) async {
      await pumpCard(
        tester,
        Wallet(id: 'w1', type: 'CASH', balance: -50, totalDebited: 50),
        false,
      );

      expect(find.text('Paid ${formatMoney(50)}'), findsOneWidget);
      final balance = tester.widget<Text>(find.text(formatMoney(-50)));
      expect(balance.style?.color, AppColors.red);
    },
  );
}
