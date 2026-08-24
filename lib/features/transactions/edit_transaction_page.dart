// ==========================================
// ARCHIVO: lib/features/transactions/edit_transaction_page.dart
// ==========================================

import 'package:flutter/material.dart';

import '../../models/transaction.dart';
import '../../repositories/account_repository.dart';
import '../../repositories/category_repository.dart';
import '../../repositories/payment_method_repository.dart';
import '../../repositories/subcategory_repository.dart';
import '../../repositories/transaction_repository.dart';
import '../../services/transaction_service.dart';

class EditTransactionPage extends StatefulWidget {
  final int transactionId;

  const EditTransactionPage({
    super.key,
    required this.transactionId,
  });

  @override
  State<EditTransactionPage> createState() => _EditTransactionPageState();
}

class _EditTransactionPageState extends State<EditTransactionPage> {
  final _transactionRepository = TransactionRepository();
  final _accountRepository = AccountRepository();
  final _categoryRepository = CategoryRepository();
  final _subcategoryRepository = SubcategoryRepository();
  final _paymentMethodRepository = PaymentMethodRepository();
  final _transactionService = TransactionService();

  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _loadingCategories = false;
  bool _countForFoodControl = false;

  String _type = 'expense';
  DateTime _date = DateTime.now();

  List<Map<String, Object?>> _categories = [];
  List<Map<String, Object?>> _subcategories = [];
  List<Map<String, Object?>> _accounts = [];
  List<Map<String, Object?>> _paymentMethods = [];

  // Para Gasto e Ingreso
  int? _selectedCategoryId;
  int? _selectedSubcategoryId;

  // Para Gasto e Ingreso
  int? _selectedAccountId;
  int? _selectedPaymentMethodId;

  // Para Transferencia
  int? _selectedOriginAccountId;
  int? _selectedDestinationAccountId;

