// ==========================================
// ARCHIVO: lib/features/food_budget/food_budget_page.dart
// ==========================================

import 'package:flutter/material.dart';

import '../../models/food_budget_day.dart';
import '../../repositories/food_budget_repository.dart';
import '../transactions/create_transaction_page.dart';
import '../transactions/edit_transaction_page.dart';

class FoodBudgetPage extends StatefulWidget {
  const FoodBudgetPage({super.key});

  @override
  State<FoodBudgetPage> createState() => _FoodBudgetPageState();
}

class _FoodBudgetPageState extends State<FoodBudgetPage> {
  final _repository = FoodBudgetRepository();

  bool _loading = true;
  late DateTime _selectedDate;

  late FoodBudgetDay _currentBudgetDay;
  int _spentToday = 0;
  List<Map<String, Object?>> _foodTransactions = [];

  List<_DaySummary> _recentDays = [];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadData();
  }

  String _formatDateToIso(DateTime d) {
    final year = d.year.toString();
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Future<void> _loadData() async {
    final dateIso = _formatDateToIso(_selectedDate);

    final budgetDay = await _repository.getDay(dateIso);
    final spent = await _repository.getFoodSpendingByDate(dateIso);
    final transactions = await _repository.getFoodTransactionsByDate(dateIso);

    final recent = <_DaySummary>[];
    for (int i = 0; i < 7; i++) {
      final d = _selectedDate.subtract(Duration(days: i));
      final dIso = _formatDateToIso(d);
      final b = await _repository.getDay(dIso);
      final s = await _repository.getFoodSpendingByDate(dIso);
      recent.add(_DaySummary(
        date: d,
        limit: b.dailyLimit + b.adjustment,
        spent: s,
      ));
    }

    if (!mounted) return;

    setState(() {
      _currentBudgetDay = budgetDay;
      _spentToday = spent;
      _foodTransactions = transactions;
      _recentDays = recent;
      _loading = false;
    });
  }

  void _previousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
      _loading = true;
    });
    _loadData();
  }

  void _nextDay() {
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
      _loading = true;
    });
    _loadData();
  }

  String _formatAmount(int amountInCents) {
    final amount = amountInCents / 100;
    return 'S/ ${amount.toStringAsFixed(2)}';
  }

  String _formatHeaderDate(DateTime d) {
    final now = DateTime.now();
    final isToday = d.year == now.year && d.month == now.month && d.day == now.day;
    const months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Set', 'Oct', 'Nov', 'Dic'
    ];
    final dateStr = '${d.day} ${months[d.month - 1]} ${d.year}';
    return isToday ? 'Hoy ($dateStr)' : dateStr;
  }

  Future<void> _editDayBudget() async {
    final limitController = TextEditingController(
      text: (_currentBudgetDay.dailyLimit / 100).toStringAsFixed(2),
    );
    final adjustmentController = TextEditingController(
      text: (_currentBudgetDay.adjustment / 100).toStringAsFixed(2),
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Presupuesto de Alimentación'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: limitController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Límite para este día (S/)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: adjustmentController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                decoration: const InputDecoration(
                  labelText: 'Ajuste / Extra (S/)',
                  hintText: 'Ej. 5.00 o -10.00',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
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

    if (saved == true && mounted) {
      final lim = (double.tryParse(limitController.text.replaceAll(',', '.')) ?? 0) * 100;
      final adj = (double.tryParse(adjustmentController.text.replaceAll(',', '.')) ?? 0) * 100;

      await _repository.saveDay(
        date: _formatDateToIso(_selectedDate),
        dailyLimit: lim.round(),
        adjustment: adj.round(),
      );

      await _loadData();
    }
  }

  Future<void> _configureDefaultLimit() async {
    final currentDefault = await _repository.getDefaultDailyLimit();

    if (!mounted) return;

    final controller = TextEditingController(
      text: (currentDefault / 100).toStringAsFixed(2),
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Límite Diario Estándar'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Este monto se usará por defecto para todos los días que no configures individualmente.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Límite diario por defecto (S/)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
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

    if (saved == true && mounted) {
      final lim = (double.tryParse(controller.text.replaceAll(',', '.')) ?? 0) * 100;
      await _repository.setDefaultDailyLimit(lim.round());
      await _loadData();
    }
  }

  Widget _buildDailyStatusCard(bool isDark) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveLimit = _currentBudgetDay.dailyLimit + _currentBudgetDay.adjustment;
    final remaining = effectiveLimit - _spentToday;
    final progress = effectiveLimit > 0 ? (_spentToday / effectiveLimit).clamp(0.0, 1.0) : 0.0;
    final isExceeded = remaining < 0;
    final subtextColor = isDark ? Colors.white70 : Colors.black54;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _previousDay,
                  icon: Icon(Icons.chevron_left, color: colorScheme.onSurface),
                  tooltip: 'Día anterior',
                ),
                Text(
                  _formatHeaderDate(_selectedDate),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                IconButton(
                  onPressed: _nextDay,
                  icon: Icon(Icons.chevron_right, color: colorScheme.onSurface),
                  tooltip: 'Día siguiente',
                ),
              ],
            ),
            Divider(color: colorScheme.outlineVariant),
            const SizedBox(height: 12),
            Text(
              isExceeded ? 'Excedido por' : 'Disponible para hoy',
              style: TextStyle(
                fontSize: 13,
                color: isExceeded ? (isDark ? Colors.redAccent.shade100 : Colors.red.shade700) : subtextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatAmount(remaining.abs()),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: isExceeded
                    ? (isDark ? Colors.redAccent.shade100 : Colors.red.shade700)
                    : (isDark ? Colors.greenAccent : Colors.green.shade800),
              ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isExceeded ? Colors.redAccent : (progress > 0.8 ? Colors.amber : Colors.green),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Límite + Ajuste', style: TextStyle(fontSize: 11, color: subtextColor)),
                    Text(
                      _formatAmount(effectiveLimit),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: _editDayBudget,
                  icon: const Icon(Icons.tune, size: 16),
                  label: const Text('Ajustar'),
                  style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Gastado en Comida', style: TextStyle(fontSize: 11, color: subtextColor)),
                    Text(
                      _formatAmount(_spentToday),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.redAccent.shade100 : Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentHistory(bool isDark) {
    final colorScheme = Theme.of(context).colorScheme;
    final subtextColor = isDark ? Colors.white70 : Colors.black54;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Últimos 7 días',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
            ),
            const SizedBox(height: 12),
            ..._recentDays.map((d) {
              const days = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
              final dayName = days[d.date.weekday % 7];
              final dateStr = '$dayName ${d.date.day}';
              final rem = d.limit - d.spent;
              final isOk = rem >= 0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 70,
                      child: Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Gastó ${_formatAmount(d.spent)} de ${_formatAmount(d.limit)}',
                        style: TextStyle(fontSize: 12, color: subtextColor),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isOk
                            ? (isDark ? Colors.green.shade900.withAlpha(80) : Colors.green.shade50)
                            : (isDark ? Colors.red.shade900.withAlpha(80) : Colors.red.shade50),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isOk ? '+${_formatAmount(rem)}' : '-${_formatAmount(rem.abs())}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isOk
                              ? (isDark ? Colors.greenAccent : Colors.green.shade800)
                              : (isDark ? Colors.redAccent.shade100 : Colors.red.shade800),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList(bool isDark) {
    final colorScheme = Theme.of(context).colorScheme;
    final subtextColor = isDark ? Colors.white70 : Colors.black54;

    if (_foodTransactions.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'No hay gastos de comida registrados en este día.',
              style: TextStyle(color: subtextColor),
            ),
          ),
        ),
      );
    }

    return Column(
      children: _foodTransactions.map((t) {
        final id = t['id'] as int;
        final desc = t['description'] as String?;
        final time = t['time'] as String;
        final amount = t['amount'] as int;
        final cat = t['category_name'] as String? ?? 'Alimentación';
        final subcat = t['subcategory_name'] as String?;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isDark ? Colors.orange.shade900.withAlpha(100) : Colors.orange.shade100,
              child: Icon(Icons.restaurant, color: isDark ? Colors.orangeAccent : Colors.orange.shade900, size: 20),
            ),
            title: Text(
              desc?.isNotEmpty == true ? desc! : cat,
              style: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onSurface),
            ),
            subtitle: Text(
              subcat != null ? '$time · $cat ($subcat)' : '$time · $cat',
              style: TextStyle(fontSize: 12, color: subtextColor),
            ),
            trailing: Text(
              _formatAmount(amount),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.redAccent.shade100 : Colors.red.shade700,
              ),
            ),
            onTap: () async {
              final res = await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => EditTransactionPage(transactionId: id)),
              );
              if (res == true && mounted) {
                await _loadData();
              }
            },
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Control de Alimentación'),
        actions: [
          IconButton(
            onPressed: _configureDefaultLimit,
            icon: Icon(Icons.settings_outlined, color: colorScheme.onSurface),
            tooltip: 'Configurar límite diario estándar',
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
                  _buildDailyStatusCard(isDark),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Gastos de Comida de este Día',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          final res = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const CreateTransactionPage(initialType: 'expense'),
                            ),
                          );
                          if (res == true && mounted) {
                            await _loadData();
                          }
                        },
                        icon: const Icon(Icons.add_circle, color: Colors.orange),
                        tooltip: 'Agregar gasto de comida',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildTransactionsList(isDark),
                  const SizedBox(height: 20),

                  _buildRecentHistory(isDark),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
}

class _DaySummary {
  final DateTime date;
  final int limit;
  final int spent;

  const _DaySummary({
    required this.date,
    required this.limit,
    required this.spent,
  });
}