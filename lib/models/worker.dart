class Category {
  final String id;
  final String name;

  Category({
    required this.id,
    required this.name,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class Worker {
  final String id;
  final String workerName;
  final String email;
  final String phoneNumber;
  final List<String> workerCategories;
  final String? accountId;

  Worker({
    required this.id,
    required this.workerName,
    required this.email,
    required this.phoneNumber,
    required this.workerCategories,
    this.accountId,
  });

  factory Worker.fromJson(Map<String, dynamic> json) {
    return Worker(
      id: json['id'] ?? '',
      workerName: json['workerName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      workerCategories: List<String>.from(json['workerCategories'] ?? []),
      accountId: json['accountId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workerName': workerName,
      'email': email,
      'phoneNumber': phoneNumber,
      'workerCategories': workerCategories,
      'accountId': accountId,
    };
  }
}
