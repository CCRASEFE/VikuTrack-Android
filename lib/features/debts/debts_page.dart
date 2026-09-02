// ==========================================
// ARCHIVO: lib/features/debts/debts_page.dart
// ==========================================

import 'package:flutter/material.dart';

import '../../core/app_themes.dart';
import '../../models/debt.dart';
import '../../models/person_owed.dart';
import '../../models/planned_purchase.dart';
import '../../repositories/debt_repository.dart';
import '../../repositories/people_owed_repository.dart';
import '../../repositories/planned_purchase_repository.dart';
import '../transactions/create_transaction_page.dart';
import 'debt_detail_page.dart';

class DebtsPage extends StatefulWidget {
  const DebtsPage({super.key});

  @override
  State<DebtsPage> createState() => _DebtsPageState();
}

class _DebtsPageState extends State<DebtsPage> {
  final _debtRepository = DebtRepository();
  final _peopleOwedRepository = PeopleOwedRepository();
  final _plannedPurchaseRepository = PlannedPurchaseRepository();

  bool _loading = true;
  String _selectedSection = 'debts'; // 'debts', 'people', 'planned'

  List<Map<String, Object?>> _debts = [];
  List<PersonOwed> _peopleOwed = [];
  List<PlannedPurchase> _plannedPurchases = [];

  int _pendingDebtsPEN = 0;
  int _pendingDebtsUSD = 0;

  int _owedToMePEN = 0;
  int _owedToMeUSD = 0;

  int _plannedPEN = 0;
  int _plannedUSD = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final debts = await _debtRepository.getActiveDebtsWithProgress();
    final people = await _peopleOwedRepository.getActive();
    final planned = await _plannedPurchaseRepository.getActive();

    final debtTotals = await _debtRepository.getTotalPendingDebtsByCurrency();
    final peopleTotals = await _peopleOwedRepository.getTotalOwedToMeByCurrency();
    final plannedTotals = await _plannedPurchaseRepository.getTotalEstimatedByCurrency();

    if (!mounted) return;

    setState(() {
      _debts = debts;
      _peopleOwed = people;
      _plannedPurchases = planned;

      _pendingDebtsPEN = debtTotals['PEN'] ?? 0;
      _pendingDebtsUSD = debtTotals['USD'] ?? 0;

      _owedToMePEN = peopleTotals['PEN'] ?? 0;
      _owedToMeUSD = peopleTotals['USD'] ?? 0;

      _plannedPEN = plannedTotals['PEN'] ?? 0;
      _plannedUSD = plannedTotals['USD'] ?? 0;

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

  Future<void> _createPlannedPurchase() async {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    String currency = 'PEN';

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Nueva Compra Planeada'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: '¿Qué vas a comprar? *',
                        hintText: 'Ej. Manillar de bicicleta',
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
                        labelText: 'Precio estimado / fijo *',
                        hintText: '0.00',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: noteController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Nota / Detalle (opcional)',
                        hintText: 'Ej. Tienda Bike Perú',
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
        await _plannedPurchaseRepository.insert(
          PlannedPurchase(
            name: name,
            amount: amt.round(),
            currency: currency,
            note: note.isEmpty ? null : note,
          ),
        );
        await _loadData();
      }
    }
  }

