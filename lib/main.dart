// ==========================================
// ARCHIVO: lib/main.dart
// ==========================================

import 'package:flutter/material.dart';

import 'core/theme_controller.dart';
import 'database/database_helper.dart';
import 'features/dashboard/dashboard_page.dart';
import 'features/accounts/accounts_page.dart';
import 'features/settings/categories_page.dart';
import 'features/transactions/transactions_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DatabaseHelper.database;
  await ThemeController.instance.loadTheme();

  runApp(const FinanzasApp());
}

class FinanzasApp extends StatelessWidget {
  const FinanzasApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = ThemeController.instance;

    return ListenableBuilder(
      listenable: themeController,
      builder: (context, _) {
        final seedColor = themeController.selectedColor.color;

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'VikuTrack',
          themeMode: themeController.themeMode,

          // Tema Claro
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: seedColor,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),

          // Tema Oscuro con navegación de alto contraste
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: seedColor,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            navigationBarTheme: NavigationBarThemeData(
              indicatorColor: seedColor.withAlpha(80),
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white);
                }
                return const TextStyle(fontSize: 12, color: Colors.white70);
              }),
              iconTheme: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const IconThemeData(color: Colors.white);
                }
                return const IconThemeData(color: Colors.white70);
              }),
            ),
          ),

          home: const MainPage(),
        );
      },
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    DashboardPage(),
    AccountsPage(),
    CategoriesPage(),
    TransactionsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Cuentas',
          ),
          NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category),
            label: 'Categorías',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Operaciones',
          ),
        ],
      ),
    );
  }
}