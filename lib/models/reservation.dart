// ==========================================
// ARCHIVO: lib/models/reservation.dart
// ==========================================

class Reservation {
  final int? id;
  final int accountId;
  final String name;
  final int amount; // Entero en centavos
  final String currency;
  final String? reason;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Reservation({
    this.id,
    required this.accountId,
    required this.name,
    required this.amount,
    required this.currency,
    this.reason,
    this.active = true,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, Object?> toMap() {
    final now = DateTime.now().toIso8601String();
    return {
      'id': id,
      'account_id': accountId,
      'name': name,
      'amount': amount,
      'currency': currency,
      'reason': reason,
      'active': active ? 1 : 0,
      'created_at': createdAt?.toIso8601String() ?? now,
      'updated_at': updatedAt?.toIso8601String() ?? now,
    };
  }

  factory Reservation.fromMap(Map<String, Object?> map) {
    return Reservation(
      id: map['id'] as int?,
      accountId: map['account_id'] as int,
      name: map['name'] as String,
      amount: map['amount'] as int,
      currency: map['currency'] as String,
      reason: map['reason'] as String?,
      active: (map['active'] as int) == 1,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? ''),
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? ''),
    );
  }
}