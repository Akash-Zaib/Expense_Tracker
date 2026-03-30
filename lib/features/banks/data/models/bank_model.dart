import '../../domain/entities/bank.dart';

class BankModel extends Bank {
  const BankModel({
    required super.id,
    required super.name,
    super.accountNumber,
    super.isSubmitted = false,
    super.ownerUid = '',
    super.ownerName = '',
  });

  factory BankModel.fromJson(Map<String, dynamic> json) {
    return BankModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      accountNumber: (json['accountNumber'] as String?)?.trim().isEmpty == true
          ? null
          : (json['accountNumber'] as String?),
      isSubmitted: (json['isSubmitted'] as bool?) ?? false,
      ownerUid: (json['ownerUid'] ?? '').toString(),
      ownerName: (json['ownerName'] ?? '').toString(),
    );
  }

  BankModel copyWith({
    String? id,
    String? name,
    String? accountNumber,
    bool? isSubmitted,
    String? ownerUid,
    String? ownerName,
  }) {
    return BankModel(
      id: id ?? this.id,
      name: name ?? this.name,
      accountNumber: accountNumber ?? this.accountNumber,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      ownerUid: ownerUid ?? this.ownerUid,
      ownerName: ownerName ?? this.ownerName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'accountNumber': accountNumber,
      'isSubmitted': isSubmitted,
      'ownerUid': ownerUid,
      'ownerName': ownerName,
    };
  }
}