  @override
  void initState() {
    super.initState();
    _loadTransaction();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  bool get _isExpense => _type == 'expense';
  bool get _isIncome => _type == 'income';
  bool get _isTransfer => _type == 'transfer';

  String _formatAmount(int amountInCents, String currency) {
    final amount = amountInCents / 100;
    return currency == 'USD' ? '\$${amount.toStringAsFixed(2)}' : 'S/ ${amount.toStringAsFixed(2)}';
  }

  Future<void> _loadTransaction() async {
    try {
      final transaction = await _transactionRepository.getById(
        widget.transactionId,
      );

      if (transaction == null) {
        _abortWithError('No se encontró la operación.');
        return;
      }

      final items = await _transactionRepository.getItems(widget.transactionId);
      final payments = await _transactionRepository.getPayments(widget.transactionId);

      final type = transaction['type'] as String;
      final dateText = transaction['date'] as String;
      final timeText = transaction['time'] as String;
      final parsedDate = DateTime.tryParse('$dateText $timeText') ?? DateTime.now();

      await _loadAccounts();

      if (!mounted) return;

      int amount = 0;
      int? categoryId;
      int? subcategoryId;
      int? accountId;
      int? paymentMethodId;
      int? originAccountId;
      int? destinationAccountId;
      bool foodControl = false;

      if (type == 'expense') {
        if (items.isEmpty || payments.isEmpty) {
          _abortWithError('Datos incompletos para el gasto.');
          return;
        }

        final item = items.first;
        final payment = payments.first;

        amount = item['amount'] as int;
        categoryId = item['category_id'] as int?;
        subcategoryId = item['subcategory_id'] as int?;
        foodControl = (item['count_for_food_control'] as int? ?? 0) == 1;
        paymentMethodId = payment['payment_method_id'] as int;
        accountId = await _paymentMethodRepository.getAccountId(paymentMethodId);

        if (categoryId != null) {
          await _loadSubcategories(categoryId, keepSelection: true);
        }
      } else if (type == 'income') {
        if (payments.isEmpty) {
          _abortWithError('Datos incompletos para el ingreso.');
          return;
        }

        final payment = payments.first;
        amount = payment['amount'] as int;
        paymentMethodId = payment['payment_method_id'] as int;
        accountId = await _paymentMethodRepository.getAccountId(paymentMethodId);

        if (items.isNotEmpty) {
          categoryId = items.first['category_id'] as int?;
        }
      } else if (type == 'transfer') {
        if (payments.length < 2) {
          _abortWithError('Datos incompletos para la transferencia.');
          return;
        }

        final outPayment = payments.firstWhere(
          (p) => p['direction'] == 'out',
          orElse: () => payments.first,
        );
        final inPayment = payments.firstWhere(
          (p) => p['direction'] == 'in',
          orElse: () => payments.last,
        );

        amount = outPayment['amount'] as int;
        final outMethodId = outPayment['payment_method_id'] as int;
        final inMethodId = inPayment['payment_method_id'] as int;

        originAccountId = await _paymentMethodRepository.getAccountId(outMethodId);
        destinationAccountId = await _paymentMethodRepository.getAccountId(inMethodId);
      }

      if (accountId != null && type == 'expense') {
        await _loadPaymentMethods(accountId, keepSelection: true);
      }

      if (!mounted) return;

      setState(() {
        _type = type;
        _date = parsedDate;
        _descriptionController.text = transaction['description'] as String? ?? '';
        _amountController.text = (amount / 100).toStringAsFixed(2);
        _countForFoodControl = foodControl;

        _selectedCategoryId = categoryId;
        _selectedSubcategoryId = subcategoryId;
        _selectedAccountId = accountId;
        _selectedPaymentMethodId = paymentMethodId;
        _selectedOriginAccountId = originAccountId;
        _selectedDestinationAccountId = destinationAccountId;

        _loading = false;
      });

      if (_isExpense || _isIncome) {
        await _loadCategories();
      }
    } catch (error) {
      _abortWithError('No se pudo cargar la operación: $error');
    }
  }

  void _abortWithError(String message) {
    if (!mounted) return;
    _showMessage(message);
    Navigator.of(context).pop();
  }

  Future<void> _loadAccounts() async {
    final loadedAccounts = await _accountRepository.getActive();
    final accountList = <Map<String, Object?>>[];

    for (final account in loadedAccounts) {
      if (account.id != null) {
        final balanceDetails = await _accountRepository.getBalanceDetails(account.id!);
        accountList.add({
          'id': account.id,
          'name': account.name,
          'currency': account.currency,
          'type': account.type,
          'currentBalance': balanceDetails['current'] ?? 0,
        });
      }
    }

    if (!mounted) return;

    setState(() {
      _accounts = accountList;
    });
  }

  Future<void> _loadCategories() async {
    if (_isTransfer) {
      if (!mounted) return;
      setState(() {
        _categories = [];
        _subcategories = [];
      });
      return;
    }

    setState(() {
      _loadingCategories = true;
    });

    final categories = await _categoryRepository.getByType(_type);
    if (!mounted) return;

    setState(() {
      _categories = categories;
      _loadingCategories = false;
    });
  }

  Future<void> _loadSubcategories(
    int categoryId, {
    bool keepSelection = false,
  }) async {
    final subcategories = await _subcategoryRepository.getByCategory(categoryId);
    if (!mounted) return;

    setState(() {
      _subcategories = subcategories;
      if (!keepSelection) {
        _selectedSubcategoryId = null;
      }
    });
  }

  Future<void> _loadPaymentMethods(
    int accountId, {
    bool keepSelection = false,
  }) async {
    final methods = await _paymentMethodRepository.getByAccount(accountId);
    if (!mounted) return;

    setState(() {
      _paymentMethods = methods;
      if (!keepSelection) {
        _selectedPaymentMethodId = null;
      }
    });
  }

  void _changeType(String type) {
    if (type == _type) return;

    setState(() {
      _type = type;
      _categories = [];
      _subcategories = [];
      _paymentMethods = [];

      _selectedCategoryId = null;
      _selectedSubcategoryId = null;
      _countForFoodControl = false;
      _selectedAccountId = null;
      _selectedPaymentMethodId = null;
      _selectedOriginAccountId = null;
      _selectedDestinationAccountId = null;
    });

    _loadCategories();
  }

  Future<void> _selectDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selectedDate == null || !mounted) return;

    setState(() {
      _date = selectedDate;
    });
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  int? _parseAmount() {
    final text = _amountController.text.trim();
    if (text.isEmpty) return null;

    final normalized = text.replaceAll(',', '.');
    final amount = double.tryParse(normalized);
    if (amount == null || amount <= 0) return null;

    return (amount * 100).round();
  }

  Map<String, Object?>? _findAccount(int? accountId) {
    if (accountId == null) return null;
    for (final account in _accounts) {
      if (account['id'] == accountId) return account;
    }
    return null;
  }

