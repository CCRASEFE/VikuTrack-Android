// ==========================================
// ARCHIVO: lib/repositories/reservation_repository.dart
// ==========================================

import '../database/database_helper.dart';
import '../models/reservation.dart';
import 'account_repository.dart';

class ReservationRepository {
  final _accountRepository = AccountRepository();

  /// Inserta una reserva validando que no supere el saldo libre disponible de la cuenta
  Future<int> insert(Reservation reservation) async {
    final account = await _accountRepository.getById(reservation.accountId);
    final balanceDetails = await _accountRepository.getBalanceDetails(reservation.accountId);
    final freeBalance = balanceDetails['free'] ?? 0;

    if (reservation.amount > freeBalance) {
      final accountName = account?.name ?? 'Cuenta';
      final currency = account?.currency ?? 'PEN';
      final freeStr = currency == 'USD'
          ? '\$${(freeBalance / 100).toStringAsFixed(2)}'
          : 'S/ ${(freeBalance / 100).toStringAsFixed(2)}';
      final reqStr = currency == 'USD'
          ? '\$${(reservation.amount / 100).toStringAsFixed(2)}'
          : 'S/ ${(reservation.amount / 100).toStringAsFixed(2)}';

      throw ArgumentError(
        'Fondos insuficientes en "$accountName": Tienes un saldo libre disponible de $freeStr e intentas reservar $reqStr.',
      );
    }

    final db = await DatabaseHelper.database;
    return db.insert('reservations', reservation.toMap());
  }

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

  /// Actualiza la reserva validando saldo libre y reintegrando provisionalmente el monto anterior
  Future<int> update(Reservation reservation) async {
    if (reservation.id == null) {
      throw ArgumentError('No se puede actualizar una reserva sin ID.');
    }

    final oldReservation = await getById(reservation.id!);
    final account = await _accountRepository.getById(reservation.accountId);
    final balanceDetails = await _accountRepository.getBalanceDetails(reservation.accountId);
    int effectiveFreeBalance = balanceDetails['free'] ?? 0;

    // Si sigue en la misma cuenta, sumamos el monto anterior antes de verificar
    if (oldReservation != null && oldReservation.accountId == reservation.accountId) {
      effectiveFreeBalance += oldReservation.amount;
    }

    if (reservation.amount > effectiveFreeBalance) {
      final accountName = account?.name ?? 'Cuenta';
      final currency = account?.currency ?? 'PEN';
      final freeStr = currency == 'USD'
          ? '\$${(effectiveFreeBalance / 100).toStringAsFixed(2)}'
          : 'S/ ${(effectiveFreeBalance / 100).toStringAsFixed(2)}';
      final reqStr = currency == 'USD'
          ? '\$${(reservation.amount / 100).toStringAsFixed(2)}'
          : 'S/ ${(reservation.amount / 100).toStringAsFixed(2)}';

      throw ArgumentError(
        'Fondos insuficientes en "$accountName": Tienes un saldo libre disponible de $freeStr e intentas reservar $reqStr.',
      );
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

  Future<int> delete(int id) async {
    final db = await DatabaseHelper.database;
    return db.delete(
      'reservations',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

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