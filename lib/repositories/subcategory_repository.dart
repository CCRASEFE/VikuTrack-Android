// lib/repositories/subcategory_repository.dart
import '../database/database_helper.dart';

class SubcategoryRepository {
  Future<int> insert({
    required int categoryId,
    required String name,
  }) async {
    final db = await DatabaseHelper.database;

    return db.insert(
      'subcategories',
      {
        'category_id': categoryId,
        'name': name,
        'active': 1,
        'created_at': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<List<Map<String, Object?>>> getByCategory(int categoryId) async {
    final db = await DatabaseHelper.database;

    return db.query(
      'subcategories',
      where: 'category_id = ? AND active = 1',
      whereArgs: [categoryId],
      orderBy: 'id ASC',
    );
  }

  Future<List<Map<String, Object?>>> getAll() async {
    final db = await DatabaseHelper.database;

    return db.query(
      'subcategories',
      where: 'active = 1',
      orderBy: 'id ASC',
    );
  }

  Future<List<Map<String, Object?>>> getInactiveByCategory(int categoryId) async {
    final db = await DatabaseHelper.database;

    return db.query(
      'subcategories',
      where: 'category_id = ? AND active = 0',
      whereArgs: [categoryId],
      orderBy: 'id ASC',
    );
  }

  Future<int> update({
    required int id,
    required String name,
  }) async {
    final db = await DatabaseHelper.database;

    return db.update(
      'subcategories',
      {'name': name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deactivate(int id) async {
    final db = await DatabaseHelper.database;

    return db.update(
      'subcategories',
      {'active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deactivateByCategory(int categoryId) async {
    final db = await DatabaseHelper.database;

    return db.update(
      'subcategories',
      {'active': 0},
      where: 'category_id = ?',
      whereArgs: [categoryId],
    );
  }

  Future<int> reactivateByCategory(int categoryId) async {
    final db = await DatabaseHelper.database;

    return db.update(
      'subcategories',
      {'active': 1},
      where: 'category_id = ?',
      whereArgs: [categoryId],
    );
  }

  Future<int> reactivate(int id) async {
    final db = await DatabaseHelper.database;

    return db.update(
      'subcategories',
      {'active': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Comprueba si la subcategoría fue usada en algún gasto
  Future<bool> hasMovements(int subcategoryId) async {
    final db = await DatabaseHelper.database;

    final result = await db.query(
      'transaction_items',
      where: 'subcategory_id = ?',
      whereArgs: [subcategoryId],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  /// Borrado físico definitivo
  Future<int> delete(int id) async {
    final db = await DatabaseHelper.database;

    return db.delete(
      'subcategories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}