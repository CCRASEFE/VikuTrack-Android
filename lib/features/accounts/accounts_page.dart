// ==========================================
// ARCHIVO: lib/features/accounts/accounts_page.dart
// ==========================================

import 'package:flutter/material.dart';

import '../../core/app_themes.dart';
import '../../repositories/account_repository.dart';
import '../../repositories/payment_method_repository.dart';
import '../../models/account.dart';
import 'payment_methods_page.dart';
import 'inactive_accounts_page.dart';

class AccountsPage extends StatefulWidget {
  const AccountsPage({super.key});

  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  final _accountRepository = AccountRepository();
  final _paymentMethodRepository = PaymentMethodRepository();

  bool _loading = true;
  List<_AccountView> _accounts = [];

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final accounts = await _accountRepository.getActive();
    final accountViews = <_AccountView>[];

    for (final account in accounts) {
      if (account.id == null) continue;

      final methods = await _paymentMethodRepository.getByAccount(account.id!);
      final balanceDetails = await _accountRepository.getBalanceDetails(account.id!);

      accountViews.add(
        _AccountView(
          id: account.id!,
          name: account.name,
          currency: account.currency,
          type: account.type,
          initialBalance: balanceDetails['initial']!,
          totalBalance: balanceDetails['total']!,
          reservedBalance: balanceDetails['reserved']!,
          freeBalance: balanceDetails['free']!,
          paymentMethods: methods
              .map((method) => method['name'] as String)
              .toList(),
        ),
      );
    }

    if (!mounted) return;

