// ==========================================
// ARCHIVO: lib/features/transactions/transactions_page.dart
// ==========================================

import 'package:flutter/material.dart';

import '../../core/app_themes.dart';
import 'create_transaction_page.dart';
import 'edit_transaction_page.dart';
import '../../repositories/transaction_repository.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  final _repository = TransactionRepository();

  bool _loading = true;
  List<Map<String, Object?>> _transactions = [];

  String _filterType = 'all';

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final transactions = await _repository.getAllWithDetails(
      typeFilter: _filterType == 'all' ? null : _filterType,
    );

    if (!mounted) return;

    setState(() {
      _transactions = transactions;
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

  Future<void> _editTransaction(int transactionId) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditTransactionPage(transactionId: transactionId),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      await _loadTransactions();
    }
  }

  Future<void> _deleteTransaction(int transactionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar operación'),
          content: const Text(
            '¿Estás seguro de que deseas eliminar esta operación?\n\n'
            'Se borrará de forma permanente y se recalculará tu saldo.',
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

    if (confirmed != true || !mounted) return;

    try {
      await _repository.delete(transactionId);

      if (!mounted) return;
      await _loadTransactions();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Operación eliminada definitivamente.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar la operación: $error')),
      );
    }
  }

  Future<void> _showTransactionActions(int transactionId) async {
    final themeColors = Theme.of(context).extension<AppThemeColors>();

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: themeColors?.cardBaseBg ?? Theme.of(context).colorScheme.surface,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.edit, color: themeColors?.cardAccentText),
                title: Text(
                  'Editar operación',
                  style: TextStyle(color: themeColors?.cardBaseText),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _editTransaction(transactionId);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                title: const Text('Eliminar operación', style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _deleteTransaction(transactionId);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterPill(String type, String label, AppThemeColors? themeColors) {
    final isSelected = _filterType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _filterType = type;
          _loading = true;
        });
        _loadTransactions();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (themeColors?.cardAccentText ?? Colors.amber)
              : (themeColors?.cardBaseBg ?? Colors.white12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (themeColors?.cardBaseBorder ?? Colors.white24),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isSelected
                ? (themeColors?.navBg ?? Colors.black)
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterRow(AppThemeColors? themeColors) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterPill('all', 'Todas', themeColors),
          const SizedBox(width: 8),
          _buildFilterPill('expense', 'Gastos', themeColors),
          const SizedBox(width: 8),
          _buildFilterPill('income', 'Ingresos', themeColors),
          const SizedBox(width: 8),
          _buildFilterPill('transfer', 'Transferencias', themeColors),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = Theme.of(context).extension<AppThemeColors>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Operaciones'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTransactions,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildFilterRow(themeColors),
                  const SizedBox(height: 14),

                  if (_transactions.isEmpty)
                    Card(
                      elevation: 0,
                      color: themeColors?.cardBaseBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(color: themeColors?.cardBaseBorder ?? Colors.white12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Center(
                          child: Text(
                            'No hay operaciones registradas.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                          ),
                        ),
                      ),
                    )
                  else
                    ..._transactions.map((t) {
                      final id = t['id'] as int;
                      final type = t['type'] as String;
                      final date = t['date'] as String;
                      final description = t['description'] as String?;
                      final amount = t['amount'] as int? ?? 0;
                      final currency = t['currency'] as String? ?? 'PEN';
                      final categoryName = t['category_name'] as String?;
                      final subcategoryName = t['subcategory_name'] as String?;
                      final accountName = t['account_name'] as String?;

                      IconData iconData;
                      String prefix;
                      String titleText;

                      if (type == 'expense') {
                        iconData = Icons.trending_down; // 👈 Gráfica de gasto decreciente
                        prefix = '-';
                        titleText = description?.isNotEmpty == true
                            ? description!
                            : (categoryName ?? 'Gasto');
                      } else if (type == 'income') {
                        iconData = Icons.trending_up; // 👈 Gráfica de ganancia creciente
                        prefix = '+';
                        titleText = description?.isNotEmpty == true
                            ? description!
                            : (categoryName ?? 'Ingreso');
                      } else if (type == 'transfer') {
                        iconData = Icons.swap_horiz;
                        prefix = '';
                        titleText = description?.isNotEmpty == true
                            ? description!
                            : 'Transferencia';
                      } else {
                        iconData = Icons.handshake_outlined;
                        prefix = '-';
                        titleText = 'Pago de deuda';
                      }

                      String subText = date;
                      if (categoryName != null && description?.isNotEmpty == true) {
                        subText += ' · $categoryName';
                        if (subcategoryName != null && subcategoryName.isNotEmpty) {
                          subText += ' ($subcategoryName)';
                        }
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        color: themeColors?.cardBaseBg,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(color: themeColors?.cardBaseBorder ?? Colors.white12),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => _editTransaction(id),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: themeColors?.pillBg,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    iconData,
                                    color: themeColors?.cardAccentText ?? colorScheme.primary,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        titleText,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: themeColors?.cardBaseText ?? colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        subText,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      if (accountName != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          'Cuenta: $accountName',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: colorScheme.onSurfaceVariant.withAlpha(160),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '$prefix${_formatAmount(amount, currency)}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: themeColors?.cardAccentText ?? colorScheme.primary,
                                      ),
                                    ),
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: Icon(
                                        Icons.more_vert,
                                        size: 18,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      onPressed: () => _showTransactionActions(id),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreateTransactionPage()),
          );

          if (!mounted) return;
          if (result == true) {
            await _loadTransactions();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}