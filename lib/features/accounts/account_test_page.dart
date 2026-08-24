import 'package:flutter/material.dart';

import '../../repositories/account_repository.dart';
import '../../repositories/payment_method_repository.dart';

class AccountTestPage extends StatefulWidget {
  const AccountTestPage({super.key});

  @override
  State<AccountTestPage> createState() => _AccountTestPageState();
}

class _AccountTestPageState extends State<AccountTestPage> {
  final _accountRepository = AccountRepository();
  final _paymentMethodRepository = PaymentMethodRepository();

  List<Map<String, Object?>> _accounts = [];
  final Map<int, List<Map<String, Object?>>> _methods = {};

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final accounts = await _accountRepository.getAll();

    final methods = <int, List<Map<String, Object?>>>{};

    for (final account in accounts) {
      if (account.id != null) {
        methods[account.id!] =
            await _paymentMethodRepository.getByAccount(
          account.id!,
        );
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _accounts = accounts
          .map(
            (account) => {
              'id': account.id,
              'name': account.name,
              'currency': account.currency,
              'type': account.type,
              'initialBalance': account.initialBalance,
            },
          )
          .toList();

      _methods.clear();
      _methods.addAll(methods);

      _loading = false;
    });
  }

  String _formatBalance(
    Object? value,
    String currency,
  ) {
    final amount = (value as int) / 100;

    return currency == 'USD'
        ? '\$${amount.toStringAsFixed(2)}'
        : 'S/ ${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prueba de cuentas'),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _accounts.length,
              itemBuilder: (context, index) {
                final account = _accounts[index];

                final id = account['id'] as int;
                final name = account['name'] as String;
                final currency =
                    account['currency'] as String;
                final balance =
                    account['initialBalance'];

                final methods = _methods[id] ?? [];

                return Card(
                  margin:
                      const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$name — $currency',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Saldo inicial: '
                          '${_formatBalance(balance, currency)}',
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Medios:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ...methods.map(
                          (method) => Text(
                            '• ${method['name']}',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}