class PaymentInformation {
  final double amount;
  final String walletId;

  PaymentInformation({
    required this.amount,
    required this.walletId,
  });

  factory PaymentInformation.fromJson(Map<String, dynamic> json) {
    return PaymentInformation(
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      walletId: json['walletId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'walletId': walletId,
    };
  }
}
