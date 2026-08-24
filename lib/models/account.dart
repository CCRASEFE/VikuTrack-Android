class Account {
  final int? id;
  final String name;
  final String currency;
  final String type;
  final int initialBalance;
  final bool active;

  const Account({
    this.id,
    required this.name,
    required this.currency,
    required this.type,
    required this.initialBalance,
    this.active = true,
  });

  Map<String, Object?> toMap() {
  return {
    'id': id,
    'name': name,
    'currency': currency,
    'type': type,
    'initial_balance': initialBalance,
    'active': active ? 1 : 0,
    'created_at': DateTime.now().toIso8601String(),
  };
  }

  factory Account.fromMap(Map<String, Object?> map) {
    return Account(
      id: map['id'] as int?,
      name: map['name'] as String,
      currency: map['currency'] as String,
      type: map['type'] as String,
      initialBalance: map['initial_balance'] as int,
      active: (map['active'] as int) == 1,
    );
  }
}