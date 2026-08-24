// ==========================================
// ARCHIVO: lib/features/debts/debts_page.dart
// ==========================================

import 'package:flutter/material.dart';

import '../../models/debt.dart';
import '../../models/person_owed.dart';
import '../../repositories/debt_repository.dart';
import '../../repositories/people_owed_repository.dart';
import 'debt_detail_page.dart';

class DebtsPage extends StatefulWidget {
  const DebtsPage({super.key});

  @override
  State<DebtsPage> createState() => _DebtsPageState();
}

class _DebtsPageState extends State<DebtsPage> {
  final _debtRepository = DebtRepository();
  final _peopleOwedRepository = PeopleOwedRepository();

  bool _loading = true;
  String _selectedSection = 'debts';

  List<Map<String, Object?>> _debts = [];
  List<PersonOwed> _peopleOwed = [];

  int _pendingDebtsPEN = 0;
  int _pendingDebtsUSD = 0;

  int _owedToMePEN = 0;
  int _owedToMeUSD = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final debts = await _debtRepository.getActiveDebtsWithProgress();
    final people = await _peopleOwedRepository.getActive();
    final debtTotals = await _debtRepository.getTotalPendingDebtsByCurrency();
    final peopleTotals = await _peopleOwedRepository.getTotalOwedToMeByCurrency();

    if (!mounted) return;

    setState(() {
      _debts = debts;
      _peopleOwed = people;
      _pendingDebtsPEN = debtTotals['PEN'] ?? 0;
      _pendingDebtsUSD = debtTotals['USD'] ?? 0;
      _owedToMePEN = peopleTotals['PEN'] ?? 0;
      _owedToMeUSD = peopleTotals['USD'] ?? 0;
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

  Future<void> _createDebt() async {
    final descController = TextEditingController();
    final amountController = TextEditingController();
    String currency = 'PEN';
    DateTime date = DateTime.now();

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Nueva Deuda (Yo Debo)'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: descController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Descripción / Acreedor *',
                        hintText: 'Ej. Préstamo Juan o Tarjeta Ripley',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
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
                        hintText: '0.00',
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

      if (desc.isNotEmpty && amt > 0) {
        final year = date.year.toString();
        final month = date.month.toString().padLeft(2, '0');
        final day = date.day.toString().padLeft(2, '0');

        await _debtRepository.insertDebt(
          Debt(
            description: desc,
            originalAmount: amt.round(),
            currency: currency,
            date: '$year-$month-$day',
          ),
        );
        await _loadData();
      }
    }
  }

  Future<void> _createPersonOwed() async {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    String currency = 'PEN';
    DateTime date = DateTime.now();

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Persona que me debe'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de la persona *',
                        hintText: 'Ej. Carlos Méndez',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
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
                        labelText: 'Monto que me debe *',
                        hintText: '0.00',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: noteController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Nota / Motivo (opcional)',
                        hintText: 'Ej. Préstamo para almuerzo',
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
      final name = nameController.text.trim();
      final amt = (double.tryParse(amountController.text.replaceAll(',', '.')) ?? 0) * 100;
      final note = noteController.text.trim();

      if (name.isNotEmpty && amt > 0) {
        final year = date.year.toString();
        final month = date.month.toString().padLeft(2, '0');
        final day = date.day.toString().padLeft(2, '0');

        await _peopleOwedRepository.insert(
          PersonOwed(
            name: name,
            amount: amt.round(),
            currency: currency,
            note: note.isEmpty ? null : note,
            date: '$year-$month-$day',
          ),
        );
        await _loadData();
      }
    }
  }

