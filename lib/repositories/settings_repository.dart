import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';

class SettingsRepository {
  static const String initialSetupCompleted =
      'initial_setup_completed';

  Future<String?> get(String key) async {
    final db = await DatabaseHelper.database;

    final result = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first['value'] as String?;
  }

  Future<void> set(String key, String value) async {
    final db = await DatabaseHelper.database;

    await db.insert(
      'settings',
      {
        'key': key,
        'value': value,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<bool> isInitialSetupCompleted() async {
    final value = await get(initialSetupCompleted);

    return value == 'true';
  }

  Future<void> markInitialSetupCompleted() async {
    await set(initialSetupCompleted, 'true');
  }
}