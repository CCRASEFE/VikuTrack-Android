// ==========================================
// ARCHIVO: lib/repositories/people_owed_repository.dart
// ==========================================

import '../database/database_helper.dart';
import '../models/person_owed.dart';

class PeopleOwedRepository {
  Future<int> insert(PersonOwed person) async {
    final db = await DatabaseHelper.database;
    return db.insert('people_owed', person.toMap());
  }

  Future<List<PersonOwed>> getActive() async {
    final db = await DatabaseHelper.database;

    final results = await db.query(
      'people_owed',
      where: 'active = 1',
      orderBy: 'id DESC',
    );

    return results.map((m) => PersonOwed.fromMap(m)).toList();
  }

  Future<int> update(PersonOwed person) async {
    if (person.id == null) {
      throw ArgumentError('No se puede actualizar sin ID.');
    }

    final db = await DatabaseHelper.database;
    return db.update(
      'people_owed',
      {
        'name': person.name,
        'amount': person.amount,
        'currency': person.currency,
        'note': person.note,
        'date': person.date,
        'active': person.active ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [person.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await DatabaseHelper.database;
    return db.delete('people_owed', where: 'id = ?', whereArgs: [id]);
  }

  /// Suma total de dinero que deben al usuario por moneda
  Future<Map<String, int>> getTotalOwedToMeByCurrency() async {
    final db = await DatabaseHelper.database;
    final results = await db.rawQuery('''
      SELECT
        currency,
        COALESCE(SUM(amount), 0) AS total
      FROM people_owed
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