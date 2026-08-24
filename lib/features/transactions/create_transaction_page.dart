// ==========================================
// ARCHIVO: lib/features/transactions/create_transaction_page.dart
// ==========================================

import 'package:flutter/material.dart';

import '../../models/transaction.dart';
import '../../repositories/account_repository.dart';
import '../../repositories/category_repository.dart';
import '../../repositories/payment_method_repository.dart';
import '../../repositories/subcategory_repository.dart';
import '../../services/transaction_service.dart';

class CreateTransactionPage extends StatefulWidget {
  final String initialType;

  const CreateTransactionPage({
    super.key,
    this.initialType = 'expense',
  });

  @override
  State<CreateTransactionPage> createState() => _CreateTransactionPageState();
}

class _CreateTransactionPageState extends State<CreateTransactionPage> {
  final _accountRepository = AccountRepository();
  final _categoryRepository = CategoryRepository();
  final _subcategoryRepository = SubcategoryRepository();
  final _paymentMethodRepository = PaymentMethodRepository();
  final _transactionService = TransactionService();

  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  bool _loadingCategories = false;
  bool _loadingAccounts = true;
  bool _saving = false;
  bool _countForFoodControl = false;

  late String _type;
  DateTime _date = DateTime.now();

  List<Map<String, Object?>> _categories = [];
  List<Map<String, Object?>> _subcategories = [];
  List<Map<String, Object?>> _accounts = [];
  List<Map<String, Object?>> _paymentMethods = [];

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
    _type = widget.initialType;
    _loadAccounts();
    _loadCategories();
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

  Future<void> _loadCategories() async {
    if (_isTransfer) {
      if (!mounted) return;
      setState(() {
        _categories = [];
        _subcategories = [];
        _selectedCategoryId = null;
        _selectedSubcategoryId = null;
        _loadingCategories = false;
      });
      return;
    }

    if (mounted) {
      setState(() {
        _loadingCategories = true;
      });
    }

    final categories = await _categoryRepository.getByType(_type);

    if (!mounted) return;

    setState(() {
      _categories = categories;
      _subcategories = [];
      _selectedCategoryId = null;
      _selectedSubcategoryId = null;
      _loadingCategories = false;
    });
  }

