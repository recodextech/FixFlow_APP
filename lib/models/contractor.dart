class Contractor {
  final String id;
  final String contractorName;
  final String contractorType;
  final String email;
  final String phoneNumber;
  final String? accountId;
  final String? photoBase64;

  Contractor({
    required this.id,
    required this.contractorName,
    required this.contractorType,
    required this.email,
    required this.phoneNumber,
    this.accountId,
    this.photoBase64,
  });

  factory Contractor.fromJson(Map<String, dynamic> json) {
    return Contractor(
      id: json['id'] ?? '',
      contractorName: json['contractorName'] ?? '',
      contractorType: json['contractorType'] ?? 'COMPANY',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      accountId: json['accountId'],
      photoBase64: json['photoBase64'] as String?,
    );
  }

  Contractor copyWith({
    String? id,
    String? contractorName,
    String? contractorType,
    String? email,
    String? phoneNumber,
    String? accountId,
    String? photoBase64,
  }) {
    return Contractor(
      id: id ?? this.id,
      contractorName: contractorName ?? this.contractorName,
      contractorType: contractorType ?? this.contractorType,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      accountId: accountId ?? this.accountId,
      photoBase64: photoBase64 ?? this.photoBase64,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contractorName': contractorName,
      'contractorType': contractorType,
      'email': email,
      'phoneNumber': phoneNumber,
      'accountId': accountId,
      if (photoBase64 != null && photoBase64!.isNotEmpty)
        'photoBase64': photoBase64,
    };
  }
}
