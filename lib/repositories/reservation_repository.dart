// ==========================================
// ARCHIVO: lib/repositories/reservation_repository.dart
// ==========================================

import '../database/database_helper.dart';
import '../models/reservation.dart';

class ReservationRepository {
  Future<int> insert(Reservation reservation) async {
    final db = await DatabaseHelper.database;
    return db.insert('reservations', reservation.toMap());
  }

  /// Obtiene todas las reservas activas junto con la información de su cuenta
  Future<List<Map<String, Object?>>> getActiveWithAccount() async {
    final db = await DatabaseHelper.database;
    return db.rawQuery('''
      SELECT
        r.*,
        a.name AS account_name,
        a.type AS account_type
      FROM reservations r
      INNER JOIN accounts a ON r.account_id = a.id
      WHERE r.active = 1
      ORDER BY r.id DESC
    ''');
  }

  Future<Reservation?> getById(int id) async {
    final db = await DatabaseHelper.database;
    final results = await db.query(
      'reservations',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return Reservation.fromMap(results.first);
  }

  Future<int> update(Reservation reservation) async {
    if (reservation.id == null) {
      throw ArgumentError('No se puede actualizar una reserva sin ID.');
    }

    final db = await DatabaseHelper.database;
    return db.update(
      'reservations',
      {
        'account_id': reservation.accountId,
        'name': reservation.name,
        'amount': reservation.amount,
        'currency': reservation.currency,
        'reason': reservation.reason,
        'active': reservation.active ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [reservation.id],
    );
  }

  /// Borrado físico de la reserva (liberación definitiva del fondo)
  Future<int> delete(int id) async {
    final db = await DatabaseHelper.database;
    return db.delete(
      'reservations',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Suma total de reservas activas por moneda
  Future<Map<String, int>> getTotalReservedByCurrency() async {
    final db = await DatabaseHelper.database;
    final results = await db.rawQuery('''
      SELECT
        currency,
        COALESCE(SUM(amount), 0) AS total
      FROM reservations
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

  /// Total reservado en una cuenta específica
  Future<int> getTotalReservedByAccount(int accountId) async {
    final db = await DatabaseHelper.database;
    final results = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) AS total
      FROM reservations
      WHERE account_id = ? AND active = 1
    ''', [accountId]);

    return (results.first['total'] as num?)?.toInt() ?? 0;
  }
}