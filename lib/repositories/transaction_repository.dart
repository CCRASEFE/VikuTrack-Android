// ==========================================
// ARCHIVO: lib/repositories/transaction_repository.dart
// ==========================================

import '../database/database_helper.dart';
import '../models/transaction.dart';

class TransactionRepository {
  Future<int> insert(Transaction transaction) async {
    final db = await DatabaseHelper.database;
    final now = DateTime.now().toIso8601String();

    return db.insert('transactions', {
      'type': transaction.type.dbValue,
      'date': transaction.date.toIso8601String().split('T').first,
      'time': transaction.date
          .toIso8601String()
          .split('T')
          .last
          .split('.')
          .first,
      'description': transaction.description,
      'active': 1,
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<Map<String, Object?>?> getById(int id) async {
    final db = await DatabaseHelper.database;

    final results = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) {
      return null;
    }

    return results.first;
  }

  Future<List<Map<String, Object?>>> getAll() async {
    final db = await DatabaseHelper.database;

    return db.query(
      'transactions',
      where: 'active = ?',
      whereArgs: [1],
      orderBy: 'date DESC, time DESC, id DESC',
    );
  }

  Future<List<Map<String, Object?>>> getAllWithDetails({String? typeFilter}) async {
    final db = await DatabaseHelper.database;

    String whereClause = 'WHERE t.active = 1';
    final List<Object?> whereArgs = [];

    if (typeFilter != null && typeFilter.isNotEmpty && typeFilter != 'all') {
      whereClause += ' AND t.type = ?';
      whereArgs.add(typeFilter);
    }

    return db.rawQuery('''
      SELECT
        t.id,
        t.type,
        t.date,
        t.time,
        t.description,
        (
          SELECT COALESCE(amount, 0)
          FROM transaction_payments
          WHERE transaction_id = t.id
          LIMIT 1
        ) AS amount,
        (
          SELECT a.currency
          FROM transaction_payments tp
          INNER JOIN payment_methods pm ON tp.payment_method_id = pm.id
          INNER JOIN accounts a ON pm.account_id = a.id
          WHERE tp.transaction_id = t.id
          LIMIT 1
        ) AS currency,
        (
          SELECT c.name
          FROM transaction_items ti
          INNER JOIN categories c ON ti.category_id = c.id
          WHERE ti.transaction_id = t.id
          LIMIT 1
        ) AS category_name,
        (
          SELECT s.name
          FROM transaction_items ti
          INNER JOIN subcategories s ON ti.subcategory_id = s.id
          WHERE ti.transaction_id = t.id
          LIMIT 1
        ) AS subcategory_name,
        (
          SELECT a.name
          FROM transaction_payments tp
          INNER JOIN payment_methods pm ON tp.payment_method_id = pm.id
          INNER JOIN accounts a ON pm.account_id = a.id
          WHERE tp.transaction_id = t.id
          LIMIT 1
        ) AS account_name
      FROM transactions t
      $whereClause
      ORDER BY t.date DESC, t.time DESC, t.id DESC
    ''', whereArgs);
  }

  Future<List<Map<String, Object?>>> getRecent({int limit = 5}) async {
    final db = await DatabaseHelper.database;

    return db.query(
      'transactions',
      where: 'active = ?',
      whereArgs: [1],
      orderBy: 'date DESC, time DESC, id DESC',
      limit: limit,
    );
  }

  Future<Map<String, int>> getMonthlyTotals({
    required int year,
    required int month,
  }) async {
    final db = await DatabaseHelper.database;

    final startMonth = month.toString().padLeft(2, '0');
    final startDate = '$year-$startMonth-01';
    final lastDay = DateTime(year, month + 1, 0).day;
    final endDate = '$year-$startMonth-$lastDay';

    final results = await db.rawQuery('''
      SELECT
        t.type,
        a.currency,
        COALESCE(SUM(tp.amount), 0) AS total
      FROM transactions t
      INNER JOIN transaction_payments tp ON t.id = tp.transaction_id
      INNER JOIN payment_methods pm ON tp.payment_method_id = pm.id
      INNER JOIN accounts a ON pm.account_id = a.id
      WHERE t.active = 1
        AND t.date >= ? AND t.date <= ?
        AND t.type IN ('income', 'expense')
      GROUP BY t.type, a.currency
    ''', [startDate, endDate]);

    int expensePEN = 0;
    int incomePEN = 0;
    int expenseUSD = 0;
    int incomeUSD = 0;

    for (final row in results) {
      final type = row['type'] as String;
      final currency = row['currency'] as String;
      final total = (row['total'] as num?)?.toInt() ?? 0;

      if (currency == 'PEN') {
        if (type == 'expense') expensePEN += total;
        if (type == 'income') incomePEN += total;
      } else if (currency == 'USD') {
        if (type == 'expense') expenseUSD += total;
        if (type == 'income') incomeUSD += total;
      }
    }

    return {
      'expensePEN': expensePEN,
      'incomePEN': incomePEN,
      'expenseUSD': expenseUSD,
      'incomeUSD': incomeUSD,
    };
  }

  Future<List<Map<String, Object?>>> getItems(int transactionId) async {
    final db = await DatabaseHelper.database;

    return db.query(
      'transaction_items',
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
      orderBy: 'id ASC',
    );
  }

  Future<List<Map<String, Object?>>> getPayments(int transactionId) async {
    final db = await DatabaseHelper.database;

    return db.query(
      'transaction_payments',
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
      orderBy: 'id ASC',
    );
  }

  Future<Map<String, Object?>?> getItem(int transactionId) async {
    final db = await DatabaseHelper.database;

    final results = await db.query(
      'transaction_items',
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
      limit: 1,
    );

    if (results.isEmpty) {
      return null;
    }

    return results.first;
  }

  Future<Map<String, Object?>?> getPayment(int transactionId) async {
    final db = await DatabaseHelper.database;

    final results = await db.query(
      'transaction_payments',
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
      limit: 1,
    );

    if (results.isEmpty) {
      return null;
    }

    return results.first;
  }

  Future<void> updateTransaction({
    required int id,
    required Transaction transaction,
  }) async {
    final db = await DatabaseHelper.database;

    await db.update(
      'transactions',
      {
        'type': transaction.type.dbValue,
        'date': transaction.date.toIso8601String().split('T').first,
        'time': transaction.date
            .toIso8601String()
            .split('T')
            .last
            .split('.')
            .first,
        'description': transaction.description,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> replaceItems({
    required int transactionId,
    required List<Map<String, Object?>> items,
  }) async {
    final db = await DatabaseHelper.database;

    await db.delete(
      'transaction_items',
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
    );

    for (final item in items) {
      await db.insert('transaction_items', {
        'transaction_id': transactionId,
        'category_id': item['category_id'],
        'subcategory_id': item['subcategory_id'],
        'amount': item['amount'],
        'count_for_food_control': item['count_for_food_control'] ?? 0,
      });
    }
  }

  Future<void> replacePayments({
    required int transactionId,
    required List<Map<String, Object?>> payments,
  }) async {
    final db = await DatabaseHelper.database;

    await db.delete(
      'transaction_payments',
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
    );

    for (final payment in payments) {
      await db.insert('transaction_payments', {
        'transaction_id': transactionId,
        'payment_method_id': payment['payment_method_id'],
        'amount': payment['amount'],
        'direction': payment['direction'] ?? 'out',
      });
    }
  }

  Future<void> delete(int id) async {
    final db = await DatabaseHelper.database;

    await db.transaction((txn) async {
      await txn.delete('debt_payments', where: 'transaction_id = ?', whereArgs: [id]);
      await txn.delete('transactions', where: 'id = ?', whereArgs: [id]);
    });
  }
}