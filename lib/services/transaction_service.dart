// ==========================================
// ARCHIVO: lib/services/transaction_service.dart
// ==========================================

import '../database/database_helper.dart';
import '../models/transaction.dart';
import '../repositories/account_repository.dart';
import '../repositories/payment_method_repository.dart';
import '../repositories/transaction_repository.dart';

class TransactionItemInput {
  final int? categoryId;
  final int? subcategoryId;
  final int amount;
  final bool countForFoodControl;

  const TransactionItemInput({
    this.categoryId,
    this.subcategoryId,
    required this.amount,
    this.countForFoodControl = false,
  });
}

class TransactionPaymentInput {
  final int paymentMethodId;
  final int amount;
  final String direction;

  const TransactionPaymentInput({
    required this.paymentMethodId,
    required this.amount,
    required this.direction,
  }) : assert(
          direction == 'in' || direction == 'out',
          'direction debe ser "in" o "out".',
        );
}

class TransactionService {
  final _accountRepository = AccountRepository();
  final _paymentMethodRepository = PaymentMethodRepository();
  final _transactionRepository = TransactionRepository();

  Future<int> createTransaction({
    required Transaction transaction,
    required List<TransactionItemInput> items,
    required List<TransactionPaymentInput> payments,
  }) async {
    _validateTransaction(
      transaction: transaction,
      items: items,
      payments: payments,
    );

    await _validateSufficientFreeFunds(payments: payments);

    final db = await DatabaseHelper.database;

    return db.transaction<int>((txn) async {
      final now = DateTime.now().toIso8601String();

      final transactionId = await txn.insert(
        'transactions',
        {
          'type': transaction.type.dbValue,
          'date': transaction.date.toIso8601String().split('T').first,
          'time': transaction.date.toIso8601String().split('T').last.split('.').first,
          'description': transaction.description,
          'active': 1,
          'created_at': now,
          'updated_at': now,
        },
      );

      for (final item in items) {
        await txn.insert(
          'transaction_items',
          {
            'transaction_id': transactionId,
            'category_id': item.categoryId,
            'subcategory_id': item.subcategoryId,
            'amount': item.amount,
            'count_for_food_control': item.countForFoodControl ? 1 : 0,
          },
        );
      }

      for (final payment in payments) {
        await txn.insert(
          'transaction_payments',
          {
            'transaction_id': transactionId,
            'payment_method_id': payment.paymentMethodId,
            'amount': payment.amount,
            'direction': payment.direction,
          },
        );
      }

      return transactionId;
    });
  }

  Future<void> updateTransaction({
    required int id,
    required Transaction transaction,
    required List<TransactionItemInput> items,
    required List<TransactionPaymentInput> payments,
  }) async {
    _validateTransaction(
      transaction: transaction,
      items: items,
      payments: payments,
    );

    await _validateSufficientFreeFunds(payments: payments, editingTransactionId: id);

    final db = await DatabaseHelper.database;

    await db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();

      await txn.update(
        'transactions',
        {
          'type': transaction.type.dbValue,
          'date': transaction.date.toIso8601String().split('T').first,
          'time': transaction.date.toIso8601String().split('T').last.split('.').first,
          'description': transaction.description,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      await txn.update(
        'debt_payments',
        {'amount': transaction.amount},
        where: 'transaction_id = ?',
        whereArgs: [id],
      );

      await txn.delete(
        'transaction_items',
        where: 'transaction_id = ?',
        whereArgs: [id],
      );

      for (final item in items) {
        await txn.insert(
          'transaction_items',
          {
            'transaction_id': id,
            'category_id': item.categoryId,
            'subcategory_id': item.subcategoryId,
            'amount': item.amount,
            'count_for_food_control': item.countForFoodControl ? 1 : 0,
          },
        );
      }

      await txn.delete(
        'transaction_payments',
        where: 'transaction_id = ?',
        whereArgs: [id],
      );

      for (final payment in payments) {
        await txn.insert(
          'transaction_payments',
          {
            'transaction_id': id,
            'payment_method_id': payment.paymentMethodId,
            'amount': payment.amount,
            'direction': payment.direction,
          },
        );
      }
    });
  }

