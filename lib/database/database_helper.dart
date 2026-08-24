import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const String _databaseName = 'finanzas_personales.db';
  static const int _databaseVersion = 2;

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
    // ============================================================
    // CUENTAS
    // ============================================================

    await db.execute('''
      CREATE TABLE accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        currency TEXT NOT NULL CHECK (
          currency IN ('PEN', 'USD')
        ),
        type TEXT NOT NULL CHECK (
          type IN ('bank', 'cash')
        ),
        initial_balance INTEGER NOT NULL DEFAULT 0,
        active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');

    // ============================================================
    // MEDIOS DE PAGO
    // ============================================================

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

    // ============================================================
    // CATEGORÍAS
    // ============================================================

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL CHECK (
          type IN ('income', 'expense')
        ),
        active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');

    // ============================================================
    // SUBCATEGORÍAS
    // ============================================================

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

    // ============================================================
    // OPERACIONES
    // ============================================================

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL CHECK (
          type IN (
            'income',
            'expense',
            'transfer',
            'debt_payment'
          )
        ),
        date TEXT NOT NULL,
        time TEXT NOT NULL,
        description TEXT,
        active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // ============================================================
    // CONCEPTOS DE UNA OPERACIÓN
    //
    // category_id ahora puede ser NULL porque:
    // - ingresos no tienen categoría
    // - transferencias no tienen categoría
    // ============================================================

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

    // ============================================================
    // PAGOS / MOVIMIENTOS DE UNA OPERACIÓN
    //
    // direction:
    //   in  = dinero entra a la cuenta
    //   out = dinero sale de la cuenta
    //
    // Esto permite:
    //   ingreso     -> in
    //   gasto       -> out
    //   transferencia:
    //       cuenta origen  -> out
    //       cuenta destino -> in
    // ============================================================

    await db.execute('''
      CREATE TABLE transaction_payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id INTEGER NOT NULL,
        payment_method_id INTEGER NOT NULL,
        amount INTEGER NOT NULL CHECK (amount > 0),
        direction TEXT NOT NULL CHECK (
          direction IN ('in', 'out')
        ),
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

    // ============================================================
    // CONTROL DIARIO DE ALIMENTACIÓN
    // ============================================================

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

    // ============================================================
    // RESERVAS
    // ============================================================

    await db.execute('''
      CREATE TABLE reservations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        amount INTEGER NOT NULL CHECK (amount > 0),
        currency TEXT NOT NULL CHECK (
          currency IN ('PEN', 'USD')
        ),
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

    // ============================================================
    // DEUDAS
    // ============================================================

    await db.execute('''
      CREATE TABLE debts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT NOT NULL,
        original_amount INTEGER NOT NULL CHECK (
          original_amount > 0
        ),
        currency TEXT NOT NULL CHECK (
          currency IN ('PEN', 'USD')
        ),
        date TEXT NOT NULL,
        active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // ============================================================
    // PAGOS DE DEUDAS
    // ============================================================

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

    // ============================================================
    // PERSONAS QUE TE DEBEN
    // ============================================================

    await db.execute('''
      CREATE TABLE people_owed (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        amount INTEGER NOT NULL CHECK (amount > 0),
        currency TEXT NOT NULL CHECK (
          currency IN ('PEN', 'USD')
        ),
        note TEXT,
        date TEXT NOT NULL,
        active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // ============================================================
    // CONFIGURACIÓN
    // ============================================================

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    // ============================================================
    // ÍNDICES
    // ============================================================

    await db.execute('''
      CREATE INDEX idx_payment_methods_account
      ON payment_methods (account_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_subcategories_category
      ON subcategories (category_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_transaction_items_transaction
      ON transaction_items (transaction_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_transaction_payments_transaction
      ON transaction_payments (transaction_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_transaction_payments_direction
      ON transaction_payments (direction)
    ''');

    await db.execute('''
      CREATE INDEX idx_transactions_date
      ON transactions (date)
    ''');

    await db.execute('''
      CREATE INDEX idx_reservations_account
      ON reservations (account_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_debt_payments_debt
      ON debt_payments (debt_id)
    ''');
  }

  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // ============================================================
    // VERSIÓN 1 -> 2
    // ============================================================

    if (oldVersion < 2) {
      // ----------------------------------------------------------
      // transaction_items
      //
      // category_id deja de ser obligatorio porque:
      // - income no usa categorías
      // - transfer no usa categorías
      //
      // SQLite no permite cambiar directamente NOT NULL,
      // por lo que reconstruimos la tabla.
      // ----------------------------------------------------------

      await db.execute('''
        ALTER TABLE transaction_items
        RENAME TO transaction_items_old
      ''');

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

      await db.execute('''
        INSERT INTO transaction_items (
          id,
          transaction_id,
          category_id,
          subcategory_id,
          amount,
          count_for_food_control
        )
        SELECT
          id,
          transaction_id,
          category_id,
          subcategory_id,
          amount,
          count_for_food_control
        FROM transaction_items_old
      ''');

      await db.execute('''
        DROP TABLE transaction_items_old
      ''');

      // ----------------------------------------------------------
      // transaction_payments
      //
      // Agregamos direction.
      //
      // Las operaciones existentes se consideran "out" por
      // compatibilidad con los gastos que ya existían.
      //
      // Los nuevos ingresos y transferencias deberán indicar
      // explícitamente la dirección.
      // ----------------------------------------------------------

      await db.execute('''
        ALTER TABLE transaction_payments
        ADD COLUMN direction TEXT NOT NULL DEFAULT 'out'
      ''');

      await db.execute('''
        CREATE INDEX IF NOT EXISTS
        idx_transaction_payments_direction
        ON transaction_payments (direction)
      ''');
    }
  }
}