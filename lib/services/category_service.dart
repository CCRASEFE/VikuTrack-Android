// lib/services/category_service.dart
import '../database/database_helper.dart';
import '../repositories/category_repository.dart';
import '../repositories/subcategory_repository.dart';

class CategoryService {
  final CategoryRepository _categoryRepository;
  final SubcategoryRepository _subcategoryRepository;

  CategoryService({
    CategoryRepository? categoryRepository,
    SubcategoryRepository? subcategoryRepository,
  })  : _categoryRepository = categoryRepository ?? CategoryRepository(),
        _subcategoryRepository =
            subcategoryRepository ?? SubcategoryRepository();

  /// Decide si eliminar definitivamente o desactivar la categoría
  /// Retorna `true` si fue eliminada físicamente, o `false` si fue desactivada.
  Future<bool> deleteOrDeactivateCategory(int categoryId) async {
    final hasMovements = await _categoryRepository.hasMovements(categoryId);

    if (hasMovements) {
      await deactivateCategory(categoryId);
      return false; // Desactivada
    } else {
      await _categoryRepository.delete(categoryId);
      return true; // Eliminada físicamente
    }
  }

  /// Decide si eliminar definitivamente o desactivar la subcategoría
  /// Retorna `true` si fue eliminada físicamente, o `false` si fue desactivada.
  Future<bool> deleteOrDeactivateSubcategory(int subcategoryId) async {
    final hasMovements =
        await _subcategoryRepository.hasMovements(subcategoryId);

    if (hasMovements) {
      await _subcategoryRepository.deactivate(subcategoryId);
      return false; // Desactivada
    } else {
      await _subcategoryRepository.delete(subcategoryId);
      return true; // Eliminada físicamente
    }
  }

  Future<void> deactivateCategory(int categoryId) async {
    final db = await DatabaseHelper.database;

    await db.transaction((txn) async {
      await txn.update(
        'categories',
        {'active': 0},
        where: 'id = ?',
        whereArgs: [categoryId],
      );

      await txn.update(
        'subcategories',
        {'active': 0},
        where: 'category_id = ?',
        whereArgs: [categoryId],
      );
    });
  }

  Future<void> reactivateCategory(int categoryId) async {
    final db = await DatabaseHelper.database;

    await db.transaction((txn) async {
      await txn.update(
        'categories',
        {'active': 1},
        where: 'id = ?',
        whereArgs: [categoryId],
      );

      await txn.update(
        'subcategories',
        {'active': 1},
        where: 'category_id = ?',
        whereArgs: [categoryId],
      );
    });
  }

  Future<void> deactivateSubcategory(int subcategoryId) async {
    await _subcategoryRepository.deactivate(subcategoryId);
  }

  Future<void> reactivateSubcategory(int subcategoryId) async {
    await _subcategoryRepository.reactivate(subcategoryId);
  }

  Future<List<Map<String, Object?>>> getInactiveCategories() {
    return _categoryRepository.getInactive();
  }

  Future<List<Map<String, Object?>>> getInactiveSubcategories(int categoryId) {
    return _subcategoryRepository.getInactiveByCategory(categoryId);
  }
}