  Future<void> _save() async {
    if (_saving) return;

    final amount = _parseAmount();
    if (amount == null) {
      _showMessage('Ingresa un importe válido.');
      return;
    }

    if (_isExpense) {
      await _saveExpense(amount);
    } else if (_isIncome) {
      await _saveIncome(amount);
    } else if (_isTransfer) {
      await _saveTransfer(amount);
    }
  }

  Future<void> _saveExpense(int amount) async {
    if (_selectedCategoryId == null) {
      _showMessage('Por favor, selecciona una categoría para el gasto.');
      return;
    }

    if (_selectedAccountId == null) {
      _showMessage('Selecciona una cuenta.');
      return;
    }

    if (_selectedPaymentMethodId == null) {
      _showMessage('Selecciona un medio de pago.');
      return;
    }

    final selectedAccount = _findAccount(_selectedAccountId);
    if (selectedAccount == null) {
      _showMessage('No se encontró la cuenta seleccionada.');
      return;
    }

    final currency = selectedAccount['currency'] as String;

    await _executeSave(
      amount: amount,
      currency: currency,
      items: [
        TransactionItemInput(
          categoryId: _selectedCategoryId!,
          subcategoryId: _selectedSubcategoryId,
          amount: amount,
          countForFoodControl: _countForFoodControl,
        ),
      ],
      payments: [
        TransactionPaymentInput(
          paymentMethodId: _selectedPaymentMethodId!,
          amount: amount,
          direction: 'out',
        ),
      ],
      accountId: _selectedAccountId!,
      paymentMethodId: _selectedPaymentMethodId,
    );
  }

  Future<void> _saveIncome(int amount) async {
    if (_selectedCategoryId == null) {
      _showMessage('Por favor, selecciona una categoría para el ingreso.');
      return;
    }

    if (_selectedAccountId == null) {
      _showMessage('Selecciona la cuenta que recibe el dinero.');
      return;
    }

    final selectedAccount = _findAccount(_selectedAccountId);
    if (selectedAccount == null) {
      _showMessage('No se encontró la cuenta seleccionada.');
      return;
    }

    final methods = await _paymentMethodRepository.getByAccount(_selectedAccountId!);
    if (methods.isEmpty) {
      _showMessage('La cuenta seleccionada no tiene medios de pago activos.');
      return;
    }

    final autoPaymentMethodId = methods.first['id'] as int;
    final currency = selectedAccount['currency'] as String;

    await _executeSave(
      amount: amount,
      currency: currency,
      items: [
        TransactionItemInput(
          categoryId: _selectedCategoryId!,
          subcategoryId: null,
          amount: amount,
          countForFoodControl: false,
        ),
      ],
      payments: [
        TransactionPaymentInput(
          paymentMethodId: autoPaymentMethodId,
          amount: amount,
          direction: 'in',
        ),
      ],
      accountId: _selectedAccountId!,
      paymentMethodId: autoPaymentMethodId,
    );
  }

  Future<void> _saveTransfer(int amount) async {
    if (_selectedOriginAccountId == null) {
      _showMessage('Selecciona la cuenta origen.');
      return;
    }

    if (_selectedDestinationAccountId == null) {
      _showMessage('Selecciona la cuenta destino.');
      return;
    }

    if (_selectedOriginAccountId == _selectedDestinationAccountId) {
      _showMessage('La cuenta origen y destino deben ser diferentes.');
      return;
    }

    final originAccount = _findAccount(_selectedOriginAccountId);
    final destinationAccount = _findAccount(_selectedDestinationAccountId);

    if (originAccount == null || destinationAccount == null) {
      _showMessage('No se pudieron determinar las cuentas.');
      return;
    }

    final originCurrency = originAccount['currency'] as String;
    final destinationCurrency = destinationAccount['currency'] as String;

    if (originCurrency != destinationCurrency) {
      _showMessage('La transferencia debe realizarse entre cuentas de la misma moneda.');
      return;
    }

    final originMethods = await _paymentMethodRepository.getByAccount(_selectedOriginAccountId!);
    final destinationMethods = await _paymentMethodRepository.getByAccount(_selectedDestinationAccountId!);

    if (originMethods.isEmpty || destinationMethods.isEmpty) {
      _showMessage('Las cuentas deben tener al menos un medio de pago activo.');
      return;
    }

    final originPaymentMethodId = originMethods.first['id'] as int;
    final destinationPaymentMethodId = destinationMethods.first['id'] as int;

    await _executeSave(
      amount: amount,
      currency: originCurrency,
      items: [],
      payments: [
        TransactionPaymentInput(
          paymentMethodId: originPaymentMethodId,
          amount: amount,
          direction: 'out',
        ),
        TransactionPaymentInput(
          paymentMethodId: destinationPaymentMethodId,
          amount: amount,
          direction: 'in',
        ),
      ],
      accountId: _selectedOriginAccountId!,
      paymentMethodId: null,
    );
  }