  Future<void> _deletePersonOwed(PersonOwed p) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Marcar como cobrado / Eliminar'),
          content: Text('¿Deseas eliminar el registro de deuda de "${p.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      await _peopleOwedRepository.delete(p.id!);
      await _loadData();
    }
  }

  Widget _buildSummaryHeader(bool isDark) {
    final isDebts = _selectedSection == 'debts';
    final title = isDebts ? 'Total Pendiente por Pagar' : 'Total por Cobrar a Favor';
    final pen = isDebts ? _pendingDebtsPEN : _owedToMePEN;
    final usd = isDebts ? _pendingDebtsUSD : _owedToMeUSD;
    final color = isDebts
        ? (isDark ? Colors.purpleAccent.shade100 : Colors.purple.shade900)
        : (isDark ? Colors.tealAccent : Colors.teal.shade900);
    final bgColor = isDebts
        ? (isDark ? Colors.purple.shade900.withAlpha(80) : Colors.purple.shade50)
        : (isDark ? Colors.teal.shade900.withAlpha(80) : Colors.teal.shade50);
    final borderColor = isDebts
        ? (isDark ? Colors.purple.shade700 : Colors.purple.shade200)
        : (isDark ? Colors.teal.shade700 : Colors.teal.shade200);
    final subtextColor = isDark ? Colors.white70 : Colors.black54;

    return Card(
      elevation: 0,
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(isDebts ? Icons.credit_card_off : Icons.volunteer_activism, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
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
                      Text('En Soles', style: TextStyle(fontSize: 11, color: subtextColor)),
                      Text(
                        _formatAmount(pen, 'PEN'),
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
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
                      Text('En Dólares', style: TextStyle(fontSize: 11, color: subtextColor)),
                      Text(
                        _formatAmount(usd, 'USD'),
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
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

  Widget _buildSectionSwitcher() {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(
          value: 'debts',
          label: Text('Debo Yo (Deudas)'),
          icon: Icon(Icons.arrow_upward, size: 16, color: Colors.purple),
        ),
        ButtonSegment(
          value: 'people',
          label: Text('Me Deben (Préstamos)'),
          icon: Icon(Icons.arrow_downward, size: 16, color: Colors.teal),
        ),
      ],
      selected: {_selectedSection},
      onSelectionChanged: (val) {
        if (val.isNotEmpty) {
          setState(() {
            _selectedSection = val.first;
          });
        }
      },
    );
  }

  Widget _buildDebtsList(bool isDark) {
    final colorScheme = Theme.of(context).colorScheme;
    final subtextColor = isDark ? Colors.white70 : Colors.black54;

    if (_debts.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(
              'No tienes deudas pendientes registradas.\n¡Excelente estado financiero!',
              textAlign: TextAlign.center,
              style: TextStyle(color: subtextColor),
            ),
          ),
        ),
      );
    }

    return Column(
      children: _debts.map((d) {
        final id = d['id'] as int;
        final desc = d['description'] as String;
        final original = d['original_amount'] as int;
        final paid = (d['paid_amount'] as num?)?.toInt() ?? 0;
        final currency = d['currency'] as String;
        final date = d['date'] as String;
        final pending = (original - paid).clamp(0, original);
        final progress = original > 0 ? (paid / original).clamp(0.0, 1.0) : 0.0;
        final isPaidOff = pending == 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () async {
              final res = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DebtDetailPage(debtId: id),
                ),
              );
              if (res == true && mounted) {
                await _loadData();
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: isDark ? Colors.purple.shade900.withAlpha(100) : Colors.purple.shade50,
                        child: Icon(Icons.handshake_outlined, color: isDark ? Colors.purpleAccent.shade100 : Colors.purple.shade900, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              desc,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                            ),
                            Text('Registrada: $date', style: TextStyle(fontSize: 11, color: subtextColor)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isPaidOff
                              ? (isDark ? Colors.green.shade900.withAlpha(80) : Colors.green.shade50)
                              : (isDark ? Colors.purple.shade900.withAlpha(80) : Colors.purple.shade50),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isPaidOff ? 'Pagada' : 'Pendiente',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isPaidOff
                                ? (isDark ? Colors.greenAccent : Colors.green.shade800)
                                : (isDark ? Colors.purpleAccent.shade100 : Colors.purple.shade900),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pendiente por pagar', style: TextStyle(fontSize: 11, color: subtextColor)),
                          Text(
                            _formatAmount(pending, currency),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isPaidOff
                                  ? (isDark ? Colors.greenAccent : Colors.green.shade800)
                                  : (isDark ? Colors.purpleAccent.shade100 : Colors.purple.shade900),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Total original', style: TextStyle(fontSize: 11, color: subtextColor)),
                          Text(
                            _formatAmount(original, currency),
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isPaidOff ? Colors.green : (isDark ? Colors.purpleAccent : Colors.purple),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Abonado: ${_formatAmount(paid, currency)} (${(progress * 100).toInt()}%)',
                        style: TextStyle(fontSize: 11, color: subtextColor),
                      ),
                      Text(
                        'Ver detalles e historial >',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.purpleAccent.shade100 : Colors.purple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPeopleOwedList(bool isDark) {
    final colorScheme = Theme.of(context).colorScheme;
    final subtextColor = isDark ? Colors.white70 : Colors.black54;

    if (_peopleOwed.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(
              'No tienes cuentas por cobrar pendientes.\nNadie te debe dinero actualmente.',
              textAlign: TextAlign.center,
              style: TextStyle(color: subtextColor),
            ),
          ),
        ),
      );
    }

    return Column(
      children: _peopleOwed.map((p) {
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isDark ? Colors.teal.shade900.withAlpha(100) : Colors.teal.shade50,
              child: Text(
                p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.tealAccent : Colors.teal.shade900),
              ),
            ),
            title: Text(p.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.onSurface)),
            subtitle: Text(
              p.note?.isNotEmpty == true ? '${p.date} · ${p.note!}' : p.date,
              style: TextStyle(fontSize: 12, color: subtextColor),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatAmount(p.amount, p.currency),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.tealAccent : Colors.teal.shade800,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.check_circle_outline, color: Colors.teal),
                  tooltip: 'Marcar como cobrado',
                  onPressed: () => _deletePersonOwed(p),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deudas y Préstamos'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSummaryHeader(isDark),
                  const SizedBox(height: 16),
                  _buildSectionSwitcher(),
                  const SizedBox(height: 16),
                  if (_selectedSection == 'debts') _buildDebtsList(isDark) else _buildPeopleOwedList(isDark),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _selectedSection == 'debts' ? _createDebt : _createPersonOwed,
        icon: const Icon(Icons.add),
        label: Text(_selectedSection == 'debts' ? 'Nueva deuda' : 'Nuevo préstamo'),
      ),
    );
  }
}