import 'package:flutter/material.dart';

import '../../models/account.dart';
import '../../repositories/account_repository.dart';

class InactiveAccountsPage extends StatefulWidget {
  const InactiveAccountsPage({super.key});

  @override
  State<InactiveAccountsPage> createState() =>
      _InactiveAccountsPageState();
}

class _InactiveAccountsPageState
    extends State<InactiveAccountsPage> {
  final _accountRepository = AccountRepository();

  bool _loading = true;

  List<Account> _accounts = [];

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final accounts =
        await _accountRepository.getInactive();

    if (!mounted) {
      return;
    }

    setState(() {
      _accounts = accounts;
      _loading = false;
    });
  }

  Future<void> _activateAccount(
    Account account,
  ) async {
    if (account.id == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reactivar cuenta'),
          content: Text(
            '¿Quieres reactivar la cuenta "${account.name}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Reactivar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await _accountRepository.activate(account.id!);

    if (!mounted) {
      return;
    }

    await _loadAccounts();
  }

  String _formatBalance(
    int balance,
    String currency,
  ) {
    final amount = balance / 100;

    if (currency == 'USD') {
      return '\$${amount.toStringAsFixed(2)}';
    }

    return 'S/ ${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuentas desactivadas'),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _accounts.isEmpty
              ? const Center(
                  child: Text(
                    'No hay cuentas desactivadas.',
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _accounts.length,
                  itemBuilder: (context, index) {
                    final account = _accounts[index];

                    return Card(
                      margin: const EdgeInsets.only(
                        bottom: 12,
                      ),
                      child: ListTile(
                        title: Text(
                          account.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '${account.currency} · '
                          '${_formatBalance(
                            account.initialBalance,
                            account.currency,
                          )}',
                        ),
                        trailing: FilledButton(
                          onPressed: () =>
                              _activateAccount(account),
                          child: const Text('Reactivar'),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}