class PaymentInformation {
  final double amount;
  final String? method;
  final String? walletId;

  PaymentInformation({
    required this.amount,
    this.method,
    this.walletId,
  });

  factory PaymentInformation.fromJson(Map<String, dynamic> json) {
    return PaymentInformation(
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      method: json['method'] as String?,
      walletId: json['walletId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      if (method != null) 'method': method,
      if (walletId != null) 'walletId': walletId,
    };
  }
}
