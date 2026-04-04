import 'package:flutter/material.dart';

class Wallet {
  final String id;
  final String type;
  final double balance;
  final String status;

  Wallet({
    required this.id,
    required this.type,
    required this.balance,
    this.status = 'ACTIVE',
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'ACTIVE',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'balance': balance,
      'status': status,
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
