import 'contractor.dart';
import 'worker.dart';

class UserAccounts {
  final String userId;
  final Worker? worker;
  final Contractor? contractor;

  UserAccounts({
    required this.userId,
    this.worker,
    this.contractor,
  });

  factory UserAccounts.fromJson(Map<String, dynamic> json) {
    return UserAccounts(
      userId: json['userId'] ?? '',
      worker: json['worker'] != null
          ? Worker.fromJson(json['worker'] as Map<String, dynamic>)
          : null,
      contractor: json['contractor'] != null
          ? Contractor.fromJson(json['contractor'] as Map<String, dynamic>)
          : null,
    );
  }

  bool get hasWorker => worker != null;
  bool get hasContractor => contractor != null;
  bool get hasAnyProfile => hasWorker || hasContractor;
}
