// ==========================================
// ARCHIVO: lib/models/planned_purchase.dart
// ==========================================

class PlannedPurchase {
  final int? id;
  final String name;
  final int amount; // En centavos
  final String currency;
  final String? note;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PlannedPurchase({
    this.id,
    required this.name,
    required this.amount,
    required this.currency,
    this.note,
    this.active = true,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, Object?> toMap() {
    final now = DateTime.now().toIso8601String();
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'currency': currency,
      'note': note,
      'active': active ? 1 : 0,
      'created_at': createdAt?.toIso8601String() ?? now,
      'updated_at': updatedAt?.toIso8601String() ?? now,
    };
  }

  factory PlannedPurchase.fromMap(Map<String, Object?> map) {
    return PlannedPurchase(
      id: map['id'] as int?,
      name: map['name'] as String,
      amount: map['amount'] as int,
      currency: map['currency'] as String,
      note: map['note'] as String?,
      active: (map['active'] as int) == 1,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? ''),
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? ''),
    );
  }
}