// ==========================================
// ARCHIVO: lib/repositories/planned_purchase_repository.dart
// ==========================================

import '../database/database_helper.dart';
import '../models/planned_purchase.dart';

class PlannedPurchaseRepository {
  Future<int> insert(PlannedPurchase purchase) async {
    final db = await DatabaseHelper.database;
    return db.insert('planned_purchases', purchase.toMap());
  }

  Future<List<PlannedPurchase>> getActive() async {
    final db = await DatabaseHelper.database;
    final results = await db.query(
      'planned_purchases',
      where: 'active = 1',
      orderBy: 'id DESC',
    );

    return results.map((m) => PlannedPurchase.fromMap(m)).toList();
  }

  Future<int> update(PlannedPurchase purchase) async {
    if (purchase.id == null) {
      throw ArgumentError('No se puede actualizar sin ID.');
    }

    final db = await DatabaseHelper.database;
    return db.update(
      'planned_purchases',
      {
        'name': purchase.name,
        'amount': purchase.amount,
        'currency': purchase.currency,
        'note': purchase.note,
        'active': purchase.active ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [purchase.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await DatabaseHelper.database;
    return db.delete('planned_purchases', where: 'id = ?', whereArgs: [id]);
  }

  /// Suma total proyectada por comprar por moneda
  Future<Map<String, int>> getTotalEstimatedByCurrency() async {
    final db = await DatabaseHelper.database;
    final results = await db.rawQuery('''
      SELECT
        currency,
        COALESCE(SUM(amount), 0) AS total
      FROM planned_purchases
      WHERE active = 1
      GROUP BY currency
    ''');

    int pen = 0;
    int usd = 0;

    for (final row in results) {
      final currency = row['currency'] as String;
      final total = (row['total'] as num?)?.toInt() ?? 0;
      if (currency == 'PEN') pen = total;
      if (currency == 'USD') usd = total;
    }

    return {'PEN': pen, 'USD': usd};
  }
}