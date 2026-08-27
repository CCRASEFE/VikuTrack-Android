// ==========================================
// ARCHIVO: lib/repositories/food_budget_repository.dart
// ==========================================

import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/food_budget_day.dart';

class FoodBudgetRepository {
  static const String _defaultLimitKey = 'default_food_daily_limit';

  /// Por defecto el límite diario es S/ 0.00 para no generar arrastres en días inactivos
  Future<int> getDefaultDailyLimit() async {
    final db = await DatabaseHelper.database;
    final results = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [_defaultLimitKey],
      limit: 1,
    );

    if (results.isEmpty || results.first['value'] == null) {
      return 0; // 👈 S/ 0.00 por defecto
    }

    return int.tryParse(results.first['value'] as String) ?? 0;
  }

  Future<void> setDefaultDailyLimit(int limitInCents) async {
    final db = await DatabaseHelper.database;
    await db.insert(
      'settings',
      {'key': _defaultLimitKey, 'value': limitInCents.toString()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

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

  Future<void> saveDayBaseLimit({
    required String date,
    required int dailyLimit,
  }) async {
    final db = await DatabaseHelper.database;
    final now = DateTime.now().toIso8601String();

    await db.rawInsert('''
      INSERT INTO food_budget_days (date, daily_limit, adjustment, created_at, updated_at)
      VALUES (?, ?, 0, ?, ?)
      ON CONFLICT(date) DO UPDATE SET
        daily_limit = excluded.daily_limit,
        updated_at = excluded.updated_at
    ''', [date, dailyLimit, now, now]);
  }

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

  /// Calcula el presupuesto diario y arrastre automático
  Future<Map<String, int>> getDayCalculation(DateTime targetDate) async {
    final db = await DatabaseHelper.database;
    final defaultLimit = await getDefaultDailyLimit();

    final targetDateStr = _formatDateIso(targetDate);
    final yesterday = targetDate.subtract(const Duration(days: 1));
    final yesterdayStr = _formatDateIso(yesterday);

    // 1. Límite base del día objetivo
    final targetDayRow = await db.query(
      'food_budget_days',
      where: 'date = ?',
      whereArgs: [targetDateStr],
      limit: 1,
    );
    final targetBaseLimit = targetDayRow.isNotEmpty
        ? (targetDayRow.first['daily_limit'] as int)
        : defaultLimit;

    // 2. Gasto real del día objetivo
    final targetSpent = await getFoodSpendingByDate(targetDateStr);

    // 3. Límite y gasto de ayer
    final yesterdayDayRow = await db.query(
      'food_budget_days',
      where: 'date = ?',
      whereArgs: [yesterdayStr],
      limit: 1,
    );
    final yesterdayBaseLimit = yesterdayDayRow.isNotEmpty
        ? (yesterdayDayRow.first['daily_limit'] as int)
        : defaultLimit;

    final yesterdaySpent = await getFoodSpendingByDate(yesterdayStr);

    // El arrastre automático solo aplica si ayer tuvo presupuesto configurado o gastos reales
    int autoAdjustment = 0;
    if (yesterdayBaseLimit > 0 || yesterdaySpent > 0 || yesterdayDayRow.isNotEmpty) {
      autoAdjustment = yesterdayBaseLimit - yesterdaySpent;
    }

    final effectiveTargetLimit = targetBaseLimit + autoAdjustment;
    final targetRemaining = effectiveTargetLimit - targetSpent;

    return {
      'baseLimit': targetBaseLimit,
      'autoAdjustment': autoAdjustment,
      'effectiveLimit': effectiveTargetLimit,
      'spent': targetSpent,
      'remaining': targetRemaining,
    };
  }

  String _formatDateIso(DateTime d) {
    final year = d.year.toString();
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}