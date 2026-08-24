// ==========================================
// ARCHIVO: lib/features/reservations/reservations_page.dart
// ==========================================

import 'package:flutter/material.dart';

import '../../models/account.dart';
import '../../models/reservation.dart';
import '../../repositories/account_repository.dart';
import '../../repositories/reservation_repository.dart';

class ReservationsPage extends StatefulWidget {
  const ReservationsPage({super.key});

  @override
  State<ReservationsPage> createState() => _ReservationsPageState();
}

class _ReservationsPageState extends State<ReservationsPage> {
  final _reservationRepository = ReservationRepository();
  final _accountRepository = AccountRepository();

  bool _loading = true;
  List<Map<String, Object?>> _reservations = [];
  List<Account> _accounts = [];

  int _totalPEN = 0;
  int _totalUSD = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final reservations = await _reservationRepository.getActiveWithAccount();
    final accounts = await _accountRepository.getActive();
    final totals = await _reservationRepository.getTotalReservedByCurrency();

    if (!mounted) return;

    setState(() {
      _reservations = reservations;
      _accounts = accounts;
      _totalPEN = totals['PEN'] ?? 0;
      _totalUSD = totals['USD'] ?? 0;
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

  Future<void> _createReservation() async {
    if (_accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Necesitas tener al menos una cuenta activa.')),
      );
      return;
    }

    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return _ReservationDialog(
          accounts: _accounts,
          onSave: ({
            required int accountId,
            required String name,
            required int amount,
            required String currency,
            String? reason,
          }) async {
            await _reservationRepository.insert(
              Reservation(
                accountId: accountId,
                name: name,
                amount: amount,
                currency: currency,
                reason: reason,
              ),
            );
          },
        );
      },
    );

