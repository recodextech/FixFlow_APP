import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/wallet.dart';
import '../services/api_service.dart';
import '../theme.dart';

String formatMoney(double amount) =>
    '${AppConstants.currencySymbol} ${amount.toStringAsFixed(2)}';

/// Wallet tile showing the balance and, for the account's role, what was
/// earned (worker) or paid (contractor). Tap to see the transaction history.
class WalletCard extends StatelessWidget {
  final Wallet wallet;
  final AppLocalizations loc;
  final String? accountId;
  final bool isWorker;
  final Color balanceColor;

  const WalletCard({
    super.key,
    required this.wallet,
    required this.loc,
    required this.accountId,
    required this.isWorker,
    required this.balanceColor,
  });

  @override
  Widget build(BuildContext context) {
    final totalLabel = isWorker ? loc.earned : loc.paid;
    final total = isWorker ? wallet.totalCredited : wallet.totalDebited;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => showWalletTransactionsSheet(
          context: context,
          wallet: wallet,
          loc: loc,
          accountId: accountId,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.gray2, width: 1),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: wallet.iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(wallet.icon, color: wallet.iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wallet.displayName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalLabel ${formatMoney(total)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.text2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatMoney(wallet.balance),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: wallet.balance < 0 ? AppColors.red : balanceColor,
                    ),
                  ),
                  Text(
                    loc.balance,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.text3,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: AppColors.text3),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet listing the wallet's ledger entries, newest first.
Future<void> showWalletTransactionsSheet({
  required BuildContext context,
  required Wallet wallet,
  required AppLocalizations loc,
  required String? accountId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (context, scrollController) => _WalletTransactionsSheet(
        wallet: wallet,
        loc: loc,
        accountId: accountId,
        scrollController: scrollController,
      ),
    ),
  );
}

class _WalletTransactionsSheet extends StatefulWidget {
  final Wallet wallet;
  final AppLocalizations loc;
  final String? accountId;
  final ScrollController scrollController;

  const _WalletTransactionsSheet({
    required this.wallet,
    required this.loc,
    required this.accountId,
    required this.scrollController,
  });

  @override
  State<_WalletTransactionsSheet> createState() =>
      _WalletTransactionsSheetState();
}

class _WalletTransactionsSheetState extends State<_WalletTransactionsSheet> {
  late final Future<List<WalletTransaction>> _transactionsFuture = ApiService()
      .getWalletTransactions(
        walletId: widget.wallet.id,
        accountId: widget.accountId,
      );

  @override
  Widget build(BuildContext context) {
    final loc = widget.loc;
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.gray3,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Icon(widget.wallet.icon, color: widget.wallet.iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${widget.wallet.displayName} · ${loc.transactionHistory}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: FutureBuilder<List<WalletTransaction>>(
            future: _transactionsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return _message(loc.failedToLoadTransactions);
              }
              final transactions = snapshot.data ?? const [];
              if (transactions.isEmpty) {
                return _message(loc.noTransactionsYet);
              }
              return ListView.separated(
                controller: widget.scrollController,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: transactions.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, indent: 72),
                itemBuilder: (_, i) =>
                    _TransactionTile(transaction: transactions[i], loc: loc),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _message(String text) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(text, style: const TextStyle(color: AppColors.text3)),
    ),
  );
}

class _TransactionTile extends StatelessWidget {
  final WalletTransaction transaction;
  final AppLocalizations loc;

  const _TransactionTile({required this.transaction, required this.loc});

  @override
  Widget build(BuildContext context) {
    final credit = transaction.isCredit;
    final color = credit ? AppColors.green : AppColors.red;
    final date = transaction.createdAt;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: (credit ? AppColors.greenPale : AppColors.redPale),
        child: Icon(
          credit ? Icons.south_west_rounded : Icons.north_east_rounded,
          color: color,
          size: 20,
        ),
      ),
      title: Text(
        credit ? loc.jobPaymentReceived : loc.jobPaymentMade,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        [
          if (date != null) DateFormat('yyyy-MM-dd HH:mm').format(date),
          loc.balanceAfter(formatMoney(transaction.balanceAfter)),
        ].join(' · '),
        style: const TextStyle(fontSize: 12, color: AppColors.text3),
      ),
      trailing: Text(
        '${credit ? '+' : '−'}${formatMoney(transaction.amount)}',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
