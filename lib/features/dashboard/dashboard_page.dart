// ==========================================
// ARCHIVO: lib/features/dashboard/dashboard_page.dart
// ==========================================

import 'package:flutter/material.dart';

import '../../repositories/account_repository.dart';
import '../../repositories/debt_repository.dart';
import '../../repositories/food_budget_repository.dart';
import '../../repositories/people_owed_repository.dart';
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

  bool _loading = true;

  late DateTime _selectedMonth;

  // Totales de patrimonio
  int _netWorthPEN = 0;
  int _netWorthUSD = 0;

  // Totales de reservas
  int _reservedPEN = 0;
  int _reservedUSD = 0;

  // Comida de hoy
  int _foodRemainingToday = 0;
  int _foodLimitToday = 0;

  // Deudas y Préstamos
  int _debtsPendingPEN = 0;
  int _owedToMePEN = 0;

  // Totales mensuales
  int _incomePEN = 0;
  int _expensePEN = 0;
  int _incomeUSD = 0;
  int _expenseUSD = 0;

  // Últimas operaciones
  List<Map<String, Object?>> _recentTransactions = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
    _loadDashboardData();
  }

  String _formatDateToIso(DateTime d) {
    final year = d.year.toString();
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
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

    // 3. Comida de HOY
    final todayIso = _formatDateToIso(DateTime.now());
    final todayBudget = await _foodBudgetRepository.getDay(todayIso);
    final todaySpent = await _foodBudgetRepository.getFoodSpendingByDate(todayIso);
    final effectiveLimit = todayBudget.dailyLimit + todayBudget.adjustment;

    // 4. Deudas y Préstamos
    final debtTotals = await _debtRepository.getTotalPendingDebtsByCurrency();
    final peopleTotals = await _peopleOwedRepository.getTotalOwedToMeByCurrency();

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

      _foodLimitToday = effectiveLimit;
      _foodRemainingToday = effectiveLimit - todaySpent;

      _debtsPendingPEN = debtTotals['PEN'] ?? 0;
      _owedToMePEN = peopleTotals['PEN'] ?? 0;

      _incomePEN = monthlyTotals['incomePEN'] ?? 0;
      _expensePEN = monthlyTotals['expensePEN'] ?? 0;
      _incomeUSD = monthlyTotals['incomeUSD'] ?? 0;
      _expenseUSD = monthlyTotals['expenseUSD'] ?? 0;

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

  Widget _buildAvailableCashCard() {
    final primaryColor = Theme.of(context).colorScheme.primary;

    // Dinero Libre Disponible = Total en cuentas - Dinero Reservado
    final freePEN = _netWorthPEN - _reservedPEN;
    final freeUSD = _netWorthUSD - _reservedUSD;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              primaryColor,
              primaryColor.withAlpha(200),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.account_balance_wallet_outlined, color: Colors.white70, size: 20),
                SizedBox(width: 8),
                Text(
                  'Dinero Libre Disponible',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Soles Libres', style: TextStyle(color: Colors.white70, fontSize: 11)),
                      const SizedBox(height: 2),
                      Text(
                        _formatAmount(freePEN, 'PEN'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_reservedPEN > 0)
                        Text(
                          'Total en cuentas: ${_formatAmount(_netWorthPEN, 'PEN')}',
                          style: const TextStyle(color: Colors.white60, fontSize: 10),
                        ),
                    ],
                  ),
                ),
                Container(height: 40, width: 1, color: Colors.white30),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Dólares Libres', style: TextStyle(color: Colors.white70, fontSize: 11)),
                      const SizedBox(height: 2),
                      Text(
                        _formatAmount(freeUSD, 'USD'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_reservedUSD > 0)
                        Text(
                          'Total en cuentas: ${_formatAmount(_netWorthUSD, 'USD')}',
                          style: const TextStyle(color: Colors.white60, fontSize: 10),
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

  Widget _buildFeatureCardsRow() {
    return Column(
      children: [
        Row(
          children: [
            // Tarjeta de Reservas (Estilo pastel con alto contraste)
            Expanded(
              child: Card(
                elevation: 0,
                color: Colors.deepPurple.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.deepPurple.shade200),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _openReservations,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.savings_outlined, color: Colors.deepPurple.shade800, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'Reservas',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple.shade900,
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
                            fontSize: _reservedUSD > 0 ? 13 : 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple.shade900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text('Fondos apartados', style: TextStyle(fontSize: 10, color: Colors.black54)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Tarjeta de Control de Alimentación (Estilo cálido con alto contraste)
            Expanded(
              child: Card(
                elevation: 0,
                color: Colors.orange.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.orange.shade200),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _openFoodBudget,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.restaurant, color: Colors.orange.shade900, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'Comida Hoy',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatAmount(_foodRemainingToday.abs(), 'PEN'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _foodRemainingToday < 0 ? Colors.red.shade800 : Colors.green.shade800,
                          ),
                        ),
                        Text(
                          _foodRemainingToday < 0 ? 'Excedido' : 'de ${_formatAmount(_foodLimitToday, 'PEN')}',
                          style: const TextStyle(fontSize: 10, color: Colors.black54),
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

        // Tarjeta de Deudas y Préstamos (Estilo pastel índigo)
        Card(
          elevation: 0,
          color: Colors.indigo.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.indigo.shade200),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _openDebts,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.indigo.shade100,
                    child: Icon(Icons.handshake_outlined, color: Colors.indigo.shade900, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Deudas y Préstamos',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.indigo),
                        ),
                        Text(
                          'Debo: ${_formatAmount(_debtsPendingPEN, 'PEN')}  ·  Me deben: ${_formatAmount(_owedToMePEN, 'PEN')}',
                          style: const TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.indigo.shade800),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _QuickActionButton(
            label: 'Gasto',
            icon: Icons.arrow_upward,
            color: Colors.redAccent,
            onTap: () => _openCreateTransaction('expense'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickActionButton(
            label: 'Ingreso',
            icon: Icons.arrow_downward,
            color: Colors.green,
            onTap: () => _openCreateTransaction('income'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickActionButton(
            label: 'Transferir',
            icon: Icons.swap_horiz,
            color: Colors.blueAccent,
            onTap: () => _openCreateTransaction('transfer'),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlySummaryCard() {
    final netPEN = _incomePEN - _expensePEN;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300),
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
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Mes anterior',
                ),
                Text(
                  _formatMonthYear(_selectedMonth),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: _nextMonth,
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Mes siguiente',
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _SummaryBox(
                    title: 'Ingresos',
                    amountPEN: _incomePEN,
                    amountUSD: _incomeUSD,
                    color: Colors.green,
                    icon: Icons.trending_up,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryBox(
                    title: 'Gastos',
                    amountPEN: _expensePEN,
                    amountUSD: _expenseUSD,
                    color: Colors.redAccent,
                    icon: Icons.trending_down,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Barra verde de Ahorro del Mes
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: netPEN >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    netPEN >= 0 ? 'Ahorro del Mes (Soles):' : 'Déficit del Mes (Soles):',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: netPEN >= 0 ? Colors.green.shade900 : Colors.red.shade900,
                    ),
                  ),
                  Text(
                    _formatAmount(netPEN, 'PEN'),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: netPEN >= 0 ? Colors.green.shade900 : Colors.red.shade900,
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

  Widget _buildRecentTransactionsList() {
    if (_recentTransactions.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.white24),
        ),
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text(
              'No hay operaciones registradas aún.',
              style: TextStyle(
                color: Colors.white70, // 👈 Blanco/plata nítido en Modo Oscuro
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
        Color iconColor;
        String typeLabel;

        switch (type) {
          case 'income':
            iconData = Icons.arrow_downward;
            iconColor = Colors.green;
            typeLabel = 'Ingreso';
            break;
          case 'transfer':
            iconData = Icons.swap_horiz;
            iconColor = Colors.blue;
            typeLabel = 'Transferencia';
            break;
          case 'debt_payment':
            iconData = Icons.handshake_outlined;
            iconColor = Colors.purple;
            typeLabel = 'Pago deuda';
            break;
          default:
            iconData = Icons.arrow_upward;
            iconColor = Colors.redAccent;
            typeLabel = 'Gasto';
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: iconColor.withAlpha(30),
              child: Icon(iconData, color: iconColor, size: 20),
            ),
            title: Text(typeLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(description?.isNotEmpty == true ? '$date · $description' : date),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () => _openEditTransaction(id),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Finanzas Personales',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.palette_outlined),
            tooltip: 'Apariencia y Estilo',
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
                  _buildAvailableCashCard(),
                  const SizedBox(height: 12),

                  _buildFeatureCardsRow(),
                  const SizedBox(height: 16),

                  _buildQuickActions(),
                  const SizedBox(height: 20),

                  const Text(
                    'Resumen del Mes',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildMonthlySummaryCard(),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Últimos Movimientos',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildRecentTransactionsList(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withAlpha(25),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
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

class _SummaryBox extends StatelessWidget {
  final String title;
  final int amountPEN;
  final int amountUSD;
  final Color color;
  final IconData icon;

  const _SummaryBox({
    required this.title,
    required this.amountPEN,
    required this.amountUSD,
    required this.color,
    required this.icon,
  });

  String _format(int cents, String currency) {
    final amount = cents / 100;
    return currency == 'USD' ? '\$${amount.toStringAsFixed(2)}' : 'S/ ${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _format(amountPEN, 'PEN'),
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (amountUSD > 0)
            Text(
              _format(amountUSD, 'USD'),
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
            ),
        ],
      ),
    );
  }
}