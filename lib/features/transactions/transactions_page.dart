// ==========================================
// ARCHIVO: lib/features/transactions/transactions_page.dart
// ==========================================

import 'package:flutter/material.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.edit, color: isDark ? Colors.white70 : Colors.black87),
                title: Text(
                  'Editar operación',
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
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

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('all', 'Todas'),
          const SizedBox(width: 8),
          _buildFilterChip('expense', 'Gastos', icon: Icons.arrow_upward, color: Colors.redAccent),
          const SizedBox(width: 8),
          _buildFilterChip('income', 'Ingresos', icon: Icons.arrow_downward, color: Colors.green),
          const SizedBox(width: 8),
          _buildFilterChip('transfer', 'Transferencias', icon: Icons.swap_horiz, color: Colors.blueAccent),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String type, String label, {IconData? icon, Color? color}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isSelected = _filterType == type;

    return FilterChip(
      selected: isSelected,
      showCheckmark: false,
      avatar: icon != null
          ? Icon(
              icon,
              size: 16,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white70 : (color ?? colorScheme.primary)),
            )
          : null,
      label: Text(label),
      backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
      selectedColor: color ?? colorScheme.primary,
      side: BorderSide(
        color: isSelected
            ? Colors.transparent
            : (isDark ? Colors.white24 : Colors.grey.shade300),
      ),
      labelStyle: TextStyle(
        color: isSelected
            ? Colors.white
            : (isDark ? Colors.white : Colors.black87),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
        fontSize: 13,
      ),
      onSelected: (selected) {
        setState(() {
          _filterType = type;
          _loading = true;
        });
        _loadTransactions();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

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
                  _buildFilterChips(),
                  const SizedBox(height: 12),

                  if (_transactions.isEmpty)
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: colorScheme.outlineVariant),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Center(
                          child: Text(
                            'No hay operaciones que coincidan con este filtro.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
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
                      Color itemColor;
                      String prefix;
                      String titleText;

                      if (type == 'expense') {
                        iconData = Icons.arrow_upward;
                        itemColor = isDark ? const Color(0xFFFF6B6B) : Colors.redAccent.shade700;
                        prefix = '-';
                        titleText = description?.isNotEmpty == true
                            ? description!
                            : (categoryName ?? 'Gasto');
                      } else if (type == 'income') {
                        iconData = Icons.arrow_downward;
                        itemColor = isDark ? const Color(0xFF51CF66) : Colors.green.shade800;
                        prefix = '+';
                        titleText = description?.isNotEmpty == true
                            ? description!
                            : (categoryName ?? 'Ingreso');
                      } else if (type == 'transfer') {
                        iconData = Icons.swap_horiz;
                        itemColor = isDark ? const Color(0xFF4DABF7) : Colors.blue.shade800;
                        prefix = '';
                        titleText = description?.isNotEmpty == true
                            ? description!
                            : 'Transferencia';
                      } else {
                        iconData = Icons.handshake_outlined;
                        itemColor = isDark ? const Color(0xFFCC5DE8) : Colors.purple.shade800;
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => _editTransaction(id),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: itemColor.withAlpha(isDark ? 45 : 25),
                                  child: Icon(iconData, color: itemColor, size: 20),
                                ),
                                const SizedBox(width: 12),
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
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        subText,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? Colors.white70 : Colors.black54,
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
                                            color: isDark ? Colors.white60 : Colors.black45,
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
                                        fontWeight: FontWeight.bold,
                                        color: itemColor,
                                      ),
                                    ),
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: Icon(
                                        Icons.more_vert,
                                        size: 18,
                                        color: isDark ? Colors.white60 : Colors.black38,
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