import 'package:flutter/material.dart';

import '../../database/database_helper.dart';

class TransactionTestPage extends StatefulWidget {
  const TransactionTestPage({super.key});

  @override
  State<TransactionTestPage> createState() =>
      _TransactionTestPageState();
}

class _TransactionTestPageState
    extends State<TransactionTestPage> {
  String _result = 'Pulsa el botón para consultar la base de datos.';

  Future<void> _inspectDatabase() async {
    try {
      final db = await DatabaseHelper.database;

      final accounts = await db.query(
        'accounts',
        orderBy: 'id ASC',
      );

      final categories = await db.query(
        'categories',
        orderBy: 'id ASC',
      );

      final paymentMethods = await db.query(
        'payment_methods',
        orderBy: 'id ASC',
      );

      final buffer = StringBuffer();

      buffer.writeln('CUENTAS');
      buffer.writeln('────────────');

      for (final account in accounts) {
        buffer.writeln(
          'ID ${account['id']}: '
          '${account['name']} '
          '(${account['currency']})',
        );
      }

      buffer.writeln();
      buffer.writeln('CATEGORÍAS');
      buffer.writeln('────────────');

      for (final category in categories) {
        buffer.writeln(
          'ID ${category['id']}: '
          '${category['name']} '
          '[${category['type']}]',
        );
      }

      buffer.writeln();
      buffer.writeln('MEDIOS DE PAGO');
      buffer.writeln('────────────');

      for (final method in paymentMethods) {
        buffer.writeln(
          'ID ${method['id']}: '
          '${method['name']} '
          '(cuenta ${method['account_id']})',
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _result = buffer.toString();
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _result = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnóstico'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _inspectDatabase,
              child: const Text(
                'Consultar base de datos',
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: SelectableText(
                  _result,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}