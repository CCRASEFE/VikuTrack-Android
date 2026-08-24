// ==========================================
// ARCHIVO: lib/repositories/debt_repository.dart
// ==========================================

import '../database/database_helper.dart';
import '../models/debt.dart';
import 'account_repository.dart';

class DebtRepository {
  final _accountRepository = AccountRepository();

  Future<int> insertDebt(Debt debt) async {
    final db = await DatabaseHelper.database;
    return db.insert('debts', debt.toMap());
  }

  Future<List<Map<String, Object?>>> getActiveDebtsWithProgress() async {
    final db = await DatabaseHelper.database;

    final results = await db.rawQuery('''
      SELECT
        d.*,
        COALESCE(
          (
            SELECT SUM(dp.amount)
            FROM debt_payments dp
            INNER JOIN transactions t ON dp.transaction_id = t.id
            WHERE dp.debt_id = d.id AND t.active = 1
          ),
          0
        ) AS paid_amount
      FROM debts d
      WHERE d.active = 1
      ORDER BY d.id DESC
    ''');

    return results;
  }

  Future<Debt?> getDebtById(int id) async {
    final db = await DatabaseHelper.database;
    final results = await db.query(
      'debts',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return Debt.fromMap(results.first);
  }

  Future<void> registerPayment({
    required int debtId,
    required int amount,
    required int accountId,
    required int paymentMethodId,
    required String date,
    String? note,
  }) async {
    // Validar fondos suficientes en la cuenta de origen
    final account = await _accountRepository.getById(accountId);
    final balanceDetails = await _accountRepository.getBalanceDetails(accountId);
    final currentBalance = balanceDetails['current'] ?? 0;

    if (currentBalance < amount) {
      final accountName = account?.name ?? 'Cuenta';
      final currency = account?.currency ?? 'PEN';
      final dispStr = currency == 'USD'
          ? '\$${(currentBalance / 100).toStringAsFixed(2)}'
          : 'S/ ${(currentBalance / 100).toStringAsFixed(2)}';
      final reqStr = currency == 'USD'
          ? '\$${(amount / 100).toStringAsFixed(2)}'
          : 'S/ ${(amount / 100).toStringAsFixed(2)}';

      throw ArgumentError(
        'Fondos insuficientes en "$accountName": Saldo disponible $dispStr, intentas pagar $reqStr.',
      );
    }

    final db = await DatabaseHelper.database;

    await db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      final time = now.split('T').last.split('.').first;

      final transactionId = await txn.insert('transactions', {
        'type': 'debt_payment',
        'date': date,
        'time': time,
        'description': note?.isNotEmpty == true ? note : 'Pago de deuda',
        'active': 1,
        'created_at': now,
        'updated_at': now,
      });

      await txn.insert('transaction_payments', {
        'transaction_id': transactionId,
        'payment_method_id': paymentMethodId,
        'amount': amount,
        'direction': 'out',
      });

      await txn.insert('debt_payments', {
        'debt_id': debtId,
        'transaction_id': transactionId,
        'amount': amount,
      });
    });
  }

  Future<List<Map<String, Object?>>> getPaymentHistory(int debtId) async {
    final db = await DatabaseHelper.database;

    return db.rawQuery('''
      SELECT
        dp.id AS payment_id,
        dp.amount,
        t.date,
        t.time,
        t.description,
        a.name AS account_name,
        pm.name AS payment_method_name
      FROM debt_payments dp
      INNER JOIN transactions t ON dp.transaction_id = t.id
      INNER JOIN transaction_payments tp ON t.id = tp.transaction_id
      INNER JOIN payment_methods pm ON tp.payment_method_id = pm.id
      INNER JOIN accounts a ON pm.account_id = a.id
      WHERE dp.debt_id = ? AND t.active = 1
      ORDER BY t.date DESC, t.time DESC
    ''', [debtId]);
  }

  Future<int> updateDebt(Debt debt) async {
    if (debt.id == null) {
      throw ArgumentError('No se puede actualizar una deuda sin ID.');
    }

    final db = await DatabaseHelper.database;
    return db.update(
      'debts',
      {
        'description': debt.description,
        'original_amount': debt.originalAmount,
        'currency': debt.currency,
        'date': debt.date,
        'active': debt.active ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [debt.id],
    );
  }

  Future<void> deleteDebt(int id) async {
    final db = await DatabaseHelper.database;

    final payments = await db.query(
      'debt_payments',
      where: 'debt_id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (payments.isEmpty) {
      await db.delete('debts', where: 'id = ?', whereArgs: [id]);
    } else {
      await db.update('debts', {'active': 0}, where: 'id = ?', whereArgs: [id]);
    }
  }

  Future<Map<String, int>> getTotalPendingDebtsByCurrency() async {
    final debts = await getActiveDebtsWithProgress();

    int pen = 0;
    int usd = 0;

    for (final d in debts) {
      final currency = d['currency'] as String;
      final original = d['original_amount'] as int;
      final paid = (d['paid_amount'] as num?)?.toInt() ?? 0;
      final pending = original - paid;

      if (pending > 0) {
        if (currency == 'PEN') pen += pending;
        if (currency == 'USD') usd += pending;
      }
    }

    return {'PEN': pen, 'USD': usd};
  }
}