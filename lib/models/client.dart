class Client {
  final int? id;
  final String name;
  final String email;
  final String phone;
  final String company;
  final DateTime createdAt;

  Client({
    this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.company,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'company': company,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      phone: map['phone'],
      company: map['company'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Client copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? company,
    DateTime? createdAt,
  }) {
    return Client(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      company: company ?? this.company,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