  Future<void> _loadAccounts() async {
    final accounts = await _accountRepository.getActive();
    final accountList = <Map<String, Object?>>[];

    for (final account in accounts) {
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
      _loadingAccounts = false;
    });
  }

  Future<void> _loadSubcategories(int categoryId) async {
    final subcategories = await _subcategoryRepository.getByCategory(categoryId);

    if (!mounted) return;

    setState(() {
      _subcategories = subcategories;
      _selectedSubcategoryId = null;
    });
  }

  Future<void> _loadPaymentMethods(int accountId) async {
    final methods = await _paymentMethodRepository.getByAccount(accountId);

    if (!mounted) return;

    setState(() {
      _paymentMethods = methods;
      _selectedPaymentMethodId = null;
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
      if (account['id'] == accountId) {
        return account;
      }
    }
    return null;
  }

  Future<void> _saveTransaction() async {
    if (_saving) return;

    final amount = _parseAmount();

    if (amount == null) {
      _showMessage('Ingresa un importe válido.');
      return;
    }

    if (_isExpense) {
      await _saveExpense(amount);
      return;
    }

    if (_isIncome) {
      await _saveIncome(amount);
      return;
    }

    if (_isTransfer) {
      await _saveTransfer(amount);
      return;
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
    final currentBalance = selectedAccount['currentBalance'] as int? ?? 0;

    if (amount > currentBalance) {
      _showMessage(
        'Fondos insuficientes en "${selectedAccount['name']}": '
        'Saldo disponible ${_formatAmount(currentBalance, currency)}, intentas gastar ${_formatAmount(amount, currency)}.',
      );
      return;
    }

    await _createStandardTransaction(
      amount: amount,
      currency: currency,
      direction: 'out',
      accountId: _selectedAccountId!,
      paymentMethodId: _selectedPaymentMethodId!,
      categoryId: _selectedCategoryId,
      subcategoryId: _selectedSubcategoryId,
      countForFoodControl: _countForFoodControl,
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

    await _createStandardTransaction(
      amount: amount,
      currency: currency,
      direction: 'in',
      accountId: _selectedAccountId!,
      paymentMethodId: autoPaymentMethodId,
      categoryId: _selectedCategoryId,
      subcategoryId: null,
      countForFoodControl: false,
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
      _showMessage('No se pudieron determinar las cuentas seleccionadas.');
      return;
    }

    final originCurrency = originAccount['currency'] as String;
    final destinationCurrency = destinationAccount['currency'] as String;
    final originBalance = originAccount['currentBalance'] as int? ?? 0;

    if (originCurrency != destinationCurrency) {
      _showMessage('La transferencia debe realizarse entre cuentas de la misma moneda.');
      return;
    }

    if (amount > originBalance) {
      _showMessage(
        'Fondos insuficientes en "${originAccount['name']}": '
        'Saldo disponible ${_formatAmount(originBalance, originCurrency)}, intentas transferir ${_formatAmount(amount, originCurrency)}.',
      );
      return;
    }

    await _createTransfer(
      amount: amount,
      currency: originCurrency,
      originAccountId: _selectedOriginAccountId!,
      destinationAccountId: _selectedDestinationAccountId!,
    );
  }

  Future<void> _createStandardTransaction({
    required int amount,
    required String currency,
    required String direction,
    required int accountId,
    required int paymentMethodId,
    required int? categoryId,
    required int? subcategoryId,
    required bool countForFoodControl,
  }) async {
    setState(() {
      _saving = true;
    });

    try {
      final transaction = Transaction(
        type: TransactionType.values.firstWhere(
          (value) => value.name == _type,
        ),
        amount: amount,
        currency: currency,
        accountId: accountId,
        paymentMethodId: paymentMethodId,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        date: _date,
      );

      final items = <TransactionItemInput>[];

      if (categoryId != null) {
        items.add(
          TransactionItemInput(
            categoryId: categoryId,
            subcategoryId: subcategoryId,
            amount: amount,
            countForFoodControl: countForFoodControl,
          ),
        );
      }

      await _transactionService.createTransaction(
        transaction: transaction,
        items: items,
        payments: [
          TransactionPaymentInput(
            paymentMethodId: paymentMethodId,
            amount: amount,
            direction: direction,
          ),
        ],
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

  Future<void> _createTransfer({
    required int amount,
    required String currency,
    required int originAccountId,
    required int destinationAccountId,
  }) async {
    setState(() {
      _saving = true;
    });

    try {
      final transaction = Transaction(
        type: TransactionType.transfer,
        amount: amount,
        currency: currency,
        accountId: originAccountId,
        paymentMethodId: null,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        date: _date,
      );

      final originMethods = await _paymentMethodRepository.getByAccount(originAccountId);
      final destinationMethods = await _paymentMethodRepository.getByAccount(destinationAccountId);

      if (originMethods.isEmpty) {
        throw ArgumentError('La cuenta origen no tiene medios de pago activos.');
      }

      if (destinationMethods.isEmpty) {
        throw ArgumentError('La cuenta destino no tiene medios de pago activos.');
      }

      final originPaymentMethodId = originMethods.first['id'] as int;
      final destinationPaymentMethodId = destinationMethods.first['id'] as int;

      await _transactionService.createTransaction(
        transaction: transaction,
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
          key: ValueKey('category_dropdown_$_type'),
          isExpanded: true,
          initialValue: _selectedCategoryId,
          decoration: InputDecoration(
            labelText: _isIncome ? 'Categoría de ingreso *' : 'Categoría *',
            border: const OutlineInputBorder(),
            hintText: 'Selecciona una categoría',
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

                    if (_isExpense && value != null) {
                      final selectedCat = _categories.firstWhere(
                        (c) => c['id'] == value,
                        orElse: () => {},
                      );
                      final name = (selectedCat['name'] as String? ?? '').toLowerCase();
                      if (name.contains('aliment') || name.contains('comida')) {
                        _countForFoodControl = true;
                      }
                    }
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
              key: ValueKey('subcategory_dropdown_$_selectedCategoryId'),
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
          key: ValueKey('account_dropdown_$_type'),
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
              key: ValueKey('payment_method_dropdown_$_selectedAccountId'),
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
          key: const ValueKey('origin_account_dropdown'),
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
          key: const ValueKey('destination_account_dropdown'),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva operación'),
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
              decoration: InputDecoration(
                labelText: 'Descripción',
                hintText: _isIncome
                    ? 'Ej. Pago de quincena o Bonificación'
                    : 'Ej. Almuerzo menú ejecutivo',
                border: const OutlineInputBorder(),
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
              if (_loadingAccounts)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                _buildStandardAccountSection(isDark),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _saveTransaction,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Registrar operación'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}