    if (created == true && mounted) {
      await _loadData();
    }
  }

  Future<void> _editReservation(Map<String, Object?> item) async {
    final id = item['id'] as int;
    final currentReservation = await _reservationRepository.getById(id);

    if (currentReservation == null || !mounted) return;

    final updated = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return _ReservationDialog(
          accounts: _accounts,
          reservation: currentReservation,
          onSave: ({
            required int accountId,
            required String name,
            required int amount,
            required String currency,
            String? reason,
          }) async {
            await _reservationRepository.update(
              Reservation(
                id: currentReservation.id,
                accountId: accountId,
                name: name,
                amount: amount,
                currency: currency,
                reason: reason,
                active: currentReservation.active,
              ),
            );
          },
        );
      },
    );

    if (updated == true && mounted) {
      await _loadData();
    }
  }

  Future<void> _deleteReservation(Map<String, Object?> item) async {
    final id = item['id'] as int;
    final name = item['name'] as String;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Liberar reserva'),
          content: Text(
            '¿Deseas liberar la reserva "$name"?\n\n'
            'El dinero volverá a figurar como disponible en su cuenta.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Liberar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    await _reservationRepository.delete(id);

    if (!mounted) return;
    await _loadData();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Reserva "$name" liberada.')),
    );
  }

  Widget _buildSummaryCard(bool isDark) {
    final bgColor = isDark ? Colors.deepPurple.shade900.withAlpha(80) : Colors.deepPurple.shade50;
    final borderColor = isDark ? Colors.deepPurple.shade700 : Colors.deepPurple.shade200;
    final titleColor = isDark ? Colors.deepPurple.shade200 : Colors.deepPurple.shade800;
    final amountColor = isDark ? Colors.purpleAccent.shade100 : Colors.deepPurple.shade900;
    final subtextColor = isDark ? Colors.white70 : Colors.black54;

    return Card(
      elevation: 0,
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lock_clock, color: titleColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Total Dinero Reservado',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Reservado en Soles', style: TextStyle(fontSize: 12, color: subtextColor)),
                      Text(
                        _formatAmount(_totalPEN, 'PEN'),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: amountColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(height: 36, width: 1, color: borderColor),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Reservado en Dólares', style: TextStyle(fontSize: 12, color: subtextColor)),
                      Text(
                        _formatAmount(_totalUSD, 'USD'),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: amountColor,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservas de Dinero'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSummaryCard(isDark),
                const SizedBox(height: 8),
                Text(
                  'Mis Fondos Reservados',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                ),
                const SizedBox(height: 8),

                if (_reservations.isEmpty)
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'No tienes reservas activas.\n\n'
                          'Crea una reserva para apartar dinero de tus cuentas para metas o emergencias.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                        ),
                      ),
                    ),
                  )
                else
                  ..._reservations.map((item) {
                    final name = item['name'] as String;
                    final amount = item['amount'] as int;
                    final currency = item['currency'] as String;
                    final accountName = item['account_name'] as String;
                    final reason = item['reason'] as String?;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: isDark
                                      ? Colors.deepPurple.shade900.withAlpha(120)
                                      : Colors.deepPurple.shade100,
                                  child: Icon(
                                    Icons.savings_outlined,
                                    color: isDark ? Colors.purpleAccent.shade100 : Colors.deepPurple.shade800,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                      Text(
                                        'Cuenta: $accountName ($currency)',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? Colors.white70 : Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (value) async {
                                    if (value == 'edit') {
                                      await _editReservation(item);
                                    }
                                    if (value == 'delete') {
                                      await _deleteReservation(item);
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
                                        'Liberar / Eliminar',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatAmount(amount, currency),
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.purpleAccent.shade100
                                        : Colors.deepPurple.shade900,
                                  ),
                                ),
                                if (reason?.isNotEmpty == true)
                                  Flexible(
                                    child: Chip(
                                      visualDensity: VisualDensity.compact,
                                      backgroundColor: colorScheme.surfaceContainerHighest,
                                      side: BorderSide(color: colorScheme.outlineVariant),
                                      label: Text(
                                        reason!,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: colorScheme.onSurface,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createReservation,
        icon: const Icon(Icons.add),
        label: const Text('Nueva reserva'),
      ),
    );
  }
}

class _ReservationDialog extends StatefulWidget {
  final List<Account> accounts;
  final Reservation? reservation;
  final Future<void> Function({
    required int accountId,
    required String name,
    required int amount,
    required String currency,
    String? reason,
  }) onSave;

  const _ReservationDialog({
    required this.accounts,
    this.reservation,
    required this.onSave,
  });

  @override
  State<_ReservationDialog> createState() => _ReservationDialogState();
}

class _ReservationDialogState extends State<_ReservationDialog> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();

  int? _selectedAccountId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.reservation != null) {
      _nameController.text = widget.reservation!.name;
      _amountController.text = (widget.reservation!.amount / 100).toStringAsFixed(2);
      _reasonController.text = widget.reservation!.reason ?? '';
      _selectedAccountId = widget.reservation!.accountId;
    } else if (widget.accounts.isNotEmpty) {
      _selectedAccountId = widget.accounts.first.id;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Account? _findSelectedAccount() {
    if (_selectedAccountId == null) return null;
    for (final acc in widget.accounts) {
      if (acc.id == _selectedAccountId) return acc;
    }
    return null;
  }

  Future<void> _save() async {
    if (_saving) return;

    final name = _nameController.text.trim();
    final amountText = _amountController.text.trim();
    final reason = _reasonController.text.trim();

    if (name.isEmpty || amountText.isEmpty || _selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos obligatorios.')),
      );
      return;
    }

    final normalized = amountText.replaceAll(',', '.');
    final parsedAmount = double.tryParse(normalized);

    if (parsedAmount == null || parsedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un importe válido.')),
      );
      return;
    }

    final selectedAccount = _findSelectedAccount();
    if (selectedAccount == null) return;

    setState(() {
      _saving = true;
    });

    try {
      await widget.onSave(
        accountId: _selectedAccountId!,
        name: name,
        amount: (parsedAmount * 100).round(),
        currency: selectedAccount.currency,
        reason: reason.isEmpty ? null : reason,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar reserva: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.reservation != null;

    return AlertDialog(
      title: Text(isEditing ? 'Editar reserva' : 'Nueva reserva'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              enabled: !_saving,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nombre *',
                hintText: 'Ej. Fondo de emergencia',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              key: const ValueKey('reservation_account_select'),
              isExpanded: true,
              initialValue: _selectedAccountId,
              decoration: const InputDecoration(
                labelText: 'Cuenta asociada *',
                border: OutlineInputBorder(),
              ),
              items: widget.accounts.map((acc) {
                return DropdownMenuItem<int>(
                  value: acc.id,
                  child: Text(
                    '${acc.name} (${acc.currency})',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                );
              }).toList(),
              onChanged: _saving
                  ? null
                  : (value) {
                      setState(() {
                        _selectedAccountId = value;
                      });
                    },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              enabled: !_saving,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Importe a reservar *',
                hintText: '0.00',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              enabled: !_saving,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Motivo (opcional)',
                hintText: 'Ej. Meta para fin de año',
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
              : Text(isEditing ? 'Guardar' : 'Crear reserva'),
        ),
      ],
    );
  }
}