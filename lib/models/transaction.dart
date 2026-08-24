enum TransactionType {
  income,
  expense,
  transfer,
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