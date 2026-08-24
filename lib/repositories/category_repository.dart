// lib/repositories/category_repository.dart
import '../database/database_helper.dart';

class CategoryRepository {
  Future<int> insert({
    required String name,
    required String type,
  }) async {
    final db = await DatabaseHelper.database;

    return db.insert(
      'categories',
      {
        'name': name,
        'type': type,
        'active': 1,
        'created_at': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<List<Map<String, Object?>>> getByType(String type) async {
    final db = await DatabaseHelper.database;

    return db.query(
      'categories',
      where: 'type = ? AND active = 1',
      whereArgs: [type],
      orderBy: 'id ASC',
    );
  }

  Future<List<Map<String, Object?>>> getAll() async {
    final db = await DatabaseHelper.database;

    return db.query(
      'categories',
      where: 'active = 1',
      orderBy: 'id ASC',
    );
  }

  Future<List<Map<String, Object?>>> getInactive() async {
    final db = await DatabaseHelper.database;

    return db.query(
      'categories',
      where: 'active = 0',
      orderBy: 'id ASC',
    );
  }

  Future<int> update({
    required int id,
    required String name,
    required String type,
  }) async {
    final db = await DatabaseHelper.database;

    return db.update(
      'categories',
      {'name': name, 'type': type},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deactivate(int id) async {
    final db = await DatabaseHelper.database;

    return db.update(
      'categories',
      {'active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> reactivate(int id) async {
    final db = await DatabaseHelper.database;

    return db.update(
      'categories',
      {'active': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Comprueba si la categoría (o alguna de sus subcategorías) ha sido usada en gastos
  Future<bool> hasMovements(int categoryId) async {
    final db = await DatabaseHelper.database;

    final result = await db.query(
      'transaction_items',
      where: 'category_id = ?',
      whereArgs: [categoryId],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  /// Borrado físico definitivo de la categoría y sus subcategorías
  Future<void> delete(int id) async {
    final db = await DatabaseHelper.database;

    await db.transaction((txn) async {
      await txn.delete(
        'subcategories',
        where: 'category_id = ?',
        whereArgs: [id],
      );
      await txn.delete(
        'categories',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }
}