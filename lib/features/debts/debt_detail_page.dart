// ==========================================
// ARCHIVO: lib/features/debts/debt_detail_page.dart
// ==========================================

import 'package:flutter/material.dart';

import '../../core/app_themes.dart';
import '../../models/account.dart';
import '../../models/debt.dart';
import '../../repositories/account_repository.dart';
import '../../repositories/debt_repository.dart';
import '../../repositories/payment_method_repository.dart';
import '../transactions/edit_transaction_page.dart';

class DebtDetailPage extends StatefulWidget {
  final int debtId;

  const DebtDetailPage({super.key, required this.debtId});

  @override
  State<DebtDetailPage> createState() => _DebtDetailPageState();
}

class _DebtDetailPageState extends State<DebtDetailPage> {
  final _debtRepository = DebtRepository();
  final _accountRepository = AccountRepository();
  final _paymentMethodRepository = PaymentMethodRepository();

  bool _loading = true;
  Debt? _debt;
  List<Map<String, Object?>> _payments = [];
  List<Account> _accounts = [];

  int _paidTotal = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final debt = await _debtRepository.getDebtById(widget.debtId);
    final history = await _debtRepository.getPaymentHistory(widget.debtId);
    final accounts = await _accountRepository.getActive();

    if (!mounted) return;

    int paid = 0;
    for (final row in history) {
      paid += (row['amount'] as num?)?.toInt() ?? 0;
    }

    setState(() {
      _debt = debt;
      _payments = history;
      _accounts = accounts;
      _paidTotal = paid;
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

  Future<void> _editDebt() async {
    if (_debt == null) return;

    final descController = TextEditingController(text: _debt!.description);
    final amountController = TextEditingController(
      text: (_debt!.originalAmount / 100).toStringAsFixed(2),
    );
    String currency = _debt!.currency;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Editar Deuda'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: descController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Descripción / Acreedor *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: currency,
                      decoration: const InputDecoration(
                        labelText: 'Moneda',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'PEN', child: Text('Soles (PEN)')),
                        DropdownMenuItem(value: 'USD', child: Text('Dólares (USD)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => currency = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Monto total de la deuda *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved == true && mounted) {
      final desc = descController.text.trim();
      final amt = (double.tryParse(amountController.text.replaceAll(',', '.')) ?? 0) * 100;
      final newAmountCents = amt.round();

      if (desc.isEmpty || newAmountCents <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ingresa una descripción y un monto válido.')),
        );
        return;
      }

      if (newAmountCents < _paidTotal) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'El monto total no puede ser menor a lo que ya has abonado (${_formatAmount(_paidTotal, _debt!.currency)}).',
            ),
          ),
        );
        return;
      }

      await _debtRepository.updateDebt(
        Debt(
          id: _debt!.id,
          description: desc,
          originalAmount: newAmountCents,
          currency: currency,
          date: _debt!.date,
          active: _debt!.active,
        ),
      );

