import '../../domain/entities/bank.dart';

class BankModel extends Bank {
  const BankModel({
    required super.id,
    required super.name,
    super.accountNumber,
    super.isSubmitted = false,
  });

  factory BankModel.fromJson(Map<String, dynamic> json) {
    return BankModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      accountNumber: (json['accountNumber'] as String?)?.trim().isEmpty == true
          ? null
          : (json['accountNumber'] as String?),
      isSubmitted: (json['isSubmitted'] as bool?) ?? false,
    );
  }

  BankModel copyWith({
    String? id,
    String? name,
    String? accountNumber,
    bool? isSubmitted,
  }) {
    return BankModel(
      id: id ?? this.id,
      name: name ?? this.name,
      accountNumber: accountNumber ?? this.accountNumber,
      isSubmitted: isSubmitted ?? this.isSubmitted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'accountNumber': accountNumber,
      'isSubmitted': isSubmitted,
    };
  }
}

