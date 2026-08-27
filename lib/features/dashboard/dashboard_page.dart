// ==========================================
// ARCHIVO: lib/features/dashboard/dashboard_page.dart
// ==========================================

import 'package:flutter/material.dart';

import '../../core/app_themes.dart';
import '../../repositories/account_repository.dart';
import '../../repositories/debt_repository.dart';
import '../../repositories/food_budget_repository.dart';
import '../../repositories/people_owed_repository.dart';
import '../../repositories/planned_purchase_repository.dart';
import '../../repositories/reservation_repository.dart';
import '../../repositories/transaction_repository.dart';
import '../debts/debts_page.dart';
import '../food_budget/food_budget_page.dart';
import '../reservations/reservations_page.dart';
import '../settings/appearance_settings_page.dart';
import '../transactions/create_transaction_page.dart';
import '../transactions/edit_transaction_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _accountRepository = AccountRepository();
  final _transactionRepository = TransactionRepository();
  final _reservationRepository = ReservationRepository();
  final _foodBudgetRepository = FoodBudgetRepository();
  final _debtRepository = DebtRepository();
  final _peopleOwedRepository = PeopleOwedRepository();
  final _plannedPurchaseRepository = PlannedPurchaseRepository();

  bool _loading = true;

  late DateTime _selectedMonth;

  // Totales de patrimonio
  int _netWorthPEN = 0;
  int _netWorthUSD = 0;

  // Totales de reservas
  int _reservedPEN = 0;
  int _reservedUSD = 0;

  // Comida de hoy con arrastre automático
  int _foodRemainingToday = 0;
  int _foodLimitToday = 0;

  // Deudas, Préstamos y Compras Planeadas
  int _debtsPendingPEN = 0;
  int _owedToMePEN = 0;
  int _plannedPEN = 0;

  // Totales mensuales
  int _incomePEN = 0;
  int _expensePEN = 0;

  // Últimas operaciones
  List<Map<String, Object?>> _recentTransactions = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    // 1. Patrimonio Total en Cuentas
    final accounts = await _accountRepository.getActive();
    int pen = 0;
    int usd = 0;

    for (final acc in accounts) {
      if (acc.id != null) {
        final details = await _accountRepository.getBalanceDetails(acc.id!);
        if (acc.currency == 'PEN') {
          pen += details['current']!;
        } else if (acc.currency == 'USD') {
          usd += details['current']!;
        }
      }
    }

    // 2. Fondos Reservados
    final reservedTotals = await _reservationRepository.getTotalReservedByCurrency();

    // 3. Comida de HOY con arrastre automático
    final foodCalc = await _foodBudgetRepository.getDayCalculation(DateTime.now());

    // 4. Deudas, Préstamos y Compras Planeadas
    final debtTotals = await _debtRepository.getTotalPendingDebtsByCurrency();
    final peopleTotals = await _peopleOwedRepository.getTotalOwedToMeByCurrency();
    final plannedTotals = await _plannedPurchaseRepository.getTotalEstimatedByCurrency();

    // 5. Mes Seleccionado
    final monthlyTotals = await _transactionRepository.getMonthlyTotals(
      year: _selectedMonth.year,
      month: _selectedMonth.month,
    );

    // 6. Últimas 5 operaciones
    final recent = await _transactionRepository.getRecent(limit: 5);

    if (!mounted) return;

    setState(() {
      _netWorthPEN = pen;
      _netWorthUSD = usd;

      _reservedPEN = reservedTotals['PEN'] ?? 0;
      _reservedUSD = reservedTotals['USD'] ?? 0;

      _foodLimitToday = foodCalc['effectiveLimit'] ?? 0;
      _foodRemainingToday = foodCalc['remaining'] ?? 0;

      _debtsPendingPEN = debtTotals['PEN'] ?? 0;
      _owedToMePEN = peopleTotals['PEN'] ?? 0;
      _plannedPEN = plannedTotals['PEN'] ?? 0;

      _incomePEN = monthlyTotals['incomePEN'] ?? 0;
      _expensePEN = monthlyTotals['expensePEN'] ?? 0;

      _recentTransactions = recent;
      _loading = false;
    });
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
      _loading = true;
    });
    _loadDashboardData();
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
      _loading = true;
    });
    _loadDashboardData();
  }

  String _formatMonthYear(DateTime date) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _formatAmount(int amountInCents, String currency) {
    final amount = amountInCents / 100;
    if (currency == 'USD') {
      return '\$${amount.toStringAsFixed(2)}';
    }
    return 'S/ ${amount.toStringAsFixed(2)}';
  }

  Future<void> _openCreateTransaction(String type) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateTransactionPage(initialType: type),
      ),
    );

    if (result == true && mounted) {
      await _loadDashboardData();
    }
  }

  Future<void> _openEditTransaction(int id) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditTransactionPage(transactionId: id),
      ),
    );

    if (result == true && mounted) {
      await _loadDashboardData();
    }
  }

  Future<void> _openReservations() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ReservationsPage()),
    );
    if (mounted) await _loadDashboardData();
  }

  Future<void> _openFoodBudget() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FoodBudgetPage()),
    );
    if (mounted) await _loadDashboardData();
  }

  Future<void> _openDebts() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DebtsPage()),
    );
    if (mounted) await _loadDashboardData();
  }

  Future<void> _openAppearanceSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AppearanceSettingsPage()),
    );
  }

  Widget _buildAvailableCashCard(AppThemeColors? themeColors) {
    final freePEN = _netWorthPEN - _reservedPEN;
    final freeUSD = _netWorthUSD - _reservedUSD;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: themeColors?.heroCardBorder ?? Colors.transparent),
      ),
      color: themeColors?.heroCardBg ?? Theme.of(context).colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  color: themeColors?.heroCardAccent ?? Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Dinero Libre Disponible',
                  style: TextStyle(
                    color: themeColors?.heroCardText ?? Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
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
                        'Soles Libres',
                        style: TextStyle(
                          color: (themeColors?.heroCardText ?? Colors.white).withAlpha(180),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatAmount(freePEN, 'PEN'),
                        style: TextStyle(
                          color: themeColors?.heroCardAccent ?? Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      if (_reservedPEN > 0)
                        Text(
                          'Total en cuentas: ${_formatAmount(_netWorthPEN, 'PEN')}',
                          style: TextStyle(
                            color: (themeColors?.heroCardText ?? Colors.white).withAlpha(140),
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(height: 40, width: 1, color: Colors.white24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dólares Libres',
                        style: TextStyle(
                          color: (themeColors?.heroCardText ?? Colors.white).withAlpha(180),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatAmount(freeUSD, 'USD'),
                        style: TextStyle(
                          color: themeColors?.heroCardAccent ?? Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      if (_reservedUSD > 0)
                        Text(
                          'Total en cuentas: ${_formatAmount(_netWorthUSD, 'USD')}',
                          style: TextStyle(
                            color: (themeColors?.heroCardText ?? Colors.white).withAlpha(140),
                            fontSize: 10,
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

  Widget _buildFeatureCardsRow(AppThemeColors? themeColors) {
    final foodIsExceeded = _foodRemainingToday < 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Card(
                elevation: 0,
                color: themeColors?.cardBaseBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: themeColors?.cardBaseBorder ?? Colors.white12),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: _openReservations,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.savings_outlined,
                              color: themeColors?.cardAccentText,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Reservas',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: themeColors?.cardAccentText,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _reservedUSD > 0
                              ? '${_formatAmount(_reservedPEN, 'PEN')}\n${_formatAmount(_reservedUSD, 'USD')}'
                              : _formatAmount(_reservedPEN, 'PEN'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: themeColors?.cardBaseText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Fondos apartados',
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Card(
                elevation: 0,
                color: themeColors?.cardBaseBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: themeColors?.cardBaseBorder ?? Colors.white12),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _openFoodBudget,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.restaurant,
                              color: themeColors?.cardAccentText,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Comida Hoy',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: themeColors?.cardAccentText,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatAmount(_foodRemainingToday.abs(), 'PEN'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: foodIsExceeded
                                ? Theme.of(context).colorScheme.error
                                : themeColors?.cardBaseText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          foodIsExceeded ? 'Excedido' : 'de ${_formatAmount(_foodLimitToday, 'PEN')}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Tarjeta de Compromisos y Metas (Deudas, Préstamos y Compras)
        Card(
          elevation: 0,
          color: themeColors?.cardBaseBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: themeColors?.cardBaseBorder ?? Colors.white12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: _openDebts,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
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
                      color: themeColors?.cardAccentText,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Compromisos y Metas',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: themeColors?.cardBaseText,
                          ),
                        ),
                        Text(
                          'Debo: ${_formatAmount(_debtsPendingPEN, 'PEN')} · Me deben: ${_formatAmount(_owedToMePEN, 'PEN')}${_plannedPEN > 0 ? ' · Metas: ${_formatAmount(_plannedPEN, 'PEN')}' : ''}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(AppThemeColors? themeColors) {
    return Row(
      children: [
        Expanded(
          child: _ActionBtn(
            label: 'Gasto',
            icon: Icons.arrow_upward,
            themeColors: themeColors,
            onTap: () => _openCreateTransaction('expense'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionBtn(
            label: 'Ingreso',
            icon: Icons.arrow_downward,
            themeColors: themeColors,
            onTap: () => _openCreateTransaction('income'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionBtn(
            label: 'Transferir',
            icon: Icons.swap_horiz,
            themeColors: themeColors,
            onTap: () => _openCreateTransaction('transfer'),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlySummaryCard(AppThemeColors? themeColors) {
    final netPEN = _incomePEN - _expensePEN;

    return Card(
      elevation: 0,
      color: themeColors?.summaryBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: themeColors?.summaryBorder ?? Colors.white12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _previousMonth,
                  icon: Icon(Icons.chevron_left, color: themeColors?.cardBaseText),
                  tooltip: 'Mes anterior',
                ),
                Text(
                  _formatMonthYear(_selectedMonth),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: themeColors?.cardBaseText,
                  ),
                ),
                IconButton(
                  onPressed: _nextMonth,
                  icon: Icon(Icons.chevron_right, color: themeColors?.cardBaseText),
                  tooltip: 'Mes siguiente',
                ),
              ],
            ),
            Divider(color: themeColors?.summaryBorder),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: themeColors?.summaryBoxBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.trending_up, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Ingresos',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatAmount(_incomePEN, 'PEN'),
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: themeColors?.cardBaseText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: themeColors?.summaryBoxBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.trending_down, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Gastos',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatAmount(_expensePEN, 'PEN'),
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: themeColors?.cardBaseText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: themeColors?.savingsBg ?? Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    netPEN >= 0 ? 'Ahorro del Mes (Soles):' : 'Déficit del Mes (Soles):',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: themeColors?.savingsText ?? Colors.black,
                    ),
                  ),
                  Text(
                    _formatAmount(netPEN, 'PEN'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: themeColors?.savingsText ?? Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactionsList(AppThemeColors? themeColors) {
    if (_recentTransactions.isEmpty) {
      return Card(
        elevation: 0,
        color: themeColors?.cardBaseBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: themeColors?.cardBaseBorder ?? Colors.white12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'No hay operaciones registradas aún.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: _recentTransactions.map((t) {
        final id = t['id'] as int;
        final type = t['type'] as String;
        final date = t['date'] as String;
        final description = t['description'] as String?;

        IconData iconData;
        String typeLabel;

        switch (type) {
          case 'income':
            iconData = Icons.arrow_downward;
            typeLabel = 'Ingreso';
            break;
          case 'transfer':
            iconData = Icons.swap_horiz;
            typeLabel = 'Transferencia';
            break;
          case 'debt_payment':
            iconData = Icons.handshake_outlined;
            typeLabel = 'Pago deuda';
            break;
          default:
            iconData = Icons.arrow_upward;
            typeLabel = 'Gasto';
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: themeColors?.cardBaseBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: themeColors?.cardBaseBorder ?? Colors.white12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: themeColors?.pillBg,
              child: Icon(iconData, color: themeColors?.cardAccentText, size: 20),
            ),
            title: Text(
              typeLabel,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: themeColors?.cardBaseText,
              ),
            ),
            subtitle: Text(
              description?.isNotEmpty == true ? '$date · $description' : date,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right,
              size: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            onTap: () => _openEditTransaction(id),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = Theme.of(context).extension<AppThemeColors>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finanzas Personales'),
        actions: [
          IconButton(
            icon: const Icon(Icons.palette_outlined),
            tooltip: 'Apariencia y Estilos',
            onPressed: _openAppearanceSettings,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildAvailableCashCard(themeColors),
                  const SizedBox(height: 12),

                  _buildFeatureCardsRow(themeColors),
                  const SizedBox(height: 16),

                  _buildQuickActions(themeColors),
                  const SizedBox(height: 20),

                  Text(
                    'Resumen del Mes',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: themeColors?.cardBaseText ?? Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildMonthlySummaryCard(themeColors),
                  const SizedBox(height: 24),

                  Text(
                    'Últimos Movimientos',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: themeColors?.cardBaseText ?? Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildRecentTransactionsList(themeColors),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final AppThemeColors? themeColors;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.themeColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: themeColors?.btnBg ?? Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: themeColors?.btnBorder ?? Colors.white24),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Icon(icon, color: themeColors?.btnColor ?? Theme.of(context).colorScheme.primary, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: themeColors?.btnColor ?? Theme.of(context).colorScheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}