    setState(() {
      _accounts = accountViews;
      _loading = false;
    });
  }

  String _formatAmount(int amountInCents, String currency) {
    final amount = amountInCents / 100;
    if (currency == 'USD') {
      return '\$${amount.toStringAsFixed(2)}';
    }
    return 'S/ ${amount.toStringAsFixed(2)}';
  }

  Future<void> _createAccount() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return _CreateAccountDialog(
          onCreate: ({
            required String name,
            required String currency,
            required String type,
            required int initialBalance,
          }) async {
            final accountId = await _accountRepository.insert(
              Account(
                name: name,
                currency: currency,
                type: type,
                initialBalance: initialBalance,
              ),
            );

            await _paymentMethodRepository.insert(
              accountId: accountId,
              name: name,
            );
          },
        );
      },
    );

    if (created == true && mounted) {
      await _loadAccounts();
    }
  }

  Future<void> _handleDeleteAccount(_AccountView account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar cuenta'),
          content: Text('¿Quieres eliminar la cuenta "${account.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final hasMovements = await _accountRepository.hasMovements(account.id);

    if (hasMovements) {
      await _accountRepository.deactivate(account.id);

      if (!mounted) return;
      await _loadAccounts();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'La cuenta "${account.name}" contiene operaciones o reservas. Se ha desactivado para proteger tu historial.',
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      await _accountRepository.delete(account.id);

      if (!mounted) return;
      await _loadAccounts();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cuenta "${account.name}" eliminada definitivamente.')),
      );
    }
  }

  Future<void> _editAccount(_AccountView account) async {
    final currentAccount = await _accountRepository.getById(account.id);

    if (currentAccount == null || !mounted) return;

    final updated = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return _EditAccountDialog(
          account: currentAccount,
          onSave: ({
            required String name,
            required String currency,
            required String type,
            required int initialBalance,
          }) async {
            await _accountRepository.update(
              Account(
                id: currentAccount.id,
                name: name,
                currency: currency,
                type: type,
                initialBalance: initialBalance,
                active: currentAccount.active,
              ),
            );
          },
        );
      },
    );

    if (updated == true && mounted) {
      await _loadAccounts();
    }
  }

  Widget _buildNetWorthSummary(AppThemeColors? themeColors) {
    int totalPEN = 0;
    int totalUSD = 0;

    for (final acc in _accounts) {
      if (acc.currency == 'PEN') {
        totalPEN += acc.totalBalance;
      } else if (acc.currency == 'USD') {
        totalUSD += acc.totalBalance;
      }
    }

    return Card(
      elevation: 3,
      color: themeColors?.heroCardBg ?? Theme.of(context).colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: themeColors?.heroCardBorder ?? Colors.transparent),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance,
                  color: themeColors?.heroCardAccent ?? Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Patrimonio Total en Cuentas',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: themeColors?.heroCardText ?? Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Soles',
                        style: TextStyle(
                          fontSize: 11,
                          color: (themeColors?.heroCardText ?? Colors.white).withAlpha(180),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatAmount(totalPEN, 'PEN'),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: themeColors?.heroCardAccent ?? Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(height: 38, width: 1, color: Colors.white24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Dólares',
                        style: TextStyle(
                          fontSize: 11,
                          color: (themeColors?.heroCardText ?? Colors.white).withAlpha(180),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatAmount(totalUSD, 'USD'),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: themeColors?.heroCardAccent ?? Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = Theme.of(context).extension<AppThemeColors>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuentas'),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: colorScheme.onSurfaceVariant),
            onSelected: (value) {
              if (value == 'inactive') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const InactiveAccountsPage(),
                  ),
                );
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'inactive',
                child: Text('Cuentas desactivadas'),
              ),
            ],
          ),
          IconButton(
            onPressed: _createAccount,
            icon: const Icon(Icons.add),
            tooltip: 'Nueva cuenta',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildNetWorthSummary(themeColors),
                const SizedBox(height: 8),
                Text(
                  'Mis Cuentas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: themeColors?.cardBaseText ?? colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                if (_accounts.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'No tienes cuentas activas registradas.',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                  )
                else
                  ..._accounts.map((account) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: themeColors?.cardBaseBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(color: themeColors?.cardBaseBorder ?? Colors.white12),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PaymentMethodsPage(
                                accountId: account.id,
                                accountName: account.name,
                              ),
                            ),
                          );

                          if (!mounted) return;
                          await _loadAccounts();
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: themeColors?.pillBg,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      account.type == 'cash'
                                          ? Icons.payments_outlined
                                          : Icons.account_balance_outlined,
                                      color: themeColors?.cardAccentText ?? colorScheme.primary,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          account.name,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: themeColors?.cardBaseText ?? colorScheme.onSurface,
                                          ),
                                        ),
                                        Text(
                                          '${account.currency} · ${account.type == 'cash' ? 'Efectivo' : 'Banco'}',
                                          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    icon: Icon(Icons.more_vert, color: colorScheme.onSurfaceVariant),
                                    onSelected: (value) async {
                                      if (value == 'edit') {
                                        await _editAccount(account);
                                      }
                                      if (value == 'delete') {
                                        await _handleDeleteAccount(account);
                                      }
                                    },
                                    itemBuilder: (context) => const [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Text('Editar'),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text(
                                          'Eliminar',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Saldo Total en Cuenta',
                                        style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                                      ),
                                      Text(
                                        _formatAmount(account.totalBalance, account.currency),
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w800,
                                          color: account.totalBalance >= 0
                                              ? (themeColors?.cardBaseText ?? colorScheme.onSurface)
                                              : colorScheme.error,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant.withAlpha(120)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Divider(height: 1, color: themeColors?.cardBaseBorder ?? Colors.white12),
                              const SizedBox(height: 10),

                              // Fila elástica de 3 columnas (Inicial, Reservado, Dinero disponible)
                              Row(
                                children: [
                                  // Columna 1: Inicial
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Inicial',
                                          style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          _formatAmount(account.initialBalance, account.currency),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Columna 2: Reservado
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Reservado',
                                          style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          _formatAmount(account.reservedBalance, account.currency),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: account.reservedBalance > 0
                                                ? (themeColors?.cardAccentText ?? Colors.amber)
                                                : colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Columna 3: Dinero disponible (Libre)
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Disponible',
                                          style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          _formatAmount(account.freeBalance, account.currency),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: account.freeBalance >= 0
                                                ? (themeColors?.cardAccentText ?? Colors.green)
                                                : colorScheme.error,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              if (account.paymentMethods.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: account.paymentMethods
                                      .map((method) => Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: themeColors?.pillBg,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: themeColors?.pillBorder ?? Colors.transparent),
                                            ),
                                            child: Text(
                                              method,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: themeColors?.pillText ?? colorScheme.onSurface,
                                              ),
                                            ),
                                          ))
                                      .toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
    );
  }
}

