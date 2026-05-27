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
  final String? photoBase64;

  List<String> get categories => workerCategories;

  Worker({
    required this.id,
    required this.workerName,
    required this.email,
    required this.phoneNumber,
    required this.workerCategories,
    this.accountId,
    this.photoBase64,
  });

  factory Worker.fromJson(Map<String, dynamic> json) {
    final categoryList =
        (json['workerCategories'] ?? json['categories'] ?? []) as List<dynamic>;

    return Worker(
      id: json['id'] ?? '',
      workerName: json['workerName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      workerCategories: categoryList.map((item) => item.toString()).toList(),
      accountId: json['accountId'],
      photoBase64: json['photoBase64'] as String?,
    );
  }

  Worker copyWith({
    String? id,
    String? workerName,
    String? email,
    String? phoneNumber,
    List<String>? workerCategories,
    String? accountId,
    String? photoBase64,
  }) {
    return Worker(
      id: id ?? this.id,
      workerName: workerName ?? this.workerName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      workerCategories: workerCategories ?? this.workerCategories,
      accountId: accountId ?? this.accountId,
      photoBase64: photoBase64 ?? this.photoBase64,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workerName': workerName,
      'email': email,
      'phoneNumber': phoneNumber,
      'workerCategories': workerCategories,
      'categories': workerCategories,
      'accountId': accountId,
      if (photoBase64 != null && photoBase64!.isNotEmpty)
        'photoBase64': photoBase64,
    };
  }
}
