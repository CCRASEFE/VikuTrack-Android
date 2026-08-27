// ==========================================
// ARCHIVO: lib/features/reservations/reservations_page.dart
// ==========================================

import 'package:flutter/material.dart';

import '../../core/app_themes.dart';
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
  List<Map<String, Object?>> _accounts = [];

  int _totalPEN = 0;
  int _totalUSD = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final reservations = await _reservationRepository.getActiveWithAccount();
    final loadedAccounts = await _accountRepository.getActive();
    final totals = await _reservationRepository.getTotalReservedByCurrency();

    final accountList = <Map<String, Object?>>[];
    for (final acc in loadedAccounts) {
      if (acc.id != null) {
        final balanceDetails = await _accountRepository.getBalanceDetails(acc.id!);
        accountList.add({
          'id': acc.id,
          'name': acc.name,
          'currency': acc.currency,
          'type': acc.type,
          'freeBalance': balanceDetails['free'] ?? 0,
          'totalBalance': balanceDetails['total'] ?? 0,
        });
      }
    }

    if (!mounted) return;

    setState(() {
      _reservations = reservations;
      _accounts = accountList;
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

  Widget _buildSummaryCard(AppThemeColors? themeColors) {
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
                  Icons.savings_outlined,
                  color: themeColors?.heroCardAccent ?? Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Total Dinero Reservado',
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
                        'Reservado en Soles',
                        style: TextStyle(
                          fontSize: 11,
                          color: (themeColors?.heroCardText ?? Colors.white).withAlpha(180),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatAmount(_totalPEN, 'PEN'),
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
                        'Reservado en Dólares',
                        style: TextStyle(
                          fontSize: 11,
                          color: (themeColors?.heroCardText ?? Colors.white).withAlpha(180),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatAmount(_totalUSD, 'USD'),
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
        title: const Text('Reservas de Dinero'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSummaryCard(themeColors),
                const SizedBox(height: 8),
                Text(
                  'Mis Fondos Reservados',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: themeColors?.cardBaseText ?? colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),

                if (_reservations.isEmpty)
                  Card(
                    elevation: 0,
                    color: themeColors?.cardBaseBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(color: themeColors?.cardBaseBorder ?? Colors.white12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'No tienes reservas activas.\n\n'
                          'Crea una reserva para apartar dinero de tus cuentas para metas o emergencias.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
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
                      color: themeColors?.cardBaseBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(color: themeColors?.cardBaseBorder ?? Colors.white12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: themeColors?.pillBg,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.savings_outlined,
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
                                        name,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: themeColors?.cardBaseText ?? colorScheme.onSurface,
                                        ),
                                      ),
                                      Text(
                                        'Cuenta: $accountName ($currency)',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  icon: Icon(
                                    Icons.more_vert,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
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
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatAmount(amount, currency),
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: themeColors?.cardAccentText ?? colorScheme.primary,
                                  ),
                                ),
                                if (reason?.isNotEmpty == true)
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: themeColors?.pillBg,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: themeColors?.pillBorder ?? Colors.transparent),
                                      ),
                                      child: Text(
                                        reason!,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: themeColors?.pillText ?? colorScheme.onSurface,
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
  final List<Map<String, Object?>> accounts;
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
      _selectedAccountId = widget.accounts.first['id'] as int?;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Map<String, Object?>? _findSelectedAccount() {
    if (_selectedAccountId == null) return null;
    for (final acc in widget.accounts) {
      if (acc['id'] == _selectedAccountId) return acc;
    }
    return null;
  }

  String _formatAmount(int amountInCents, String currency) {
    final amount = amountInCents / 100;
    return currency == 'USD' ? '\$${amount.toStringAsFixed(2)}' : 'S/ ${amount.toStringAsFixed(2)}';
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

    final amountInCents = (parsedAmount * 100).round();
    final currency = selectedAccount['currency'] as String;
    int availableToReserve = selectedAccount['freeBalance'] as int? ?? 0;

    // Si estamos editando y sigue en la misma cuenta, sumamos provisionalmente lo anterior
    if (widget.reservation != null && widget.reservation!.accountId == _selectedAccountId) {
      availableToReserve += widget.reservation!.amount;
    }

    // Validación preventiva en UI
    if (amountInCents > availableToReserve) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Fondos insuficientes en "${selectedAccount['name']}": '
            'Saldo libre disponible ${_formatAmount(availableToReserve, currency)}, intentas reservar ${_formatAmount(amountInCents, currency)}.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await widget.onSave(
        accountId: _selectedAccountId!,
        name: name,
        amount: amountInCents,
        currency: currency,
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
        SnackBar(content: Text('$error')),
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
                final id = acc['id'] as int;
                final name = acc['name'] as String;
                final currency = acc['currency'] as String;
                final freeBalance = acc['freeBalance'] as int? ?? 0;

                return DropdownMenuItem<int>(
                  value: id,
                  child: Text(
                    '$name ($currency) · Libre: ${_formatAmount(freeBalance, currency)}',
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