class _CreateAccountDialog extends StatefulWidget {
  final Future<void> Function({
    required String name,
    required String currency,
    required String type,
    required int initialBalance,
  }) onCreate;

  const _CreateAccountDialog({required this.onCreate});

  @override
  State<_CreateAccountDialog> createState() => _CreateAccountDialogState();
}

class _CreateAccountDialogState extends State<_CreateAccountDialog> {
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();

  String _currency = 'PEN';
  String _type = 'bank';
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;

    final name = _nameController.text.trim();
    final balanceText = _balanceController.text.trim();

    if (name.isEmpty || balanceText.isEmpty) return;

    final balance = double.tryParse(balanceText);
    if (balance == null) return;

    setState(() {
      _saving = true;
    });

    try {
      await widget.onCreate(
        name: name,
        currency: _currency,
        type: _type,
        initialBalance: (balance * 100).round(),
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo crear la cuenta: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nueva cuenta'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              enabled: !_saving,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _currency,
              decoration: const InputDecoration(
                labelText: 'Moneda',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'PEN', child: Text('Soles (PEN)')),
                DropdownMenuItem(value: 'USD', child: Text('Dólares (USD)')),
              ],
              onChanged: _saving
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() {
                        _currency = value;
                      });
                    },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: 'Tipo',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'bank', child: Text('Banco')),
                DropdownMenuItem(value: 'cash', child: Text('Efectivo')),
              ],
              onChanged: _saving
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() {
                        _type = value;
                      });
                    },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _balanceController,
              enabled: !_saving,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Saldo inicial',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Crear'),
        ),
      ],
    );
  }
}

class _EditAccountDialog extends StatefulWidget {
  final Account account;
  final Future<void> Function({
    required String name,
    required String currency,
    required String type,
    required int initialBalance,
  }) onSave;

  const _EditAccountDialog({required this.account, required this.onSave});

  @override
  State<_EditAccountDialog> createState() => _EditAccountDialogState();
}

class _EditAccountDialogState extends State<_EditAccountDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _balanceController;
  late String _currency;
  late String _type;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.account.name);
    _balanceController = TextEditingController(
      text: (widget.account.initialBalance / 100).toStringAsFixed(2),
    );
    _currency = widget.account.currency;
    _type = widget.account.type;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;

    final name = _nameController.text.trim();
    final balanceText = _balanceController.text.trim();

    if (name.isEmpty || balanceText.isEmpty) return;

    final balance = double.tryParse(balanceText);
    if (balance == null) return;

    setState(() {
      _saving = true;
    });

    try {
      await widget.onSave(
        name: name,
        currency: _currency,
        type: _type,
        initialBalance: (balance * 100).round(),
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar la cuenta: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar cuenta'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              enabled: !_saving,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _currency,
              decoration: const InputDecoration(
                labelText: 'Moneda',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'PEN', child: Text('Soles (PEN)')),
                DropdownMenuItem(value: 'USD', child: Text('Dólares (USD)')),
              ],
              onChanged: _saving
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() {
                        _currency = value;
                      });
                    },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: 'Tipo',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'bank', child: Text('Banco')),
                DropdownMenuItem(value: 'cash', child: Text('Efectivo')),
              ],
              onChanged: _saving
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() {
                        _type = value;
                      });
                    },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _balanceController,
              enabled: !_saving,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Saldo inicial',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }
}

class _AccountView {
  final int id;
  final String name;
  final String currency;
  final String type;
  final int initialBalance;
  final int totalBalance;
  final int reservedBalance;
  final int freeBalance;
  final List<String> paymentMethods;

  const _AccountView({
    required this.id,
    required this.name,
    required this.currency,
    required this.type,
    required this.initialBalance,
    required this.totalBalance,
    required this.reservedBalance,
    required this.freeBalance,
    required this.paymentMethods,
  });
}