  Future<void> _validateSufficientFreeFunds({
    required List<TransactionPaymentInput> payments,
    int? editingTransactionId,
  }) async {
    for (final payment in payments.where((p) => p.direction == 'out')) {
      final accountId = await _paymentMethodRepository.getAccountId(payment.paymentMethodId);
      if (accountId == null) continue;

      final account = await _accountRepository.getById(accountId);
      final balanceDetails = await _accountRepository.getBalanceDetails(accountId);
      int freeBalance = balanceDetails['free'] ?? 0;
      final totalBalance = balanceDetails['total'] ?? 0;
      final totalReserved = balanceDetails['reserved'] ?? 0;

      if (editingTransactionId != null) {
        final oldPayments = await _transactionRepository.getPayments(editingTransactionId);
        for (final oldP in oldPayments.where((op) => op['direction'] == 'out')) {
          final oldMethodId = oldP['payment_method_id'] as int;
          final oldAccId = await _paymentMethodRepository.getAccountId(oldMethodId);
          if (oldAccId == accountId) {
            freeBalance += (oldP['amount'] as num).toInt();
          }
        }
      }

      if (freeBalance < payment.amount) {
        final accountName = account?.name ?? 'Cuenta';
        final currency = account?.currency ?? 'PEN';
        final freeStr = currency == 'USD'
            ? '\$${(freeBalance / 100).toStringAsFixed(2)}'
            : 'S/ ${(freeBalance / 100).toStringAsFixed(2)}';
        final reqStr = currency == 'USD'
            ? '\$${(payment.amount / 100).toStringAsFixed(2)}'
            : 'S/ ${(payment.amount / 100).toStringAsFixed(2)}';
        final reservedStr = currency == 'USD'
            ? '\$${(totalReserved / 100).toStringAsFixed(2)}'
            : 'S/ ${(totalReserved / 100).toStringAsFixed(2)}';
        final totalStr = currency == 'USD'
            ? '\$${(totalBalance / 100).toStringAsFixed(2)}'
            : 'S/ ${(totalBalance / 100).toStringAsFixed(2)}';

        if (totalReserved > 0) {
          throw ArgumentError(
            'Fondos insuficientes en "$accountName": '
            'Tienes un saldo libre de $freeStr (Total: $totalStr, Reservado: $reservedStr) e intentas retirar $reqStr.',
          );
        } else {
          throw ArgumentError(
            'Fondos insuficientes en "$accountName": Saldo disponible $freeStr, intentas retirar $reqStr.',
          );
        }
      }
    }
  }

  void _validateTransaction({
    required Transaction transaction,
    required List<TransactionItemInput> items,
    required List<TransactionPaymentInput> payments,
  }) {
    if (transaction.amount <= 0) {
      throw ArgumentError('El importe de la operación debe ser mayor que cero.');
    }

    for (final item in items) {
      if (item.amount <= 0) {
        throw ArgumentError('El importe de un concepto debe ser mayor que cero.');
      }
    }

    for (final payment in payments) {
      if (payment.amount <= 0) {
        throw ArgumentError('El importe de un medio de pago debe ser mayor que cero.');
      }
    }

    switch (transaction.type) {
      case TransactionType.expense:
        _validateExpense(transaction: transaction, items: items, payments: payments);
        break;

      case TransactionType.income:
        _validateIncome(transaction: transaction, items: items, payments: payments);
        break;

      case TransactionType.transfer:
        _validateTransfer(transaction: transaction, items: items, payments: payments);
        break;

      case TransactionType.debtPayment:
        _validateDebtPayment(transaction: transaction, items: items, payments: payments);
        break;
    }
  }

