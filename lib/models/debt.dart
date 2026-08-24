// ==========================================
// ARCHIVO: lib/models/debt.dart
// ==========================================

class Debt {
  final int? id;
  final String description;
  final int originalAmount; // En centavos
  final String currency;
  final String date;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Debt({
    this.id,
    required this.description,
    required this.originalAmount,
    required this.currency,
    required this.date,
    this.active = true,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, Object?> toMap() {
    final now = DateTime.now().toIso8601String();
    return {
      'id': id,
      'description': description,
      'original_amount': originalAmount,
      'currency': currency,
      'date': date,
      'active': active ? 1 : 0,
      'created_at': createdAt?.toIso8601String() ?? now,
      'updated_at': updatedAt?.toIso8601String() ?? now,
    };
  }

  factory Debt.fromMap(Map<String, Object?> map) {
    return Debt(
      id: map['id'] as int?,
      description: map['description'] as String,
      originalAmount: map['original_amount'] as int,
      currency: map['currency'] as String,
      date: map['date'] as String,
      active: (map['active'] as int) == 1,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? ''),
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? ''),
    );
  }
}

class DebtPayment {
  final int? id;
  final int debtId;
  final int transactionId;
  final int amount;

  const DebtPayment({
    this.id,
    required this.debtId,
    required this.transactionId,
    required this.amount,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'debt_id': debtId,
      'transaction_id': transactionId,
      'amount': amount,
    };
  }

  factory DebtPayment.fromMap(Map<String, Object?> map) {
    return DebtPayment(
      id: map['id'] as int?,
      debtId: map['debt_id'] as int,
      transactionId: map['transaction_id'] as int,
      amount: map['amount'] as int,
    );
  }
}