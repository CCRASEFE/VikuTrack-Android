// ==========================================
// ARCHIVO: lib/features/debts/debt_detail_page.dart
// ==========================================

import 'package:flutter/material.dart';

import '../../models/account.dart';
import '../../models/debt.dart';
import '../../repositories/account_repository.dart';
import '../../repositories/debt_repository.dart';
import '../../repositories/payment_method_repository.dart';

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
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.purple),
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
            '¿Estás seguro de que deseas eliminar esta deuda?\n'
            'Si ya tiene abonos registrados, se desactivará para proteger tus movimientos.',
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final subtextColor = isDark ? Colors.white70 : Colors.black54;

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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _debt!.description,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isPaidOff
                              ? (isDark ? Colors.green.shade900.withAlpha(80) : Colors.green.shade50)
                              : (isDark ? Colors.purple.shade900.withAlpha(80) : Colors.purple.shade50),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isPaidOff ? 'Completamente Pagada' : 'Pendiente de Pago',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isPaidOff
                                ? (isDark ? Colors.greenAccent : Colors.green.shade800)
                                : (isDark ? Colors.purpleAccent.shade100 : Colors.purple.shade900),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Pendiente:', style: TextStyle(fontSize: 12, color: subtextColor)),
                  Text(
                    _formatAmount(pending, _debt!.currency),
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: isPaidOff
                          ? (isDark ? Colors.greenAccent : Colors.green.shade800)
                          : (isDark ? Colors.purpleAccent.shade100 : Colors.purple.shade900),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isPaidOff ? Colors.green : (isDark ? Colors.purpleAccent : Colors.purple),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total: ${_formatAmount(_debt!.originalAmount, _debt!.currency)}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                      ),
                      Text(
                        'Abonado: ${_formatAmount(_paidTotal, _debt!.currency)} (${(progress * 100).toInt()}%)',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.greenAccent : Colors.green.shade800,
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
                  backgroundColor: isDark ? Colors.purple.shade700 : Colors.purple.shade800,
                ),
              ),
            ),
          const SizedBox(height: 24),

          Text(
            'Historial de Abonos Realizados',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
          ),
          const SizedBox(height: 8),

          if (_payments.isEmpty)
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'No se han realizado abonos a esta deuda aún.',
                    style: TextStyle(color: subtextColor),
                  ),
                ),
              ),
            )
          else
            ..._payments.map((p) {
              final amt = p['amount'] as int;
              final date = p['date'] as String;
              final time = p['time'] as String;
              final desc = p['description'] as String?;
              final acc = p['account_name'] as String;
              final method = p['payment_method_name'] as String;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isDark ? Colors.purple.shade900.withAlpha(100) : Colors.purple.shade50,
                    child: Icon(Icons.check, color: isDark ? Colors.purpleAccent.shade100 : Colors.purple.shade900, size: 20),
                  ),
                  title: Text(
                    desc?.isNotEmpty == true ? desc! : 'Abono a deuda',
                    style: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                  ),
                  subtitle: Text(
                    '$date · $time\nDesde: $acc ($method)',
                    style: TextStyle(fontSize: 12, color: subtextColor),
                  ),
                  isThreeLine: true,
                  trailing: Text(
                    _formatAmount(amt, _debt!.currency),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.purpleAccent.shade100 : Colors.purple.shade900,
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