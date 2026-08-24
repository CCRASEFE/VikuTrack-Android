// lib/repositories/payment_method_repository.dart
import '../database/database_helper.dart';

class PaymentMethodRepository {
  Future<int> insert({required int accountId, required String name}) async {
    final db = await DatabaseHelper.database;

    return db.insert('payment_methods', {
      'account_id': accountId,
      'name': name,
      'active': 1,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, Object?>>> getByAccount(int accountId) async {
    final db = await DatabaseHelper.database;

    return db.query(
      'payment_methods',
      where: 'account_id = ? AND active = 1',
      whereArgs: [accountId],
      orderBy: 'id ASC',
    );
  }

  Future<int> deactivate(int id) async {
    final db = await DatabaseHelper.database;

    return db.update(
      'payment_methods',
      {'active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, Object?>>> getInactiveByAccount(int accountId) async {
    final db = await DatabaseHelper.database;

    return db.query(
      'payment_methods',
      where: 'account_id = ? AND active = 0',
      whereArgs: [accountId],
      orderBy: 'id ASC',
    );
  }

  Future<int> activate(int id) async {
    final db = await DatabaseHelper.database;

    return db.update(
      'payment_methods',
      {'active': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int?> getAccountId(int paymentMethodId) async {
    final db = await DatabaseHelper.database;

    final results = await db.query(
      'payment_methods',
      columns: ['account_id'],
      where: 'id = ?',
      whereArgs: [paymentMethodId],
      limit: 1,
    );

    if (results.isEmpty) {
      return null;
    }

    return results.first['account_id'] as int?;
  }

  /// Comprueba si este medio de pago ha sido usado en alguna transacción
  Future<bool> hasMovements(int paymentMethodId) async {
    final db = await DatabaseHelper.database;

    final result = await db.query(
      'transaction_payments',
      where: 'payment_method_id = ?',
      whereArgs: [paymentMethodId],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  /// Borrado físico definitivo
  Future<int> delete(int id) async {
    final db = await DatabaseHelper.database;

    return db.delete(
      'payment_methods',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}