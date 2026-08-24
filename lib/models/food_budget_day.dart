// ==========================================
// ARCHIVO: lib/models/food_budget_day.dart
// ==========================================

class FoodBudgetDay {
  final int? id;
  final String date; // Formato YYYY-MM-DD
  final int dailyLimit; // En centavos
  final int adjustment; // En centavos (+ o -)
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const FoodBudgetDay({
    this.id,
    required this.date,
    required this.dailyLimit,
    this.adjustment = 0,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, Object?> toMap() {
    final now = DateTime.now().toIso8601String();
    return {
      'id': id,
      'date': date,
      'daily_limit': dailyLimit,
      'adjustment': adjustment,
      'created_at': createdAt?.toIso8601String() ?? now,
      'updated_at': updatedAt?.toIso8601String() ?? now,
    };
  }

  factory FoodBudgetDay.fromMap(Map<String, Object?> map) {
    return FoodBudgetDay(
      id: map['id'] as int?,
      date: map['date'] as String,
      dailyLimit: map['daily_limit'] as int,
      adjustment: map['adjustment'] as int? ?? 0,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? ''),
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? ''),
    );
  }
}