// ==========================================
// ARCHIVO: lib/features/food_budget/food_budget_page.dart
// ==========================================

import 'package:flutter/material.dart';

import '../../core/app_themes.dart';
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

  int _baseLimit = 0;
  int _autoAdjustment = 0;
  int _effectiveLimit = 0;
  int _spentToday = 0;
  int _remainingToday = 0;

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
    final calculation = await _repository.getDayCalculation(_selectedDate);
    final dateIso = _formatDateToIso(_selectedDate);
    final transactions = await _repository.getFoodTransactionsByDate(dateIso);

    final recent = <_DaySummary>[];
    for (int i = 0; i < 7; i++) {
      final d = _selectedDate.subtract(Duration(days: i));
      final calc = await _repository.getDayCalculation(d);
      recent.add(_DaySummary(
        date: d,
        effectiveLimit: calc['effectiveLimit'] ?? 0,
        spent: calc['spent'] ?? 0,
        remaining: calc['remaining'] ?? 0,
      ));
    }

    if (!mounted) return;

    setState(() {
      _baseLimit = calculation['baseLimit'] ?? 0;
      _autoAdjustment = calculation['autoAdjustment'] ?? 0;
      _effectiveLimit = calculation['effectiveLimit'] ?? 0;
      _spentToday = calculation['spent'] ?? 0;
      _remainingToday = calculation['remaining'] ?? 0;

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

  Future<void> _editDayBaseLimit() async {
    final limitController = TextEditingController(
      text: _baseLimit > 0 ? (_baseLimit / 100).toStringAsFixed(2) : '',
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final themeColors = Theme.of(context).extension<AppThemeColors>();

        return AlertDialog(
          title: const Text('Presupuesto del Día'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: limitController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Límite Base para este día (S/)',
                  hintText: '0.00',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: themeColors?.pillBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _autoAdjustment >= 0 ? Icons.trending_up : Icons.trending_down,
                      size: 16,
                      color: _autoAdjustment >= 0 ? Colors.green : Colors.redAccent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _autoAdjustment >= 0
                            ? 'Ajuste automático de ayer: +${_formatAmount(_autoAdjustment)}'
                            : 'Ajuste automático de ayer: -${_formatAmount(_autoAdjustment.abs())}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _autoAdjustment >= 0 ? Colors.green : Colors.redAccent,
                        ),
                      ),
                    ),
                  ],
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
      final text = limitController.text.trim();
      final lim = text.isEmpty
          ? 0.0
          : ((double.tryParse(text.replaceAll(',', '.')) ?? 0) * 100);

      await _repository.saveDayBaseLimit(
        date: _formatDateToIso(_selectedDate),
        dailyLimit: lim.round(),
      );

      await _loadData();
    }
  }

  Future<void> _configureDefaultLimit() async {
    final currentDefault = await _repository.getDefaultDailyLimit();

    if (!mounted) return;

    final controller = TextEditingController(
      text: currentDefault > 0 ? (currentDefault / 100).toStringAsFixed(2) : '',
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
                'Si lo dejas en 0.00, los días que no uses la app no acumularán ajustes automáticos.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Límite base estándar (S/)',
                  hintText: '0.00',
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
      final text = controller.text.trim();
      final lim = text.isEmpty
          ? 0.0
          : ((double.tryParse(text.replaceAll(',', '.')) ?? 0) * 100);

      await _repository.setDefaultDailyLimit(lim.round());
      await _loadData();
    }
  }

  Widget _buildDailyStatusCard(AppThemeColors? themeColors) {
    final colorScheme = Theme.of(context).colorScheme;
    final isExceeded = _remainingToday < 0 || (_effectiveLimit == 0 && _spentToday > 0);
    final progress = _effectiveLimit > 0
        ? (_spentToday / _effectiveLimit).clamp(0.0, 1.0)
        : (_spentToday > 0 ? 1.0 : 0.0);

    return Card(
      elevation: 2,
      color: themeColors?.cardBaseBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: themeColors?.cardBaseBorder ?? Colors.white12),
      ),
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
            Divider(color: themeColors?.cardBaseBorder ?? Colors.white12),
            const SizedBox(height: 12),
            Text(
              isExceeded ? 'Excedido por' : 'Disponible para hoy',
              style: TextStyle(
                fontSize: 13,
                color: isExceeded ? colorScheme.error : colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatAmount(_remainingToday.abs()),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: isExceeded ? colorScheme.error : (themeColors?.cardAccentText ?? Colors.green),
              ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isExceeded ? colorScheme.error : (themeColors?.cardAccentText ?? Colors.green),
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
                    Text('Límite Base', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                    Text(
                      _formatAmount(_baseLimit),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: themeColors?.cardBaseText ?? colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('Ajuste de Ayer', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                    Text(
                      _autoAdjustment >= 0 ? '+${_formatAmount(_autoAdjustment)}' : '-${_formatAmount(_autoAdjustment.abs())}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _autoAdjustment >= 0 ? (themeColors?.cardAccentText ?? Colors.green) : colorScheme.error,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Gastado Hoy', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                    Text(
                      _formatAmount(_spentToday),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.center,
              child: OutlinedButton.icon(
                onPressed: _editDayBaseLimit,
                icon: Icon(Icons.tune, size: 16, color: themeColors?.btnColor),
                label: Text('Asignar / Modificar Límite', style: TextStyle(color: themeColors?.btnColor, fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  side: BorderSide(color: themeColors?.btnBorder ?? Colors.white24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentHistory(AppThemeColors? themeColors) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
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
            Text(
              'Últimos 7 días',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: themeColors?.cardBaseText ?? colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            ..._recentDays.map((d) {
              const days = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
              final dayName = days[d.date.weekday % 7];
              final dateStr = '$dayName ${d.date.day}';
              final isOk = d.remaining >= 0;

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
                          color: themeColors?.cardBaseText,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Gastó ${_formatAmount(d.spent)} de ${_formatAmount(d.effectiveLimit)}',
                        style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: themeColors?.pillBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: themeColors?.pillBorder ?? Colors.transparent),
                      ),
                      child: Text(
                        isOk ? '+${_formatAmount(d.remaining)}' : '-${_formatAmount(d.remaining.abs())}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isOk ? (themeColors?.cardAccentText ?? Colors.green) : colorScheme.error,
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

  Widget _buildTransactionsList(AppThemeColors? themeColors) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_foodTransactions.isEmpty) {
      return Card(
        elevation: 0,
        color: themeColors?.cardBaseBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: themeColors?.cardBaseBorder ?? Colors.white12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'No hay gastos de comida registrados en este día.',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
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
          color: themeColors?.cardBaseBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: themeColors?.cardBaseBorder ?? Colors.white12),
          ),
          child: ListTile(
            leading: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: themeColors?.pillBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.restaurant,
                color: themeColors?.cardAccentText ?? colorScheme.primary,
                size: 20,
              ),
            ),
            title: Text(
              desc?.isNotEmpty == true ? desc! : cat,
              style: TextStyle(fontWeight: FontWeight.w600, color: themeColors?.cardBaseText),
            ),
            subtitle: Text(
              subcat != null ? '$time · $cat ($subcat)' : '$time · $cat',
              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
            ),
            trailing: Text(
              _formatAmount(amount),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.error,
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
    final themeColors = Theme.of(context).extension<AppThemeColors>();
    final colorScheme = Theme.of(context).colorScheme;

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
                  _buildDailyStatusCard(themeColors),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Gastos de Comida de este Día',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: themeColors?.cardBaseText ?? colorScheme.onSurface,
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
                        icon: Icon(Icons.add_circle, color: themeColors?.cardAccentText ?? Colors.orange),
                        tooltip: 'Agregar gasto de comida',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildTransactionsList(themeColors),
                  const SizedBox(height: 20),

                  _buildRecentHistory(themeColors),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
}

class _DaySummary {
  final DateTime date;
  final int effectiveLimit;
  final int spent;
  final int remaining;

  const _DaySummary({
    required this.date,
    required this.effectiveLimit,
    required this.spent,
    required this.remaining,
  });
}