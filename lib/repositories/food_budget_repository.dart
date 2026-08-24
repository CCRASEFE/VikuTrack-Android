// ==========================================
// ARCHIVO: lib/repositories/food_budget_repository.dart
// ==========================================

import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/food_budget_day.dart';

class FoodBudgetRepository {
  static const String _defaultLimitKey = 'default_food_daily_limit';

  /// Obtiene el límite diario estándar configurado en settings (por defecto S/ 30.00 = 3000)
  Future<int> getDefaultDailyLimit() async {
    final db = await DatabaseHelper.database;
    final results = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [_defaultLimitKey],
      limit: 1,
    );

    if (results.isEmpty || results.first['value'] == null) {
      return 3000; // S/ 30.00 por defecto
    }

    return int.tryParse(results.first['value'] as String) ?? 3000;
  }

  /// Guarda el límite diario predeterminado
  Future<void> setDefaultDailyLimit(int limitInCents) async {
    final db = await DatabaseHelper.database;
    await db.insert(
      'settings',
      {'key': _defaultLimitKey, 'value': limitInCents.toString()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Obtiene o inicializa la configuración de un día específico
  Future<FoodBudgetDay> getDay(String date) async {
    final db = await DatabaseHelper.database;
    final results = await db.query(
      'food_budget_days',
      where: 'date = ?',
      whereArgs: [date],
      limit: 1,
    );

    if (results.isNotEmpty) {
      return FoodBudgetDay.fromMap(results.first);
    }

    final defaultLimit = await getDefaultDailyLimit();
    return FoodBudgetDay(date: date, dailyLimit: defaultLimit, adjustment: 0);
  }

  /// Guarda o actualiza el límite y ajuste de un día
  Future<void> saveDay({
    required String date,
    required int dailyLimit,
    required int adjustment,
  }) async {
    final db = await DatabaseHelper.database;
    final now = DateTime.now().toIso8601String();

    await db.rawInsert('''
      INSERT INTO food_budget_days (date, daily_limit, adjustment, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?)
      ON CONFLICT(date) DO UPDATE SET
        daily_limit = excluded.daily_limit,
        adjustment = excluded.adjustment,
        updated_at = excluded.updated_at
    ''', [date, dailyLimit, adjustment, now, now]);
  }

  /// Suma de todos los gastos de alimentación en una fecha determinada
  Future<int> getFoodSpendingByDate(String date) async {
    final db = await DatabaseHelper.database;
    final results = await db.rawQuery('''
      SELECT COALESCE(SUM(ti.amount), 0) AS total_spent
      FROM transaction_items ti
      INNER JOIN transactions t ON ti.transaction_id = t.id
      WHERE t.active = 1
        AND t.date = ?
        AND ti.count_for_food_control = 1
    ''', [date]);

    return (results.first['total_spent'] as num?)?.toInt() ?? 0;
  }

  /// Obtiene la lista de transacciones que cuentan para comida en una fecha
  Future<List<Map<String, Object?>>> getFoodTransactionsByDate(String date) async {
    final db = await DatabaseHelper.database;
    return db.rawQuery('''
      SELECT
        t.id,
        t.description,
        t.time,
        ti.amount,
        c.name AS category_name,
        s.name AS subcategory_name
      FROM transaction_items ti
      INNER JOIN transactions t ON ti.transaction_id = t.id
      LEFT JOIN categories c ON ti.category_id = c.id
      LEFT JOIN subcategories s ON ti.subcategory_id = s.id
      WHERE t.active = 1
        AND t.date = ?
        AND ti.count_for_food_control = 1
      ORDER BY t.time DESC, t.id DESC
    ''', [date]);
  }
}