  Future<void> _editPersonOwed(PersonOwed p) async {
    final nameController = TextEditingController(text: p.name);
    final amountController = TextEditingController(
      text: (p.amount / 100).toStringAsFixed(2),
    );
    final noteController = TextEditingController(text: p.note ?? '');
    String currency = p.currency;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Editar Deuda / Préstamo'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de la persona *',
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
                        labelText: 'Monto que me debe *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: noteController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Nota / Motivo (opcional)',
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
        await _peopleOwedRepository.update(
          PersonOwed(
            id: p.id,
            name: name,
            amount: amt.round(),
            currency: currency,
            note: note.isEmpty ? null : note,
            date: p.date,
            active: p.active,
          ),
        );
        await _loadData();
      }
    }
  }

  Future<void> _editPlannedPurchase(PlannedPurchase item) async {
    final nameController = TextEditingController(text: item.name);
    final amountController = TextEditingController(
      text: (item.amount / 100).toStringAsFixed(2),
    );
    final noteController = TextEditingController(text: item.note ?? '');
    String currency = item.currency;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Editar Compra Planeada'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: '¿Qué vas a comprar? *',
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
                        labelText: 'Precio estimado *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: noteController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Nota / Detalle (opcional)',
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
        await _plannedPurchaseRepository.update(
          PlannedPurchase(
            id: item.id,
            name: name,
            amount: amt.round(),
            currency: currency,
            note: note.isEmpty ? null : note,
            active: item.active,
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

  Future<void> _deletePlannedPurchase(PlannedPurchase item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar compra planeada'),
          content: Text('¿Deseas eliminar "${item.name}" de tus compras planeadas?'),
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
      await _plannedPurchaseRepository.delete(item.id!);
      await _loadData();
    }
  }

  Future<void> _executePurchase(PlannedPurchase item) async {
    final bought = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateTransactionPage(
          initialType: 'expense',
          initialDescription: item.name,
          initialAmount: item.amount,
          lockType: true,
        ),
      ),
    );

    if (bought == true && mounted) {
      await _plannedPurchaseRepository.delete(item.id!);
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('¡"${item.name}" comprado y registrado como gasto real!')),
      );
    }
  }

  void _showSettledDebtsDialog() {
    final themeColors = Theme.of(context).extension<AppThemeColors>();
    final colorScheme = Theme.of(context).colorScheme;

    final settledDebts = _debts.where((d) {
      final original = d['original_amount'] as int;
      final paid = (d['paid_amount'] as num?)?.toInt() ?? 0;
      return (original - paid) <= 0;
    }).toList();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Deudas Totalmente Pagadas'),
          content: SizedBox(
            width: double.maxFinite,
            child: settledDebts.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No tienes deudas saldadas en el historial.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: settledDebts.length,
                    itemBuilder: (context, index) {
                      final d = settledDebts[index];
                      final id = d['id'] as int;
                      final desc = d['description'] as String;
                      final original = d['original_amount'] as int;
                      final currency = d['currency'] as String;

                      return ListTile(
                        leading: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: themeColors?.pillBg,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.check, color: themeColors?.cardAccentText, size: 18),
                        ),
                        title: Text(desc, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(
                          'Total saldado: ${_formatAmount(original, currency)}',
                          style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                        ),
                        trailing: const Icon(Icons.chevron_right, size: 16),
                        onTap: () async {
                          Navigator.of(dialogContext).pop();
                          final res = await Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => DebtDetailPage(debtId: id)),
                          );
                          if (res == true && mounted) {
                            await _loadData();
                          }
                        },
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryHeader(AppThemeColors? themeColors) {
    String title;
    int pen;
    int usd;

    if (_selectedSection == 'debts') {
      title = 'Total Pendiente por Pagar';
      pen = _pendingDebtsPEN;
      usd = _pendingDebtsUSD;
    } else if (_selectedSection == 'people') {
      title = 'Total por Cobrar a Favor';
      pen = _owedToMePEN;
      usd = _owedToMeUSD;
    } else {
      title = 'Total Proyectado por Comprar';
      pen = _plannedPEN;
      usd = _plannedUSD;
    }

    return Card(
      elevation: 3,
      color: themeColors?.heroCardBg ?? Theme.of(context).colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: themeColors?.heroCardBorder ?? Colors.transparent),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _selectedSection == 'debts'
                      ? Icons.credit_card_off
                      : (_selectedSection == 'people' ? Icons.volunteer_activism : Icons.shopping_bag_outlined),
                  color: themeColors?.heroCardAccent ?? Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
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
                        'En Soles',
                        style: TextStyle(
                          fontSize: 11,
                          color: (themeColors?.heroCardText ?? Colors.white).withAlpha(180),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatAmount(pen, 'PEN'),
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
                        'En Dólares',
                        style: TextStyle(
                          fontSize: 11,
                          color: (themeColors?.heroCardText ?? Colors.white).withAlpha(180),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatAmount(usd, 'USD'),
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

  Widget _buildSectionSwitcher(AppThemeColors? themeColors) {
    return SegmentedButton<String>(
      style: const ButtonStyle(
        visualDensity: VisualDensity.compact,
      ),
      segments: [
        ButtonSegment(
          value: 'debts',
          label: const Text('Debo Yo', style: TextStyle(fontSize: 11)),
          icon: Icon(Icons.arrow_upward, size: 13, color: themeColors?.cardAccentText),
        ),
        ButtonSegment(
          value: 'people',
          label: const Text('Me Deben', style: TextStyle(fontSize: 11)),
          icon: Icon(Icons.arrow_downward, size: 13, color: themeColors?.cardAccentText),
        ),
        ButtonSegment(
          value: 'planned',
          label: const Text('Por Comprar', style: TextStyle(fontSize: 11)),
          icon: Icon(Icons.shopping_bag_outlined, size: 13, color: themeColors?.cardAccentText),
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

  Widget _buildDebtsList(AppThemeColors? themeColors) {
    final colorScheme = Theme.of(context).colorScheme;

    // Filtramos para mostrar ÚNICAMENTE las deudas que tienen saldo pendiente > 0
    final pendingDebts = _debts.where((d) {
      final original = d['original_amount'] as int;
      final paid = (d['paid_amount'] as num?)?.toInt() ?? 0;
      return (original - paid) > 0;
    }).toList();

    if (pendingDebts.isEmpty) {
      return Card(
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
              'No tienes deudas pendientes por pagar.\n¡Excelente estado financiero!',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
        ),
      );
    }

    return Column(
      children: pendingDebts.map((d) {
        final id = d['id'] as int;
        final desc = d['description'] as String;
        final original = d['original_amount'] as int;
        final paid = (d['paid_amount'] as num?)?.toInt() ?? 0;
        final currency = d['currency'] as String;
        final date = d['date'] as String;
        final pending = (original - paid).clamp(0, original);
        final progress = original > 0 ? (paid / original).clamp(0.0, 1.0) : 0.0;

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
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: themeColors?.pillBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.handshake_outlined,
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
                              desc,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: themeColors?.cardBaseText ?? colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              'Registrada: $date',
                              style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: themeColors?.pillBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: themeColors?.pillBorder ?? Colors.transparent),
                        ),
                        child: Text(
                          'Pendiente',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: themeColors?.cardAccentText ?? colorScheme.primary,
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
                          Text('Pendiente por pagar', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                          Text(
                            _formatAmount(pending, currency),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: themeColors?.cardAccentText ?? colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Total original', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                          Text(
                            _formatAmount(original, currency),
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: themeColors?.cardBaseText),
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
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        themeColors?.cardAccentText ?? colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Abonado: ${_formatAmount(paid, currency)} (${(progress * 100).toInt()}%)',
                        style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                      ),
                      Text(
                        'Ver detalles e historial >',
                        style: TextStyle(
                          fontSize: 11,
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
        );
      }).toList(),
    );
  }

  Widget _buildPeopleOwedList(AppThemeColors? themeColors) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_peopleOwed.isEmpty) {
      return Card(
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
              'No tienes cuentas por cobrar pendientes.\nNadie te debe dinero actualmente.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
        ),
      );
    }

    return Column(
      children: _peopleOwed.map((p) {
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          color: themeColors?.cardBaseBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: themeColors?.cardBaseBorder ?? Colors.white12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _editPersonOwed(p),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: themeColors?.pillBg,
                child: Text(
                  p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: themeColors?.cardAccentText ?? colorScheme.primary,
                  ),
                ),
              ),
              title: Text(
                p.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: themeColors?.cardBaseText ?? colorScheme.onSurface,
                ),
              ),
              subtitle: Text(
                p.note?.isNotEmpty == true ? '${p.date} · ${p.note!}' : p.date,
                style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatAmount(p.amount, p.currency),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: themeColors?.cardAccentText ?? colorScheme.primary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit_outlined, color: colorScheme.onSurfaceVariant, size: 20),
                    tooltip: 'Editar préstamo',
                    onPressed: () => _editPersonOwed(p),
                  ),
                  IconButton(
                    icon: Icon(Icons.check_circle_outline, color: themeColors?.cardAccentText),
                    tooltip: 'Marcar como cobrado / Eliminar',
                    onPressed: () => _deletePersonOwed(p),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPlannedPurchasesList(AppThemeColors? themeColors) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_plannedPurchases.isEmpty) {
      return Card(
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
              'No tienes compras planeadas registradas.\nAgrega aquí las cosas con precio fijo que planeas comprar cuando tengas el dinero.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
        ),
      );
    }

    return Column(
      children: _plannedPurchases.map((item) {
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
                        Icons.shopping_bag_outlined,
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
                            item.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: themeColors?.cardBaseText ?? colorScheme.onSurface,
                            ),
                          ),
                          if (item.note?.isNotEmpty == true)
                            Text(
                              item.note!,
                              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                            ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: colorScheme.onSurfaceVariant),
                      onSelected: (val) {
                        if (val == 'edit') _editPlannedPurchase(item);
                        if (val == 'delete') _deletePlannedPurchase(item);
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('Editar')),
                        PopupMenuItem(value: 'delete', child: Text('Eliminar', style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Precio Estimado', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                        Text(
                          _formatAmount(item.amount, item.currency),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: themeColors?.cardAccentText ?? colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    FilledButton.icon(
                      onPressed: () => _executePurchase(item),
                      icon: const Icon(Icons.shopping_cart_checkout, size: 16),
                      label: const Text('Comprar ahora'),
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        backgroundColor: themeColors?.fabBg ?? colorScheme.primary,
                        foregroundColor: themeColors?.fabText ?? Colors.black,
                      ),
                    ),
                  ],
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
    final themeColors = Theme.of(context).extension<AppThemeColors>();
    final colorScheme = Theme.of(context).colorScheme;

    String fabLabel;
    VoidCallback fabAction;

    if (_selectedSection == 'debts') {
      fabLabel = 'Nueva deuda';
      fabAction = _createDebt;
    } else if (_selectedSection == 'people') {
      fabLabel = 'Nuevo préstamo';
      fabAction = _createPersonOwed;
    } else {
      fabLabel = 'Planeada';
      fabAction = _createPlannedPurchase;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compromisos y por Comprar'),
        actions: [
          if (_selectedSection == 'debts')
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: colorScheme.onSurfaceVariant),
              onSelected: (val) {
                if (val == 'settled') _showSettledDebtsDialog();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'settled',
                  child: ListTile(
                    leading: Icon(Icons.check_circle_outline),
                    title: Text('Ver deudas saldadas'),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSummaryHeader(themeColors),
                  const SizedBox(height: 16),
                  _buildSectionSwitcher(themeColors),
                  const SizedBox(height: 16),
                  if (_selectedSection == 'debts')
                    _buildDebtsList(themeColors)
                  else if (_selectedSection == 'people')
                    _buildPeopleOwedList(themeColors)
                  else
                    _buildPlannedPurchasesList(themeColors),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: fabAction,
        icon: const Icon(Icons.add),
        label: Text(fabLabel),
      ),
    );
  }
}