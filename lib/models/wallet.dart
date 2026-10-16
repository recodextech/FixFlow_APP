import 'package:flutter/material.dart';

class Wallet {
  final String id;
  final String type;
  final double balance;
  final String status;

  /// Everything paid into the wallet (a worker's earnings).
  final double totalCredited;

  /// Everything paid out of the wallet (a contractor's job payments).
  final double totalDebited;

  Wallet({
    required this.id,
    required this.type,
    required this.balance,
    this.status = 'ACTIVE',
    this.totalCredited = 0,
    this.totalDebited = 0,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'ACTIVE',
      totalCredited: (json['totalCredited'] as num?)?.toDouble() ?? 0.0,
      totalDebited: (json['totalDebited'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'balance': balance,
      'status': status,
      'totalCredited': totalCredited,
      'totalDebited': totalDebited,
    };
  }

  IconData get icon {
    switch (type.toUpperCase()) {
      case 'CASH':
        return Icons.money;
      case 'POINTS':
        return Icons.stars;
      case 'CARD':
        return Icons.credit_card;
      default:
        return Icons.account_balance_wallet;
    }
  }

  Color get iconColor {
    switch (type.toUpperCase()) {
      case 'CASH':
        return Colors.green;
      case 'POINTS':
        return Colors.amber;
      case 'CARD':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String get displayName {
    switch (type.toUpperCase()) {
      case 'CASH':
        return 'Cash';
      case 'POINTS':
        return 'Points';
      case 'CARD':
        return 'Card';
      default:
        return type;
    }
  }
}

/// One ledger entry on a wallet: money in (CREDIT) or out (DEBIT) for a job.
class WalletTransaction {
  final String id;
  final String paymentId;
  final String jobId;
  final String type;
  final String direction;

  /// Always positive; [isCredit] tells whether it came in or went out.
  final double amount;
  final double balanceAfter;
  final DateTime? createdAt;

  const WalletTransaction({
    required this.id,
    required this.paymentId,
    required this.jobId,
    required this.type,
    required this.direction,
    required this.amount,
    required this.balanceAfter,
    this.createdAt,
  });

  bool get isCredit => direction.toUpperCase() == 'CREDIT';

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'] ?? '',
      paymentId: json['paymentId'] ?? '',
      jobId: json['jobId'] ?? '',
      type: json['type'] ?? '',
      direction: json['direction'] ?? 'CREDIT',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      balanceAfter: (json['balanceAfter'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '')?.toLocal(),
    );
  }
}
