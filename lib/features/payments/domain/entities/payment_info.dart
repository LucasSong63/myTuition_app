// lib/features/payments/domain/entities/payment_info.dart

import 'package:equatable/equatable.dart';

class BankAccount extends Equatable {
  final String id;
  final String name;
  final String accountNumber;
  final String accountHolder;
  final bool isActive;

  const BankAccount({
    required this.id,
    required this.name,
    required this.accountNumber,
    required this.accountHolder,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [id, name, accountNumber, accountHolder, isActive];

  BankAccount copyWith({
    String? id,
    String? name,
    String? accountNumber,
    String? accountHolder,
    bool? isActive,
  }) {
    return BankAccount(
      id: id ?? this.id,
      name: name ?? this.name,
      accountNumber: accountNumber ?? this.accountNumber,
      accountHolder: accountHolder ?? this.accountHolder,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'accountNumber': accountNumber,
      'accountHolder': accountHolder,
      'isActive': isActive,
    };
  }

  factory BankAccount.fromMap(Map<String, dynamic> map) {
    return BankAccount(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      accountNumber: map['accountNumber'] ?? '',
      accountHolder: map['accountHolder'] ?? '',
      isActive: map['isActive'] ?? true,
    );
  }
}

class EWallet extends Equatable {
  final String id;
  final String type;
  final String number;
  final String name;
  final bool isActive;

  const EWallet({
    required this.id,
    required this.type,
    required this.number,
    required this.name,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [id, type, number, name, isActive];

  EWallet copyWith({
    String? id,
    String? type,
    String? number,
    String? name,
    bool? isActive,
  }) {
    return EWallet(
      id: id ?? this.id,
      type: type ?? this.type,
      number: number ?? this.number,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'number': number,
      'name': name,
      'isActive': isActive,
    };
  }

  factory EWallet.fromMap(Map<String, dynamic> map) {
    return EWallet(
      id: map['id'] ?? '',
      type: map['type'] ?? '',
      number: map['number'] ?? '',
      name: map['name'] ?? '',
      isActive: map['isActive'] ?? true,
    );
  }
}

class OtherPaymentMethod extends Equatable {
  final String id;
  final String name;
  final String details;
  final bool isActive;

  const OtherPaymentMethod({
    required this.id,
    required this.name,
    required this.details,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [id, name, details, isActive];

  OtherPaymentMethod copyWith({
    String? id,
    String? name,
    String? details,
    bool? isActive,
  }) {
    return OtherPaymentMethod(
      id: id ?? this.id,
      name: name ?? this.name,
      details: details ?? this.details,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'details': details,
      'isActive': isActive,
    };
  }

  factory OtherPaymentMethod.fromMap(Map<String, dynamic> map) {
    return OtherPaymentMethod(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      details: map['details'] ?? '',
      isActive: map['isActive'] ?? true,
    );
  }
}

class PaymentInfo extends Equatable {
  final List<BankAccount> bankAccounts;
  final List<EWallet> eWallets;
  final List<OtherPaymentMethod> otherMethods;
  final String additionalInfo;

  const PaymentInfo({
    this.bankAccounts = const [],
    this.eWallets = const [],
    this.otherMethods = const [],
    this.additionalInfo = '',
  });

  @override
  List<Object?> get props =>
      [bankAccounts, eWallets, otherMethods, additionalInfo];

  PaymentInfo copyWith({
    List<BankAccount>? bankAccounts,
    List<EWallet>? eWallets,
    List<OtherPaymentMethod>? otherMethods,
    String? additionalInfo,
  }) {
    return PaymentInfo(
      bankAccounts: bankAccounts ?? this.bankAccounts,
      eWallets: eWallets ?? this.eWallets,
      otherMethods: otherMethods ?? this.otherMethods,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bankAccounts': bankAccounts.map((account) => account.toMap()).toList(),
      'eWallets': eWallets.map((wallet) => wallet.toMap()).toList(),
      'otherMethods': otherMethods.map((method) => method.toMap()).toList(),
      'additionalInfo': additionalInfo,
    };
  }

  factory PaymentInfo.fromMap(Map<String, dynamic> map) {
    return PaymentInfo(
      bankAccounts: map['bankAccounts'] != null
          ? List<BankAccount>.from(
              (map['bankAccounts'] as List).map((x) => BankAccount.fromMap(x)))
          : [],
      eWallets: map['eWallets'] != null
          ? List<EWallet>.from(
              (map['eWallets'] as List).map((x) => EWallet.fromMap(x)))
          : [],
      otherMethods: map['otherMethods'] != null
          ? List<OtherPaymentMethod>.from((map['otherMethods'] as List)
              .map((x) => OtherPaymentMethod.fromMap(x)))
          : [],
      additionalInfo: map['additionalInfo'] ?? '',
    );
  }
}
