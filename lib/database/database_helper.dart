// ==========================================
// ARCHIVO: lib/database/database_helper.dart
// ==========================================

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const String _databaseName = 'finanzas_personales.db';
  static const int _databaseVersion = 3; // 👈 Versión 3: Compras Planeadas

  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    return openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onConfigure: _onConfigure,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  static Future<void> _onCreate(
    Database db,
    int version,
  ) async {
    // CUENTAS
    await db.execute('''
      CREATE TABLE accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        currency TEXT NOT NULL CHECK (currency IN ('PEN', 'USD')),
        type TEXT NOT NULL CHECK (type IN ('bank', 'cash')),
        initial_balance INTEGER NOT NULL DEFAULT 0,
        active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');

    // MEDIOS DE PAGO
    await db.execute('''
      CREATE TABLE payment_methods (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        FOREIGN KEY (account_id)
          REFERENCES accounts (id)
          ON DELETE RESTRICT
          ON UPDATE CASCADE
      )
    ''');

    // CATEGORÍAS
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL CHECK (type IN ('income', 'expense')),
        active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');

    // SUBCATEGORÍAS
    await db.execute('''
      CREATE TABLE subcategories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        FOREIGN KEY (category_id)
          REFERENCES categories (id)
          ON DELETE RESTRICT
          ON UPDATE CASCADE
      )
    ''');

    // OPERACIONES
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL CHECK (type IN ('income', 'expense', 'transfer', 'debt_payment')),
        date TEXT NOT NULL,
        time TEXT NOT NULL,
        description TEXT,
        active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // CONCEPTOS
    await db.execute('''
      CREATE TABLE transaction_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id INTEGER NOT NULL,
        category_id INTEGER,
        subcategory_id INTEGER,
        amount INTEGER NOT NULL CHECK (amount > 0),
        count_for_food_control INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (transaction_id)
          REFERENCES transactions (id)
          ON DELETE CASCADE
          ON UPDATE CASCADE,
        FOREIGN KEY (category_id)
          REFERENCES categories (id)
          ON DELETE RESTRICT
          ON UPDATE CASCADE,
        FOREIGN KEY (subcategory_id)
          REFERENCES subcategories (id)
          ON DELETE RESTRICT
          ON UPDATE CASCADE
      )
    ''');

    // MOVIMIENTOS / PAGOS
    await db.execute('''
      CREATE TABLE transaction_payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id INTEGER NOT NULL,
        payment_method_id INTEGER NOT NULL,
        amount INTEGER NOT NULL CHECK (amount > 0),
        direction TEXT NOT NULL CHECK (direction IN ('in', 'out')),
        FOREIGN KEY (transaction_id)
          REFERENCES transactions (id)
          ON DELETE CASCADE
          ON UPDATE CASCADE,
        FOREIGN KEY (payment_method_id)
          REFERENCES payment_methods (id)
          ON DELETE RESTRICT
          ON UPDATE CASCADE
      )
    ''');

    // CONTROL DIARIO DE ALIMENTACIÓN
    await db.execute('''
      CREATE TABLE food_budget_days (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        daily_limit INTEGER NOT NULL DEFAULT 0,
        adjustment INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // RESERVAS
    await db.execute('''
      CREATE TABLE reservations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        amount INTEGER NOT NULL CHECK (amount > 0),
        currency TEXT NOT NULL CHECK (currency IN ('PEN', 'USD')),
        reason TEXT,
        active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (account_id)
          REFERENCES accounts (id)
          ON DELETE RESTRICT
          ON UPDATE CASCADE
      )
    ''');

    // DEUDAS (YO DEBO)
    await db.execute('''
      CREATE TABLE debts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT NOT NULL,
        original_amount INTEGER NOT NULL CHECK (original_amount > 0),
        currency TEXT NOT NULL CHECK (currency IN ('PEN', 'USD')),
        date TEXT NOT NULL,
        active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // ABONOS DE DEUDAS
    await db.execute('''
      CREATE TABLE debt_payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        debt_id INTEGER NOT NULL,
        transaction_id INTEGER NOT NULL,
        amount INTEGER NOT NULL CHECK (amount > 0),
        FOREIGN KEY (debt_id)
          REFERENCES debts (id)
          ON DELETE RESTRICT
          ON UPDATE CASCADE,
        FOREIGN KEY (transaction_id)
          REFERENCES transactions (id)
          ON DELETE RESTRICT
          ON UPDATE CASCADE
      )
    ''');

    // PERSONAS QUE ME DEBEN
    await db.execute('''
      CREATE TABLE people_owed (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        amount INTEGER NOT NULL CHECK (amount > 0),
        currency TEXT NOT NULL CHECK (currency IN ('PEN', 'USD')),
        note TEXT,
        date TEXT NOT NULL,
        active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // COMPRAS PLANEADAS (METAS / COSAS POR COMPRAR)
    await db.execute('''
      CREATE TABLE planned_purchases (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        amount INTEGER NOT NULL CHECK (amount > 0),
        currency TEXT NOT NULL CHECK (currency IN ('PEN', 'USD')),
        note TEXT,
        active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // CONFIGURACIÓN
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE transaction_payments ADD COLUMN direction TEXT NOT NULL DEFAULT "out"');
    }

    // Migración a Versión 3: Crear tabla de compras planeadas
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS planned_purchases (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          amount INTEGER NOT NULL CHECK (amount > 0),
          currency TEXT NOT NULL CHECK (currency IN ('PEN', 'USD')),
          note TEXT,
          active INTEGER NOT NULL DEFAULT 1,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
    }
  }
}