  void _validateExpense({
    required Transaction transaction,
    required List<TransactionItemInput> items,
    required List<TransactionPaymentInput> payments,
  }) {
    if (items.isEmpty) {
      throw ArgumentError('El gasto debe tener al menos un concepto.');
    }

    if (payments.isEmpty) {
      throw ArgumentError('El gasto debe tener al menos un medio de pago.');
    }

    if (items.any((item) => item.categoryId == null)) {
      throw ArgumentError('Cada concepto de un gasto debe tener una categoría.');
    }

    if (payments.any((payment) => payment.direction != 'out')) {
      throw ArgumentError('Los pagos de un gasto deben tener dirección "out".');
    }

    _validateTotals(transaction: transaction, items: items, payments: payments);
  }

  void _validateIncome({
    required Transaction transaction,
    required List<TransactionItemInput> items,
    required List<TransactionPaymentInput> payments,
  }) {
    if (items.isEmpty) {
      throw ArgumentError('El ingreso debe tener una categoría asignada.');
    }

    if (items.any((item) => item.categoryId == null)) {
      throw ArgumentError('El ingreso debe tener una categoría seleccionada.');
    }

    if (payments.isEmpty) {
      throw ArgumentError('El ingreso debe tener al menos un medio de pago.');
    }

    if (payments.any((payment) => payment.direction != 'in')) {
      throw ArgumentError('Los pagos de un ingreso deben tener dirección "in".');
    }

    _validateTotals(transaction: transaction, items: items, payments: payments);
  }

  void _validateTransfer({
    required Transaction transaction,
    required List<TransactionItemInput> items,
    required List<TransactionPaymentInput> payments,
  }) {
    if (items.isNotEmpty) {
      throw ArgumentError('Una transferencia no debe tener categorías ni conceptos.');
    }

    if (payments.length != 2) {
      throw ArgumentError('Una transferencia debe tener una cuenta origen y una cuenta destino.');
    }

    final outgoing = payments.where((payment) => payment.direction == 'out').toList();
    final incoming = payments.where((payment) => payment.direction == 'in').toList();

    if (outgoing.length != 1 || incoming.length != 1) {
      throw ArgumentError('La transferencia debe tener un movimiento de salida y uno de entrada.');
    }

    if (outgoing.first.paymentMethodId == incoming.first.paymentMethodId) {
      throw ArgumentError('La cuenta origen y la cuenta destino deben ser diferentes.');
    }

    if (outgoing.first.amount != incoming.first.amount) {
      throw ArgumentError('El importe de origen y destino debe ser el mismo.');
    }

    if (outgoing.first.amount != transaction.amount) {
      throw ArgumentError('El importe de la transferencia no coincide con sus movimientos.');
    }
  }

  void _validateDebtPayment({
    required Transaction transaction,
    required List<TransactionItemInput> items,
    required List<TransactionPaymentInput> payments,
  }) {
    if (payments.isEmpty) {
      throw ArgumentError('El pago de deuda debe tener un medio de pago.');
    }

    if (payments.any((payment) => payment.direction != 'out')) {
      throw ArgumentError('El pago de deuda debe tener dirección "out".');
    }

    _validateTotals(transaction: transaction, items: items, payments: payments);
  }

  void _validateTotals({
    required Transaction transaction,
    required List<TransactionItemInput> items,
    required List<TransactionPaymentInput> payments,
  }) {
    if (items.isNotEmpty) {
      final itemsTotal = items.fold<int>(0, (total, item) => total + item.amount);
      if (itemsTotal != transaction.amount) {
        throw ArgumentError('El total de los conceptos no coincide con el importe de la operación.');
      }
    }

    final paymentsTotal = payments.fold<int>(0, (total, payment) => total + payment.amount);
    if (paymentsTotal != transaction.amount) {
      throw ArgumentError('El total de los pagos no coincide con el importe de la operación.');
    }
  }
}