  Future<void> _executeSave({
    required int amount,
    required String currency,
    required List<TransactionItemInput> items,
    required List<TransactionPaymentInput> payments,
    required int accountId,
    required int? paymentMethodId,
  }) async {
    setState(() {
      _saving = true;
    });

    try {
      final transaction = Transaction(
        id: widget.transactionId,
        type: TransactionType.values.firstWhere((v) => v.name == _type),
        amount: amount,
        currency: currency,
        accountId: accountId,
        paymentMethodId: paymentMethodId,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        date: _date,
      );

      await _transactionService.updateTransaction(
        id: widget.transactionId,
        transaction: transaction,
        items: items,
        payments: payments,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
      });
      _showMessage('$error');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildTypeSelector() {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(
          value: 'expense',
          label: Text('Gasto'),
          icon: Icon(Icons.arrow_upward),
        ),
        ButtonSegment(
          value: 'income',
          label: Text('Ingreso'),
          icon: Icon(Icons.arrow_downward),
        ),
        ButtonSegment(
          value: 'transfer',
          label: Text('Transferencia'),
          icon: Icon(Icons.swap_horiz),
        ),
      ],
      selected: {_type},
      onSelectionChanged: _saving
          ? null
          : (selection) {
              if (selection.isEmpty) return;
              _changeType(selection.first);
            },
    );
  }

  Widget _buildCategorySection(bool isDark) {
    if (_isTransfer) return const SizedBox.shrink();

    if (_loadingCategories) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_categories.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber.shade400),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _isIncome
                    ? 'No tienes categorías de ingreso activas. Ve a la pestaña Categorías para crear una.'
                    : 'No tienes categorías de gasto activas.',
                style: TextStyle(color: Colors.amber.shade900, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<int>(
          key: ValueKey('edit_category_dropdown_$_type'),
          isExpanded: true,
          initialValue: _selectedCategoryId,
          decoration: InputDecoration(
            labelText: _isIncome ? 'Categoría de ingreso *' : 'Categoría *',
            border: const OutlineInputBorder(),
          ),
          items: _categories.map((category) {
            return DropdownMenuItem<int>(
              value: category['id'] as int,
              child: Text(
                category['name'] as String,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            );
          }).toList(),
          onChanged: _saving
              ? null
              : (value) {
                  setState(() {
                    _selectedCategoryId = value;
                    _subcategories = [];
                    _selectedSubcategoryId = null;
                  });

                  if (_isExpense && value != null) {
                    _loadSubcategories(value);
                  }
                },
        ),
        if (_isExpense && _selectedCategoryId != null) ...[
          const SizedBox(height: 16),
          if (_subcategories.isEmpty)
            Text(
              'Esta categoría no tiene subcategorías activas.',
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
            )
          else
            DropdownButtonFormField<int>(
              key: ValueKey('edit_subcategory_dropdown_$_selectedCategoryId'),
              isExpanded: true,
              initialValue: _selectedSubcategoryId,
              decoration: const InputDecoration(
                labelText: 'Subcategoría',
                border: OutlineInputBorder(),
              ),
              items: _subcategories.map((subcategory) {
                return DropdownMenuItem<int>(
                  value: subcategory['id'] as int,
                  child: Text(
                    subcategory['name'] as String,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                );
              }).toList(),
              onChanged: _saving
                  ? null
                  : (value) {
                      setState(() {
                        _selectedSubcategoryId = value;
                      });
                    },
            ),
        ],

        if (_isExpense) ...[
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _countForFoodControl,
            activeThumbColor: Colors.orange.shade800,
            title: Text(
              'Incluir en control diario de alimentación',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            subtitle: Text(
              'Se descontará del presupuesto diario de comida de este día',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            onChanged: _saving
                ? null
                : (val) {
                    setState(() {
                      _countForFoodControl = val;
                    });
                  },
          ),
        ],
      ],
    );
  }

  Widget _buildStandardAccountSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<int>(
          key: ValueKey('edit_account_dropdown_$_type'),
          isExpanded: true,
          initialValue: _selectedAccountId,
          decoration: InputDecoration(
            labelText: _isIncome ? 'Cuenta de destino *' : 'Cuenta de origen *',
            border: const OutlineInputBorder(),
          ),
          items: _accounts.map((account) {
            final name = account['name'] as String;
            final currency = account['currency'] as String;
            final balance = account['currentBalance'] as int? ?? 0;

            return DropdownMenuItem<int>(
              value: account['id'] as int,
              child: Text(
                '$name ($currency) · Disp: ${_formatAmount(balance, currency)}',
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
                    _paymentMethods = [];
                    _selectedPaymentMethodId = null;
                  });

                  if (value != null && _isExpense) {
                    _loadPaymentMethods(value);
                  }
                },
        ),
        if (_isExpense && _selectedAccountId != null) ...[
          const SizedBox(height: 16),
          if (_paymentMethods.isEmpty)
            Text(
              'Esta cuenta no tiene medios de pago activos.',
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
            )
          else
            DropdownButtonFormField<int>(
              key: ValueKey('edit_payment_method_dropdown_$_selectedAccountId'),
              isExpanded: true,
              initialValue: _selectedPaymentMethodId,
              decoration: const InputDecoration(
                labelText: 'Medio de pago *',
                border: OutlineInputBorder(),
              ),
              items: _paymentMethods.map((method) {
                return DropdownMenuItem<int>(
                  value: method['id'] as int,
                  child: Text(
                    method['name'] as String,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                );
              }).toList(),
              onChanged: _saving
                  ? null
                  : (value) {
                      setState(() {
                        _selectedPaymentMethodId = value;
                      });
                    },
            ),
        ],
      ],
    );
  }

  Widget _buildTransferAccountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<int>(
          key: const ValueKey('edit_origin_account_dropdown'),
          isExpanded: true,
          initialValue: _selectedOriginAccountId,
          decoration: const InputDecoration(
            labelText: 'Cuenta origen *',
            border: OutlineInputBorder(),
          ),
          items: _accounts.map((account) {
            final name = account['name'] as String;
            final currency = account['currency'] as String;
            final balance = account['currentBalance'] as int? ?? 0;

            return DropdownMenuItem<int>(
              value: account['id'] as int,
              child: Text(
                '$name ($currency) · Disp: ${_formatAmount(balance, currency)}',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            );
          }).toList(),
          onChanged: _saving
              ? null
              : (value) {
                  setState(() {
                    _selectedOriginAccountId = value;
                  });
                },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<int>(
          key: const ValueKey('edit_destination_account_dropdown'),
          isExpanded: true,
          initialValue: _selectedDestinationAccountId,
          decoration: const InputDecoration(
            labelText: 'Cuenta destino *',
            border: OutlineInputBorder(),
          ),
          items: _accounts.map((account) {
            final name = account['name'] as String;
            final currency = account['currency'] as String;
            final balance = account['currentBalance'] as int? ?? 0;

            return DropdownMenuItem<int>(
              value: account['id'] as int,
              child: Text(
                '$name ($currency) · Disp: ${_formatAmount(balance, currency)}',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            );
          }).toList(),
          onChanged: _saving
              ? null
              : (value) {
                  setState(() {
                    _selectedDestinationAccountId = value;
                  });
                },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final showStandardAccountSection = _isExpense || _isIncome;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Editar operación'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar operación'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tipo de operación',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            _buildTypeSelector(),
            const SizedBox(height: 24),
            Text(
              'Fecha',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text(_formatDate(_date), style: TextStyle(color: colorScheme.onSurface)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _saving ? null : _selectDate,
            ),
            Divider(color: colorScheme.outlineVariant),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              enabled: !_saving,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            if (_isExpense || _isIncome) ...[
              Text(
                _isIncome ? 'Categoría de ingreso' : 'Concepto y Categoría',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              _buildCategorySection(isDark),
              const SizedBox(height: 16),
            ],
            if (_isTransfer) ...[
              Text(
                'Transferencia',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              _buildTransferAccountSection(),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _amountController,
              enabled: !_saving,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Importe *',
                hintText: '0.00',
                border: OutlineInputBorder(),
              ),
            ),
            if (showStandardAccountSection) ...[
              const SizedBox(height: 32),
              Text(
                _isIncome ? 'Cuenta de destino' : 'Cuenta y medio de pago',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              _buildStandardAccountSection(isDark),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Guardar cambios'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}