// ==========================================
// ARCHIVO: lib/repositories/account_repository.dart
// ==========================================

import '../database/database_helper.dart';
import '../models/account.dart';

class AccountRepository {
  Future<int> insert(Account account) async {
    final db = await DatabaseHelper.database;

    return db.insert(
      'accounts',
      {
        'name': account.name,
        'currency': account.currency,
        'type': account.type,
        'initial_balance': account.initialBalance,
        'active': account.active ? 1 : 0,
        'created_at': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<List<Account>> getAll() async {
    final db = await DatabaseHelper.database;

    final maps = await db.query(
      'accounts',
      orderBy: 'id ASC',
    );

    return maps.map((map) => Account.fromMap(map)).toList();
  }

  Future<List<Account>> getActive() async {
    final db = await DatabaseHelper.database;

    final maps = await db.query(
      'accounts',
      where: 'active = ?',
      whereArgs: [1],
      orderBy: 'id ASC',
    );

    return maps.map((map) => Account.fromMap(map)).toList();
  }

  Future<List<Account>> getInactive() async {
    final db = await DatabaseHelper.database;

    final maps = await db.query(
      'accounts',
      where: 'active = ?',
      whereArgs: [0],
      orderBy: 'id ASC',
    );

    return maps.map((map) => Account.fromMap(map)).toList();
  }

  Future<Account?> getById(int id) async {
    final db = await DatabaseHelper.database;

    final maps = await db.query(
      'accounts',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (resultsIsEmpty(maps)) {
      return null;
    }

    return Account.fromMap(maps.first);
  }

  bool resultsIsEmpty(List<Map<String, Object?>> maps) => maps.isEmpty;

  Future<int> update(Account account) async {
    if (account.id == null) {
      throw ArgumentError('No se puede actualizar una cuenta sin ID.');
    }

    final db = await DatabaseHelper.database;

    return db.update(
      'accounts',
      {
        'name': account.name,
        'currency': account.currency,
        'type': account.type,
        'initial_balance': account.initialBalance,
        'active': account.active ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<int> deactivate(int id) async {
    final db = await DatabaseHelper.database;

    return db.update(
      'accounts',
      {'active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> activate(int id) async {
    final db = await DatabaseHelper.database;

    return db.update(
      'accounts',
      {'active': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<bool> hasMovements(int accountId) async {
    final db = await DatabaseHelper.database;

    final payments = await db.rawQuery('''
      SELECT 1 FROM transaction_payments tp
      INNER JOIN payment_methods pm ON tp.payment_method_id = pm.id
      WHERE pm.account_id = ?
      LIMIT 1
    ''', [accountId]);

    if (payments.isNotEmpty) return true;

    final reservations = await db.query(
      'reservations',
      where: 'account_id = ?',
      whereArgs: [accountId],
      limit: 1,
    );

    return reservations.isNotEmpty;
  }

  Future<void> delete(int id) async {
    final db = await DatabaseHelper.database;

    await db.transaction((txn) async {
      await txn.delete(
        'payment_methods',
        where: 'account_id = ?',
        whereArgs: [id],
      );
      await txn.delete(
        'accounts',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  /// MOTOR DE SALDO: Calcula Total, Reservado y Saldo Libre Disponible
  Future<Map<String, int>> getBalanceDetails(int accountId) async {
    final db = await DatabaseHelper.database;

    final account = await getById(accountId);
    if (account == null) {
      return {'initial': 0, 'in': 0, 'out': 0, 'total': 0, 'reserved': 0, 'free': 0, 'current': 0};
    }

    // 1. Entradas y Salidas
    final results = await db.rawQuery('''
      SELECT
        COALESCE(SUM(CASE WHEN tp.direction = 'in' THEN tp.amount ELSE 0 END), 0) AS total_in,
        COALESCE(SUM(CASE WHEN tp.direction = 'out' THEN tp.amount ELSE 0 END), 0) AS total_out
      FROM transaction_payments tp
      INNER JOIN transactions t ON tp.transaction_id = t.id
      INNER JOIN payment_methods pm ON tp.payment_method_id = pm.id
      WHERE pm.account_id = ? AND t.active = 1
    ''', [accountId]);

    // 2. Total Reservado en esta cuenta
    final reservationResults = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) AS total_reserved
      FROM reservations
      WHERE account_id = ? AND active = 1
    ''', [accountId]);

    final totalIn = (results.first['total_in'] as num?)?.toInt() ?? 0;
    final totalOut = (results.first['total_out'] as num?)?.toInt() ?? 0;
    final totalBalance = account.initialBalance + totalIn - totalOut;
    final totalReserved = (reservationResults.first['total_reserved'] as num?)?.toInt() ?? 0;
    final freeBalance = totalBalance - totalReserved;

    return {
      'initial': account.initialBalance,
      'in': totalIn,
      'out': totalOut,
      'total': totalBalance,
      'reserved': totalReserved,
      'free': freeBalance,
      'current': totalBalance, // Total contable
    };
  }
}