// ==========================================
// ARCHIVO: lib/models/transaction.dart
// ==========================================

enum TransactionType {
  income,
  expense,
  transfer,
  debtPayment; // 👈 lowerCamelCase según las normas de Dart

  String get dbValue {
    switch (this) {
      case TransactionType.income:
        return 'income';
      case TransactionType.expense:
        return 'expense';
      case TransactionType.transfer:
        return 'transfer';
      case TransactionType.debtPayment:
        return 'debt_payment';
    }
  }

  static TransactionType fromDbValue(String value) {
    switch (value) {
      case 'income':
        return TransactionType.income;
      case 'expense':
        return TransactionType.expense;
      case 'transfer':
        return TransactionType.transfer;
      case 'debt_payment':
      case 'debtPayment':
        return TransactionType.debtPayment;
      default:
        return TransactionType.expense;
    }
  }
}

class Transaction {
  final int? id;
  final TransactionType type;
  final int amount;
  final String currency;
  final int accountId;
  final int? paymentMethodId;
  final String? description;
  final DateTime date;

  const Transaction({
    this.id,
    required this.type,
    required this.amount,
    required this.currency,
    required this.accountId,
    this.paymentMethodId,
    this.description,
    required this.date,
  });
}