      await _loadData();
    }
  }

  Future<void> _makePayment() async {
    if (_debt == null || _accounts.isEmpty) return;

    final pending = _debt!.originalAmount - _paidTotal;
    if (pending <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esta deuda ya está totalmente pagada.')),
      );
      return;
    }

    final amountController = TextEditingController(
      text: (pending / 100).toStringAsFixed(2),
    );
    final noteController = TextEditingController();
    int? selectedAccountId = _accounts.first.id;
    List<Map<String, Object?>> methods = await _paymentMethodRepository.getByAccount(selectedAccountId!);
    int? selectedPaymentMethodId = methods.isNotEmpty ? methods.first['id'] as int : null;

    if (!mounted) return;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final themeColors = Theme.of(context).extension<AppThemeColors>();

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Abonar / Pagar Deuda'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Saldo pendiente actual: ${_formatAmount(pending, _debt!.currency)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: themeColors?.cardAccentText ?? Colors.amber,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Monto a pagar *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      isExpanded: true,
                      initialValue: selectedAccountId,
                      decoration: const InputDecoration(
                        labelText: 'Cuenta de donde sale el dinero *',
                        border: OutlineInputBorder(),
                      ),
                      items: _accounts.map((acc) {
                        return DropdownMenuItem<int>(
                          value: acc.id,
                          child: Text(
                            '${acc.name} (${acc.currency})',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) async {
                        if (val != null) {
                          final loadedMethods = await _paymentMethodRepository.getByAccount(val);
                          setDialogState(() {
                            selectedAccountId = val;
                            methods = loadedMethods;
                            selectedPaymentMethodId = methods.isNotEmpty ? methods.first['id'] as int : null;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    if (methods.isNotEmpty)
                      DropdownButtonFormField<int>(
                        isExpanded: true,
                        initialValue: selectedPaymentMethodId,
                        decoration: const InputDecoration(
                          labelText: 'Medio de pago *',
                          border: OutlineInputBorder(),
                        ),
                        items: methods.map((m) {
                          return DropdownMenuItem<int>(
                            value: m['id'] as int,
                            child: Text(
                              m['name'] as String,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setDialogState(() => selectedPaymentMethodId = val);
                        },
                      ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: noteController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Nota / Detalle (opcional)',
                        hintText: 'Ej. Cuota 1 de 3',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Confirmar Pago'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved == true && mounted) {
      final amt = (double.tryParse(amountController.text.replaceAll(',', '.')) ?? 0) * 100;
      final note = noteController.text.trim();

      if (amt > 0 && selectedAccountId != null && selectedPaymentMethodId != null) {
        final now = DateTime.now();
        final year = now.year.toString();
        final month = now.month.toString().padLeft(2, '0');
        final day = now.day.toString().padLeft(2, '0');

        await _debtRepository.registerPayment(
          debtId: widget.debtId,
          amount: amt.round(),
          accountId: selectedAccountId!,
          paymentMethodId: selectedPaymentMethodId!,
          date: '$year-$month-$day',
          note: note.isNotEmpty ? note : 'Abono a: ${_debt!.description}',
        );

        await _loadData();
      }
    }
  }

  Future<void> _deleteDebt() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar deuda'),
          content: const Text(
            '¿Estás seguro de que deseas eliminar esta deuda?\n\n'
            'Se eliminará la deuda y todas sus operaciones de abono registradas, restaurando el saldo de tus cuentas.',
          ),
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

    if (confirmed == true && mounted) {
      await _debtRepository.deleteDebt(widget.debtId);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _openEditPaymentTransaction(int transactionId) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditTransactionPage(transactionId: transactionId),
      ),
    );

    if (result == true && mounted) {
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = Theme.of(context).extension<AppThemeColors>();
    final colorScheme = Theme.of(context).colorScheme;

    if (_loading || _debt == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle de Deuda')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final pending = (_debt!.originalAmount - _paidTotal).clamp(0, _debt!.originalAmount);
    final progress = _debt!.originalAmount > 0 ? (_paidTotal / _debt!.originalAmount).clamp(0.0, 1.0) : 0.0;
    final isPaidOff = pending == 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(_debt!.description),
        actions: [
          IconButton(
            onPressed: _editDebt,
            icon: Icon(Icons.edit_outlined, color: themeColors?.cardAccentText ?? colorScheme.primary),
            tooltip: 'Editar deuda',
          ),
          IconButton(
            onPressed: _deleteDebt,
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Eliminar deuda',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 2,
            color: themeColors?.cardBaseBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: themeColors?.cardBaseBorder ?? Colors.white12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          _debt!.description,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: themeColors?.cardBaseText ?? colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isPaidOff
                              ? (themeColors?.savingsBg ?? Colors.green)
                              : themeColors?.pillBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: themeColors?.pillBorder ?? Colors.transparent),
                        ),
                        child: Text(
                          isPaidOff ? 'Pagada' : 'Pendiente',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isPaidOff
                                ? (themeColors?.savingsText ?? Colors.white)
                                : (themeColors?.cardAccentText ?? colorScheme.primary),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Pendiente:', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                  Text(
                    _formatAmount(pending, _debt!.currency),
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: isPaidOff
                          ? colorScheme.onSurfaceVariant
                          : (themeColors?.cardAccentText ?? colorScheme.primary),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        themeColors?.cardAccentText ?? colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total: ${_formatAmount(_debt!.originalAmount, _debt!.currency)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: themeColors?.cardBaseText,
                        ),
                      ),
                      Text(
                        'Abonado: ${_formatAmount(_paidTotal, _debt!.currency)} (${(progress * 100).toInt()}%)',
                        style: TextStyle(
                          fontSize: 12,
                          color: themeColors?.cardAccentText ?? colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          if (!isPaidOff)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _makePayment,
                icon: const Icon(Icons.payment),
                label: const Text('Realizar Abono / Pago'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: themeColors?.fabBg ?? colorScheme.primary,
                  foregroundColor: themeColors?.fabText ?? Colors.black,
                ),
              ),
            ),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Historial de Abonos Realizados',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: themeColors?.cardBaseText ?? colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Toca cualquier abono para editar o eliminar la operación:',
            style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),

          if (_payments.isEmpty)
            Card(
              elevation: 0,
              color: themeColors?.cardBaseBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: themeColors?.cardBaseBorder ?? Colors.white12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'No se han realizado abonos a esta deuda aún.',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
            )
          else
            ..._payments.map((p) {
              final transactionId = p['transaction_id'] as int;
              final amt = p['amount'] as int;
              final date = p['date'] as String;
              final time = p['time'] as String;
              final desc = p['description'] as String?;
              final acc = p['account_name'] as String;
              final method = p['payment_method_name'] as String;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: themeColors?.cardBaseBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: themeColors?.cardBaseBorder ?? Colors.white12),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _openEditPaymentTransaction(transactionId),
                  child: ListTile(
                    leading: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: themeColors?.pillBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.check,
                        color: themeColors?.cardAccentText ?? colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      desc?.isNotEmpty == true ? desc! : 'Abono a deuda',
                      style: TextStyle(fontWeight: FontWeight.w600, color: themeColors?.cardBaseText),
                    ),
                    subtitle: Text(
                      '$date · $time\nDesde: $acc ($method)',
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatAmount(amt, _debt!.currency),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: themeColors?.cardAccentText ?? colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right, size: 16, color: colorScheme.onSurfaceVariant),
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