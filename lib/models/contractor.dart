class Contractor {
  final String id;
  final String contractorName;
  final String contractorType;
  final String email;
  final String phoneNumber;
  final String? accountId;

  Contractor({
    required this.id,
    required this.contractorName,
    required this.contractorType,
    required this.email,
    required this.phoneNumber,
    this.accountId,
  });

  factory Contractor.fromJson(Map<String, dynamic> json) {
    return Contractor(
      id: json['id'] ?? '',
      contractorName: json['contractorName'] ?? '',
      contractorType: json['contractorType'] ?? 'COMPANY',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      accountId: json['accountId'],
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
    };
  }
}
